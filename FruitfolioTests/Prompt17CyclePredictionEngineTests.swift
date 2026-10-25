import Foundation
import Testing
@testable import Fruitfolio

@Suite("Prompt 17 Cycle Prediction Engine")
struct Prompt17CyclePredictionEngineTests {
    private func calendar(
        timeZoneID: String = "America/New_York"
    ) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: timeZoneID)!
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
        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }

    @Test("First cycle start gives day 1 and no fabricated prediction")
    func firstCycleStart() {
        let cal = calendar()
        let start = date(2026, 9, 7, calendar: cal)
        let engine = Prompt17CyclePredictionEngine(calendar: cal)
        let result = engine.calculate(
            from: .init(
                cycleStartDates: [start],
                asOfDate: start
            )
        )

        #expect(result.currentCycleDay == 1)
        #expect(result.completedCycleLengths.isEmpty)
        #expect(result.nextPeriodWindow == nil)
        #expect(result.predictionConfidence == .limitedEstimate)
    }

    @Test("Multiple completed cycles are calculated start-to-start")
    func multipleCompletedCycles() {
        let cal = calendar()
        let starts = [
            date(2026, 5, 1, calendar: cal),
            date(2026, 5, 31, calendar: cal),
            date(2026, 7, 1, calendar: cal),
            date(2026, 7, 30, calendar: cal),
            date(2026, 8, 29, calendar: cal)
        ]
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: starts,
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.completedCycleLengths == [30, 31, 29, 30])
        #expect(result.meanCycleLength == 30)
        #expect(result.medianCycleLength == 30)
        #expect(result.cycleVariation == .low)
        #expect(result.predictionConfidence == .strongEstimate)
    }

    @Test("Current cycle day is one-based")
    func currentCycleDayOneBased() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [date(2026, 9, 3, calendar: cal)],
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.currentCycleDay == 5)
    }

    @Test("A new cycle start resets current cycle day")
    func transitionToNextCycle() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [
                    date(2026, 8, 8, calendar: cal),
                    date(2026, 9, 7, calendar: cal)
                ],
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.completedCycleLengths == [30])
        #expect(result.currentCycleDay == 1)
    }

    @Test("Identical cycles produce a strong estimate with a narrow range")
    func identicalCycleLengths() {
        let cal = calendar()
        let starts = [0, 30, 60, 90, 120].compactMap {
            cal.date(
                byAdding: .day,
                value: $0,
                to: date(2026, 1, 1, calendar: cal)
            )
        }
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: starts,
                asOfDate: starts.last!
            )
        )

        #expect(result.completedCycleLengths == [30, 30, 30, 30])
        #expect(result.cycleVariation == .low)
        #expect(result.predictionConfidence == .strongEstimate)
        #expect(result.predictionRangeHalfWidthDays == 1)
    }

    @Test("Mild variation remains visible without fake precision")
    func mildlyVaryingCycles() {
        let cal = calendar()
        let lengths = [28, 32, 30, 31]
        var starts = [date(2026, 1, 1, calendar: cal)]
        for length in lengths {
            starts.append(cal.date(byAdding: .day, value: length, to: starts.last!)!)
        }
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: starts.last!)
        )

        #expect(result.completedCycleLengths == lengths)
        #expect(result.cycleVariation == .low || result.cycleVariation == .moderate)
        #expect(result.nextPeriodWindow != nil)
    }

    @Test("Highly varying cycles lower confidence and widen the window")
    func highlyVaryingCycles() {
        let cal = calendar()
        let lengths = [24, 37, 26, 41]
        var starts = [date(2026, 1, 1, calendar: cal)]
        for length in lengths {
            starts.append(cal.date(byAdding: .day, value: length, to: starts.last!)!)
        }
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: starts.last!)
        )

        #expect(result.completedCycleLengths == lengths)
        #expect(result.cycleVariation == .high)
        #expect(result.predictionConfidence == .limitedEstimate)
        #expect((result.predictionRangeHalfWidthDays ?? 0) >= 4)
        #expect(result.highVariationMessage == "your recent cycles vary a bit, so this window is wider!")
    }

    @Test("An outlier is preserved rather than silently deleted")
    func outlierPreserved() {
        let cal = calendar()
        let lengths = [30, 30, 42, 30]
        var starts = [date(2026, 1, 1, calendar: cal)]
        for length in lengths {
            starts.append(cal.date(byAdding: .day, value: length, to: starts.last!)!)
        }
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: starts.last!)
        )

        #expect(result.completedCycleLengths.contains(42))
        #expect(result.completedCycleLengths.count == 4)
        #expect(result.cycleVariation == .high)
    }

    @Test("Incomplete period records do not become invented period lengths")
    func missingPeriodEnd() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [date(2026, 9, 1, calendar: cal)],
                periodRecords: [
                    .init(
                        startDate: date(2026, 9, 1, calendar: cal),
                        endDate: nil
                    )
                ],
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.recordedPeriodLengths.isEmpty)
        #expect(result.typicalPeriodLength == nil)
    }

    @Test("Complete recorded period duration is inclusive")
    func completePeriodLength() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [date(2026, 9, 1, calendar: cal)],
                periodRecords: [
                    .init(
                        startDate: date(2026, 9, 1, calendar: cal),
                        endDate: date(2026, 9, 5, calendar: cal)
                    )
                ],
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.recordedPeriodLengths == [5])
        #expect(result.typicalPeriodLength == 5)
    }

    @Test("Missing history stays missing")
    func missingHistoricalCycles() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [],
                asOfDate: date(2026, 9, 7, calendar: cal)
            )
        )

        #expect(result.currentCycleDay == nil)
        #expect(result.medianCycleLength == nil)
        #expect(result.nextPeriodWindow == nil)
        #expect(result.dataSufficiency == .noCompletedCycles)
    }

    @Test("Editing historical data recalculates every derived result")
    func editedHistoricalCycleStart() {
        let cal = calendar()
        let engine = Prompt17CyclePredictionEngine(calendar: cal)
        let original = engine.calculate(
            from: .init(
                cycleStartDates: [
                    date(2026, 6, 1, calendar: cal),
                    date(2026, 7, 1, calendar: cal),
                    date(2026, 7, 31, calendar: cal)
                ],
                asOfDate: date(2026, 8, 5, calendar: cal)
            )
        )
        let edited = engine.calculate(
            from: .init(
                cycleStartDates: [
                    date(2026, 6, 1, calendar: cal),
                    date(2026, 7, 2, calendar: cal),
                    date(2026, 7, 31, calendar: cal)
                ],
                asOfDate: date(2026, 8, 5, calendar: cal)
            )
        )

        #expect(original.completedCycleLengths != edited.completedCycleLengths)
        #expect(original.historyVersion != edited.historyVersion)
    }

    @Test("Deleting a cycle start recalculates history")
    func deletedCycleStart() {
        let cal = calendar()
        let engine = Prompt17CyclePredictionEngine(calendar: cal)
        let full = engine.calculate(
            from: .init(
                cycleStartDates: [
                    date(2026, 5, 1, calendar: cal),
                    date(2026, 5, 31, calendar: cal),
                    date(2026, 6, 30, calendar: cal)
                ],
                asOfDate: date(2026, 7, 4, calendar: cal)
            )
        )
        let deleted = engine.calculate(
            from: .init(
                cycleStartDates: [
                    date(2026, 5, 1, calendar: cal),
                    date(2026, 6, 30, calendar: cal)
                ],
                asOfDate: date(2026, 7, 4, calendar: cal)
            )
        )

        #expect(full.completedCycleLengths == [30, 30])
        #expect(deleted.completedCycleLengths == [60])
        #expect(full.historyVersion != deleted.historyVersion)
    }

    @Test("Prediction range is centered on median cycle length")
    func predictionRangeGeneration() {
        let cal = calendar()
        let starts = [
            date(2026, 5, 1, calendar: cal),
            date(2026, 5, 31, calendar: cal),
            date(2026, 6, 30, calendar: cal),
            date(2026, 7, 30, calendar: cal),
            date(2026, 8, 29, calendar: cal)
        ]
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: date(2026, 9, 7, calendar: cal))
        )

        let normalizedLatest = cal.startOfDay(for: starts.last!)
        let center = cal.date(byAdding: .day, value: 30, to: normalizedLatest)!
        #expect(result.nextPeriodWindow != nil)
        #expect(result.nextPeriodWindow!.start == cal.date(byAdding: .day, value: -1, to: center)!)
        #expect(result.nextPeriodWindow!.end == cal.date(byAdding: .day, value: 1, to: center)!)
    }

    @Test("Confidence can strengthen with sufficient consistent history")
    func confidenceTransitions() {
        let cal = calendar()
        let base = date(2026, 1, 1, calendar: cal)
        let engine = Prompt17CyclePredictionEngine(calendar: cal)

        let oneCompleted = engine.calculate(
            from: .init(
                cycleStartDates: [base, cal.date(byAdding: .day, value: 30, to: base)!],
                asOfDate: cal.date(byAdding: .day, value: 30, to: base)!
            )
        )
        #expect(oneCompleted.predictionConfidence == .limitedEstimate)

        var starts = [base]
        for _ in 0..<4 {
            starts.append(cal.date(byAdding: .day, value: 30, to: starts.last!)!)
        }
        let established = engine.calculate(
            from: .init(cycleStartDates: starts, asOfDate: starts.last!)
        )
        #expect(established.predictionConfidence == .strongEstimate)
    }

    @Test("DST transition uses local calendar days rather than elapsed hours")
    func daylightSavingTransition() {
        let cal = calendar(timeZoneID: "America/New_York")
        let start = date(2026, 3, 7, hour: 23, calendar: cal)
        let asOf = date(2026, 3, 9, hour: 1, calendar: cal)
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: [start], asOfDate: asOf)
        )

        #expect(result.currentCycleDay == 3)
    }

    @Test("Timezone-local dates stay deterministic")
    func timezoneBoundary() {
        let cal = calendar(timeZoneID: "America/Los_Angeles")
        let start = date(2026, 9, 1, hour: 0, calendar: cal)
        let asOf = date(2026, 9, 2, hour: 23, calendar: cal)
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: [start], asOfDate: asOf)
        )

        #expect(result.currentCycleDay == 2)
    }

    @Test("Month and year transitions calculate correctly")
    func monthYearTransition() {
        let cal = calendar()
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(
                cycleStartDates: [date(2025, 12, 31, calendar: cal)],
                asOfDate: date(2026, 1, 2, calendar: cal)
            )
        )

        #expect(result.currentCycleDay == 3)
    }

    @Test("Leap day participates in calendar-safe cycle length")
    func leapYearBoundary() {
        let cal = calendar()
        let starts = [
            date(2024, 2, 1, calendar: cal),
            date(2024, 3, 1, calendar: cal)
        ]
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: starts.last!)
        )

        #expect(result.completedCycleLengths == [29])
    }

    @Test("AI context carries provenance and cannot alter engine state")
    func aiContextProvenance() {
        let cal = calendar()
        let starts = [
            date(2026, 5, 1, calendar: cal),
            date(2026, 5, 31, calendar: cal),
            date(2026, 6, 30, calendar: cal),
            date(2026, 7, 30, calendar: cal),
            date(2026, 8, 29, calendar: cal)
        ]
        let result = Prompt17CyclePredictionEngine(calendar: cal).calculate(
            from: .init(cycleStartDates: starts, asOfDate: date(2026, 9, 7, calendar: cal))
        )
        let context = Prompt17CycleAIContext(result: result)

        #expect(context.currentCycleDay?.provenance == .calculated)
        #expect(context.nextPeriodWindow?.provenance == .estimated)
        #expect(context.confidence.value == result.predictionConfidence)
    }
}
