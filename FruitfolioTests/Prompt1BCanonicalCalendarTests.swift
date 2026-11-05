import XCTest
@testable import Fruitfolio

final class Prompt1BCanonicalCalendarTests: XCTestCase {
    private func utc() -> Calendar {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
    func testStoredCivilDateIsGregorianAcrossNonGregorianDisplayCalendars() throws {
        let absolute = try XCTUnwrap(utc().date(from: DateComponents(year: 2024, month: 2, day: 29, hour: 12)))
        for identifier: Calendar.Identifier in [.gregorian, .buddhist, .hebrew, .islamicUmmAlQura, .japanese] {
            var display = Calendar(identifier: identifier); display.timeZone = utc().timeZone
            let local = try Prompt13LocalDate(absolute, calendar: display)
            XCTAssertEqual(local.year, 2024); XCTAssertEqual(local.month, 2); XCTAssertEqual(local.day, 29)
            XCTAssertEqual(try local.foundationDate(in: display), absolute)
            XCTAssertEqual(try local.addingDays(1).description, "2024-03-01")
            let logDay = Prompt20LocalDay(date: absolute, calendar: display)
            XCTAssertEqual(logDay, Prompt20LocalDay(year: 2024, month: 2, day: 29))
            XCTAssertEqual(logDay.date(in: display), absolute)
        }
    }
    func testCallerTimeZoneStillDeterminesObservedDayWithoutChangingStoredEventOnTravel() throws {
        let instant = try XCTUnwrap(utc().date(from: DateComponents(year: 2026, month: 11, day: 5, hour: 1)))
        var west = Calendar(identifier: .buddhist); west.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))
        var east = Calendar(identifier: .hebrew); east.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Bangkok"))
        let observed = try Prompt13LocalDate(instant, calendar: west)
        XCTAssertEqual(observed.description, "2026-11-04")
        XCTAssertEqual(try Prompt13LocalDate(instant, calendar: east).description, "2026-11-05")
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let before = try encoder.encode(observed)
        XCTAssertEqual(try Prompt13LocalDate(observed.foundationDate(in: east), calendar: east), observed)
        XCTAssertEqual(try encoder.encode(observed), before)
    }
    func testImpossibleStoredDatesRejectInsteadOfRollingIntoAnotherMonthOrInventingEpoch() throws {
        let invalid = Data(#"{"year":2026,"month":2,"day":30}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(Prompt13LocalDate.self, from: invalid))
        XCTAssertThrowsError(try JSONDecoder().decode(Prompt20LocalDay.self, from: invalid))
        let invalidDay = Prompt20LocalDay(year: 2026, month: 2, day: 30)
        XCTAssertNil(invalidDay.date(in: utc()))
        XCTAssertThrowsError(try Prompt20DailyLogRules.makeLog(ownerID: .localDevice, date: invalidDay, draft: .init(), existing: nil, now: Date()))
        let nonfinite = Date(timeIntervalSince1970: .infinity)
        XCTAssertThrowsError(try Prompt13LocalDate(nonfinite, calendar: utc()))
        XCTAssertNil(Prompt20LocalDay(date: nonfinite, calendar: utc()).date(in: utc()))
    }
    func testDailyLogProjectionUsesDisplayCalendarKeysButNeverRewritesStoredDay() throws {
        let absolute = try XCTUnwrap(utc().date(from: DateComponents(year: 2024, month: 2, day: 29, hour: 12)))
        var display = Calendar(identifier: .buddhist); display.timeZone = utc().timeZone
        var draft = Prompt20DailyLogDraft(); draft.generalNote = "recorded note"
        let log = try Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
            date: .init(date: absolute, calendar: display), draft: draft, existing: nil, now: absolute)
        let month = Prompt19CalendarMonth(containing: absolute, calendar: display)
        let projected = Prompt20CalendarProjection.annotations(for: [log], month: month, calendar: display)
        XCTAssertEqual(projected.count, 1)
        XCTAssertEqual(projected.first?.key.year, 2567)
        XCTAssertEqual(projected.first?.key.day, 29)
        XCTAssertEqual(projected.first?.noteText, "recorded note")
        XCTAssertEqual(log.date.year, 2024)
        XCTAssertFalse(projected.contains { $0.recordedPeriod || $0.predictedPeriod || $0.fertileEstimated || $0.ovulationEstimated })
    }
    func testExistingAmbiguousLegacyYearIsNotGuessedOrRewritten() throws {
        let legacy = try JSONDecoder().decode(Prompt13LocalDate.self, from: Data(#"{"year":2569,"month":11,"day":5}"#.utf8))
        XCTAssertEqual(legacy.year, 2569, "No original calendar identifier exists; never assume a stored year should be offset")
    }
    func testActualCalendarLoaderMapsCanonicalRecordsIntoBuddhistDisplayMonth() async throws {
        let now = try XCTUnwrap(utc().date(from: DateComponents(year: 2026, month: 5, day: 5, hour: 12)))
        var display = Calendar(identifier: .buddhist); display.timeZone = utc().timeZone
        let cycle = Prompt13CycleStore.inMemory()
        _ = try await cycle.recordCycleStart(on: .init(year: 2026, month: 5, day: 1), today: .init(year: 2026, month: 5, day: 5))
        let onboard = Prompt14CycleOnboardingStore.inMemory(cycleStore: cycle)
        let loader = Prompt19CalendarLoader(todayLoader: .init(cycleStore: cycle, onboardingStore: onboard, calendar: display))
        let result = try await loader.load(month: .init(containing: now, calendar: display), now: now)
        XCTAssertTrue(result.annotations[.init(year: 2569, month: 5, day: 1)]?.recordedPeriod == true)
        XCTAssertEqual(result.annotations[.init(year: 2569, month: 5, day: 5)]?.cycleDay, 5)
    }

    func testNonfiniteTemperatureIsRejectedBeforeConstructingAnObservation() {
        for text in ["NaN", "nan", "inf", "-inf", "infinity"] {
            var draft = Prompt20DailyLogDraft(); draft.temperatureText = text
            let validation = Prompt20DailyLogRules.validate(draft)
            XCTAssertFalse(validation.isValid)
            XCTAssertTrue(validation.issues.contains(.invalidTemperatureFormat))
            XCTAssertThrowsError(try Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
                date: .init(year: 2026, month: 11, day: 5), draft: draft, existing: nil, now: Date()))
        }
    }
    func testInvalidDateInActualCycleFileIsPreservedAndCannotBeOverwrittenByANewRecord() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let original = Prompt13CycleStore.inMemory()
        _ = try await original.recordCycleStart(on: .init(year: 2026, month: 2, day: 28), today: .init(year: 2026, month: 3, day: 1))
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let archive = try await original.snapshot()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(archive)) as? [String: Any])
        var starts = try XCTUnwrap(object["cycleStarts"] as? [[String: Any]])
        starts[0]["date"] = ["year": 2026, "month": 2, "day": 30]
        object["cycleStarts"] = starts
        let bytes = try JSONSerialization.data(withJSONObject: object, options: .sortedKeys)
        let url = directory.appendingPathComponent("cycle.json")
        try bytes.write(to: url)
        let store = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: url))
        do {
            _ = try await store.recordCycleStart(on: .init(year: 2026, month: 3, day: 1), today: .init(year: 2026, month: 3, day: 1))
            XCTFail("Corrupt original dates must block writes")
        } catch { }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

}
