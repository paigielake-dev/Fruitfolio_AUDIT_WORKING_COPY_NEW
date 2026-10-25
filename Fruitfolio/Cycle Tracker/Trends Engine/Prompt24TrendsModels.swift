import Foundation

nonisolated enum Prompt24TrendsTab: String, CaseIterable, Identifiable, Sendable {
    case cycle
    case temperature
    case symptoms

    var id: String { rawValue }
}

nonisolated enum Prompt24PatternStatus: String, Equatable, Sendable {
    case insufficientData = "insufficient_data"
    case unsupported
    case developing
    case supported
}

nonisolated enum Prompt24TemperatureShiftStatus: Equatable, Sendable {
    case unavailable
    case notDetected
    case detected(summary: String)
}

nonisolated struct Prompt24CycleLengthPoint: Identifiable, Equatable, Sendable {
    let cycleIndex: Int
    let startDate: Date
    let days: Int

    var id: String {
        "\(cycleIndex)-\(startDate.timeIntervalSinceReferenceDate)"
    }
}

nonisolated struct Prompt24PeriodLengthPoint: Identifiable, Equatable, Sendable {
    let startDate: Date
    let endDate: Date
    let days: Int

    var id: String {
        "\(startDate.timeIntervalSinceReferenceDate)-\(endDate.timeIntervalSinceReferenceDate)"
    }
}

nonisolated struct Prompt24BBTPoint: Identifiable, Equatable, Sendable {
    let date: Date
    let originalValue: Double
    let originalUnit: Prompt20TemperatureUnit
    let canonicalCelsius: Double
    let cycleDay: Int?

    var id: String {
        "bbt-\(date.timeIntervalSinceReferenceDate)"
    }

    func value(in unit: Prompt20TemperatureUnit) -> Double {
        switch unit {
        case .celsius:
            canonicalCelsius
        case .fahrenheit:
            canonicalCelsius * 9.0 / 5.0 + 32.0
        }
    }
}

nonisolated struct Prompt24SymptomOccurrence: Identifiable, Equatable, Sendable {
    let symptomID: Prompt20SymptomID
    let date: Date
    let cycleDay: Int?
    let completedCycleIndex: Int?

    var id: String {
        "\(symptomID.rawValue)-\(date.timeIntervalSinceReferenceDate)"
    }
}

nonisolated struct Prompt24SymptomPattern: Equatable, Sendable {
    let symptomID: Prompt20SymptomID
    let status: Prompt24PatternStatus
    let cyclesEvaluated: Int
    let cyclesMatched: Int
    let windowStartDay: Int?
    let windowEndDay: Int?
    let underlyingDataIsRecorded: Bool
    let patternIsCalculated: Bool
    let algorithmVersion: String

    var isEligibleForNudge: Bool {
        status == .supported
    }
}

nonisolated struct Prompt24PredictionMarker: Equatable, Sendable {
    let estimatedCycleLength: Int
    let confidence: Prompt17PredictionConfidence
}

nonisolated struct Prompt24TrendsInput: Sendable {
    let cycleStartDates: [Date]
    let completedCycleLengths: [Int]
    let periodRecords: [Prompt17RecordedPeriod]
    let dailyLogs: [Prompt20DailyLog]
    let predictionMarker: Prompt24PredictionMarker?
    let displayTemperatureUnit: Prompt20TemperatureUnit
    let temperatureShiftStatus: Prompt24TemperatureShiftStatus

    init(
        cycleStartDates: [Date],
        completedCycleLengths: [Int],
        periodRecords: [Prompt17RecordedPeriod],
        dailyLogs: [Prompt20DailyLog],
        predictionMarker: Prompt24PredictionMarker?,
        displayTemperatureUnit: Prompt20TemperatureUnit = .fahrenheit,
        temperatureShiftStatus: Prompt24TemperatureShiftStatus = .unavailable
    ) {
        self.cycleStartDates = cycleStartDates
        self.completedCycleLengths = completedCycleLengths
        self.periodRecords = periodRecords
        self.dailyLogs = dailyLogs
        self.predictionMarker = predictionMarker
        self.displayTemperatureUnit = displayTemperatureUnit
        self.temperatureShiftStatus = temperatureShiftStatus
    }
}

nonisolated struct Prompt24TrendsSnapshot: Equatable, Sendable {
    let cycleLengths: [Prompt24CycleLengthPoint]
    let cycleMedianDays: Double?
    let cycleObservedRange: ClosedRange<Int>?
    let periodLengths: [Prompt24PeriodLengthPoint]
    let periodMedianDays: Double?
    let bbtPoints: [Prompt24BBTPoint]
    let displayTemperatureUnit: Prompt20TemperatureUnit
    let temperatureShiftStatus: Prompt24TemperatureShiftStatus
    let symptomOccurrences: [Prompt24SymptomOccurrence]
    let symptomPatterns: [Prompt20SymptomID: Prompt24SymptomPattern]
    let predictionMarker: Prompt24PredictionMarker?
    let calculatedAt: Date
    let algorithmVersion: String

    var hasCycleTrendData: Bool {
        !cycleLengths.isEmpty || !periodLengths.isEmpty
    }

    var hasTemperatureData: Bool {
        !bbtPoints.isEmpty
    }

    func occurrences(for symptomID: Prompt20SymptomID) -> [Prompt24SymptomOccurrence] {
        symptomOccurrences.filter { $0.symptomID == symptomID }
    }

    func pattern(for symptomID: Prompt20SymptomID) -> Prompt24SymptomPattern {
        symptomPatterns[symptomID]
            ?? Prompt24SymptomPattern(
                symptomID: symptomID,
                status: .insufficientData,
                cyclesEvaluated: 0,
                cyclesMatched: 0,
                windowStartDay: nil,
                windowEndDay: nil,
                underlyingDataIsRecorded: true,
                patternIsCalculated: true,
                algorithmVersion: algorithmVersion
            )
    }
}
