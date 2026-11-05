import XCTest
@testable import Fruitfolio

final class Prompt1BCalendarPresentationPolicyTests: XCTestCase {
    func testContextChangeHidesOnlyInapplicableEstimatesWithoutChangingRecordedData() {
        let key = Prompt19CalendarDateKey(year: 2026, month: 11, day: 5)
        let original = Prompt19CalendarDayAnnotation(key: key, cycleDay: 7, recordedPeriod: true, predictedPeriod: true,
            fertileEstimated: true, ovulationEstimated: true, symptomsLogged: true, bbtRecorded: true, noteAdded: true,
            symptomSummary: ["recorded symptom"], temperatureDisplay: "36.50 °C", noteText: "user note")
        let policy = Prompt27AContextPolicyEngine().policy(for: .init(reproductiveStage: .pregnant))
        let shown = Prompt19CalendarPresentationPolicy.annotations([key: original], context: policy)[key]!
        XCTAssertFalse(shown.predictedPeriod); XCTAssertFalse(shown.fertileEstimated); XCTAssertFalse(shown.ovulationEstimated)
        XCTAssertTrue(shown.recordedPeriod); XCTAssertTrue(shown.bbtRecorded); XCTAssertTrue(shown.noteAdded)
        XCTAssertEqual(shown.cycleDay, original.cycleDay)
        XCTAssertEqual(shown.temperatureDisplay, original.temperatureDisplay)
        XCTAssertEqual(shown.noteText, original.noteText)
        XCTAssertEqual(shown.symptomSummary, original.symptomSummary)
        let restored = Prompt19CalendarPresentationPolicy.annotations([key: original], context: .init())[key]
        XCTAssertEqual(restored, original)
    }
    func testOlderMonthOrContextResultCannotWinARequestRace() {
        let month = Prompt19CalendarMonth(year: 2026, month: 11)
        let old = Prompt19CalendarLoadIdentity(month: month, context: .init())
        let changedContext = Prompt19CalendarLoadIdentity(month: month,
            context: Prompt27AContextPolicyEngine().policy(for: .init(reproductiveStage: .pregnant)))
        XCTAssertTrue(old.accepts(.empty(month: month), current: old))
        XCTAssertFalse(old.accepts(.empty(month: month), current: changedContext))
        XCTAssertFalse(old.accepts(.empty(month: .init(year: 2026, month: 12)), current: old))
    }
}
