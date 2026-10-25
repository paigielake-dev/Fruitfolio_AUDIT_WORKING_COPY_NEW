import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt19CalendarEngineTests: XCTestCase {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(secondsFromGMT: 0)!
        c.firstWeekday = 1
        return c
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.calendar = calendar
        c.timeZone = calendar.timeZone
        c.year = y
        c.month = m
        c.day = d
        c.hour = 12
        return calendar.date(from: c)!
    }

    func testAugust2026RequiresSixRows() {
        let engine = Prompt19CalendarEngine(calendar: calendar)
        let model = engine.buildMonth(
            month: Prompt19CalendarMonth(year: 2026, month: 8),
            annotations: [:],
            today: date(2026, 8, 1),
            selected: nil
        )

        XCTAssertEqual(model.weekRowCount, 6)
        XCTAssertEqual(model.cells.count, 42)
    }

    func testFebruary2026UsesFourRows() {
        let engine = Prompt19CalendarEngine(calendar: calendar)
        let model = engine.buildMonth(
            month: Prompt19CalendarMonth(year: 2026, month: 2),
            annotations: [:],
            today: date(2026, 2, 1),
            selected: nil
        )

        XCTAssertEqual(model.weekRowCount, 4)
        XCTAssertEqual(model.cells.count, 28)
    }

    func testLeapFebruaryHas29RealDates() {
        let engine = Prompt19CalendarEngine(calendar: calendar)
        let model = engine.buildMonth(
            month: Prompt19CalendarMonth(year: 2028, month: 2),
            annotations: [:],
            today: date(2028, 2, 1),
            selected: nil
        )

        XCTAssertEqual(
            model.cells.compactMap(\.dateNumber).count,
            29
        )
    }

    func testMonthGridPlacesFirstDayInCorrectWeekdayColumn() {
        let engine = Prompt19CalendarEngine(calendar: calendar)
        let model = engine.buildMonth(
            month: Prompt19CalendarMonth(year: 2026, month: 8),
            annotations: [:],
            today: date(2026, 8, 1),
            selected: nil
        )

        XCTAssertEqual(
            model.cells.firstIndex(where: { $0.dateNumber == 1 }),
            6
        )
    }

    func testRecordedPeriodDominatesEstimatedStates() {
        let key = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 17
        )

        let annotation = Prompt19CalendarDayAnnotation(
            key: key,
            recordedPeriod: true,
            predictedPeriod: true,
            fertileEstimated: true,
            ovulationEstimated: true
        )

        XCTAssertEqual(
            annotation.primaryState,
            .recordedPeriod
        )
    }

    func testMetadataIsCappedAtTwoAndPrioritized() {
        let key = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 17
        )

        let annotation = Prompt19CalendarDayAnnotation(
            key: key,
            symptomsLogged: true,
            bbtRecorded: true,
            noteAdded: true
        )

        XCTAssertEqual(
            annotation.visibleMetadata,
            [.bbt, .symptom]
        )
    }

    func testCycleDayOneOnRecordedStart() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let start = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 4
        )

        let today = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 20
        )

        XCTAssertEqual(
            engine.cycleDay(
                for: start,
                recordedCycleStarts: [start],
                today: today
            ),
            1
        )
    }

    func testCycleDayUsesRecordedDateDifference() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let start = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 4
        )

        let target = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 17
        )

        let today = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 20
        )

        XCTAssertEqual(
            engine.cycleDay(
                for: target,
                recordedCycleStarts: [start],
                today: today
            ),
            14
        )
    }

    func testFutureCycleDayIsNotFabricated() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let start = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 4
        )

        let target = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 25
        )

        let today = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 20
        )

        XCTAssertNil(
            engine.cycleDay(
                for: target,
                recordedCycleStarts: [start],
                today: today
            )
        )
    }

    func testWindowKeysStayInsideRequestedMonth() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let keys = engine.keys(
            in: date(2026, 7, 30)...date(2026, 8, 3),
            restrictedTo: Prompt19CalendarMonth(
                year: 2026,
                month: 8
            )
        )

        XCTAssertEqual(
            keys.map(\.day),
            [1, 2, 3]
        )
    }

    func testMonthShiftCrossesYearBoundary() {
        let december = Prompt19CalendarMonth(
            year: 2026,
            month: 12
        )

        let january = december.shifted(
            by: 1,
            calendar: calendar
        )

        XCTAssertEqual(
            january,
            Prompt19CalendarMonth(
                year: 2027,
                month: 1
            )
        )
    }

    func testAccessibilityLabelPreservesEstimateLanguage() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let key = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 17
        )

        let annotation = Prompt19CalendarDayAnnotation(
            key: key,
            cycleDay: 13,
            fertileEstimated: true,
            symptomsLogged: true
        )

        let cell = Prompt19CalendarCell(
            key: key,
            dateNumber: 17,
            isInDisplayedMonth: true,
            isToday: false,
            isSelected: false,
            annotation: annotation
        )

        let label = engine.accessibilityLabel(
            for: cell
        )

        XCTAssertTrue(
            label.contains("estimated fertile window")
        )

        XCTAssertTrue(
            label.contains("symptoms logged")
        )

        XCTAssertFalse(
            label.contains("confirmed")
        )
    }

    func testMergingDoesNotEraseExistingRecordedState() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let key = Prompt19CalendarDateKey(
            year: 2026,
            month: 8,
            day: 17
        )

        let recorded = Prompt19CalendarDayAnnotation(
            key: key,
            recordedPeriod: true
        )

        let estimate = Prompt19CalendarDayAnnotation(
            key: key,
            predictedPeriod: true
        )

        let merged = engine.merging(
            estimate,
            into: recorded
        )

        XCTAssertTrue(
            merged.recordedPeriod
        )

        XCTAssertTrue(
            merged.predictedPeriod
        )

        XCTAssertEqual(
            merged.primaryState,
            .recordedPeriod
        )
    }

    func testBuildIsDeterministic() {
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let month = Prompt19CalendarMonth(
            year: 2026,
            month: 9
        )

        let today = date(
            2026,
            9,
            7
        )

        let first = engine.buildMonth(
            month: month,
            annotations: [:],
            today: today,
            selected: nil
        )

        let second = engine.buildMonth(
            month: month,
            annotations: [:],
            today: today,
            selected: nil
        )

        XCTAssertEqual(
            first,
            second
        )
    }
}
