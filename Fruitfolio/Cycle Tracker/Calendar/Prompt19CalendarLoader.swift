import Foundation

struct Prompt19CalendarLoader {
    var todayLoader: Prompt16TodayLoader
    var supplementalProvider: Prompt19CalendarSupplementalProvider
    var contextPolicy: Prompt27AContextPolicyResult

    init(
        todayLoader: Prompt16TodayLoader = Prompt16TodayLoader(),
        supplementalProvider: Prompt19CalendarSupplementalProvider? = nil,
        contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult()
    ) {
        self.todayLoader = todayLoader
        self.supplementalProvider = supplementalProvider ?? .empty
        self.contextPolicy = contextPolicy
    }

    func load(
        month: Prompt19CalendarMonth,
        now: Date = Date()
    ) async throws -> Prompt19CalendarSnapshot {
        async let archiveTask = todayLoader.cycleStore.snapshot()
        async let onboardingTask = todayLoader.onboardingStore.snapshot()

        let archive = try await archiveTask
        let onboarding = try await onboardingTask

        let calendar = todayLoader.calendar
        let engine = Prompt19CalendarEngine(calendar: calendar)

        let storedStarts = archive
            .cycleStarts
            .filter { !$0.metadata.isDeleted }
            .map(\.date)

        let sourceStarts = storedStarts.isEmpty
            ? onboarding.allSuppliedCycleStarts
            : storedStarts

        let cycleStartDates = try sourceStarts.map {
            try Prompt19LocalDateBridge.foundationDate(
                from: $0,
                calendar: calendar
            )
        }

        let periodRecords = try makeExplicitPeriodRecords(
            onboarding: onboarding,
            calendar: calendar
        )

        let prediction = Prompt17CyclePredictionEngine(
            calendar: calendar
        ).calculate(
            from: Prompt17CyclePredictionInput(
                cycleStartDates: cycleStartDates,
                periodRecords: periodRecords,
                asOfDate: now
            )
        )

        let todayKey = Prompt19CalendarDateKey(
            date: now,
            calendar: calendar
        )

        let startKeys = prediction.normalizedCycleStartDates.map {
            Prompt19CalendarDateKey(date: $0, calendar: calendar)
        }

        var annotations: [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation] = [:]

        for key in startKeys where key.year == month.year && key.month == month.month {
            let cycleDay = engine.cycleDay(
                for: key,
                recordedCycleStarts: startKeys,
                today: todayKey
            )

            annotations[key] = engine.merging(
                Prompt19CalendarDayAnnotation(
                    key: key,
                    cycleDay: cycleDay,
                    recordedPeriod: true
                ),
                into: annotations[key]
            )
        }

        // Only explicit recorded period ranges are filled. Missing end dates are not extended.
        for period in periodRecords {
            guard let end = period.endDate else { continue }
            let range = period.startDate...end
            for key in engine.keys(in: range, restrictedTo: month) {
                let cycleDay = engine.cycleDay(
                    for: key,
                    recordedCycleStarts: startKeys,
                    today: todayKey
                )

                annotations[key] = engine.merging(
                    Prompt19CalendarDayAnnotation(
                        key: key,
                        cycleDay: cycleDay,
                        recordedPeriod: true
                    ),
                    into: annotations[key]
                )
            }
        }

        // Historical/present cycle-day labels are calculated only from recorded starts.
        if let first = month.firstDate(in: calendar),
           let dayRange = calendar.range(of: .day, in: .month, for: first) {
            for day in dayRange {
                let key = Prompt19CalendarDateKey(
                    year: month.year,
                    month: month.month,
                    day: day
                )
                guard let cycleDay = engine.cycleDay(
                    for: key,
                    recordedCycleStarts: startKeys,
                    today: todayKey
                ) else {
                    continue
                }

                let base = annotations[key] ?? Prompt19CalendarDayAnnotation(key: key)
                annotations[key] = engine.merging(
                    Prompt19CalendarDayAnnotation(
                        key: key,
                        cycleDay: cycleDay
                    ),
                    into: base
                )
            }
        }

        let contextAdapter = Prompt27AExistingSystemPolicyAdapter(
            result: contextPolicy
        )

        // Prompt 17's deterministic next-period window is the only predicted period
        // source consumed here. Prompt 27A may make that overlay presently
        // inapplicable, but never changes Prompt 17's calculation or stored history.
        if contextAdapter.showCurrentNextPeriodPrediction,
           let nextWindow = prediction.nextPeriodWindow,
           nextWindow.provenance == .estimated {
            for key in engine.keys(
                in: nextWindow.start...nextWindow.end,
                restrictedTo: month
            ) {
                annotations[key] = engine.merging(
                    Prompt19CalendarDayAnnotation(
                        key: key,
                        predictedPeriod: true
                    ),
                    into: annotations[key]
                )
            }
        }

        // Prompt 17 currently does not emit validated fertile/ovulation windows.
        // Those states stay absent unless a deterministic upstream provider supplies them.
        let supplemental = try await supplementalProvider.load(month, calendar)
        for incoming in supplemental {
            var presentationAnnotation = incoming

            if !contextAdapter.showCurrentNextPeriodPrediction {
                presentationAnnotation.predictedPeriod = false
            }

            if !contextAdapter.showCurrentFertileWindowPrediction {
                presentationAnnotation.fertileEstimated = false
            }

            if !contextAdapter.showCurrentOvulationPrediction {
                presentationAnnotation.ovulationEstimated = false
            }

            annotations[presentationAnnotation.key] = engine.merging(
                presentationAnnotation,
                into: annotations[presentationAnnotation.key]
            )
        }

        return Prompt19CalendarSnapshot(
            month: month,
            annotations: annotations,
            predictionHistoryVersion: prediction.historyVersion,
            predictionConfidenceLabel: prediction.predictionConfidence.rawValue
        )
    }

