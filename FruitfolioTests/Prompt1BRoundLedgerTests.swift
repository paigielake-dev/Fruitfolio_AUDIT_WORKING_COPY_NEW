import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BRoundLedgerTests: XCTestCase {
    func testDisplayFormattingPreservesEveryIntegerDigitAcrossAllAppLocales() {
        for language in FruitfolioLanguage.allCases {
            for value in [0, 7, 1000, Int.max, Int.min] {
                let formatted = Prompt28GameStatisticFormatting.integer(value, language: language)
                let digits = formatted.compactMap(\.wholeNumberValue).map(String.init).joined()
                XCTAssertEqual(digits, String(value.magnitude), language.rawValue)
                if value < 0 {
                    XCTAssertTrue(formatted.contains("-") || formatted.contains("−"), language.rawValue)
                }
            }
            let signedZero = Prompt28GameStatisticFormatting.integer(0, language: language, signed: true)
            XCTAssertTrue(signedZero.contains("+"), language.rawValue)
        }
    }

    func testFractionAndSignedScoreKeepOriginalValuesAndEnglishCompatibility() {
        XCTAssertEqual(Prompt28GameStatisticFormatting.fraction(7, target: 10, language: .english), "7 / 10")
        XCTAssertEqual(Prompt28GameStatisticFormatting.integer(0, language: .english, signed: true), "+0")
        XCTAssertEqual(Prompt28GameStatisticFormatting.integer(-7, language: .english, signed: true), "-7")
        for language in FruitfolioLanguage.allCases {
            let value = Prompt28GameStatisticFormatting.fraction(7, target: 10, language: language)
            let parts = value.components(separatedBy: " / ")
            XCTAssertEqual(parts.count, 2)
            XCTAssertEqual(parts[0].compactMap(\.wholeNumberValue), [7])
            XCTAssertEqual(parts[1].compactMap(\.wholeNumberValue), [1, 0])
        }
    }

    func testNineGoodFruitCannotCreateACompletedRevealAndDuplicateEventsDoNotCount() throws {
        var ledger = Prompt28RoundLedger()
        var first: UUID?
        for _ in 0..<9 {
            let id = UUID(); if first == nil { first = id }
            XCTAssertTrue(ledger.recordGoodFruit(.pear, eventID: id))
        }
        XCTAssertNil(ledger.result(score: 90, passesRemaining: 0, nextGameLevel: 1))
        XCTAssertFalse(ledger.recordGoodFruit(.apple, eventID: try XCTUnwrap(first)))
        XCTAssertFalse(ledger.recordStar(eventID: try XCTUnwrap(first)))
        XCTAssertEqual(ledger.caughtFruit.count, 9)
        XCTAssertTrue(ledger.recordGoodFruit(.strawberry, eventID: UUID()))
        let result = try XCTUnwrap(ledger.result(score: 100, passesRemaining: 0, nextGameLevel: 1))
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.caughtFruit, Array(repeating: .pear, count: 9) + [.strawberry])
        XCTAssertFalse(ledger.recordStar(eventID: UUID()), "No late reward may alter a completed round")
        XCTAssertEqual(ledger.result(score: 100, passesRemaining: 0, nextGameLevel: 1), result)
    }
    func testUnprotectedBadFruitProducesAnActualPartialAttemptResult() throws {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        var ledger = Prompt28RoundLedger()
        for _ in 0..<7 {
            XCTAssertTrue(ledger.recordGoodFruit(.pear, eventID: UUID()))
            _ = engine.registerGoodCatch(session: &session)
        }
        let outcome = engine.registerBadCatch(.lemon, session: &session)
        XCTAssertTrue(ledger.recordBadFruit(.lemon, outcome: outcome, eventID: UUID()))
        let result = try XCTUnwrap(ledger.result(score: session.score, passesRemaining: session.availableStarPasses, nextGameLevel: 1))
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.caughtFruit.count, 7)
        XCTAssertEqual(result.endingBadFruit, .lemon)
        XCTAssertEqual(result.scoreChange, 70)
        XCTAssertEqual(result.starPassesSpent, 0)
        XCTAssertFalse(ledger.recordGoodFruit(.apple, eventID: UUID()))
    }
    func testStarsPassSpendingAndEarnedVersusCumulativeScoreRemainDistinct() throws {
        let engine = Prompt28FruitBasketEngine()
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 3)
        session.score = 20; session.availableStarPasses = 2
        var ledger = Prompt28RoundLedger(gameLevelPlayed: 3, startingScore: 20, startingPasses: 2)
        XCTAssertTrue(ledger.recordStar(eventID: UUID()))
        _ = engine.registerStarCatch(session: &session)
        XCTAssertEqual(ledger.caughtFruit.count, 0)
        let outcome = engine.registerBadCatch(.lemon, session: &session)
        XCTAssertTrue(ledger.recordBadFruit(.lemon, outcome: outcome, eventID: UUID()))
        XCTAssertNil(ledger.terminalSuccess)
        for _ in 0..<10 {
            XCTAssertTrue(ledger.recordGoodFruit(.orange, eventID: UUID()))
            _ = engine.registerGoodCatch(session: &session)
        }
        let result = try XCTUnwrap(ledger.result(score: session.score, passesRemaining: session.availableStarPasses, nextGameLevel: 4))
        XCTAssertEqual(result.starsCollected, 1)
        XCTAssertEqual(result.starPassesAtStart, 2)
        XCTAssertEqual(result.starPassesSpent, 1)
        XCTAssertEqual(result.starPassesRemaining, 2)
        XCTAssertEqual(result.starPassesAtStart + result.starsCollected - result.starPassesSpent, result.starPassesRemaining)
        XCTAssertEqual(result.scoreChange, 100)
        XCTAssertEqual(result.cumulativeScore, 120)
        XCTAssertEqual(result.gameLevelPlayed, 3)
        XCTAssertEqual(result.nextGameLevel, 4)
    }
    func testPassedFruitAndStarsNeverBecomeInventedCatchesOrPenalties() throws {
        var ledger = Prompt28RoundLedger()
        let id = UUID()
        XCTAssertTrue(ledger.recordPassedFruit(.good, eventID: id))
        XCTAssertFalse(ledger.recordPassedFruit(.good, eventID: id))
        XCTAssertTrue(ledger.recordPassedFruit(.bad, eventID: UUID()))
        XCTAssertTrue(ledger.recordPassedStar(eventID: UUID()))
        XCTAssertEqual(ledger.goodFruitPassed, 1)
        XCTAssertEqual(ledger.badFruitPassed, 1)
        XCTAssertEqual(ledger.starsPassed, 1)
        XCTAssertTrue(ledger.caughtFruit.isEmpty)
        XCTAssertEqual(ledger.starsCollected, 0)
        XCTAssertNil(ledger.result(score: 0, passesRemaining: 0, nextGameLevel: 1))
    }
    func testFinishedSnapshotRetainsItsOriginalValuesWhenAnotherRoundBegins() throws {
        var ledger = Prompt28RoundLedger()
        for _ in 0..<10 { _ = ledger.recordGoodFruit(.pear, eventID: UUID()) }
        let result = try XCTUnwrap(ledger.result(score: 100, passesRemaining: 0, nextGameLevel: 1))
        let firstID = result.roundID
        ledger = Prompt28RoundLedger(gameLevelPlayed: 2, startingScore: 100, startingPasses: 0)
        _ = ledger.recordStar(eventID: UUID())
        XCTAssertNotEqual(ledger.roundID, firstID)
        XCTAssertEqual(result.starsCollected, 0)
        XCTAssertEqual(result.caughtFruit.count, 10)
        XCTAssertEqual(result.cumulativeScore, 100)
    }
}
