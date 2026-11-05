import Foundation

nonisolated enum FruitfolioEvidencePromptBuilder {
    static let maximumNoteParagraphs = 6
    static let maximumSourceParagraphs = 4

    static func prompt(question: String, evidence: FruitfolioEvidencePacket) -> String {
        let outputLanguage = "English"
        return """
        You are Fruitfolio's local synthesis layer. Write all user-facing bridge, claim, and limitation text in \(outputLanguage), while preserving the exact scientific meaning of the approved evidence and leaving evidence IDs unchanged. Use ONLY the supplied approved evidence for substantive health or scientific claims. Do not supplement from pretrained knowledge. Do not invent facts, user biology, diagnoses, citations, authors, dates, URLs, or study details. If evidence supports only part of the question, answer only that part and state the limitation. Keep recorded, calculated, estimated, predicted, educational, and user-reported information distinct. Classify emphasis by meaning and emit only the canonical annotations described below. Serious health content must be calm and non-playful.

        \(FruitfolioCanonicalAnswerVoice.generationInstructions)

        \(FruitfolioSemanticPolicy.generationInstructions)

        Return ONLY valid JSON matching this exact shape:
        {"bridge":"optional short human bridge or null","claims":[{"text":"one evidence-bounded claim","evidenceIDs":["NOTE_OR_SOURCE_ID"]}],"limitation":"optional honest limitation or null"}

        Every substantive claim MUST include one or more evidenceIDs copied exactly from the permitted evidence IDs below. Never create an evidence ID. If a requested part is unsupported, omit that claim and put the limitation in limitation. Do not include a Sources section; Fruitfolio renders verified sources deterministically.

        \(context(question: question, evidence: evidence))
        Produce concise Fruitfolio-language content inside the JSON fields only.
        """
    }

    static func selectionPrompt(question: String, evidence: FruitfolioEvidencePacket, maximumClaims: Int = 3) -> String {
        """
        Select the complete approved evidence paragraphs that most directly answer the user's question. Return only JSON with this exact shape:
        {"evidenceIDs":["PERMITTED_NOTE_OR_SOURCE_ID"]}
        Choose zero to \(maximumClaims) distinct IDs in order of relevance. Copy IDs exactly from the permitted claim/evidence boundary. Do not invent an ID, facts, diagnoses, citations, bridges or limitations. If no supplied paragraph answers the question, return an empty array. Fruitfolio reconstructs the original scientific text and applies its shared voice after validation; do not regenerate that text here.

        \(context(question: question, evidence: evidence))
        """
    }

    private static func context(question: String, evidence: FruitfolioEvidencePacket) -> String {
        let noteText =
            evidence
                .researchNoteChunks
                .prefix(maximumNoteParagraphs)
                .map {
                    """
                    [NOTE \($0.chunkID)]
                    \($0.text)
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        let sourceText =
            evidence
                .sourceChunks
                .prefix(maximumSourceParagraphs)
                .map {
                    """
                    [SOURCE \($0.sourceChunkID)]
                    \($0.text)
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        let claimMapText = evidence.claimEvidenceMap
            .map { item in
                let ids = item.noteChunkIDs + item.sourceChunkIDs
                return "[CLAIM \(item.claim.id)] \(item.claim.text)\nPERMITTED EVIDENCE IDS: \(ids.joined(separator: ", "))"
            }
            .joined(separator: "\n\n")

        let trackerContext: String
        if let context = evidence.permittedContext {
            trackerContext = """
            predictionConfidence=\(context.predictionConfidence ?? "unknown")
            reasonCode=\(context.reasonCode ?? "unknown")
            trackingGoal=\(context.trackingGoal ?? "unknown")
            reproductiveStage=\(context.reproductiveStage ?? "unknown")
            cycleHealthContext=\(context.cycleHealthContext ?? "unknown")
            """
        } else {
            trackerContext = "[none supplied]"
        }

        return """
        USER QUESTION:
        \(question)

        SAFETY CLASSIFICATION:
        \(evidence.safetyClassification.level.rawValue)

        PERMITTED BOUNDED TRACKER CONTEXT:
        \(trackerContext)

        CLAIM / EVIDENCE BOUNDARY:
        \(claimMapText)

        APPROVED RESEARCH NOTES:
        \(noteText)

        APPROVED SOURCE EXCERPTS:
        \(sourceText.isEmpty ? "[none supplied]" : sourceText)

        """
    }
}

// MARK: - Deterministic generated-claim validation

nonisolated enum FruitfolioGeneratedDraftValidator {
    struct ValidatedAnswer: Sendable {
        let text: String
        let usedEvidenceIDs: Set<String>
    }

    static func validatedText(draft: FruitfolioGeneratedDraft, evidence: FruitfolioEvidencePacket) -> String? {
        validatedAnswer(draft: draft, evidence: evidence)?.text
    }

    static func validatedAnswer(draft: FruitfolioGeneratedDraft, evidence: FruitfolioEvidencePacket) -> ValidatedAnswer? {
        let noteIDs = evidence.researchNoteChunks.map(\.chunkID)
        let sourceIDs = evidence.sourceChunks.map(\.sourceChunkID)
        let claimIDs = evidence.claimEvidenceMap.map(\.claim.id)
        guard Set(noteIDs + sourceIDs).count == noteIDs.count + sourceIDs.count,
              Set(claimIDs).count == claimIDs.count else { return nil }
        let textByID = Dictionary(uniqueKeysWithValues:
            evidence.researchNoteChunks.map { ($0.chunkID, $0.text) } + evidence.sourceChunks.map { ($0.sourceChunkID, $0.text) })
        var answeredNeeds: Set<String> = []
        var usedEvidenceIDs: Set<String> = []
        var seenPresentations: Set<String> = []
        let surviving = draft.claims.compactMap { generated -> String? in
            let tokens = FruitfolioQueryNormalizer.tokens(generated.text)
            let cited = Set(generated.evidenceIDs)
            guard !tokens.isEmpty, !cited.isEmpty, cited.allSatisfy({ textByID[$0] != nil }) else { return nil }
            let matchingNeeds = evidence.claimEvidenceMap.filter { item in
                let allowed = Set(item.noteChunkIDs + item.sourceChunkIDs)
                return cited.isSubset(of: allowed) && !tokens.intersection(FruitfolioQueryNormalizer.tokens(item.claim.text)).isEmpty
            }
            guard !matchingNeeds.isEmpty else { return nil }
            let matches: [(String, String)] = cited.sorted().compactMap { id in
                textByID[id].flatMap { text in
                    FruitfolioEvidenceCopyPolicy.validatedPresentation(generated.text, original: text).map { (id, $0) }
                }
            }
            guard let presentation = matches.first?.1 else { return nil }
            usedEvidenceIDs.formUnion(matches.map { $0.0 })
            answeredNeeds.formUnion(matchingNeeds.map(\.claim.id))
            guard seenPresentations.insert(presentation).inserted else { return nil }
            return presentation
        }
        guard !surviving.isEmpty else { return nil }
        // Free-form bridge/limitation fields cannot bypass evidence validation.
        return ValidatedAnswer(text: FruitfolioCanonicalAnswerVoice.compose(excerpts: surviving,
            hasUnansweredParts: answeredNeeds.count < evidence.claimEvidenceMap.count,
            safety: evidence.safetyClassification), usedEvidenceIDs: usedEvidenceIDs)
    }
}

/// Constrained native selection of complete permitted evidence. JSON grammar
/// cannot introduce a new factual sentence or an invented evidence identifier.
nonisolated enum FruitfolioEvidenceDecodingGrammar {
    private static func jsonString(_ value: String) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return String(decoding: try encoder.encode(value), as: UTF8.self)
    }

    private static func claimObject(id: String, text: String) throws -> String {
        "{\"text\":" + (try jsonString(text)) + ",\"evidenceIDs\":[" + (try jsonString(id)) + "]}"
    }

    static func singleClaimDraftJSON(id: String, text: String) throws -> String {
        "{\"bridge\":null,\"claims\":[" + (try claimObject(id: id, text: text)) + "],\"limitation\":null}"
    }

    static func singleSelectionJSON(id: String) throws -> String {
        "{\"evidenceIDs\":[" + (try jsonString(id)) + "]}"
    }

    static func make(evidence: FruitfolioEvidencePacket, maximumClaims: Int = 3) throws -> String {
        let permitted = Set(evidence.claimEvidenceMap.flatMap { $0.noteChunkIDs + $0.sourceChunkIDs })
        let entries = evidence.researchNoteChunks.map(\.chunkID) + evidence.sourceChunks.map(\.sourceChunkID)
        let literals = try entries.filter { permitted.contains($0) }.map { try jsonString(jsonString($0)) }
        let emptyRoot = try jsonString("{\"evidenceIDs\":[]}")
        guard !literals.isEmpty, maximumClaims > 0 else { return "root ::= " + emptyRoot + "\n" }
        let prefix = try jsonString("{\"evidenceIDs\":[")
        let suffix = try jsonString("]}")
        let repeatLimit = min(3, maximumClaims, literals.count) - 1
        return "root ::= " + prefix + " (evidence-id (\",\" evidence-id){0," + String(repeatLimit) + "})? " + suffix + "\nevidence-id ::= " + literals.joined(separator: " | ") + "\n"
    }
}

