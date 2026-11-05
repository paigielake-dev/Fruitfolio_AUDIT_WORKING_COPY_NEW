import XCTest
@testable import Fruitfolio

final class Prompt1BHormoneCivilDateTests: XCTestCase {
    private func instant(_ day: Int, hour: Int) throws -> Date {
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        return try XCTUnwrap(utc.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour)))
    }
    private func calendar(_ identifier: Calendar.Identifier, zone: String) throws -> Calendar {
        var calendar = Calendar(identifier: identifier); calendar.timeZone = try XCTUnwrap(TimeZone(identifier: zone))
        return calendar
    }
    func testEnteredDaySurvivesTravelExportAndStoreReinitializationWithoutClaimingATestTime() throws {
        let west = try calendar(.buddhist, zone: "America/Los_Angeles")
        let east = try calendar(.hebrew, zone: "Asia/Bangkok")
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.50"; record.unit = "ng/mL"; record.resultLocaleIdentifier = "en_US"
        try record.setReportedTestDate(instant(5, hour: 1), calendar: west)
        XCTAssertEqual(record.reportedTestDay?.description, "2026-11-04")
        XCTAssertEqual(record.testDatePrecision, .day)
        XCTAssertEqual(record.testDateEntryTimeZoneIdentifier, "America/Los_Angeles")
        let shown = try XCTUnwrap(record.dateForDisplay(calendar: east))
        XCTAssertEqual(try Prompt13LocalDate(shown, calendar: east).description, "2026-11-04")
        let suite = "HormoneCivilDateTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements").save(record)
        let restarted = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
        XCTAssertEqual(restarted.records.first, record)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        XCTAssertEqual(try decoder.decode([FruitfolioHormoneMeasurement].self, from: restarted.exportJSON()).first, record)
        let snapshot = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [record.id], personalCategories: [],
            measurements: [record], context: .unspecified))
        let fields = try XCTUnwrap(snapshot.records.first?.fields)
        XCTAssertEqual(fields["test_date_gregorian"], "2026-11-04")
        XCTAssertEqual(fields["test_time_of_day"], "not_recorded")
        XCTAssertNil(fields["test_date"])
        XCTAssertFalse(fields["test_date_gregorian"]?.contains("T") == true)
    }
    func testLegacyMissingCivilDayAndEntryZoneRemainUnknownWhenEditingOtherFields() throws {
        var record = FruitfolioHormoneMeasurement()
        record.result = "1.25"; record.unit = "ng/mL"; record.resultLocaleIdentifier = "en_US"
        record.testDate = try instant(5, hour: 1)
        let encoder = JSONEncoder()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(record)) as? [String: Any])
        object.removeValue(forKey: "reportedTestDay"); object.removeValue(forKey: "testDateEntryTimeZoneIdentifier")
        object.removeValue(forKey: "testDatePrecision")
        var legacy = try JSONDecoder().decode(FruitfolioHormoneMeasurement.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(legacy.reportedTestDay); XCTAssertNil(legacy.testDateEntryTimeZoneIdentifier); XCTAssertNil(legacy.testDatePrecision)
        legacy.notes = "an unrelated note edit"
        let suite = "HormoneLegacyDateTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
        try store.save(legacy)
        XCTAssertNil(store.records.first?.reportedTestDay)
        XCTAssertEqual(store.records.first?.testDate, record.testDate)
        let snapshot = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [legacy.id], personalCategories: [],
            measurements: [legacy], context: .unspecified))
        XCTAssertEqual(snapshot.records.first?.fields["test_date_basis"], "date_value_in_current_timezone_original_entry_timezone_unknown")
        XCTAssertEqual(snapshot.records.first?.fields["test_time_of_day"], "not_recorded")
    }
    func testSameDayRecordsHaveStableOrderRatherThanInventedLaboratoryTimeSequence() throws {
        let zone = try calendar(.gregorian, zone: "UTC")
        var first = FruitfolioHormoneMeasurement(); first.result = "1"; first.unit = "ng/mL"
        first.id = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001"))
        try first.setReportedTestDate(instant(4, hour: 1), calendar: zone)
        var second = first
        second.id = try XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000002"))
        second.reportedTestDay = nil
        try second.setReportedTestDate(instant(4, hour: 22), calendar: zone)
        let suite = "HormoneDateOrderTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
        try store.save(second); try store.save(first)
        XCTAssertEqual(store.history().map(\.id), [first.id, second.id])
    }
    func testSkippedCivilDayInTargetZoneIsNotSilentlyReplaced() throws {
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = try XCTUnwrap(utc.date(from: DateComponents(year: 2011, month: 12, day: 30, hour: 12)))
        var record = FruitfolioHormoneMeasurement()
        try record.setReportedTestDate(date, calendar: utc)
        let apia = try calendar(.gregorian, zone: "Pacific/Apia")
        XCTAssertNil(record.dateForDisplay(calendar: apia))
        XCTAssertEqual(record.reportedTestDay?.description, "2011-12-30")
    }
    func testInvalidDateCaptureDoesNotPartiallyMutateExistingRecord() throws {
        var record = FruitfolioHormoneMeasurement()
        let before = record
        XCTAssertThrowsError(try record.setReportedTestDate(Date(timeIntervalSince1970: .infinity), calendar: .current))
        XCTAssertEqual(record, before)
    }
}
