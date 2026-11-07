import XCTest
@testable import Fruitfolio

final class Prompt1BResearchRetrievalTests: XCTestCase {
    private func source(_ id: String, approved: Bool) -> FruitfolioResearchSource {
        .init(sourceID: id, title: "Fixture source", authors: nil, organization: nil,
              publicationDate: nil, publicationType: nil, canonicalURL: nil, doi: nil,
              apa7Reference: approved ? "Verified fixture reference" : nil,
              verificationStatus: approved ? "verified" : "unresolved", retrievalEligibility: true,
              sourceVersion: "1", verifiedAt: nil, contentVersion: "fixture")
    }
    private func package(notes: [FruitfolioResearchNoteChunk] = [], sources: [FruitfolioResearchSource] = [], chunks: [FruitfolioSourceChunk] = []) -> FruitfolioResearchPackage {
        .init(schemaVersion: 1, contentVersion: "fixture", generatedFrom: "fixture", generationNote: "fixture",
              researchNoteChunks: notes, sources: sources, sourceChunks: chunks)
    }
    func testCachedStaticTokensRetainRankingScoresTieOrderAndCoverage() {
        let notes = ["n2", "n1"].map { id in
            FruitfolioResearchNoteChunk(chunkID: id, researchTopicID: "topic", heading: "progesterone temperature", subheading: nil,
                text: "progesterone temperature observed in the approved fixture", sourceIDs: [], semanticTags: [], domainTags: [])
        }
        let retriever = FruitfolioLocalResearchRetriever(package: package(notes: notes))
        for _ in 0..<3 {
            let ranked = retriever.searchNotes(question: "progesterone temperature")
            XCTAssertEqual(ranked.map(\.chunk.chunkID), ["n1", "n2"])
            XCTAssertEqual(ranked.map(\.score), [11, 11])
            let coverage = retriever.coverage(claims: [.init(id: "supported", text: "progesterone temperature"),
                                                      .init(id: "unknown", text: "quantum entanglement")], notes: ranked)
            XCTAssertEqual(coverage.supportedClaims.map(\.id), ["supported"])
            XCTAssertEqual(coverage.unsupportedClaims.map(\.id), ["unknown"])
        }
        XCTAssertTrue(retriever.searchNotes(question: "quantum entanglement").isEmpty)
        XCTAssertTrue(retriever.searchNotes(question: "progesterone", limit: -1).isEmpty)
    }
    func testSourceExpansionCannotUseUnverifiedOrUnrequestedRecords() {
        let chunks = ["approved", "unverified", "missing"].map { id in
            FruitfolioSourceChunk(sourceChunkID: "chunk-" + id, sourceID: id, section: nil,
                                  text: "progesterone temperature", locationMetadata: nil, claimCategories: [])
        }
        let retriever = FruitfolioLocalResearchRetriever(package: package(sources: [source("approved", approved: true), source("unverified", approved: false)], chunks: chunks))
        XCTAssertEqual(retriever.searchSources(question: "progesterone temperature", approvedSourceIDs: []).map(\.chunk.sourceID), ["approved"])
        XCTAssertTrue(retriever.searchSources(question: "progesterone temperature", approvedSourceIDs: ["unverified"]).isEmpty)
        XCTAssertTrue(retriever.searchSources(question: "progesterone temperature", approvedSourceIDs: ["approved"], limit: -1).isEmpty)
    }
}

extension Prompt1BResearchRetrievalTests {
    func testMultipleRequestedConceptsOutrankSingleTermHeadingCrowdingWithoutChangingScores() {
        let distractors = (0..<12).map { index in
            FruitfolioResearchNoteChunk(chunkID: "d-\(index)", researchTopicID: "fixture", heading: "anchor",
                subheading: nil, text: "anchor fixture", sourceIDs: [], semanticTags: [], domainTags: [])
        }
        let relevant = FruitfolioResearchNoteChunk(chunkID: "complete-match", researchTopicID: "fixture",
            heading: "nonclinical fixture", subheading: nil, text: "anchor context target", sourceIDs: [], semanticTags: [], domainTags: [])
        let package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "fixture", generatedFrom: "test",
            generationNote: "Nonclinical ranking fixture, not source approval", researchNoteChunks: distractors + [relevant], sources: [], sourceChunks: [])
        let ranked = FruitfolioLocalResearchRetriever(package: package).searchNotes(question: "anchor target", limit: 8)
        XCTAssertEqual(ranked.first?.chunk.chunkID, relevant.chunkID)
        XCTAssertEqual(ranked.first?.matchedConceptCount, 2)
        XCTAssertEqual(ranked.first?.score, 2)
        XCTAssertTrue(ranked.dropFirst().allSatisfy { $0.score == 4 })
        XCTAssertEqual(ranked.count, 8)
        XCTAssertTrue(ranked.dropFirst().allSatisfy { $0.matchedConceptCount == 1 })
    }
}
