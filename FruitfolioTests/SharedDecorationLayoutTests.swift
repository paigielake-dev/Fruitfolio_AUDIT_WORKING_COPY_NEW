import XCTest
import SwiftUI
@testable import Fruitfolio

final class SharedDecorationLayoutTests: XCTestCase {
    func testKeyboardHeightUsesOnlyTheApprovedSizeRangeAndKeepsTheAssignedCornerAndAspect() {
        let container = CGRect(x: 0, y: 0, width: 400, height: 300)
        let result = FruitfolioDecorativeArtLayout.placement(intrinsicSize: .init(width: 100, height: 200),
            roleFraction: 0.30...0.50, anchor: .topTrailing, container: container,
            safeInsets: EdgeInsets(), protectedRegions: [])
        XCTAssertTrue(result.isVisible, "Height can constrain the art within its approved role range without omitting it")
        XCTAssertEqual(result.frame.maxX, 384, accuracy: 0.001)
        XCTAssertEqual(result.frame.minY, 16, accuracy: 0.001)
        XCTAssertEqual(result.frame.width / result.frame.height, 0.5, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(result.frame.width, 368 * 0.30)
        XCTAssertTrue(container.contains(result.frame))
        let tooShort = FruitfolioDecorativeArtLayout.placement(intrinsicSize: .init(width: 100, height: 200),
            roleFraction: 0.30...0.50, anchor: .topTrailing,
            container: CGRect(x: 0, y: 0, width: 400, height: 190),
            safeInsets: EdgeInsets(), protectedRegions: [])
        XCTAssertFalse(tooShort.isVisible, "Do not reduce artwork below its approved role minimum")
    }

    func testExpandingTextSuppressesOnlyTheDecorationWhosePaintedFootprintCollides() {
        func placement(_ protected: [FruitfolioProtectedRegion]) -> FruitfolioDecorativePlacement {
            FruitfolioDecorativeArtLayout.placement(intrinsicSize: .init(width: 100, height: 100),
                visibleAlphaBounds: CGRect(x: 20, y: 20, width: 60, height: 60),
                roleFraction: 0.20...0.30, anchor: .topTrailing,
                container: CGRect(x: 0, y: 0, width: 400, height: 300),
                safeInsets: EdgeInsets(), protectedRegions: protected, minimumGap: 4)
        }
        XCTAssertTrue(placement([.init(rect: CGRect(x: 20, y: 20, width: 180, height: 50))]).isVisible)
        XCTAssertFalse(placement([.init(rect: CGRect(x: 20, y: 20, width: 360, height: 150))]).isVisible)
        XCTAssertTrue(placement([]).isVisible, "Dismissal or smaller text restores the same composition")
    }

    func testInvalidPaintedBoundsFailClosedInsteadOfPlacingArtOverProtectedContent() {
        for bounds in [[-1.0, 0, 90, 180], [0, 0, 101, 180], [0, 0, 90, 201], [0, 0, Double.nan, 180]] {
            let geometry = FruitfolioArtworkGeometry(width: 100, height: 200, visibleBounds: bounds)
            XCTAssertNil(geometry.paintedBounds(in: .init(width: 50, height: 100)))
        }
        XCTAssertFalse(FruitfolioDecorativeArtLayout.isCollisionFree(
            paintedFrame: CGRect(x: .infinity, y: 0, width: 10, height: 10), protectedRegions: []))
    }
}