    private func makeExplicitPeriodRecords(
        onboarding: Prompt14OnboardingDraft,
        calendar: Calendar
    ) throws -> [Prompt17RecordedPeriod] {
        guard onboarding.latestPeriodState == .supplied,
              let localStart = onboarding.latestPeriodStart
        else {
            return []
        }

        let start = try Prompt19LocalDateBridge.foundationDate(
            from: localStart,
            calendar: calendar
        )

        let end: Date?
        if onboarding.currentPeriodAnswer == .no,
           onboarding.periodEndState == .supplied,
           let localEnd = onboarding.periodEnd {
            end = try Prompt19LocalDateBridge.foundationDate(
                from: localEnd,
                calendar: calendar
            )
        } else {
            end = nil
        }

        return [Prompt17RecordedPeriod(startDate: start, endDate: end)]
    }
}

struct Prompt19CalendarSupplementalProvider: Sendable {
    let load: @Sendable (
        Prompt19CalendarMonth,
        Calendar
    ) async throws -> [Prompt19CalendarDayAnnotation]

    init(
        load: @escaping @Sendable (
            Prompt19CalendarMonth,
            Calendar
        ) async throws -> [Prompt19CalendarDayAnnotation]
    ) {
        self.load = load
    }

    static let empty = Prompt19CalendarSupplementalProvider { _, _ in [] }
}

private enum Prompt19LocalDateBridgeError: Error {
    case unsupportedEncoding
    case invalidCalendarDate
}

private enum Prompt19LocalDateBridge {
    static func foundationDate(
        from localDate: Prompt13LocalDate,
        calendar: Calendar
    ) throws -> Date {
        let data = try JSONEncoder().encode(localDate)
        let object = try JSONSerialization.jsonObject(with: data)

        guard let components = extractComponents(from: object) else {
            throw Prompt19LocalDateBridgeError.unsupportedEncoding
        }

        var c = DateComponents()
        c.calendar = calendar
        c.timeZone = calendar.timeZone
        c.year = components.year
        c.month = components.month
        c.day = components.day
        c.hour = 12

        guard let date = calendar.date(from: c) else {
            throw Prompt19LocalDateBridgeError.invalidCalendarDate
        }

        return date
    }

    private static func extractComponents(
        from object: Any
    ) -> (year: Int, month: Int, day: Int)? {
        if let dictionary = object as? [String: Any] {
            if let year = integerValue(dictionary["year"]),
               let month = integerValue(dictionary["month"]),
               let day = integerValue(dictionary["day"]) {
                return (year, month, day)
            }

            for value in dictionary.values {
                if let nested = extractComponents(from: value) {
                    return nested
                }
            }
        }

        if let array = object as? [Any] {
            if array.count == 3,
               let year = integerValue(array[0]),
               let month = integerValue(array[1]),
               let day = integerValue(array[2]) {
                return (year, month, day)
            }

            for value in array {
                if let nested = extractComponents(from: value) {
                    return nested
                }
            }
        }

        if let string = object as? String {
            let pieces = string.split(separator: "-")
            guard pieces.count >= 3,
                  let year = Int(pieces[0]),
                  let month = Int(pieces[1])
            else {
                return nil
            }

            let dayDigits = pieces[2].prefix { $0.isNumber }
            guard let day = Int(dayDigits) else { return nil }
            return (year, month, day)
        }

        return nil
    }

    private static func integerValue(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }
}
