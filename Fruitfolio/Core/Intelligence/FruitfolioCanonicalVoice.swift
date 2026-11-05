import Foundation

enum Prompt54CanonicalVoicePolicy {
    static let maximumKaomojiPerAnswer = 3
    static let preferredKaomojiRange = 0...1
    static let seriousContentUsesKaomoji = false
    static let symptomsMustBeUnderlined = true
    static let foodNamesAreBolded = true
    static let evidenceMustFollowHumanBridge = true
    static let allowsInfluencerTherapyCliches = false
}


/// Shared framing for normal generation and deterministic research fallbacks.
/// Source claims keep their original scientific case, numbers and qualifiers.
nonisolated enum FruitfolioCanonicalAnswerVoice {
    static let generationInstructions = """
    Use FruitsofLife.xo's human-bridge → clean-evidence structure. Keep framing lowercase except proper names, abbreviations and scientific notation. Use familiar words, contractions, direct reader address and restrained warmth. Do not diagnose the reader's feelings. Avoid influencer/therapy clichés, sales language, generic AI introductions and exaggerated certainty. Use ☆ for main points and - for supporting points when the structure warrants it.
    Kaomojis are rare emotional punctuation: ordinary answers usually use 0–1, long playful answers may use 0–2, and 3 is an exceptional absolute maximum. Never repeat one nearby. Serious, urgent, safety-critical, abuse/consent and laboratory-interpretation content uses zero. Fruit Basket questions and reveal facts use zero. Preserve the founder Guide's plain, conversational teaching rhythm without borrowing new health facts from style references.
    Every claim must preserve a complete supplied evidence paragraph, including all qualifiers, quantities and units. You may add canonical semantic emphasis without changing its words. Do not shorten a paragraph into a misleading fragment or paraphrase a scientific relationship that has not been independently validated. Set bridge and limitation to null; Fruitfolio supplies consistent, safe framing after evidence validation.
    """

    static let unsupportedMessage = "i don’t have enough approved research to answer that reliably yet."

    static func compose(excerpts: [String], hasUnansweredParts: Bool, safety: Prompt34SafetyClassification) -> String {
        guard !excerpts.isEmpty else { return unsupportedMessage }
        var sections: [String] = []
        if safety.requiresUrgentGuidance { sections.append(Prompt34LocalSafetyRouter.urgentResponseText()) }
        sections.append(safety.requiresSeriousTone
            ? "here is what the approved research supports."
            : "let’s start with what the approved research can support.")
        sections.append(excerpts.map { "☆ " + $0 }.joined(separator: "\n\n"))
        if hasUnansweredParts {
            sections.append("i can share the supported part here, but this material doesn’t resolve every part reliably.")
        }
        return sections.joined(separator: "\n\n")
    }
}

/// A token overlap is not medical entailment. Until a validated paraphrase
/// verifier exists, generated factual prose must preserve complete evidence.
nonisolated enum FruitfolioEvidenceCopyPolicy {
    static func matchesCompleteEvidence(_ generated: String, original: String) -> Bool {
        validatedPresentation(generated, original: original) != nil
    }

    static func validatedPresentation(_ generated: String, original: String) -> String? {
        if normalize(generated) == normalize(original) {
            // Raw scientific operators/underscores are literal source text,
            // not an invitation for Markdown to reinterpret the expression.
            return FruitfolioSemanticMarkup.markdown([.init(text: original)])
        }
        guard normalize(plainCanonicalMarkup(generated)) == normalize(original) else { return nil }
        return generated
    }

    private static func normalize(_ text: String) -> String {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
    }

    private static func plainCanonicalMarkup(_ text: String) -> String {
        var plain = text.replacingOccurrences(of: "<u>", with: "").replacingOccurrences(of: "</u>", with: "")
        for pattern in [#"\*\*\*(.+?)\*\*\*"#, #"\*\*(.+?)\*\*"#, #"\*(.+?)\*"#] {
            plain = plain.replacingOccurrences(of: pattern, with: "$1", options: .regularExpression)
        }
        return plain
    }
}
