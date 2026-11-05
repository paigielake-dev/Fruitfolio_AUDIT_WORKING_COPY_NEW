import Foundation

nonisolated enum FruitfolioEvidencePromptBuilder {
    static func prompt(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) -> String {
        let noteText =
            evidence
                .researchNoteChunks
                .prefix(6)
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
                .prefix(4)
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

        // The evidence validator and stored scientific source use English.
        // MADLAD owns display localization after validation; UI language must not
        // silently relabel already-translated model output as English source.
        let outputLanguage = "English"

        return """
        You are Fruitfolio's local synthesis layer. Write all user-facing bridge, claim, and limitation text in \(outputLanguage), while preserving the exact scientific meaning of the approved evidence and leaving evidence IDs unchanged. Use ONLY the supplied approved evidence for substantive health or scientific claims. Do not supplement from pretrained knowledge. Do not invent facts, user biology, diagnoses, citations, authors, dates, URLs, or study details. If evidence supports only part of the question, answer only that part and state the limitation. Keep recorded, calculated, estimated, predicted, educational, and user-reported information distinct. Classify emphasis by meaning and emit only the canonical annotations described below. Serious health content must be calm and non-playful.

        \(FruitfolioCanonicalAnswerVoice.generationInstructions)

        \(FruitfolioSemanticPolicy.generationInstructions)

        Return ONLY valid JSON matching this exact shape:
        {"bridge":"optional short human bridge or null","claims":[{"text":"one evidence-bounded claim","evidenceIDs":["NOTE_OR_SOURCE_ID"]}],"limitation":"optional honest limitation or null"}

        Every substantive claim MUST include one or more evidenceIDs copied exactly from the permitted evidence IDs below. Never create an evidence ID. If a requested part is unsupported, omit that claim and put the limitation in limitation. Do not include a Sources section; Fruitfolio renders verified sources deterministically.

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

        Produce concise Fruitfolio-language content inside the JSON fields only.
        """
    }
}

// MARK: - Deterministic generated-claim validation

nonisolated enum FruitfolioGeneratedDraftValidator {
    static func validatedText(draft: FruitfolioGeneratedDraft, evidence: FruitfolioEvidencePacket) -> String? {
        let noteIDs = evidence.researchNoteChunks.map(\.chunkID)
        let sourceIDs = evidence.sourceChunks.map(\.sourceChunkID)
        let claimIDs = evidence.claimEvidenceMap.map(\.claim.id)
        guard Set(noteIDs + sourceIDs).count == noteIDs.count + sourceIDs.count,
              Set(claimIDs).count == claimIDs.count else { return nil }
        let textByID = Dictionary(uniqueKeysWithValues:
            evidence.researchNoteChunks.map { ($0.chunkID, $0.text) } + evidence.sourceChunks.map { ($0.sourceChunkID, $0.text) })
        var answeredNeeds: Set<String> = []
        let surviving = draft.claims.compactMap { generated -> String? in
            let tokens = FruitfolioQueryNormalizer.tokens(generated.text)
            let cited = Set(generated.evidenceIDs)
            guard !tokens.isEmpty, !cited.isEmpty, cited.allSatisfy({ textByID[$0] != nil }) else { return nil }
            let matchingNeeds = evidence.claimEvidenceMap.filter { item in
                let allowed = Set(item.noteChunkIDs + item.sourceChunkIDs)
                return cited.isSubset(of: allowed) && !tokens.intersection(FruitfolioQueryNormalizer.tokens(item.claim.text)).isEmpty
            }
            guard !matchingNeeds.isEmpty else { return nil }
            let presentations = cited.sorted().compactMap { id in
                textByID[id].flatMap { FruitfolioEvidenceCopyPolicy.validatedPresentation(generated.text, original: $0) }
            }
            guard let presentation = presentations.first else { return nil }
            answeredNeeds.formUnion(matchingNeeds.map(\.claim.id))
            return presentation
        }
        guard !surviving.isEmpty else { return nil }
        // Free-form bridge/limitation fields cannot bypass evidence validation.
        return FruitfolioCanonicalAnswerVoice.compose(excerpts: surviving,
            hasUnansweredParts: answeredNeeds.count < evidence.claimEvidenceMap.count,
            safety: evidence.safetyClassification)
    }
}

/// Constrained native selection of complete permitted evidence. JSON grammar
/// cannot introduce a new factual sentence or an invented evidence identifier.
nonisolated enum FruitfolioEvidenceDecodingGrammar {
    static func make(evidence: FruitfolioEvidencePacket) throws -> String {
        let permitted = Set(evidence.claimEvidenceMap.flatMap { $0.noteChunkIDs + $0.sourceChunkIDs })
        let entries = evidence.researchNoteChunks.map { ($0.chunkID, $0.text) } + evidence.sourceChunks.map { ($0.sourceChunkID, $0.text) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        func jsonString(_ value: String) throws -> String { String(decoding: try encoder.encode(value), as: UTF8.self) }
        var literals: [String] = []
        for (id, text) in entries where permitted.contains(id) && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let object = "{\"text\":" + (try jsonString(text)) + ",\"evidenceIDs\":[" + (try jsonString(id)) + "]}"
            literals.append(try jsonString(object))
        }
        let emptyRoot = try jsonString("{\"bridge\":null,\"claims\":[],\"limitation\":null}")
        guard !literals.isEmpty else { return "root ::= " + emptyRoot + "\n" }
        let prefix = try jsonString("{\"bridge\":null,\"claims\":[")
        let suffix = try jsonString("],\"limitation\":null}")
        let repeatLimit = min(3, literals.count) - 1
        return "root ::= " + prefix + " (claim (\",\" claim){0," + String(repeatLimit) + "})? " + suffix + "\nclaim ::= " + literals.joined(separator: " | ") + "\n"
    }
}
