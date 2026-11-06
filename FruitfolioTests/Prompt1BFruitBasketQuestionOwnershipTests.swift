import Foundation
import XCTest
@testable import Fruitfolio

private actor Prompt1BDelayedGameResearch: Prompt28ResearchProviding {
    private var completion: CheckedContinuation<Void, Never>?
    private var waiting: CheckedContinuation<Void, Never>?
    private var started = false
    func question(topic: String, normalizedTopic: String, difficulty: Prompt28EducationalDifficulty,
                  excludingQuestionIDs: Set<String>) async throws -> Prompt28Question {
        await withCheckedContinuation { continuation in
            completion = continuation; started = true
            waiting?.resume(); waiting = nil
        }
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
