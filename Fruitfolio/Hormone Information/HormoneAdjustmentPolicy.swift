import Foundation

/// A request is not scientific permission to adjust a curve. No reviewed,
/// versioned adjustment method with required contexts/units is bundled yet.
/// Keep this gate closed instead of normalizing laboratory values onto the
/// unrelated, unitless educational curve or synthesizing missing levels.
nonisolated enum FruitfolioHormoneAdjustmentPolicy {
    enum Decision: Equatable, Sendable {
        case original
        case measurementsUnavailable
        case noMeasurements
        case reviewedMethodUnavailable
        var appliesAdjustment: Bool { false }
    }
    static func decision(requested: Bool, measurementCount: Int, storageUnreadable: Bool) -> Decision {
        guard requested else { return .original }
        guard !storageUnreadable else { return .measurementsUnavailable }
        guard measurementCount > 0 else { return .noMeasurements }
        return .reviewedMethodUnavailable
    }
    static func presentation(preserving original: Prompt22HormoneRhythmPresentation, decision: Decision) -> Prompt22HormoneRhythmPresentation {
        // No decision currently permits altering an educational relationship,
        // marker, source, measured concentration or prediction confidence.
        original
    }
    static let insufficientTitle = "a little note! ☆"
    static let insufficientMessage = "your measurement has been saved, but there isn’t enough information to adjust this illustration reliably. you can still explore the typical hormone rhythm and view your actual result in my measurements."
    // Required text is reserved for an actually applied, reviewed adjustment.
    // It must never appear as a claim that this unavailable flow changed curves.
    static let appliedDisclosureTitle = "your hormone rhythm <3"
    static let appliedDisclosure = "this educational illustration has been adjusted using your recorded hormone information. the curves show possible hormonal patterns, not your measured hormone levels. actual hormone concentrations may differ."
}
