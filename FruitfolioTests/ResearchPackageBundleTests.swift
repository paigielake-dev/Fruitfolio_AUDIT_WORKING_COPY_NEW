import XCTest
@testable import Fruitfolio

final class ResearchPackageBundleTests: XCTestCase {
    func testRealBundledResearchPackageDecodesAndHasNoOrphanSources() async throws {
        let package = try await FruitfolioResearchPackageStore().load()
        XCTAssertEqual(package.schemaVersion, 1)
        XCTAssertGreaterThanOrEqual(package.researchNoteChunks.count, 395)
        XCTAssertEqual(package.sourceChunks.count, 470)
        let sourceIDs = Set(package.sources.map(\.sourceID))
        XCTAssertEqual(sourceIDs.count, package.sources.count)
        XCTAssertEqual(Set(package.researchNoteChunks.map(\.chunkID)).count, package.researchNoteChunks.count)
        for note in package.researchNoteChunks {
            XCTAssertTrue(Set(note.sourceIDs).isSubset(of: sourceIDs), note.chunkID)
        }
        for chunk in package.sourceChunks {
            XCTAssertTrue(sourceIDs.contains(chunk.sourceID), chunk.sourceChunkID)
            XCTAssertFalse(chunk.text.isEmpty)
            XCTAssertNotNil(chunk.locationMetadata)
        }
        XCTAssertTrue(package.sources.contains { $0.verificationStatus == "unresolved" && !$0.retrievalEligibility })
    }
}
