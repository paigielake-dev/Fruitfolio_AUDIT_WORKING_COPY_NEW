import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BOnboardingViewModelTests: XCTestCase {
    private func url() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json") }
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private func suppliedDate() throws -> Date {
        try Prompt13LocalDate(year: 2026, month: 8, day: 1).foundationDate(in: calendar)
    }

    func testRapidAnswersSaveInOrderAndKeepLatestFullDraft() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load()
        model.getStarted()
        model.selectLatestPeriod(try suppliedDate())
        for index in 0..<40 { model.chooseBBTUnit(index.isMultiple(of: 2) ? .fahrenheit : .celsius) }
        let success = await model.waitForPendingSaves(); XCTAssertTrue(success)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk.bbtUnit, .celsius)
        XCTAssertEqual(disk.latestPeriodStart, try Prompt13LocalDate(year: 2026, month: 8, day: 1))
        XCTAssertEqual(disk.step, .latestPeriod)
        XCTAssertFalse(model.hasUnsavedChanges); XCTAssertFalse(model.saveFailed)
        XCTAssertEqual(model.savedDraft?.bbtUnit, .celsius)
    }

    func testFinishWaitsForHeldAnswerAndDisallowsChangesDuringCommit() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        let backend = OnboardingWriteBoundary(url)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle)
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); await backend.hold()
        model.selectLatestPeriod(try suppliedDate())
        await backend.waitUntilHeld()
        let finish = Task { await model.finish() }
        for _ in 0..<1_000 where !model.isFinishing { await Task.yield() }
        XCTAssertTrue(model.isFinishing)
        model.chooseBBTUnit(.fahrenheit)
        XCTAssertNil(model.draft.bbtUnit)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cycleURL.path))
        await backend.release()
        let success = await finish.value; XCTAssertTrue(success)
        let disk = try await Prompt13FileCyclePersistence(fileURL: cycleURL).load()
        XCTAssertEqual(disk.cycleStarts.map(\.date), [try Prompt13LocalDate(year: 2026, month: 8, day: 1)])
        XCTAssertTrue(model.draft.isCompleted); XCTAssertFalse(model.isFinishing)
    }

    func testFailedAnswerRemainsEditableAndFinishDoesNotCommitUntilRetrySucceeds() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL)))
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); await backend.rejectSave()
        model.chooseBBTUnit(.fahrenheit)
        let failed = await model.waitForPendingSaves(); XCTAssertFalse(failed)
        XCTAssertEqual(model.draft.bbtUnit, .fahrenheit); XCTAssertNil(model.savedDraft?.bbtUnit)
        XCTAssertTrue(model.hasUnsavedChanges); XCTAssertTrue(model.saveFailed)
        let finish = await model.finish(); XCTAssertFalse(finish)
        XCTAssertFalse(FileManager.default.fileExists(atPath: cycleURL.path))
        let retried = await model.retrySaving(); XCTAssertTrue(retried)
        XCTAssertFalse(model.hasUnsavedChanges); XCTAssertNil(model.errorMessage)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk.bbtUnit, .fahrenheit)
    }

    func testStaleEditorCannotOverwriteNewerSameStoreAnswerOrReloadAwayItsDraft() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        let first = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        let stale = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await first.load(); await stale.load()
        first.chooseBBTUnit(.fahrenheit)
        let saved = await first.waitForPendingSaves(); XCTAssertTrue(saved)
        let bytes = try Data(contentsOf: url)
        stale.chooseBBTUnit(.celsius)
        let rejected = await stale.waitForPendingSaves(); XCTAssertFalse(rejected)
        XCTAssertEqual(stale.draft.bbtUnit, .celsius); XCTAssertTrue(stale.hasUnsavedChanges)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let retry = await stale.retrySaving(); XCTAssertFalse(retry)
        await stale.load()
        XCTAssertEqual(stale.draft.bbtUnit, .celsius)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testOutsideWriterSurvivesStaleEditorSaveAndRetry() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); model.chooseBBTUnit(.fahrenheit)
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        let outside = Prompt14FileOnboardingPersistence(fileURL: url)
        var newer = try await outside.load(); newer.bbtUnit = .celsius
        try await outside.save(newer)
        let bytes = try Data(contentsOf: url)
        model.getStarted()
        let rejected = await model.waitForPendingSaves(); XCTAssertFalse(rejected)
        let retry = await model.retrySaving(); XCTAssertFalse(retry)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        XCTAssertEqual(model.draft.bbtUnit, .fahrenheit)
    }

    func testFailedInitialLoadCannotSaveDefaultAnswersOverUnsupportedFile() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let bytes = Data("{\"schemaVersion\":2,\"future\":true}".utf8); try bytes.write(to: url)
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); XCTAssertNil(model.savedDraft); XCTAssertFalse(model.isLoading)
        model.getStarted(); model.chooseBBTUnit(.fahrenheit)
        XCTAssertNil(model.draft.bbtUnit); XCTAssertFalse(model.hasUnsavedChanges)
        let finished = await model.finish(); XCTAssertFalse(finished)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testSavedReceiptDoesNotPublishHeldUnacknowledgedAnswer() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let model = Prompt14CycleOnboardingViewModel(store: Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory()), calendar: calendar)
        await model.load(); await backend.hold()
        model.chooseBBTUnit(.fahrenheit)
        await backend.waitUntilHeld()
        XCTAssertEqual(model.draft.bbtUnit, .fahrenheit)
        XCTAssertNil(model.savedDraft?.bbtUnit)
        await backend.release()
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        XCTAssertEqual(model.savedDraft?.bbtUnit, .fahrenheit)
    }

    func testLostCompletionAcknowledgmentCanRecoverSameSavedAnswersWithoutDuplicateDates() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        let backend = OnboardingWriteBoundary(url)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let model = Prompt14CycleOnboardingViewModel(store: Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle), calendar: calendar)
        await model.load(); model.selectLatestPeriod(try suppliedDate())
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        await backend.rejectWrite(2, afterCommit: true)
        let failed = await model.finish(); XCTAssertFalse(failed)
        let committed = try await Prompt13FileCyclePersistence(fileURL: cycleURL).load()
        let recovered = await model.finish(); XCTAssertTrue(recovered)
        let after = try await Prompt13FileCyclePersistence(fileURL: cycleURL).load()
        XCTAssertEqual(after.cycleStarts.map(\.id), committed.cycleStarts.map(\.id))
        XCTAssertTrue(model.draft.isCompleted)
    }
    func testMissingFileDefaultClockAndLostSaveAcknowledgmentAllowReadOnlyRetry() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        var initial = Prompt14OnboardingDraft(); initial.updatedAt = Date(timeIntervalSince1970: 100)
        let store = Prompt14CycleOnboardingStore(draft: initial, persistence: backend, cycleStore: .inMemory(), isLoaded: true)
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load()
        await backend.rejectSave(afterCommit: true)
        model.chooseBBTUnit(.fahrenheit)
        let recovered = await model.waitForPendingSaves(); XCTAssertTrue(recovered)
        let count = await backend.count(); XCTAssertEqual(count, 1)
        let committedBytes = try Data(contentsOf: url)
        let receipt = try await store.savedReceipt(matching: model.draft)
        XCTAssertNotNil(receipt)
        XCTAssertEqual(try Data(contentsOf: url), committedBytes)
        XCTAssertEqual(model.savedDraft?.bbtUnit, .fahrenheit)
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testLostEarlierSaveAcknowledgmentDoesNotBlockNewerQueuedAnswer() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory())
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); await backend.rejectSave(afterCommit: true)
        model.chooseBBTUnit(.fahrenheit)
        model.chooseBBTUnit(.celsius)
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk.bbtUnit, .celsius)
        let count = await backend.count(); XCTAssertEqual(count, 2)
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testCompletedEditorCannotIssueStaleReceiptAfterOutsideAnswersChange() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        let model = Prompt14CycleOnboardingViewModel(store: store, calendar: calendar)
        await model.load(); model.chooseBBTUnit(.fahrenheit)
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        let completed = await model.finish(); XCTAssertTrue(completed)
        let outside = Prompt14FileOnboardingPersistence(fileURL: url)
        var changed = try await outside.load(); changed.bbtUnit = .celsius
        try await outside.save(changed)
        let bytes = try Data(contentsOf: url)
        let stale = await model.finish(); XCTAssertFalse(stale)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        XCTAssertEqual(model.draft.bbtUnit, .fahrenheit)
    }

    func testDiscardAfterFailedAnswerKeepsAcknowledgedAnswersAndDoesNotRewriteFile() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let model = Prompt14CycleOnboardingViewModel(store: Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory()), calendar: calendar)
        await model.load(); model.chooseBBTUnit(.fahrenheit)
        let saved = await model.waitForPendingSaves(); XCTAssertTrue(saved)
        let bytes = try Data(contentsOf: url)
        await backend.rejectSave(); model.chooseBBTUnit(.celsius)
        let failed = await model.waitForPendingSaves(); XCTAssertFalse(failed)
        let unsafe = await model.prepareToExit(); XCTAssertFalse(unsafe)
        await model.discardUnsavedAnswers()
        XCTAssertEqual(model.draft.bbtUnit, .fahrenheit)
        XCTAssertFalse(model.hasUnsavedChanges); XCTAssertFalse(model.saveFailed)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let ready = await model.prepareToExit(); XCTAssertTrue(ready)
        let settled = await model.waitForPendingSaves(); XCTAssertTrue(settled)
    }

    func testPrepareExitWaitsForHeldAnswerAndFreezesFurtherEdits() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let model = Prompt14CycleOnboardingViewModel(store: Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory()), calendar: calendar)
        await model.load(); await backend.hold()
        model.chooseBBTUnit(.fahrenheit)
        await backend.waitUntilHeld()
        let exit = Task { await model.prepareToExit() }
        for _ in 0..<1_000 where !model.isFinishing { await Task.yield() }
        XCTAssertTrue(model.isFinishing)
        model.chooseBBTUnit(.celsius); XCTAssertEqual(model.draft.bbtUnit, .fahrenheit)
        await backend.release()
        let ready = await exit.value; XCTAssertTrue(ready)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk.bbtUnit, .fahrenheit); XCTAssertFalse(disk.isCompleted)
    }

    func testSaveForExitRetriesAnswerWithoutCompletingOrImportingPeriodHistory() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url), cycle = Prompt13CycleStore.inMemory()
        let model = Prompt14CycleOnboardingViewModel(store: Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle), calendar: calendar)
        await model.load(); await backend.rejectSave()
        model.selectLatestPeriod(try suppliedDate())
        let failed = await model.waitForPendingSaves(); XCTAssertFalse(failed)
        let ready = await model.saveForExit(); XCTAssertTrue(ready)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk.latestPeriodStart, try Prompt13LocalDate(year: 2026, month: 8, day: 1))
        XCTAssertFalse(disk.isCompleted); XCTAssertNil(disk.pendingCycleCommit)
        let archive = try await cycle.snapshot(); XCTAssertTrue(archive.cycleStarts.isEmpty)
    }

}
