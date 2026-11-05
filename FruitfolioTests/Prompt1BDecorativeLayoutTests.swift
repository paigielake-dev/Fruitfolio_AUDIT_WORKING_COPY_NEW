import XCTest
@testable import Fruitfolio

final class Prompt1BDecorativeLayoutTests: XCTestCase {
    private func place(height: CGFloat = 200, protected: [FruitfolioProtectedRegion] = []) -> FruitfolioDecorativePlacement {
        FruitfolioDecorativeArtLayout.placement(
            intrinsicSize: CGSize(width: 100, height: 100), roleFraction: 0.2...0.8,
            anchor: .bottomTrailing, container: CGRect(x: 0, y: 0, width: 300, height: height),
            safeInsets: FruitfolioArtInsets(), protectedRegions: protected)
    }

    func testHeightConstraintResizesWithinRoleAndRetainsAnchor() {
        let placement = place()
        XCTAssertTrue(placement.isVisible)
        XCTAssertEqual(placement.frame.maxX, 284, accuracy: 0.001)
        XCTAssertEqual(placement.frame.maxY, 184, accuracy: 0.001)
        XCTAssertEqual(placement.frame.width, placement.frame.height)
        XCTAssertGreaterThanOrEqual(placement.frame.width, 268 * 0.2)
    }

    func testFullyProtectedRegionOmitsArtInsteadOfCoveringText() {
        XCTAssertFalse(place(protected: [.init(rect: CGRect(x: 0, y: 0, width: 300, height: 200))]).isVisible)
    }

    func testTooSmallContainerOmitsInsteadOfShrinkingBelowApprovedRole() {
        XCTAssertFalse(place(height: 50).isVisible)
    }
}
