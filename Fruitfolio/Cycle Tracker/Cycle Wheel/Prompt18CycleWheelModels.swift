import Foundation

public enum Prompt18WheelRegionKind: String, CaseIterable, Codable, Sendable, Identifiable {
    case menstruation
    case follicular
    case estimatedOvulation
    case luteal
    case estimatedFertileWindow

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .menstruation:
            return "menstruation"
        case .follicular:
            return "follicular phase"
        case .estimatedOvulation:
            return "estimated ovulation"
        case .luteal:
            return "luteal phase"
        case .estimatedFertileWindow:
            return "estimated fertile window"
        }
    }

    public var noteBody: String {
        switch self {
        case .menstruation:
            return "the uterine lining is shedding at the start of a new cycle."
        case .follicular:
            return "follicles are developing in the ovary."
        case .estimatedOvulation:
            return "this is when ovulation may occur based on your logged cycle pattern."
        case .luteal:
            return "after ovulation, progesterone commonly rises as the body supports the uterine lining."
        case .estimatedFertileWindow:
            return "an estimated window based on what you’ve logged."
        }
    }

    public var isEstimate: Bool {
        switch self {
        case .estimatedOvulation, .estimatedFertileWindow:
            return true
        case .menstruation, .follicular, .luteal:
            return false
        }
    }
}

public struct Prompt18CycleDayInterval: Equatable, Codable, Sendable {
    public let startDay: Int
    public let endDay: Int
    public let provenance: Prompt17BiologicalDataProvenance

    public init(
        startDay: Int,
        endDay: Int,
        provenance: Prompt17BiologicalDataProvenance
    ) {
        self.startDay = max(1, startDay)
        self.endDay = max(max(1, startDay), endDay)
        self.provenance = provenance
    }

    public var dayCount: Int {
        endDay - startDay + 1
    }

    public func contains(day: Int) -> Bool {
        day >= startDay && day <= endDay
    }
}

public struct Prompt18EstimatedIntervals: Equatable, Codable, Sendable {
    public let estimatedOvulation: Prompt18CycleDayInterval?
    public let estimatedFertileWindow: Prompt18CycleDayInterval?

    public init(
        estimatedOvulation: Prompt18CycleDayInterval? = nil,
        estimatedFertileWindow: Prompt18CycleDayInterval? = nil
    ) {
        self.estimatedOvulation = estimatedOvulation?.provenance == .estimated ? estimatedOvulation : nil
        self.estimatedFertileWindow = estimatedFertileWindow?.provenance == .estimated ? estimatedFertileWindow : nil
    }

    public static let none = Prompt18EstimatedIntervals()
}

public struct Prompt18WheelSegment: Identifiable, Equatable, Sendable {
    public let kind: Prompt18WheelRegionKind
    public let interval: Prompt18CycleDayInterval
    public let startFraction: Double
    public let endFraction: Double

    public var id: String { kind.rawValue }

    public init(
        kind: Prompt18WheelRegionKind,
        interval: Prompt18CycleDayInterval,
        startFraction: Double,
        endFraction: Double
    ) {
        self.kind = kind
        self.interval = interval
        self.startFraction = startFraction
        self.endFraction = endFraction
    }

    public var fractionLength: Double {
        max(0, endFraction - startFraction)
    }

    public var midFraction: Double {
        (startFraction + endFraction) / 2
    }
}

public struct Prompt18WheelModel: Equatable, Sendable {
    public let representedCycleLength: Int?
    public let currentCycleDay: Int?
    public let baseSegments: [Prompt18WheelSegment]
    public let fertileOverlay: Prompt18WheelSegment?
    public let unresolvedIntervals: [Prompt18CycleDayInterval]
    public let currentRegion: Prompt18WheelRegionKind?
    public let currentPositionFraction: Double?
    public let confidence: Prompt17PredictionConfidence
    public let dataSufficiency: Prompt17DataSufficiency
    public let historyVersion: String

    public init(
        representedCycleLength: Int?,
        currentCycleDay: Int?,
        baseSegments: [Prompt18WheelSegment],
        fertileOverlay: Prompt18WheelSegment?,
        unresolvedIntervals: [Prompt18CycleDayInterval],
        currentRegion: Prompt18WheelRegionKind?,
        currentPositionFraction: Double?,
        confidence: Prompt17PredictionConfidence,
        dataSufficiency: Prompt17DataSufficiency,
        historyVersion: String
    ) {
        self.representedCycleLength = representedCycleLength
        self.currentCycleDay = currentCycleDay
        self.baseSegments = baseSegments
        self.fertileOverlay = fertileOverlay
        self.unresolvedIntervals = unresolvedIntervals
        self.currentRegion = currentRegion
        self.currentPositionFraction = currentPositionFraction
        self.confidence = confidence
        self.dataSufficiency = dataSufficiency
        self.historyVersion = historyVersion
    }

    public var hasPersonalizedGeometry: Bool {
        representedCycleLength != nil && !baseSegments.isEmpty
    }

    public var hasEstimatedOvulation: Bool {
        baseSegments.contains { $0.kind == .estimatedOvulation }
    }

    public var hasEstimatedFertileWindow: Bool {
        fertileOverlay != nil
    }
}

