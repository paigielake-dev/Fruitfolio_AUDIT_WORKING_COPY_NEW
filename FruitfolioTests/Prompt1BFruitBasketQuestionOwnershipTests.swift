import Foundation
import XCTest
@testable import Fruitfolio

private final class Prompt1BQuestionWriteFaultDefaults: UserDefaults, @unchecked Sendable {
    var dropWrites = false
    override func set(_ value: Any?, forKey key: String) {
        if key == "game", dropWrites { return }
        super.set(value, forKey: key)
    }
}

private actor Prompt1BDelayedGameResearch: Prompt28ResearchProviding {
    private var completion: CheckedContinuation<Void, Never>?
    private var waiting: CheckedContinuation<Void, Never>?
    private var started = false
    private let fail: Bool
    private let failure: Prompt28ResearchError?
    init(fail: Bool = false, failure: Prompt28ResearchError? = nil) {
        self.fail = fail; self.failure = failure
    }
    func question(topic: String, normalizedTopic: String, difficulty: Prompt28EducationalDifficulty,
                  excludingQuestionIDs: Set<String>) async throws -> Prompt28Question {
        await withCheckedContinuation { continuation in
            completion = continuation; started = true
            waiting?.resume(); waiting = nil
        }
        if let failure { throw failure }
        if fail { throw Prompt28ResearchError.providerUnavailable }
        return Prompt28Question(id: "fixture-question", topicQuery: topic, normalizedTopic: normalizedTopic,
            category: "test fixture", educationalDifficulty: difficulty, questionText: "nonmedical test question",
            answerOptions: [.init(id: "a", text: "fixture a"), .init(id: "b", text: "fixture b")],
            correctAnswerID: "a", explanation: "nonmedical test fixture", sourceIDs: ["fixture"], sourceTitles: ["Fixture"],
            catchConceptID: "test", catchRule: "starred fruit", goodFruitIDs: [.apple], badFruitIDs: [.lemon],
            contentVersion: "fixture", reviewStatus: "test only", createdAt: Date())
    }
    func waitForStart() async {
        if started { return }
        await withCheckedContinuation { waiting = $0 }
    }
    func finish() { completion?.resume(); completion = nil }
}

@MainActor
final class Prompt1BFruitBasketQuestionOwnershipTests: XCTestCase {
    func testSeriousUnsupportedAndExhaustedErrorsUseControlledCalmMessages() async throws {
        for error in [Prompt28ResearchError.unsupportedTopic, .topicExhausted] {
        for (topic, serious) in [("pregnancy loss", true), ("watercolor", false)] {
            let suite = "Fruitfolio.calm-research-errors." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt28FruitBasketStore(defaults: defaults)
            let provider = Prompt1BDelayedGameResearch(failure: error)
            let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
            defer { model.leaveScreen() }
            model.rawTopic = topic
            let task = Task { await model.loadQuestion() }
            await provider.waitForStart(); await provider.finish(); await task.value
            let calm = error == .unsupportedTopic
                ? "there is not enough approved research for this topic in the FruitsofLife.xo library yet."
                : "the available questions for this topic have been used. choose another topic."
            XCTAssertEqual(model.message, serious ? calm : error.localizedDescription)
            XCTAssertEqual(model.screen, error == .topicExhausted ? .topicExhausted : .topicUnsupported)
            XCTAssertEqual(model.setupMessageRequiresSeriousTone, serious)
            XCTAssertEqual(model.rawTopic, topic)
            XCTAssertNil(model.currentQuestion)
            XCTAssertTrue(store.questionHistory.isEmpty)
        }
        }
    }

    func testActualUrgentProviderErrorKeepsCanonicalUrgentMessageInAllContexts() async throws {
        for topic in ["severe bleeding", "watercolor"] {
            let suite = "Fruitfolio.urgent-source-preserved." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt28FruitBasketStore(defaults: defaults)
            let provider = Prompt1BDelayedGameResearch(failure: .urgentTopic)
            let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
            defer { model.leaveScreen() }
            model.rawTopic = topic
            let task = Task { await model.loadQuestion() }
            await provider.waitForStart(); await provider.finish(); await task.value
            XCTAssertEqual(model.message, Prompt34LocalSafetyRouter.urgentResponseText())
            XCTAssertTrue(model.setupMessageRequiresSeriousTone)
            XCTAssertEqual(model.screen, .topicUnsupported)
            XCTAssertTrue(store.questionHistory.isEmpty)
        }
    }

