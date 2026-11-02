import Foundation
import NaturalLanguage

nonisolated enum FruitfolioTranslationPreservationError: Error {
    case emptyInput, changedNumber, changedLiteral, changedProtectedMeasurement, unexpectedCitation, invalidSourceCitation
}

/// A failed candidate is never shown as a translation. Synthetic integration
/// tests may inspect its exact raw sentence; normal error descriptions contain
/// no user text, and this object is neither logged nor persisted by the adapter.
nonisolated struct FruitfolioTranslationRejectedCandidate: Error, Sendable, CustomStringConvertible {
    let reason: FruitfolioTranslationPreservationError
    let sourceSentence: String
    let actualModelInput: String
    let rawOutput: String
    let target: String
    var description: String { "Translation rejected: \(reason)" }
}

/// A candidate is deliberately distinct from an approved user-facing medical
/// translation. Preservation checks alone cannot establish clinical entailment.
nonisolated struct FruitfolioTranslationCandidate: Sendable {
    let originalText: String
    let textForVerification: String
    let sourceIdentifiers: [String]
    let citationMarkers: [String]
    let target: String
    let medicalMeaningVerified = false
    /// Ephemeral inference provenance. Only synthetic integration fixtures
    /// serialize this; the application does not log or persist user content.
    let sentenceEvidence: [FruitfolioTranslationSentenceEvidence]
}

nonisolated struct FruitfolioTranslationSentenceEvidence: Sendable, Codable {
    let sourceSentence: String
    let actualModelInput: String
    let rawOutput: String
    let restoredOutput: String
    let preservedLiteralSuffix: String
}

