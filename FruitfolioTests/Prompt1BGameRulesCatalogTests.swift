import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BGameRulesCatalogTests: XCTestCase {
    func testFAQExposesCurrentRulesResultsTotalsAndAccessibleAlternative() throws {
        let sections = Prompt29FAQCatalog.sections
        XCTAssertEqual(Set(sections.map(\.id)).count, sections.count)
        let items = sections.flatMap(\.items)
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        let basket = try XCTUnwrap(sections.first { $0.id == "basket" })
        XCTAssertEqual(Set(basket.items.map(\.answer)), Set([
            Prompt28RulesCopy.catches + " " + Prompt28RulesCopy.protection,
            Prompt28RulesCopy.results, Prompt28RulesCopy.totals, Prompt28RulesCopy.accessibleMode
        ]))
    }

    func testTutorialFAQAndCollectibleDescribeDelayedBankingAndNoFruitOrPoints() throws {
        let tourRule = try XCTUnwrap(Prompt28TourCatalog.pages.first { $0.showsFruitDemo })
        let faq = try XCTUnwrap(Prompt29FAQCatalog.sections.first { $0.id == "basket" })
        let faqRule = try XCTUnwrap(faq.items.first { $0.answer.contains("standalone stars are rare") })
        for source in [tourRule.body, faqRule.answer, Prompt28RulesCopy.protection] {
            XCTAssertTrue(source.contains("fully enters and settles"))
            XCTAssertTrue(source.contains("no fixed limit"))
            XCTAssertTrue(source.contains("do not fill the basket or add points"))
            XCTAssertTrue(source.contains("exactly one available pass"))
            XCTAssertTrue(source.contains("not into a new session"))
        }
        XCTAssertTrue(Prompt28RulesCopy.standaloneStar.contains("fully enters and settles"))
        XCTAssertTrue(Prompt28RulesCopy.standaloneStar.contains("does not fill the fruit basket or add points"))
        XCTAssertTrue(Prompt28TourCatalog.pages.last?.body.contains("fully enters and settles") == true)
        XCTAssertTrue(Prompt28TourCatalog.pages.last?.body.contains("question difficulty and game level stay separate") == true)
    }

    func testDocumentedScoreAndProtectionMatchActualEngineWithoutFruitCreditForStars() {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        XCTAssertEqual(engine.registerStarCatch(session: &session), .active)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
        XCTAssertEqual(session.score, 0)
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .badFruitBlockedByStar(badFruit: .lemon))
        XCTAssertEqual(session.availableStarPasses, 0)
        XCTAssertEqual(engine.registerGoodMiss(session: &session), .active)
        XCTAssertEqual(engine.registerBadMiss(session: &session), .active)
        for index in 1...engine.rules.goodFruitTarget {
            XCTAssertEqual(engine.registerGoodCatch(session: &session), index == engine.rules.goodFruitTarget ? .success : .active)
        }
        XCTAssertEqual(session.score, engine.rules.goodFruitTarget * engine.rules.goodFruitCatchScore)
        XCTAssertTrue(Prompt28RulesCopy.catches.contains("\(engine.rules.goodFruitTarget) starred"))
        XCTAssertTrue(Prompt28RulesCopy.catches.contains("+\(engine.rules.goodFruitCatchScore) points"))
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .unsuccessful(badFruit: .lemon))
        XCTAssertEqual(session.score, 100)
    }
}
