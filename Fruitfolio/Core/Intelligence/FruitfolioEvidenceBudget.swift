import Foundation

/// Admission uses the native model's actual tokenizer through synchronous
/// closures. Whole paragraphs fit or are omitted; medical text is never clipped.
nonisolated enum FruitfolioEvidenceBudget {
    struct Selection: Sendable {
        let evidence: FruitfolioEvidencePacket
        let maximumClaims: Int
        let promptTokens: Int
    }

    static func fit(
        evidence: FruitfolioEvidencePacket,
        maximumPromptTokens: Int,
        maximumOutputTokens: Int,
        promptTokenCount: (FruitfolioEvidencePacket) throws -> Int,
        outputTokenCount: (String) throws -> Int
    ) throws -> Selection? {
        guard maximumPromptTokens > 0, maximumOutputTokens > 8 else { return nil }
        let permitted = Set(evidence.claimEvidenceMap.flatMap { $0.noteChunkIDs + $0.sourceChunkIDs })
        var notes: [FruitfolioResearchNoteChunk] = []
        var sources: [FruitfolioSourceChunk] = []
        var largestOutput = 0

        func packet(_ notes: [FruitfolioResearchNoteChunk], _ sources: [FruitfolioSourceChunk]) -> FruitfolioEvidencePacket {
            let noteIDs = Set(notes.map(\.chunkID))
            let sourceIDs = Set(sources.map(\.sourceChunkID))
            return FruitfolioEvidencePacket(normalizedQuestion: evidence.normalizedQuestion,
                researchNoteChunks: notes, sourceChunks: sources,
                claimEvidenceMap: evidence.claimEvidenceMap.map {
                    .init(claim: $0.claim, noteChunkIDs: $0.noteChunkIDs.filter { noteIDs.contains($0) },
                          sourceChunkIDs: $0.sourceChunkIDs.filter { sourceIDs.contains($0) })
                }, sourceRecords: evidence.sourceRecords, safetyClassification: evidence.safetyClassification,
                permittedContext: evidence.permittedContext, contentVersion: evidence.contentVersion,
                userProvidedContext: evidence.userProvidedContext,
                conversationalPresentation: evidence.conversationalPresentation)
        }
        guard try promptTokenCount(packet([], [])) <= maximumPromptTokens else { return nil }
        for note in evidence.researchNoteChunks where permitted.contains(note.chunkID) {
            try Task.checkCancellation()
            guard notes.count < FruitfolioEvidencePromptBuilder.maximumNoteParagraphs else { break }
            let cost = try outputTokenCount(FruitfolioEvidenceDecodingGrammar.singleSelectionJSON(id: note.chunkID))
            guard cost + 8 <= maximumOutputTokens,
                  try promptTokenCount(packet(notes + [note], sources)) <= maximumPromptTokens else { continue }
            notes.append(note)
            largestOutput = max(largestOutput, cost)
        }
        for source in evidence.sourceChunks where permitted.contains(source.sourceChunkID) {
            try Task.checkCancellation()
            guard sources.count < FruitfolioEvidencePromptBuilder.maximumSourceParagraphs else { break }
            let cost = try outputTokenCount(FruitfolioEvidenceDecodingGrammar.singleSelectionJSON(id: source.sourceChunkID))
            guard cost + 8 <= maximumOutputTokens,
                  try promptTokenCount(packet(notes, sources + [source])) <= maximumPromptTokens else { continue }
            sources.append(source)
            largestOutput = max(largestOutput, cost)
        }
        guard !notes.isEmpty || !sources.isEmpty else { return nil }
        var maximumClaims = min(3, notes.count + sources.count)
        // Conservative even if the grammar repeats its longest alternative.
        // Each single-draft cost already includes framing; reserve EOS/merges.
        while maximumClaims > 1 && largestOutput * maximumClaims + 8 > maximumOutputTokens {
            maximumClaims -= 1
        }
        let selected = packet(notes, sources)
        return Selection(evidence: selected, maximumClaims: maximumClaims,
                         promptTokens: try promptTokenCount(selected))
    }
}
