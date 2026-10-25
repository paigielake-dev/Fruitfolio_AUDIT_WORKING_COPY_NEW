import Foundation

nonisolated enum Prompt15CycleSection: String, CaseIterable, Identifiable, Sendable {
    case today
    case calendar
    case body
    case symptoms
    case trends

    var id: String { rawValue }
}
