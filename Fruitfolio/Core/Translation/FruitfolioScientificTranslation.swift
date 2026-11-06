import Foundation

/// Protected tokens are verified after inference. A changed/missing/reordered
/// placeholder rejects the output instead of guessing how to repair a citation.
struct FruitfolioScientificTranslationEnvelope: Sendable {
    let original: String
    let prepared: String
    private let replacements: [(String, String)]
    private let protectionRegexPattern: String

    init(_ source: String, protectedLiterals: [String] = []) throws {
        original = source
        let literalPatterns = protectedLiterals.filter { !$0.isEmpty }
            .sorted { $0.count > $1.count }.map { NSRegularExpression.escapedPattern(for: $0) }
        let patterns = literalPatterns + [
            FruitfolioScientificQuantityProtection.protectionPattern,
            #"\\[\\*_`\[\]<>]"#,
            #"</?u>"#,
            FruitfolioScientificQuantityProtection.referencePattern,
            #"\*\*|__|(?<!\*)\*(?!\*)"#
        ]
        let pattern = patterns.map { "(?:\($0))" }.joined(separator: "|")
        protectionRegexPattern = pattern
        let regex = try NSRegularExpression(pattern: pattern)
        let ns = source as NSString
        let matches = regex.matches(in: source, range: NSRange(location: 0, length: ns.length))
        let prefix = "FFPROTECT_" + UUID().uuidString.replacingOccurrences(of: "-", with: "") + "_"
        var replacements: [(String, String)] = []
        let output = NSMutableString(string: source)
        for (index, match) in matches.enumerated() {
            replacements.append(("\(prefix)\(index)_END", ns.substring(with: match.range)))
        }
        for (index, match) in matches.enumerated().reversed() {
            output.replaceCharacters(in: match.range, with: replacements[index].0)
        }
        self.replacements = replacements
        prepared = output as String
    }

    func restore(_ translated: String) throws -> String {
        var lastEnd = translated.startIndex
        for (marker, _) in replacements {
            guard translated.components(separatedBy: marker).count == 2,
                  let range = translated.range(of: marker), range.lowerBound >= lastEnd else {
                throw FruitfolioTranslationError.protectedContentChanged
            }
            lastEnd = range.upperBound
        }
        var output = translated
        for (marker, original) in replacements { output = output.replacingOccurrences(of: marker, with: original) }
        guard try FruitfolioScientificQuantityProtection.quantitySignature(output) == FruitfolioScientificQuantityProtection.quantitySignature(original),
              try FruitfolioScientificQuantityProtection.referenceSignature(output) == FruitfolioScientificQuantityProtection.referenceSignature(original) else {
            throw FruitfolioTranslationError.protectedContentChanged
        }
        return output
    }

    /// Catalog text has no generated placeholders. Preserve the source-specific
    /// protected token sequence while permitting ordinary translated words that
    /// merely resemble units (for example Norwegian "min"). This checks literal
    /// integrity, not semantic/clinical approval of a translation.
    func validateCatalogCandidate(_ candidate: String) throws -> String {
        let expected = replacements.map { $0.1 }
        let sourceLiterals = Set(expected)
        let regex = try NSRegularExpression(pattern: protectionRegexPattern)
        let ns = candidate as NSString
        let retained = regex.matches(in: candidate, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }.filter { sourceLiterals.contains($0) }
        guard retained == expected,
              try FruitfolioScientificQuantityProtection.quantitySignature(candidate) == FruitfolioScientificQuantityProtection.quantitySignature(original),
              try FruitfolioScientificQuantityProtection.referenceSignature(candidate) == FruitfolioScientificQuantityProtection.referenceSignature(original) else {
            throw FruitfolioTranslationError.protectedContentChanged
        }
        return candidate
    }



}

enum FruitfolioTranslationOrigin: Equatable, Sendable { case source, catalog, machine }
struct FruitfolioDisplayTranslation: Equatable, Sendable {
    let text: String
    let origin: FruitfolioTranslationOrigin
}

actor FruitfolioTranslationService {
    static let shared = FruitfolioTranslationService(runtime: FruitfolioMADLADRuntime.shared)
    private let runtime: any FruitfolioLocalTranslationRuntime
    init(runtime: any FruitfolioLocalTranslationRuntime) { self.runtime = runtime }

    func releaseResources() async { await runtime.releaseResources() }

    func translate(_ source: String, language: FruitfolioLanguage, protectedLiterals: [String] = [],
                   sourceLanguage: String = "en", preferCatalog: Bool = true, bundle: Bundle = .main) async throws -> String {
        try await translateForDisplay(source, language: language, protectedLiterals: protectedLiterals,
            sourceLanguage: sourceLanguage, preferCatalog: preferCatalog, bundle: bundle).text
    }

    func translateForDisplay(_ source: String, language: FruitfolioLanguage, protectedLiterals: [String] = [],
                             sourceLanguage: String = "en", preferCatalog: Bool = true,
                             inferenceAllowed: Bool = true, bundle: Bundle = .main) async throws -> FruitfolioDisplayTranslation {
        try Task.checkCancellation()
        guard language.rawValue != sourceLanguage,
              !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .init(text: source, origin: .source)
        }
        // Catalog keys describe English source text. Never reinterpret a saved
        // non-English original as an English UI key, or rewrite saved records.
        if preferCatalog, sourceLanguage == "en",
           let candidate = FruitfolioLocalization.catalogValue(source, language: language, bundle: bundle),
           let accepted = try? FruitfolioScientificTranslationEnvelope(source, protectedLiterals: protectedLiterals)
                .validateCatalogCandidate(candidate) {
            try Task.checkCancellation()
            return .init(text: accepted, origin: .catalog)
        }
        guard inferenceAllowed else { throw FruitfolioTranslationError.pausedForMemoryPressure }
        // Only the simplified Chinese selector maps to the generic zh tag.
        // Traditional Chinese is not silently advertised as equivalent.
        let tag = language == .chineseSimplified ? "zh" : language.rawValue
        var translated: [String] = []
        for paragraph in source.components(separatedBy: "\n\n") {
            try Task.checkCancellation()
            if paragraph.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                translated.append(paragraph)
                continue
            }
            let envelope = try FruitfolioScientificTranslationEnvelope(paragraph, protectedLiterals: protectedLiterals)
            let result = try await runtime.translate(envelope.prepared, targetTag: tag)
            try Task.checkCancellation()
            translated.append(try envelope.restore(result))
        }
        return .init(text: translated.joined(separator: "\n\n"), origin: .machine)
    }
}