nonisolated enum FruitfolioTranslationPreservation {
    // Lexical recognition only: never parse, round, convert units, or infer a
    // measurement's clinical meaning. Unicode digits and exponents stay exact.
    static let numericPattern = #"[+＋−﹣－-]?(?:(?:\p{Nd}+[\p{Zs}\t]+)?[¼½¾⅐⅑⅒⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]|\p{Nd}+[/⁄／]\p{Nd}+|\p{Nd}+(?:[.,٫．]\p{Nd}+)?|[.．]\p{Nd}+)(?:(?:[eEｅＥ][+−﹣－-]?\p{Nd}+)|(?:[\p{Zs}\t]*[×x·][\p{Zs}\t]*10(?:\^?[+−-]?\p{Nd}+|[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]+))|\^[+−-]?\p{Nd}+|[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]+)?"#
    private static let numeric = try! NSRegularExpression(pattern: numericPattern)
    static func numbers(_ text: String) -> [String] {
        numeric.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap {
            Range($0.range, in: text).map { String(text[$0]) }
        }
    }

    /// Restore the original decimal spelling only after exact numeric
    /// equivalence is demonstrated. The final lexical invariant stays strict.
    /// Source comma/grouping conventions are never guessed or converted.
    static func preserveNumbers(source: String, translated: String, target: String) throws -> String {
        let original = numbers(source)
        let matches = numeric.matches(in: translated, range: NSRange(translated.startIndex..., in: translated))
        guard original.count == matches.count else { throw FruitfolioTranslationPreservationError.changedNumber }
        var result = translated
        for (sourceNumber, match) in zip(original, matches).reversed() {
            guard let range = Range(match.range, in: result) else { throw FruitfolioTranslationPreservationError.changedNumber }
            let proposed = String(result[range])
            if sourceNumber == proposed { continue }
            guard ["fr", "de"].contains(target), sourceNumber.contains("."), !sourceNumber.contains(","),
                  proposed.contains(","), !proposed.contains("."),
                  // Decimal(string:) accepts numeric prefixes. Restrict this
                  // legacy locale exception to whole simple ASCII decimals;
                  // an exponent, sign, or Unicode change must never slip through.
                  sourceNumber.range(of: #"^[+-]?[0-9]+\.[0-9]+$"#, options: .regularExpression) != nil,
                  proposed.range(of: #"^[+-]?[0-9]+,[0-9]+$"#, options: .regularExpression) != nil,
                  let first = Decimal(string: sourceNumber, locale: Locale(identifier: "en_US_POSIX")),
                  let second = Decimal(string: proposed.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")),
                  first == second else { throw FruitfolioTranslationPreservationError.changedNumber }
            result.replaceSubrange(range, with: sourceNumber)
        }
        guard numbers(result) == original else { throw FruitfolioTranslationPreservationError.changedNumber }
        return result
    }

    static func preserveLiterals(_ literals: [String], source: String, translated: String) throws {
        for literal in literals {
            guard !literal.isEmpty,
                  source.components(separatedBy: literal).count == translated.components(separatedBy: literal).count else {
                throw FruitfolioTranslationPreservationError.changedLiteral
            }
        }
    }
}

/// Numeric values, ranges, recognized unit spans and explicit immutable units are opaque
/// source metadata, like citations. The model may translate surrounding words
/// but cannot convert a result, translate its unit, or choose another quantity.
nonisolated struct FruitfolioProtectedMeasurements {
    let modelInput: String
    let markers: [String]
    let originalSpans: [String]
    private let prefix: String

    init(source: String, immutableTerms: [String]) throws {
        let full = NSRange(source.startIndex..., in: source)
        let horizontal = #"[\p{Zs}\t]*"#
        let number = FruitfolioTranslationPreservation.numericPattern
        let quantity = #"(?:(?:<=|>=|≤|≥|<|>|≈|~)"# + horizontal + #")?(?:"# + number
            + #")(?:(?:"# + horizontal + #"(?:[–—−-]|±|to)"# + horizontal + #")(?:"# + number + #"))?"#
        // These spellings identify source spans, not permissible conversions.
        // Longest first plus a letter boundary avoids consuming 'm' in months.
        let prefixes = ["", "f", "p", "n", "u", "µ", "μ", "m", "c", "d", "k", "M"]
        let bases = ["g", "L", "l", "mol", "IU", "U", "Eq", "m", "Pa", "Hz", "J", "W", "cal"]
        let conventional = ["%", "٪", "％", "°C", "°F", "℃", "℉", "K", "mmHg", "bpm", "min", "h", "s", "d"]
        let baseNames = Set(prefixes.flatMap { prefix in bases.map { prefix + $0 } } + conventional)
        let widthNames = baseNames.map { term in
            term.unicodeScalars.reduce(into: "") { result, scalar in
                if (0x21...0x7E).contains(scalar.value) {
                    result.unicodeScalars.append(UnicodeScalar(scalar.value + 0xFEE0)!)
                } else { result.unicodeScalars.append(scalar) }
            }
        }
        let unitNames = baseNames.union(widthNames)
        let unit = unitNames.sorted { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        let power = #"(?:\^[+−-]?\p{Nd}+|[⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻]+|[−-]\p{Nd}+)?"#
        let atom = #"(?:"# + unit + #")"# + power + #"(?![\p{L}])"#
        let denominator = #"(?:"# + number + #")?"# + atom
        let compound = atom + #"(?:"# + horizontal + #"[/／·⋅*]"# + horizontal + denominator + #")*"#
        var patterns = [
            // ISO dates are immutable data too; protect the complete date so
            // its separators and order cannot be rewritten by translation.
            #"(?<![\p{L}\p{N}_])\d{4}-\d{2}-\d{2}(?![\p{L}\p{N}_])"#,
            #"(?<![\p{L}\p{N}_])"# + quantity + horizontal + compound,
            #"(?<![\p{L}\p{N}_])"# + quantity
        ]
        for term in Set(immutableTerms) where !term.isEmpty {
            let literal = NSRegularExpression.escapedPattern(for: term)
            patterns.append(#"(?<![\p{L}\p{N}_])"# + quantity + horizontal + literal)
            // Explicit immutable medical terms are protected even when they
            // are not adjacent to a measurement (for example TSH).
            patterns.append(literal)
        }
        var ranges: [NSRange] = []
        for pattern in patterns {
            let regex = try NSRegularExpression(pattern: pattern)
            ranges.append(contentsOf: regex.matches(in: source, range: full).map(\.range))
        }
        ranges.sort { $0.location == $1.location ? $0.length > $1.length : $0.location < $1.location }
        var selected: [NSRange] = []
        for range in ranges {
            if let previous = selected.last, range.location < NSMaxRange(previous) { continue }
            selected.append(range)
        }
        var prefix = "FFQ"
        let normalizedSource = Self.canonicalASCIIWidth(source)
        while normalizedSource.contains("[" + prefix) { prefix += "X" }
        self.prefix = prefix
        markers = selected.indices.map { "[" + prefix + String($0) + "]" }
        let nsSource = source as NSString
        originalSpans = selected.map { nsSource.substring(with: $0) }
        let protected = NSMutableString(string: source)
        for (index, range) in selected.enumerated().reversed() {
            protected.replaceCharacters(in: range, with: markers[index])
        }
        modelInput = protected as String
    }

    /// A terminal list made solely of protected quantities and separators is
    /// immutable source metadata. Actual Japanese MADLAD dropped a six-marker
    /// list entirely. Generate only its surrounding prose, then restore the
    /// exact list outside inference, as with terminal citation metadata.
    func terminalLiteralList() throws -> FruitfolioTerminalMeasurementList? {
        guard let colon = modelInput.lastIndex(where: { $0 == ":" || $0 == "：" }) else { return nil }
        let head = String(modelInput[..<colon]).trimmingCharacters(in: .whitespaces)
        let suffix = String(modelInput[colon...])
        guard !head.isEmpty else { return nil }
        let marker = #"\["# + NSRegularExpression.escapedPattern(for: prefix) + #"[0-9]+\]"#
        let spacing = #"[\p{Zs}\t]*"#
        let pattern = #"^[:：]"# + spacing + marker
            + #"(?:"# + spacing + #"[,;，；،؛]"# + spacing + marker + #")+"#
            + spacing + #"[.!?。！？؟।]?$"#
        let expression = try NSRegularExpression(pattern: pattern)
        let full = NSRange(suffix.startIndex..., in: suffix)
        guard expression.firstMatch(in: suffix, range: full)?.range == full else { return nil }
        return .init(modelInput: head, sourceSuffix: suffix)
    }

    static func canonicalASCIIWidth(_ value: String) -> String {
        // Exact Unicode width counterparts only; no script, unit conversion,
        // decimal rounding, synonym replacement or whole-number reinterpretation.
        var output = ""
        for scalar in value.unicodeScalars {
            if (0xFF01...0xFF5E).contains(scalar.value) {
                output.unicodeScalars.append(UnicodeScalar(scalar.value - 0xFEE0)!)
            } else if scalar.value == 0x3000 {
                output.append(" ")
            } else { output.unicodeScalars.append(scalar) }
        }
        return output
    }

    func restoring(in rawOutput: String) throws -> String {
        var output = Self.canonicalASCIIWidth(rawOutput)
        // The actual official zh decoder inserted a horizontal space before
        // the closing bracket. Permit only marker-edge typography, never a
        // changed identifier, missing slot, extra slot, or reordered quantity.
        let regex = try NSRegularExpression(pattern: #"\[[\p{Zs}\t]*"# + prefix + #"(\d+)[\p{Zs}\t]*\]"#)
        let matches = regex.matches(in: output, range: NSRange(output.startIndex..., in: output))
        let found = matches.map { match in
            "[" + prefix + (output as NSString).substring(with: match.range(at: 1)) + "]"
        }
        guard found == markers else { throw FruitfolioTranslationPreservationError.changedProtectedMeasurement }
        let restored = NSMutableString(string: output)
        for (match, original) in zip(matches, originalSpans).reversed() {
            restored.replaceCharacters(in: match.range, with: original)
        }
        output = restored as String
        return output
    }
}

nonisolated struct FruitfolioTerminalMeasurementList: Sendable {
    let modelInput: String
    let sourceSuffix: String
    func combining(with rawPrefix: String) -> String {
        var prefix = rawPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        if let last = prefix.last, ".!?。！？؟।:：".contains(last) { prefix.removeLast() }
        return prefix.trimmingCharacters(in: .whitespaces) + sourceSuffix
    }
}

/// Literal layout is never sent through generation. Sentence candidates may
/// change language, but paragraph separators, indentation and list/header marks
/// retain their original positions and spelling.
nonisolated enum FruitfolioTranslationSegment: Equatable, Sendable {
    case literal(String)
    case sentence(String)
    var original: String {
        switch self { case .literal(let value), .sentence(let value): return value }
    }
}

nonisolated enum FruitfolioTranslationLayout {
    static func segments(_ source: String) -> [FruitfolioTranslationSegment] {
        var result: [FruitfolioTranslationSegment] = []
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: .byLines) { _, lineRange, enclosingRange, _ in
            let line = String(source[lineRange])
            let prefixPattern = #"^[ \t]*(?:(?:[-*+]\s+|\d+[.)]\s+|#{1,6}\s+))?"#
            let prefix = line.range(of: prefixPattern, options: .regularExpression)!
            if !line[prefix].isEmpty { result.append(.literal(String(line[prefix]))) }
            let body = String(line[prefix.upperBound...])
            let tokenizer = NLTokenizer(unit: .sentence)
            tokenizer.setLanguage(.english); tokenizer.string = body
            var ranges: [Range<String.Index>] = []
            tokenizer.enumerateTokens(in: body.startIndex..<body.endIndex) { range, _ in ranges.append(range); return true }
            if ranges.isEmpty && !body.isEmpty { ranges = [body.startIndex..<body.endIndex] }
            var cursor = body.startIndex
            for range in ranges {
                var start = range.lowerBound, end = range.upperBound
                while start < end, body[start].isWhitespace { start = body.index(after: start) }
                while end > start, body[body.index(before: end)].isWhitespace { end = body.index(before: end) }
                if cursor < start { result.append(.literal(String(body[cursor..<start]))) }
                if start < end { result.append(.sentence(String(body[start..<end]))) }
                cursor = end
            }
            if cursor < body.endIndex { result.append(.literal(String(body[cursor...]))) }
            if lineRange.upperBound < enclosingRange.upperBound {
                result.append(.literal(String(source[lineRange.upperBound..<enclosingRange.upperBound])))
            }
        }
        return result
    }
}

/// Actual official MADLAD inference with sentence-sized requests and citation
/// metadata kept outside generation. No replacement model or network service.
/// Production Ask remains gated until semantic/language/device acceptance; this
/// API returns a clearly identified candidate for that verification process.
actor FruitfolioMADLADDocumentTranslator {
    private let runtime: FruitfolioMADLADLocalRuntime
    init(runtime: FruitfolioMADLADLocalRuntime = FruitfolioMADLADLocalRuntime()) { self.runtime = runtime }

    func candidate(source: String, sourceIdentifiers: [String], target: String,
                   immutableTerms: [String], directory: URL) async throws -> FruitfolioTranslationCandidate {
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FruitfolioTranslationPreservationError.emptyInput
        }
        let citation = try NSRegularExpression(pattern: #"\[([A-Za-z0-9_.:-]+)\]"#)
        var translated: [String] = []
        var markers: [String] = []
        var sentenceEvidence: [FruitfolioTranslationSentenceEvidence] = []
        for segment in FruitfolioTranslationLayout.segments(source) {
            try Task.checkCancellation()
            guard case .sentence(let sentence) = segment else {
                translated.append(segment.original)
                continue
            }
            let matches = citation.matches(in: sentence, range: NSRange(sentence.startIndex..., in: sentence))
            let localMarkers = try matches.map { match -> String in
                guard let idRange = Range(match.range(at: 1), in: sentence),
                      sourceIdentifiers.contains(String(sentence[idRange])),
                      let markerRange = Range(match.range, in: sentence) else {
                    throw FruitfolioTranslationPreservationError.invalidSourceCitation
                }
                return String(sentence[markerRange])
            }
            // Moving an inline citation to the sentence end could broaden its
            // claim attribution. Only an already-terminal citation cluster can
            // be detached and reattached; ambiguous placement fails closed.
            if let first = matches.first, let start = Range(first.range, in: sentence)?.lowerBound {
                let suffix = String(sentence[start...])
                guard suffix.range(of: #"^(?:\[[A-Za-z0-9_.:-]+\]\s*)+[.!?]?$"#, options: .regularExpression) != nil else {
                    throw FruitfolioTranslationPreservationError.invalidSourceCitation
                }
            }
            var modelInput = citation.stringByReplacingMatches(in: sentence,
                range: NSRange(sentence.startIndex..., in: sentence), withTemplate: "")
            modelInput = modelInput.replacingOccurrences(of: #"\s+([.!?])$"#, with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !modelInput.isEmpty else { throw FruitfolioTranslationPreservationError.emptyInput }
            let measurements = try FruitfolioProtectedMeasurements(source: modelInput, immutableTerms: immutableTerms)
            let literalList = try measurements.terminalLiteralList()
            let actualModelInput = literalList?.modelInput ?? measurements.modelInput
            let rawOutput = try await runtime.translateRawSentence(actualModelInput, target: target, directory: directory)
            let candidateWithSourceMetadata = literalList?.combining(with: rawOutput) ?? rawOutput
            try Task.checkCancellation()
            var output: String
            do {
                output = try measurements.restoring(in: candidateWithSourceMetadata)
                guard citation.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)) == nil else {
                    throw FruitfolioTranslationPreservationError.unexpectedCitation
                }
                output = try FruitfolioTranslationPreservation.preserveNumbers(source: modelInput, translated: output, target: target)
                try FruitfolioTranslationPreservation.preserveLiterals(immutableTerms, source: modelInput, translated: output)
            } catch let reason as FruitfolioTranslationPreservationError {
                throw FruitfolioTranslationRejectedCandidate(reason: reason, sourceSentence: modelInput,
                    actualModelInput: actualModelInput, rawOutput: rawOutput, target: target)
            }
            if !localMarkers.isEmpty {
                let terminal = output.last.map { ".!?。！？؟।".contains($0) } == true ? String(output.removeLast()) : ""
                output = output.trimmingCharacters(in: .whitespaces)
                output += " " + localMarkers.joined(separator: " ") + terminal
            }
            sentenceEvidence.append(.init(sourceSentence: modelInput,
                actualModelInput: actualModelInput, rawOutput: rawOutput, restoredOutput: output,
                preservedLiteralSuffix: literalList?.sourceSuffix ?? ""))
            markers.append(contentsOf: localMarkers)
            translated.append(output)
        }
        return .init(originalText: source, textForVerification: translated.joined(),
                     sourceIdentifiers: sourceIdentifiers, citationMarkers: markers, target: target, sentenceEvidence: sentenceEvidence)
    }
}
