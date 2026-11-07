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

/// Canonical interchange for explicit semantic spans through local translation.
/// Literal Markdown/control characters are escaped; underline tags are emitted
/// only by the semantic model and protected by the translation envelope.
enum FruitfolioSemanticMarkup {
    static func markdown(_ spans: [FruitfolioSemanticSpan]) -> String {
        spans.map { span in
            var text = span.text
            for character in ["\\", "*", "_", "`", "[", "]", "<", ">"] {
                text = text.replacingOccurrences(of: character, with: "\\" + character)
            }
            switch span.emphasis {
            case .plain: return text
            case .anchorBold: return "**\(text)**"
            case .spokenItalic: return "*\(text)*"
            case .anchorBoldSpokenItalic: return "***\(text)***"
            case .symptomOrPracticalUnderline: return "<u>\(text)</u>"
            case .actionableBoldUnderline: return "<u>**\(text)**</u>"
            case .rareItalicUnderline: return "<u>*\(text)*</u>"
            case .absoluteBoldItalicUnderline: return "<u>***\(text)***</u>"
            }
        }.joined()
    }
}

/// Shared author/model contract. Emphasis follows established meaning; this
/// policy never searches prose for medical keywords or invents emphasis.
enum FruitfolioSemanticPolicy {
    static let generationInstructions = """
    Apply semantic emphasis only after establishing the evidence-bounded meaning of the complete passage. Use **bold** selectively for central informational anchors (conditions, hormones, mechanisms, anatomy, nutrients, treatment concepts, important quantities and scientific concepts). When a food is a meaningful item, bold its complete name, such as **apple slices**. Do not bold every medical noun or repeat nearby anchors automatically.
    Use *italics* only for occasional natural spoken stress, never merely because a phrase is a symptom or scientific term. Use <u>underline</u> for the smallest meaningful symptom phrase or practical/qualifying clue when recognition improves comprehension. These tags are semantic annotations; do not output other HTML.
    Combine styles only when their independent meanings both apply. Bold+underline is rare; italic+underline is very rare. Triple emphasis is reserved for the exact words not, never or every, and only when the context truly warrants that emphasis. Never decorate a whole paragraph. Evaluate the whole passage and choose the smallest useful set of emphasized phrases; no per-sentence or per-paragraph quotas. Serious or safety-critical content must remain calm, with restrained informational emphasis and no playful vocal stress. Preserve all scientific claims, uncertainty, numbers, units and evidence IDs exactly; formatting must never change substantive meaning.
    """

    /// Review is tied to the complete source context, never to word occurrence.
    /// This method cannot add or omit source words, quantities or qualifiers.
    static func reviewedSourceSpans(_ original: String, serious: Bool = false) -> [FruitfolioSemanticSpan] {
        guard let review = FruitfolioReviewedSemanticContexts.passages.first(where: { $0.originalText.utf8.elementsEqual(original.utf8) }),
              review.spans.map(\.text).joined().utf8.elementsEqual(original.utf8) else {
            return [.init(text: original)]
        }
        return normalized(review.spans, serious: serious)
    }

    static func sourceMarkup(_ original: String, serious: Bool = false) -> String {
        FruitfolioSemanticMarkup.markdown(reviewedSourceSpans(original, serious: serious))
    }

    static func normalized(_ spans: [FruitfolioSemanticSpan], serious: Bool = false) -> [FruitfolioSemanticSpan] {
        spans.map { span in
            var emphasis = span.emphasis
            if emphasis == .absoluteBoldItalicUnderline {
                let word = span.text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                if !["not", "never", "every"].contains(word) { emphasis = .actionableBoldUnderline }
            }
            if serious {
                switch emphasis {
                case .spokenItalic: emphasis = .plain
                case .anchorBoldSpokenItalic: emphasis = .anchorBold
                case .rareItalicUnderline: emphasis = .symptomOrPracticalUnderline
                case .absoluteBoldItalicUnderline: emphasis = .actionableBoldUnderline
                default: break
                }
            }
            return .init(id: span.id, text: span.text, emphasis: emphasis)
        }
    }
}
