import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt18CycleWheelTests: XCTestCase {
    private func result(
        cycleLength: Int? = 30,
        currentDay: Int? = 13,
        typicalPeriodLength: Int? = 5,
        confidence: Prompt17PredictionConfidence = .strongEstimate,
        sufficiency: Prompt17DataSufficiency = .establishedHistory
    ) -> Prompt17CyclePredictionResult {
        Prompt17CyclePredictionResult(
            normalizedCycleStartDates: [],
            completedCycleLengths: cycleLength.map { [$0, $0, $0, $0] } ?? [],
            recentCycleLengths: cycleLength.map { [$0, $0, $0, $0] } ?? [],
            meanCycleLength: cycleLength.map(Double.init),
            medianCycleLength: cycleLength.map(Double.init),
            cycleVariation: cycleLength == nil ? nil : .low,
            recordedPeriodLengths: typicalPeriodLength.map { [$0] } ?? [],
            typicalPeriodLength: typicalPeriodLength,
            currentCycleDay: currentDay,
            estimatedCycleLength: cycleLength,
            currentCycleProgress: nil,
            nextPeriodWindow: nil,
            predictionConfidence: confidence,
            dataSufficiency: sufficiency,
            predictionRangeHalfWidthDays: cycleLength == nil ? nil : 1,
            historyVersion: "test-history",
            calculatedAt: Date(timeIntervalSince1970: 0),
            validationIssues: []
        )
    }

    func testNoCycleLengthProducesNoFabricatedPersonalizedGeometry() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: nil,
                currentDay: nil,
                typicalPeriodLength: nil,
                confidence: .limitedEstimate,
                sufficiency: .noCompletedCycles
            )
        )

        XCTAssertNil(model.representedCycleLength)
        XCTAssertTrue(model.baseSegments.isEmpty)
        XCTAssertNil(model.fertileOverlay)
        XCTAssertNil(model.currentPositionFraction)
        XCTAssertNil(model.currentRegion)
    }

    func testSegmentAngularFractionsAreProportionalToRepresentedDays() {
        let intervals = Prompt18EstimatedIntervals(
            estimatedOvulation: .init(
                startDay: 15,
                endDay: 16,
                provenance: .estimated
            ),
            estimatedFertileWindow: .init(
                startDay: 10,
                endDay: 16,
                provenance: .estimated
            )
        )

        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 30,
                currentDay: 13,
                typicalPeriodLength: 5
            ),
            estimatedIntervals: intervals
        )

        guard
            let menstruation = model.baseSegments.first(where: { $0.kind == .menstruation }),
            let follicular = model.baseSegments.first(where: { $0.kind == .follicular }),
            let ovulation = model.baseSegments.first(where: { $0.kind == .estimatedOvulation }),
            let luteal = model.baseSegments.first(where: { $0.kind == .luteal })
        else {
            XCTFail("Expected all four base cycle segments")
            return
        }

        XCTAssertEqual(menstruation.fractionLength, 5.0 / 30.0, accuracy: 0.000001)
        XCTAssertEqual(follicular.fractionLength, 9.0 / 30.0, accuracy: 0.000001)
        XCTAssertEqual(ovulation.fractionLength, 2.0 / 30.0, accuracy: 0.000001)
        XCTAssertEqual(luteal.fractionLength, 14.0 / 30.0, accuracy: 0.000001)
    }

    func testFertileWindowRemainsAnOverlayRatherThanABasePhase() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 15,
                    endDay: 16,
                    provenance: .estimated
                ),
                estimatedFertileWindow: .init(
                    startDay: 10,
                    endDay: 16,
                    provenance: .estimated
                )
            )
        )

        XCTAssertFalse(
            model.baseSegments.contains {
                $0.kind == .estimatedFertileWindow
            }
        )

        XCTAssertEqual(model.fertileOverlay?.kind, .estimatedFertileWindow)
        XCTAssertEqual(model.fertileOverlay?.interval.startDay, 10)
        XCTAssertEqual(model.fertileOverlay?.interval.endDay, 16)
    }

    func testCurrentMarkerUsesActualCurrentCycleDayAndRepresentedCycleLength() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 30,
                currentDay: 13
            ),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 15,
                    endDay: 16,
                    provenance: .estimated
                )
            )
        )

        let expected = 12.5 / 30.0

        guard let currentPositionFraction = model.currentPositionFraction else {
            XCTFail("Expected a current-position fraction")
            return
        }

        XCTAssertEqual(currentPositionFraction, expected, accuracy: 0.000001)
        XCTAssertEqual(model.currentRegion, .follicular)
    }

    func testCurrentRegionNeverBecomesFertileBecauseFertileIsNotAnEndocrinePhase() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 30,
                currentDay: 12
            ),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 15,
                    endDay: 16,
                    provenance: .estimated
                ),
                estimatedFertileWindow: .init(
                    startDay: 10,
                    endDay: 16,
                    provenance: .estimated
                )
            )
        )

        XCTAssertTrue(model.fertileOverlay?.interval.contains(day: 12) == true)
        XCTAssertEqual(model.currentRegion, .follicular)
    }

    func testMissingOvulationEstimateDoesNotInventFollicularOrLutealBoundaries() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 31,
                currentDay: 9,
                typicalPeriodLength: 5
            )
        )

        XCTAssertEqual(model.baseSegments.count, 1)
        XCTAssertEqual(model.baseSegments.first?.kind, .menstruation)
        XCTAssertEqual(model.unresolvedIntervals.count, 1)

        guard let unresolved = model.unresolvedIntervals.first else {
            XCTFail("Expected exactly one unresolved interval")
            return
        }

        XCTAssertEqual(unresolved.startDay, 6)
        XCTAssertEqual(unresolved.endDay, 31)
        XCTAssertEqual(unresolved.provenance, .calculated)
        XCTAssertNil(model.currentRegion)
    }

    func testEstimatedIntervalsAreClampedToRepresentedCycleLength() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 30,
                currentDay: 30
            ),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 29,
                    endDay: 35,
                    provenance: .estimated
                ),
                estimatedFertileWindow: .init(
                    startDay: 27,
                    endDay: 40,
                    provenance: .estimated
                )
            )
        )

        XCTAssertEqual(
            model.baseSegments.first(where: { $0.kind == .estimatedOvulation })?.interval.endDay,
            30
        )

        XCTAssertEqual(model.fertileOverlay?.interval.endDay, 30)

        guard let currentPositionFraction = model.currentPositionFraction else {
            XCTFail("Expected a current-position fraction")
            return
        }

        XCTAssertLessThan(currentPositionFraction, 1)
    }

    func testCurrentDayOutsideRepresentedCycleDoesNotFabricateMarker() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 30,
                currentDay: 34
            ),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 15,
                    endDay: 16,
                    provenance: .estimated
                )
            )
        )

        XCTAssertEqual(model.currentCycleDay, 34)
        XCTAssertNil(model.currentPositionFraction)
        XCTAssertNil(model.currentRegion)
    }

    func testHistoryVersionAndConfidenceArePreservedFromPrompt17() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 32,
                currentDay: 8,
                confidence: .developingEstimate,
                sufficiency: .someHistory
            )
        )

        XCTAssertEqual(model.historyVersion, "test-history")
        XCTAssertEqual(model.confidence, .developingEstimate)
        XCTAssertEqual(model.dataSufficiency, .someHistory)
    }

    func testFractionsRemainWithinZeroAndOne() {
        let model = Prompt18CycleWheelBuilder().build(
            prediction: result(
                cycleLength: 26,
                currentDay: 1,
                typicalPeriodLength: 7
            ),
            estimatedIntervals: .init(
                estimatedOvulation: .init(
                    startDay: 12,
                    endDay: 13,
                    provenance: .estimated
                ),
                estimatedFertileWindow: .init(
                    startDay: 7,
                    endDay: 13,
                    provenance: .estimated
                )
            )
        )

        for segment in model.baseSegments {
            XCTAssertGreaterThanOrEqual(segment.startFraction, 0)
            XCTAssertLessThanOrEqual(segment.endFraction, 1)
            XCTAssertLessThan(segment.startFraction, segment.endFraction)
        }

        guard let fertileOverlay = model.fertileOverlay else {
            XCTFail("Expected fertile-window overlay")
            return
        }

        XCTAssertGreaterThanOrEqual(fertileOverlay.startFraction, 0)
        XCTAssertLessThanOrEqual(fertileOverlay.endFraction, 1)
    }

    func testDateWindowAdapterConvertsOnlyExistingEstimatedWindows() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/New_York")!

        let cycleStart = cal.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 1,
                hour: 12
            )
        )!

        let ovulationStart = cal.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 14,
                hour: 12
            )
        )!

        let ovulationEnd = cal.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 15,
                hour: 12
            )
        )!

        let fertileStart = cal.date(
            from: DateComponents(
                year: 2026,
                month: 9,
                day: 9,
                hour: 12
            )
        )!

        let fertileEnd = ovulationEnd

        let intervals = Prompt18EstimatedIntervalAdapter(
            calendar: cal
        ).makeIntervals(
            cycleStartDate: cycleStart,
            representedCycleLength: 30,
            estimatedOvulation: Prompt17DateWindow(
                start: ovulationStart,
                end: ovulationEnd,
                confidence: .developingEstimate
            ),
            estimatedFertileWindow: Prompt17DateWindow(
                start: fertileStart,
                end: fertileEnd,
                confidence: .developingEstimate
            )
        )

        XCTAssertEqual(intervals.estimatedOvulation?.startDay, 14)
        XCTAssertEqual(intervals.estimatedOvulation?.endDay, 15)
        XCTAssertEqual(intervals.estimatedFertileWindow?.startDay, 9)
        XCTAssertEqual(intervals.estimatedFertileWindow?.endDay, 15)
    }
}
