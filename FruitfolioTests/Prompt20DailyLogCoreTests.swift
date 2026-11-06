import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt20CoreTests: XCTestCase {
    private func calendar(_ timeZoneID: String = "America/New_York") -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12,
        calendar: Calendar? = nil
    ) -> Date {
        let calendar = calendar ?? self.calendar()
        return calendar.date(from: DateComponents(
            calendar: calendar,
            timeZone: calendar.timeZone,
            year: year,
            month: month,
            day: day,
            hour: hour
        ))!
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Prompt20LocalDay {
        Prompt20LocalDay(year: year, month: month, day: day)
    }

    func testConcurrentWritesToOneDayReceiveDistinctSequentialRevisions() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let selected = day(2026, 9, 7)
        let store = Prompt20CycleDailyLogStore(fileURL: nil, calendar: cal)
        let revisions = try await withThrowingTaskGroup(of: Int.self) { group in
            for index in 0..<64 {
                group.addTask {
                    var draft = Prompt20DailyLogDraft(); draft.generalNote = "observation \(index)"
                    let saved = try await store.save(ownerID: .localDevice, date: selected,
                        draft: draft, now: now, requestID: UUID())
                    return try XCTUnwrap(saved).revision
                }
            }
            var revisions: [Int] = []
            for try await revision in group { revisions.append(revision) }
            return revisions
        }
        XCTAssertEqual(revisions.count, 64)
        XCTAssertEqual(Set(revisions), Set(1...64))
        let final = try await store.load(ownerID: .localDevice, date: selected)
        XCTAssertEqual(final?.revision, 64)
    }

    func testConcurrentIdenticalRequestIDsCommitOneStableRecordIdentity() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let selected = day(2026, 9, 7)
        let store = Prompt20CycleDailyLogStore(fileURL: nil, calendar: cal)
        let requestID = UUID()
        let ids = try await withThrowingTaskGroup(of: UUID.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    var draft = Prompt20DailyLogDraft(); draft.generalNote = "one observation"
                    let saved = try await store.save(ownerID: .localDevice, date: selected,
                        draft: draft, now: now, requestID: requestID)
                    return try XCTUnwrap(saved).id
                }
            }
            var ids: [UUID] = []
            for try await id in group { ids.append(id) }
            return ids
        }
        XCTAssertEqual(Set(ids).count, 1)
        let final = try await store.load(ownerID: .localDevice, date: selected)
        XCTAssertEqual(final?.revision, 1)
        XCTAssertEqual(final?.id, ids.first)
        XCTAssertEqual(final?.generalNote?.text, "one observation")
    }

    func testConcurrentIndependentDaysPersistAllRecordsAndRetryIdentities() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let file = folder.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: folder) }
        let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: cal)
        let requests = (1...16).map { (Prompt20LocalDay(year: 2026, month: 8, day: $0), UUID()) }
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (selected, request) in requests {
                group.addTask {
                    var draft = Prompt20DailyLogDraft(); draft.generalNote = "retained observation"
                    _ = try await store.save(ownerID: .localDevice, date: selected,
                        draft: draft, now: now, requestID: request)
                }
            }
            try await group.waitForAll()
        }
        let baseline = try Data(contentsOf: file)
        let restored = Prompt20CycleDailyLogStore(fileURL: file, calendar: cal)
        let saved = try await restored.allActiveLogs(ownerID: .localDevice)
        XCTAssertEqual(saved.count, 16)
        XCTAssertTrue(saved.allSatisfy { $0.revision == 1 })
        for (selected, request) in requests {
            var retry = Prompt20DailyLogDraft(); retry.generalNote = "must not overwrite committed request"
            let actual = try await restored.save(ownerID: .localDevice, date: selected,
                draft: retry, now: now, requestID: request)
            XCTAssertEqual(actual?.generalNote?.text, "retained observation")
            XCTAssertEqual(actual?.revision, 1)
        }
        XCTAssertEqual(try Data(contentsOf: file), baseline)
    }

    func testInMemoryRepositoryRetainsConcurrentRevisionAndRetryContract() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let selected = day(2026, 9, 7)
        let repository = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let revisions = try await withThrowingTaskGroup(of: Int.self) { group in
            for index in 0..<64 {
                group.addTask {
                    var draft = Prompt20DailyLogDraft(); draft.generalNote = "observation \(index)"
                    let saved = try await repository.save(ownerID: .localDevice, date: selected,
                        draft: draft, now: now, requestID: UUID())
                    return try XCTUnwrap(saved).revision
                }
            }
            var values: [Int] = []
            for try await revision in group { values.append(revision) }
            return values
        }
        XCTAssertEqual(Set(revisions), Set(1...64))
        let request = UUID()
        var original = Prompt20DailyLogDraft(); original.generalNote = "one retry identity"
        let saved = try await repository.save(ownerID: .localDevice, date: selected, draft: original, now: now, requestID: request)
        var retry = original; retry.generalNote = "must not overwrite"
        let retried = try await repository.save(ownerID: .localDevice, date: selected, draft: retry, now: now, requestID: request)
        XCTAssertEqual(saved, retried)
        XCTAssertEqual(retried?.revision, 65)
        XCTAssertEqual(retried?.generalNote?.text, "one retry identity")
    }

    func testCancellationBeforeStoreEntryCannotWriteARecord() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let selected = day(2026, 9, 7)
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: cal)
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            var draft = Prompt20DailyLogDraft(); draft.generalNote = "cancelled before entry"
            return try await store.save(ownerID: .localDevice, date: selected, draft: draft, now: now)
        }
        do { _ = try await task.value; XCTFail("Cancelled request must not write") }
        catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        let active = try await store.allActiveLogs(ownerID: .localDevice)
        XCTAssertTrue(active.isEmpty)
    }

    func testRevisionOverflowRejectsWithoutChangingOriginalPersistence() async throws {
        let cal = calendar()
        let now = date(2026, 9, 7, calendar: cal)
        let selected = day(2026, 9, 7)
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "original observation"
        var log = try Prompt20DailyLogRules.makeLog(ownerID: .localDevice, date: selected,
                                                  draft: draft, existing: nil, now: now)
        log.revision = Int.max
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .millisecondsSince1970
        let encodedLog = try JSONSerialization.jsonObject(with: encoder.encode(log))
        let bytes = try JSONSerialization.data(withJSONObject: ["schemaVersion": 1, "logs": [encodedLog], "recentlyProcessedRequestIDs": []])
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        try bytes.write(to: file)
        let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: cal)
        draft.generalNote = "must not overwrite"
        do {
            _ = try await store.save(ownerID: .localDevice, date: selected, draft: draft, now: now)
            XCTFail("Revision overflow must reject, not trap or overwrite")
        } catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .corruptPersistence) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let original = try await store.load(ownerID: .localDevice, date: selected)
        XCTAssertEqual(original?.revision, Int.max)
        XCTAssertEqual(original?.generalNote?.text, "original observation")
    }

    func testInMemoryRepositoryChecksActiveSnapshotAfterIdempotentRetryLookup() async throws {
        let cal = calendar(); let now = date(2026, 9, 7, calendar: cal); let selected = day(2026, 9, 7)
        let repository = Prompt20InMemoryDailyLogRepository(calendar: cal)
        var first = Prompt20DailyLogDraft(); first.generalNote = "first"
        let saved = try await repository.save(ownerID: .localDevice, date: selected, draft: first,
            now: now, requestID: UUID(), expectation: .activeSnapshot(nil))
        var next = first; next.generalNote = "newer"
        let request = UUID()
        let newer = try await repository.save(ownerID: .localDevice, date: selected, draft: next,
            now: now, requestID: request, expectation: .activeSnapshot(saved))
        do {
            _ = try await repository.save(ownerID: .localDevice, date: selected, draft: first,
                now: now, requestID: UUID(), expectation: .activeSnapshot(saved))
            XCTFail("Old active snapshot must reject")
        } catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .recordChanged) }
        let retried = try await repository.save(ownerID: .localDevice, date: selected, draft: next,
            now: now, requestID: request, expectation: .activeSnapshot(saved))
        XCTAssertEqual(retried, newer)
        XCTAssertEqual(retried?.revision, 2)
    }

    private func seedPersistenceFile(_ file: URL) async throws -> (store: Prompt20CycleDailyLogStore, log: Prompt20DailyLog, bytes: Data, now: Date, calendar: Calendar) {
        let cal = calendar("UTC")
        let now = date(2026, 9, 7, calendar: cal)
        let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: cal)
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "original observation"
        draft.temperatureText = "98.67"; draft.temperatureUnit = .fahrenheit
        let saved = try await store.save(ownerID: .localDevice, date: day(2026, 9, 7), draft: draft, now: now)
        return (store, try XCTUnwrap(saved), try Data(contentsOf: file), now, cal)
    }

    func testOutsideDailyLogWriterCannotBeOverwrittenAndReloadIsReadOnly() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        let writer = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        var newer = Prompt20DailyLogDraft(log: fixture.log, displayTemperatureUnit: .celsius)
        newer.generalNote = "newer outside observation"
        _ = try await writer.save(ownerID: .localDevice, date: fixture.log.date, draft: newer, now: fixture.now)
        let bytes = try Data(contentsOf: file)
        var old = Prompt20DailyLogDraft(log: fixture.log, displayTemperatureUnit: .fahrenheit)
        old.generalNote = "must not overwrite"
        do {
            _ = try await fixture.store.save(ownerID: .localDevice, date: fixture.log.date, draft: old, now: fixture.now)
            XCTFail("Outside writer must invalidate the cached snapshot")
        } catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .storageChanged) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        do { _ = try await fixture.store.load(ownerID: .localDevice, date: fixture.log.date); XCTFail("Read must not report a stale cache") }
        catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .storageChanged) }
        try await fixture.store.reloadSavedLogs()
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let current = try await fixture.store.load(ownerID: .localDevice, date: fixture.log.date)
        XCTAssertEqual(current?.generalNote?.text, "newer outside observation")
    }

    func testDeletedDailyLogFileCannotBeResurrectedFromLoadedCache() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        try FileManager.default.removeItem(at: file)
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "stale editor"
        for _ in 0..<2 {
            do { _ = try await fixture.store.save(ownerID: .localDevice, date: fixture.log.date, draft: draft, now: fixture.now); XCTFail("Cleared file must stay cleared") }
            catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .storageChanged) }
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        }
        try await fixture.store.reloadSavedLogs()
        let empty = try await fixture.store.allActiveLogs(ownerID: .localDevice)
        XCTAssertTrue(empty.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        draft.generalNote = "new explicitly entered day"
        _ = try await fixture.store.save(ownerID: .localDevice, date: day(2026, 9, 6), draft: draft, now: fixture.now)
        let restored = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
        let active = try await restored.allActiveLogs(ownerID: .localDevice)
        XCTAssertEqual(active.map(\.date), [day(2026, 9, 6)])
    }

    func testUnknownDailyLogFieldsAndExplicitNullsPreserveOriginalBytes() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        for location in ["root", "record", "temperature", "explicit-null"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture.bytes) as? [String: Any])
            var logs = try XCTUnwrap(object["logs"] as? [[String: Any]])
            switch location {
            case "root": object["futureRootMetadata"] = ["retain": true]
            case "record": logs[0]["futureObservation"] = ["value": "exact future data"]
            case "temperature":
                var temperature = try XCTUnwrap(logs[0]["temperature"] as? [String: Any])
                temperature["futurePrecision"] = "preserve"; logs[0]["temperature"] = temperature
            default: logs[0]["symptoms"] = NSNull()
            }
            object["logs"] = logs
            let bytes = try JSONSerialization.data(withJSONObject: object)
            try bytes.write(to: file)
            let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
            do { _ = try await store.load(ownerID: .localDevice, date: fixture.log.date); XCTFail(location) }
            catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .unsupportedPersistence, location) }
            var draft = Prompt20DailyLogDraft(); draft.generalNote = "must not replace future fields"
            do { _ = try await store.save(ownerID: .localDevice, date: fixture.log.date, draft: draft, now: fixture.now); XCTFail(location) }
            catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .unsupportedPersistence, location) }
            XCTAssertEqual(try Data(contentsOf: file), bytes, location)
        }
    }

    func testAmbiguousOrFutureDailyLogEnvelopesAreNotSilentlyNormalized() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .millisecondsSince1970
        let original = try JSONSerialization.jsonObject(with: encoder.encode(fixture.log))
        for variant in ["schema", "history-capacity", "duplicate-day", "duplicate-id", "duplicate-request"] {
            var object: [String: Any] = ["schemaVersion": 1, "logs": [original], "recentlyProcessedRequestIDs": []]
            var expected = Prompt20DailyLogDomainError.corruptPersistence
            switch variant {
            case "schema": object["schemaVersion"] = 2; expected = .unsupportedPersistence
            case "history-capacity": object["recentlyProcessedRequestIDs"] = (0..<129).map { _ in UUID().uuidString }; expected = .unsupportedPersistence
            case "duplicate-day":
                var other = try XCTUnwrap(original as? [String: Any]); other["id"] = UUID().uuidString
                object["logs"] = [original, other]
            case "duplicate-id":
                var other = try XCTUnwrap(original as? [String: Any])
                other["date"] = try JSONSerialization.jsonObject(with: encoder.encode(day(2026, 9, 6)), options: [.fragmentsAllowed])
                object["logs"] = [original, other]
            default:
                let id = UUID().uuidString; object["recentlyProcessedRequestIDs"] = [id, id]
            }
            let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
            let store = Prompt20CycleDailyLogStore(fileURL: file, calendar: fixture.calendar)
            do { _ = try await store.load(ownerID: .localDevice, date: fixture.log.date); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, expected, variant) }
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    func testExactSnapshotChangeRequiresReloadEvenWhenDecodedRecordsMatch() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        let bytes = fixture.bytes + Data("\n  ".utf8); try bytes.write(to: file)
        do { _ = try await fixture.store.load(ownerID: .localDevice, date: fixture.log.date); XCTFail("Exact snapshot changed") }
        catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .storageChanged) }
        try await fixture.store.reloadSavedLogs()
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let actual = try await fixture.store.load(ownerID: .localDevice, date: fixture.log.date)
        XCTAssertEqual(actual?.temperature, fixture.log.temperature)
    }

    func testOutsideFutureFieldsStayProtectedAfterExplicitReloadAttempt() async throws {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let fixture = try await seedPersistenceFile(file)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: fixture.bytes) as? [String: Any])
        object["futureSourceMetadata"] = "must remain"
        let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
        do { _ = try await fixture.store.allActiveLogs(ownerID: .localDevice); XCTFail("Cache cannot mask an outside change") }
        catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .storageChanged) }
        do { try await fixture.store.reloadSavedLogs(); XCTFail("Reload cannot discard future fields") }
        catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .unsupportedPersistence) }
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "must not write"
        do { _ = try await fixture.store.save(ownerID: .localDevice, date: fixture.log.date, draft: draft, now: fixture.now); XCTFail("Future fields must survive") }
        catch { XCTAssertEqual(error as? Prompt20DailyLogDomainError, .unsupportedPersistence) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
    }

    func testLocalDayRoundTripUsesCalendarDay() async {
        let cal = calendar()
        let source = date(2026, 9, 7, hour: 23, calendar: cal)
        let local = Prompt20LocalDay(date: source, calendar: cal)
        XCTAssertEqual(local, day(2026, 9, 7))
        XCTAssertEqual(Prompt20LocalDay(date: local.date(in: cal)!, calendar: cal), local)
    }

    func testLocalDaySurvivesDSTBoundary() async {
        let cal = calendar()
        let local = day(2026, 3, 8)
        let restored = local.date(in: cal)!
        XCTAssertEqual(Prompt20LocalDay(date: restored, calendar: cal), local)
    }

    func testFutureDateRuleUsesLocalCalendarDayNotElapsedHours() async {
        let cal = calendar()
        let now = date(2026, 9, 7, hour: 23, calendar: cal)
        XCTAssertFalse(Prompt20DailyLogRules.isFuture(day(2026, 9, 7), relativeTo: now, calendar: cal))
        XCTAssertTrue(Prompt20DailyLogRules.isFuture(day(2026, 9, 8), relativeTo: now, calendar: cal))
    }

    func testPartialBleedingOnlyLogIsValid() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .spotting
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.bleeding?.level, .spotting)
        XCTAssertNil(log.symptoms)
        XCTAssertNil(log.temperature)
        XCTAssertTrue(log.hasRecordedContent)
    }

    func testBleedingObservationDoesNotDeclarePeriodInCalendarBridge() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .heavy
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotations = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: Prompt19CalendarMonth(year: 2026, month: 9),
            calendar: calendar()
        )
        XCTAssertEqual(annotations.count, 1)
        XCTAssertFalse(annotations[0].recordedPeriod)
        XCTAssertFalse(annotations[0].predictedPeriod)
        XCTAssertFalse(annotations[0].fertileEstimated)
        XCTAssertFalse(annotations[0].ovulationEstimated)
    }

    func testSymptomsRemainStructuredAndNoteSeparate() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps, .bloating, .headache]
        draft.symptomNote = "after lunch"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.symptoms?.selectedIDs, [.cramps, .bloating, .headache])
        XCTAssertEqual(log.symptoms?.note, "after lunch")
    }

    func testSymptomSummaryDoesNotInventSeverity() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps]
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let summary = Prompt20DailyLogRules.summary(for: log)
        XCTAssertEqual(summary.symptomNames, ["cramps"])
        XCTAssertFalse(summary.symptomNames.contains { $0.contains("mild") || $0.contains("severe") })
    }

    func testFahrenheitConvertsToCanonicalCelsius() async {
        let value = Prompt20TemperatureObservation(
            originalValue: 98.6,
            originalUnit: .fahrenheit,
            readingType: .general
        )
        XCTAssertEqual(value.canonicalCelsius, 37.0, accuracy: 0.0001)
        XCTAssertEqual(value.value(in: .fahrenheit), 98.6, accuracy: 0.0001)
    }

    func testCelsiusConvertsToFahrenheit() async {
        let value = Prompt20TemperatureObservation(
            originalValue: 36.5,
            originalUnit: .celsius,
            readingType: .basalWaking
        )
        XCTAssertEqual(value.value(in: .fahrenheit), 97.7, accuracy: 0.0001)
    }

    func testTemperatureValidationRejectsNonnumericInputWithoutDiscardingDraft() async {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "ninety seven"
        let result = Prompt20DailyLogRules.validate(draft)
        XCTAssertEqual(result.issues, [.invalidTemperatureFormat])
        XCTAssertEqual(draft.temperatureText, "ninety seven")
    }

    func testTemperatureValidationRejectsObviousUnitTypo() async {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "986"
        draft.temperatureUnit = .fahrenheit
        XCTAssertEqual(Prompt20DailyLogRules.validate(draft).issues, [.implausibleTemperature])
    }

    func testTemperatureValidationAcceptsReasonableGeneralInput() async {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "98.6"
        draft.temperatureUnit = .fahrenheit
        XCTAssertTrue(Prompt20DailyLogRules.validate(draft).isValid)
    }

    func testGeneralTemperatureDoesNotBecomeBBTCalendarMarker() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "98.6"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .general
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertFalse(annotation.bbtRecorded)
        XCTAssertNil(annotation.temperatureDisplay)
    }

    func testBasalTemperatureBecomesBBTCalendarMarker() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureText = "97.8"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .basalWaking
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertTrue(annotation.bbtRecorded)
        XCTAssertEqual(annotation.temperatureDisplay, "97.8°F · basal / waking")
    }

    func testCervicalFluidStaysObservationOnly() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.cervicalFluidCategory = .eggWhiteStretchy
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.cervicalFluid?.category, .eggWhiteStretchy)
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertFalse(annotation.fertileEstimated)
        XCTAssertFalse(annotation.ovulationEstimated)
    }

    func testMedicationRequiresNameWhenOtherFieldsContainContent() async {
        var draft = Prompt20DailyLogDraft()
        draft.medications = [Prompt20MedicationEntry(dose: "10 mg")]
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.medicationNameRequired(index: 0)]
        )
    }

    func testMultipleMedicationsRemainSeparateRows() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.medications = [
            Prompt20MedicationEntry(name: "Medication A", dose: "10 mg"),
            Prompt20MedicationEntry(name: "Supplement B", time: "8:00 am")
        ]
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.medications.count, 2)
        XCTAssertEqual(log.medications.map(\.name), ["Medication A", "Supplement B"])
    }

    func testGeneralNoteIsSensitiveDataFieldNotCalendarPrimaryState() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "private note"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertEqual(log.generalNote?.text, "private note")
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertTrue(annotation.noteAdded)
        XCTAssertEqual(annotation.noteText, "private note")
        XCTAssertEqual(annotation.primaryState, .none)
    }

    func testEditPreservesStableIDAndCreatedAtAndIncrementsRevision() async throws {
        var firstDraft = Prompt20DailyLogDraft()
        firstDraft.selectedSymptoms = [.cramps]
        let created = date(2026, 9, 7, hour: 10)
        let first = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: firstDraft,
            existing: nil,
            now: created
        )

        var editedDraft = firstDraft
        editedDraft.selectedSymptoms.insert(.bloating)
        let editedAt = date(2026, 9, 7, hour: 11)
        let edited = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: editedDraft,
            existing: first,
            now: editedAt
        )

        XCTAssertEqual(edited.id, first.id)
        XCTAssertEqual(edited.createdAt, first.createdAt)
        XCTAssertEqual(edited.revision, first.revision + 1)
        XCTAssertEqual(edited.updatedAt, editedAt)
    }

    func testInMemoryRepositoryEnforcesOneCanonicalLogPerOwnerAndDate() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)

        var firstDraft = Prompt20DailyLogDraft()
        firstDraft.generalNote = "first"
        let first = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: firstDraft,
            now: now,
            requestID: UUID()
        )!

        var secondDraft = firstDraft
        secondDraft.generalNote = "edited"
        let second = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: secondDraft,
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )!

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(second.generalNote?.text, "edited")
        let activeLogs = try await repo.allActiveLogs(ownerID: .localDevice)
        XCTAssertEqual(activeLogs.count, 1)
    }

    func testRepeatedRequestIDIsIdempotent() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)
        let requestID = UUID()
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "once"

        let first = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now,
            requestID: requestID
        )!
        let second = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now.addingTimeInterval(90),
            requestID: requestID
        )!

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.revision, second.revision)
        XCTAssertEqual(first.updatedAt, second.updatedAt)
    }

    func testIntentionallyClearingExistingLogRemovesActiveLog() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        let target = day(2026, 9, 7)
        let now = date(2026, 9, 7, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "delete me"
        _ = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: draft,
            now: now,
            requestID: UUID()
        )
        let cleared = try await repo.save(
            ownerID: .localDevice,
            date: target,
            draft: Prompt20DailyLogDraft(),
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )
        XCTAssertNil(cleared)
        let loadedAfterClear = try await repo.load(ownerID: .localDevice, date: target)
        XCTAssertNil(loadedAfterClear)
    }

    func testRepositoryRejectsFutureObservationSaveEvenIfUICheckIsBypassed() async throws {
        let cal = calendar()
        let repo = Prompt20InMemoryDailyLogRepository(calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "future body observation"
        do {
            _ = try await repo.save(
                ownerID: .localDevice,
                date: day(2026, 9, 8),
                draft: draft,
                now: date(2026, 9, 7, calendar: cal),
                requestID: UUID()
            )
            XCTFail("Future observation save should have failed")
        } catch let error as Prompt20DailyLogDomainError {
            XCTAssertEqual(error, .futureDate)
        }
    }

    func testFileStorePersistsAndReloadsCanonicalLog() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let firstStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps, .headache]
        draft.generalNote = "persisted"
        let now = date(2026, 9, 7, calendar: cal)
        let saved = try await firstStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: UUID()
        )!

        let reloadedStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loaded = try await reloadedStore.load(
            ownerID: .localDevice,
            date: day(2026, 9, 7)
        )
        XCTAssertEqual(loaded, saved)
    }

    func testFileStorePersistsDeletionTombstoneAsInactive() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.bleedingLevel = .light
        let now = date(2026, 9, 7, calendar: cal)
        _ = try await store.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: UUID()
        )
        _ = try await store.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: Prompt20DailyLogDraft(),
            now: now.addingTimeInterval(60),
            requestID: UUID()
        )

        let reloaded = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loadedAfterReload = try await reloaded.load(ownerID: .localDevice, date: day(2026, 9, 7))
        let activeAfterReload = try await reloaded.allActiveLogs(ownerID: .localDevice)
        XCTAssertNil(loadedAfterReload)
        XCTAssertTrue(activeAfterReload.isEmpty)
    }

    func testCalendarBridgeFiltersToDisplayedMonth() async throws {
        var septemberDraft = Prompt20DailyLogDraft()
        septemberDraft.selectedSymptoms = [.cramps]
        let september = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: septemberDraft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        var octoberDraft = Prompt20DailyLogDraft()
        octoberDraft.generalNote = "october"
        let october = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 10, 1),
            draft: octoberDraft,
            existing: nil,
            now: date(2026, 10, 1)
        )
        let annotations = Prompt20CalendarIntegration.annotations(
            for: [september, october],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        )
        XCTAssertEqual(annotations.map(\.key), [Prompt19CalendarDateKey(year: 2026, month: 9, day: 7)])
    }

    func testCalendarMetadataRespectsPrompt19TwoIndicatorPriority() async throws {
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps]
        draft.temperatureText = "97.8"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .basalWaking
        draft.generalNote = "note"
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            existing: nil,
            now: date(2026, 9, 7)
        )
        let annotation = Prompt20CalendarIntegration.annotations(
            for: [log],
            month: .init(year: 2026, month: 9),
            calendar: calendar()
        ).first!
        XCTAssertEqual(annotation.visibleMetadata, [.bbt, .symptom])
        XCTAssertTrue(annotation.noteAdded)
    }

    func testEmptyDraftProducesNoRecordedObservations() async throws {
        let log = try Prompt20DailyLogRules.makeLog(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: Prompt20DailyLogDraft(),
            existing: nil,
            now: date(2026, 9, 7)
        )
        XCTAssertFalse(log.hasRecordedContent)
        XCTAssertNil(log.bleeding)
        XCTAssertNil(log.symptoms)
        XCTAssertNil(log.temperature)
        XCTAssertNil(log.cervicalFluid)
        XCTAssertTrue(log.medications.isEmpty)
        XCTAssertNil(log.generalNote)
    }

    func testFailedFileWriteRollsBackInMemoryMutation() async throws {
        let cal = calendar()
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let blockingFile = root.appendingPathComponent("not-a-directory")
        try Data("block".utf8).write(to: blockingFile)
        let impossibleURL = blockingFile.appendingPathComponent("daily-logs.json")
        let store = Prompt20CycleDailyLogStore(fileURL: impossibleURL, calendar: cal)

        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "must not survive a failed write"

        do {
            _ = try await store.save(
                ownerID: .localDevice,
                date: day(2026, 9, 7),
                draft: draft,
                now: date(2026, 9, 7, calendar: cal),
                requestID: UUID()
            )
            XCTFail("Write should fail when the parent path is a regular file")
        } catch let error as Prompt20DailyLogDomainError {
            XCTAssertEqual(error, .persistenceUnavailable)
        }

        let loaded = try await store.load(ownerID: .localDevice, date: day(2026, 9, 7))
        XCTAssertNil(loaded)
    }

    func testCorruptPersistenceNeverSilentlyTurnsIntoEmptyStore() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("not valid json".utf8).write(to: fileURL)

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        for _ in 0..<2 {
            do {
                _ = try await store.load(ownerID: .localDevice, date: day(2026, 9, 7))
                XCTFail("Corrupt persistence must not be treated as an empty archive")
            } catch let error as Prompt20DailyLogDomainError {
                XCTAssertEqual(error, .corruptPersistence)
            }
        }
    }

    func testPersistedRequestIDRemainsIdempotentAfterStoreReload() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let requestID = UUID()
        let now = date(2026, 9, 7, calendar: cal)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "only once"

        let firstStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let first = try await firstStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now,
            requestID: requestID
        )!

        let reloadedStore = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let second = try await reloadedStore.save(
            ownerID: .localDevice,
            date: day(2026, 9, 7),
            draft: draft,
            now: now.addingTimeInterval(120),
            requestID: requestID
        )!

        XCTAssertEqual(second.id, first.id)
        XCTAssertEqual(second.revision, first.revision)
        XCTAssertEqual(second.updatedAt, first.updatedAt)
    }

    func testBleedingNoteWithoutLevelIsRejectedRatherThanSilentlyDropped() async {
        var draft = Prompt20DailyLogDraft()
        draft.bleedingNote = "important detail"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.bleedingLevelRequiredForNote]
        )
    }

    func testTemperatureContextWithoutValueIsRejectedRatherThanSilentlyDropped() async {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureReadingType = .basalWaking
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.temperatureValueRequired]
        )
    }

    func testTemperatureNoteWithoutValueIsRejectedRatherThanSilentlyDropped() async {
        var draft = Prompt20DailyLogDraft()
        draft.temperatureNote = "slept poorly"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.temperatureValueRequired]
        )
    }

    func testCervicalNoteWithoutCategoryIsRejectedRatherThanSilentlyDropped() async {
        var draft = Prompt20DailyLogDraft()
        draft.cervicalFluidNote = "hard to categorize"
        XCTAssertEqual(
            Prompt20DailyLogRules.validate(draft).issues,
            [.cervicalCategoryRequiredForNote]
        )
    }

    func testPersistencePreservesSubsecondRevisionTimestamps() async throws {
        let cal = calendar()
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("Prompt20Tests-\(UUID().uuidString)", isDirectory: true)
        let fileURL = directory.appendingPathComponent("daily-logs.json")
        defer { try? FileManager.default.removeItem(at: directory) }

        let preciseNow = Date(timeIntervalSince1970: 1_788_800_000.731)
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "timestamp precision"

        let store = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let saved = try await store.save(
            ownerID: .localDevice,
            date: Prompt20LocalDay(date: preciseNow, calendar: cal),
            draft: draft,
            now: preciseNow,
            requestID: UUID()
        )!

        let reloaded = Prompt20CycleDailyLogStore(fileURL: fileURL, calendar: cal)
        let loaded = try await reloaded.load(ownerID: .localDevice, date: saved.date)!
        XCTAssertEqual(loaded.createdAt, preciseNow)
        XCTAssertEqual(loaded.updatedAt, preciseNow)
    }
}
