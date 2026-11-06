import XCTest
@testable import Fruitfolio

final class Prompt1BFruitBasketRulesTests: XCTestCase {
    func testLargeStarBankProtectsEveryBadCatchWithoutCreditingFruitOrScore() {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "nonclinical fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        let bank = 1_000
        for _ in 0..<bank { XCTAssertEqual(engine.registerStarCatch(session: &session), .active) }
        XCTAssertEqual(session.availableStarPasses, bank)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
        XCTAssertEqual(session.score, 0)
        for remaining in stride(from: bank - 1, through: 0, by: -1) {
            XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .badFruitBlockedByStar(badFruit: .lemon))
            XCTAssertEqual(session.availableStarPasses, remaining)
        }
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .unsuccessful(badFruit: .lemon))
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
        XCTAssertEqual(session.score, 0)
    }

    func testBadFruitWithoutStarPassEndsRoundImmediately() {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .unsuccessful(badFruit: .lemon))
        XCTAssertEqual(session.availableStarPasses, 0)
    }
    func testBadFruitConsumesExactlyOnePassAndContinues() {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        for _ in 0..<3 { _ = engine.registerStarCatch(session: &session) }
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .badFruitBlockedByStar(badFruit: .lemon))
        XCTAssertEqual(session.availableStarPasses, 2)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
    }
}
