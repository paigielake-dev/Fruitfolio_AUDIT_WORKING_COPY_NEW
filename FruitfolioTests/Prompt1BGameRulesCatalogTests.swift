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
