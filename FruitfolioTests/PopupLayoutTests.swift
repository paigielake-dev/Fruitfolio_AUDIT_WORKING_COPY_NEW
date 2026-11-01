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

@MainActor
final class ProtectedDecorationTests: XCTestCase {
    func testActualAlphaFootprintProtectsTextWithoutBlanketHidingUnrelatedArtwork() {
        let title = FruitfolioProtectedRegion(rect: CGRect(x: 90, y: 0, width: 220, height: 90))
        XCTAssertFalse(FruitfolioDecorativeArtLayout.isCollisionFree(paintedFrame: CGRect(x: 80, y: 30, width: 40, height: 40), protectedRegions: [title], minimumGap: 4))
        XCTAssertTrue(FruitfolioDecorativeArtLayout.isCollisionFree(paintedFrame: CGRect(x: 320, y: 5, width: 50, height: 50), protectedRegions: [title], minimumGap: 4))
        let expanded = FruitfolioProtectedRegion(rect: CGRect(x: 35, y: 0, width: 330, height: 210))
        XCTAssertFalse(FruitfolioDecorativeArtLayout.isCollisionFree(paintedFrame: CGRect(x: 320, y: 5, width: 50, height: 50), protectedRegions: [expanded], minimumGap: 4))
    }
}
