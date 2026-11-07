import Foundation
import XCTest
@testable import Fruitfolio

/// Faults affect only this test suite's game key; production uses real defaults.
private final class Prompt1BGameWriteFaultDefaults: UserDefaults, @unchecked Sendable {
    enum Fault { case accept, drop, replace(Data), wrongType }
    var fault: Fault = .accept
    private(set) var writeAttempts = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == "game" else { super.set(value, forKey: key); return }
        writeAttempts += 1
        switch fault {
        case .accept: super.set(value, forKey: key)
        case .drop: break
        case .replace(let bytes): super.set(bytes, forKey: key)
        case .wrongType: super.set("external replacement", forKey: key)
        }
    }
}

@MainActor
final class Prompt1BGamePersistenceTests: XCTestCase {
    private func defaults() throws -> (String, UserDefaults) {
        let name = "Fruitfolio.game-persistence-tests." + UUID().uuidString
        return (name, try XCTUnwrap(UserDefaults(suiteName: name)))
    }
    private func setupWriteFixture(starDropRandomUnit: @escaping @MainActor () -> Double = { Double.random(in: 0...1) }) throws -> (String, Prompt1BGameWriteFaultDefaults, Prompt28FruitBasketStore, Prompt28FruitBasketViewModel) {
        let suite = "Fruitfolio.setup-write-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        var progress = store.ensureProgress(for: "fixture")
        progress.currentGameLevel = 6; progress.highestGameLevelReached = 8
        progress.totalRoundsCompleted = 2
        store.updateProgress(progress)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider(), starDropRandomUnit: starDropRandomUnit)
        model.rawTopic = "fixture"; model.screen = .learningSetup
        return (suite, defaults, store, model)
    }

    func testRejectedNewTopicWriteCannotCreateUnacknowledgedSession() async throws {
        let (suite, defaults, store, model) = try setupWriteFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        model.rawTopic = "new-topic"
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        await model.startTopic()
        XCTAssertTrue(store.isReadOnly)
        XCTAssertNil(model.session)
        XCTAssertNil(store.progress(for: "new-topic"))
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
    }

    func testRejectedReturningTopicResetCannotCreateSession() async throws {
        let (suite, defaults, store, model) = try setupWriteFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        model.screen = .topicProgressChoice
        let original = defaults.data(forKey: "game")
        let accepted = store.topicProgress
        defaults.fault = .drop
        await model.continueReturningTopic(resetLevel: true)
        XCTAssertTrue(store.isReadOnly)
        XCTAssertNil(model.session)
        XCTAssertEqual(model.screen, .topicProgressChoice)
        XCTAssertEqual(store.topicProgress, accepted)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
    }

    func testRejectedLevelResetPreservesSessionUntilFreshAcknowledgedRequest() async throws {
        let (suite, defaults, store, model) = try setupWriteFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        // Domain-level paused session; this does not claim level-six physical gameplay.
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 6)
        model.screen = .paused
        let session = model.session
        let accepted = store.topicProgress
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        model.resetGameLevel()
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(model.session, session)
        XCTAssertEqual(model.screen, .paused)
        XCTAssertEqual(store.topicProgress, accepted)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        defaults.fault = .accept; store.reload()
        model.resetGameLevel() // A fresh explicit request, not automatic replay.
        XCTAssertEqual(model.session?.currentGameLevel, 1)
        XCTAssertEqual(model.session?.startingGameLevel, 1)
        XCTAssertEqual(model.session?.score, session?.score)
        XCTAssertEqual(store.progress(for: "fixture")?.currentGameLevel, 1)
        XCTAssertEqual(store.progress(for: "fixture")?.highestGameLevelReached, 8)
    }

    func testRejectedDifficultyWritePreservesSeparateSessionLevelAndDifficulty() async throws {
        let (suite, defaults, store, model) = try setupWriteFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 6)
        let session = model.session
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        model.updateDifficulty(.hard)
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(model.difficulty, .easy)
        XCTAssertEqual(model.session, session)
        XCTAssertEqual(store.preferredDifficulty, .easy)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        defaults.fault = .accept; store.reload()
        model.updateDifficulty(.hard)
        XCTAssertEqual(model.difficulty, .hard)
        XCTAssertEqual(model.session?.educationalDifficulty, .hard)
        XCTAssertEqual(model.session?.currentGameLevel, 6)
        XCTAssertEqual(model.session?.score, session?.score)
        XCTAssertEqual(store.preferredDifficulty, .hard)
    }

    private func activeModeFixture(mode: Prompt28ControlMode = .classification,
                                   starDropRandomUnit: @escaping @MainActor () -> Double = { Double.random(in: 0...1) }) throws -> (String, Prompt1BGameWriteFaultDefaults, Prompt28FruitBasketStore, Prompt28FruitBasketViewModel) {
        let (suite, defaults, store, model) = try setupWriteFixture(starDropRandomUnit: starDropRandomUnit)
        store.resetCurrentGameLevel(for: "fixture")
        store.controlMode = mode; store.persistPreferences()
        let question = Prompt28Question(id: "credit-fixture", topicQuery: "fixture", normalizedTopic: "fixture", category: "nonclinical test",
            educationalDifficulty: .easy, questionText: "Which visual item has a star?",
            answerOptions: [.init(id: "a", text: "Pear"), .init(id: "b", text: "Lemon")],
            correctAnswerID: "a", explanation: "Nonclinical write-acknowledgement fixture only.",
            sourceIDs: ["qa-only"], sourceTitles: ["Nonclinical fixture"], catchConceptID: "visual-star",
            catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "qa-only", reviewStatus: "test-only", createdAt: Date(timeIntervalSince1970: 0))
        model.currentQuestion = question
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 1)
        model.updatePlayfield(size: CGSize(width: 390, height: 620))
        model.screen = .question
        model.answer("a", expectedQuestionID: question.id)
        model.presentCatchIntro(expectedQuestionID: question.id)
        model.beginCatch(expectedQuestionID: question.id)
        return (suite, defaults, store, model)
    }

    func testRejectedModePreferenceRetainsClassificationFruitAndStarChoices() async throws {
        for isStar in [false, true] {
            let (suite, defaults, store, model) = try activeModeFixture()
            defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
            model.pause()
            if isStar { model.classificationFruit = nil; model.classificationStarAvailable = true }
            let fruitID = model.classificationFruit?.id
            let star = model.classificationStarAvailable
            let session = model.session
            let ledger = model.roundLedger
            let original = defaults.data(forKey: "game")
            defaults.fault = .drop
            model.setControlMode(.catchMode)
            XCTAssertTrue(store.isReadOnly)
            XCTAssertEqual(store.controlMode, .classification)
            XCTAssertEqual(model.classificationFruit?.id, fruitID)
            XCTAssertEqual(model.classificationStarAvailable, star)
            XCTAssertEqual(model.session, session)
            XCTAssertEqual(model.roundLedger, ledger)
            XCTAssertEqual(defaults.data(forKey: "game"), original)
        }
    }

    func testRejectedModePreferenceRetainsPausedPhysicalFruitPresentation() async throws {
        let (suite, defaults, store, model) = try activeModeFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        model.setControlMode(.catchMode); model.pause()
        model.activeFruit = [.init(fruitID: .pear, classification: .good,
            x: 0.25, y: 0.4, fallSpeed: 0.2, horizontalDrift: 0.02, rotationDegrees: 0)]
        let ids = model.activeFruit.map(\.id)
        let session = model.session
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        model.setControlMode(.classification)
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(store.controlMode, .catchMode)
        XCTAssertEqual(model.activeFruit.map(\.id), ids)
        XCTAssertEqual(model.session, session)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
    }

    func testAcceptedActiveClassificationToCatchModeStartsActualOwnedClock() async throws {
        let (suite, defaults, store, model) = try activeModeFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(model.screen, .catchActive)
        XCTAssertTrue(model.activeFruit.isEmpty)
        model.setControlMode(.catchMode)
        let deadline = Date().addingTimeInterval(2)
        while model.activeFruit.isEmpty && Date() < deadline {
            try await Task.sleep(nanoseconds: 2_000_000)
        }
        XCTAssertEqual(store.controlMode, .catchMode)
        XCTAssertFalse(model.activeFruit.isEmpty, "Observe an actual owned-clock spawn, not a manually advanced frame")
    }

    func testModeSetupCallbacksRejectChangedPhaseAndBackgroundIdentity() async throws {
        let (suite, defaults, store, model) = try setupWriteFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        let ticket = model.questionInteractionID
        let original = defaults.data(forKey: "game")
        model.screen = .question
        model.setControlMode(.classification, expectedScreen: .learningSetup, expectedInteractionID: ticket)
        XCTAssertEqual(store.controlMode, .catchMode)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        model.screen = .learningSetup
        model.sceneBecameInactive()
        model.setControlMode(.classification, expectedScreen: .learningSetup, expectedInteractionID: ticket)
        XCTAssertEqual(store.controlMode, .catchMode)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        model.setControlMode(.classification, expectedScreen: .learningSetup,
            expectedInteractionID: model.questionInteractionID)
        XCTAssertEqual(store.controlMode, .classification)
        XCTAssertFalse(store.isReadOnly)
    }

    func testModeChangeCannotInterruptActualPendingSuccessfulRound() async throws {
        let (suite, defaults, store, model) = try activeModeFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        for _ in 0..<model.engine.rules.goodFruitTarget {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: .pear, classification: .good,
                x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        }
        XCTAssertEqual(model.roundLedger.terminalSuccess, true)
        let original = defaults.data(forKey: "game")
        let ledger = model.roundLedger
        model.setControlMode(.catchMode)
        XCTAssertEqual(store.controlMode, .classification)
        XCTAssertEqual(model.roundLedger, ledger)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        model.sceneBecameInactive()
        XCTAssertEqual(model.screen, .basketReveal)
        XCTAssertEqual(model.roundResult?.succeeded, true)
    }

    func testAcceptedModeCyclePreservesEnteringFruitOrStarAndCreditsOnce() async throws {
        for isStar in [false, true] {
            let (suite, defaults, store, model) = try activeModeFixture()
            defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
            if isStar {
                model.classificationFruit = nil; model.classificationStarAvailable = true
                model.classificationStarDecision(accept: true)
            } else {
                model.classificationStarAvailable = false
                model.classificationFruit = .init(fruitID: .pear, classification: .good,
                    x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
                model.classificationDecision(accept: true)
            }
            let entering = model.catchTransits
            XCTAssertEqual(entering.count, 1)
            let session = model.session
            let ledger = model.roundLedger
            model.setControlMode(.catchMode)
            XCTAssertEqual(store.controlMode, .catchMode)
            XCTAssertEqual(model.catchTransits, entering)
            XCTAssertEqual(model.session, session)
            XCTAssertEqual(model.roundLedger, ledger)
            model.setControlMode(.classification)
            XCTAssertEqual(store.controlMode, .classification)
            XCTAssertEqual(model.catchTransits, entering)
            XCTAssertEqual(model.session, session)
            XCTAssertEqual(model.roundLedger, ledger)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
            XCTAssertTrue(model.catchTransits.isEmpty)
            XCTAssertEqual(model.basketCount, isStar ? 0 : 1)
            XCTAssertEqual(model.session?.availableStarPasses, isStar ? 1 : 0)
            XCTAssertEqual(model.session?.score, isStar ? 0 : 10)
            XCTAssertEqual(model.roundLedger.starsCollected, isStar ? 1 : 0)
            XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, isStar ? 0 : 1)
            XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, isStar ? 1 : 0)
            let credited = model.roundLedger
            let accepted = defaults.data(forKey: "game")
            for _ in 0..<20 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
            XCTAssertEqual(model.roundLedger, credited)
            XCTAssertEqual(defaults.data(forKey: "game"), accepted)
        }
    }

    func testObjectDescriptionsDistinguishMarkerAndStandaloneStarWithoutMotionKeys() async {
        var good = Prompt28FallingFruit(fruitID: .pear, classification: .good,
            x: 0.25, y: 0.4, fallSpeed: 0.2, horizontalDrift: 0.02, rotationDegrees: 0)
        let bad = Prompt28FallingFruit(fruitID: .pear, classification: .bad,
            x: 0.25, y: 0.4, fallSpeed: 0.2, horizontalDrift: 0.02, rotationDegrees: 0)
        let goodSource = Prompt28RulesCopy.fruitAccessibilitySource(good)
        let badSource = Prompt28RulesCopy.fruitAccessibilitySource(bad)
        let starSource = Prompt28RulesCopy.standaloneStar
        XCTAssertEqual(Set([goodSource, badSource, starSource]).count, 3)
        XCTAssertTrue(goodSource.contains("attached star marker")); XCTAssertFalse(goodSource.contains("no attached"))
        XCTAssertTrue(badSource.contains("no attached star marker"))
        XCTAssertTrue(starSource.contains("standalone star")); XCTAssertTrue(starSource.contains("one star pass"))
        XCTAssertTrue(starSource.contains("does not fill the fruit basket"))
        good.x = 0.9; good.y = 0.7; good.isInVines = true; good.vineContactTime = 0.4
        XCTAssertEqual(Prompt28RulesCopy.fruitAccessibilitySource(good), goodSource)
        XCTAssertTrue(Prompt28RulesCopy.fruitAccessibilitySource(good, classificationPrompt: true).contains("attached star marker"))
    }

    func testGoodFruitStandaloneStarAndProtectedBadFruitRemainDistinctActualEvents() async throws {
        let (suite, defaults, store, model) = try activeModeFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        model.classificationStarAvailable = false
        model.classificationFruit = .init(fruitID: .pear, classification: .good,
            x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
        model.classificationDecision(accept: true)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.basketCount, 1); XCTAssertEqual(model.session?.score, 10)
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        model.classificationFruit = nil; model.classificationStarAvailable = true
        model.classificationStarDecision(accept: true)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.basketCount, 1); XCTAssertEqual(model.session?.score, 10)
        XCTAssertEqual(model.session?.availableStarPasses, 1)
        model.classificationStarAvailable = false
        model.classificationFruit = .init(fruitID: .lemon, classification: .bad,
            x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
        model.classificationDecision(accept: true)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.basketCount, 1); XCTAssertEqual(model.session?.score, 10)
        XCTAssertEqual(model.session?.availableStarPasses, 0)
        XCTAssertEqual(model.roundLedger.caughtFruit, [.pear])
        XCTAssertEqual(model.roundLedger.starsCollected, 1)
        XCTAssertEqual(model.roundLedger.blockedBadFruit, [.lemon])
        XCTAssertEqual(model.screen, .catchActive); XCTAssertNil(model.roundResult)
        XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, 1)
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 1)
    }

    func testActualClassificationSpawnerHonorsSpacingAndResetsAfterPassedStar() async throws {
        let (suite, defaults, store, model) = try activeModeFixture(starDropRandomUnit: { 0 })
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        for cycle in 1...2 {
            for _ in 0..<8 {
                XCTAssertNotNil(model.classificationFruit)
                XCTAssertFalse(model.classificationStarAvailable)
                model.classificationDecision(accept: false)
            }
            XCTAssertNil(model.classificationFruit); XCTAssertTrue(model.classificationStarAvailable)
            model.classificationStarDecision(accept: false)
            XCTAssertEqual(model.roundLedger.starsPassed, cycle)
            XCTAssertFalse(model.classificationStarAvailable)
        }
        XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.availableStarPasses, 0)
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 0)
    }

    func testActualPhysicalSpawnerHonorsSpacingAndStarCanEnterWithoutFruit() async throws {
        let (suite, defaults, store, model) = try activeModeFixture(mode: .catchMode, starDropRandomUnit: { 0 })
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        let base = Date(timeIntervalSince1970: 10_000)
        for index in 0..<9 {
            // Discard unselected spawn probes to isolate rarity from collisions.
            model.activeFruit.removeAll(); model.activeStars.removeAll()
            model.advanceGameplayFrame(delta: 0.04, now: base.addingTimeInterval(Double(index) * 10))
            XCTAssertEqual(model.activeStars.count, index == 8 ? 1 : 0)
            XCTAssertEqual(model.activeFruit.count, index == 8 ? 0 : 1)
        }
        // Follow the actual last spawned star with the basket through shared physics.
        for frame in 1...500 {
            model.activeFruit.removeAll()
            if let star = model.activeStars.first { model.moveBasket(to: star.x) }
            model.advanceGameplayFrame(delta: 0.04, now: base.addingTimeInterval(80 + Double(frame) * 0.04))
            if model.session?.availableStarPasses == 1 { break }
        }
        XCTAssertEqual(model.session?.availableStarPasses, 1)
        XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.score, 0)
        XCTAssertEqual(model.roundLedger.starsCollected, 1)
        XCTAssertTrue(model.roundLedger.caughtFruit.isEmpty)
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 1)
        XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, 0)
    }

    func testBothActualSpawnersExcludeProbabilityUpperBoundary() async throws {
        for mode in Prompt28ControlMode.allCases {
            let (suite, defaults, store, model) = try activeModeFixture(mode: mode,
                starDropRandomUnit: { Prompt28RareStarPlanner.probability })
            defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
            for index in 0..<32 {
                if mode == .classification {
                    XCTAssertNotNil(model.classificationFruit); XCTAssertFalse(model.classificationStarAvailable)
                    model.classificationDecision(accept: false)
                } else {
                    model.activeFruit.removeAll(); model.activeStars.removeAll()
                    model.advanceGameplayFrame(delta: 0.04, now: Date(timeIntervalSince1970: 10_000 + Double(index) * 10))
                    XCTAssertTrue(model.activeStars.isEmpty); XCTAssertEqual(model.activeFruit.count, 1)
                }
            }
            XCTAssertEqual(model.session?.availableStarPasses, 0)
            XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 0)
        }
    }

    func testActualControllerBankBeyondThousandAcknowledgesEveryStarAndCarriesNextRound() async throws {
        let (suite, defaults, store, model) = try activeModeFixture()
        defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
        let sessionID = model.session?.id
        for _ in 0..<1001 {
            model.classificationFruit = nil; model.classificationStarAvailable = true
            model.classificationStarDecision(accept: true)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        }
        XCTAssertFalse(store.isReadOnly)
        XCTAssertEqual(model.session?.availableStarPasses, 1001)
        XCTAssertEqual(model.roundLedger.starsCollected, 1001)
        XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.score, 0)
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 1001)
        let accepted = defaults.data(forKey: "game")
        let reopened = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        XCTAssertEqual(reopened.progress(for: "fixture")?.totalStarsEarned, 1001)
        XCTAssertEqual(defaults.data(forKey: "game"), accepted)
        model.classificationStarAvailable = false
        model.classificationFruit = .init(fruitID: .lemon, classification: .bad,
            x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
        model.classificationDecision(accept: true)
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertEqual(model.session?.availableStarPasses, 1000)
        XCTAssertEqual(model.screen, .catchActive)
        XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.score, 0)
        for _ in 0..<model.engine.rules.goodFruitTarget {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: .pear, classification: .good,
                x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        }
        model.sceneBecameInactive()
        let result = try XCTUnwrap(model.roundResult)
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.starsCollected, 1001)
        XCTAssertEqual(result.starPassesSpent, 1)
        XCTAssertEqual(result.starPassesRemaining, 1000)
        await model.continueAfterReveal(expectedRoundID: result.roundID,
            expectedInteractionID: model.questionInteractionID)
        XCTAssertEqual(model.session?.id, sessionID)
        XCTAssertEqual(model.session?.currentRound, 2)
        XCTAssertEqual(model.session?.availableStarPasses, 1000)
        XCTAssertEqual(model.session?.score, 100)
        XCTAssertEqual(model.screen, .topicUnsupported, "Existing unavailable provider prevents fabricating the next question")
        XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, 1001)
    }

    func testActualFruitAndStarCreditWaitsBeyondFullEntryUntilSettlement() async throws {
        for isStar in [false, true] {
            let (suite, defaults, store, model) = try activeModeFixture()
            defer { model.leaveScreen(); defaults.removePersistentDomain(forName: suite) }
            if isStar {
                model.classificationFruit = nil; model.classificationStarAvailable = true
                model.classificationStarDecision(accept: true)
            } else {
                model.classificationStarAvailable = false
                model.classificationFruit = .init(fruitID: .pear, classification: .good,
                    x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
                model.classificationDecision(accept: true)
            }
            let original = defaults.data(forKey: "game")
            let ledger = model.roundLedger
            for _ in 0..<3 { model.advanceGameplayFrame(delta: 0.08, now: Date()) }
            let entered = try XCTUnwrap(model.catchTransits.first)
            XCTAssertEqual(entered.progress, 1, accuracy: 0.000001)
            XCTAssertLessThan(entered.elapsed, Prompt28CatchTransit.duration)
            XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.availableStarPasses, 0)
            XCTAssertEqual(model.session?.score, 0); XCTAssertEqual(model.roundLedger, ledger)
            XCTAssertEqual(defaults.data(forKey: "game"), original)
            model.advanceGameplayFrame(delta: 0.08, now: Date())
            XCTAssertFalse(model.catchTransits.isEmpty)
            XCTAssertEqual(model.basketCount, 0); XCTAssertEqual(model.session?.availableStarPasses, 0)
            XCTAssertEqual(defaults.data(forKey: "game"), original)
            model.advanceGameplayFrame(delta: 0.08, now: Date())
            XCTAssertTrue(model.catchTransits.isEmpty)
            XCTAssertEqual(model.basketCount, isStar ? 0 : 1)
            XCTAssertEqual(model.session?.availableStarPasses, isStar ? 1 : 0)
            XCTAssertEqual(model.session?.score, isStar ? 0 : 10)
            XCTAssertEqual(store.progress(for: "fixture")?.totalStarsEarned, isStar ? 1 : 0)
            let accepted = defaults.data(forKey: "game")
            let credited = model.roundLedger
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.08, now: Date()) }
            XCTAssertEqual(model.roundLedger, credited)
            XCTAssertEqual(defaults.data(forKey: "game"), accepted)
        }
    }

    func testSharedFruitAndStarFullEntryPoseIsFlattenedBelowPhysicalRim() async {
        let kinds: [Prompt28CatchTransit.Kind] = [.star, .fruit(.pear, .good)]
        for kind in kinds {
        for relative in [-0.9, 0, 0.9] {
        for reduced in [false, true] {
            var transit = Prompt28CatchTransit(id: UUID(), kind: kind, relativeX: relative)
            XCTAssertFalse(transit.advance(by: Prompt28CatchTransit.entryDuration))
            for size in [CGSize(width: 320, height: 568), CGSize(width: 568, height: 320), CGSize(width: 390, height: 844)] {
                let geometry = Prompt28CatchGeometry(playfield: size)
                XCTAssertTrue(geometry.isValid)
                let mouth = geometry.mouth(basketX: 0.5)
                let pose = geometry.pose(for: transit, basketX: 0.5, reducedMotion: reduced)
                XCTAssertGreaterThan(pose.size.height, 0); XCTAssertLessThan(pose.size.height, pose.size.width)
                XCTAssertGreaterThanOrEqual(pose.center.y - pose.size.height / 2, mouth.minY - 0.000001)
                XCTAssertGreaterThanOrEqual(pose.center.x - pose.size.width / 2, mouth.minX - 0.000001)
                XCTAssertLessThanOrEqual(pose.center.x + pose.size.width / 2, mouth.maxX + 0.000001)
            }
            for size in [CGSize(width: 150, height: 132), CGSize(width: 210, height: 180)] {
                let pose = Prompt28CatchGeometry.localPose(for: transit, basketSize: size, reducedMotion: reduced)
                XCTAssertGreaterThan(pose.size.height, 0); XCTAssertLessThan(pose.size.height, pose.size.width)
                XCTAssertTrue(pose.center.x.isFinite && pose.center.y.isFinite)
                XCTAssertTrue(CGRect(origin: .zero, size: size).contains(pose.center))
            }
        }
        }
        }
    }

    func testRejectedTerminalStatsCannotPublishPersonalBestOrResult() async throws {
        let suite = "Fruitfolio.terminal-round-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        store.controlMode = .classification; store.persistPreferences()
        _ = store.ensureProgress(for: "fixture")
        let question = Prompt28Question(id: "credit-fixture", topicQuery: "fixture", normalizedTopic: "fixture", category: "nonclinical test",
            educationalDifficulty: .easy, questionText: "Which visual item has a star?",
            answerOptions: [.init(id: "a", text: "Pear"), .init(id: "b", text: "Lemon")],
            correctAnswerID: "a", explanation: "Nonclinical write-acknowledgement fixture only.",
            sourceIDs: ["qa-only"], sourceTitles: ["Nonclinical fixture"], catchConceptID: "visual-star",
            catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "qa-only", reviewStatus: "test-only", createdAt: Date(timeIntervalSince1970: 0))
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"; model.currentQuestion = question
        model.session = Prompt28FruitBasketEngine().newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 1)
        model.screen = .question
        model.answer("a", expectedQuestionID: question.id)
        model.presentCatchIntro(expectedQuestionID: question.id)
        model.beginCatch(expectedQuestionID: question.id)
        XCTAssertEqual(model.screen, .catchActive)
        for _ in 0..<model.engine.rules.goodFruitTarget {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: .pear, classification: .good,
                x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        }
        XCTAssertEqual(model.session?.goodFruitCaughtThisRound, model.engine.rules.goodFruitTarget)
        XCTAssertFalse(model.didSetPersonalBestThisRound)
        let accepted = store.topicProgress
        let original = defaults.data(forKey: "game")
        let score = model.session?.score
        defaults.fault = .drop
        model.sceneBecameInactive()
        XCTAssertTrue(store.isReadOnly)
        XCTAssertFalse(model.didSetPersonalBestThisRound, "An unacknowledged terminal write is not a confirmed personal best")
        XCTAssertNil(model.roundResult)
        XCTAssertEqual(store.topicProgress, accepted)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        XCTAssertEqual(model.session?.score, score)
        defaults.fault = .accept
        store.reload(); model.changeTopic()
        XCTAssertEqual(store.topicProgress, accepted)
        XCTAssertEqual(model.screen, .learningSetup)
    }

    func testNewAcceptedRoundClearsPreviousAcknowledgedPersonalBest() async throws {
        let suite = "Fruitfolio.terminal-round-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        store.controlMode = .classification; store.persistPreferences()
        _ = store.ensureProgress(for: "fixture")
        let question = Prompt28Question(id: "credit-fixture", topicQuery: "fixture", normalizedTopic: "fixture", category: "nonclinical test",
            educationalDifficulty: .easy, questionText: "Which visual item has a star?",
            answerOptions: [.init(id: "a", text: "Pear"), .init(id: "b", text: "Lemon")],
            correctAnswerID: "a", explanation: "Nonclinical write-acknowledgement fixture only.",
            sourceIDs: ["qa-only"], sourceTitles: ["Nonclinical fixture"], catchConceptID: "visual-star",
            catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "qa-only", reviewStatus: "test-only", createdAt: Date(timeIntervalSince1970: 0))
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"; model.currentQuestion = question
        model.session = Prompt28FruitBasketEngine().newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 1)
        model.screen = .question
        model.answer("a", expectedQuestionID: question.id)
        model.presentCatchIntro(expectedQuestionID: question.id)
        model.beginCatch(expectedQuestionID: question.id)
        XCTAssertEqual(model.screen, .catchActive)
        for _ in 0..<model.engine.rules.goodFruitTarget {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: .pear, classification: .good,
                x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true)
            for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        }
        model.sceneBecameInactive()
        XCTAssertEqual(model.screen, .basketReveal)
        XCTAssertTrue(model.didSetPersonalBestThisRound)
        model.changeTopic()
        model.rawTopic = "fixture"; model.currentQuestion = question
        model.session = model.engine.newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 1)
        model.screen = .question
        model.answer("a", expectedQuestionID: question.id)
        model.presentCatchIntro(expectedQuestionID: question.id)
        model.beginCatch(expectedQuestionID: question.id)
        XCTAssertEqual(model.screen, .catchActive)
        XCTAssertFalse(model.didSetPersonalBestThisRound)
        XCTAssertNil(model.roundResult)
    }

    func testActualGoodFruitCreditRequiresAcknowledgedProgress() async throws {
        try assertDroppedControllerCredit(isStar: false)
    }

    func testActualStarCreditRequiresAcknowledgedProgress() async throws {
        try assertDroppedControllerCredit(isStar: true)
    }

    private func assertDroppedControllerCredit(isStar: Bool) throws {
        let suite = "Fruitfolio.controller-credit-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        store.controlMode = .classification; store.persistPreferences()
        _ = store.ensureProgress(for: "fixture")
        let question = Prompt28Question(id: "credit-fixture", topicQuery: "fixture", normalizedTopic: "fixture", category: "nonclinical test",
            educationalDifficulty: .easy, questionText: "Which visual item has a star?",
            answerOptions: [.init(id: "a", text: "Pear"), .init(id: "b", text: "Lemon")],
            correctAnswerID: "a", explanation: "Nonclinical write-acknowledgement fixture only.",
            sourceIDs: ["qa-only"], sourceTitles: ["Nonclinical fixture"], catchConceptID: "visual-star",
            catchRule: "starred fruit", goodFruitIDs: [.pear], badFruitIDs: [.lemon],
            contentVersion: "qa-only", reviewStatus: "test-only", createdAt: Date(timeIntervalSince1970: 0))
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"; model.currentQuestion = question
        model.session = Prompt28FruitBasketEngine().newSession(topic: "fixture", normalizedTopic: "fixture",
            difficulty: .easy, startingLevel: 1)
        model.screen = .question
        model.answer("a", expectedQuestionID: question.id)
        model.presentCatchIntro(expectedQuestionID: question.id)
        model.beginCatch(expectedQuestionID: question.id)
        XCTAssertEqual(model.screen, .catchActive)
        if isStar {
            model.classificationFruit = nil; model.classificationStarAvailable = true
            model.classificationStarDecision(accept: true)
        } else {
            model.classificationStarAvailable = false
            model.classificationFruit = .init(fruitID: .pear, classification: .good,
                x: 0.5, fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
            model.classificationDecision(accept: true)
        }
        XCTAssertEqual(model.catchTransits.count, 1)
        let session = model.session
        let ledger = model.roundLedger
        let progress = store.topicProgress
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        for _ in 0..<10 { model.advanceGameplayFrame(delta: 0.04, now: Date()) }
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(model.session, session)
        XCTAssertEqual(model.roundLedger, ledger)
        XCTAssertNil(model.roundResult)
        XCTAssertEqual(store.topicProgress, progress)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        // Preserve actual UI recovery: explicit reload accepts disk, then topic setup.
        defaults.fault = .accept
        store.reload(); model.changeTopic()
        XCTAssertFalse(store.isReadOnly)
        XCTAssertEqual(store.topicProgress, progress)
        XCTAssertEqual(model.screen, .learningSetup)
    }

    func testActualStoreDroppedProgressWriteKeepsAcknowledgedCacheAndOriginalBytes() async throws {
        let suite = "Fruitfolio.game-store-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        var progress = store.ensureProgress(for: "fixture")
        progress.totalFruitCaught = 2
        store.updateProgress(progress)
        let accepted = store.topicProgress
        let original = defaults.data(forKey: "game")
        defaults.fault = .drop
        progress.totalFruitCaught = 99
        store.updateProgress(progress)
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(store.topicProgress, accepted)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        defaults.fault = .accept
        store.reload()
        XCTAssertFalse(store.isReadOnly)
        XCTAssertEqual(store.topicProgress, accepted)
        progress = try XCTUnwrap(store.progress(for: "fixture"))
        progress.totalFruitCaught += 1
        store.updateProgress(progress)
        XCTAssertEqual(store.progress(for: "fixture")?.totalFruitCaught, 3)
    }

    func testActualStoreDroppedCreationHistoryAndTourWritesRetainAcknowledgedValues() async throws {
        for mutation in ["new-topic", "history", "complete-tour", "reset-tour", "preferences"] {
            let suite = "Fruitfolio.game-store-ack." + UUID().uuidString
            let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
            _ = store.ensureProgress(for: "fixture")
            store.recordQuestion("accepted-question", topic: "fixture")
            if mutation == "reset-tour" { store.completeTour() }
            let progress = store.topicProgress
            let history = store.questionHistory
            let tour = store.tourState
            let mode = store.controlMode
            let difficulty = store.preferredDifficulty
            let original = defaults.data(forKey: "game")
            defaults.fault = .drop
            switch mutation {
            case "new-topic": _ = store.ensureProgress(for: "unconfirmed")
            case "history": store.recordQuestion("unconfirmed", topic: "fixture")
            case "complete-tour": store.completeTour()
            case "reset-tour": store.resetTourForReplay()
            default:
                store.controlMode = .classification
                store.preferredDifficulty = .hard
                store.persistPreferences()
            }
            XCTAssertTrue(store.isReadOnly, mutation)
            XCTAssertEqual(store.topicProgress, progress, mutation)
            XCTAssertEqual(store.questionHistory, history, mutation)
            XCTAssertEqual(store.tourState, tour, mutation)
            XCTAssertEqual(store.controlMode, mode, mutation)
            XCTAssertEqual(store.preferredDifficulty, difficulty, mutation)
            XCTAssertEqual(defaults.data(forKey: "game"), original, mutation)
        }
    }

    func testExistingStateKeysAndProgressSurviveStoreReinitialization() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertNil(try store.load())
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", totalRoundsCompleted: 3, totalFruitCaught: 30, totalSuccessfulRounds: 3, bestScore: 300)
        state.questionHistory["fixture"] = ["source:version:question"]
        state.controlMode = .classification
        try store.save(state)
        let original = try XCTUnwrap(defaults.data(forKey: "game"))
        let next = Prompt28GamePersistence(defaults: defaults, key: "game")
        let loaded = try XCTUnwrap(next.load())
        XCTAssertEqual(loaded.topicProgress, state.topicProgress)
        XCTAssertEqual(loaded.questionHistory, state.questionHistory)
        XCTAssertEqual(loaded.controlMode, .classification)
        XCTAssertEqual(defaults.data(forKey: "game"), original, "Loading must not rewrite existing source bytes")
    }
    func testWrongStoredTypeAndCorruptBytesAreNeverOverwritten() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        defaults.set("original wrong-type value", forKey: "game")
        let wrong = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try wrong.load())
        XCTAssertThrowsError(try wrong.save(.init()))
        XCTAssertEqual(defaults.string(forKey: "game"), "original wrong-type value")
        let bytes = Data([0xff, 0x00, 0x7b])
        defaults.set(bytes, forKey: "game")
        let corrupt = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try corrupt.load())
        XCTAssertThrowsError(try corrupt.save(.init()))
        XCTAssertTrue(corrupt.isWriteBlocked)
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testStaleWriterCannotReplaceNewerProgressAndReloadPreservesIt() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let first = Prompt28GamePersistence(defaults: defaults, key: "game")
        let second = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try first.load(); _ = try second.load()
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: 100)
        try second.save(state)
        let committed = defaults.data(forKey: "game")
        XCTAssertThrowsError(try first.save(.init()))
        XCTAssertEqual(first.failure, .changedElsewhere)
        XCTAssertEqual(defaults.data(forKey: "game"), committed)
        var fresh = try XCTUnwrap(first.load())
        fresh.controlMode = .classification
        try first.save(fresh)
        let reloaded = try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load())
        XCTAssertEqual(reloaded.topicProgress["fixture"]?.bestScore, 100)
        XCTAssertEqual(reloaded.controlMode, .classification)
    }
    func testDeletedProgressCannotBeResurrectedByAnOldView() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let old = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try old.load()
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: 100)
        try old.save(state)
        defaults.removeObject(forKey: "game")
        XCTAssertThrowsError(try old.save(state))
        XCTAssertNil(defaults.object(forKey: "game"))
        XCTAssertNil(try old.load(), "Only explicit reload accepts the cleared state")
        try old.save(.init())
        XCTAssertTrue(try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load()).topicProgress.isEmpty)
    }
    func testFutureFormatAndInvalidCountersRemainReadOnlyWithOriginalData() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        var state = Prompt28PersistedGameState(); state.schemaVersion = 2
        let future = try JSONEncoder().encode(state)
        defaults.set(future, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(store.failure, .unsupportedFormat)
        XCTAssertThrowsError(try store.save(.init()))
        XCTAssertEqual(defaults.data(forKey: "game"), future)
        state.schemaVersion = 1
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", bestScore: -1)
        let invalid = try JSONEncoder().encode(state)
        defaults.set(invalid, forKey: "game")
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(store.failure, .invalidState)
        XCTAssertEqual(defaults.data(forKey: "game"), invalid)
    }
    func testLegacyDocumentWithoutFormatOrTierFieldsLoadsWithoutMigrationWrite() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        var state = Prompt28PersistedGameState()
        state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture", totalRoundsCompleted: 3, totalSuccessfulRounds: 3)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
        json.removeValue(forKey: "schemaVersion")
        var topics = try XCTUnwrap(json["topicProgress"] as? [String: [String: Any]])
        topics["fixture"]?.removeValue(forKey: "successesInCurrentLevel")
        topics["fixture"]?.removeValue(forKey: "captureTotalsCompleteFromStart")
        json["topicProgress"] = topics
        let bytes = try JSONSerialization.data(withJSONObject: json)
        defaults.set(bytes, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        let loaded = try XCTUnwrap(store.load())
        XCTAssertNil(loaded.schemaVersion)
        XCTAssertNil(loaded.topicProgress["fixture"]?.successesInCurrentLevel)
        XCTAssertNil(loaded.topicProgress["fixture"]?.captureTotalsCompleteFromStart)
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testBlindWriteBeforeLoadingIsRefused() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let bytes = Data("keep this original".utf8)
        defaults.set(bytes, forKey: "game")
        let store = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertThrowsError(try store.save(.init()))
        XCTAssertEqual(defaults.data(forKey: "game"), bytes)
    }
    func testTierResetAndNextWinRemainGentleAcrossPersistenceReinitialization() async throws {
        let (name, defaults) = try defaults(); defer { defaults.removePersistentDomain(forName: name) }
        let writer = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try writer.load()
        var state = Prompt28PersistedGameState()
        let old = Prompt28TopicProgress(normalizedTopicID: "fixture", currentGameLevel: 8, highestGameLevelReached: 8,
            totalRoundsCompleted: 200, totalSuccessfulRounds: 200, bestScore: 20000)
        state.topicProgress["fixture"] = Prompt28ProgressionPolicy.resettingLevel(old)
        try writer.save(state)
        let next = Prompt28GamePersistence(defaults: defaults, key: "game")
        var restored = try XCTUnwrap(next.load())
        restored.topicProgress["fixture"] = Prompt28ProgressionPolicy.afterSuccessfulRound(try XCTUnwrap(restored.topicProgress["fixture"]))
        try next.save(restored)
        let final = try XCTUnwrap(Prompt28GamePersistence(defaults: defaults, key: "game").load()).topicProgress["fixture"]
        XCTAssertEqual(final?.currentGameLevel, 1)
        XCTAssertEqual(final?.successesInCurrentLevel, 1)
        XCTAssertEqual(final?.highestGameLevelReached, 8)
        XCTAssertEqual(final?.totalSuccessfulRounds, 201)
        XCTAssertEqual(final?.bestScore, 20000)
    }

    func testDroppedReplacementIsNotAcknowledgedAndRequiresExplicitReload() async throws {
        let name = "Fruitfolio.game-write-fault." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let persistence = Prompt28GamePersistence(defaults: defaults, key: "game")
        _ = try persistence.load()
        var state = Prompt28PersistedGameState()
        try persistence.save(state)
        let original = try XCTUnwrap(defaults.data(forKey: "game"))
        defaults.fault = .drop
        state.controlMode = .classification
        XCTAssertThrowsError(try persistence.save(state))
        XCTAssertEqual(persistence.failure, .failedToSave)
        XCTAssertTrue(persistence.isWriteBlocked)
        XCTAssertEqual(defaults.data(forKey: "game"), original)
        defaults.fault = .accept
        let attempts = defaults.writeAttempts
        XCTAssertThrowsError(try persistence.save(state))
        XCTAssertEqual(defaults.writeAttempts, attempts)
        XCTAssertEqual(try persistence.load()?.controlMode, .catchMode)
        try persistence.save(state)
        XCTAssertEqual(try Prompt28GamePersistence(defaults: defaults, key: "game").load()?.controlMode, .classification)
    }
    func testDroppedFirstSaveCannotInventAnAcknowledgedRecord() async throws {
        let name = "Fruitfolio.game-first-write-fault." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let persistence = Prompt28GamePersistence(defaults: defaults, key: "game")
        XCTAssertNil(try persistence.load())
        defaults.fault = .drop
        XCTAssertThrowsError(try persistence.save(.init()))
        XCTAssertNil(defaults.object(forKey: "game"))
        XCTAssertEqual(persistence.failure, .failedToSave)
        XCTAssertTrue(persistence.isWriteBlocked)
    }
    func testPostWriteExternalReplacementRemainsUntouchedRatherThanRolledBack() async throws {
        for wrongType in [false, true] {
            let name = "Fruitfolio.game-replaced-write." + UUID().uuidString
            let defaults = try XCTUnwrap(Prompt1BGameWriteFaultDefaults(suiteName: name))
            defer { defaults.removePersistentDomain(forName: name) }
            let persistence = Prompt28GamePersistence(defaults: defaults, key: "game")
            _ = try persistence.load()
            try persistence.save(.init())
            var foreign = Prompt28PersistedGameState()
            foreign.preferredDifficulty = .hard
            let foreignBytes = try JSONEncoder().encode(foreign)
            defaults.fault = wrongType ? .wrongType : .replace(foreignBytes)
            XCTAssertThrowsError(try persistence.save(.init()))
            XCTAssertEqual(persistence.failure, .failedToSave)
            XCTAssertTrue(persistence.isWriteBlocked)
            XCTAssertEqual(defaults.writeAttempts, 2, "No rollback may overwrite a replacement")
            if wrongType { XCTAssertEqual(defaults.string(forKey: "game"), "external replacement") }
            else { XCTAssertEqual(defaults.data(forKey: "game"), foreignBytes) }
        }
    }
    func testUnknownSameVersionFieldsIncludingNestedNullCannotBeDiscarded() async throws {
        for variant in 0..<4 {
            let (name, defaults) = try defaults()
            defer { defaults.removePersistentDomain(forName: name) }
            var state = Prompt28PersistedGameState()
            state.topicProgress["fixture"] = .init(normalizedTopicID: "fixture")
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(state)) as? [String: Any])
            switch variant {
            case 0: json["future"] = ["preserve": "original"]
            case 1:
                var topics = try XCTUnwrap(json["topicProgress"] as? [String: [String: Any]])
                topics["fixture"]?["future"] = ["sequence": 1]
                json["topicProgress"] = topics
            case 2:
                var tour = try XCTUnwrap(json["tourState"] as? [String: Any])
                tour["future"] = NSNull()
                json["tourState"] = tour
            default:
                var topics = try XCTUnwrap(json["topicProgress"] as? [String: [String: Any]])
                topics["fixture"]?["future"] = NSNull()
                json["topicProgress"] = topics
            }
            let bytes = try JSONSerialization.data(withJSONObject: json)
            defaults.set(bytes, forKey: "game")
            let persistence = Prompt28GamePersistence(defaults: defaults, key: "game")
            XCTAssertThrowsError(try persistence.load(), "Future field variant \(variant)")
            XCTAssertEqual(persistence.failure, .unsupportedFormat)
            XCTAssertTrue(persistence.isWriteBlocked)
            XCTAssertEqual(defaults.data(forKey: "game"), bytes)
            XCTAssertThrowsError(try persistence.save(state))
            XCTAssertEqual(defaults.data(forKey: "game"), bytes)
        }
    }

}
