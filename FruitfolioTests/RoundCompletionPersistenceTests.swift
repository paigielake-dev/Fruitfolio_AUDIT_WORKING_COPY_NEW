import XCTest
@testable import Fruitfolio

@MainActor
final class RoundCompletionPersistenceTests: XCTestCase {
    private func model(defaults: UserDefaults) async throws -> Prompt28FruitBasketViewModel {
        let store = Prompt28FruitBasketStore(defaults: defaults)
        store.controlMode = .classification
        let question = try await Prompt28CanonicalResearchProvider().question(topic: "nutrition", normalizedTopic: "nutrition",
                                                                             difficulty: .easy, excludingQuestionIDs: [])
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
        model.rawTopic = "nutrition"
        model.currentQuestion = question
        model.session = Prompt28Session(rawTopicQuery: "nutrition", normalizedTopicID: "nutrition",
                                         educationalDifficulty: .easy, startingGameLevel: 1)
        model.screen = .catchActive
        return model
    }
    private func accept(_ fruit: Prompt28FruitID, classification: Prompt28FruitClassification,
                        in model: Prompt28FruitBasketViewModel) {
        model.classificationFruit = .init(fruitID: fruit, classification: classification, x: 0.5,
                                           fallSpeed: 0, horizontalDrift: 0, rotationDegrees: 0)
        model.classificationDecision(accept: true)
    }
    private func finishGoodBasket(_ model: Prompt28FruitBasketViewModel) throws {
        let choices = try XCTUnwrap(model.currentQuestion?.goodFruitIDs)
        for index in 0..<Prompt28FruitBasketEngine.goodFruitTarget {
            accept(choices[index % choices.count], classification: .good, in: model)
        }
    }

    func testCompletedRoundIsPersistedAtFinalRegisteredCatchEvenIfHostDisappearsBeforeRevealDelay() async throws {
        let suite = "RoundImmediateCommit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var game: Prompt28FruitBasketViewModel? = try await model(defaults: defaults)
        weak var observed = game
        try finishGoodBasket(try XCTUnwrap(game))
        let stored = try XCTUnwrap(game?.store.completedRounds.first)
        XCTAssertTrue(stored.successful)
        XCTAssertEqual(stored.collection.goodFruit.count, 10)
        XCTAssertTrue(stored.question.hasVerifiedEvidenceSnapshot)
        game = nil // Deliberately omit onDisappear; a registered result must already be durable.
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertNil(observed)
        let reopened = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertEqual(reopened.completedRounds, [stored])
        XCTAssertEqual(reopened.progress(for: "nutrition")?.totalRoundsCompleted, 1)
    }

    func testPauseCannotCancelALockedSuccessAndRepeatedBackgroundCallbacksDoNotCountTwice() async throws {
        let suite = "RoundBackgroundCommit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        try finishGoodBasket(game)
        game.pause()
        XCTAssertEqual(game.screen, .catchActive)
        XCTAssertFalse(game.isPaused)
        game.sceneBecameInactive()
        XCTAssertEqual(game.screen, .basketReveal)
        game.sceneBecameInactive(); game.viewWillDisappear()
        try await Task.sleep(for: .milliseconds(750))
        XCTAssertEqual(game.store.completedRounds.count, 1)
        XCTAssertEqual(game.store.progress(for: "nutrition")?.totalRoundsCompleted, 1)
        XCTAssertEqual(game.store.progress(for: "nutrition")?.totalSuccessfulRounds, 1)
    }

    func testUnprotectedBadCatchCommitsActualFailureImmediatelyAndCannotMoveAfterLogicalRoundEnd() async throws {
        let suite = "RoundBadCommit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        let fruit = try XCTUnwrap(game.currentQuestion?.badFruitIDs.first)
        accept(fruit, classification: .bad, in: game)
        let stored = try XCTUnwrap(game.store.completedRounds.first)
        XCTAssertFalse(stored.successful)
        XCTAssertEqual(stored.collection.badFruit, [fruit])
        XCTAssertEqual(stored.finalScore, 0)
        let basket = game.basketX
        game.moveBasket(to: 0.8)
        XCTAssertEqual(game.basketX, basket)
        game.viewWillDisappear()
        XCTAssertEqual(game.screen, .catchUnsuccessful)
        let reopened = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertEqual(reopened.completedRounds, [stored])
        XCTAssertEqual(reopened.progress(for: "nutrition")?.totalRoundsCompleted, 1)
        XCTAssertEqual(reopened.progress(for: "nutrition")?.totalSuccessfulRounds, 0)
    }

