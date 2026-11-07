import XCTest
@testable import Fruitfolio

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

    func testSelectedDisplayLocaleChangesDateWeekdayAndNumberPresentation() {
        let month = Prompt19CalendarMonth(year: 2026, month: 11)
        let key = Prompt19CalendarDateKey(year: 2026, month: 11, day: 7)
        let english = Prompt19CalendarEngine(calendar: calendar)
        let french = Prompt19CalendarEngine(calendar: calendar, displayLocale: Locale(identifier: "fr_FR"))
        let arabic = Prompt19CalendarEngine(calendar: calendar, displayLocale: Locale(identifier: "ar_EG"))
        XCTAssertEqual(english.monthTitle(month), "nov 2026")
        XCTAssertEqual(english.weekdaySymbols, ["S", "M", "T", "W", "T", "F", "S"])
        XCTAssertTrue(french.monthTitle(month).contains("nov"))
        XCTAssertTrue(french.displayDateTitle(key).contains("novembre"))
        XCTAssertNotEqual(french.weekdaySymbols, english.weekdaySymbols)
        XCTAssertTrue(arabic.monthTitle(month).contains("نوفمبر"))
        XCTAssertTrue(arabic.displayDateTitle(key).contains("نوفمبر"))
        XCTAssertEqual(arabic.weekdaySymbols.count, 7)
        XCTAssertTrue(arabic.weekdaySymbols.joined().unicodeScalars.contains { (0x0600...0x06FF).contains($0.value) })
        XCTAssertEqual(arabic.displayNumber(7), "٧")
    }

    func testDisplayLocaleCannotChangeCivilDayKeysObservationsOrEstimateCertainty() throws {
        let key = Prompt19CalendarDateKey(year: 2026, month: 11, day: 7)
        let original = Prompt19CalendarDayAnnotation(key: key, cycleDay: 12,
            predictedPeriod: true, fertileEstimated: true, ovulationEstimated: true,
            bbtRecorded: true, noteAdded: true, temperatureDisplay: "98.600 °F",
            noteText: "my **verbatim** journal 42 μg")
        let month = Prompt19CalendarMonth(year: 2026, month: 11)
        let now = date(2026, 11, 7)
        let baseline = Prompt19CalendarEngine(calendar: calendar).buildMonth(month: month,
            annotations: [key: original], today: now, selected: key)
        for code in ["fr_FR", "ar_EG", "fa_IR", "ja_JP", "th_TH"] {
            let engine = Prompt19CalendarEngine(calendar: calendar, displayLocale: Locale(identifier: code))
            let shown = engine.buildMonth(month: month, annotations: [key: original], today: now, selected: key)
            XCTAssertEqual(shown, baseline, "Locale changes display only: \(code)")
            let cell = try XCTUnwrap(shown.cells.first { $0.key == key })
            XCTAssertEqual(cell.annotation?.temperatureDisplay, original.temperatureDisplay)
            XCTAssertEqual(cell.annotation?.noteText, original.noteText)
            let copy = engine.accessibilityCopy(for: cell)
            XCTAssertTrue(copy.protectedLiterals.first?.contains(engine.displayNumber(2026)) == true, "Display must retain the existing Gregorian year: \(code)")
            XCTAssertTrue(copy.source.contains("estimated fertile window"))
            XCTAssertTrue(copy.source.contains("estimated ovulation"))
            XCTAssertFalse(copy.source.contains("my **verbatim** journal"), "AX translation receives controlled recording labels, not private journal text")
            XCTAssertTrue(copy.protectedLiterals.contains(engine.displayNumber(12)))
            let envelope = try FruitfolioScientificTranslationEnvelope(copy.source, protectedLiterals: copy.protectedLiterals)
            XCTAssertEqual(try envelope.restore(envelope.prepared), copy.source)
        }
    }

    func testTypedLogProjectionOwnsTranslatableLabelsAndLiteralTemperatureWithoutSendingNotes() throws {
        let now = date(2026, 11, 7)
        var draft = Prompt20DailyLogDraft()
        draft.selectedSymptoms = [.cramps, .headache]
        draft.symptomNote = "private symptom note **42**"
        draft.generalNote = "private journal remains verbatim"
        draft.temperatureText = "98.60"
        draft.temperatureUnit = .fahrenheit
        draft.temperatureReadingType = .basalWaking
        let log = try XCTUnwrap(Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
            date: .init(date: now, calendar: calendar), draft: draft, existing: nil, now: now))
        let projected = try XCTUnwrap(Prompt20CalendarProjection.annotations(for: [log],
            month: .init(year: 2026, month: 11), calendar: calendar).first)
        XCTAssertTrue(projected.symptomSummaryIsAuthoredUI)
        XCTAssertEqual(Set(projected.symptomSummary), ["cramps", "headache"])
        XCTAssertFalse(projected.symptomSummary.joined().contains("private symptom note"))
        XCTAssertEqual(projected.noteText, draft.generalNote)
        XCTAssertEqual(projected.temperatureDisplayProtectedLiterals.count, 1)
        let literal = try XCTUnwrap(projected.temperatureDisplayProtectedLiterals.first)
        XCTAssertTrue(literal.hasSuffix("°F"))
        let temperature = try XCTUnwrap(projected.temperatureDisplay)
        XCTAssertTrue(temperature.contains(literal))
        let envelope = try FruitfolioScientificTranslationEnvelope(temperature,
            protectedLiterals: projected.temperatureDisplayProtectedLiterals)
        XCTAssertEqual(try envelope.restore(envelope.prepared), temperature)
        let raw = Prompt19CalendarDayAnnotation(key: projected.key,
            symptomSummary: ["raw authored symptom words"], temperatureDisplay: "original recorded temperature")
        let merged = Prompt19CalendarEngine(calendar: calendar).merging(raw, into: projected)
        XCTAssertFalse(merged.symptomSummaryIsAuthoredUI, "Replacement raw strings must not inherit typed-label authority")
        XCTAssertTrue(merged.temperatureDisplayProtectedLiterals.isEmpty)
        XCTAssertEqual(merged.noteText, projected.noteText)
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
