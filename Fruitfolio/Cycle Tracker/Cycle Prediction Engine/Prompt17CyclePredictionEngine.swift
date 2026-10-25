import Foundation

public struct Prompt17CyclePredictionEngine: Sendable {
    public static let recentCycleLimit = 6
    public static let methodVersion = "prompt17.v1"

    private let calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    public func calculate(
        from input: Prompt17CyclePredictionInput
    ) -> Prompt17CyclePredictionResult {
        let asOf = calendar.startOfDay(for: input.asOfDate)
        var validationIssues: [Prompt17ValidationIssue] = []

        let normalizedCycleStarts = normalizeCycleStarts(
            input.cycleStartDates,
            asOf: asOf,
            issues: &validationIssues
        )

        let completedCycleLengths = cycleLengths(
            from: normalizedCycleStarts
        )

        let recentCycleLengths = Array(
            completedCycleLengths.suffix(Self.recentCycleLimit)
        )

        let mean = mean(of: recentCycleLengths)
        let medianCycleLength = median(of: recentCycleLengths)
        let variation = variation(of: recentCycleLengths)

        let recordedPeriodLengths = periodLengths(
            from: input.periodRecords,
            asOf: asOf,
            issues: &validationIssues
        )

        let typicalPeriodLength = self.median(of: recordedPeriodLengths)
            .map { Int($0.rounded()) }

        let currentCycleDay = normalizedCycleStarts.last.flatMap {
            inclusiveDayNumber(from: $0, through: asOf)
        }

        let sufficiency = dataSufficiency(
            completedCycleCount: completedCycleLengths.count
        )

        let confidence = confidence(
            completedCycleCount: completedCycleLengths.count,
            variation: variation
        )

        let estimatedCycleLength = medianCycleLength.map {
            max(1, Int($0.rounded()))
        }

        let halfWidth = predictionHalfWidth(
            recentCycleLengths: recentCycleLengths,
            median: medianCycleLength,
            variation: variation
        )

        let nextPeriodWindow = makeNextPeriodWindow(
            latestCycleStart: normalizedCycleStarts.last,
            estimatedCycleLength: estimatedCycleLength,
            halfWidth: halfWidth,
            confidence: confidence
        )

        let currentCycleProgress = cycleProgress(
            currentCycleDay: currentCycleDay,
            estimatedCycleLength: estimatedCycleLength
        )

        return Prompt17CyclePredictionResult(
            normalizedCycleStartDates: normalizedCycleStarts,
            completedCycleLengths: completedCycleLengths,
            recentCycleLengths: recentCycleLengths,
            meanCycleLength: mean,
            medianCycleLength: medianCycleLength,
            cycleVariation: variation,
            recordedPeriodLengths: recordedPeriodLengths,
            typicalPeriodLength: typicalPeriodLength,
            currentCycleDay: currentCycleDay,
            estimatedCycleLength: estimatedCycleLength,
            currentCycleProgress: currentCycleProgress,
            nextPeriodWindow: nextPeriodWindow,
            predictionConfidence: confidence,
            dataSufficiency: sufficiency,
            predictionRangeHalfWidthDays: halfWidth,
            historyVersion: historyVersion(
                cycleStarts: normalizedCycleStarts,
                periods: input.periodRecords
            ),
            calculatedAt: input.asOfDate,
            validationIssues: validationIssues
        )
    }

    // MARK: - Normalization

    private func normalizeCycleStarts(
        _ dates: [Date],
        asOf: Date,
        issues: inout [Prompt17ValidationIssue]
    ) -> [Date] {
        var unique = Set<Date>()

        for rawDate in dates {
            let date = calendar.startOfDay(for: rawDate)

            guard date <= asOf else {
                issues.append(.futureCycleStartIgnored(date))
                continue
            }

            unique.insert(date)
        }

        return unique.sorted()
    }

    // MARK: - Recorded history

