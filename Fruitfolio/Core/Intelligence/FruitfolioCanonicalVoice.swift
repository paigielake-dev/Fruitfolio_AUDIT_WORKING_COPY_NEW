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


/// Ephemeral presentation choice from explicit conversational self-report only.
/// Never a diagnosis, persisted emotional profile, research claim or model input.
nonisolated enum FruitfolioConversationalPresentation: String, Sendable, CaseIterable {
    case neutral, gentle, clear, curious, bright, casual

    var prefersCalm: Bool { self == .gentle || self == .clear }

    static func classify(_ question: String) -> Self {
        var text = question.lowercased().replacingOccurrences(of: "’", with: "'")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        for greeting in ["hi, ", "hello, ", "hey, ", "hi! ", "hello! ", "hey! "] where text.hasPrefix(greeting) {
            text.removeFirst(greeting.count); break
        }
        func begins(_ phrase: String, in value: String) -> Bool {
            guard value.hasPrefix(phrase) else { return false }
            guard value.count > phrase.count else { return true }
            let next = value[value.index(value.startIndex, offsetBy: phrase.count)]
            return !next.isLetter && !next.isNumber && next != "_"
        }
        for phrase in ["i don't understand", "this is frustrating", "this is confusing"] where begins(phrase, in: text) {
            return .clear
        }
        for phrase in ["just curious", "i was wondering"] where begins(phrase, in: text) { return .curious }
        for phrase in ["just for fun", "for fun"] where begins(phrase, in: text) { return .casual }
        let moods: [(String, Self)] = [
            ("worried", .gentle), ("anxious", .gentle), ("scared", .gentle), ("afraid", .gentle),
            ("sad", .gentle), ("upset", .gentle), ("embarrassed", .gentle), ("ashamed", .gentle),
            ("frustrated", .clear), ("confused", .clear), ("overwhelmed", .gentle),
            ("curious", .curious), ("interested", .curious), ("excited", .bright)
        ]
        for prefix in ["i'm feeling ", "i am feeling ", "i feel ", "i'm ", "i am "] where text.hasPrefix(prefix) {
            var report = String(text.dropFirst(prefix.count))
            for modifier in ["really ", "very ", "so ", "quite ", "a bit ", "a little "] where report.hasPrefix(modifier) {
                report.removeFirst(modifier.count); break
            }
            guard let (word, primary) = moods.first(where: { begins($0.0, in: report) }) else { return .neutral }
            let remainder = String(report.dropFirst(word.count))
            for connector in [" and also ", " and ", " but "] where remainder.hasPrefix(connector) {
                let secondary = String(remainder.dropFirst(connector.count))
                if moods.contains(where: { $0.1.prefersCalm && begins($0.0, in: secondary) }) { return .gentle }
            }
            return primary
        }
        // Third-person, quoted, negated and unsupported cues stay neutral.
        return .neutral
    }

    /// Scope a recognized introduction only when a clear question follows.
    /// Standalone symptom reports/arbitrary clauses stay intact. The original
    /// question and full safety classification are never replaced by this query.
    static func researchQuestion(_ original: String) -> String {
        guard classify(original) != .neutral else { return original }
        let greeting = #"(?:(?:hi|hello|hey)[,!]\s+)?"#
        let selfReport = #"(?:i(?:['’]m|\s+am)(?:\s+feeling)?|i\s+feel)\s+(?:(?:really|very|so|quite|a\s+bit|a\s+little)\s+)?(?:worried|anxious|scared|afraid|sad|upset|embarrassed|ashamed|frustrated|confused|overwhelmed|curious|interested|excited)\s+about\s+"#
        let conversational = #"(?:just\s+curious|i\s+was\s+wondering|just\s+for\s+fun|for\s+fun)[,:]?\s+(?:about\s+)?"#
        let pattern = #"^\s*"# + greeting + "(?:" + selfReport + "|" + conversational +
            #")((?:how|what|why|whether|when|where|can|does|is|should)\b[\s\S]+)$"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = expression.firstMatch(in: original, range: NSRange(original.startIndex..., in: original)),
              let range = Range(match.range(at: 1), in: original) else { return original }
        return String(original[range])
    }

    func bridge(safety: Prompt34SafetyClassification) -> String {
        switch self {
        case .gentle: return "we can take this one step at a time."
        case .clear: return "let’s keep this clear and step by step."
        default:
            if safety.requiresSeriousTone { return "here is what the approved research supports." }
            switch self {
            case .curious: return "let’s look at how this works."
            case .bright: return "let’s explore this!"
            case .casual: return "let’s take a look."
            default: return "let’s start with what the approved research can support."
            }
        }
    }

    func notice(_ original: String, safety: Prompt34SafetyClassification) -> String {
        guard prefersCalm, !safety.requiresUrgentGuidance else { return original }
        return bridge(safety: safety) + "\n\n" + original
    }
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

    static func compose(excerpts: [String], hasUnansweredParts: Bool, safety: Prompt34SafetyClassification,
                        presentation: FruitfolioConversationalPresentation = .neutral) -> String {
        guard !excerpts.isEmpty else { return presentation.notice(unsupportedMessage, safety: safety) }
        var sections: [String] = []
        if safety.requiresUrgentGuidance { sections.append(Prompt34LocalSafetyRouter.urgentResponseText()) }
        sections.append(presentation.bridge(safety: safety))
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
            return FruitfolioSemanticPolicy.sourceMarkup(original, serious: true)
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
