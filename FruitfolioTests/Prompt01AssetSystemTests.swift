import XCTest
@testable import Fruitfolio

final class Prompt01AssetSystemTests: XCTestCase {
    func testRegistryContainsExactly265ProductionPNGs() {
        XCTAssertEqual(AssetRegistry.all.count, 265)
        XCTAssertEqual(FruitfolioAssetID.allCases.count, 265)
    }

    func testCanonicalIDsAndPhysicalPathsAreUnique() {
        XCTAssertEqual(Set(AssetRegistry.all.map(\.id)).count, 265)
        XCTAssertEqual(Set(AssetRegistry.all.map(\.physicalPath)).count, 265)
    }

    func testEducationalVisualsAreNeverDecorative() {
        let educational = AssetRegistry.all.filter { $0.category == "EducationalVisuals" }

        XCTAssertEqual(educational.count, 44)
        XCTAssertTrue(educational.allSatisfy { $0.assetClass == .educational })
        XCTAssertTrue(educational.allSatisfy { $0.primaryDestination == "Ask the Encyclopedia" })
        XCTAssertTrue(educational.allSatisfy(\.researchSupportRequired))
    }

    func testPopupAssetsHaveCanonicalOwnership() {
        let popups = AssetRegistry.all.filter { $0.category == "Popups" }
        XCTAssertEqual(popups.count, 10)
        XCTAssertTrue(popups.allSatisfy { $0.primaryDestination == "Global Popup Engine" })
    }

    func testReferenceOnlyFilesAreNotInProductionRegistry() {
        XCTAssertFalse(AssetRegistry.all.contains { $0.filename == "cycle_calendar_reference.png" })
        XCTAssertFalse(AssetRegistry.all.contains { $0.filename == "cycle_wheel_reference.png" })
    }

    func testLegacySemanticAliasesResolveToRealPhysicalAssets() {
        XCTAssertEqual(AssetRegistry.resolve("book_open_hub")?.id, .book_open_blank)
        XCTAssertEqual(AssetRegistry.resolve("hub_search")?.id, .ask_magnifying_glass)
        XCTAssertEqual(AssetRegistry.resolve("hub_guide")?.id, .guide_folder_add)
    }

    func testNoSuppliedProductionAssetIsAwaitingFutureAsset() {
        XCTAssertFalse(AssetRegistry.all.contains { $0.status == .awaitingFutureAsset })
    }
}