    func testActualUnavailableProviderSetupToneUsesLocalContextWithoutChangingMessage() async throws {
        for (topic, serious) in [("severe bleeding", true), ("pregnancy loss", true), ("watercolor", false)] {
            let suite = "Fruitfolio.setup-tone." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt28FruitBasketStore(defaults: defaults)
            let model = Prompt28FruitBasketViewModel(store: store, researchProvider: Prompt28UnavailableResearchProvider())
            defer { model.leaveScreen() }
            model.rawTopic = topic
            await model.loadQuestion()
            XCTAssertEqual(model.screen, .topicUnsupported)
            XCTAssertEqual(model.message, Prompt28ResearchError.providerUnavailable.localizedDescription)
            XCTAssertEqual(model.setupMessageRequiresSeriousTone, serious)
            XCTAssertEqual(model.rawTopic, topic)
            XCTAssertNil(model.currentQuestion)
            XCTAssertTrue(store.questionHistory.isEmpty)
        }
    }

    func testProtectedStoreRejectsLateQuestionAfterExternalDeletion() async throws {
        let suite = "Fruitfolio.question-protected." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        _ = store.ensureProgress(for: "fixture")
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        defaults.removeObject(forKey: "game")
        XCTAssertFalse(store.persistPreferences())
        XCTAssertTrue(store.isReadOnly)
        await provider.finish(); await task.value
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(store.questionHistory["fixture"])
        XCTAssertNil(defaults.object(forKey: "game"), "Never resurrect externally removed data")
    }

    func testRejectedQuestionHistoryWriteCannotExposeUnacknowledgedQuestion() async throws {
        let suite = "Fruitfolio.question-history-ack." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BQuestionWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        _ = store.ensureProgress(for: "fixture")
        let original = defaults.data(forKey: "game")
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        defaults.dropWrites = true
        await provider.finish(); await task.value
        XCTAssertTrue(store.isReadOnly)
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(store.questionHistory["fixture"])
        XCTAssertEqual(defaults.data(forKey: "game"), original)
    }

    func testProtectedStoreRejectsLateProviderErrorWithoutReplacingSetupMessage() async throws {
        let suite = "Fruitfolio.question-protected-error." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        _ = store.ensureProgress(for: "fixture")
        let provider = Prompt1BDelayedGameResearch(fail: true)
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        defaults.removeObject(forKey: "game")
        XCTAssertFalse(store.persistPreferences())
        await provider.finish(); await task.value
        XCTAssertTrue(store.isReadOnly)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(model.message)
        XCTAssertNil(defaults.object(forKey: "game"))
    }

    func testAcknowledgedQuestionHistoryPublishesQuestionAndSurvivesReopen() async throws {
        let suite = "Fruitfolio.question-history-positive." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        defer { model.leaveScreen() }
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        await provider.finish(); await task.value
        XCTAssertEqual(model.screen, .question)
        XCTAssertEqual(model.currentQuestion?.id, "fixture-question")
        XCTAssertNil(model.selectedAnswerID)
        XCTAssertEqual(store.questionHistory["fixture"], ["fixture-question"])
        let accepted = defaults.data(forKey: "game")
        let reopened = Prompt28FruitBasketStore(defaults: defaults, persistenceKey: "game")
        XCTAssertEqual(reopened.questionHistory["fixture"], ["fixture-question"])
        XCTAssertEqual(defaults.data(forKey: "game"), accepted)
        XCTAssertFalse(reopened.isReadOnly)
    }

    func testBackgroundedQuestionLoadCannotPublishOrPersistLateResponse() async throws {
        let suite = "Fruitfolio.game-question-background." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        model.sceneBecameInactive()
        await provider.finish()
        await task.value
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(store.questionHistory["fixture"])
    }

    func testChangingTopicRejectsDelayedQuestionWithoutPersistingHistory() async throws {
        let suite = "Fruitfolio.game-question-ownership." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        model.changeTopic()
        await provider.finish()
        await task.value
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(store.questionHistory["fixture"])
    }

    func testCancelledQuestionLoadReturnsToRetryableSetup() async throws {
        let suite = "Fruitfolio.game-question-cancellation." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = Prompt1BDelayedGameResearch()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        model.rawTopic = "fixture"
        let task = Task { await model.loadQuestion() }
        await provider.waitForStart()
        task.cancel()
        await provider.finish()
        await task.value
        XCTAssertNil(model.currentQuestion)
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(store.questionHistory["fixture"])
    }
}
