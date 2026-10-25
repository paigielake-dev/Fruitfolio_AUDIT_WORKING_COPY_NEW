import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt24TrendsCoreTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        calendar.date(
            from: DateComponents(
                calendar: calendar,
                timeZone: calendar.timeZone,
                year: y,
                month: m,
                day: d,
                hour: 12
            )
        )!
    }

    func testCycleLengthsRemainActualCompletedHistoryOnly() {
        let starts = [
            date(2026, 1, 1),
            date(2026, 1, 30),
            date(2026, 2, 28),
            date(2026, 3, 30)
        ]

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: starts,
                completedCycleLengths: [29, 29, 30],
                periodRecords: [],
                dailyLogs: [],
                predictionMarker: Prompt24PredictionMarker(
                    estimatedCycleLength: 31,
                    confidence: .developingEstimate
                )
            ),
            asOfDate: date(2026, 4, 5)
        )

        XCTAssertEqual(snapshot.cycleLengths.map(\.days), [29, 29, 30])
        XCTAssertEqual(snapshot.cycleMedianDays, 29)
        XCTAssertEqual(snapshot.cycleObservedRange, 29...30)
        XCTAssertEqual(snapshot.predictionMarker?.estimatedCycleLength, 31)
    }

    func testPredictionNeverContaminatesHistoricalMedian() {
        let starts = [
            date(2026, 1, 1),
            date(2026, 1, 29),
            date(2026, 2, 27)
        ]

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: starts,
                completedCycleLengths: [28, 29],
                periodRecords: [],
                dailyLogs: [],
                predictionMarker: Prompt24PredictionMarker(
                    estimatedCycleLength: 60,
                    confidence: .limitedEstimate
                )
            ),
            asOfDate: date(2026, 3, 2)
        )

        XCTAssertEqual(snapshot.cycleMedianDays, 28.5)
    }

    func testIncompletePeriodNeverBecomesDefinitiveDuration() {
        let complete = Prompt17RecordedPeriod(
            startDate: date(2026, 1, 1),
            endDate: date(2026, 1, 5)
        )
        let incomplete = Prompt17RecordedPeriod(
            startDate: date(2026, 2, 1),
            endDate: nil
        )

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: [],
                completedCycleLengths: [],
                periodRecords: [complete, incomplete],
                dailyLogs: [],
                predictionMarker: nil
            ),
            asOfDate: date(2026, 3, 1)
        )

        XCTAssertEqual(snapshot.periodLengths.map(\.days), [5])
    }

    func testBBTUsesOnlyBasalWakingMeasurements() {
        let owner = Prompt20DailyLogOwnerID(rawValue: "test")
        let basal = Prompt20DailyLog(
            ownerID: owner,
            date: Prompt20LocalDay(year: 2026, month: 1, day: 5),
            temperature: Prompt20TemperatureObservation(
                originalValue: 97.8,
                originalUnit: .fahrenheit,
                readingType: .basalWaking
            )
        )
        let general = Prompt20DailyLog(
            ownerID: owner,
            date: Prompt20LocalDay(year: 2026, month: 1, day: 6),
            temperature: Prompt20TemperatureObservation(
                originalValue: 98.4,
                originalUnit: .fahrenheit,
                readingType: .general
            )
        )

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: [date(2026, 1, 1)],
                completedCycleLengths: [],
                periodRecords: [],
                dailyLogs: [basal, general],
                predictionMarker: nil
            ),
            asOfDate: date(2026, 1, 10)
        )

        XCTAssertEqual(snapshot.bbtPoints.count, 1)
        XCTAssertEqual(snapshot.bbtPoints.first?.cycleDay, 5)
    }

    func testBinarySymptomsStayBinaryAndUsePhase23Taxonomy() {
        XCTAssertEqual(
            Set(Prompt23SymptomTaxonomy.items.map(\.symptomID)),
            Set(Prompt20SymptomID.allCases)
        )
    }

    func testSupportedPatternRequiresThreeCyclesAndTwoThirds() {
        let owner = Prompt20DailyLogOwnerID(rawValue: "test")
        let starts = [
            date(2026, 1, 1),
            date(2026, 1, 29),
            date(2026, 2, 26),
            date(2026, 3, 26)
        ]

        let logs = [
            (2026, 1, 24),
            (2026, 2, 21),
            (2026, 3, 20)
        ].map { y, m, d in
            Prompt20DailyLog(
                ownerID: owner,
                date: Prompt20LocalDay(year: y, month: m, day: d),
                symptoms: Prompt20SymptomObservation(
                    selectedIDs: [.cramps]
                )
            )
        }

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: starts,
                completedCycleLengths: [28, 28, 28],
                periodRecords: [],
                dailyLogs: logs,
                predictionMarker: nil
            ),
            asOfDate: date(2026, 3, 27)
        )

        let pattern = snapshot.pattern(for: .cramps)
        XCTAssertEqual(pattern.status, .supported)
        XCTAssertEqual(pattern.cyclesEvaluated, 3)
        XCTAssertEqual(pattern.cyclesMatched, 3)
    }

    func testTwoCyclesCannotBecomeSupportedPattern() {
        let owner = Prompt20DailyLogOwnerID(rawValue: "test")
        let starts = [
            date(2026, 1, 1),
            date(2026, 1, 29),
            date(2026, 2, 26)
        ]

        let logs = [
            Prompt20DailyLog(
                ownerID: owner,
                date: Prompt20LocalDay(year: 2026, month: 1, day: 24),
                symptoms: Prompt20SymptomObservation(
                    selectedIDs: [.cramps]
                )
            ),
            Prompt20DailyLog(
                ownerID: owner,
                date: Prompt20LocalDay(year: 2026, month: 2, day: 21),
                symptoms: Prompt20SymptomObservation(
                    selectedIDs: [.cramps]
                )
            )
        ]

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: starts,
                completedCycleLengths: [28, 28],
                periodRecords: [],
                dailyLogs: logs,
                predictionMarker: nil
            ),
            asOfDate: date(2026, 2, 27)
        )

        XCTAssertEqual(
            snapshot.pattern(for: .cramps).status,
            .insufficientData
        )
    }

    func testCurrentIncompleteCycleDoesNotEnterPatternEligibility() {
        let owner = Prompt20DailyLogOwnerID(rawValue: "test")
        let starts = [
            date(2026, 1, 1),
            date(2026, 1, 29),
            date(2026, 2, 26),
            date(2026, 3, 26)
        ]

        let currentLog = Prompt20DailyLog(
            ownerID: owner,
            date: Prompt20LocalDay(year: 2026, month: 3, day: 28),
            symptoms: Prompt20SymptomObservation(
                selectedIDs: [.headache]
            )
        )

        let snapshot = Prompt24TrendsEngine(calendar: calendar).calculate(
            from: Prompt24TrendsInput(
                cycleStartDates: starts,
                completedCycleLengths: [28, 28, 28],
                periodRecords: [],
                dailyLogs: [currentLog],
                predictionMarker: nil
            ),
            asOfDate: date(2026, 3, 30)
        )

        XCTAssertEqual(snapshot.occurrences(for: .headache).count, 1)
        XCTAssertNil(
            snapshot.occurrences(for: .headache).first?.completedCycleIndex
        )
        XCTAssertEqual(
            snapshot.pattern(for: .headache).cyclesMatched,
            0
        )
    }
}
