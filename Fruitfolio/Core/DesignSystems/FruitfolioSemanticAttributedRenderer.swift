import Foundation
import UIKit

/// Canonical role interpretation, consumed by both SwiftUI and selectable UIKit text.
nonisolated struct FruitfolioSemanticTraits {
    let bold: Bool
    let italic: Bool
    let underline: Bool
}

extension FruitfolioSemanticEmphasis {
    var traits: FruitfolioSemanticTraits {
        switch self {
        case .plain: return .init(bold: false, italic: false, underline: false)
        case .anchorBold: return .init(bold: true, italic: false, underline: false)
        case .spokenItalic: return .init(bold: false, italic: true, underline: false)
        case .symptomOrPracticalUnderline: return .init(bold: false, italic: false, underline: true)
        case .actionableBoldUnderline: return .init(bold: true, italic: false, underline: true)
        case .rareItalicUnderline: return .init(bold: false, italic: true, underline: true)
        case .absoluteBoldItalicUnderline: return .init(bold: true, italic: true, underline: true)
        }
    }
}

extension FruitfolioSemanticDocument {
    /// Uses the actual selected occurrence, not a search for possibly repeated words.
    func slice(utf16Range range: NSRange) -> FruitfolioSemanticDocument? {
        let text = plainText
        guard range.location != NSNotFound, range.length > 0,
              let selected = Range(range, in: text) else { return nil }
        let boundaries = Set(text.indices).union([text.endIndex])
        guard boundaries.contains(selected.lowerBound), boundaries.contains(selected.upperBound) else { return nil }
        let lower = text.distance(from: text.startIndex, to: selected.lowerBound)
        let upper = lower + text[selected].count
        var offset = 0
        var result: [FruitfolioSemanticSpan] = []
        for span in spans {
            let end = offset + span.text.count
            let a = max(offset, lower), b = min(end, upper)
            if a < b {
                let start = span.text.index(span.text.startIndex, offsetBy: a - offset)
                let finish = span.text.index(span.text.startIndex, offsetBy: b - offset)
                result.append(.init(id: span.id, text: String(span.text[start..<finish]), emphasis: span.emphasis))
            }
            offset = end
        }
        return .init(spans: result)
    }
}

@MainActor
enum FruitfolioSemanticAttributedRenderer {
    static func render(_ document: FruitfolioSemanticDocument, traits: UITraitCollection? = nil) -> NSAttributedString {
        let base = UIFont(name: "ChalkboardSE-Regular", size: 16) ?? .systemFont(ofSize: 16)
        let scaled = UIFontMetrics(forTextStyle: .body).scaledFont(for: base, compatibleWith: traits)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let color = UIColor(red: 128.0 / 255, green: 0, blue: 0, alpha: 1)
        let result = NSMutableAttributedString(string: "")
        for span in document.spans {
            let roles = span.emphasis.traits
            var descriptor = scaled.fontDescriptor
            if roles.bold, let bold = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitBold)) {
                descriptor = bold
            }
            if roles.italic {
                if let italic = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) {
                    descriptor = italic
                } else {
                    // Synthetic oblique preserves the approved family when it has no italic face.
                    descriptor = descriptor.addingAttributes([.matrix: NSValue(cgAffineTransform: CGAffineTransform(a: 1, b: 0, c: -0.18, d: 1, tx: 0, ty: 0))])
                }
            }
            var attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont(descriptor: descriptor, size: scaled.pointSize),
                .foregroundColor: color, .paragraphStyle: paragraph
            ]
            if roles.underline { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            result.append(NSAttributedString(string: span.text, attributes: attributes))
        }
        return result
    }
}
