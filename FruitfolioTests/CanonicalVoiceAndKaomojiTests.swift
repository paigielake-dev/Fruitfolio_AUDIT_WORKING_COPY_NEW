import XCTest
@testable import Fruitfolio

final class CanonicalVoiceAndKaomojiTests: XCTestCase {
    func testVoiceBridgeCannotRewriteEvidenceUnitsIdentifiersOrSafetyQualifiers() {
        let body = "☆ TSH: 2.50 ng/mL [source-1]. This does NOT confirm ovulation.\n- Keep the original qualifier."
        for serious in [false, true] {
            let document = FruitfolioCanonicalVoice.evidenceDocument(body, serious: serious)
            XCTAssertEqual(document.spans.last?.text, body)
            XCTAssertTrue(document.plainText.hasSuffix(body))
            XCTAssertEqual(document.spans.last?.emphasis, .plain,
                           "Voice must not invent semantic emphasis or reclassify source words using keyword replacement")
        }
        XCTAssertTrue(FruitfolioCanonicalVoice.evidenceDocument("  \n", serious: false).spans.isEmpty)
    }

    func testSeriousLabConsentAndFruitBasketContentNeverReceivesKaomojis() {
        var system = FruitfolioKaomojiSystem()
        for domain: FruitfolioKaomojiDomain in [.serious, .urgent, .labInterpretation, .abuseOrConsent, .fruitBasketQuestion, .fruitBasketReveal] {
            for beat in FruitfolioEmotionalBeat.allCases {
                XCTAssertNil(system.choose(for: beat, domain: domain, unusuallyCasual: true, allowRareExpression: true))
            }
        }
        XCTAssertTrue(system.recent.isEmpty)
    }

    func testRarityLimitsAndRecentChoiceSuppressionRespectTheFounderMaximumOfThree() throws {
        var system = FruitfolioKaomojiSystem()
        XCTAssertNil(system.choose(for: nil, domain: .generalEducation))
        let first = try XCTUnwrap(system.choose(for: .curious, domain: .generalEducation))
        XCTAssertNil(system.choose(for: .curious, domain: .generalEducation, usedInAnswer: [first]))
        let second = try XCTUnwrap(system.choose(for: .curious, domain: .generalEducation, usedInAnswer: [first], longerPlayful: true))
        XCTAssertNotEqual(first, second)
        XCTAssertNil(system.choose(for: .curious, domain: .generalEducation, usedInAnswer: [first, second], longerPlayful: true))
        let third = try XCTUnwrap(system.choose(for: .curious, domain: .generalEducation, usedInAnswer: [first, second], unusuallyCasual: true))
        XCTAssertEqual(Set([first, second, third]).count, 3)
        XCTAssertNil(system.choose(for: .curious, domain: .generalEducation, usedInAnswer: [first, second, third], unusuallyCasual: true))
        XCTAssertEqual(Prompt54CanonicalVoicePolicy.maximumKaomojiPerAnswer, 3)
        XCTAssertEqual(Prompt54CanonicalVoicePolicy.preferredKaomojiRange, 0...1)
    }

    func testRareExpressionRequiresExplicitMatchingMomentApproval() {
        var system = FruitfolioKaomojiSystem()
        for beat: FruitfolioEmotionalBeat in [.surprised, .awkward, .celebratory] {
            XCTAssertNil(system.choose(for: beat, domain: .generalEducation))
            XCTAssertNotNil(system.choose(for: beat, domain: .generalEducation, allowRareExpression: true))
        }
    }
}
