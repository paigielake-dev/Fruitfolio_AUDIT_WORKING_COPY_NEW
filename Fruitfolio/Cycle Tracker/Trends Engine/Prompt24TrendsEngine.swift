import Foundation

@MainActor struct Prompt24TrendsEngine: Sendable {
    static let algorithmVersion = "prompt24.v1"

    // Phase 24 uses a deliberately conservative small-N recurrence rule.
    // A supported recurring timing pattern requires:
    // - at least 3 completed eligible cycles;
    // - occurrence in at least 3 completed cycles;
    // - occurrence in at least 2/3 of eligible completed cycles;
    // - a fixed 5-day raw-cycle-day window (candidate day ±2).
    //
    // This is descriptive recurrence, not inferential statistical significance.
    static let minimumEligibleCycles = 3
    static let minimumMatchedCycles = 3
    static let supportFraction = 2.0 / 3.0
    static let windowRadiusDays = 2

    private let calendar: Calendar

    init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    func calculate(
        from input: Prompt24TrendsInput,
        asOfDate: Date = Date()
    ) -> Prompt24TrendsSnapshot {
        let starts = normalizedStarts(input.cycleStartDates, asOf: asOfDate)

        let cyclePoints = makeCycleLengthPoints(
            starts: starts,
            completedLengths: input.completedCycleLengths
        )

        let cycleValues = cyclePoints.map(\.days)
        let cycleMedian = median(cycleValues.map(Double.init))
        let cycleRange = observedRange(cycleValues)

        let periodPoints = makePeriodLengthPoints(
            records: input.periodRecords,
            asOf: asOfDate
        )
        let periodMedian = median(periodPoints.map { Double($0.days) })

        let bbt = makeBBTPoints(
            logs: input.dailyLogs,
            starts: starts,
            asOf: asOfDate
        )

        let occurrences = makeSymptomOccurrences(
            logs: input.dailyLogs,
            starts: starts,
            asOf: asOfDate
        )

        let completedCycleCount = max(0, starts.count - 1)
        var patterns: [Prompt20SymptomID: Prompt24SymptomPattern] = [:]
        for symptomID in Prompt23SymptomTaxonomy.items.map(\.symptomID) {
            patterns[symptomID] = pattern(
                for: symptomID,
                occurrences: occurrences,
                completedCycleCount: completedCycleCount
            )
        }

        return Prompt24TrendsSnapshot(
            cycleLengths: cyclePoints,
            cycleMedianDays: cycleMedian,
            cycleObservedRange: cycleRange,
            periodLengths: periodPoints,
            periodMedianDays: periodMedian,
            bbtPoints: bbt,
            displayTemperatureUnit: input.displayTemperatureUnit,
            temperatureShiftStatus: input.temperatureShiftStatus,
            symptomOccurrences: occurrences,
            symptomPatterns: patterns,
            predictionMarker: input.predictionMarker,
            calculatedAt: asOfDate,
            algorithmVersion: Self.algorithmVersion
        )
    }

    private func normalizedStarts(
        _ raw: [Date],
        asOf: Date
    ) -> [Date] {
        let today = calendar.startOfDay(for: asOf)
        return Array(
            Set(
                raw
                    .map { calendar.startOfDay(for: $0) }
                    .filter { $0 <= today }
            )
        )
        .sorted()
    }

    private func makeCycleLengthPoints(
        starts: [Date],
        completedLengths: [Int]
    ) -> [Prompt24CycleLengthPoint] {
        guard starts.count >= 2 else { return [] }

        let validPairCount = min(starts.count - 1, completedLengths.count)
        guard validPairCount > 0 else { return [] }

        return (0..<validPairCount).compactMap { index in
            let days = completedLengths[index]
            guard days > 0 else { return nil }
            return Prompt24CycleLengthPoint(
                cycleIndex: index + 1,
                startDate: starts[index],
                days: days
            )
        }
    }

    private func makePeriodLengthPoints(
        records: [Prompt17RecordedPeriod],
        asOf: Date
    ) -> [Prompt24PeriodLengthPoint] {
        let today = calendar.startOfDay(for: asOf)

        return records.compactMap { record in
            let start = calendar.startOfDay(for: record.startDate)
            guard start <= today, let rawEnd = record.endDate else {
                return nil
            }

            let end = calendar.startOfDay(for: rawEnd)
            guard end >= start, end <= today else {
                return nil
            }

            guard let delta = calendar.dateComponents(
                [.day],
                from: start,
                to: end
            ).day else {
                return nil
            }

            return Prompt24PeriodLengthPoint(
                startDate: start,
                endDate: end,
                days: delta + 1
            )
        }
        .sorted { $0.startDate < $1.startDate }
    }

    private func makeBBTPoints(
        logs: [Prompt20DailyLog],
        starts: [Date],
        asOf: Date
    ) -> [Prompt24BBTPoint] {
        let today = calendar.startOfDay(for: asOf)

        return logs.compactMap { log in
            guard !log.isDeleted,
                  let temperature = log.temperature,
                  temperature.readingType == .basalWaking,
                  let date = log.date.date(in: calendar)
            else {
                return nil
            }

            let normalizedDate = calendar.startOfDay(for: date)
            guard normalizedDate <= today else { return nil }

            return Prompt24BBTPoint(
                date: normalizedDate,
                originalValue: temperature.originalValue,
                originalUnit: temperature.originalUnit,
                canonicalCelsius: temperature.canonicalCelsius,
                cycleDay: cycleDay(for: normalizedDate, starts: starts)
            )
        }
        .sorted { $0.date < $1.date }
    }

