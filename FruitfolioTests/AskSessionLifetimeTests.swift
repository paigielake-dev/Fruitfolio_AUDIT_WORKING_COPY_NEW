import XCTest
@testable import Fruitfolio

private struct SessionFixtureEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        AskAnswer(originalQuestion: question, answerText: "fixture answer for \(question)",
                  support: .supported, sourceIDs: ["fixture-source"],
                  sources: [AskSourceRecord(id: "fixture-source", title: "Fixture")],
                  knowledgeBaseVersion: "test")
    }
}

@MainActor
final class AskSessionLifetimeTests: XCTestCase {
    func testMultipleAnswersRemainInMemoryWithTheirOriginalCitations() async {
        let model = Prompt09AskViewModel(engine: SessionFixtureEngine())
        model.inputText = "first"
        await model.submitCurrentQuestion(reduceMotion: true)
        model.inputText = "second"
        await model.submitCurrentQuestion(reduceMotion: true)
        XCTAssertEqual(model.sessionAnswers.count, 2)
        XCTAssertEqual(model.messages.filter { $0.role == .user }.count, 2)
        XCTAssertTrue(model.sessionAnswers.values.allSatisfy { $0.sourceIDs == ["fixture-source"] })
        model.inputText = "unsaved draft"
        model.resetConversation()
        XCTAssertTrue(model.sessionAnswers.isEmpty)
        XCTAssertTrue(model.inputText.isEmpty)
        XCTAssertNil(model.answer)
        XCTAssertEqual(model.messages.count, 1)
        XCTAssertEqual(model.phase, .ready)
    }
    func testClearingAnActiveAskVisitPreservesTheIndependentlySavedGuideAndOriginalAttribution() async throws {
        let suite = "Fruitfolio.AskGuideIsolation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "ask-guide-isolation"
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: key)
        let guide = try library.createGuideEncyclopedia(name: "explicitly saved guide", subtitle: "", style: .pink)
        let chapter = try library.createChapter(in: guide.id, name: "selected material")
        let model = Prompt09AskViewModel(engine: SessionFixtureEngine())
        model.inputText = "explicitly selected first question"
        await model.submitCurrentQuestion(reduceMotion: true)
        let answer = try XCTUnwrap(model.answer)
        let selected = Prompt10SavedPage(chapterID: chapter.id, question: answer.originalQuestion,
            answer: answer.answerText, saveType: .fullAnswer,
            originalAnswerID: answer.id.uuidString, sourceIDs: answer.sourceIDs, sourceSnapshots: answer.sources,
            knowledgeBaseVersion: answer.knowledgeBaseVersion)
        let saved = try library.savePage(selected, to: guide.id, chapterID: chapter.id)
        model.inputText = "PRIVATE_SECOND_UNSAVED_QUESTION"
        await model.submitCurrentQuestion(reduceMotion: true)
        XCTAssertEqual(model.sessionAnswers.count, 2)
        let originalLibraryBytes = try XCTUnwrap(defaults.data(forKey: key))
        XCTAssertFalse(String(decoding: originalLibraryBytes, as: UTF8.self).contains("PRIVATE_SECOND_UNSAVED_QUESTION"))
        model.resetConversation()
        XCTAssertTrue(model.sessionAnswers.isEmpty)
        XCTAssertNil(model.answer)
        XCTAssertTrue(model.inputText.isEmpty)
        XCTAssertEqual(defaults.data(forKey: key), originalLibraryBytes,
            "Clearing an unsaved visit must not rewrite or delete the independently saved Guide")
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: key)
        let restored = try XCTUnwrap(reopened.encyclopedia(id: guide.id)?.chapters.flatMap(\.pages).first)
        XCTAssertEqual(restored.id, saved.id)
        XCTAssertEqual(restored.question, answer.originalQuestion)
        XCTAssertEqual(restored.answer, answer.answerText)
        XCTAssertEqual(restored.sourceIDs, answer.sourceIDs)
        XCTAssertEqual(restored.sourceSnapshots, answer.sources)
        XCTAssertEqual(restored.knowledgeBaseVersion, answer.knowledgeBaseVersion)
    }

}

extension AskSessionLifetimeTests {
    func testContinuousPaperAutoFollowDistinguishesGrowingAnswersFromReadingEarlierContent() {
        var policy = AskConversationScrollPolicy()
        policy.updateBottom(700, viewportHeight: 700)
        XCTAssertTrue(policy.shouldFollow)
        policy.updateBottom(1100, viewportHeight: 700)
        XCTAssertTrue(policy.shouldFollow, "Streaming growth alone cannot disable conditional auto-follow")
        policy.userDragged(towardEarlier: true)
        policy.updateBottom(1400, viewportHeight: 700)
        XCTAssertFalse(policy.shouldFollow)
        policy.userEndedDrag()
        XCTAssertFalse(policy.shouldFollow, "Releasing an earlier-answer scroll must not force a jump")
        policy.updateBottom(1600, viewportHeight: 700)
        XCTAssertFalse(policy.shouldFollow, "Later streaming must respect the existing reading position")
        policy.userDragged(towardEarlier: false)
        policy.updateBottom(710, viewportHeight: 700)
        XCTAssertFalse(policy.shouldFollow, "Do not fight an active finger gesture")
        policy.userEndedDrag()
        XCTAssertTrue(policy.shouldFollow, "Returning to the latest content re-enables following")
        policy.userDragged(towardEarlier: true); policy.userEndedDrag()
        policy.requestedNewQuestion()
        XCTAssertTrue(policy.shouldFollow, "An explicit new question requests the latest response")
    }
}
