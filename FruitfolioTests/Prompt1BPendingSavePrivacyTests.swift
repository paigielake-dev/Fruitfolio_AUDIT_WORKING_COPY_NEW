import XCTest
@testable import Fruitfolio

final class Prompt1BPendingSavePrivacyTests: XCTestCase {
    func testExcerptPayloadDoesNotRetainTheUnsavedRemainderOfAnAnswer() {
        let pending = Prompt10PendingSavedContent(question: "question", answer: "selected words plus private unsaved remainder",
            saveType: .excerpt, excerptText: "selected words", originalAnswerID: "answer-1",
            sourceIDs: ["source-1"], sourceRecords: [.init(id: "source-1", title: "Original source")])
        XCTAssertEqual(pending.answer, "selected words")
        XCTAssertFalse(pending.answer.contains("private unsaved remainder"))
        XCTAssertEqual(pending.originalAnswerID, "answer-1")
        XCTAssertEqual(pending.sourceRecords?.first?.title, "Original source")
    }
    func testImageOnlyAndTextWithImageRetainExactlyTheChosenContent() {
        let art: FruitfolioAssetID = .ovarian_cycle_follicle_development_stages
        let imageOnly = Prompt10PendingSavedContent(question: "question", answer: "private unsaved text", saveType: .excerpt,
            excerptText: "", sourceIDs: ["source-1"], educationalAssetIDs: [art])
        XCTAssertEqual(imageOnly.answer, "")
        XCTAssertEqual(imageOnly.educationalAssetIDs, [art])
        let combination = Prompt10PendingSavedContent(question: "question", answer: "whole unsaved answer", saveType: .excerpt,
            excerptText: "chosen passage", educationalAssetIDs: [art])
        XCTAssertEqual(combination.answer, "chosen passage")
        XCTAssertEqual(combination.educationalAssetIDs, [art])
    }

    func testOnlyExplicitFullAnswerSaveRetainsFullAnswer() {
        let pending = Prompt10PendingSavedContent(question: "question", answer: "full selected answer", saveType: .fullAnswer)
        XCTAssertEqual(pending.answer, "full selected answer")
        let invalid = Prompt10PendingSavedContent(question: "question", answer: "unsaved answer", saveType: .excerpt)
        XCTAssertEqual(invalid.answer, "")
    }
}
