import XCTest
@testable import Fruitfolio

/// Synthetic fixtures verify attribution mechanics, not clinical accuracy or native inference.
final class GroundingAttributionTests: XCTestCase {
    private func note(_ id: String, _ text: String, source: String) -> FruitfolioResearchNoteChunk {
        .init(chunkID: id, researchTopicID: id, heading: "temperature progesterone evidence",
              subheading: nil, text: text, sourceIDs: [source], semanticTags: [], domainTags: [])
    }

    private func source(_ id: String) -> FruitfolioResearchSource {
        .init(sourceID: id, title: id, authors: nil, organization: nil, publicationDate: nil,
              publicationType: "Synthetic test fixture", canonicalURL: nil, doi: nil,
              apa7Reference: id, verificationStatus: "verified", retrievalEligibility: true,
              sourceVersion: "test", verifiedAt: nil, contentVersion: "test")
    }

    private func package(_ notes: [FruitfolioResearchNoteChunk]) -> FruitfolioResearchPackage {
        .init(schemaVersion: 1, contentVersion: "synthetic-test", generatedFrom: "test fixture",
              generationNote: "Not medical evidence", researchNoteChunks: notes,
              sources: notes.flatMap(\.sourceIDs).map(source), sourceChunks: [])
    }

    func testUnrelatedExtraCitationCannotRideAlongWithMatchingQuote() {
        let a = note("a", "Temperature evidence preserves its qualifier.", source: "s1")
        let b = note("b", "Temperature evidence about a different matter.", source: "s2")
        let packet = FruitfolioEvidencePacket(
            normalizedQuestion: "temperature evidence", researchNoteChunks: [a, b], sourceChunks: [],
            claimEvidenceMap: [.init(claim: .init(id: "c", text: "temperature evidence"),
                                     noteChunkIDs: [a.chunkID, b.chunkID], sourceChunkIDs: [])],
            sourceRecords: [], safetyClassification: .init(level: .normal, matchedPatterns: []),
            permittedContext: nil, contentVersion: "test")
        let selected = try? FruitfolioSelectedEvidenceDraftBuilder.draft(
            selection: .init(evidenceIDs: [a.chunkID]), evidence: packet)
        XCTAssertEqual(selected?.claims.first?.text, a.text)
        XCTAssertThrowsError(try FruitfolioSelectedEvidenceDraftBuilder.draft(
            selection: .init(evidenceIDs: ["invented"]), evidence: packet))
        XCTAssertThrowsError(try FruitfolioSelectedEvidenceDraftBuilder.draft(
            selection: .init(evidenceIDs: [a.chunkID, a.chunkID]), evidence: packet))
        let bad = FruitfolioGeneratedDraft(bridge: nil,
            claims: [.init(text: a.text, evidenceIDs: [a.chunkID, b.chunkID])], limitation: nil)
        XCTAssertNil(FruitfolioGeneratedDraftValidator.validatedText(draft: bad, evidence: packet))
        let good = FruitfolioGeneratedDraft(bridge: nil,
            claims: [.init(text: a.text, evidenceIDs: [a.chunkID])], limitation: nil)
        let accepted = FruitfolioGeneratedDraftValidator.validatedDraft(draft: good, evidence: packet)
        XCTAssertEqual(accepted?.evidenceIDs, Set([a.chunkID]))
    }

    @MainActor
    func testOnlyDisplayedEvidenceContributesSources() async throws {
        let notes = [note("a", "Temperature progesterone evidence is limited.", source: "s1"),
                     note("b", "Temperature progesterone evidence needs more context.", source: "s2")]
        let engine = FruitfolioResearchIntelligenceEngine(
            packageStore: .init(package: package(notes)), languageModel: FixtureModel(fail: false))
        let answer = try await engine.answer(question: "temperature progesterone evidence", conversation: [])
        XCTAssertEqual(answer.sources.count, 1, "Unused retrieval candidates must not acquire citations")
        XCTAssertEqual(answer.sourceIDs, answer.sources.map(\.id))
    }

    @MainActor
    func testFallbackRetainsQualifierBeyondOldClippingBoundary() async throws {
        let text = String(repeating: "Temperature progesterone evidence needs context. ", count: 24)
            + "This does not confirm ovulation."
        let engine = FruitfolioResearchIntelligenceEngine(
            packageStore: .init(package: package([note("a", text, source: "s1")])),
            languageModel: FixtureModel(fail: true))
        let answer = try await engine.answer(question: "temperature progesterone evidence", conversation: [])
        XCTAssertTrue(answer.answerText.contains("This does not confirm ovulation."))
        XCTAssertFalse(answer.answerText.contains("…"))
    }
}

private struct FixtureModel: FruitfolioLanguageModel {
    let fail: Bool
    func availability() async -> FruitfolioLanguageModelAvailability { .available }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        if fail { throw FruitfolioResearchIntelligenceError.unsupported }
        let note = try XCTUnwrap(evidence.researchNoteChunks.first)
        return .init(bridge: nil, claims: [.init(text: note.text, evidenceIDs: [note.chunkID])], limitation: nil)
    }
}
