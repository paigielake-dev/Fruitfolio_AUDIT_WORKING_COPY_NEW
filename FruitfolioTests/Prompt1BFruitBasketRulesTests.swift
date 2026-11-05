import XCTest
@testable import Fruitfolio

final class Prompt1BFruitBasketRulesTests: XCTestCase {
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
