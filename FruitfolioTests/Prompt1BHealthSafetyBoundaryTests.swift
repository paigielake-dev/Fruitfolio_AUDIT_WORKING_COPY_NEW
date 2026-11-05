import XCTest
@testable import Fruitfolio

final class Prompt1BHealthSafetyBoundaryTests: XCTestCase {
    func testFruitWordsDoNotBecomeSexualAssaultClassifications() {
        for word in ["grape", "grapes", "grapefruit", "grapeseed nutrition", "scrapebook"] {
            XCTAssertEqual(Prompt34LocalSafetyRouter.classify(word).level, .normal, word)
        }
    }
    func testRealSensitiveWordRemainsDetectedAtPunctuationBoundaries() {
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("support after rape.").level, .sensitive)
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("(sexual assault)").level, .sensitive)
    }
    func testUrgentPhrasesAcceptNewlinesAndCurlyApostrophes() {
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("heavy\nbleeding").level, .urgent)
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("I can’t breathe").level, .urgent)
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("passing   out").level, .urgent)
    }
    func testPartialWordsAreNotClinicalPatternMatches() {
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("faintingly colored art").level, .normal)
        XCTAssertEqual(Prompt34LocalSafetyRouter.classify("he fainted.").level, .urgent)
    }
}
