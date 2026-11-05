import XCTest
@testable import Fruitfolio

final class Prompt1BEvidenceBudgetTests: XCTestCase {
    private func packet(_ texts: [String]) -> FruitfolioEvidencePacket {
        let notes = texts.enumerated().map { index, text in
            FruitfolioResearchNoteChunk(chunkID: "note-\(index)", researchTopicID: "fixture", heading: "fixture", subheading: nil,
                text: text, sourceIDs: [], semanticTags: [], domainTags: [])
        }
        return .init(normalizedQuestion: "fixture", researchNoteChunks: notes, sourceChunks: [],
            claimEvidenceMap: [.init(claim: .init(id: "claim-1", text: "fixture"), noteChunkIDs: notes.map(\.chunkID), sourceChunkIDs: [])],
            sourceRecords: [], safetyClassification: .init(level: .normal, matchedPatterns: []), permittedContext: nil, contentVersion: "fixture")
    }
    func testWholeParagraphAdmissionOmitsOversizedEvidenceAndItsIDsWithoutClipping() throws {
        let original = packet([String(repeating: "long medical paragraph ", count: 100), "a complete short paragraph"])
        let selected = try XCTUnwrap(FruitfolioEvidenceBudget.fit(evidence: original, maximumPromptTokens: 120, maximumOutputTokens: 180,
            promptTokenCount: { 20 + $0.researchNoteChunks.reduce(0) { $0 + $1.text.utf8.count } },
            outputTokenCount: { $0.utf8.count }))
        XCTAssertEqual(selected.evidence.researchNoteChunks.map(\.text), ["a complete short paragraph"])
        XCTAssertEqual(selected.evidence.claimEvidenceMap.first?.noteChunkIDs, ["note-1"])
        XCTAssertLessThanOrEqual(selected.promptTokens, 120)
        XCTAssertEqual(original.researchNoteChunks.count, 2)
    }
    func testNoEvidenceFitsFallsBackRatherThanCuttingScientificText() throws {
        let original = packet(["a complete paragraph with an essential qualifier"])
        XCTAssertNil(try FruitfolioEvidenceBudget.fit(evidence: original, maximumPromptTokens: 10, maximumOutputTokens: 200,
            promptTokenCount: { _ in 20 }, outputTokenCount: { $0.utf8.count }))
        XCTAssertNil(try FruitfolioEvidenceBudget.fit(evidence: original, maximumPromptTokens: 200, maximumOutputTokens: 20,
            promptTokenCount: { _ in 20 }, outputTokenCount: { $0.utf8.count }))
    }
    func testOutputBudgetRestrictsNumberOfWholeClaimsAndJSONPreservesUnits() throws {
        let original = packet(["E2 20 pg/mL", "exact second paragraph"])
        let selected = try XCTUnwrap(FruitfolioEvidenceBudget.fit(evidence: original, maximumPromptTokens: 500, maximumOutputTokens: 50,
            promptTokenCount: { _ in 20 }, outputTokenCount: { $0.utf8.count }))
        XCTAssertEqual(selected.maximumClaims, 1)
        let json = try FruitfolioEvidenceDecodingGrammar.singleClaimDraftJSON(id: "note-0", text: "E2 20 pg/mL")
        let draft = try JSONDecoder().decode(FruitfolioGeneratedDraft.self, from: Data(json.utf8))
        XCTAssertEqual(draft.claims.first?.text, "E2 20 pg/mL")
        XCTAssertEqual(draft.claims.first?.evidenceIDs, ["note-0"])
    }
}