    private func cycleLengths(
        from cycleStarts: [Date]
    ) -> [Int] {
        guard cycleStarts.count >= 2 else {
            return []
        }

        return zip(
            cycleStarts,
            cycleStarts.dropFirst()
        ).compactMap { start, nextStart in
            calendar.dateComponents(
                [.day],
                from: start,
                to: nextStart
            ).day.flatMap { days in
                days > 0 ? days : nil
            }
        }
    }

    private func periodLengths(
        from records: [Prompt17RecordedPeriod],
        asOf: Date,
        issues: inout [Prompt17ValidationIssue]
    ) -> [Int] {
        records.compactMap { record in
            let start = calendar.startOfDay(for: record.startDate)

            guard start <= asOf else {
                issues.append(.futurePeriodRecordIgnored(start))
                return nil
            }

            guard let rawEnd = record.endDate else {
                // Incomplete period records intentionally do not become definite durations.
                return nil
            }

            let end = calendar.startOfDay(for: rawEnd)

            guard end <= asOf else {
                issues.append(.futurePeriodRecordIgnored(end))
                return nil
            }

            guard end >= start else {
                issues.append(
                    .periodEndBeforeStartIgnored(
                        start: start,
                        end: end
                    )
                )
                return nil
            }

            guard let difference = calendar.dateComponents(
                [.day],
                from: start,
                to: end
            ).day else {
                return nil
            }

            return difference + 1
        }
    }

    private func inclusiveDayNumber(
        from cycleStart: Date,
        through asOf: Date
    ) -> Int? {
        guard cycleStart <= asOf else {
            return nil
        }

        guard let days = calendar.dateComponents(
            [.day],
            from: cycleStart,
            to: asOf
        ).day else {
            return nil
        }

        return days + 1
    }

    // MARK: - Statistics

    private func mean(
        of values: [Int]
    ) -> Double? {
        guard !values.isEmpty else {
            return nil
        }

        return Double(values.reduce(0, +))
            / Double(values.count)
    }

    private func median(
        of values: [Int]
    ) -> Double? {
        guard !values.isEmpty else {
            return nil
        }

        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return Double(sorted[middle - 1] + sorted[middle]) / 2.0
        }

