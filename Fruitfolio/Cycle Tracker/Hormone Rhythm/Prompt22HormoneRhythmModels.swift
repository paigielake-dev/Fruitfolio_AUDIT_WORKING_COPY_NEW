import Foundation

nonisolated enum Prompt22Hormone: String, CaseIterable, Identifiable, Sendable {
    case estrogen
    case progesterone
    case testosterone

    var id: String { rawValue }
}

nonisolated enum Prompt22CycleContext: String, Equatable, Sendable {
    case insufficient
    case menstruation
    case follicularEarly
    case follicularLater
    case estimatedOvulation
    case luteal
    case alteredNaturalCycleContext
}

nonisolated enum Prompt22ContextKind: String, Equatable, Sendable {
    case educational
    case calculated
    case estimated
}

nonisolated enum Prompt22Confidence: String, Equatable, Sendable {
    case limited
    case developing
    case strong
    case unavailable
}

nonisolated struct Prompt22HormoneEducationalCopy: Equatable, Sendable {
    let summary: String
    let researchIDs: [String]

    init(
        summary: String,
        researchIDs: [String] = []
    ) {
        self.summary = summary
        self.researchIDs = researchIDs
    }
}

nonisolated struct Prompt22HormoneRhythmInput: Equatable, Sendable {
    let context: Prompt22CycleContext
    let contextKind: Prompt22ContextKind
    let cycleDay: Int?
    let estimatedCycleLength: Int?
    let estimatedCycleProgress: Double?
    let confidence: Prompt22Confidence
    let personalizationPermitted: Bool
    let measuredHormoneDataAvailable: Bool
    let copyByHormone: [Prompt22Hormone: Prompt22HormoneEducationalCopy]

    init(
        context: Prompt22CycleContext,
        contextKind: Prompt22ContextKind,
        cycleDay: Int?,
        estimatedCycleLength: Int? = nil,
        estimatedCycleProgress: Double? = nil,
        confidence: Prompt22Confidence,
        personalizationPermitted: Bool,
        measuredHormoneDataAvailable: Bool = false,
        copyByHormone: [Prompt22Hormone: Prompt22HormoneEducationalCopy] = [:]
    ) {
        self.context = context
        self.contextKind = contextKind
        self.cycleDay = cycleDay
        self.estimatedCycleLength = estimatedCycleLength
        self.estimatedCycleProgress = estimatedCycleProgress
        self.confidence = confidence
        self.personalizationPermitted = personalizationPermitted
        self.measuredHormoneDataAvailable = measuredHormoneDataAvailable
        self.copyByHormone = copyByHormone
    }

    static let neutral = Prompt22HormoneRhythmInput(
        context: .insufficient,
        contextKind: .educational,
        cycleDay: nil,
        confidence: .unavailable,
        personalizationPermitted: false
    )
}

nonisolated struct Prompt22NormalizedPoint: Equatable, Sendable {
    let x: Double
    let y: Double
}

/// Presentation geometry for the "around where you may be" indicator.
/// `x` is estimated cycle-timeline position. `y` is obtained only by
/// interpolating the educational curve at that x-position; it is never a
/// measured, inferred, or predicted hormone concentration.
nonisolated struct Prompt22ContextMarker: Equatable, Sendable {
    let x: Double
    let y: Double
    let confidence: Prompt22Confidence
}

nonisolated struct Prompt22HormoneSectionPresentation: Equatable, Sendable {
    let hormone: Prompt22Hormone
    let assetName: String
    let title: String
    let summary: String
    let accessibilitySummary: String
    let pattern: [Prompt22NormalizedPoint]
    let marker: Prompt22ContextMarker?
    let researchIDs: [String]
}

nonisolated struct Prompt22HormoneRhythmPresentation: Equatable, Sendable {
    let title: String
    let subtitle: String
    let contextNote: String?
    let sections: [Prompt22HormoneSectionPresentation]
    let showsContextMarker: Bool
}

nonisolated enum Prompt22HormoneAsset {
    static let estrogen = "hormone_estrogen"
    static let progesterone = "hormone_progesterone"
    static let testosterone = "hormone_testosterone"
    static let increaseArrow = "hormone_increase_arrow"
    static let decreaseArrow = "hormone_decrease_arrow"
    static let bloodCells = "hormone_blood_cells"
    static let accentMarks = "hormone_accent_marks"

    static let allCanonicalAssetNames: [String] = [
        estrogen,
        decreaseArrow,
        progesterone,
        testosterone,
        increaseArrow,
        bloodCells,
        accentMarks
    ]
}
