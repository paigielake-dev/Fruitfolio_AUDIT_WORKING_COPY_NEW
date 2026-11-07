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

/// Actual view-model request contract; no clinical/model inference claim.
private actor Prompt1BLanguageCaptureAskEngine: AskLocalizedResearchServing {
    private(set) var languages: [FruitfolioLanguage] = []
    let fail: Bool
    init(fail: Bool = false) { self.fail = fail }
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        .init(originalQuestion: question, answerText: "nonclinical request fixture", support: .genuinelyNovel,
              knowledgeBaseVersion: "language-contract-fixture")
    }
    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        try await answer(question: question, conversation: conversation)
    }
    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        userContext: FruitfolioAskUserContext?, progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        try await answer(question: question, conversation: conversation)
    }
    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        userContext: FruitfolioAskUserContext?, inputLanguage: FruitfolioLanguage, translationInferenceAllowed: Bool,
        progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        languages.append(inputLanguage)
        if fail { throw FruitfolioTranslationError.resourcesMissing }
        return try await answer(question: question, conversation: conversation)
    }
}

@MainActor
final class Prompt1BAskLifecycleTests: XCTestCase {
    func testKnownEnglishSuggestionDoesNotAcquireTheInterfaceLanguageAndEditedTextDoes() async {
        let engine = Prompt1BLanguageCaptureAskEngine()
        let model = Prompt09AskViewModel(engine: engine)
        model.useSuggestion("source English question")
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        var languages = await engine.languages
        XCTAssertEqual(languages, [.english])
        XCTAssertEqual(model.answer?.originalQuestion, "source English question")
        model.resetConversation()
        model.useSuggestion("source English question")
        model.inputText += " modifiée"
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        languages = await engine.languages
        XCTAssertEqual(languages, [.english, .french])
        XCTAssertEqual(model.answer?.originalQuestion, "source English question modifiée")
    }

    func testQuestionTranslationFailureKeepsOriginalAuthoredQuestionForRetry() async {
        let model = Prompt09AskViewModel(engine: Prompt1BLanguageCaptureAskEngine(fail: true))
        let original = "question française 12.50 pg/mL"
        model.inputText = original
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        XCTAssertEqual(model.inputText, original)
        XCTAssertEqual(model.messages.last?.text, original)
        XCTAssertNil(model.answer)
        XCTAssertTrue(model.answerHistory.isEmpty)
        guard case .failed = model.phase else { return XCTFail("Actual translation failure must remain a failure") }
    }

    func testCancellingSubmitOwnerRejectsLateProviderAnswer() async {
        let started = expectation(description: "provider started for cancelled owner")
        let engine = Prompt1BSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        model.inputText = "old question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true) }
        await fulfillment(of: [started], timeout: 2)
        task.cancel()
        await engine.finish()
        await task.value
        XCTAssertNil(model.answer)
        XCTAssertTrue(model.answerHistory.isEmpty)
        XCTAssertEqual(model.messages.map(\.role), [.fruitfolio, .user])
        XCTAssertEqual(model.phase, .ready)
    }

    func testInactivityRestoresInterruptedQuestionAndRejectsLateProviderAnswer() async {
        let started = expectation(description: "provider started before inactivity")
        let engine = Prompt1BSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        model.inputText = "old question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true) }
        await fulfillment(of: [started], timeout: 2)
        XCTAssertEqual(model.inputText, "")
        model.suspendForInactivity()
        XCTAssertEqual(model.inputText, "old question")
        model.suspendForInactivity()
        await engine.finish()
        await task.value
        XCTAssertNil(model.answer)
        XCTAssertTrue(model.answerHistory.isEmpty)
        XCTAssertEqual(model.inputText, "old question")
        XCTAssertEqual(model.phase, .ready)
    }

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

extension Prompt1BAskLifecycleTests {
    func testInactivityPreservesNewerDraftAndRejectsLateContextResponse() async throws {
        let started = expectation(description: "context provider started before inactivity")
        let engine = Prompt1BContextSuspendedAskEngine(started: started)
        let model = Prompt09AskViewModel(engine: engine)
        var measurement = FruitfolioHormoneMeasurement()
        measurement.result = "1.25"; measurement.unit = "ng/mL"; measurement.notes = "private context fixture"
        let context = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [measurement.id], personalCategories: [],
            measurements: [measurement], context: .unspecified))
        model.inputText = "question"
        let task = Task { await model.submitCurrentQuestion(reduceMotion: true, userContext: context) }
        await fulfillment(of: [started], timeout: 2)
        model.inputText = "my newer unsent draft"
        model.suspendForInactivity()
        XCTAssertEqual(model.inputText, "my newer unsent draft")
        XCTAssertFalse(model.hasUserContextInFlight)
        await engine.finish()
        await task.value
        XCTAssertNil(model.answer)
        XCTAssertTrue(model.answerHistory.isEmpty)
        XCTAssertEqual(model.inputText, "my newer unsent draft")
        XCTAssertFalse(model.messages.contains { $0.text.contains("private context fixture") })
    }
}

private actor Prompt1BLongTypewriterAskEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        AskAnswer(originalQuestion: question,
            answerText: String(repeating: "**Anchor** with semantic text. ", count: 200),
            support: .supported, knowledgeBaseVersion: "synthetic-typewriter-lifetime")
    }
}

extension Prompt1BAskLifecycleTests {
    func testTypewriterDoesNotRetainReleasedViewModelAcrossItsSleep() async throws {
        var model: Prompt09AskViewModel? = Prompt09AskViewModel(engine: Prompt1BLongTypewriterAskEngine())
        weak var observed = model
        model?.inputText = "fixture"
        await model?.submitCurrentQuestion(reduceMotion: false)
        let deadline = ContinuousClock.now.advanced(by: .seconds(1))
        while model?.displayedSemanticSpans.isEmpty == true, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(1))
        }
        XCTAssertFalse(model?.displayedSemanticSpans.isEmpty ?? true)
        XCTAssertEqual(model?.phase, .answering)
        model = nil
        for _ in 0..<20 {
            if observed == nil { break }
            await Task.yield()
        }
        XCTAssertNil(observed, "The sleeping typewriter must not own the released view model")
        observed?.cancelOutstandingWork() // Clean up a failing implementation's long fixture.
    }
}
