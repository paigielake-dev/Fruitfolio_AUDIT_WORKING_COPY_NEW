import Foundation

/// Measurement references never become estimates of unmeasured concentrations.
/// The current approved research package has no validated quantitative calibration
/// contract for deriving personal curves. That dependency is explicit, not filled
/// with guessed coefficients or a curve fitted through laboratory results.
nonisolated enum Prompt22RhythmMode: String, CaseIterable, Identifiable, Hashable, Sendable {
    case typical, adjusted, measurements
    var id: String { rawValue }
    var title: String {
        switch self {
        case .typical: return "hormone rhythm"
        case .adjusted: return "adjusted rhythm"
        case .measurements: return "my measurements"
        }
    }
}

nonisolated enum Prompt22AdjustmentAssessment: Equatable, Sendable {
    case notRequested, noRecordedMeasurements, approvedCalibrationUnavailable
}

nonisolated struct Prompt22MeasurementPresentationPolicy {
    static let insufficientTitle = "a little note! ☆"
    static let insufficientMessage = "your measurement has been saved, but there isn’t enough information to adjust this illustration reliably. you can still explore the typical hormone rhythm and view your actual result in my measurements."

    static func assessment(requested: Bool, measurements: [HormoneMeasurement]) -> Prompt22AdjustmentAssessment {
        guard requested else { return .notRequested }
        guard !measurements.isEmpty else { return .noRecordedMeasurements }
        return .approvedCalibrationUnavailable
    }

    /// No interpolated samples, synthesized values, normal ranges or converted
    /// units are introduced. Original records remain the source of truth.
    static func orderedReferences(_ measurements: [HormoneMeasurement]) -> [HormoneMeasurement] {
        measurements.sorted {
            if $0.testDate != $1.testDate { return $0.testDate < $1.testDate }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