    func testRetryDuringPendingFailureKeepsOriginalRecordAndStartsFreshUnpausedAttempt() async throws {
        let suite = "RoundRetryCommit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        let fruit = try XCTUnwrap(game.currentQuestion?.badFruitIDs.first)
        accept(fruit, classification: .bad, in: game)
        let original = game.store.completedRounds
        game.retryRound()
        XCTAssertEqual(game.screen, .catchActive)
        XCTAssertFalse(game.isPaused)
        XCTAssertEqual(game.basketCount, 0)
        XCTAssertTrue(game.roundCollection.badFruit.isEmpty)
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(game.screen, .catchActive, "The previous attempt's delayed result must not reopen")
        XCTAssertEqual(game.store.completedRounds, original)
        game.viewWillDisappear()
    }

    func testDuplicateStoredRoundIdentitiesFailExplicitlyWithoutDroppingEvidenceOrReplacingBytes() async throws {
        let suite = "RoundDuplicateIdentity-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        try finishGoodBasket(game)
        game.viewWillDisappear()
        let record = try XCTUnwrap(game.store.completedRounds.first)
        let progress = try XCTUnwrap(game.store.progress(for: "nutrition"))
        let saved = try XCTUnwrap(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"))
        var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: saved) as? [String: Any])
        let rounds = try XCTUnwrap(snapshot["completedRounds"] as? [[String: Any]])
        snapshot["completedRounds"] = rounds + rounds
        let unreadable = try JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])
        defaults.set(unreadable, forKey: "fruitfolio.prompt28.fruitBasket.v1")
        let reopened = Prompt28FruitBasketStore(defaults: defaults)
        XCTAssertNotNil(reopened.loadError)
        XCTAssertFalse(reopened.commitCompletedRound(record, updating: progress))
        reopened.persistPreferences()
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"), unreadable)
        XCTAssertTrue(reopened.completedRounds.isEmpty,
                      "Do not present an ambiguous subset as successfully restored history")
    }

    func testRejectedRoundSnapshotDoesNotPublishProgressOrReplaceSavedBytes() async throws {
        let suite = "RoundSnapshotRejection-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        try finishGoodBasket(game)
        let record = try XCTUnwrap(game.store.completedRounds.first)
        let before = try XCTUnwrap(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"))
        let originalProgress = game.store.topicProgress
        var next = try XCTUnwrap(game.store.progress(for: "nutrition"))
        next.totalRoundsCompleted += 1
        let invalid = Prompt28CompletedRound(id: UUID(), sessionID: record.sessionID, round: 2,
            completedAt: Date(timeIntervalSinceReferenceDate: .infinity), successful: true,
            question: record.question, collection: record.collection, finalScore: record.finalScore,
            remainingStarPasses: record.remainingStarPasses, personalBest: false,
            educationalFacts: record.educationalFacts)
        XCTAssertFalse(game.store.commitCompletedRound(invalid, updating: next))
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"), before)
        XCTAssertEqual(game.store.topicProgress, originalProgress)
        XCTAssertEqual(game.store.completedRounds, [record])
        // A second commit of an already stored record cannot increment progress.
        XCTAssertTrue(game.store.commitCompletedRound(record, updating: next))
        XCTAssertEqual(game.store.topicProgress, originalProgress)
        XCTAssertEqual(Prompt28FruitBasketStore(defaults: defaults).completedRounds, [record])
        game.viewWillDisappear()
    }

    func testOrdinaryDelayedRevealPresentsAlreadyCommittedResultWithoutCountingItAgain() async throws {
        let suite = "RoundNormalCommit-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let game = try await model(defaults: defaults)
        try finishGoodBasket(game)
        XCTAssertEqual(game.store.completedRounds.count, 1)
        try await Task.sleep(for: .milliseconds(750))
        XCTAssertEqual(game.screen, .basketReveal)
        XCTAssertEqual(game.store.completedRounds.count, 1)
        XCTAssertEqual(game.store.progress(for: "nutrition")?.totalRoundsCompleted, 1)
        game.viewWillDisappear()
    }
}
