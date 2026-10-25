import XCTest
@testable import Fruitfolio

final class Prompt09EducationalAssetRouterTests: XCTestCase {
    func testSingleOverlappingWordDoesNotRetrieveArtwork() {
        let assets = EducationalAssetRouter.shared.assets(for: ["tea"], support: .supported)
        XCTAssertTrue(assets.isEmpty)
    }

    func testConceptLevelMatchCanRetrieveArtwork() {
        let assets = EducationalAssetRouter.shared.assets(
            for: ["period", "menstruation", "ginger", "tea"],
            support: .supported
        )
        XCTAssertTrue(assets.contains { $0.assetID == .period_ginger_tea })
    }
}
