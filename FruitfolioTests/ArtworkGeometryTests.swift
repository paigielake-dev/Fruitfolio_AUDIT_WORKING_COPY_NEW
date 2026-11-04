import XCTest
@testable import Fruitfolio

final class ArtworkGeometryTests: XCTestCase {
    func testOriginalArtworkGeometryIsActuallyBundled() throws {
        let cloud = try XCTUnwrap(FruitfolioArtworkGeometryStore.geometry(named: "decor_fluffy_cloud"))
        XCTAssertEqual(cloud.width, 1774)
        XCTAssertEqual(cloud.height, 887)
        let painted = try XCTUnwrap(cloud.paintedBounds(in: .init(width: 177.4, height: 88.7)))
        XCTAssertEqual(painted.width, 177, accuracy: 0.001)
        XCTAssertEqual(painted.height, 87.9, accuracy: 0.001)
        XCTAssertNotNil(FruitfolioArtworkGeometryStore.geometry(named: "popup_speech_bubble"))
    }

    func testTransparentMarginsAreProjectedWithoutChangingAspectOrOrigin() throws {
        let geometry = FruitfolioArtworkGeometry(width: 100, height: 200, visibleBounds: [10,20,90,180])
        let bounds = try XCTUnwrap(geometry.paintedBounds(in: .init(width: 50, height: 100)))
        XCTAssertEqual(bounds, .init(x: 5, y: 10, width: 40, height: 80))
    }
}
