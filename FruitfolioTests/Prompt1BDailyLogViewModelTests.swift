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
