import SwiftUI
import UIKit

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

    init(markdown: String, baseFont: Font = .body, color: Color? = nil) {
        self.init(spans: FruitfolioSemanticDocument.spans(from: markdown), baseFont: baseFont, color: color)
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

        case .anchorBoldSpokenItalic:
            text = text.bold().italic()

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

/// Emphasis comes from explicit author/model markup or structured spans, never
/// from a symptom/hormone keyword lookup. Unknown prose remains plain.
enum FruitfolioSemanticDocument {
    static func spans(from markdown: String) -> [FruitfolioSemanticSpan] {
        guard let parsed = try? AttributedString(
            markdown: markdown,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) else { return [.init(text: markdown)] }
        return parsed.runs.map { run in
            let intent = run.inlinePresentationIntent ?? []
            let bold = intent.contains(.stronglyEmphasized)
            let italic = intent.contains(.emphasized)
            let emphasis: FruitfolioSemanticEmphasis
            if bold && italic { emphasis = .anchorBoldSpokenItalic }
            else if bold { emphasis = .anchorBold }
            else if italic { emphasis = .spokenItalic }
            else { emphasis = .plain }
            return .init(text: String(parsed[run.range].characters), emphasis: emphasis)
        }
    }

    static func plainText(from markdown: String) -> String {
        spans(from: markdown).map(\.text).joined()
    }
}

@MainActor
enum FruitfolioSemanticRenderer {
    static func attributed(markdown: String, font: UIFont, color: UIColor) -> NSAttributedString {
        attributed(spans: FruitfolioSemanticDocument.spans(from: markdown), font: font, color: color)
    }

    static func attributed(spans: [FruitfolioSemanticSpan], font: UIFont, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString(string: "")
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        for span in spans {
            let bold = [FruitfolioSemanticEmphasis.anchorBold, .anchorBoldSpokenItalic,
                        .actionableBoldUnderline, .absoluteBoldItalicUnderline].contains(span.emphasis)
            let italic = [FruitfolioSemanticEmphasis.spokenItalic, .anchorBoldSpokenItalic,
                          .rareItalicUnderline, .absoluteBoldItalicUnderline].contains(span.emphasis)
            let underline = [FruitfolioSemanticEmphasis.symptomOrPracticalUnderline,
                             .actionableBoldUnderline, .rareItalicUnderline,
                             .absoluteBoldItalicUnderline].contains(span.emphasis)
            var traits = font.fontDescriptor.symbolicTraits
            if bold { traits.insert(.traitBold) }
            if italic { traits.insert(.traitItalic) }
            let descriptor = font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
            var attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(descriptor: descriptor, size: font.pointSize),
                .foregroundColor: color, .paragraphStyle: paragraph
            ]
            if underline { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            result.append(NSAttributedString(string: span.text, attributes: attributes))
        }
        return result
    }
}
