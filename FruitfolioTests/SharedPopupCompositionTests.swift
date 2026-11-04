import XCTest
import CoreGraphics
@testable import Fruitfolio

@MainActor
final class SharedPopupCompositionTests: XCTestCase {
    func testAuthoredMeaningSurvivesPopupTransportWithoutChangingMedicalValuesOrSourceIdentifiers() {
        let message = "LH is 2.500 ng/mL [source-1]. this is not a diagnosis."
        let document = FruitfolioSemanticDocument.authored(message, annotations: [
            .init(phrase: "LH", emphasis: .anchorBold),
            .init(phrase: "2.500 ng/mL", emphasis: .anchorBold)
        ])
        let request = FruitPopupRequest(character: .blueberry, message: message, semanticMessage: document)
        XCTAssertEqual(request.semanticMessage, document)
        XCTAssertEqual(Array(request.semanticMessage.plainText.utf8), Array(message.utf8))
        XCTAssertEqual(request.semanticMessage.spans.map(\.id), document.spans.map(\.id))
        XCTAssertTrue(request.semanticMessage.spans.contains { $0.text == "2.500 ng/mL" && $0.emphasis == .anchorBold })
    }

    func testStaleAnnotationsCannotReplaceCurrentPopupWordingAndUnannotatedMedicalProseIsNotKeywordStyled() {
        let current = "ovulation has not been confirmed."
        let stale = FruitfolioSemanticDocument(spans: [.init(text: "ovulation is confirmed", emphasis: .anchorBold)])
        let request = FruitPopupRequest(character: .peach, message: current, semanticMessage: stale)
        XCTAssertEqual(request.semanticMessage.plainText, current)
        XCTAssertTrue(request.semanticMessage.spans.allSatisfy { $0.emphasis == .plain })
    }

    func testNarrowPopupFitsWithoutShrinkingFontsOrDistortingCharacterArtwork() {
        for width in [CGFloat(160), 200, 232, 280, 343, 398] {
            for length in [0, 58, 59, 105, 106, 4000] {
                let metrics = FruitPopupCompositionMetrics(availableWidth: width, messageLength: length)
                let extent = metrics.characterWidth + metrics.bubbleWidth + metrics.spacing
                XCTAssertGreaterThan(metrics.bubbleWidth, 0)
                XCTAssertLessThanOrEqual(extent, width + 0.001)
                if metrics.showsCharacter { XCTAssertGreaterThanOrEqual(metrics.characterWidth, 58) }
                else { XCTAssertEqual(metrics.characterWidth, 0) }
            }
        }
    }

    func testInvalidWritingRegionsNeverProduceOffArtworkOrNonfiniteTextFrames() {
        let valid = CGRect(x: 0.24, y: 0.14, width: 0.65, height: 0.76)
        for invalid in [CGRect(x: -0.1, y: 0, width: 1, height: 1),
                        CGRect(x: 0.8, y: 0, width: 0.3, height: 1),
                        CGRect(x: 0, y: 0.8, width: 1, height: 0.3), .zero] {
            let geometry = FruitfolioPopupLayout.geometry(assetSize: .init(width: 684, height: 564),
                normalizedWriting: invalid, available: .init(width: 375, height: 667))
            XCTAssertEqual(geometry.artwork, .zero)
            XCTAssertEqual(geometry.writing, .zero)
        }
        let collapsed = FruitfolioPopupLayout.geometry(assetSize: .init(width: 684, height: 564),
            normalizedWriting: valid, available: .init(width: 16, height: 16))
        XCTAssertEqual(collapsed.writing, .zero, "An interrupted zero-area layout must not yield a centered phantom text frame")
        let nonfinite = FruitfolioPopupLayout.geometry(assetSize: .init(width: .infinity, height: 564),
            normalizedWriting: valid, available: .init(width: 375, height: 667))
        XCTAssertEqual(nonfinite.writing, .zero)
    }
}
