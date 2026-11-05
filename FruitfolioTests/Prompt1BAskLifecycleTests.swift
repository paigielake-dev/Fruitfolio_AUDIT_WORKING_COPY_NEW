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
                  sourceIDs: ["fixture-source"], knowledgeBaseVersion: "fixture", conceptTags: ["ovulation", "follicle"])
    }
}

extension Prompt1BAskLifecycleTests {
    func testIllustrationIsNotDisplayedUntilExplicitEducationalAction() async {
        let model = Prompt09AskViewModel(engine: Prompt1BImmediateAskEngine())
        model.inputText = "fixture"
        await model.submitCurrentQuestion(reduceMotion: true)
        XCTAssertTrue(model.selectedEducationalAssets.isEmpty)
        XCTAssertEqual(model.availableEducationalAssets.count, 1)
        model.revealEducationalIllustration()
        XCTAssertEqual(model.selectedEducationalAssets.count, 1)
        model.resetConversation()
        XCTAssertTrue(model.selectedEducationalAssets.isEmpty)
        XCTAssertTrue(model.availableEducationalAssets.isEmpty)
    }

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

private actor Prompt1BContextSuspendedAskEngine: AskContextualResearchServing {
    let started: XCTestExpectation
    private(set) var captured: FruitfolioAskUserContext?
    private var pending: CheckedContinuation<AskAnswer, Never>?
    init(started: XCTestExpectation) { self.started = started }
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        try await answer(question: question, conversation: conversation, trackerContext: nil, userContext: nil, progress: nil)
    }
    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        try await answer(question: question, conversation: conversation, trackerContext: trackerContext, userContext: nil, progress: progress)
    }
    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        userContext: FruitfolioAskUserContext?, progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        captured = userContext
        return await withCheckedContinuation { pending = $0; started.fulfill() }
    }
    func finish() {
        captured = nil
        pending?.resume(returning: .init(originalQuestion: "question", answerText: "late source-only answer",
            support: .supported, knowledgeBaseVersion: "fixture"))
        pending = nil
    }
}

extension Prompt1BAskLifecycleTests {
    func testExplicitContextIsNotCopiedIntoMessagesAndCancellationRejectsLateResponse() async throws {
        let started = expectation(description: "selected context reached provider")
        let engine = Prompt1BContextSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        var measurement = FruitfolioHormoneMeasurement()
        measurement.result = "1.25"; measurement.unit = "ng/mL"; measurement.notes = "private context fixture"
        let context = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [measurement.id], personalCategories: [],
            measurements: [measurement], context: .unspecified))
        model.inputText = "question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true, userContext: context) }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertTrue(model.hasUserContextInFlight)
        XCTAssertFalse(model.messages.contains { $0.text.contains("private context fixture") })
        model.cancelOutstandingWork()
        XCTAssertFalse(model.hasUserContextInFlight)
        await engine.finish()
        await task.value
        XCTAssertNil(model.answer)
        XCTAssertEqual(model.phase, .ready)
    }
}
