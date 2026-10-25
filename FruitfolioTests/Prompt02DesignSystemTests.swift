import XCTest
@testable import Fruitfolio

final class Prompt02DesignSystemTests: XCTestCase {
    func testReferenceCanvasIsDesignReferenceSize() {
        XCTAssertEqual(DesignTokens.ReferenceCanvas.width, 393)
        XCTAssertEqual(DesignTokens.ReferenceCanvas.height, 852)
    }

    func testMinimumHitTargetIs44() {
        XCTAssertGreaterThanOrEqual(DesignTokens.Layout.minimumHitTarget, 44)
    }

    func testMinimumHorizontalMarginIs16() {
        XCTAssertEqual(DesignTokens.Layout.minimumHorizontalMargin, 16)
    }

    func testPreferredMarginsRemain20To24() {
        XCTAssertEqual(DesignTokens.Layout.preferredHorizontalMargin.lowerBound, 20)
        XCTAssertEqual(DesignTokens.Layout.preferredHorizontalMargin.upperBound, 24)
    }

    func testScaleGuardrailsMatchCanonicalPrompt() {
        XCTAssertEqual(DesignTokens.Layout.tinyFleck, 0.03...0.06)
        XCTAssertEqual(DesignTokens.Layout.smallDecoration, 0.06...0.12)
        XCTAssertEqual(DesignTokens.Layout.tinyFunctionalIcon, 0.05...0.08)
        XCTAssertEqual(DesignTokens.Layout.normalFunctionalIllustration, 0.10...0.17)
        XCTAssertEqual(DesignTokens.Layout.fruitCharacter, 0.14...0.23)
        XCTAssertEqual(DesignTokens.Layout.mediumIllustration, 0.18...0.30)
        XCTAssertEqual(DesignTokens.Layout.majorBiologyIllustration, 0.32...0.48)
        XCTAssertEqual(DesignTokens.Layout.heroIllustration, 0.48...0.70)
        XCTAssertEqual(DesignTokens.Layout.bookEnvironment, 0.84...1.00)
    }

    func testMotionRangesMatchCanonicalPrompt() {
        XCTAssertEqual(DesignTokens.Motion.micro, 0.080...0.180)
        XCTAssertEqual(DesignTokens.Motion.component, 0.200...0.450)
        XCTAssertEqual(DesignTokens.Motion.storybook, 0.600...1.000)
        XCTAssertEqual(DesignTokens.Motion.celebration, 0.800...1.800)
    }

    func testSemanticHubColorMemoryMapIsStable() {
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["Ask the Encyclopedia"], .inquiry)
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["My Encyclopedias"], .organization)
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["Build Your Own Guide"], .creation)
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["Cycle Tracker"], .bodyAction)
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["Fruit Basket"], .playReward)
        XCTAssertEqual(FruitfolioColorTheory.hubMemoryMap["FAQ"], .helpReference)
    }

    func testBurgundyContrastOnCoreLightPaletteIsAtLeastAAForNormalText() {
        let backgrounds: [FruitfolioRGB] = [
            .init(hex: 0xFFF9F0),
            .init(hex: 0xCBDAC3),
            .init(hex: 0xE2DEAF),
            .init(hex: 0xFEDF9C),
            .init(hex: 0xFDAC9F),
            .init(hex: 0xFEF0AD),
            .init(hex: 0xF1CDF4),
            .init(hex: 0xB8CBD5)
        ]

        for background in backgrounds {
            XCTAssertGreaterThanOrEqual(
                FruitfolioContrast.ratio(.init(hex: 0x6F273D), background),
                4.5
            )
        }
    }

    func testAllAudioCategoriesRemainIndependent() {
        XCTAssertEqual(Set(FruitfolioAudioCategory.allCases).count, 4)
        XCTAssertTrue(FruitfolioAudioCategory.allCases.contains(.music))
        XCTAssertTrue(FruitfolioAudioCategory.allCases.contains(.rainAmbience))
        XCTAssertTrue(FruitfolioAudioCategory.allCases.contains(.soundEffects))
        XCTAssertTrue(FruitfolioAudioCategory.allCases.contains(.typingASMR))
    }

    func testPrompt01RegistryStillContains265Assets() {
        XCTAssertEqual(AssetRegistry.all.count, 265)
    }
}
