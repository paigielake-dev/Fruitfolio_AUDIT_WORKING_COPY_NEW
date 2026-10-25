import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt28FruitBasketTests: XCTestCase {
    private let engine = Prompt28FruitBasketEngine()

    func testCanonicalRoundRulesNeverScaleTarget() {
        XCTAssertEqual(Prompt28FruitBasketEngine.goodFruitTarget, 10)
        XCTAssertEqual(Prompt28RoundRules.canonical.goodFruitTarget, 10)
        for level in 1...Prompt28FruitBasketEngine.maxGameLevel {
            _ = engine.config(for: level)
            XCTAssertEqual(Prompt28RoundRules.canonical.goodFruitTarget, 10)
        }
    }

    func testGameLevelCeilingIsEight() {
        XCTAssertEqual(engine.clampedLevel(0), 1)
        XCTAssertEqual(engine.clampedLevel(9), 8)
        XCTAssertEqual(engine.config(for: 99).level, 8)
    }

    func testTopicNormalizationIsStable() {
        XCTAssertEqual(engine.normalizeTopic("  PCOS   and Insulin Resistance  "), "pcos and insulin resistance")
    }

    func testGoodCatchAddsExactlyTenPointsAndOneProgress() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .hard, startingLevel: 1)
        let outcome = engine.registerGoodCatch(session: &session)
        XCTAssertEqual(outcome, .active)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 1)
        XCTAssertEqual(session.score, 10)
        XCTAssertEqual(session.fruitCaught, 1)
    }

    func testTenthGoodCatchCompletesRound() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .easy, startingLevel: 8)
        for _ in 0..<9 { XCTAssertEqual(engine.registerGoodCatch(session: &session), .active) }
        XCTAssertEqual(engine.registerGoodCatch(session: &session), .success)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 10)
        XCTAssertEqual(session.score, 100)
    }

    func testMissingGoodFruitHasNoPenalty() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .medium, startingLevel: 4)
        _ = engine.registerGoodCatch(session: &session)
        let before = session
        XCTAssertEqual(engine.registerGoodMiss(session: &session), .active)
        XCTAssertEqual(session.goodFruitCaughtThisRound, before.goodFruitCaughtThisRound)
        XCTAssertEqual(session.score, before.score)
        XCTAssertEqual(session.currentStreak, before.currentStreak)
    }

    func testMissingBadFruitHasNoPenalty() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .medium, startingLevel: 4)
        let before = session
        XCTAssertEqual(engine.registerBadMiss(session: &session), .active)
        XCTAssertEqual(session, before)
    }

    func testBadCatchWithoutStarPassEndsRound() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .hard, startingLevel: 7)
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .unsuccessful(badFruit: .lemon))
    }

    func testLifetimeStarsPersistAcrossEncoding() throws {
        let original = Prompt28TopicProgress(
            normalizedTopicID: "pcos",
            totalStarsEarned: 7
        )

        let data = try JSONEncoder().encode(original)
        let restored = try JSONDecoder().decode(Prompt28TopicProgress.self, from: data)

        XCTAssertEqual(restored.totalStarsEarned, 7)
        XCTAssertEqual(restored.normalizedTopicID, "pcos")
    }

    func testLegacyProgressDefaultsLifetimeStarsToZero() throws {
        let original = Prompt28TopicProgress(
            normalizedTopicID: "endometriosis",
            totalFruitCaught: 45,
            totalSuccessfulRounds: 3
        )

        let data = try JSONEncoder().encode(original)
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        object.removeValue(forKey: "totalStarsEarned")

        let legacyData = try JSONSerialization.data(withJSONObject: object)
        let restored = try JSONDecoder().decode(
            Prompt28TopicProgress.self,
            from: legacyData
        )

        XCTAssertEqual(restored.totalStarsEarned, 0)
        XCTAssertEqual(restored.totalFruitCaught, 45)
        XCTAssertEqual(restored.totalSuccessfulRounds, 3)
    }

    @MainActor
    func testLifetimeStarsSurviveProgressStoreUpdates() {
        let suite = "Prompt28Stars.\\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = Prompt28FruitBasketStore(
            defaults: defaults,
            persistenceKey: "test"
        )

        var progress = store.ensureProgress(for: "pcos")
        progress.totalStarsEarned += 1
        store.updateProgress(progress)

        XCTAssertEqual(store.progress(for: "pcos")?.totalStarsEarned, 1)

        store.resetCurrentGameLevel(for: "pcos")

        XCTAssertEqual(store.progress(for: "pcos")?.totalStarsEarned, 1)
    }

    func testStandaloneStarsBankWithoutLimitAndProtectBadCatch() {
        var session = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .hard, startingLevel: 7)
        for _ in 0..<3 { XCTAssertEqual(engine.registerStarCatch(session: &session), .active) }
        XCTAssertEqual(session.availableStarPasses, 3)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
        XCTAssertEqual(engine.registerBadCatch(.lemon, session: &session), .badFruitBlockedByStar(badFruit: .lemon))
        XCTAssertEqual(session.availableStarPasses, 2)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
    }

    func testEducationalDifficultyDoesNotChangePhysicsConfig() {
        let easy = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .easy, startingLevel: 7)
        let hard = engine.newSession(topic: "demo", normalizedTopic: "demo", difficulty: .hard, startingLevel: 7)
        XCTAssertEqual(engine.config(for: easy.currentGameLevel), engine.config(for: hard.currentGameLevel))
    }

    func testNewSessionKeepsTopicDifficultyAndGameLevelIndependent() {
        let session = engine.newSession(topic: "endometriosis", normalizedTopic: "endometriosis", difficulty: .hard, startingLevel: 1)
        XCTAssertEqual(session.educationalDifficulty, .hard)
        XCTAssertEqual(session.currentGameLevel, 1)
    }

    func testSuccessfulRoundProgressionPlateaus() {
        XCTAssertEqual(engine.levelAfterSuccessfulRounds(0), 1)
        XCTAssertEqual(engine.levelAfterSuccessfulRounds(2), 2)
        XCTAssertEqual(engine.levelAfterSuccessfulRounds(20), 8)
        XCTAssertEqual(engine.levelAfterSuccessfulRounds(200), 8)
    }

    func testSpawnPlannerNeverCreatesMoreThanTwoBadInARow() {
        var planner = Prompt28SpawnPlanner()
        let results = (0..<12).map { _ in planner.nextClassification(goodProbability: 0, randomUnit: 1) }
        var run = 0
        var maxRun = 0
        for result in results {
            if result == .bad { run += 1; maxRun = max(maxRun, run) } else { run = 0 }
        }
        XCTAssertLessThanOrEqual(maxRun, 2)
    }

    func testQuestionRequiresSourcesAndDisjointFruitSets() {
        let valid = fixtureQuestion()
        XCTAssertTrue(valid.isPlayable)
        let invalid = Prompt28Question(
            id: "bad", topicQuery: "demo", normalizedTopic: "demo", category: "demo",
            educationalDifficulty: .easy,
            questionText: "demo?",
            answerOptions: [.init(id: "a", text: "a"), .init(id: "b", text: "b")],
            correctAnswerID: "a", explanation: "demo", sourceIDs: [], sourceTitles: [],
            catchConceptID: "demo", catchRule: "demo", goodFruitIDs: [.apple], badFruitIDs: [.lemon],
            contentVersion: "1", reviewStatus: "approved", createdAt: Date()
        )
        XCTAssertFalse(invalid.isPlayable)
    }

    @MainActor
    func testResetPreservesHistoricalProgress() {
        let suite = "Prompt28FruitBasketTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "test")
        store.updateProgress(.init(normalizedTopicID: "pcos", currentGameLevel: 7, highestGameLevelReached: 8, totalRoundsCompleted: 20, totalFruitCaught: 100, totalSuccessfulRounds: 10, bestScore: 700, bestStreak: 9))
        store.resetCurrentGameLevel(for: "pcos")
        let progress = store.progress(for: "pcos")
        XCTAssertEqual(progress?.currentGameLevel, 1)
        XCTAssertEqual(progress?.highestGameLevelReached, 8)
        XCTAssertEqual(progress?.bestScore, 700)
        XCTAssertEqual(progress?.totalFruitCaught, 100)
    }

    @MainActor
    func testNewTopicStartsAtLevelOneWithoutMutatingOtherTopic() {
        let suite = "Prompt28FruitBasketTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "test")
        store.updateProgress(.init(normalizedTopicID: "pcos", currentGameLevel: 7, highestGameLevelReached: 7))
        let newProgress = store.ensureProgress(for: "endometriosis")
        XCTAssertEqual(newProgress.currentGameLevel, 1)
        XCTAssertEqual(store.progress(for: "pcos")?.currentGameLevel, 7)
    }

    func testAllTenFruitAssetsHaveCanonicalMappings() {
        XCTAssertEqual(Prompt28FruitID.allCases.count, 10)
        XCTAssertEqual(Set(Prompt28FruitID.allCases.map(\.assetID)).count, 10)
    }

    @MainActor
    func testAllTwentyFourFruitBasketAssetsAreRegisteredForProductionRoutes() {
        XCTAssertEqual(Prompt28AssetUsageRegistrar.allFruitBasketAssets.count, 24)
        XCTAssertEqual(Set(Prompt28AssetUsageRegistrar.allFruitBasketAssets).count, 24)
        Prompt28AssetUsageRegistrar.markProductionRoutes()
        for id in Prompt28AssetUsageRegistrar.allFruitBasketAssets {
            XCTAssertFalse(AssetUsageLedger.shared.entries[id]?.exactReachableProductionStates.isEmpty ?? true)
        }
    }

    func testCollisionUsesNormalizedCoordinates() {
        XCTAssertTrue(engine.collision(fruitX: 0.5, fruitY: 0.85, basketX: 0.5))
        XCTAssertFalse(engine.collision(fruitX: 0.1, fruitY: 0.85, basketX: 0.9))
        XCTAssertFalse(engine.collision(fruitX: 0.5, fruitY: 0.5, basketX: 0.5))
    }

    func testWeatherStaysLevelDrivenNotEducationalDifficultyDriven() {
        XCTAssertEqual(engine.weather(level: 1, round: 3), .clear)
        XCTAssertEqual(engine.weather(level: 3, round: 2), .breezy)
        XCTAssertEqual(engine.weather(level: 6, round: 3), .softRain)
    }


    func testObstaclePlanStaysLimitedAndLevelDriven() {
        XCTAssertTrue(engine.activeObstacles(level: 1, round: 1).isEmpty)
        XCTAssertEqual(engine.activeObstacles(level: 2, round: 1), [.vines])

        for level in 1...Prompt28FruitBasketEngine.maxGameLevel {
            for round in 1...12 {
                XCTAssertLessThanOrEqual(
                    engine.activeObstacles(level: level, round: round).count,
                    2,
                    "Fruit Basket should not stack every obstacle at once."
                )
            }
        }
    }

    func testWindDirectionIsPredictableByRound() {
        XCTAssertEqual(engine.windDirection(round: 1), 1)
        XCTAssertEqual(engine.windDirection(round: 2), -1)
        XCTAssertEqual(engine.windDirection(round: 3), 1)
    }

    func testVinesOnlyNarrowLaneAtHigherLevels() {
        XCTAssertEqual(engine.fruitLaneBounds(level: 1, round: 1), 0.08...0.92)
        XCTAssertEqual(engine.fruitLaneBounds(level: 2, round: 1), 0.09...0.91)
        XCTAssertEqual(engine.fruitLaneBounds(level: 5, round: 4), 0.12...0.88)
    }

    func testLeaderboardUsernamePolicyProtectsBoardLayoutAndModeration() {
        XCTAssertTrue(Prompt28LeaderboardUsernamePolicy.isValid("fruit.friend_12"))
        XCTAssertFalse(Prompt28LeaderboardUsernamePolicy.isValid("ab"))
        XCTAssertFalse(Prompt28LeaderboardUsernamePolicy.isValid("abcdefghijklmnopq"))
        XCTAssertFalse(Prompt28LeaderboardUsernamePolicy.isValid("nude_friend"))
        XCTAssertFalse(Prompt28LeaderboardUsernamePolicy.isValid("f4ck_friend"))
        XCTAssertEqual(
            Prompt28LeaderboardUsernamePolicy.sanitized("fruit friend✨123456789"),
            "fruitfriend12345"
        )
    }

    @MainActor
    func testPuddleAddsMildInertiaWithoutTakingAwayBasketControl() {
        let suite = "Prompt28FruitBasketTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "puddle-test")
        let viewModel = Prompt28FruitBasketViewModel(
            store: store,
            researchProvider: Prompt28UnavailableResearchProvider(),
            engine: engine
        )
        viewModel.session = Prompt28Session(
            rawTopicQuery: "demo",
            normalizedTopicID: "demo",
            educationalDifficulty: .easy,
            startingGameLevel: 5,
            currentRound: 4
        )
        viewModel.screen = .catchActive
        viewModel.basketX = 0.5
        viewModel.moveBasket(to: 0.9)

        XCTAssertGreaterThan(viewModel.basketX, 0.5)
        XCTAssertLessThan(viewModel.basketX, 0.9)
        XCTAssertGreaterThanOrEqual(viewModel.basketX, 0.10)
        XCTAssertLessThanOrEqual(viewModel.basketX, 0.90)
    }

    private func fixtureQuestion() -> Prompt28Question {
        Prompt28Question(
            id: "q1", topicQuery: "demo", normalizedTopic: "demo", category: "demo",
            educationalDifficulty: .medium,
            questionText: "which option matches the approved demo rule?",
            answerOptions: [.init(id: "a", text: "one"), .init(id: "b", text: "two")],
            correctAnswerID: "a", explanation: "fixture explanation", sourceIDs: ["source-1"], sourceTitles: ["Fixture Source"],
            catchConceptID: "demo", catchRule: "collect the fixture category", goodFruitIDs: [.apple, .pear], badFruitIDs: [.lemon, .plum],
            contentVersion: "test-v1", reviewStatus: "approved", createdAt: Date()
        )
    }

    func testFounderFacingLearningTopicsAreExact() {
        XCTAssertEqual(
            Prompt28LearningTopic.allCases.map(\.displayName),
            ["reproductive health", "hormones", "nutrition", "surrogacy", "women’s wellness"]
        )
    }

    func testNewAudioSemanticIDsAreRegistered() {
        XCTAssertNotNil(FruitfolioAudioDesign.descriptors[.fruitBasketWind])
        XCTAssertNotNil(FruitfolioAudioDesign.descriptors[.notificationSoftSparkle])
        XCTAssertEqual(FruitfolioAudioID.notificationSoftSparkle.rawValue, "audio_notification")
        XCTAssertEqual(FruitfolioAudioID.fruitBasketWind.rawValue, "audio_fruitbasket_wind_gust")
    }

}
