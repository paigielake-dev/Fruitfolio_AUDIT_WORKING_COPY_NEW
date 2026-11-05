import XCTest
@testable import Fruitfolio

final class Prompt1BPopupLayoutTests: XCTestCase {
    func testAllCharacterPaintedBoundsAreCenteredWithoutDistortingAspectRatio() {
        for character in FruitfolioPopupLayout.CharacterArtwork.allCases {
            let side: CGFloat = 72
            let pixels = character.pixelSize
            let bounds = character.paintedBounds
            XCTAssertTrue(CGRect(origin: .zero, size: pixels).contains(bounds))
            let scale = min(side / pixels.width, side / pixels.height)
            let offset = character.opticalOffset(boxSide: side)
            let paintedCenter = CGPoint(x: (side - pixels.width * scale) / 2 + bounds.midX * scale + offset.width,
                                        y: (side - pixels.height * scale) / 2 + bounds.midY * scale + offset.height)
            XCTAssertEqual(paintedCenter.x, side / 2, accuracy: 0.001)
            XCTAssertEqual(paintedCenter.y, side / 2, accuracy: 0.001)
        }
    }

    func testDialogueNeverOverflowsNarrowViewportEvenForLongMessages() {
        for width: CGFloat in [0, 100, 160, 240, 288, 361, 852] {
            for count in [0, 58, 59, 105, 106, 10_000] {
                let metrics = FruitfolioPopupLayout.dialogue(availableWidth: width, messageCount: count)
                XCTAssertLessThanOrEqual(metrics.totalWidth, width + 0.001)
                XCTAssertGreaterThanOrEqual(metrics.characterWidth, 0)
                XCTAssertGreaterThanOrEqual(metrics.bubbleWidth, 0)
                // Character artwork ends before the writing area's near edge,
                // including its measured optical correction for either side.
                for character in FruitfolioPopupLayout.CharacterArtwork.allCases {
                    let offset = character.opticalOffset(boxSide: metrics.characterWidth)
                    XCTAssertLessThanOrEqual(metrics.characterWidth + abs(offset.width),
                        metrics.characterWidth + metrics.spacing + metrics.bubbleWidth * 0.09 + 0.001)
                }
            }
        }
        XCTAssertEqual(FruitfolioPopupLayout.dialogue(availableWidth: .infinity, messageCount: 3).totalWidth, 0)
    }

    func testKeyboardConstrainedDialoguePreservesSpeechArtworkRatioWithinHeight() {
        for height: CGFloat in [44, 100, 180, 400] {
            let metrics = FruitfolioPopupLayout.dialogue(availableWidth: 288, availableHeight: height, messageCount: 400)
            let bubbleHeight = metrics.bubbleWidth * 499 / 497
            XCTAssertLessThanOrEqual(bubbleHeight, height + 0.001)
            XCTAssertLessThanOrEqual(metrics.characterWidth, height)
            XCTAssertLessThanOrEqual(metrics.totalWidth, 288)
        }
    }

    func testTourRetainsItsApprovedSmallerRoleAndViewportBounds() {
        let metrics = FruitfolioPopupLayout.dialogue(availableWidth: 160, availableHeight: 120,
            messageCount: 1000, maximumBubbleWidth: 184, maximumCharacterWidth: 62)
        XCTAssertLessThanOrEqual(metrics.totalWidth, 160)
        XCTAssertLessThanOrEqual(metrics.bubbleWidth, 184)
        XCTAssertLessThanOrEqual(metrics.characterWidth, 62)
        XCTAssertLessThanOrEqual(metrics.bubbleWidth * 499 / 497, 120)
    }

    func testTapedWhitePopupPreservesArtworkAndTapeFreeWritingArea() {
        let metrics = FruitfolioPopupLayout.tapedWhite(available: CGSize(width: 320, height: 260))
        XCTAssertLessThanOrEqual(metrics.paperSize.height, 228)
        XCTAssertEqual(metrics.paperSize.width / metrics.paperSize.height, 662.0 / 647, accuracy: 0.0001)
        XCTAssertLessThan(metrics.writingSize.width, metrics.paperSize.width)
        XCTAssertLessThanOrEqual(metrics.writingSize.height / 2 + metrics.paperSize.height * 0.05, metrics.paperSize.height / 2)
    }

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

    func testCompactSaveCardUsesOriginalAspectRatioAndWritingBounds() {
        let metrics = FruitfolioPopupLayout.saveConfirmation(available: CGSize(width: 320, height: 500))
        XCTAssertLessThanOrEqual(metrics.paperSize.width, 240)
        XCTAssertEqual(metrics.paperSize.width / metrics.paperSize.height, 634.0 / 667.0, accuracy: 0.0001)
        XCTAssertLessThan(metrics.writingSize.width, metrics.paperSize.width)
        XCTAssertLessThan(metrics.writingSize.height, metrics.paperSize.height)
    }

    func testInvalidOrCollapsedViewportNeverProducesNegativeOrNonfiniteFrames() {
        for size in [CGSize.zero, CGSize(width: 12, height: 10),
                     CGSize(width: -1, height: 100), CGSize(width: CGFloat.infinity, height: 100)] {
            let metrics = FruitfolioPopupLayout.notebook(available: size)
            XCTAssertEqual(metrics.paperSize, CGSize.zero)
            XCTAssertEqual(metrics.writingSize, CGSize.zero)
        }
    }
}
