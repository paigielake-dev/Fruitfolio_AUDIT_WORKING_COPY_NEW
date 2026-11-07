import XCTest
import Combine
import SwiftUI
import UIKit
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
    private(set) var questions: [String] = []
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
        questions.append(question)
        if fail { throw FruitfolioTranslationError.resourcesMissing }
        return try await answer(question: question, conversation: conversation)
    }
}

private actor Prompt1BLongAnswerFixture: AskKnowledgeServing {
    static let source = String(repeating: "nonclinical source fixture. ", count: 100)
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        .init(originalQuestion: question, answerText: Self.source,
              support: .genuinelyNovel, knowledgeBaseVersion: "display-overlap-fixture")
    }
}

@MainActor
final class Prompt1BAskLifecycleTests: XCTestCase {
    func testCompleteCatalogAnswerAppearsBeforeEnglishTypewriterFinishes() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        let folder = root.appendingPathComponent("fr.lproj")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try PropertyListSerialization.data(fromPropertyList: [
            "CFBundleIdentifier": "fixture." + UUID().uuidString, "CFBundleDevelopmentRegion": "en"
        ], format: .xml, options: 0).write(to: root.appendingPathComponent("Info.plist"))
        let target = "texte de démonstration non clinique"
        try PropertyListSerialization.data(fromPropertyList: [Prompt1BLongAnswerFixture.source: target],
            format: .binary, options: 0).write(to: folder.appendingPathComponent("Localizable.strings"))
        let bundle = try XCTUnwrap(Bundle(url: root))
        let suite = "display-overlap." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.language = .french
        let model = Prompt09AskViewModel(engine: Prompt1BLongAnswerFixture())
        model.inputText = "original nonclinical question"
        await model.submitCurrentQuestion(reduceMotion: false)
        let answer = try XCTUnwrap(model.answer)
        XCTAssertEqual(model.phase, .answering)
        XCTAssertLessThan(model.displayedAnswerText.count, answer.answerText.count)
        let host = UIHostingController(rootView:
            Prompt09LocalizedAnswerText(answer: answer, viewModel: model, bundle: bundle)
                .environmentObject(settings))
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previous?.makeKey()
            model.resetConversation()
        }
        func containsTarget(_ view: UIView) -> Bool {
            if let editor = view as? UITextView, editor.text == target { return true }
            return view.subviews.contains(where: containsTarget)
        }
        // The source takes many seconds to animate; the complete catalog result
        // must appear promptly through the real SwiftUI translation owner.
        for _ in 0..<100 {
            if model.phase == .ready, containsTarget(host.view) { break }
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        XCTAssertEqual(model.phase, .ready)
        XCTAssertTrue(containsTarget(host.view))
        XCTAssertEqual(model.answer?.answerText, Prompt1BLongAnswerFixture.source)
        XCTAssertEqual(model.answer?.originalQuestion, "original nonclinical question")
        XCTAssertEqual(model.displayedAnswerText, Prompt1BLongAnswerFixture.source)
    }

    func testSubmissionFreezesOriginalBytesBeforePublishedStateCanChangeTheDraft() async {
        let engine = Prompt1BLanguageCaptureAskEngine()
        let model = Prompt09AskViewModel(engine: engine)
        let original = "source café question"
        let newer = "source cafe\u{0301} question"
        model.useSuggestion(original)
        let observation = model.$hasUserContextInFlight.dropFirst().prefix(1).sink { _ in
            model.inputText = newer
        }
        defer { observation.cancel() }
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        var questions = await engine.questions
        var languages = await engine.languages
        XCTAssertEqual(questions.count, 1)
        XCTAssertEqual(Data(questions[0].utf8), Data(original.utf8))
        XCTAssertEqual(languages, [.english])
        XCTAssertEqual(Data(model.inputText.utf8), Data(newer.utf8), "A canonically equivalent but newly authored draft must not be erased")
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        questions = await engine.questions
        languages = await engine.languages
        XCTAssertEqual(languages, [.english, .french])
        XCTAssertEqual(Data(questions[1].utf8), Data(newer.utf8))
    }

    func testFailedRequestDoesNotRestoreOverAnIntentionallyClearedNewDraft() async {
        let model = Prompt09AskViewModel(engine: Prompt1BLanguageCaptureAskEngine(fail: true))
        model.inputText = "original submitted question"
        let observation = model.$phase.sink { phase in
            if phase == .searching {
                model.inputText = "newer draft"
                model.inputText = ""
            }
        }
        defer { observation.cancel() }
        await model.submitCurrentQuestion(reduceMotion: true, inputLanguage: .french)
        XCTAssertEqual(model.inputText, "", "Failure must respect a deliberate newer clear, not restore an old submitted question")
        XCTAssertEqual(model.messages.last?.text, "original submitted question")
        XCTAssertNil(model.answer)
    }

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
