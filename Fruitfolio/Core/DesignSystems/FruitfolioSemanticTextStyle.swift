import SwiftUI

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
        var remaining = max(0, count)
        var result: [FruitfolioSemanticSpan] = []
        for span in spans {
            guard remaining > 0 else { break }
            let text = String(span.text.prefix(remaining))
            if !text.isEmpty {
                result.append(.init(id: span.id, text: text, emphasis: span.emphasis))
                remaining -= text.count
            }
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
