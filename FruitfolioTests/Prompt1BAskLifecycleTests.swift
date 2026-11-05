import XCTest
@testable import Fruitfolio

private actor Prompt1BSuspendedAskEngine: AskKnowledgeServing {
    let started: XCTestExpectation
    var pending: CheckedContinuation<AskAnswer, Never>?
    init(started: XCTestExpectation) { self.started = started }
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        await withCheckedContinuation { continuation in
            pending = continuation
            started.fulfill()
        }
    }
    func finish() {
        pending?.resume(returning: AskAnswer(originalQuestion: "old question", answerText: "old answer",
                                            support: .supported, knowledgeBaseVersion: "fixture"))
        pending = nil
    }
}

@MainActor
final class Prompt1BAskLifecycleTests: XCTestCase {
    func testResetRejectsLateAnswerEvenIfProviderIgnoresCancellation() async {
        let started = expectation(description: "provider received question")
        let engine = Prompt1BSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        let oldID = model.conversationID
        model.inputText = "old question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true) }
        await fulfillment(of: [started], timeout: 2)
        model.resetConversation()
        await engine.finish()
        await task.value
        XCTAssertNotEqual(model.conversationID, oldID)
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertTrue(model.answerHistory.isEmpty)
        XCTAssertNil(model.answer)
        XCTAssertEqual(model.displayedAnswerText, "")
        XCTAssertEqual(model.phase, .ready)
    }

    func testCancellationIsNotShownAsAnApplicationFailure() async {
        let started = expectation(description: "provider received question")
        let engine = Prompt1BSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        model.inputText = "question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true) }
        await fulfillment(of: [started], timeout: 2)
        model.cancelOutstandingWork()
        await engine.finish()
        await task.value
        XCTAssertEqual(model.phase, .ready)
        XCTAssertNil(model.answer)
    }
}
