import XCTest
@testable import Fruitfolio

@MainActor
final class AskReducedMotionLifecycleTests: XCTestCase {
    func testEnablingReducedMotionDuringTypewriterShowsCompleteExactAnswerAndCancelsFurtherTicks() async throws {
        let engine = ReducedMotionAnswerFixture()
        let model = Prompt09AskViewModel(engine: engine)
        model.inputText = "synthetic layout fixture"
        await model.submitCurrentQuestion(reduceMotion: false)
        XCTAssertEqual(model.phase, .answering)
        model.setReducedMotion(true)
        XCTAssertEqual(model.phase, .ready)
        XCTAssertEqual(model.displayedAnswerText, engine.text)
        XCTAssertEqual(model.answer?.resolvedSemanticDocument.plainText, engine.text)
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(model.displayedAnswerText, engine.text, "Cancelled ticks must not append to the complete answer")
        model.setReducedMotion(false)
        XCTAssertEqual(model.phase, .ready, "Disabling Reduce Motion must not restart an already completed animation")
        XCTAssertEqual(model.displayedAnswerText, engine.text)
        model.resetConversation()
    }

    func testReducedMotionChangedWhileRetrievalWaitsIsHonoredWhenAnswerArrives() async {
        let engine = DeferredMotionAnswerFixture()
        let model = Prompt09AskViewModel(engine: engine)
        model.inputText = "synthetic deferred fixture"
        let request = Task { await model.submitCurrentQuestion(reduceMotion: false) }
        await engine.waitUntilStarted()
        XCTAssertEqual(model.phase, .searching)
        model.setReducedMotion(true)
        await engine.finish()
        await request.value
        XCTAssertEqual(model.phase, .ready)
        let expected = await engine.text
        XCTAssertEqual(model.displayedAnswerText, expected)
        XCTAssertEqual(model.answer?.answerText, expected)
        model.resetConversation()
    }
}

private struct ReducedMotionAnswerFixture: AskKnowledgeServing {
    let text = String(repeating: "Synthetic layout fixture: 2.500 units [fixture-source] — e\u{301} ♡. ", count: 16)
    func answer(question: String, conversation: [AskMessage]) async -> AskAnswer {
        AskAnswer(originalQuestion: question, answerText: text, support: .supported,
                  knowledgeBaseVersion: "layout-fixture-not-clinical-evidence")
    }
}

private actor DeferredMotionAnswerFixture: AskKnowledgeServing {
    let text = "Synthetic deferred layout fixture: 2.500 units [fixture-source]."
    private var didStart = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var responseWaiter: CheckedContinuation<Void, Never>?
    func answer(question: String, conversation: [AskMessage]) async -> AskAnswer {
        await withCheckedContinuation { continuation in
            responseWaiter = continuation; didStart = true
            startWaiter?.resume(); startWaiter = nil
        }
        return AskAnswer(originalQuestion: question, answerText: text, support: .supported,
                         knowledgeBaseVersion: "layout-fixture-not-clinical-evidence")
    }
    func waitUntilStarted() async {
        if didStart { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func finish() { responseWaiter?.resume(); responseWaiter = nil }
}
