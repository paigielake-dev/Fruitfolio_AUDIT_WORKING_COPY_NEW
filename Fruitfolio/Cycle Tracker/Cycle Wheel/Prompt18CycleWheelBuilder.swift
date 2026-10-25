import Foundation

public struct Prompt18CycleWheelBuilder: Sendable {
    public init() {}

    /// Builds render geometry only from deterministic Prompt 17 output plus any
    /// separately validated estimated cycle-day intervals supplied by CycleDomain.
    ///
    /// This builder intentionally does NOT invent an ovulation day, fertile window,
    /// luteal duration, or population-average cycle. If the upstream model has not
    /// produced those estimates, Prompt 18 leaves that portion visually unresolved.
    public func build(
        prediction: Prompt17CyclePredictionResult,
        estimatedIntervals: Prompt18EstimatedIntervals = .none
    ) -> Prompt18WheelModel {
        guard let rawCycleLength = prediction.estimatedCycleLength,
              rawCycleLength > 0 else {
            return Prompt18WheelModel(
                representedCycleLength: nil,
                currentCycleDay: prediction.currentCycleDay,
                baseSegments: [],
                fertileOverlay: nil,
                unresolvedIntervals: [],
                currentRegion: nil,
                currentPositionFraction: nil,
                confidence: prediction.predictionConfidence,
                dataSufficiency: prediction.dataSufficiency,
                historyVersion: prediction.historyVersion
            )
        }

        let cycleLength = rawCycleLength
        let actualCurrentDay = prediction.currentCycleDay
        let currentDayWithinRepresentedCycle = actualCurrentDay.flatMap {
            (1...cycleLength).contains($0) ? $0 : nil
        }

        let periodEnd = prediction.typicalPeriodLength.map {
            min(cycleLength, max(1, $0))
        }

        let ovulation = normalized(
            estimatedIntervals.estimatedOvulation,
            within: cycleLength,
            requiredProvenance: .estimated
        )

        let fertile = normalized(
            estimatedIntervals.estimatedFertileWindow,
            within: cycleLength,
            requiredProvenance: .estimated
        )

        var segments: [Prompt18WheelSegment] = []
        var occupied = Set<Int>()

        if let periodEnd {
            let interval = Prompt18CycleDayInterval(
                startDay: 1,
                endDay: periodEnd,
                provenance: .calculated
            )
            segments.append(segment(.menstruation, interval, cycleLength))
            occupied.formUnion(interval.startDay...interval.endDay)
        }

        if let ovulation {
            let follicularStart = (periodEnd ?? 0) + 1
            let follicularEnd = ovulation.startDay - 1

            if follicularStart <= follicularEnd {
                let interval = Prompt18CycleDayInterval(
                    startDay: follicularStart,
                    endDay: follicularEnd,
                    provenance: .estimated
                )
                segments.append(segment(.follicular, interval, cycleLength))
                occupied.formUnion(interval.startDay...interval.endDay)
            }

            segments.append(segment(.estimatedOvulation, ovulation, cycleLength))
            occupied.formUnion(ovulation.startDay...ovulation.endDay)

            let lutealStart = ovulation.endDay + 1
            if lutealStart <= cycleLength {
                let interval = Prompt18CycleDayInterval(
                    startDay: lutealStart,
                    endDay: cycleLength,
                    provenance: .estimated
                )
                segments.append(segment(.luteal, interval, cycleLength))
                occupied.formUnion(interval.startDay...interval.endDay)
            }
        }

        segments.sort { $0.interval.startDay < $1.interval.startDay }

        let unresolved = unresolvedIntervals(
            cycleLength: cycleLength,
            occupiedDays: occupied
        )

        let overlay = fertile.map {
            segment(.estimatedFertileWindow, $0, cycleLength)
        }

        let currentRegion = currentDayWithinRepresentedCycle.flatMap { day in
            if let overlay, overlay.interval.contains(day: day) {
                // Fertile remains an overlay, not the underlying endocrine context.
                // The current biological region is therefore determined from baseSegments.
                _ = overlay
            }

            return segments.first { $0.interval.contains(day: day) }?.kind
        }

        let position = currentDayWithinRepresentedCycle.map {
            currentPositionFraction(day: $0, cycleLength: cycleLength)
        }

        return Prompt18WheelModel(
            representedCycleLength: cycleLength,
            currentCycleDay: actualCurrentDay,
            baseSegments: segments,
            fertileOverlay: overlay,
            unresolvedIntervals: unresolved,
            currentRegion: currentRegion,
            currentPositionFraction: position,
            confidence: prediction.predictionConfidence,
            dataSufficiency: prediction.dataSufficiency,
            historyVersion: prediction.historyVersion
        )
    }

    private func normalized(
        _ interval: Prompt18CycleDayInterval?,
        within cycleLength: Int,
        requiredProvenance: Prompt17BiologicalDataProvenance
    ) -> Prompt18CycleDayInterval? {
        guard let interval,
              interval.provenance == requiredProvenance else {
            return nil
        }

        let start = min(cycleLength, max(1, interval.startDay))
        let end = min(cycleLength, max(1, interval.endDay))

        guard start <= end else {
            return nil
        }

        return Prompt18CycleDayInterval(
            startDay: start,
            endDay: end,
            provenance: requiredProvenance
        )
    }

    private func segment(
        _ kind: Prompt18WheelRegionKind,
        _ interval: Prompt18CycleDayInterval,
        _ cycleLength: Int
    ) -> Prompt18WheelSegment {
        let startFraction = Double(interval.startDay - 1) / Double(cycleLength)
        let endFraction = Double(interval.endDay) / Double(cycleLength)

        return Prompt18WheelSegment(
            kind: kind,
            interval: interval,
            startFraction: startFraction,
            endFraction: endFraction
        )
    }

    private func currentPositionFraction(
        day: Int,
        cycleLength: Int
    ) -> Double {
        // Place the marker at the center of the represented calendar day.
        let fraction = (Double(day) - 0.5) / Double(cycleLength)
        return min(1, max(0, fraction))
    }

    private func unresolvedIntervals(
        cycleLength: Int,
        occupiedDays: Set<Int>
    ) -> [Prompt18CycleDayInterval] {
        var result: [Prompt18CycleDayInterval] = []
        var runStart: Int?

        for day in 1...cycleLength {
            if occupiedDays.contains(day) {
                if let start = runStart {
                    result.append(
                        Prompt18CycleDayInterval(
                            startDay: start,
                            endDay: day - 1,
                            provenance: .calculated
                        )
                    )
                    runStart = nil
                }
            } else if runStart == nil {
                runStart = day
            }
        }

        if let start = runStart {
            result.append(
                Prompt18CycleDayInterval(
                    startDay: start,
                    endDay: cycleLength,
                    provenance: .calculated
                )
            )
        }

        return result
    }
}

