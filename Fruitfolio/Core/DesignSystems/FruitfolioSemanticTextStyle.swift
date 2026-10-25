import SwiftUI

enum FruitfolioSemanticEmphasis: String, Codable, Sendable {
    case plain
    case anchorBold
    case spokenItalic
    case symptomOrPracticalUnderline
    case actionableBoldUnderline
    case rareItalicUnderline
    case absoluteBoldItalicUnderline
}

struct FruitfolioSemanticSpan: Identifiable, Equatable, Sendable {
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

        switch span.emphasis {
        case .plain:
            break

        case .anchorBold:
            text = text.bold()

        case .spokenItalic:
            text = text.italic()

        case .symptomOrPracticalUnderline:
            text = text.underline()

        case .actionableBoldUnderline:
            text = text.bold().underline()

        case .rareItalicUnderline:
            text = text.italic().underline()

        case .absoluteBoldItalicUnderline:
            text = text.bold().italic().underline()
        }

        return text
    }
}
