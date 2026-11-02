import XCTest
@testable import Fruitfolio

@MainActor
final class FruitBasketQuestionLifecycleTests: XCTestCase {
    private func question(_ topic: String, difficulty: Prompt28EducationalDifficulty = .easy) async throws -> Prompt28Question {
        try await Prompt28CanonicalResearchProvider().question(topic: topic, normalizedTopic: topic,
                                                               difficulty: difficulty, excludingQuestionIDs: [])
    }

    func testLatePreviousTopicCannotReplaceCurrentQuestionOrPolluteQuestionHistory() async throws {
        let suite = "GameQuestionGeneration-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = ControlledGameQuestionProvider()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        let oldQuestion = try await question("nutrition")
        let newQuestion = try await question("hormones")
        model.rawTopic = "nutrition"
        let first = Task { await model.startTopic() }
        await provider.waitForRequest("nutrition")
        model.rawTopic = "hormones"
        let second = Task { await model.startTopic() }
        await provider.waitForRequest("hormones")
        await provider.resolve("hormones", result: .success(newQuestion))
        await second.value
        XCTAssertEqual(model.currentQuestion?.id, newQuestion.id)
        await provider.resolve("nutrition", result: .success(oldQuestion)) // Deliberately ignores cancellation.
        await first.value
        XCTAssertEqual(model.screen, .question)
        XCTAssertEqual(model.currentQuestion?.id, newQuestion.id)
        XCTAssertEqual(model.session?.normalizedTopicID, "hormones")
        XCTAssertNil(store.questionHistory["nutrition"])
        XCTAssertEqual(store.questionHistory["hormones"], Set([newQuestion.id]))
        model.viewWillDisappear()
    }

    func testLeavingDuringResearchDiscardsLateFailureAndReturnsToUsableSetup() async throws {
        let suite = "GameQuestionLeave-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = ControlledGameQuestionProvider()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        model.rawTopic = "nutrition"
        let request = Task { await model.startTopic() }
        await provider.waitForRequest("nutrition")
        model.viewWillDisappear()
        XCTAssertEqual(model.screen, .learningSetup)
        await provider.resolve("nutrition", result: .failure(Prompt28ResearchError.providerUnavailable))
        await request.value
        XCTAssertEqual(model.screen, .learningSetup)
        XCTAssertNil(model.currentQuestion)
        XCTAssertNil(model.message)
        XCTAssertTrue(store.questionHistory.isEmpty)
    }

    func testProviderCannotAttachAValidQuestionToTheWrongRequestedTopic() async throws {
        let suite = "GameQuestionAssociation-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt28FruitBasketStore(defaults: defaults)
        let provider = ControlledGameQuestionProvider()
        let model = Prompt28FruitBasketViewModel(store: store, researchProvider: provider)
        let wrongTopic = try await question("hormones")
        model.rawTopic = "nutrition"
        let request = Task { await model.startTopic() }
        await provider.waitForRequest("nutrition")
        await provider.resolve("nutrition", result: .success(wrongTopic))
        await request.value
        XCTAssertEqual(model.screen, .error)
        XCTAssertNil(model.currentQuestion)
        XCTAssertTrue(store.questionHistory.isEmpty)
    }
}

/// Deliberately noncooperative cancellation reproduces late provider callbacks.
private actor ControlledGameQuestionProvider: Prompt28ResearchProviding {
    private var requests: [String: CheckedContinuation<Prompt28Question, Error>] = [:]
    private var started: Set<String> = []
    private var waiters: [String: CheckedContinuation<Void, Never>] = [:]
    func question(topic: String, normalizedTopic: String, difficulty: Prompt28EducationalDifficulty,
                  excludingQuestionIDs: Set<String>) async throws -> Prompt28Question {
        try await withCheckedThrowingContinuation { continuation in
            requests[normalizedTopic] = continuation
            started.insert(normalizedTopic)
            waiters.removeValue(forKey: normalizedTopic)?.resume()
        }
    }
    func waitForRequest(_ topic: String) async {
        if started.contains(topic) { return }
        await withCheckedContinuation { waiters[topic] = $0 }
    }
    func resolve(_ topic: String, result: Result<Prompt28Question, Error>) {
        requests.removeValue(forKey: topic)?.resume(with: result)
    }
}
