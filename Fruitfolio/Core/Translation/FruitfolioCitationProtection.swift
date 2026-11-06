import Foundation

/// Literal bibliographic identifiers/APA records remain original-language text.
/// Do not freeze ordinary source titles/concepts that also occur in the prose.
nonisolated enum FruitfolioCitationProtection {
    static func literals(ids: [String], records: [AskSourceRecord]) -> [String] {
        var result: [String] = []
        var seen: Set<String> = []
        func append(_ value: String?) {
            guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  seen.insert(value).inserted else { return }
            result.append(value)
        }
        for id in ids { append(id) }
        for record in records {
            append(record.id)
            append(record.sourceText)
            if let citation = record.sourceText, !citation.isEmpty {
                append(FruitfolioSemanticMarkup.markdown([.init(text: citation)]))
            }
            append(record.doi)
            append(record.urlString)
        }
        return result
    }
}
