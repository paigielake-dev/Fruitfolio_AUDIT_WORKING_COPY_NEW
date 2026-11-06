import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BGameSavedSourceTests: XCTestCase {
    private func question(records: [AskSourceRecord]? = nil,
                          text: String = "which word matches the exact test excerpt?",
                          category: String = "source-excerpt practice") -> Prompt28Question {
        Prompt28Question(id: "fixture", topicQuery: "test", normalizedTopic: "test", category: category,
            educationalDifficulty: .easy, questionText: text,
            answerOptions: [.init(id: "a", text: "first"), .init(id: "b", text: "second")], correctAnswerID: "a",
            explanation: "test-only original field x_y = 2–4; not a medical claim", sourceIDs: records?.map(\.id) ?? ["legacy"],
            sourceTitles: records?.map(\.title) ?? ["Legacy attribution"], catchConceptID: "visual-starred-fruit", catchRule: "starred fruit",
            goodFruitIDs: [.pear], badFruitIDs: [.lemon], contentVersion: "package-v2", reviewStatus: "test-only",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000), sourceRecords: records)
    }
    func testKnownExcerptPresentationPreservesLiteralBytesAndSavedOriginal() throws {
        let literal = "  synthetic [blank]; x_y; FSH ≤ −2.5 IU/L. DOI:10.1234/fixture cafe\u{301}\n\n  "
        let original = Prompt28ExcerptQuestionPresentation.prefix + literal
        let q = question(text: original)
        let presentation = try XCTUnwrap(Prompt28ExcerptQuestionPresentation(question: q))
        XCTAssertEqual(Data(presentation.literalExcerpt.utf8), Data(literal.utf8))
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(Data(saved.question.utf8), Data(original.utf8))
        XCTAssertEqual(saved.answer, q.explanation)
        XCTAssertEqual(saved.sourceIDs, q.sourceIDs)
        XCTAssertEqual(q.answerOptions.map(\.text), ["first", "second"])
        XCTAssertEqual(q.correctAnswerID, "a")
    }

    func testUnknownLegacyOrEmptyExcerptTemplateDoesNotDropQuestionText() {
        for q in [question(), question(text: Prompt28ExcerptQuestionPresentation.prefix),
                  question(text: " " + Prompt28ExcerptQuestionPresentation.prefix + "literal"),
                  question(text: Prompt28ExcerptQuestionPresentation.prefix + "literal", category: "other")] {
            XCTAssertNil(Prompt28ExcerptQuestionPresentation(question: q))
            XCTAssertFalse(q.questionText.isEmpty)
        }
    }

    func testSavedLessonRetainsOriginalSourceVersionAndCitationMetadata() throws {
        let source = AskSourceRecord(id: "paper", title: "Original fixture attribution", sourceText: "Original APA fixture",
            urlString: "https://example.test/paper", doi: "10.1000/fixture", publicationData: "2026", contentVersion: "paper-v7")
        let q = question(records: [source])
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: q))
        XCTAssertEqual(saved.sourceVersions["paper"], "paper-v7")
        XCTAssertEqual(saved.knowledgeBaseVersion, "package-v2")
        XCTAssertEqual(saved.sourceRecords, [source])
        XCTAssertEqual(saved.question, q.questionText)
        XCTAssertEqual(saved.answer, q.explanation)
        XCTAssertEqual(saved.generationTimestamp, q.createdAt)
        XCTAssertEqual(saved.originalAnswerID, "fruitbasket:fixture")
    }
    func testLegacyQuestionUsesItsKnownPackageVersionWithoutInventingSourceRecords() throws {
        let saved = try XCTUnwrap(Prompt28SavedResearchCopy.pending(question: question()))
        XCTAssertEqual(saved.sourceVersions, ["legacy": "package-v2"])
        XCTAssertNil(saved.sourceRecords)
    }
    func testInvalidDuplicateSourceIdentityCannotCrashOrSaveAFalseTrail() {
        let source = AskSourceRecord(id: "same", title: "Fixture")
        XCTAssertNil(Prompt28SavedResearchCopy.pending(question: question(records: [source, source])))
    }
}
