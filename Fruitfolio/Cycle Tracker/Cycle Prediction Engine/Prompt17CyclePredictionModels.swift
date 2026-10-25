import Foundation

public enum Prompt17BiologicalDataProvenance: String, Codable, Sendable {
    case recorded
    case calculated
    case estimated
    case educational
}

public enum Prompt17PredictionConfidence: String, Codable, CaseIterable, Sendable {
    case strongEstimate = "strong estimate"
    case developingEstimate = "developing estimate"
    case limitedEstimate = "limited estimate"
}

public enum Prompt17CycleVariation: String, Codable, Sendable {
    case low
    case moderate
    case high
}

public enum Prompt17DataSufficiency: String, Codable, Sendable {
    case noCompletedCycles
    case oneCompletedCycle
    case someHistory
    case establishedHistory
}

public enum Prompt17ValidationIssue: Equatable, Sendable {
    case futureCycleStartIgnored(Date)
    case futurePeriodRecordIgnored(Date)
    case periodEndBeforeStartIgnored(start: Date, end: Date)
}

public struct Prompt17RecordedPeriod: Equatable, Sendable {
    public let startDate: Date
    public let endDate: Date?

    public init(startDate: Date, endDate: Date?) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct Prompt17CyclePredictionInput: Sendable {
    public let cycleStartDates: [Date]
    public let periodRecords: [Prompt17RecordedPeriod]
    public let asOfDate: Date

    public init(
        cycleStartDates: [Date],
        periodRecords: [Prompt17RecordedPeriod] = [],
        asOfDate: Date = Date()
    ) {
        self.cycleStartDates = cycleStartDates
        self.periodRecords = periodRecords
        self.asOfDate = asOfDate
    }
}

public struct Prompt17DateWindow: Equatable, Sendable {
    public let start: Date
    public let end: Date
    public let provenance: Prompt17BiologicalDataProvenance
    public let confidence: Prompt17PredictionConfidence

    public init(
        start: Date,
        end: Date,
        provenance: Prompt17BiologicalDataProvenance = .estimated,
        confidence: Prompt17PredictionConfidence
    ) {
        self.start = min(start, end)
        self.end = max(start, end)
        self.provenance = provenance
        self.confidence = confidence
    }

}

public struct Prompt17CyclePredictionResult: Sendable {
    public let normalizedCycleStartDates: [Date]
    public let completedCycleLengths: [Int]
    public let recentCycleLengths: [Int]
    public let meanCycleLength: Double?
    public let medianCycleLength: Double?
    public let cycleVariation: Prompt17CycleVariation?
    public let recordedPeriodLengths: [Int]
    public let typicalPeriodLength: Int?
    public let currentCycleDay: Int?
    public let estimatedCycleLength: Int?
    public let currentCycleProgress: Double?
    public let nextPeriodWindow: Prompt17DateWindow?
    public let predictionConfidence: Prompt17PredictionConfidence
    public let dataSufficiency: Prompt17DataSufficiency
    public let predictionRangeHalfWidthDays: Int?
    public let historyVersion: String
    public let calculatedAt: Date
    public let validationIssues: [Prompt17ValidationIssue]

    public init(
        normalizedCycleStartDates: [Date],
        completedCycleLengths: [Int],
        recentCycleLengths: [Int],
        meanCycleLength: Double?,
        medianCycleLength: Double?,
        cycleVariation: Prompt17CycleVariation?,
        recordedPeriodLengths: [Int],
        typicalPeriodLength: Int?,
        currentCycleDay: Int?,
        estimatedCycleLength: Int?,
        currentCycleProgress: Double?,
        nextPeriodWindow: Prompt17DateWindow?,
        predictionConfidence: Prompt17PredictionConfidence,
        dataSufficiency: Prompt17DataSufficiency,
        predictionRangeHalfWidthDays: Int?,
        historyVersion: String,
        calculatedAt: Date,
        validationIssues: [Prompt17ValidationIssue]
    ) {
        self.normalizedCycleStartDates = normalizedCycleStartDates
        self.completedCycleLengths = completedCycleLengths
        self.recentCycleLengths = recentCycleLengths
        self.meanCycleLength = meanCycleLength
        self.medianCycleLength = medianCycleLength
        self.cycleVariation = cycleVariation
        self.recordedPeriodLengths = recordedPeriodLengths
        self.typicalPeriodLength = typicalPeriodLength
        self.currentCycleDay = currentCycleDay
        self.estimatedCycleLength = estimatedCycleLength
        self.currentCycleProgress = currentCycleProgress
        self.nextPeriodWindow = nextPeriodWindow
        self.predictionConfidence = predictionConfidence
        self.dataSufficiency = dataSufficiency
        self.predictionRangeHalfWidthDays = predictionRangeHalfWidthDays
        self.historyVersion = historyVersion
        self.calculatedAt = calculatedAt
        self.validationIssues = validationIssues
    }
}