nonisolated enum FruitfolioEvidenceSelectionDecoder {
    enum Failure: Error { case invalidSelection }
    private struct Selection: Decodable { let evidenceIDs: [String] }

    static func draft(from data: Data, evidence: FruitfolioEvidencePacket, maximumClaims: Int) throws -> FruitfolioGeneratedDraft {
        let selection = try JSONDecoder().decode(Selection.self, from: data)
        guard selection.evidenceIDs.count <= maximumClaims else { throw Failure.invalidSelection }
        let permitted = Set(evidence.claimEvidenceMap.flatMap { $0.noteChunkIDs + $0.sourceChunkIDs })
        let entries = evidence.researchNoteChunks.map { ($0.chunkID, $0.text) } + evidence.sourceChunks.map { ($0.sourceChunkID, $0.text) }
        guard Set(entries.map { $0.0 }).count == entries.count else { throw Failure.invalidSelection }
        let textByID = Dictionary(uniqueKeysWithValues: entries)
        var seen: Set<String> = []
        var claims: [FruitfolioGeneratedClaim] = []
        for id in selection.evidenceIDs {
            guard permitted.contains(id), let text = textByID[id] else { throw Failure.invalidSelection }
            if seen.insert(id).inserted { claims.append(.init(text: text, evidenceIDs: [id])) }
        }
        return FruitfolioGeneratedDraft(bridge: nil, claims: claims, limitation: nil)
    }
}
