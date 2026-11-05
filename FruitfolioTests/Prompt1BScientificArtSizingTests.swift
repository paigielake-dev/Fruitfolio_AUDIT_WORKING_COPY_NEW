import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BScientificArtSizingTests: XCTestCase {
    private func fit(_ intrinsic: CGSize, width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
        FruitfolioScientificArtSizing.fit(intrinsic: intrinsic, availableWidth: width, availableHeight: height,
                                         maximumWidth: 310, maximumHeight: 360)
    }
    func testTallSourceCanvasRetainsEntireAspectRatio() {
        let size = fit(CGSize(width: 1000, height: 2000))
        XCTAssertEqual(size, CGSize(width: 180, height: 360))
    }
    func testWideSourceFitsWithoutCroppingOrStretching() {
        let size = fit(CGSize(width: 2000, height: 1000))
        XCTAssertEqual(size, CGSize(width: 310, height: 155))
    }
    func testNarrowPhoneAndHeightConstraintBothApply() {
        let size = fit(CGSize(width: 1000, height: 800), width: 140, height: 80)
        XCTAssertEqual(size, CGSize(width: 100, height: 80))
    }
    func testUnspecifiedAndInfiniteScrollProposalsStayBounded() {
        XCTAssertEqual(fit(CGSize(width: 100, height: 100)), CGSize(width: 310, height: 310))
        XCTAssertEqual(fit(CGSize(width: 100, height: 100), width: .infinity, height: .infinity), CGSize(width: 310, height: 310))
    }
    func testCollapsedInvalidAndNegativeProposalsDoNotProduceInvalidFrames() {
        XCTAssertEqual(fit(CGSize(width: 0, height: 10)), .zero)
        XCTAssertEqual(fit(CGSize(width: CGFloat.nan, height: 10)), .zero)
        XCTAssertEqual(fit(CGSize(width: 100, height: 100), width: 0), .zero)
        XCTAssertEqual(fit(CGSize(width: 100, height: 100), width: -.infinity), .zero)
        XCTAssertEqual(fit(CGSize(width: 100, height: 100), height: -1), .zero)
    }
    func testEveryViewportPreservesRelationshipOfSourceCoordinates() {
        let source = CGSize(width: 1800, height: 1200)
        for width: CGFloat in [140, 240, 320, 390, 760] {
            let size = fit(source, width: width)
            XCTAssertLessThanOrEqual(size.width, min(width, 310))
            XCTAssertLessThanOrEqual(size.height, 360)
            XCTAssertEqual(size.width / source.width, size.height / source.height, accuracy: 0.000001)
        }
    }
}
