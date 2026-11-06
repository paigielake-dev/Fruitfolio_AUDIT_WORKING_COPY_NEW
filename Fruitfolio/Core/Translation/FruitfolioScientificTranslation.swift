import Foundation

/// Protected tokens are verified after inference. A changed/missing/reordered
/// placeholder rejects the output instead of guessing how to repair a citation.
struct FruitfolioScientificTranslationEnvelope: Sendable {
    let original: String
    let prepared: String
    private let replacements: [(String, String)]

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
        let regex = try NSRegularExpression(pattern: patterns.map { "(?:\($0))" }.joined(separator: "|"))
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


}

actor FruitfolioTranslationService {
    static let shared = FruitfolioTranslationService(runtime: FruitfolioMADLADRuntime.shared)
    private let runtime: any FruitfolioLocalTranslationRuntime
    init(runtime: any FruitfolioLocalTranslationRuntime) { self.runtime = runtime }

    func releaseResources() async { await runtime.releaseResources() }

    func translate(_ source: String, language: FruitfolioLanguage, protectedLiterals: [String] = [], sourceLanguage: String = "en") async throws -> String {
        guard language.rawValue != sourceLanguage else { return source }
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
        return translated.joined(separator: "\n\n")
    }
}
