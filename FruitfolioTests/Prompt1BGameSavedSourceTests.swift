import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BGameSavedSourceTests: XCTestCase {
    private func question(records: [AskSourceRecord]? = nil) -> Prompt28Question {
        Prompt28Question(id: "fixture", topicQuery: "test", normalizedTopic: "test", category: "source-excerpt practice",
            educationalDifficulty: .easy, questionText: "which word matches the exact test excerpt?",
            answerOptions: [.init(id: "a", text: "first"), .init(id: "b", text: "second")], correctAnswerID: "a",
            explanation: "test-only original field x_y = 2–4; not a medical claim", sourceIDs: records?.map(\.id) ?? ["legacy"],
            sourceTitles: records?.map(\.title) ?? ["Legacy attribution"], catchConceptID: "visual-starred-fruit", catchRule: "starred fruit",
            goodFruitIDs: [.pear], badFruitIDs: [.lemon], contentVersion: "package-v2", reviewStatus: "test-only",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000), sourceRecords: records)
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
