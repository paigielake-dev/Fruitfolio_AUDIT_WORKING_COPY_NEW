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
            #"\\[\\*_`\[\]<>]"#,
            #"</?u>"#,
            #"https?://[^\s<>]+"#,
            #"\[[^\]\n]{1,200}\]"#,
            #"\([^\)\n]*\b(?:19|20)\d{2}[a-z]?[^\)\n]*\)"#,
            #"\p{N}+(?:[.,:/−–-]\p{N}+)*(?:\s?(?:pg/mL|ng/mL|nmol/L|pmol/L|mIU/mL|IU/L|mg|mcg|µg|μg|g|mL|L|%|°C|°F))?"#,
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
        guard Self.numbers(output) == Self.numbers(original) else {
            throw FruitfolioTranslationError.protectedContentChanged
        }
        return output
    }

    private static func numbers(_ text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: #"\p{N}+(?:[.,:/−–-]\p{N}+)*"#) else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range) }
    }
}

actor FruitfolioTranslationService {
    static let shared = FruitfolioTranslationService(runtime: FruitfolioMADLADRuntime.shared)
    private let runtime: any FruitfolioLocalTranslationRuntime
    init(runtime: any FruitfolioLocalTranslationRuntime) { self.runtime = runtime }

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
