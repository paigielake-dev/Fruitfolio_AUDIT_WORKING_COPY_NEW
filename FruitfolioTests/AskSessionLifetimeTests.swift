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
}
