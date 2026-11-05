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

private actor Prompt1BImmediateAskEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        AskAnswer(originalQuestion: question, answerText: "Evidence for \(question)", support: .supported,
                  sourceIDs: ["fixture-source"], knowledgeBaseVersion: "fixture")
    }
}

extension Prompt1BAskLifecycleTests {
    func testMultipleTurnsKeepAnswersInOriginalSessionOrder() async {
        let model = Prompt09AskViewModel(engine: Prompt1BImmediateAskEngine())
        for question in ["first", "second"] {
            model.inputText = question
            await model.submitCurrentQuestion(reduceMotion: true)
        }
        XCTAssertEqual(model.answerHistory.map(\.originalQuestion), ["first", "second"])
        XCTAssertEqual(model.messages.map(\.role), [.fruitfolio, .user, .fruitfolio, .user, .fruitfolio])
        XCTAssertEqual(model.messages[2].id, model.answerHistory[0].id)
        XCTAssertEqual(model.messages[4].id, model.answerHistory[1].id)
        XCTAssertEqual(model.answerHistory[0].sourceIDs, ["fixture-source"])
    }
}

private actor Prompt1BFormattedAskEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        AskAnswer(originalQuestion: question,
                  answerText: "**hormone** information preserves *uncertainty* and its source identifiers.",
                  support: .supported, knowledgeBaseVersion: "fixture")
    }
}

extension Prompt1BAskLifecycleTests {
    func testTypewriterPublishesStyledPrefixesWithoutRawMarkdownMarkers() async throws {
        let model = Prompt09AskViewModel(engine: Prompt1BFormattedAskEngine())
        model.inputText = "fixture"
        await model.submitCurrentQuestion(reduceMotion: false)
        try await Task.sleep(for: .milliseconds(35))
        XCTAssertFalse(model.displayedAnswerText.contains("*"))
        XCTAssertEqual(model.displayedSemanticSpans.first?.emphasis, .anchorBold)
        model.cancelOutstandingWork()
        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.displayedAnswerText, model.answer?.answerText)
    }
}
