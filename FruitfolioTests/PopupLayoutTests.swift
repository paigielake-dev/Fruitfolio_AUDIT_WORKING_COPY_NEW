import XCTest
@testable import Fruitfolio

final class PopupLayoutTests: XCTestCase {
    func testNotebookWritingRegionAvoidsBindingAndRemainsInsideArtAtKeyboardAndPhoneSizes() {
        for available in [CGSize(width: 375, height: 667), .init(width: 402, height: 390), .init(width: 430, height: 932)] {
            let layout = FruitfolioPopupLayout.geometry(assetSize: .init(width: 684, height: 564),
                normalizedWriting: .init(x: 0.24, y: 0.14, width: 0.65, height: 0.76), available: available)
            XCTAssertTrue(CGRect(origin: .zero, size: available).contains(layout.artwork))
            XCTAssertTrue(layout.artwork.contains(layout.writing))
            XCTAssertEqual(layout.artwork.width / layout.artwork.height, 684 / 564, accuracy: 0.001)
            XCTAssertGreaterThan(layout.writing.minX, layout.artwork.minX + layout.artwork.width * 0.214)
            XCTAssertGreaterThan(layout.writing.height, 150)
        }
    }
}
