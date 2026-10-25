import Foundation

public struct Prompt19CalendarDateKey: Hashable, Codable, Sendable, Comparable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = c.year ?? 0
        self.month = c.month ?? 0
        self.day = c.day ?? 0
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }

    public func date(in calendar: Calendar) -> Date? {
        var c = DateComponents()
        c.calendar = calendar
        c.timeZone = calendar.timeZone
        c.year = year
        c.month = month
        c.day = day
        c.hour = 12
        return calendar.date(from: c)
    }
}

public struct Prompt19CalendarMonth: Hashable, Codable, Sendable {
    public let year: Int
    public let month: Int

    public init(year: Int, month: Int) {
        self.year = year
        self.month = month
    }

    public init(containing date: Date, calendar: Calendar) {
        let c = calendar.dateComponents([.year, .month], from: date)
        self.year = c.year ?? 0
        self.month = c.month ?? 0
    }

    public func firstDate(in calendar: Calendar) -> Date? {
        var c = DateComponents()
        c.calendar = calendar
        c.timeZone = calendar.timeZone
        c.year = year
        c.month = month
        c.day = 1
        c.hour = 12
        return calendar.date(from: c)
    }

    public func shifted(by value: Int, calendar: Calendar) -> Self? {
        guard let first = firstDate(in: calendar),
              let shifted = calendar.date(byAdding: .month, value: value, to: first)
        else {
            return nil
        }
        return Self(containing: shifted, calendar: calendar)
    }
}

public enum Prompt19CalendarPrimaryState: String, Codable, Sendable, CaseIterable {
    case none
    case recordedPeriod
    case predictedPeriod
    case fertileEstimate
    case ovulationEstimate
}

public enum Prompt19CalendarMetadataKind: String, Codable, Sendable, CaseIterable {
    case symptom
    case bbt
    case note

    public var priority: Int {
        switch self {
        case .bbt: return 0
        case .symptom: return 1
        case .note: return 2
        }
    }
}

public struct Prompt19CalendarDayAnnotation: Equatable, Sendable {
    public let key: Prompt19CalendarDateKey
    public var cycleDay: Int?
    public var recordedPeriod: Bool
    public var predictedPeriod: Bool
    public var fertileEstimated: Bool
    public var ovulationEstimated: Bool
    public var symptomsLogged: Bool
    public var bbtRecorded: Bool
    public var noteAdded: Bool
    public var symptomSummary: [String]
    public var temperatureDisplay: String?
    public var noteText: String?

    public init(
        key: Prompt19CalendarDateKey,
        cycleDay: Int? = nil,
        recordedPeriod: Bool = false,
        predictedPeriod: Bool = false,
        fertileEstimated: Bool = false,
        ovulationEstimated: Bool = false,
        symptomsLogged: Bool = false,
        bbtRecorded: Bool = false,
        noteAdded: Bool = false,
        symptomSummary: [String] = [],
        temperatureDisplay: String? = nil,
        noteText: String? = nil
    ) {
        self.key = key
        self.cycleDay = cycleDay
        self.recordedPeriod = recordedPeriod
        self.predictedPeriod = predictedPeriod
        self.fertileEstimated = fertileEstimated
        self.ovulationEstimated = ovulationEstimated
        self.symptomsLogged = symptomsLogged
        self.bbtRecorded = bbtRecorded
        self.noteAdded = noteAdded
        self.symptomSummary = symptomSummary
        self.temperatureDisplay = temperatureDisplay
        self.noteText = noteText
    }

    public var primaryState: Prompt19CalendarPrimaryState {
        if recordedPeriod { return .recordedPeriod }
        if ovulationEstimated { return .ovulationEstimate }
        if fertileEstimated { return .fertileEstimate }
        if predictedPeriod { return .predictedPeriod }
        return .none
    }

    public var visibleMetadata: [Prompt19CalendarMetadataKind] {
        var values: [Prompt19CalendarMetadataKind] = []
        if symptomsLogged { values.append(.symptom) }
        if bbtRecorded { values.append(.bbt) }
        if noteAdded { values.append(.note) }
        return values
            .sorted { $0.priority < $1.priority }
            .prefix(2)
            .map { $0 }
    }

    public var containsEstimate: Bool {
        predictedPeriod || fertileEstimated || ovulationEstimated
    }
}

public struct Prompt19CalendarCell: Identifiable, Equatable, Sendable {
    public let id: Prompt19CalendarDateKey?
    public let key: Prompt19CalendarDateKey?
    public let dateNumber: Int?
    public let isInDisplayedMonth: Bool
    public let isToday: Bool
    public let isSelected: Bool
    public let annotation: Prompt19CalendarDayAnnotation?

    public init(
        key: Prompt19CalendarDateKey?,
        dateNumber: Int?,
        isInDisplayedMonth: Bool,
        isToday: Bool,
        isSelected: Bool,
        annotation: Prompt19CalendarDayAnnotation?
    ) {
        self.id = key
        self.key = key
        self.dateNumber = dateNumber
        self.isInDisplayedMonth = isInDisplayedMonth
        self.isToday = isToday
        self.isSelected = isSelected
        self.annotation = annotation
    }

    public var isInteractive: Bool {
        isInDisplayedMonth && key != nil
    }
}

public struct Prompt19CalendarMonthModel: Equatable, Sendable {
    public let month: Prompt19CalendarMonth
    public let cells: [Prompt19CalendarCell]
    public let weekRowCount: Int

    public init(
        month: Prompt19CalendarMonth,
        cells: [Prompt19CalendarCell],
        weekRowCount: Int
    ) {
        self.month = month
        self.cells = cells
        self.weekRowCount = weekRowCount
    }
}

public struct Prompt19CalendarSnapshot: Equatable, Sendable {
    public let month: Prompt19CalendarMonth
    public let annotations: [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation]
    public let predictionHistoryVersion: String?
    public let predictionConfidenceLabel: String?

    public init(
        month: Prompt19CalendarMonth,
        annotations: [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation],
        predictionHistoryVersion: String? = nil,
        predictionConfidenceLabel: String? = nil
    ) {
        self.month = month
        self.annotations = annotations
        self.predictionHistoryVersion = predictionHistoryVersion
        self.predictionConfidenceLabel = predictionConfidenceLabel
    }

    public static func empty(month: Prompt19CalendarMonth) -> Self {
        Self(month: month, annotations: [:])
    }
}

public enum Prompt19CalendarAction: Equatable, Sendable {
    case logSymptoms(Date)
    case addTemperature(Date)
    case addNote(Date)
    case seeBiology(Date)
}

public enum Prompt19CalendarLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}
