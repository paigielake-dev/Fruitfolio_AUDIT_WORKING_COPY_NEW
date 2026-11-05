import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BSymptomTimelineTests: XCTestCase {
    private func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar
    }
    private func date(_ month: Int, _ day: Int) -> Date {
        calendar().date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private func occurrence(_ date: Date, symptom: Prompt20SymptomID = .cramps, cycleDay: Int? = nil) -> Prompt24SymptomOccurrence {
        .init(symptomID: symptom, date: date, cycleDay: cycleDay, completedCycleIndex: nil)
    }
    func testSameCycleDayInDifferentMonthsIsNotOverlaid() {
        let observations = [occurrence(date(2, 5), cycleDay: 5), occurrence(date(1, 5), cycleDay: 5)]
        let timeline = Prompt24SymptomTimeline(occurrences: observations, selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.map(\.dayOffset), [0, 31])
        XCTAssertEqual(timeline.spanDays, 31)
        XCTAssertEqual(timeline.points.map { $0.occurrence.date }, [date(1, 5), date(2, 5)])
    }
    func testObservationWithoutCycleAssignmentIsRetained() {
        let observation = occurrence(date(1, 5))
        let timeline = Prompt24SymptomTimeline(occurrences: [observation], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.count, 1)
        XCTAssertEqual(timeline.points.first?.occurrence, observation)
        XCTAssertNil(timeline.points.first?.occurrence.cycleDay)
        XCTAssertEqual(timeline.omittedInvalidDateCount, 0)
    }
    func testDSTUsesCivilDaySpacingRatherThanElapsedHours() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(3, 7)), occurrence(date(3, 9))], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.map(\.dayOffset), [0, 2])
        XCTAssertEqual(timeline.spanDays, 2)
    }
    func testSelectionFiltersOnlyExplicitlyHiddenSymptoms() {
        let observations = [occurrence(date(1, 5)), occurrence(date(1, 5), symptom: .fatigue)]
        let timeline = Prompt24SymptomTimeline(occurrences: observations, selected: [.fatigue], calendar: calendar())
        XCTAssertEqual(timeline.symptoms, [.fatigue])
        XCTAssertEqual(timeline.points.map { $0.occurrence.symptomID }, [.fatigue])
        XCTAssertEqual(timeline.points.map(\.row), [0])
    }
    func testUnloggedDaysAreNeverSynthesizedAsAbsentSymptoms() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(1, 1)), occurrence(date(1, 31))], selected: [.cramps], calendar: calendar())
        XCTAssertEqual(timeline.points.count, 2)
        XCTAssertEqual(timeline.spanDays, 30)
    }
    func testEmptySelectionDoesNotInventDomainOrPoints() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(date(1, 1))], selected: [], calendar: calendar())
        XCTAssertTrue(timeline.points.isEmpty)
        XCTAssertNil(timeline.firstDate)
        XCTAssertNil(timeline.lastDate)
    }
    func testInvalidDateIsCountedWithoutBeingReplaced() {
        let timeline = Prompt24SymptomTimeline(occurrences: [occurrence(Date(timeIntervalSinceReferenceDate: .nan))], selected: [.cramps], calendar: calendar())
        XCTAssertTrue(timeline.points.isEmpty)
        XCTAssertNil(timeline.firstDate)
        XCTAssertEqual(timeline.omittedInvalidDateCount, 1)
    }
}