    private func makeSymptomOccurrences(
        logs: [Prompt20DailyLog],
        starts: [Date],
        asOf: Date
    ) -> [Prompt24SymptomOccurrence] {
        let today = calendar.startOfDay(for: asOf)
        var output: [Prompt24SymptomOccurrence] = []

        for log in logs where !log.isDeleted {
            guard let symptoms = log.symptoms,
                  let rawDate = log.date.date(in: calendar)
            else {
                continue
            }

            let date = calendar.startOfDay(for: rawDate)
            guard date <= today else { continue }

            let assignment = cycleAssignment(for: date, starts: starts)

            for symptomID in symptoms.selectedIDs {
                output.append(
                    Prompt24SymptomOccurrence(
                        symptomID: symptomID,
                        date: date,
                        cycleDay: assignment?.cycleDay,
                        completedCycleIndex:
                            assignment?.isCompleted == true
                                ? assignment?.index
                                : nil
                    )
                )
            }
        }

        return output.sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            return $0.symptomID.rawValue < $1.symptomID.rawValue
        }
    }

    private struct CycleAssignment {
        let index: Int
        let cycleDay: Int
        let isCompleted: Bool
    }

    private func cycleAssignment(
        for date: Date,
        starts: [Date]
    ) -> CycleAssignment? {
        guard !starts.isEmpty else { return nil }

        for index in starts.indices.reversed() {
            let start = starts[index]
            guard date >= start else { continue }

            if index + 1 < starts.count {
                let nextStart = starts[index + 1]
                guard date < nextStart else { continue }
            }

            guard let delta = calendar.dateComponents(
                [.day],
                from: start,
                to: date
            ).day else {
                return nil
            }

            return CycleAssignment(
                index: index,
                cycleDay: delta + 1,
                isCompleted: index + 1 < starts.count
            )
        }

        return nil
    }

    private func cycleDay(
        for date: Date,
        starts: [Date]
    ) -> Int? {
        cycleAssignment(for: date, starts: starts)?.cycleDay
    }

    private func pattern(
        for symptomID: Prompt20SymptomID,
        occurrences: [Prompt24SymptomOccurrence],
        completedCycleCount: Int
    ) -> Prompt24SymptomPattern {
        guard completedCycleCount >= Self.minimumEligibleCycles else {
            return basePattern(
                symptomID: symptomID,
                status: .insufficientData,
                eligible: completedCycleCount,
                matched: 0,
                window: nil
            )
        }

        let eligibleOccurrences = occurrences.filter {
            $0.symptomID == symptomID
                && $0.completedCycleIndex != nil
                && $0.cycleDay != nil
        }

        let cyclesWithSymptom = Set(
            eligibleOccurrences.compactMap(\.completedCycleIndex)
        )

        guard !eligibleOccurrences.isEmpty else {
            return basePattern(
                symptomID: symptomID,
                status: .unsupported,
                eligible: completedCycleCount,
                matched: 0,
                window: nil
            )
        }

        var best: (matched: Int, start: Int, end: Int)? = nil

        for occurrence in eligibleOccurrences {
            guard let candidateDay = occurrence.cycleDay else { continue }
            let start = max(1, candidateDay - Self.windowRadiusDays)
            let end = candidateDay + Self.windowRadiusDays

            let matchedCycles = Set(
                eligibleOccurrences.compactMap { item -> Int? in
                    guard let day = item.cycleDay,
                          day >= start,
                          day <= end
                    else {
                        return nil
                    }
                    return item.completedCycleIndex
                }
            )

            let candidate = (
                matched: matchedCycles.count,
                start: start,
                end: end
            )

            if let current = best {
                if candidate.matched > current.matched
                    || (
                        candidate.matched == current.matched
                        && candidate.start < current.start
                    ) {
                    best = candidate
                }
            } else {
                best = candidate
            }
        }

        let matched = best?.matched ?? cyclesWithSymptom.count
        let fraction =
            completedCycleCount > 0
                ? Double(matched) / Double(completedCycleCount)
                : 0

        let status: Prompt24PatternStatus
        if matched >= Self.minimumMatchedCycles,
           fraction >= Self.supportFraction {
            status = .supported
        } else if matched >= 2 {
            status = .developing
        } else {
            status = .unsupported
        }

        return basePattern(
            symptomID: symptomID,
            status: status,
            eligible: completedCycleCount,
            matched: matched,
            window: best.map { ($0.start, $0.end) }
        )
    }

    private func basePattern(
        symptomID: Prompt20SymptomID,
        status: Prompt24PatternStatus,
        eligible: Int,
        matched: Int,
        window: (Int, Int)?
    ) -> Prompt24SymptomPattern {
        Prompt24SymptomPattern(
            symptomID: symptomID,
            status: status,
            cyclesEvaluated: eligible,
            cyclesMatched: matched,
            windowStartDay: window?.0,
            windowEndDay: window?.1,
            underlyingDataIsRecorded: true,
            patternIsCalculated: true,
            algorithmVersion: Self.algorithmVersion
        )
    }

    private func observedRange(_ values: [Int]) -> ClosedRange<Int>? {
        guard let low = values.min(), let high = values.max() else {
            return nil
        }
        return low...high
    }

    private func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2.0
        }

        return sorted[middle]
    }
}
