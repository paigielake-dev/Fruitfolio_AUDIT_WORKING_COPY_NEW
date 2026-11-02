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

    func testLeaderboardTotalsAggregateAllTopics() {
        let first = Prompt28TopicProgress(
            normalizedTopicID: "topic-a", highestGameLevelReached: 4,
            totalFruitCaught: 20, totalStarsEarned: 5, totalSuccessfulRounds: 2
        )
        let second = Prompt28TopicProgress(
            normalizedTopicID: "topic-b", highestGameLevelReached: 7,
            totalFruitCaught: 30, totalStarsEarned: 3, totalSuccessfulRounds: 3
        )
        let totals = Prompt28LeaderboardTotals(progress: ["topic-a": first, "topic-b": second])
        XCTAssertEqual(totals.fruitCollected, 50)
        XCTAssertEqual(totals.starsEarned, 8)
        XCTAssertEqual(totals.basketReveals, 5)
        XCTAssertEqual(totals.highestLevel, 7)
    }

    func testLeaderboardTotalsEmptyProgress() {
        let totals = Prompt28LeaderboardTotals(progress: [:])
        XCTAssertEqual(totals.fruitCollected, 0)
        XCTAssertEqual(totals.starsEarned, 0)
        XCTAssertEqual(totals.basketReveals, 0)
        XCTAssertEqual(totals.highestLevel, 0)
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

    func testActualProductionSpawnsRespectTheBoundedGradualLevelScheduleAndNeverRetrofitAnExistingFallSpeed() throws {
        let suite = "Prompt28.ActualSpawnSchedule.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var observed: [[String: Double]] = []
        var previousMinimumDuration = Double.greatestFiniteMagnitude
        var previousMaximumDuration = Double.greatestFiniteMagnitude
        for level in 1...Prompt28FruitBasketEngine.maxGameLevel {
            let store = Prompt28FruitBasketStore(defaults: defaults)
            let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
            model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: level)
            model.currentQuestion = fixtureQuestion(); model.beginCatch()
            if model.showingStormNotice { model.dismissStormNotice() }
            let config = model.levelConfig
            XCTAssertLessThanOrEqual(config.fallDurationRange.lowerBound, previousMinimumDuration)
            XCTAssertLessThanOrEqual(config.fallDurationRange.upperBound, previousMaximumDuration)
            if level > 1 {
                XCTAssertLessThanOrEqual(previousMinimumDuration - config.fallDurationRange.lowerBound, 0.21,
                    "Avoid a new abrupt jump in the preserved gradual schedule")
                XCTAssertLessThanOrEqual(previousMaximumDuration - config.fallDurationRange.upperBound, 0.21)
            }
            previousMinimumDuration = config.fallDurationRange.lowerBound
            previousMaximumDuration = config.fallDurationRange.upperBound
            for index in 0..<24 {
                model.activeFruit = []; model.activeStars = []
                model.tick(delta: 0, now: Date().addingTimeInterval(Double(index + 1) * 10))
                let speeds = model.activeFruit.map(\.fallSpeed) + model.activeStars.map(\.fallSpeed)
                XCTAssertEqual(speeds.count, 1, "Observe a real production spawn rather than a synthetic assigned speed")
                for speed in speeds {
                    XCTAssertGreaterThanOrEqual(speed, 1.18 / config.fallDurationRange.upperBound - 0.000001)
                    XCTAssertLessThanOrEqual(speed, 1.18 / config.fallDurationRange.lowerBound + 0.000001)
                    observed.append(["level": Double(level), "actualSpawnFallSpeed": speed])
                }
                let fruit = model.activeFruit.map { ($0.id, $0.fallSpeed) }
                let stars = model.activeStars.map { ($0.id, $0.fallSpeed) }
                model.tick(delta: 0.001, now: Date().addingTimeInterval(Double(index + 1) * 10 + 0.001))
                for (id, originalSpeed) in fruit {
                    XCTAssertEqual(model.activeFruit.first { $0.id == id }?.fallSpeed, originalSpeed)
                }
                for (id, originalSpeed) in stars {
                    XCTAssertEqual(model.activeStars.first { $0.id == id }?.fallSpeed, originalSpeed)
                }
            }
            model.pause()
        }
        XCTAssertEqual(engine.config(for: Int.max), engine.config(for: 8), "Physics must plateau at the tested maximum")
        let attachment = XCTAttachment(data: try JSONSerialization.data(withJSONObject: observed, options: [.prettyPrinted, .sortedKeys]),
            uniformTypeIdentifier: "public.json")
        attachment.name = "FruitBasket_ActualProductionSpawnSpeedSamples_AllEightLevels"
        attachment.lifetime = .keepAlways; add(attachment)
        // This verifies actual spawned parameters and frame invariants, not
        // subjective comfort, visual obstacle motion, or physical-device feel.
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

    func testCollisionRequiresTheEntireItemInsideTheActualPaintedBasketOpening() {
        for (width, height) in [(320.0, 568.0), (402.0, 874.0), (430.0, 932.0)] {
            let geometry = Prompt28BasketCatchGeometry(fieldWidth: width, fieldHeight: height)
            for diameter in [Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: width),
                             Prompt28BasketCatchGeometry.starDiameter(fieldWidth: width)] {
                let entry = (geometry.mouthY + diameter / 2) / height
                XCTAssertFalse(engine.collision(fruitX: 0.5, fruitY: entry - 0.001, basketX: 0.5,
                    fieldWidth: width, fieldHeight: height, itemDiameter: diameter))
                XCTAssertTrue(engine.collision(fruitX: 0.5, fruitY: entry + 0.001, basketX: 0.5,
                    fieldWidth: width, fieldHeight: height, itemDiameter: diameter))
                let clippedX = 0.5 + (geometry.mouthHalfWidth - diameter / 2 + 1) / width
                XCTAssertFalse(engine.collision(fruitX: clippedX, fruitY: entry + 0.001, basketX: 0.5,
                    fieldWidth: width, fieldHeight: height, itemDiameter: diameter))
                XCTAssertTrue(engine.collision(fruitX: 0.5, fruitY: 1.08, basketX: 0.5,
                    fieldWidth: width, fieldHeight: height, itemDiameter: diameter, previousY: entry - 0.01),
                    "A real full-entry plane crossing must survive a delayed frame")
            }
        }
        XCTAssertFalse(engine.collision(fruitX: 0.5, fruitY: 0.82, basketX: 0.5),
            "The historical point threshold was visibly above the painted basket")
    }

    func testActualStarFrameDoesNotBankUntilFullEntryAndKeepsSettledArtwork() throws {
        let suite = "Prompt28.FullEntry.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive; model.updateGameplayFieldSize(width: 402, height: 874)
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: 402, fieldHeight: 874)
        let entry = (geometry.mouthY + Prompt28BasketCatchGeometry.starDiameter(fieldWidth: 402) / 2) / 874
        let star = Prompt28FallingStar(x: 0.5, y: entry - 0.002, fallSpeed: 0.02, horizontalDrift: 0, rotationDegrees: 0)
        model.activeStars = [star]
        model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        XCTAssertTrue(model.settledCatches.isEmpty)
        model.tick(delta: 0.10, now: Date(timeIntervalSince1970: 1.1))
        XCTAssertEqual(model.session?.availableStarPasses, 0, "Entering the basket starts settling; it must not collect immediately")
        XCTAssertEqual(model.basketCount, 0)
        XCTAssertFalse(model.activeStars.contains(where: { $0.id == star.id }))
        XCTAssertEqual(model.settledCatches.map(\.assetID), [.fruitbasket_star])
        XCTAssertEqual(model.settledCatches.first?.collected, false)
        model.tick(delta: 0.20, now: Date(timeIntervalSince1970: 1.3))
        XCTAssertEqual(model.session?.availableStarPasses, 0, "Elapsed time alone cannot substitute for actual visual settling")
        let presentation = UUID()
        model.handleCatchPresentation(id: star.id, event: .settled(presentation))
        XCTAssertEqual(model.session?.availableStarPasses, 0, "A completion without an actual presentation is not collection")
        model.handleCatchPresentation(id: star.id, event: .appeared(presentation))
        model.handleCatchPresentation(id: star.id, event: .settled(presentation))
        XCTAssertEqual(model.session?.availableStarPasses, 1)
        XCTAssertEqual(model.settledCatches.first?.collected, true)
        model.handleCatchPresentation(id: star.id, event: .settled(presentation))
        XCTAssertEqual(model.session?.availableStarPasses, 1, "A repeated animation completion cannot bank twice")
    }

    func testSettlingAcknowledgementWhilePausedCannotScoreUntilResumingAndNewAttemptClearsPendingArt() throws {
        let suite = "Prompt28.SettlePause.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        model.screen = .catchActive; model.updateGameplayFieldSize(width: 402, height: 874)
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: 402, fieldHeight: 874)
        let diameter = Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: 402)
        let fruit = Prompt28FallingFruit(fruitID: .apple, classification: .good, x: 0.5,
            y: (geometry.mouthY + diameter / 2) / 874 + 0.001, fallSpeed: 0,
            horizontalDrift: 0, rotationDegrees: 0)
        model.activeFruit = [fruit]
        model.tick(delta: 0.01, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(model.score, 0)
        let firstPresentation = UUID()
        model.handleCatchPresentation(id: fruit.id, event: .appeared(firstPresentation))
        model.pause()
        model.handleCatchPresentation(id: fruit.id, event: .settled(firstPresentation))
        model.handleCatchPresentation(id: fruit.id, event: .disappeared(firstPresentation))
        model.tick(delta: 5, now: Date(timeIntervalSince1970: 6))
        XCTAssertEqual(model.score, 0)
        model.resume()
        let resumedPresentation = UUID()
        model.handleCatchPresentation(id: fruit.id, event: .appeared(resumedPresentation))
        model.handleCatchPresentation(id: fruit.id, event: .settled(firstPresentation))
        model.tick(delta: 0.20, now: Date(timeIntervalSince1970: 6.2))
        XCTAssertEqual(model.score, 0, "An old removed animation cannot confirm a new presentation")
        model.handleCatchPresentation(id: fruit.id, event: .settled(resumedPresentation))
        XCTAssertEqual(model.score, 10)
        XCTAssertEqual(model.basketCount, 1)
        model.currentQuestion = fixtureQuestion()
        model.beginCatch()
        XCTAssertFalse(model.isPaused)
        XCTAssertTrue(model.settledCatches.isEmpty)
        model.handleCatchPresentation(id: fruit.id, event: .settled(resumedPresentation))
        XCTAssertEqual(model.basketCount, 0, "An old presentation callback cannot alter a fresh attempt")
        model.viewWillDisappear()
    }

    func testStarPassAccumulationHasNoArtificialCapAndConsumesOneAtATime() {
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        for _ in 0..<10_000 { _ = engine.registerStarCatch(session: &session) }
        XCTAssertEqual(session.availableStarPasses, 10_000)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
        _ = engine.registerBadCatch(.lemon, session: &session)
        XCTAssertEqual(session.availableStarPasses, 9_999)
        XCTAssertEqual(session.goodFruitCaughtThisRound, 0)
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

    func testEveryRainRoundIncludesItsPuddleWithoutAddingAnExtraObstacle() {
        for level in 1...Prompt28FruitBasketEngine.maxGameLevel {
            for round in 1...48 where engine.weather(level: level, round: round) == .softRain {
                let obstacles = engine.activeObstacles(level: level, round: round)
                XCTAssertTrue(obstacles.contains(.puddle), "Rain must create the visible puddle obstacle")
                XCTAssertLessThanOrEqual(obstacles.count, 2)
            }
        }
    }

    func testPuddleResistanceEndsAsSoonAsTheBasketHasLeftThePuddle() throws {
        let suite = "Prompt28.PuddleExit.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "fixture"),
            researchProvider: Prompt28UnavailableResearchProvider(), engine: engine)
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy,
            startingGameLevel: 5, currentRound: 4)
        model.screen = .catchActive; model.basketX = 0.5
        model.updateGameplayFieldSize(width: 402, height: 874)
        model.moveBasket(to: 0.9)
        XCTAssertTrue(model.basketIsMeetingPuddleResistance)
        XCTAssertTrue(model.puddleMovementActive, "The painted basket still overlaps water even after its center passes the puddle edge")
        XCTAssertLessThan(model.basketX, 0.9)
        for _ in 0..<8 { model.moveBasket(to: 0.9) }
        XCTAssertEqual(model.basketX, 0.9)
        XCTAssertFalse(model.basketIsMeetingPuddleResistance)
        model.moveBasket(to: 0.8)
        XCTAssertEqual(model.basketX, 0.8, "Normal movement resumes outside the puddle")
        XCTAssertFalse(model.basketIsMeetingPuddleResistance)
    }

    func testPuddleAudioSignalsFollowActualMovementAndStopOnDragEndAndGameExit() throws {
        let suite = "Prompt28.PuddleAudio.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: .init(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 5, currentRound: 4)
        model.screen = .catchActive; model.basketX = 0.2
        model.moveBasket(to: 0.5)
        XCTAssertTrue(model.puddleContactActive)
        XCTAssertTrue(model.puddleMovementActive)
        model.basketMovementEnded()
        XCTAssertTrue(model.puddleContactActive)
        XCTAssertFalse(model.puddleMovementActive, "Stationary contact is silent")
        model.moveBasket(to: 0.55)
        XCTAssertTrue(model.puddleMovementActive)
        model.viewWillDisappear()
        XCTAssertFalse(model.puddleMovementActive)
        XCTAssertFalse(model.puddleContactActive)
        model.moveBasket(to: 0.6)
        XCTAssertFalse(model.puddleMovementActive, "Paused or departed play cannot emit movement")
    }

    func testRainNoticeUsesExactFounderWordingAndFreezesPlayUntilAcknowledgedOnlyOncePerRound() throws {
        XCTAssertEqual(Prompt28WeatherCopy.stormNotice, "uh oh! a little storm is passing. o__o")
        let suite = "Prompt28.Storm.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 6, currentRound: 3)
        model.currentQuestion = fixtureQuestion(); model.beginCatch()
        XCTAssertTrue(model.showingStormNotice); XCTAssertTrue(model.isPaused)
        model.moveBasket(to: 0.9); XCTAssertEqual(model.basketX, 0.5, "Storm notice blocks gameplay, not just its visible controls")
        model.dismissStormNotice(); XCTAssertFalse(model.showingStormNotice); XCTAssertFalse(model.isPaused)
        model.pause(); model.beginCatch()
        XCTAssertFalse(model.showingStormNotice, "Retrying the same rainy round must not repeat its notice")
        XCTAssertFalse(model.isPaused, "A new catch attempt must not inherit a previous pause flag")
        model.pause()
    }

    func testDismissingStormAfterBackgroundPauseDoesNotAutomaticallyResumeGameplay() throws {
        let suite = "Prompt28.StormBackground.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 6, currentRound: 3)
        model.currentQuestion = fixtureQuestion(); model.beginCatch(); model.sceneBecameInactive()
        model.dismissStormNotice()
        XCTAssertEqual(model.screen, .paused); XCTAssertTrue(model.isPaused)
        XCTAssertFalse(model.showingStormNotice)
    }

    func testLeavingAnActiveGameCancelsItsLoopAndReleasesTheViewModel() async throws {
        let suite = "Prompt28.Leave.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        var model: Prompt28FruitBasketViewModel? = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        weak var observed = model
        model?.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 1)
        model?.currentQuestion = fixtureQuestion(); model?.beginCatch()
        await Task.yield() // Let the real loop enter its first suspended tick.
        model?.viewWillDisappear()
        XCTAssertEqual(model?.screen, .paused)
        model = nil
        try await Task.sleep(nanoseconds: 60_000_000)
        XCTAssertNil(observed, "A hidden game must not be retained by a still-running 30 Hz loop")
    }

    func testAnActiveGameLoopDoesNotRetainItsOwnerAcrossSuspendedFramesEvenWithoutTheViewCallback() async throws {
        let suite = "Prompt28.OwnerLifetime.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var model: Prompt28FruitBasketViewModel? = Prompt28FruitBasketViewModel(
            store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        weak var observed = model
        model?.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 1)
        model?.currentQuestion = fixtureQuestion()
        model?.beginCatch()
        await Task.yield()
        // Deliberately omit the ordinary callback; actual Task ownership must
        // not depend on it to break a permanent self/task retention cycle.
        model = nil
        try await Task.sleep(nanoseconds: 80_000_000)
        XCTAssertNil(observed, "An abandoned host must release its actual active game loop owner")
    }

    func testVineContactFollowsOriginalArtworkAspectRatioAndNotAnEntireHorizontalBand() {
        let geometry = Prompt28VineContactGeometry(fieldWidth: 344, fieldHeight: 896, level: 3)
        XCTAssertEqual(geometry.normalizedArtworkBounds.height, 0.15, accuracy: 0.00001)
        XCTAssertTrue(geometry.contains(x: 0.11, y: 0.54))
        XCTAssertFalse(geometry.contains(x: 0.70, y: 0.54), "Fruit outside the artwork must fall normally")
        XCTAssertFalse(geometry.contains(x: 0.11, y: 0.25))
        XCTAssertFalse(Prompt28VineContactGeometry(fieldWidth: 0, fieldHeight: 0, level: 3).contains(x: 0, y: 0))
    }

    func testActualVineFrameSlowsGoodFruitAndStarsOnlyAndEmitsOneEntryEvent() throws {
        let suite = "Prompt28.Vines.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 2)
        model.screen = .catchActive; model.updateGameplayFieldSize(width: 344, height: 896)
        let good = Prompt28FallingFruit(fruitID: .apple, classification: .good, x: 0.11, y: 0.54, fallSpeed: 0.3, horizontalDrift: 0, rotationDegrees: 0)
        let bad = Prompt28FallingFruit(fruitID: .lemon, classification: .bad, x: 0.11, y: 0.54, fallSpeed: 0.3, horizontalDrift: 0, rotationDegrees: 0)
        let outside = Prompt28FallingFruit(fruitID: .pear, classification: .good, x: 0.7, y: 0.54, fallSpeed: 0.3, horizontalDrift: 0, rotationDegrees: 0)
        let star = Prompt28FallingStar(x: 0.11, y: 0.54, fallSpeed: 0.3, horizontalDrift: 0, rotationDegrees: 0)
        model.activeFruit = [good, bad, outside]; model.activeStars = [star]
        model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(try XCTUnwrap(model.activeFruit.first(where: { $0.id == good.id })).y, 0.5484, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(model.activeFruit.first(where: { $0.id == bad.id })).y, 0.555, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(model.activeFruit.first(where: { $0.id == outside.id })).y, 0.555, accuracy: 0.00001)
        XCTAssertEqual(try XCTUnwrap(model.activeStars.first).y, 0.5484, accuracy: 0.00001)
        XCTAssertEqual(model.vineContactCount, 1)
        XCTAssertEqual(try XCTUnwrap(model.activeFruit.first).fallSpeed, 0.3, "Contact does not rewrite an object's base velocity")
        model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 1.05))
        XCTAssertEqual(model.vineContactCount, 1, "Rustle must not restart on every 30 Hz frame")
        model.viewWillDisappear()
    }

    func testBranchPaintedTrunkMeetsScreenEdgeAndContactDoesNotUseTheWholeImageBox() {
        let geometry = Prompt28BranchContactGeometry(fieldWidth: 344, fieldHeight: 896)
        XCTAssertEqual(geometry.point(originalX: 78, originalY: 410).x, 344, accuracy: 0.00001)
        let contact = geometry.point(originalX: 249, originalY: 257)
        XCTAssertTrue(geometry.contains(x: contact.x / 344, y: contact.y / 896, radius: 0))
        XCTAssertFalse(geometry.contains(x: 0.5, y: 0.4, radius: 20))
        XCTAssertFalse(Prompt28BranchContactGeometry(fieldWidth: 0, fieldHeight: 0).contains(x: 0, y: 0, radius: 20))
    }

    func testActualBranchContactBouncesFruitUpAndLeftThenResumesItsUnchangedBaseFallSpeed() throws {
        let suite = "Prompt28.Branch.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: Prompt28FruitBasketStore(defaults: defaults), researchProvider: Prompt28UnavailableResearchProvider())
        model.session = Prompt28Session(rawTopicQuery: "fixture", normalizedTopicID: "fixture", educationalDifficulty: .easy, startingGameLevel: 3)
        model.screen = .catchActive; model.updateGameplayFieldSize(width: 344, height: 896)
        let point = Prompt28BranchContactGeometry(fieldWidth: 344, fieldHeight: 896).point(originalX: 249, originalY: 257)
        let fruit = Prompt28FallingFruit(fruitID: .apple, classification: .good, x: point.x / 344, y: point.y / 896, fallSpeed: 0.3, horizontalDrift: 0.02, rotationDegrees: 0)
        model.activeFruit = [fruit]
        model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 1))
        let deflected = try XCTUnwrap(model.activeFruit.first)
        XCTAssertEqual(model.branchContactCount, 1, "One physical contact produces one audio event")
        XCTAssertLessThan(deflected.x, fruit.x); XCTAssertLessThan(deflected.y, fruit.y)
        XCTAssertEqual(deflected.fallSpeed, fruit.fallSpeed)
        for index in 1...8 { model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 1 + Double(index) * 0.05)) }
        let falling = try XCTUnwrap(model.activeFruit.first)
        XCTAssertEqual(model.branchContactCount, 1, "Continuous contact must not retrigger impact audio")
        XCTAssertGreaterThan(falling.y, deflected.y)
        XCTAssertLessThan(falling.x, deflected.x)
        XCTAssertEqual(falling.fallSpeed, fruit.fallSpeed)
        model.viewWillDisappear()
    }

    func testActualSettledBadFruitConsumesOnePassAndKeepsTheRoundActiveUntilNoneRemain() async throws {
        let suite = "Fruitfolio.ProtectedCatch.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: .init(defaults: defaults),
            researchProvider: Prompt28UnavailableResearchProvider())
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        session.availableStarPasses = 2
        model.session = session; model.currentQuestion = fixtureQuestion(); model.screen = .catchActive
        model.updateGameplayFieldSize(width: 402, height: 874)
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: 402, fieldHeight: 874)
        let entry = (geometry.mouthY + Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: 402) / 2) / 874
        for attempt in 0..<3 {
            let fruit = Prompt28FallingFruit(fruitID: .lemon, classification: .bad, x: 0.5,
                y: entry - 0.002, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
            model.activeFruit = [fruit]
            model.tick(delta: 0.05, now: Date(timeIntervalSince1970: 100 + Double(attempt)))
            XCTAssertTrue(model.settledCatches.contains { $0.id == fruit.id })
            let presentation = UUID()
            model.handleCatchPresentation(id: fruit.id, event: .appeared(presentation))
            model.handleCatchPresentation(id: fruit.id, event: .settled(presentation))
            model.tick(delta: 0.2, now: Date(timeIntervalSince1970: 100.2 + Double(attempt)))
            XCTAssertEqual(model.session?.availableStarPasses, max(1 - attempt, 0))
            XCTAssertEqual(model.session?.goodFruitCaughtThisRound, 0)
            if attempt < 2 {
                XCTAssertEqual(model.screen, .catchActive)
                XCTAssertFalse(model.isPaused)
                XCTAssertEqual(model.session?.score, 0)
            }
        }
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(model.screen, .catchUnsuccessful, "The first unprotected bad catch ends the actual view-model round")
        model.viewWillDisappear()
    }

    func testRoundRevealUsesActualCollectedFruitStarsAndConsequencesAndResetsOnlyOnTheNextAttempt() async throws {
        let suite = "Fruitfolio.ActualRoundReveal.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = Prompt28FruitBasketViewModel(store: .init(defaults: defaults),
            researchProvider: Prompt28UnavailableResearchProvider())
        var session = engine.newSession(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, startingLevel: 1)
        session.availableStarPasses = 2
        model.session = session; model.currentQuestion = fixtureQuestion(); model.beginCatch()
        model.updateGameplayFieldSize(width: 402, height: 874)
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: 402, fieldHeight: 874)
        var clock: TimeInterval = 200
        func settle(_ id: UUID) {
            model.tick(delta: 0.05, now: Date(timeIntervalSince1970: clock))
            let token = UUID()
            model.handleCatchPresentation(id: id, event: .appeared(token))
            model.handleCatchPresentation(id: id, event: .settled(token))
            model.tick(delta: 0.2, now: Date(timeIntervalSince1970: clock + 0.2))
            clock += 1
        }
        let starEntry = (geometry.mouthY + Prompt28BasketCatchGeometry.starDiameter(fieldWidth: 402) / 2) / 874
        let star = Prompt28FallingStar(x: 0.5, y: starEntry - 0.002, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
        model.activeStars = [star]; settle(star.id)
        let fruitEntry = (geometry.mouthY + Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: 402) / 2) / 874
        let bad = Prompt28FallingFruit(fruitID: .lemon, classification: .bad, x: 0.5,
            y: fruitEntry - 0.002, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
        model.activeFruit = [bad]; settle(bad.id)
        let actualFruit: [Prompt28FruitID] = [.pear, .pear, .apple, .pear, .apple, .apple, .pear, .pear, .apple, .pear]
        for id in actualFruit {
            let fruit = Prompt28FallingFruit(fruitID: id, classification: .good, x: 0.5,
                y: fruitEntry - 0.002, fallSpeed: 0.1, horizontalDrift: 0, rotationDegrees: 0)
            model.activeFruit = [fruit]; settle(fruit.id)
        }
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertEqual(model.screen, .basketReveal)
        XCTAssertEqual(model.roundCollection.goodFruit, actualFruit, "Do not reconstruct decorative fruit from the question pool")
        XCTAssertEqual(model.roundCollection.badFruit, [.lemon])
        XCTAssertEqual(model.roundCollection.standaloneStarsCaught, 1)
        XCTAssertEqual(model.roundCollection.starPassesConsumed, 1)
        XCTAssertEqual(model.availableStarPasses, 2)
        XCTAssertEqual(model.score - model.roundCollection.startingScore, 100)
        XCTAssertEqual(model.settledCatches.filter(\.collected).count, 12)
        let pending = try XCTUnwrap(model.savePendingContent())
        XCTAssertTrue(pending.answer.contains(actualFruit.map(\.displayName).joined(separator: ", ")))
        XCTAssertTrue(pending.answer.contains("standalone stars collected: 1"))
        XCTAssertTrue(pending.answer.contains("star passes used: 1"))
        XCTAssertTrue(pending.answer.contains("score this round: 100"))
        let completed = try XCTUnwrap(model.store.completedRounds.last)
        XCTAssertEqual(completed.question, model.currentQuestion)
        XCTAssertEqual(completed.collection, model.roundCollection)
        XCTAssertEqual(completed.roundScore, 100)
        XCTAssertEqual(completed.remainingStarPasses, 2)
        XCTAssertTrue(completed.successful)
        let restoredStore = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertEqual(restoredStore.completedRounds, [completed], "Restart preserves original question, facts, source versions and real collection")
        restoredStore.recordCompletedRound(completed)
        XCTAssertEqual(restoredStore.completedRounds.count, 1, "Repeated completion cannot duplicate a round")
        let recorded = model.roundCollection
        XCTAssertEqual(try JSONDecoder().decode(Prompt28RoundCollection.self,
            from: JSONEncoder().encode(recorded)), recorded)
        model.beginCatch()
        XCTAssertTrue(model.roundCollection.goodFruit.isEmpty)
        XCTAssertTrue(model.roundCollection.badFruit.isEmpty)
        XCTAssertEqual(model.roundCollection.standaloneStarsCaught, 0)
        XCTAssertEqual(model.roundCollection.starPassesConsumed, 0)
        XCTAssertEqual(model.roundCollection.startingScore, 100)
        XCTAssertEqual(model.roundCollection.startingStarPasses, 2)
        XCTAssertFalse(model.isPaused)
        XCTAssertTrue(pending.answer.contains("standalone stars collected: 1"), "The already prepared saved payload remains immutable")
        model.viewWillDisappear()
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

extension Prompt28FruitBasketTests {
    func testPuddleContactMatchesPaintedBasketAndPuddleWidthsAcrossActualFieldSizes() {
        for width in [280.0, 344, 402, 480] {
            let geometry = Prompt28PuddleContactGeometry(fieldWidth: width)
            XCTAssertTrue(geometry.overlaps(basketX: 0.5))
            XCTAssertTrue(geometry.overlaps(basketX: 0.732), "A wide basket can still touch water with its center beyond0.67")
            XCTAssertFalse(geometry.overlaps(basketX: 0.1))
            XCTAssertFalse(geometry.overlaps(basketX: 0.9))
            let edge = (min(width * 0.34, 190) + Prompt28BasketCatchGeometry(fieldWidth: width, fieldHeight: 874).imageWidth) / 2 / width
            XCTAssertTrue(geometry.overlaps(basketX: 0.5 + edge - 0.001))
            XCTAssertFalse(geometry.overlaps(basketX: 0.5 + edge + 0.001))
        }
        XCTAssertFalse(Prompt28PuddleContactGeometry(fieldWidth: 0).overlaps(basketX: 0.5))
    }
}
