import XCTest
@testable import Fruitfolio

final class Prompt1BPopupLayoutTests: XCTestCase {
    func testNotebookAndWritingAreaRemainWithinSmallOrKeyboardConstrainedViewport() {
        for size in [CGSize(width: 240, height: 180), CGSize(width: 320, height: 220),
                     CGSize(width: 393, height: 852), CGSize(width: 852, height: 270)] {
            let metrics = FruitfolioPopupLayout.notebook(available: size)
            XCTAssertGreaterThan(metrics.paperSize.width, 0)
            XCTAssertLessThanOrEqual(metrics.paperSize.width, size.width)
            XCTAssertLessThanOrEqual(metrics.paperSize.height, size.height)
            XCTAssertLessThan(metrics.writingSize.width, metrics.paperSize.width)
            XCTAssertLessThan(metrics.writingSize.height, metrics.paperSize.height)
            XCTAssertEqual(metrics.paperSize.width / metrics.paperSize.height, 684.0 / 564.0, accuracy: 0.0001)
        }
    }

    func testInvalidOrCollapsedViewportNeverProducesNegativeOrNonfiniteFrames() {
        for size in [CGSize.zero, CGSize(width: 12, height: 10),
                     CGSize(width: -1, height: 100), CGSize(width: .infinity, height: 100)] {
            let metrics = FruitfolioPopupLayout.notebook(available: size)
            XCTAssertEqual(metrics.paperSize, .zero)
            XCTAssertEqual(metrics.writingSize, .zero)
        }
    }
}