        return Double(sorted[middle])
    }

    /// Product heuristic for prediction uncertainty, not a diagnosis or medical classification.
    ///
    /// The engine preserves every completed cycle. It uses the median as a robust center and
    /// classifies recent spread without deleting unusual cycles:
    /// - low: range <= 4 days and median absolute deviation <= 1.5 days
    /// - moderate: range <= 8 days and median absolute deviation <= 3 days
    /// - high: anything wider
    private func variation(
        of values: [Int]
    ) -> Prompt17CycleVariation? {
        guard values.count >= 2,
              let center = median(of: values) else {
            return nil
        }

        let range = (values.max() ?? 0) - (values.min() ?? 0)
        let absoluteDeviations = values.map {
            abs(Double($0) - center)
        }
        let mad = median(of: absoluteDeviations)

        if range <= 4 && mad <= 1.5 {
            return .low
        }

        if range <= 8 && mad <= 3.0 {
            return .moderate
        }

        return .high
    }

    private func median(
        of values: [Double]
    ) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count.isMultiple(of: 2) {
            return (sorted[middle - 1] + sorted[middle]) / 2.0
        }

        return sorted[middle]
    }

    // MARK: - Confidence + uncertainty

    private func dataSufficiency(
        completedCycleCount: Int
    ) -> Prompt17DataSufficiency {
        switch completedCycleCount {
        case 0:
            return .noCompletedCycles
        case 1:
            return .oneCompletedCycle
        case 2...3:
            return .someHistory
        default:
            return .establishedHistory
        }
    }

    /// Explicit deterministic confidence rules.
    ///
    /// Confidence can move down when recent history becomes more variable.
    private func confidence(
        completedCycleCount: Int,
        variation: Prompt17CycleVariation?
    ) -> Prompt17PredictionConfidence {
        switch completedCycleCount {
        case 0...1:
            return .limitedEstimate

        case 2...3:
            switch variation {
            case .high:
                return .limitedEstimate
            case .low, .moderate, .none:
                return .developingEstimate
            }

        default:
            switch variation {
            case .low:
                return .strongEstimate
            case .moderate:
                return .developingEstimate
            case .high, .none:
                return .limitedEstimate
            }
        }
    }

    /// Builds a transparent uncertainty width from the actual recent history.
    ///
    /// No unusual cycle is discarded. The farthest recent cycle from the median can widen
    /// the prediction window. Sparse history adds an additional uncertainty floor.
    private func predictionHalfWidth(
        recentCycleLengths: [Int],
        median: Double?,
        variation: Prompt17CycleVariation?
    ) -> Int? {
        guard let median,
              !recentCycleLengths.isEmpty else {
            return nil
        }

        let largestDeviation = recentCycleLengths
            .map { abs(Double($0) - median) }
            .max() ?? 0

        let observedWidth = Int(ceil(largestDeviation))

        switch recentCycleLengths.count {
        case 1:
            return max(4, observedWidth)
        case 2:
            return max(3, observedWidth + 1)
        case 3:
            return max(2, observedWidth + 1)
        default:
            switch variation {
            case .low:
                return max(1, observedWidth)
            case .moderate:
                return max(2, observedWidth)
            case .high:
                return max(4, observedWidth)
            case .none:
                return max(3, observedWidth)
            }
        }
    }

    // MARK: - Predictions

    private func makeNextPeriodWindow(
        latestCycleStart: Date?,
        estimatedCycleLength: Int?,
        halfWidth: Int?,
        confidence: Prompt17PredictionConfidence
    ) -> Prompt17DateWindow? {
        guard let latestCycleStart,
              let estimatedCycleLength,
              let halfWidth,
              let center = calendar.date(
                byAdding: .day,
                value: estimatedCycleLength,
                to: latestCycleStart
              ),
              let start = calendar.date(
                byAdding: .day,
                value: -halfWidth,
                to: center
              ),
              let end = calendar.date(
                byAdding: .day,
                value: halfWidth,
                to: center
              ) else {
            return nil
        }

        return Prompt17DateWindow(
            start: start,
            end: end,
            confidence: confidence
        )
    }

    private func cycleProgress(
        currentCycleDay: Int?,
        estimatedCycleLength: Int?
    ) -> Double? {
        guard let currentCycleDay,
              let estimatedCycleLength,
              estimatedCycleLength > 0 else {
            return nil
        }

        let zeroBasedDay = max(0, currentCycleDay - 1)
        let denominator = max(1, estimatedCycleLength - 1)

        return min(
            1,
            max(
                0,
                Double(zeroBasedDay) / Double(denominator)
            )
        )
    }

    // MARK: - Stable history version

    private func historyVersion(
        cycleStarts: [Date],
        periods: [Prompt17RecordedPeriod]
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = calendar.timeZone
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let cyclePart = cycleStarts
            .map(dateFormatter.string(from:))
            .joined(separator: "|")

        let periodPart = periods
            .map { period in
                let start = dateFormatter.string(
                    from: calendar.startOfDay(for: period.startDate)
                )
                let end = period.endDate.map {
                    dateFormatter.string(
                        from: calendar.startOfDay(for: $0)
                    )
                } ?? "incomplete"
                return "\(start)>\(end)"
            }
            .sorted()
            .joined(separator: "|")

        let payload = "method:\(Self.methodVersion);cycles:\(cyclePart);periods:\(periodPart)"
        return String(format: "%016llx", stableFNV1a64(payload))
    }

    private func stableFNV1a64(
        _ string: String
    ) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* prime
        }

        return hash
    }
}
