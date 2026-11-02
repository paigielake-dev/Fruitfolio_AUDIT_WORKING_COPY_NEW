import XCTest
import UIKit
@testable import Fruitfolio

@MainActor
final class SharedControlArtworkTests: XCTestCase {
    func testPreparedPillUsesOriginalAspectRatioAndReusesRaster() throws {
        let original = try FruitfolioAssetLoader.uiImage(.control_pill_outline)
        let first = try XCTUnwrap(FruitfolioControlArtwork.pill(width: 292, displayScale: 3))
        XCTAssertEqual(first.size.width, 292, accuracy: 0.001)
        XCTAssertEqual(first.size.height / first.size.width,
                       original.size.height / original.size.width, accuracy: 0.001)
        let second = try XCTUnwrap(FruitfolioControlArtwork.pill(width: 292, displayScale: 3))
        XCTAssertTrue(first === second, "Repeated body updates must reuse the prepared original artwork")
        XCTAssertNotNil(first.cgImage)
    }

    func testInvalidLayoutDoesNotAllocateArtwork() {
        XCTAssertNil(FruitfolioControlArtwork.pill(width: 0, displayScale: 3))
        XCTAssertNil(FruitfolioControlArtwork.pill(width: .infinity, displayScale: 3))
        XCTAssertNil(FruitfolioControlArtwork.pill(width: 292, displayScale: 0))
    }
}
