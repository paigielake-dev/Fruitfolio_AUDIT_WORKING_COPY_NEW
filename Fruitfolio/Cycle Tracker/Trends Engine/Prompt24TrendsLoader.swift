import Foundation

@MainActor
struct Prompt24TrendsLoader {
    var todayLoader = Prompt16TodayLoader()
    var dailyLogRepository: (any Prompt20DailyLogRepository)?
    var ownerID: Prompt20DailyLogOwnerID?
    var displayTemperatureUnit: Prompt20TemperatureUnit = .fahrenheit

    /// Optional validated deterministic provider. Phase 24 deliberately does
    /// not invent a BBT-to-ovulation algorithm when no approved provider exists.
    var temperatureShiftProvider:
        (@Sendable ([Prompt20DailyLog]) async -> Prompt24TemperatureShiftStatus)?

    func load(now: Date = Date()) async throws -> Prompt24TrendsSnapshot {
        let repository =
            dailyLogRepository ?? Prompt20CycleDailyLogStore.shared
        let resolvedOwnerID =
            ownerID ?? Prompt20DailyLogOwnerID.localDevice

        async let logsTask =
            repository.allActiveLogs(ownerID: resolvedOwnerID)

        // Onboarding load may resume its journaled cycle-file change.
        let onboarding = try await todayLoader.onboardingStore.snapshot()
        let archive = try await todayLoader.cycleStore.snapshot()
        let logs = try await logsTask

        let bridge = try Prompt24Prompt17Bridge.makePredictionAndPeriods(
            archive: archive,
            onboarding: onboarding,
            asOfDate: now,
            calendar: todayLoader.calendar
        )

        let shift: Prompt24TemperatureShiftStatus
        if let temperatureShiftProvider {
            shift = await temperatureShiftProvider(logs)
        } else {
            shift = .unavailable
        }

        let predictionMarker: Prompt24PredictionMarker?
        if let estimate = bridge.prediction.estimatedCycleLength {
            predictionMarker = Prompt24PredictionMarker(
                estimatedCycleLength: estimate,
                confidence: bridge.prediction.predictionConfidence
            )
        } else {
            predictionMarker = nil
        }

        let input = Prompt24TrendsInput(
            cycleStartDates: bridge.prediction.normalizedCycleStartDates,
            completedCycleLengths: bridge.prediction.completedCycleLengths,
            periodRecords: bridge.periodRecords,
            dailyLogs: logs,
            predictionMarker: predictionMarker,
            displayTemperatureUnit: displayTemperatureUnit,
            temperatureShiftStatus: shift
        )

        return Prompt24TrendsEngine(
            calendar: todayLoader.calendar
        )
        .calculate(
            from: input,
            asOfDate: now
        )
    }
}

private enum Prompt24Prompt17Bridge {
    struct Output {
        let prediction: Prompt17CyclePredictionResult
        let periodRecords: [Prompt17RecordedPeriod]
    }

    static func makePredictionAndPeriods(
        archive: Prompt13CycleArchive,
        onboarding: Prompt14OnboardingDraft,
        asOfDate: Date,
        calendar: Calendar
    ) throws -> Output {
        let storedCycleStarts =
            archive.cycleStarts
                .filter { !$0.metadata.isDeleted }
                .map(\.date)

        let sourceCycleStarts =
            storedCycleStarts.isEmpty
                ? onboarding.allSuppliedCycleStarts
                : storedCycleStarts

        let cycleStartDates = try sourceCycleStarts.map {
            try Prompt24LocalDateBridge.foundationDate(
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
        )
        .calculate(
            from: Prompt17CyclePredictionInput(
                cycleStartDates: cycleStartDates,
                periodRecords: periodRecords,
                asOfDate: asOfDate
            )
        )

        return Output(
            prediction: prediction,
            periodRecords: periodRecords
        )
    }

    private static func makeExplicitPeriodRecords(
        onboarding: Prompt14OnboardingDraft,
        calendar: Calendar
    ) throws -> [Prompt17RecordedPeriod] {
        guard onboarding.latestPeriodState == .supplied,
              let localStart = onboarding.latestPeriodStart
        else {
            return []
        }

        let start = try Prompt24LocalDateBridge.foundationDate(
            from: localStart,
            calendar: calendar
        )

        let end: Date?
        if onboarding.currentPeriodAnswer == .no,
           onboarding.periodEndState == .supplied,
           let localEnd = onboarding.periodEnd {
            end = try Prompt24LocalDateBridge.foundationDate(
                from: localEnd,
                calendar: calendar
            )
        } else {
            end = nil
        }

        return [
            Prompt17RecordedPeriod(
                startDate: start,
                endDate: end
            )
        ]
    }
}

private enum Prompt24LocalDateBridgeError: Error {
    case unsupportedEncoding
    case invalidCalendarDate
}

private enum Prompt24LocalDateBridge {
    static func foundationDate(
        from localDate: Prompt13LocalDate,
        calendar: Calendar
    ) throws -> Date {
        try localDate.foundationDate(in: calendar)
    }

    private static func extractComponents(
        from object: Any
    ) -> (year: Int, month: Int, day: Int)? {
        guard let dictionary = object as? [String: Any] else {
            return nil
        }

        if let year = integer(dictionary["year"]),
           let month = integer(dictionary["month"]),
           let day = integer(dictionary["day"]) {
            return (year, month, day)
        }

        for key in ["date", "components", "value"] {
            if let nested = dictionary[key],
               let components = extractComponents(from: nested) {
                return components
            }
        }

        return nil
    }

    private static func integer(_ value: Any?) -> Int? {
        if let int = value as? Int {
            return int
        }

        if let number = value as? NSNumber {
            return number.intValue
        }

        if let string = value as? String {
            return Int(string)
        }

        return nil
    }
}
