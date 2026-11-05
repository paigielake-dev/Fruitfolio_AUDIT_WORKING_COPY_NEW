import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BDailyLogWriteTests: XCTestCase {
    func testIdenticalRetryReusesIdempotencyIdentity() {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "original observation"
        let first = Prompt20DailyLogWrite.begin(draft: draft, retrying: nil)
        XCTAssertEqual(Prompt20DailyLogWrite.begin(draft: draft, retrying: first), first)
    }

    func testEditedRetryCannotResolveToPreviouslyCommittedWrite() {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "first"
        let first = Prompt20DailyLogWrite.begin(draft: draft, retrying: nil)
        draft.generalNote = "corrected"
        let corrected = Prompt20DailyLogWrite.begin(draft: draft, retrying: first)
        XCTAssertNotEqual(corrected.id, first.id)
        XCTAssertEqual(corrected.draft.generalNote, "corrected")
        XCTAssertEqual(first.draft.generalNote, "first")
    }

    func testEditsDuringWriteRemainUnsaved() {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "written"
        let write = Prompt20DailyLogWrite.begin(draft: draft, retrying: nil)
        draft.selectedSymptoms.insert(.cramps)
        XCTAssertTrue(write.hasLaterEdits(draft))
        XCTAssertFalse(write.hasLaterEdits(write.draft))
        XCTAssertTrue(write.draft.selectedSymptoms.isEmpty)
    }

    func testClearingDuringWriteIsAnUnsavedEdit() {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "written"
        let write = Prompt20DailyLogWrite.begin(draft: draft, retrying: nil)
        XCTAssertTrue(write.hasLaterEdits(Prompt20DailyLogDraft()))
    }
}
