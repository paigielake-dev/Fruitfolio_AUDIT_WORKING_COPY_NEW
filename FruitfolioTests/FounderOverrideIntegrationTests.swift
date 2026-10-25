import XCTest
@testable import Fruitfolio

final class FounderOverrideIntegrationTests: XCTestCase {
    func testSharedModalBlurMatchesFounderApprovedCanonicalNonTourTreatment() {
        XCTAssertEqual(FruitfolioModalBlurSpec.radius, 8)
        XCTAssertEqual(FruitfolioModalBlurSpec.contentScale, 0.985, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.dimOpacity, 0.14, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.animationDuration, 0.20, accuracy: 0.0001)
        XCTAssertEqual(FruitfolioModalBlurSpec.reducedMotionDuration, 0.12, accuracy: 0.0001)
    }

    func testPrompt40IsNotRepresentedAsANewProductionPass() {
        XCTAssertFalse(Prompt53ScreenInventory.requiredRoutes.contains("decoration"))
    }

    func testSavedSelectionCanonicalColors() {
        XCTAssertEqual(Prompt55AskSelectionStyle.textHex, "#800000")
        XCTAssertEqual(Prompt55AskSelectionStyle.selectedHighlightHex, "#F4C7C7")
        XCTAssertEqual(Prompt55AskSelectionStyle.sourcesHeading, "sources ˚ ☆ ‧ ₊")
    }
}
