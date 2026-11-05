import XCTest
@testable import Fruitfolio

final class Prompt1BResearchPackageTests: XCTestCase {
    private func package() throws -> FruitfolioResearchPackage {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        return try JSONDecoder().decode(FruitfolioResearchPackage.self, from: Data(contentsOf: url))
    }
    func testActualCompiledPackageRetainsApprovedReferencesAndQuarantine() throws {
        let package = try package()
        XCTAssertGreaterThan(package.researchNoteChunks.count, 4000)
        XCTAssertGreaterThan(package.sources.count, 700)
        XCTAssertTrue(package.sourceChunks.isEmpty, "Reference strings must not masquerade as full-source evidence")
        let organizationNotes = package.researchNoteChunks.filter { $0.heading.lowercased().contains("lifebridge") }
        XCTAssertFalse(organizationNotes.isEmpty)
        XCTAssertTrue(organizationNotes.allSatisfy { $0.retrievalEligibility == false })
        let retriever = FruitfolioLocalResearchRetriever(package: package)
        let results = retriever.searchNotes(question: "progesterone temperature")
        XCTAssertFalse(results.isEmpty)
        let approvedIDs = Set(package.sources.filter(\.isApprovedForDisplay).map(\.sourceID))
        for chunk in package.researchNoteChunks where chunk.retrievalEligibility != false {
            XCTAssertFalse(chunk.sourceIDs.isEmpty)
            XCTAssertTrue(Set(chunk.sourceIDs).isSubset(of: approvedIDs))
        }
        for result in results {
            XCTAssertNotEqual(result.chunk.retrievalEligibility, false)
            XCTAssertFalse(result.chunk.sourceIDs.isEmpty)
            XCTAssertTrue(Set(result.chunk.sourceIDs).isSubset(of: approvedIDs))
        }
    }
    func testActualStaticIndexCanServeRepeatedIndependentQueriesWithoutChangingPackage() throws {
        let package = try package()
        let start = Date()
        let retriever = FruitfolioLocalResearchRetriever(package: package)
        let indexed = Date()
        for _ in 0..<10 {
            for query in ["progesterone temperature", "cervical mucus", "menstrual cycle", "pregnancy nutrition", "thyroid hormones"] {
                _ = retriever.searchNotes(question: query)
            }
        }
        let end = Date()
        XCTAssertEqual(retriever.package.contentVersion, package.contentVersion)
        XCTAssertEqual(retriever.package.researchNoteChunks.count, package.researchNoteChunks.count)
        print("ACTUAL_RESEARCH_INDEX seconds=\(indexed.timeIntervalSince(start)) warm_50_queries_seconds=\(end.timeIntervalSince(indexed))")
    }
}
