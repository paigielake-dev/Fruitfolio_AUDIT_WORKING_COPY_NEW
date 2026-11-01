import Foundation
import NaturalLanguage

nonisolated enum FruitfolioTranslationPreservationError: Error {
    case emptyInput, changedNumber, changedLiteral, unexpectedCitation, invalidSourceCitation
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
}

nonisolated enum FruitfolioTranslationPreservation {
    private static let numeric = try! NSRegularExpression(pattern: #"[+−-]?\d+(?:[.,]\d+)?"#)
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
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.setLanguage(.english)
        tokenizer.string = source
        var ranges: [Range<String.Index>] = []
        tokenizer.enumerateTokens(in: source.startIndex..<source.endIndex) { range, _ in ranges.append(range); return true }
        var translated: [String] = []
        var markers: [String] = []
        for range in ranges {
            try Task.checkCancellation()
            let sentence = String(source[range]).trimmingCharacters(in: .whitespacesAndNewlines)
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
            var output = try await runtime.translateRawSentence(modelInput, target: target, directory: directory)
            try Task.checkCancellation()
            guard citation.firstMatch(in: output, range: NSRange(output.startIndex..., in: output)) == nil else {
                throw FruitfolioTranslationPreservationError.unexpectedCitation
            }
            output = try FruitfolioTranslationPreservation.preserveNumbers(source: modelInput, translated: output, target: target)
            try FruitfolioTranslationPreservation.preserveLiterals(immutableTerms, source: modelInput, translated: output)
            if !localMarkers.isEmpty {
                let terminal = output.last.map { ".!?".contains($0) } == true ? String(output.removeLast()) : ""
                output += " " + localMarkers.joined(separator: " ") + terminal
            }
            markers.append(contentsOf: localMarkers)
            translated.append(output)
        }
        return .init(originalText: source, textForVerification: translated.joined(separator: " "),
                     sourceIdentifiers: sourceIdentifiers, citationMarkers: markers, target: target)
    }
}
