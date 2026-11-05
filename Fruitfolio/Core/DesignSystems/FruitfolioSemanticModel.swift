import Foundation

enum FruitfolioSemanticEmphasis: String, Codable, Sendable {
    case plain
    case anchorBold
    case anchorBoldSpokenItalic
    case spokenItalic
    case symptomOrPracticalUnderline
    case actionableBoldUnderline
    case rareItalicUnderline
    case absoluteBoldItalicUnderline
}

struct FruitfolioSemanticSpan: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let text: String
    let emphasis: FruitfolioSemanticEmphasis

    init(
        id: UUID = UUID(),
        text: String,
        emphasis: FruitfolioSemanticEmphasis = .plain
    ) {
        self.id = id
        self.text = text
        self.emphasis = emphasis
    }
}


/// Prefix/slice operations count user-perceived characters or validated UTF-16
/// ranges without ever exposing partially streamed Markdown delimiters.
enum FruitfolioSemanticSlices {
    static func prefix(_ spans: [FruitfolioSemanticSpan], characterCount: Int) -> [FruitfolioSemanticSpan] {
        var remaining = max(0, characterCount)
        var result: [FruitfolioSemanticSpan] = []
        for span in spans {
            guard remaining > 0 else { break }
            let text = String(span.text.prefix(remaining))
            if !text.isEmpty { result.append(.init(id: span.id, text: text, emphasis: span.emphasis)) }
            remaining -= text.count
        }
        return result
    }

    static func selection(_ spans: [FruitfolioSemanticSpan], utf16Range: NSRange) -> [FruitfolioSemanticSpan] {
        let plain = spans.map(\.text).joined()
        guard utf16Range.location != NSNotFound, utf16Range.length > 0,
              Range(utf16Range, in: plain) != nil else { return [] }
        var offset = 0
        var result: [FruitfolioSemanticSpan] = []
        for span in spans {
            let length = span.text.utf16.count
            let overlap = NSIntersectionRange(utf16Range, NSRange(location: offset, length: length))
            if overlap.length > 0 {
                let local = NSRange(location: overlap.location - offset, length: overlap.length)
                guard let range = Range(local, in: span.text) else { return [] }
                result.append(.init(id: span.id, text: String(span.text[range]), emphasis: span.emphasis))
            }
            offset += length
        }
        return result
    }
}
