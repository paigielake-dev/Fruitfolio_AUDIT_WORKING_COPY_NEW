import Foundation

/// Presentation follows evidence validation. This authority never paraphrases,
/// lowercases, shortens, or decorates immutable scientific quotations/citations.
nonisolated enum FruitfolioCanonicalVoice {
    static let evidenceBridge = "here’s what the library supports for this question."
    static let carefulEvidenceBridge = "here’s the supported information, with the limits kept clear."

    static func evidenceDocument(_ supportedBody: String, serious: Bool) -> FruitfolioSemanticDocument {
        guard !supportedBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .init(spans: [])
        }
        return .init(spans: [
            .init(text: serious ? carefulEvidenceBridge : evidenceBridge, emphasis: .plain),
            .init(text: "\n\n", emphasis: .plain),
            .init(text: supportedBody, emphasis: .plain)
        ])
    }
}

nonisolated enum FruitfolioKaomojiDomain: Sendable {
    case generalEducation, serious, urgent, labInterpretation, abuseOrConsent
    case fruitBasketQuestion, fruitBasketReveal
}

nonisolated enum FruitfolioEmotionalBeat: CaseIterable, Sendable {
    case pleased, affectionate, curious, playful, surprised, sympathetic, awkward, celebratory, calm
}

/// Explicitly authored emotional intent is required. No keyword replacement,
/// random probability, quota-driven insertion, or persistent question history.
/// Nearby choices are retained in memory only, without health/question content.
nonisolated struct FruitfolioKaomojiSystem: Sendable {
    static let absoluteMaximum = 3
    static let usualMaximum = 1
    static let longerPlayfulMaximum = 2
    private(set) var recent: [String] = []

    static func approvedForms(for beat: FruitfolioEmotionalBeat) -> [String] {
        switch beat {
        case .pleased: return ["^___^", "^_____^", "^‿^", "^◡^", "^ᴗ^", "^_^", "( ^ ᴗ ^ )", "( ^ v ^ )"]
        case .affectionate: return ["( ´ ᴗ \\ )", "( ´ ◡ ` )", "( . ᴗ . )", "( . v . )", "♡", "<3", "<33"]
        case .curious: return ["( • ᴗ • )", "( • ▿ • )", "( o ᴗ o )", "^o^ ?", "( ˙ ᴗ ˙ ) ?"]
        case .playful: return ["^___− ~ ☆", ":-)", ":3", "( ´ ▿ \\ )", "^_^;"]
        case .surprised: return ["o_o", "O_O", "0_0", "( ° ᴗ ° )", "( ° v ° )"]
        case .sympathetic: return [":,)", "(つ_ _)つ"]
        case .awkward: return ["._.", "._.?", "-____-", ">____<", "^____^;"]
        case .celebratory: return ["^o^", ":-D", "☆_☆", "^___^ ☆", "<333", "☆"]
        case .calm: return ["( ˘ ᴗ ˘ )", "( ˘ - ˘ )", "^◡^", "^ᴗ^"]
        }
    }

    mutating func choose(for beat: FruitfolioEmotionalBeat?, domain: FruitfolioKaomojiDomain,
                         usedInAnswer: [String] = [], longerPlayful: Bool = false,
                         unusuallyCasual: Bool = false, allowRareExpression: Bool = false) -> String? {
        guard case .generalEducation = domain, let beat else { return nil }
        let limit = unusuallyCasual ? Self.absoluteMaximum : (longerPlayful ? Self.longerPlayfulMaximum : Self.usualMaximum)
        guard usedInAnswer.count < limit else { return nil }
        // These beats require deliberate rare-expression approval by the caller;
        // matching a word in an answer is never sufficient.
        switch beat {
        case .surprised, .awkward, .celebratory:
            guard allowRareExpression else { return nil }
        default: break
        }
        let intense: Set<String> = ["O_O", "0_0", ">_<", "☆_☆", "<333", "^___^ ☆"]
        let permitted = Self.approvedForms(for: beat).filter {
            !usedInAnswer.contains($0) && (allowRareExpression || !intense.contains($0))
        }
        guard let selected = permitted.first(where: { !recent.contains($0) }) else { return nil }
        recent.append(selected)
        recent = Array(recent.suffix(4))
        return selected
    }
}
