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
    private func savedFixture(_ file: URL) async throws -> (repository: Prompt20CycleDailyLogStore, now: Date, day: Prompt20LocalDay, calendar: Calendar) {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 7, hour: 12))!
        let selected = Prompt20LocalDay(date: now, calendar: calendar)
        let repository = Prompt20CycleDailyLogStore(fileURL: file, calendar: calendar)
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "saved original"
        _ = try await repository.save(ownerID: .localDevice, date: selected, draft: draft, now: now)
        return (repository, now, selected, calendar)
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
}
