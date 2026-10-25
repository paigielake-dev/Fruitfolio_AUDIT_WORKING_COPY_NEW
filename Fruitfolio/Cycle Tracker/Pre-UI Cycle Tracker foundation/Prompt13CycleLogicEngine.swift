import Foundation

nonisolated struct Prompt13CycleLogicEngine: Sendable {
    static let predictionMethodVersion =
        "prompt13.period.v1"

    static let insightMethodVersion =
        "prompt13.insight.v1"

    /// Prompt 13 deliberately provides only a conservative next-period baseline.
    /// Fertile-window and ovulation predictions remain unsupported here rather than inventing Day-14 logic.
    func rebuildDerivedState(
        from archive: Prompt13CycleArchive,
        currentDate: Prompt13LocalDate,
        generatedAt: Date = Date()
    ) throws -> Prompt13DerivedState {
        let activeStarts =
            archive.cycleStarts
                .filter {
                    !$0.metadata.isDeleted
                }
                .sorted { lhs, rhs in
                    if lhs.date != rhs.date {
                        return lhs.date < rhs.date
                    }

                    return
                        lhs.id.uuidString <
                        rhs.id.uuidString
                }

        let duplicateDates =
            duplicateCycleStartDates(
                in: activeStarts
            )

        let needsReviewIDs =
            activeStarts
                .filter {
                    duplicateDates
                        .contains(
                            $0.date
                        )
                }
                .map(\.id)

        let cycles = try makeCycles(
            from: activeStarts,
            duplicateDates: duplicateDates,
            generatedAt: generatedAt
        )

        let stats =
            cycleStatistics(
                from: cycles
            )

        let currentCycle =
            cycle(
                containing: currentDate,
                in: cycles
            )

        let currentCycleDay: Int?

        if let currentCycle {
            currentCycleDay =
                try currentCycle
                    .startDate
                    .days(
                        to: currentDate
                    ) + 1
        } else {
            currentCycleDay = nil
        }

        let predictions =
            try nextPeriodPredictions(
                cycles: cycles,
                statistics: stats,
                generatedAt: generatedAt
            )

        let insights =
            makePatternInsights(
                archive: archive,
                cycles: cycles,
                statistics: stats,
                generatedAt: generatedAt
            )

        return Prompt13DerivedState(
            generatedAt: generatedAt,
            cycles: cycles,
            statistics: stats,
            currentCycleDay: currentCycleDay,
            currentCycleID:
                currentCycle?.id,
            currentDate: currentDate,
            activePredictions: predictions,
            patternInsights: insights,
            needsReviewCycleStartIDs:
                needsReviewIDs
        )
    }

    func makeCycles(
        from activeStarts: [CycleStart],
        duplicateDates: Set<Prompt13LocalDate> = [],
        generatedAt: Date = Date()
    ) throws -> [Cycle] {
        guard !activeStarts.isEmpty else {
            return []
        }

        var result: [Cycle] = []

        result.reserveCapacity(
            activeStarts.count
        )

        for index in activeStarts.indices {
            let start =
                activeStarts[index]

            let next =
                index + 1 < activeStarts.count
                ? activeStarts[index + 1]
                : nil

            if duplicateDates.contains(
                start.date
            ) {
                result.append(
                    Cycle(
                        id:
                            deterministicCycleID(
                                startID: start.id
                            ),
                        startID:
                            start.id,
                        nextStartID:
                            next?.id,
                        startDate:
                            start.date,
                        endDate:
                            nil,
                        observedLength:
                            nil,
                        status:
                            .needsReview,
                        generatedAt:
                            generatedAt
                    )
                )

                continue
            }

            if let next,
               duplicateDates.contains(
                    next.date
               ) {
                result.append(
                    Cycle(
                        id:
                            deterministicCycleID(
                                startID: start.id
                            ),
                        startID:
                            start.id,
                        nextStartID:
                            next.id,
                        startDate:
                            start.date,
                        endDate:
                            nil,
                        observedLength:
                            nil,
                        status:
                            .needsReview,
                        generatedAt:
                            generatedAt
                    )
                )

                continue
            }

            if let next {
                let length =
                    try start.date.days(
                        to: next.date
                    )

                guard length > 0 else {
                    result.append(
                        Cycle(
                            id:
                                deterministicCycleID(
                                    startID: start.id
                                ),
                            startID:
                                start.id,
                            nextStartID:
                                next.id,
                            startDate:
                                start.date,
                            endDate:
                                nil,
                            observedLength:
                                nil,
                            status:
                                .needsReview,
                            generatedAt:
                                generatedAt
                        )
                    )

                    continue
                }

                let endDate =
                    try next.date.addingDays(
                        -1
                    )

                result.append(
                    Cycle(
                        id:
                            deterministicCycleID(
                                startID: start.id
                            ),
                        startID:
                            start.id,
                        nextStartID:
                            next.id,
                        startDate:
                            start.date,
                        endDate:
                            endDate,
                        observedLength:
                            length,
                        status:
                            .complete,
                        generatedAt:
                            generatedAt
                    )
                )
            } else {
                result.append(
                    Cycle(
                        id:
                            deterministicCycleID(
                                startID: start.id
                            ),
                        startID:
                            start.id,
                        nextStartID:
                            nil,
                        startDate:
                            start.date,
                        endDate:
                            nil,
                        observedLength:
                            nil,
                        status:
                            .open,
                        generatedAt:
                            generatedAt
                    )
                )
            }
        }

        return result
    }

    func cycleDay(
        on selectedDate: Prompt13LocalDate,
        from archive: Prompt13CycleArchive
    ) throws -> Int? {
        let state =
            try rebuildDerivedState(
                from: archive,
                currentDate: selectedDate
            )

        return state.currentCycleDay
    }

    func cycleStatistics(
        from cycles: [Cycle]
    ) -> Prompt13CycleStatistics {
        let lengths =
            cycles.compactMap {
                cycle -> Int? in

                guard
                    cycle.status == .complete
                else {
                    return nil
                }

                return cycle.observedLength
            }

        guard !lengths.isEmpty else {
            return Prompt13CycleStatistics(
                completedCycleLengths: [],
                mean: nil,
                median: nil,
                medianAbsoluteDeviation: nil,
                minimum: nil,
                maximum: nil,
                variation: .insufficientData
            )
        }

        let mean =
            Double(
                lengths.reduce(
                    0,
                    +
                )
            ) /
            Double(
                lengths.count
            )

        let medianValue =
            median(
                lengths.map(
                    Double.init
                )
            )

        let deviations =
            lengths.map {
                abs(
                    Double($0) -
                    medianValue
                )
            }

        let mad =
            median(
                deviations
            )

        let variation:
            Prompt13VariationLevel

        if lengths.count < 2 {
            variation =
                .insufficientData
        } else if mad <= 2.0 {
            variation =
                .low
        } else if mad <= 5.0 {
            variation =
                .moderate
        } else {
            variation =
                .high
        }

        return Prompt13CycleStatistics(
            completedCycleLengths:
                lengths,
            mean:
                mean,
            median:
                medianValue,
            medianAbsoluteDeviation:
                mad,
            minimum:
                lengths.min(),
            maximum:
                lengths.max(),
            variation:
                variation
        )
    }

    func predictionConfidence(
        completedCycleCount: Int,
        variation: Prompt13VariationLevel
    ) -> Prompt13CycleConfidence {
        switch (
            completedCycleCount,
            variation
        ) {
        case let (
            count,
            .low
        ) where count >= 4:
            return .strong

        case let (
            count,
            .low
        ) where count >= 2:
            return .developing

        case let (
            count,
            .moderate
        ) where count >= 3:
            return .developing

        default:
            return .limited
        }
    }

    func duplicateCycleStartDates(
        in starts: [CycleStart]
    ) -> Set<Prompt13LocalDate> {
        var counts:
            [Prompt13LocalDate: Int] = [:]

        for start in starts
        where !start.metadata.isDeleted {
            counts[
                start.date,
                default: 0
            ] += 1
        }

        return Set(
            counts.compactMap {
                $0.value > 1
                ? $0.key
                : nil
            }
        )
    }

    func activeCycleStart(
        for date: Prompt13LocalDate,
        in archive: Prompt13CycleArchive
    ) -> CycleStart? {
        archive
            .cycleStarts
            .filter {
                !$0.metadata.isDeleted &&
                $0.date <= date
            }
            .max {
                $0.date < $1.date
            }
    }

    // MARK: - Period duration

    /// Returns only the number of explicitly recorded non-none bleeding days connected to a cycle.
    /// `isComplete` remains false unless the caller has explicit end-confirmation logic in a later phase.
    func recordedBleedingSummary(
        cycleID: UUID,
        archive: Prompt13CycleArchive
    ) -> (
        recordedBleedingDays: Int,
        isComplete: Bool
    ) {
        let days =
            Set(
                archive
                    .bleedingObservations
                    .compactMap {
                        observation
                            -> Prompt13LocalDate?
                        in

                        guard
                            !observation
                                .metadata
                                .isDeleted,
                            observation
                                .cycleID ==
                                cycleID,
                            observation
                                .flowLevel !=
                                .none
                        else {
                            return nil
                        }

                        return observation.date
                    }
            )

        return (
            days.count,
            false
        )
    }

    // MARK: - Prediction baseline

    private func nextPeriodPredictions(
        cycles: [Cycle],
        statistics: Prompt13CycleStatistics,
        generatedAt: Date
    ) throws -> [PredictionSnapshot] {
        let completed =
            cycles.filter {
                $0.status == .complete &&
                $0.observedLength != nil
            }

        guard
            completed.count >= 2,
            let openCycle =
                cycles.last(
                    where: {
                        $0.status == .open
                    }
                ),
            let medianValue =
                statistics.median
        else {
            return []
        }

        let recentCompleted =
            Array(
                completed.suffix(6)
            )

        let recentLengths =
            recentCompleted
                .compactMap(
                    \.observedLength
                )

        guard !recentLengths.isEmpty else {
            return []
        }

        let recentMedian =
            median(
                recentLengths.map(
                    Double.init
                )
            )

        let predictedLength =
            max(
                1,
                Int(
                    recentMedian
                        .rounded()
                )
            )

        let confidence =
            predictionConfidence(
                completedCycleCount:
                    recentCompleted.count,
                variation:
                    statistics.variation
            )

        let halfWidth: Int

        switch confidence {
        case .strong:
            halfWidth = 1

        case .developing:
            halfWidth = 3

        case .limited:
            let observedRange =
                (
                    recentLengths.max() ??
                    predictedLength
                ) -
                (
                    recentLengths.min() ??
                    predictedLength
                )

            halfWidth =
                max(
                    5,
                    Int(
                        ceil(
                            Double(
                                observedRange
                            ) /
                            2.0
                        )
                    )
                )
        }

        let center =
            try openCycle
                .startDate
                .addingDays(
                    predictedLength
                )

        let lower =
            try center.addingDays(
                -halfWidth
            )

        let upper =
            try center.addingDays(
                halfWidth
            )

        let cycleIDs =
            recentCompleted.map(
                \.id
            ) +
            [openCycle.id]

        let predictionFingerprint = [
            openCycle.startDate.description,
            recentLengths
                .map(String.init)
                .joined(separator: ","),
            lower.description,
            center.description,
            upper.description,
            confidence.rawValue,
            Self.predictionMethodVersion
        ]

        let nextPeriod =
            PredictionSnapshot(
                id:
                    stableID(
                        namespace:
                            openCycle.id,
                        components:
                            ["next_period"] +
                            predictionFingerprint
                    ),
                generatedAt:
                    generatedAt,
                predictionType:
                    .nextPeriod,
                targetDate:
                    center,
                dateRangeStart:
                    lower,
                dateRangeEnd:
                    upper,
                predictedCycleLength:
                    predictedLength,
                confidence:
                    confidence,
                inputCycleIDs:
                    cycleIDs,
                methodVersion:
                    Self
                        .predictionMethodVersion,
                validFrom:
                    generatedAt
            )

        let cycleLength =
            PredictionSnapshot(
                id:
                    stableID(
                        namespace:
                            openCycle.id,
                        components:
                            ["cycle_length"] +
                            predictionFingerprint
                    ),
                generatedAt:
                    generatedAt,
                predictionType:
                    .cycleLength,
                predictedCycleLength:
                    predictedLength,
                confidence:
                    confidence,
                inputCycleIDs:
                    cycleIDs,
                methodVersion:
                    Self
                        .predictionMethodVersion,
                validFrom:
                    generatedAt
            )

        _ = medianValue

        return [
            nextPeriod,
            cycleLength
        ]
    }

    // MARK: - Pattern insights

    private func makePatternInsights(
        archive: Prompt13CycleArchive,
        cycles: [Cycle],
        statistics: Prompt13CycleStatistics,
        generatedAt: Date
    ) -> [PatternInsight] {
        var results:
            [PatternInsight] = []

        let completed =
            cycles.filter {
                $0.status == .complete &&
                $0.observedLength != nil
            }

        if
            completed.count >= 3,
            let minimum =
                statistics.minimum,
            let maximum =
                statistics.maximum
        {
            let confidence =
                predictionConfidence(
                    completedCycleCount:
                        completed.count,
                    variation:
                        statistics.variation
                )

            let payload = [
                "minimum_days":
                    String(minimum),
                "maximum_days":
                    String(maximum),
                "sample_size":
                    String(
                        completed.count
                    ),
                "method_version":
                    Self.insightMethodVersion
            ]

            results.append(
                PatternInsight(
                    id:
                        stableID(
                            namespace:
                                completed[0].id,
                            components: [
                                "cycle_length_range",
                                completed
                                    .map {
                                        $0.id.uuidString
                                    }
                                    .joined(
                                        separator: ","
                                    ),
                                payload
                                    .keys
                                    .sorted()
                                    .map {
                                        "\($0)=\(payload[$0] ?? "")"
                                    }
                                    .joined(
                                        separator: "|"
                                    )
                            ]
                        ),
                    insightType:
                        .cycleLengthRange,
                    generatedAt:
                        generatedAt,
                    sourceCycleIDs:
                        completed.map(\.id),
                    sampleSize:
                        completed.count,
                    confidence:
                        confidence,
                    textKey:
                        "cycle_length_range",
                    dataPayload:
                        payload,
                    informationType:
                        .calculated
                )
            )
        }

        let activeSymptoms =
            archive
                .symptomObservations
                .filter {
                    !$0.metadata.isDeleted &&
                    $0.severity != .none
                }

        let grouped =
            Dictionary(
                grouping:
                    activeSymptoms,
                by:
                    \.symptomType
            )

        for (
            type,
            observations
        ) in grouped {
            var qualifyingObservationIDs:
                [UUID] = []

            var qualifyingCycleIDs =
                Set<UUID>()

            for observation in observations {
                guard
                    let cycle =
                        cycle(
                            containing:
                                observation.date,
                            in:
                                cycles
                        ),
                    let day =
                        try? cycle
                            .startDate
                            .days(
                                to:
                                    observation.date
                            )
                            .advanced(
                                by: 1
                            ),
                    (1...5).contains(day)
                else {
                    continue
                }

                qualifyingObservationIDs
                    .append(
                        observation.id
                    )

                qualifyingCycleIDs
                    .insert(
                        cycle.id
                    )
            }

            guard
                qualifyingCycleIDs.count >= 3,
                qualifyingObservationIDs.count >= 3
            else {
                continue
            }

            let orderedCycleIDs =
                Array(
                    qualifyingCycleIDs
                )
                .sorted {
                    $0.uuidString <
                    $1.uuidString
                }

            let orderedObservationIDs =
                qualifyingObservationIDs
                    .sorted {
                        $0.uuidString <
                        $1.uuidString
                    }

            let payload = [
                "symptom_type":
                    type.rawValue,
                "cycle_count":
                    String(
                        qualifyingCycleIDs
                            .count
                    ),
                "method_version":
                    Self.insightMethodVersion
            ]

            results.append(
                PatternInsight(
                    id:
                        stableID(
                            namespace:
                                orderedCycleIDs[0],
                            components: [
                                "symptom_near_cycle_start",
                                type.rawValue,
                                orderedCycleIDs
                                    .map(
                                        \.uuidString
                                    )
                                    .joined(
                                        separator: ","
                                    ),
                                orderedObservationIDs
                                    .map(
                                        \.uuidString
                                    )
                                    .joined(
                                        separator: ","
                                    )
                            ]
                        ),
                    insightType:
                        .symptomNearCycleStart,
                    generatedAt:
                        generatedAt,
                    sourceCycleIDs:
                        orderedCycleIDs,
                    sourceObservationIDs:
                        orderedObservationIDs,
                    sampleSize:
                        qualifyingCycleIDs.count,
                    confidence:
                        qualifyingCycleIDs
                            .count >= 4
                            ? .developing
                            : .limited,
                    textKey:
                        "symptom_near_cycle_start",
                    dataPayload:
                        payload,
                    informationType:
                        .calculated
                )
            )
        }

        return results.sorted {
            lhs,
            rhs in

            if
                lhs.insightType.rawValue !=
                rhs.insightType.rawValue
            {
                return
                    lhs.insightType.rawValue <
                    rhs.insightType.rawValue
            }

            return
                lhs.id.uuidString <
                rhs.id.uuidString
        }
    }

    // MARK: - Helpers

    private func cycle(
        containing date: Prompt13LocalDate,
        in cycles: [Cycle]
    ) -> Cycle? {
        cycles.last {
            cycle in

            guard
                cycle.startDate <= date
            else {
                return false
            }

            if let endDate =
                cycle.endDate
            {
                return
                    date <= endDate
            }

            return
                cycle.status == .open
        }
    }

    private func median(
        _ values: [Double]
    ) -> Double {
        guard !values.isEmpty else {
            return 0
        }

        let sorted =
            values.sorted()

        let middle =
            sorted.count / 2

        if sorted.count.isMultiple(
            of: 2
        ) {
            return
                (
                    sorted[middle - 1] +
                    sorted[middle]
                ) /
                2.0
        }

        return sorted[middle]
    }

    private func stableID(
        namespace: UUID,
        components: [String]
    ) -> UUID {
        let text =
            namespace.uuidString +
            "|" +
            components.joined(
                separator: "|"
            )

        let bytes =
            Array(
                text.utf8
            )

        var high:
            UInt64 =
            0xcbf29ce484222325

        var low:
            UInt64 =
            0x84222325cbf29ce4

        for byte in bytes {
            high ^=
                UInt64(byte)

            high &*=
                0x100000001b3

            low ^=
                UInt64(byte) +
                0x9e

            low &*=
                0x100000001b3
        }

        var raw =
            [UInt8](
                repeating: 0,
                count: 16
            )

        for index in 0..<8 {
            raw[index] =
                UInt8(
                    (
                        high >>
                        UInt64(
                            (7 - index) * 8
                        )
                    ) &
                    0xff
                )

            raw[index + 8] =
                UInt8(
                    (
                        low >>
                        UInt64(
                            (7 - index) * 8
                        )
                    ) &
                    0xff
                )
        }

        raw[6] =
            (raw[6] & 0x0f) |
            0x50

        raw[8] =
            (raw[8] & 0x3f) |
            0x80

        let tuple: uuid_t = (
            raw[0],
            raw[1],
            raw[2],
            raw[3],
            raw[4],
            raw[5],
            raw[6],
            raw[7],
            raw[8],
            raw[9],
            raw[10],
            raw[11],
            raw[12],
            raw[13],
            raw[14],
            raw[15]
        )

        return UUID(
            uuid: tuple
        )
    }

    private func deterministicCycleID(
        startID: UUID
    ) -> UUID {
        let mask: [UInt8] = [
            0x46,
            0x52,
            0x55,
            0x49,
            0x54,
            0x46,
            0x4F,
            0x4C,
            0x49,
            0x4F,
            0x31,
            0x33,
            0x43,
            0x59,
            0x43,
            0x4C
        ]

        var bytes =
            startID.uuid

        withUnsafeMutableBytes(
            of: &bytes
        ) { raw in
            for index in 0..<16 {
                raw[index] ^=
                    mask[index]
            }
        }

        return UUID(
            uuid: bytes
        )
    }
}
