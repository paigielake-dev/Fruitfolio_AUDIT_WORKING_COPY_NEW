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
              draft: Prompt20DailyLogDraft, now: Date, requestID: UUID,
              expectation: Prompt20DailyLogSaveExpectation) async throws -> Prompt20DailyLog? {
        // Sequencing-only fixture: these tests begin without a saved record.
        try expectation.validate(current: nil)
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

/// Injects an acknowledgement failure after the actual file actor commits.
/// Storage is real; this fixture controls only the response boundary.
private actor Prompt1BCommitThenFailDailyLogRepository: Prompt20DailyLogRepository {
    let base: Prompt20CycleDailyLogStore
    private var failOnce = true
    init(base: Prompt20CycleDailyLogStore) { self.base = base }
    func load(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay) async throws -> Prompt20DailyLog? {
        try await base.load(ownerID: ownerID, date: date)
    }
    func allActiveLogs(ownerID: Prompt20DailyLogOwnerID) async throws -> [Prompt20DailyLog] {
        try await base.allActiveLogs(ownerID: ownerID)
    }
    func save(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay, draft: Prompt20DailyLogDraft,
              now: Date, requestID: UUID, expectation: Prompt20DailyLogSaveExpectation) async throws -> Prompt20DailyLog? {
        let saved = try await base.save(ownerID: ownerID, date: date, draft: draft,
            now: now, requestID: requestID, expectation: expectation)
        if failOnce { failOnce = false; throw Prompt20DailyLogDomainError.persistenceUnavailable }
        return saved
    }
}

private actor Prompt1BHeldDailyLogReadRepository: Prompt20DailyLogRepository {
    let started: [XCTestExpectation]
    private var pending: [CheckedContinuation<Prompt20DailyLog?, any Error>] = []
    init(started: [XCTestExpectation]) { self.started = started }
    func load(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay) async throws -> Prompt20DailyLog? {
        try await withCheckedThrowingContinuation { continuation in
            let index = pending.count
            pending.append(continuation)
            started[index].fulfill()
        }
    }
    func finish(_ index: Int, log: Prompt20DailyLog?) { pending[index].resume(returning: log) }
    func allActiveLogs(ownerID: Prompt20DailyLogOwnerID) async throws -> [Prompt20DailyLog] { [] }
    func save(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay, draft: Prompt20DailyLogDraft,
              now: Date, requestID: UUID, expectation: Prompt20DailyLogSaveExpectation) async throws -> Prompt20DailyLog? {
        throw Prompt20DailyLogDomainError.persistenceUnavailable
    }
}

private actor Prompt1BDailyLogWriteAdmissionRepository: Prompt20DailyLogRepository {
    let base = Prompt20CycleDailyLogStore(fileURL: nil)
    private(set) var writeAttempts = 0
    func load(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay) async throws -> Prompt20DailyLog? {
        try await base.load(ownerID: ownerID, date: date)
    }
    func allActiveLogs(ownerID: Prompt20DailyLogOwnerID) async throws -> [Prompt20DailyLog] {
        try await base.allActiveLogs(ownerID: ownerID)
    }
    func save(ownerID: Prompt20DailyLogOwnerID, date: Prompt20LocalDay, draft: Prompt20DailyLogDraft,
              now: Date, requestID: UUID, expectation: Prompt20DailyLogSaveExpectation) async throws -> Prompt20DailyLog? {
        writeAttempts += 1
        return try await base.save(ownerID: ownerID, date: date, draft: draft, now: now,
                                   requestID: requestID, expectation: expectation)
    }
}

@MainActor
final class Prompt1BDailyLogViewModelTests: XCTestCase {
    private func savedFixture(_ file: URL) async throws -> (repository: Prompt20CycleDailyLogStore, now: Date, day: Prompt20LocalDay, calendar: Calendar) {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let selected = Prompt20LocalDay(date: now, calendar: calendar)
        let repository = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "saved original"
        _ = try await repository.save(ownerID: .localDevice, date: selected, draft: draft, now: now)
        return (repository, now, selected, calendar)
    }

    func testReactivatedReadRejectsOldResultAndDoesNotResetNewLoadingStateOrDraft() async throws {
        let started = [expectation(description: "old read"), expectation(description: "current read")]
        let repository = Prompt1BHeldDailyLogReadRepository(started: started)
        let now = Date()
        let selected = Prompt20LocalDay(date: now, calendar: .current)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: repository, nowProvider: { now })
        let old = Task { await model.load() }
        let oldStarted = await XCTWaiter.fulfillment(of: [started[0]], timeout: 2)
        XCTAssertEqual(oldStarted, .completed)
        model.suspendPendingLoad()
        let current = Task { await model.load() }
        let currentStarted = await XCTWaiter.fulfillment(of: [started[1]], timeout: 2)
        XCTAssertEqual(currentStarted, .completed)
        var stale = Prompt20DailyLogDraft(); stale.generalNote = "stale read fixture"
        var fresh = Prompt20DailyLogDraft(); fresh.generalNote = "current read fixture"
        await repository.finish(0, log: try Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
            date: selected, draft: stale, existing: nil, now: now))
        await old.value
        XCTAssertEqual(model.loadState, .loading, "Old defer must not reset a newer loading state")
        XCTAssertNotEqual(model.draft.generalNote, stale.generalNote)
        await repository.finish(1, log: try Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
            date: selected, draft: fresh, existing: nil, now: now))
        await current.value
        XCTAssertEqual(model.draft.generalNote, fresh.generalNote)
        model.mutateDraft { $0.generalNote = "retained unsaved correction" }
        model.suspendPendingLoad()
        await model.load()
        XCTAssertEqual(model.draft.generalNote, "retained unsaved correction")
        XCTAssertTrue(model.hasUnsavedChanges)
    }

    func testAlreadyCanceledSaveDoesNotEnterRepositoryAndExplicitRetryPreservesDraft() async throws {
        let repository = Prompt1BDailyLogWriteAdmissionRepository()
        let now = Date()
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: repository, nowProvider: { now })
        await model.load()
        model.mutateDraft { $0.generalNote = "retained before save admission" }
        let canceled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return await model.save()
        }
        let reported = await canceled.value
        XCTAssertFalse(reported)
        let before = await repository.writeAttempts
        XCTAssertEqual(before, 0)
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.saveState, .idle)
        let saved = await model.save()
        XCTAssertTrue(saved)
        let after = await repository.writeAttempts
        XCTAssertEqual(after, 1)
        let actual = try await repository.load(ownerID: .localDevice, date: model.selectedDay)
        XCTAssertEqual(actual?.generalNote?.text, "retained before save admission")
        XCTAssertFalse(model.hasUnsavedChanges)
    }

    func testTwoEditorsCannotOverwriteNewerSameStoreDayOrSilentlyRebase() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let first = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        let second = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await first.load(); await second.load()
        first.mutateDraft { $0.generalNote = "newer saved observation" }
        let accepted = await first.save(); XCTAssertTrue(accepted)
        let bytes = try Data(contentsOf: file)
        second.mutateDraft { $0.generalNote = "old editor draft" }
        let rejected = await second.save(); XCTAssertFalse(rejected)
        XCTAssertEqual(second.saveFailureMessage, Prompt20DailyLogDomainError.recordChanged.errorDescription)
        XCTAssertEqual(second.existingLog?.generalNote?.text, "saved original")
        XCTAssertEqual(second.draft.generalNote, "old editor draft")
        XCTAssertTrue(second.hasUnsavedChanges)
        second.mutateDraft { $0.generalNote = "changed old draft still requires review" }
        let rejectedAgain = await second.save(); XCTAssertFalse(rejectedAgain)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testOldEditorCannotResurrectClearedDayAfterAnotherClientReloads() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let old = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await old.load(); old.mutateDraft { $0.generalNote = "old unsaved edit" }
        try FileManager.default.removeItem(at: file)
        try await fixture.repository.reloadSavedLogs()
        let rejected = await old.save(); XCTAssertFalse(rejected)
        XCTAssertEqual(old.saveFailureMessage, Prompt20DailyLogDomainError.recordChanged.errorDescription)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertEqual(old.draft.generalNote, "old unsaved edit")
        let fresh = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await fresh.load(); fresh.mutateDraft { $0.generalNote = "freshly entered record" }
        let created = await fresh.save(); XCTAssertTrue(created)
        let bytes = try Data(contentsOf: file)
        let rejectedAgain = await old.retrySave(); XCTAssertFalse(rejectedAgain)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testTwoEmptyDayEditorsCannotReplaceTheFirstCreatedRecord() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let repository = Prompt20CycleDailyLogStore(fileURL: nil, calendar: calendar)
        let first = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: repository, calendar: calendar, nowProvider: { now })
        let second = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: repository, calendar: calendar, nowProvider: { now })
        await first.load(); await second.load()
        first.mutateDraft { $0.generalNote = "first new record" }
        let created = await first.save(); XCTAssertTrue(created)
        second.mutateDraft { $0.generalNote = "must not replace it" }
        let rejected = await second.save(); XCTAssertFalse(rejected)
        let actual = try await repository.load(ownerID: .localDevice, date: first.selectedDay)
        XCTAssertEqual(actual?.generalNote?.text, "first new record")
        XCTAssertEqual(actual?.revision, 1)
    }

    func testEditorsForIndependentDaysCanSaveWithoutDroppingEachOther() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let otherDate = fixture.calendar.date(from: DateComponents(year: 2026, month: 9, day: 6, hour: 12))!
        let first = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        let other = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: otherDate,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await first.load(); await other.load()
        first.mutateDraft { $0.generalNote = "updated first day" }
        other.mutateDraft { $0.generalNote = "independent second day" }
        let firstSaved = await first.save(); XCTAssertTrue(firstSaved)
        let otherSaved = await other.save(); XCTAssertTrue(otherSaved)
        let restored = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        let active = try await restored.allActiveLogs(ownerID: .localDevice)
        XCTAssertEqual(Set(active.compactMap { $0.generalNote?.text }), ["updated first day", "independent second day"])
    }

    func testCommittedWriteRetryReconcilesWithoutAnotherRevision() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let base = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
        let boundary = Prompt1BCommitThenFailDailyLogRepository(base: base)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: boundary, calendar: calendar, nowProvider: { now })
        await model.load(); model.mutateDraft { $0.generalNote = "committed despite failed acknowledgement" }
        let reported = await model.save(); XCTAssertFalse(reported)
        let bytes = try Data(contentsOf: file)
        let retried = await model.retrySave(); XCTAssertTrue(retried)
        XCTAssertFalse(model.hasUnsavedChanges)
        XCTAssertEqual(model.existingLog?.revision, 1)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testSupersededCommittedRetryCannotSilentlyRebaseOldDraftOrOverwriteNewerRecord() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let selected = Prompt20LocalDay(date: now, calendar: calendar)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let base = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
        let boundary = Prompt1BCommitThenFailDailyLogRepository(base: base)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: boundary, calendar: calendar, nowProvider: { now })
        await model.load(); model.mutateDraft { $0.generalNote = "old committed draft" }
        let reported = await model.save(); XCTAssertFalse(reported)
        var newer = Prompt20DailyLogDraft(); newer.generalNote = "newer saved observation"
        _ = try await base.save(ownerID: .localDevice, date: selected, draft: newer, now: now)
        let bytes = try Data(contentsOf: file)
        let retry = await model.retrySave(); XCTAssertFalse(retry)
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.draft.generalNote, "old committed draft")
        XCTAssertNil(model.existingLog)
        XCTAssertEqual(model.saveFailureMessage, Prompt20DailyLogDomainError.recordChanged.errorDescription)
        model.mutateDraft { $0.generalNote = "new text in still-unreviewed old editor" }
        let editedRetry = await model.save(); XCTAssertFalse(editedRetry)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testInitialFailedLoadRecoversReadOnlyWithoutReplacingAnAlreadyLoadedDraft() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let writer = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        var newer = Prompt20DailyLogDraft(); newer.generalNote = "newer outside record"
        _ = try await writer.save(ownerID: .localDevice, date: fixture.day, draft: newer, now: fixture.now)
        let bytes = try Data(contentsOf: file)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await model.load()
        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(model.loadFailureMessage, Prompt20DailyLogDomainError.storageChanged.errorDescription)
        await model.retryLoad()
        XCTAssertEqual(model.loadState, .loaded)
        XCTAssertNil(model.loadFailureMessage)
        XCTAssertEqual(model.draft.generalNote, "newer outside record")
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        model.mutateDraft { $0.generalNote = "unsaved draft must remain" }
        newer.generalNote = "latest outside record"
        _ = try await writer.save(ownerID: .localDevice, date: fixture.day, draft: newer, now: fixture.now)
        let latest = try Data(contentsOf: file)
        await model.retryLoad()
        XCTAssertEqual(model.draft.generalNote, "unsaved draft must remain")
        XCTAssertTrue(model.hasUnsavedChanges)
        let accepted = await model.save()
        XCTAssertFalse(accepted)
        XCTAssertEqual(model.saveFailureMessage, Prompt20DailyLogDomainError.storageChanged.errorDescription)
        XCTAssertEqual(try Data(contentsOf: file), latest)
    }

    func testUnknownFileFieldsRemainProtectedAcrossActualViewModelRetries() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        object["futureClinicalMetadata"] = ["retain": true]
        let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
        let repository = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await model.load()
        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(model.loadFailureMessage, Prompt20DailyLogDomainError.unsupportedPersistence.errorDescription)
        await model.retryLoad()
        XCTAssertEqual(model.loadState, .failed)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        model.mutateDraft { $0.generalNote = "keep any typed draft" }
        await model.retryLoad()
        XCTAssertEqual(model.draft.generalNote, "keep any typed draft")
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testRemovedFileIsNotRecreatedByLoadedViewModelSaveOrRetry() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, nowProvider: { fixture.now })
        await model.load()
        model.mutateDraft { $0.generalNote = "keep this unsaved edit" }
        try FileManager.default.removeItem(at: file)
        let saved = await model.save()
        let retried = await model.retrySave()
        XCTAssertFalse(saved); XCTAssertFalse(retried)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertEqual(model.draft.generalNote, "keep this unsaved edit")
        XCTAssertTrue(model.hasUnsavedChanges)
        XCTAssertEqual(model.saveState, .failed)
        XCTAssertEqual(model.saveFailureMessage, Prompt20DailyLogDomainError.storageChanged.errorDescription)
    }

    func testUnicodeTemperatureEntryPersistsNumericalValueWithoutChangingDraftOrRecordedUnit() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: fixture.repository, calendar: fixture.calendar, preferredTemperatureUnit: .celsius, nowProvider: { fixture.now })
        await model.load(); model.mutateDraft { $0.temperatureText = "٣٧٫١٢" }
        let accepted = await model.save(); XCTAssertTrue(accepted)
        XCTAssertEqual(model.draft.temperatureText, "٣٧٫١٢")
        XCTAssertEqual(model.existingLog?.temperature?.originalValue, 37.12)
        XCTAssertEqual(model.existingLog?.temperature?.originalUnit, .celsius)
        XCTAssertNil(model.existingLog?.temperature?.readingType)
        let restored = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        let reopened = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now,
            repository: restored, calendar: fixture.calendar, preferredTemperatureUnit: .fahrenheit, nowProvider: { fixture.now })
        await reopened.load()
        XCTAssertEqual(reopened.draft.temperatureUnit, .celsius)
        XCTAssertEqual(Double(reopened.draft.temperatureText), 37.12)
        reopened.mutateDraft { $0.generalNote = "notes after language change" }
        let savedAgain = await reopened.save(); XCTAssertTrue(savedAgain)
        XCTAssertEqual(reopened.existingLog?.temperature?.originalValue, 37.12)
        XCTAssertEqual(reopened.existingLog?.temperature?.originalUnit, .celsius)
    }

    func testNotesOnlyEditsPreserveOriginalTemperaturePrecisionAndUnitAcrossPreferences() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let selected = Prompt20LocalDay(date: now, calendar: calendar)
        let cases: [(String, Prompt20TemperatureUnit, Prompt20TemperatureUnit)] = [
            ("98.6789012345", .fahrenheit, .celsius), ("36.987654321", .celsius, .fahrenheit)]
        for (text, originalUnit, preference) in cases {
            let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
            defer { try? FileManager.default.removeItem(at: file) }
            let repository = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
            var draft = Prompt20DailyLogDraft(); draft.temperatureText = text; draft.temperatureUnit = originalUnit
            draft.temperatureReadingType = .basalWaking; draft.temperatureNote = "reported reading note"
            let saved = try await repository.save(ownerID: .localDevice, date: selected, draft: draft, now: now)
            let original = try XCTUnwrap(saved?.temperature)
            let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
                repository: repository, calendar: calendar, preferredTemperatureUnit: preference, nowProvider: { now })
            await model.load()
            XCTAssertEqual(model.draft.temperatureUnit, originalUnit)
            XCTAssertEqual(try XCTUnwrap(Double(model.draft.temperatureText)).bitPattern, original.originalValue.bitPattern)
            XCTAssertFalse(model.hasUnsavedChanges)
            model.mutateDraft { $0.generalNote = "only the general note changed" }
            let accepted = await model.save()
            XCTAssertTrue(accepted)
            let restored = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
            let actual = try await restored.load(ownerID: .localDevice, date: selected)
            XCTAssertEqual(actual?.temperature, original)
            XCTAssertEqual(actual?.generalNote?.text, "only the general note changed")
        }
    }

    func testUnitChoicePreservesTypedNumberAndInvalidReinterpretationCannotOverwriteSavedReading() async throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let selected = Prompt20LocalDay(date: now, calendar: calendar)
        let repository = Prompt20CycleDailyLogStore(fileURL: nil, calendar: calendar)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now,
            repository: repository, calendar: calendar, preferredTemperatureUnit: .celsius, nowProvider: { now })
        await model.load()
        XCTAssertEqual(model.draft.temperatureUnit, .celsius)
        XCTAssertEqual(model.draft.temperatureText, "")
        model.mutateDraft { $0.temperatureText = "37.123456789" }
        let initialSave = await model.save()
        XCTAssertTrue(initialSave)
        let original = try await repository.load(ownerID: .localDevice, date: selected)
        model.changeTemperatureUnit(to: .fahrenheit)
        XCTAssertEqual(model.draft.temperatureText, "37.123456789")
        XCTAssertEqual(model.draft.temperatureUnit, .fahrenheit)
        XCTAssertFalse(model.canSave)
        let rejected = await model.save()
        XCTAssertFalse(rejected)
        let after = try await repository.load(ownerID: .localDevice, date: selected)
        XCTAssertEqual(after, original)
        model.changeTemperatureUnit(to: .celsius)
        XCTAssertEqual(model.draft.temperatureText, "37.123456789")
    }

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
    func testMedicationConfirmationRejectsChangedEntryAndDoesNotTouchSavedBytes() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now, repository: fixture.repository, calendar: fixture.calendar)
        await model.load(); model.addMedication()
        let id = try XCTUnwrap(model.draft.medications.first?.id)
        model.updateMedication(id: id) { $0.name = "recorded medication"; $0.dose = "original dose" }
        let expected = try XCTUnwrap(model.draft.medications.first)
        let bytes = try Data(contentsOf: file)
        model.updateMedication(id: id) { $0.dose = "updated dose" }
        XCTAssertFalse(model.removeMedication(ifUnchanged: expected))
        XCTAssertEqual(model.draft.medications.first?.dose, "updated dose")
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let current = try XCTUnwrap(model.draft.medications.first)
        XCTAssertTrue(model.removeMedication(ifUnchanged: current))
        XCTAssertTrue(model.draft.medications.isEmpty)
        XCTAssertEqual(try Data(contentsOf: file), bytes, "Removing a draft entry is not a saved observation rewrite")
    }

    func testMedicationConfirmationCannotReplayAgainstAnotherEntry() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await savedFixture(file)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: fixture.now, repository: fixture.repository, calendar: fixture.calendar)
        await model.load(); model.addMedication()
        let removed = try XCTUnwrap(model.draft.medications.first)
        XCTAssertTrue(model.removeMedication(ifUnchanged: removed))
        model.addMedication()
        let retained = try XCTUnwrap(model.draft.medications.first)
        XCTAssertFalse(model.removeMedication(ifUnchanged: removed))
        XCTAssertEqual(model.draft.medications, [retained])
        XCTAssertEqual(model.draft.generalNote, "saved original")
    }

    func testMedicationConfirmationCannotMutateEntryDuringSuspendedSave() async throws {
        let repository = Prompt1BDelayedDailyLogRepository()
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_789_516_800)
        let model = Prompt20DailyLogViewModel(ownerID: .localDevice, selectedDate: now, repository: repository, calendar: calendar)
        await model.load(); model.addMedication()
        let id = try XCTUnwrap(model.draft.medications.first?.id)
        model.updateMedication(id: id) { $0.name = "recorded medication" }
        let expected = try XCTUnwrap(model.draft.medications.first)
        let save = Task { await model.save() }
        await repository.waitForWrite()
        XCTAssertFalse(model.removeMedication(ifUnchanged: expected))
        XCTAssertEqual(model.draft.medications, [expected])
        await repository.finish()
        let saved = await save.value; XCTAssertTrue(saved)
    }

}
