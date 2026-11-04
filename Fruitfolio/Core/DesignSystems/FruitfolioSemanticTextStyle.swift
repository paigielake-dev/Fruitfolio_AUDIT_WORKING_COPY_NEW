import SwiftUI
import Foundation

nonisolated enum FruitfolioSemanticEmphasis: String, Codable, Sendable {
    case plain
    case anchorBold
    case spokenItalic
    case anchorSpokenBoldItalic
    case symptomOrPracticalUnderline
    case actionableBoldUnderline
    case rareItalicUnderline
    case absoluteBoldItalicUnderline
}

nonisolated struct FruitfolioSemanticSpan: Identifiable, Hashable, Codable, Sendable {
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

/// Structured meaning survives storage and progressive display without parsing
/// partial Markdown or applying word-matching rules after rendering.
nonisolated struct FruitfolioSemanticDocument: Codable, Hashable, Sendable {
    let spans: [FruitfolioSemanticSpan]

    var plainText: String { spans.map(\.text).joined() }

    func prefix(characters count: Int) -> FruitfolioSemanticDocument {
        // Count graphemes in the complete document. A combining mark or ZWJ
        // sequence can legally continue across separately styled spans.
        let prefix = plainText.prefix(max(0, count))
        guard !prefix.isEmpty else { return .init(spans: []) }
        return sliceAtValidatedUTF16Range(NSRange(location: 0, length: prefix.utf16.count))
    }

    /// Uses the selected occurrence, with global grapheme boundaries. UTF-16
    /// intersections preserve exact text even when a cluster spans styles.
    func slice(utf16Range range: NSRange) -> FruitfolioSemanticDocument? {
        let text = plainText
        let length = text.utf16.count
        guard range.location != NSNotFound, range.location >= 0, range.length > 0,
              range.location <= length, range.length <= length - range.location,
              let selected = Range(range, in: text) else { return nil }
        let boundaries = Set(text.indices).union([text.endIndex])
        guard boundaries.contains(selected.lowerBound), boundaries.contains(selected.upperBound) else { return nil }
        return sliceAtValidatedUTF16Range(range)
    }

    private func sliceAtValidatedUTF16Range(_ range: NSRange) -> FruitfolioSemanticDocument {
        var offset = 0
        var result: [FruitfolioSemanticSpan] = []
        for span in spans {
            let text = span.text as NSString
            let intersection = NSIntersectionRange(NSRange(location: offset, length: text.length), range)
            if intersection.length > 0 {
                let local = NSRange(location: intersection.location - offset, length: intersection.length)
                result.append(.init(id: span.id, text: text.substring(with: local), emphasis: span.emphasis))
            }
            offset += text.length
        }
        return .init(spans: result)
    }
}

@MainActor
struct FruitfolioSemanticText: View {
    let spans: [FruitfolioSemanticSpan]
    let baseFont: Font
    let color: Color

    init(
        spans: [FruitfolioSemanticSpan],
        baseFont: Font = .body,
        color: Color? = nil
    ) {
        self.spans = spans
        self.baseFont = baseFont
        self.color = color ?? DesignTokens.ColorToken.primaryBurgundy
    }

    init(document: FruitfolioSemanticDocument, baseFont: Font = .body, color: Color? = nil) {
        self.init(spans: document.spans, baseFont: baseFont, color: color)
    }

    var body: some View {
        spans.reduce(Text("")) { partial, span in
            Text("\(partial)\(styled(span))")
        }
        .font(baseFont)
        .foregroundStyle(color)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func styled(_ span: FruitfolioSemanticSpan) -> Text {
        var text = Text(verbatim: span.text)

        let roles = span.emphasis.traits
        if roles.bold { text = text.bold() }
        if roles.italic { text = text.italic() }
        if roles.underline { text = text.underline() }

        return text
    }
}

/// Author-declared meaning, shared by every presentation surface. These are
/// explicit annotations on authored copy, never a keyword-based medical styler.
nonisolated struct FruitfolioSemanticAnnotation: Sendable {
    let phrase: String
    let emphasis: FruitfolioSemanticEmphasis
}

extension FruitfolioSemanticDocument {
    static func authored(_ text: String, annotations: [FruitfolioSemanticAnnotation]) -> FruitfolioSemanticDocument {
        var roles = Array(repeating: 0, count: text.count)
        let characters = Array(text)
        func bits(_ role: FruitfolioSemanticEmphasis) -> Int {
            switch role {
            case .plain: return 0
            case .anchorBold: return 1
            case .spokenItalic: return 2
            case .anchorSpokenBoldItalic: return 3
            case .symptomOrPracticalUnderline: return 4
            case .actionableBoldUnderline: return 5
            case .rareItalicUnderline: return 6
            case .absoluteBoldItalicUnderline: return 7
            }
        }
        let roleByBits: [FruitfolioSemanticEmphasis] = [.plain, .anchorBold, .spokenItalic,
            .anchorSpokenBoldItalic, .symptomOrPracticalUnderline, .actionableBoldUnderline,
            .rareItalicUnderline, .absoluteBoldItalicUnderline]
        for annotation in annotations where !annotation.phrase.isEmpty {
            var search = text.startIndex..<text.endIndex
            while let range = text.range(of: annotation.phrase, options: .literal, range: search) {
                let start = text.distance(from: text.startIndex, to: range.lowerBound)
                let end = text.distance(from: text.startIndex, to: range.upperBound)
                for index in start..<end { roles[index] |= bits(annotation.emphasis) }
                if range.upperBound == text.endIndex { break }
                search = range.upperBound..<text.endIndex
            }
        }
        var spans: [FruitfolioSemanticSpan] = []
        var start = 0
        while start < characters.count {
            var end = start + 1
            while end < characters.count && roles[end] == roles[start] { end += 1 }
            spans.append(.init(text: String(characters[start..<end]), emphasis: roleByBits[roles[start]]))
            start = end
        }
        return .init(spans: spans)
    }
}
