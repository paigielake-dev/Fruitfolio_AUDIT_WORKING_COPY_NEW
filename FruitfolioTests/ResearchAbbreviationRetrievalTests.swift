import XCTest
@testable import Fruitfolio

final class ResearchAbbreviationRetrievalTests: XCTestCase {
    func testSupportedShortHormoneIdentifiersSurviveWithoutAdmittingAllShortWords() {
        XCTAssertEqual(FruitfolioQueryNormalizer.tokens("what is LH?"), ["lh"])
        XCTAssertEqual(FruitfolioQueryNormalizer.tokens("E2"), ["e2"])
        XCTAssertTrue(FruitfolioQueryNormalizer.tokens("is it an ax").isEmpty)
        XCTAssertEqual(FruitfolioQueryNormalizer.normalize("INSULIN"), "insulin")
        XCTAssertEqual(FruitfolioQueryNormalizer.normalize("İNSULİN"), "insulin")
    }

    func testShortIdentifierDoesNotMatchInsideAnUnrelatedReferenceCode() {
        let note = FruitfolioResearchNoteChunk(chunkID: "fixture", researchTopicID: "fixture",
            heading: "reference code", subheading: nil, text: "An unrelated abcE2def reference code.",
            sourceIDs: [], semanticTags: [], domainTags: [])
        let package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "fixture",
            generatedFrom: "test", generationNote: "No clinical evidence", researchNoteChunks: [note],
            sources: [], sourceChunks: [])
        XCTAssertTrue(FruitfolioLocalResearchRetriever(package: package).searchNotes(question: "E2").isEmpty)
    }

    func testActualBundledResearchIsSearchedForLHAndE2WithoutModelOrNetwork() async throws {
        let store = FruitfolioResearchPackageStore()
        let package = try await store.load()
        let retriever = try await store.retriever()
        for term in ["LH", "E2"] {
            let results = retriever.searchNotes(question: term)
            XCTAssertFalse(results.isEmpty, "A supported two-character hormone term must not be discarded before search")
            XCTAssertTrue(results.contains { result in
                result.chunk.text.range(of: "\\b" + term + "\\b", options: [.regularExpression, .caseInsensitive]) != nil
            }, "Actual retrieved evidence must contain the requested original identifier")
        }
        let eligible = Set(package.sources.filter(\.isApprovedForDisplay).map(\.sourceID))
        let sources = retriever.searchSources(question: "LH", approvedSourceIDs: eligible)
        XCTAssertFalse(sources.isEmpty)
        XCTAssertTrue(sources.allSatisfy { eligible.contains($0.chunk.sourceID) },
                      "Short-token support must not bypass source approval")
    }
}
