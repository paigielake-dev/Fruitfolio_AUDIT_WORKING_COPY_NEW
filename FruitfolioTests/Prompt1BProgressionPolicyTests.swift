import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BProgressionPolicyTests: XCTestCase {
    func testResetDoesNotJumpBackToLifetimeLevelAfterOneSuccess() {
        let old = Prompt28TopicProgress(normalizedTopicID: "fixture", currentGameLevel: 8, highestGameLevelReached: 8,
            totalRoundsCompleted: 200, totalFruitCaught: 2000, totalStarsEarned: 50, totalSuccessfulRounds: 200, bestScore: 20000)
        var reset = Prompt28ProgressionPolicy.resettingLevel(old)
        XCTAssertEqual(reset.currentGameLevel, 1)
        XCTAssertEqual(reset.highestGameLevelReached, 8)
        XCTAssertEqual(reset.totalFruitCaught, 2000)
        XCTAssertEqual(reset.totalStarsEarned, 50)
        XCTAssertEqual(reset.bestScore, 20000)
        reset = Prompt28ProgressionPolicy.afterSuccessfulRound(reset)
        XCTAssertEqual(reset.currentGameLevel, 1)
        XCTAssertEqual(reset.totalSuccessfulRounds, 201)
        reset = Prompt28ProgressionPolicy.afterSuccessfulRound(reset)
        XCTAssertEqual(reset.currentGameLevel, 2)
    }
    func testFailuresCannotIncreaseLevelOrConsumeSuccessfulProgressionCredit() {
        var progress = Prompt28TopicProgress(normalizedTopicID: "fixture", totalRoundsCompleted: 1, totalSuccessfulRounds: 1, successesInCurrentLevel: 1)
        for _ in 0..<100 { progress = Prompt28ProgressionPolicy.afterUnsuccessfulRound(progress) }
        XCTAssertEqual(progress.currentGameLevel, 1)
        XCTAssertEqual(progress.successesInCurrentLevel, 1)
        XCTAssertEqual(progress.totalSuccessfulRounds, 1)
        XCTAssertEqual(Prompt28ProgressionPolicy.afterSuccessfulRound(progress).currentGameLevel, 2)
    }
    func testFreshProgressionRetainsGradualExistingThresholdsAndStopsAtMaximum() {
        let engine = Prompt28FruitBasketEngine()
        var progress = Prompt28TopicProgress(normalizedTopicID: "fixture")
        for wins in 1...1000 {
            progress = Prompt28ProgressionPolicy.afterSuccessfulRound(progress)
            XCTAssertEqual(progress.currentGameLevel, engine.levelAfterSuccessfulRounds(wins))
            XCTAssertLessThanOrEqual(progress.currentGameLevel, 8)
        }
        XCTAssertEqual(progress.highestGameLevelReached, 8)
        XCTAssertEqual(progress.successesInCurrentLevel, 0)
        XCTAssertEqual(engine.config(for: 1000), engine.config(for: 8))
    }
    func testLegacyTierCreditIsUsedOnlyWhenConsistentWithObservedLevel() {
        let regular = Prompt28TopicProgress(normalizedTopicID: "fixture", currentGameLevel: 2, highestGameLevelReached: 2,
            totalRoundsCompleted: 3, totalSuccessfulRounds: 3, successesInCurrentLevel: nil)
        XCTAssertEqual(Prompt28ProgressionPolicy.afterSuccessfulRound(regular).currentGameLevel, 3)
        let legacyReset = Prompt28TopicProgress(normalizedTopicID: "fixture", currentGameLevel: 1, highestGameLevelReached: 8,
            totalRoundsCompleted: 200, totalSuccessfulRounds: 200, successesInCurrentLevel: nil)
        XCTAssertEqual(Prompt28ProgressionPolicy.afterSuccessfulRound(legacyReset).currentGameLevel, 1)
    }
    func testDifficultyBoundsAndQuestionDepthRemainIndependent() {
        let engine = Prompt28FruitBasketEngine()
        var previous = engine.config(for: 1)
        for level in 1...8 {
            let config = engine.config(for: level)
            XCTAssertGreaterThanOrEqual(config.fallDurationRange.lowerBound, 2.8)
            XCTAssertLessThanOrEqual(config.fallDurationRange.lowerBound, previous.fallDurationRange.lowerBound)
            XCTAssertGreaterThan(config.spawnIntervalRange.lowerBound, 0.8)
            XCTAssertLessThanOrEqual(config.maxConcurrentItems, 4)
            for difficulty in Prompt28EducationalDifficulty.allCases {
                let session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: difficulty, startingLevel: level)
                XCTAssertEqual(engine.config(for: session.currentGameLevel), config)
            }
            previous = config
        }
    }
}
