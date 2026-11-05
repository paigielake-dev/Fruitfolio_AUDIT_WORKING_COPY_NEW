#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import XCTest
@testable import Fruitfolio

private actor Prompt1BDelayedDailyLogRepository: Prompt20DailyLogRepository {
    private var continuation: CheckedContinuation<Void, Never>?
    private var started = false
    private var waiter: CheckedContinuation<Void, Never>?
    private(set) var writtenDraft: Prompt20DailyLogDraft?

    func load(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay) async throws -> Prompt20DailyLog? { nil }
    func allActiveLogs(ownerID: Prompt20DailyLogOwnerID) async throws -> [Prompt20DailyLog] { [] }
    func save(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay,
              draft: Prompt20DailyLogDraft, now: Date, requestID: UUID) async throws -> Prompt20DailyLog? {
        writtenDraft = draft
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            started = true
            waiter?.resume()
            waiter = nil
        }
        return try Prompt20DailyLogRules.makeLog(ownerID: ownerID, date: date,
                                                draft: draft, existing: nil, now: now)
    }
    func waitForWrite() async {
        if started { return }
        await withCheckedContinuation { waiter = $0 }
    }
    func finish() { continuation?.resume(); continuation = nil }
}

@MainActor
final class Prompt1BDailyLogViewModelTests: XCTestCase {
    func testEditsDuringActualRepositoryAwaitRemainDirty() async {
        let repository = Prompt1BDelayedDailyLogRepository()
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: Date(), repository: repository)
        await model.load()
        model.mutateDraft { $0.generalNote = "written observation" }
        let task = Task { await model.save() }
        await repository.waitForWrite()
        model.mutateDraft { $0.generalNote = "later unsaved correction" }
        await repository.finish()
        let saved = await task.value
        XCTAssertTrue(saved)
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.draft.generalNote, "later unsaved correction")
        let written = await repository.writtenDraft
        XCTAssertEqual(written?.generalNote, "written observation")
        XCTAssertEqual(model.saveState, .idle)
        // A reappearing view must not reload over this unsaved correction.
        await model.load()
        XCTAssertEqual(model.draft.generalNote, "later unsaved correction")
    }

    func testCancelledPresentationStillReconcilesCompletedStorageWrite() async {
        let repository = Prompt1BDelayedDailyLogRepository()
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: Date(), repository: repository)
        await model.load()
        model.mutateDraft { $0.generalNote = "written" }
        let task = Task { await model.save() }
        await repository.waitForWrite()
        task.cancel()
        await repository.finish()
        let reported = await task.value
        XCTAssertFalse(reported)
        XCTAssertFalse(model.hasUnsavedChanges)
        XCTAssertEqual(model.saveState, .saved)
    }
}
#endif
