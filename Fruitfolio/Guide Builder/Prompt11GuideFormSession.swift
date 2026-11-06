import Foundation
#if canImport(Combine)
import Combine
#endif

nonisolated struct Prompt11GuideFormTicket: Equatable, Sendable {
    fileprivate let id: UUID
}
nonisolated enum Prompt11GuideFormCue: Equatable, Sendable { case open, close }

/// Ephemeral ownership of the actual notebook form. No saved-data schema or
/// health content is added. Background suspension retains the form/draft but
/// invalidates callbacks captured by its previous visible presentation.
@MainActor
final class Prompt11GuideFormSession {
    private struct State {
        var overlay: Prompt11Overlay?
        var ticket: Prompt11GuideFormTicket?
        var active = true
    }
    #if canImport(Combine)
    @Published
    #endif
    private var state = State()
    var current: Prompt11Overlay? { state.overlay }
    var ticket: Prompt11GuideFormTicket? { state.ticket }
    func isCurrent(_ ticket: Prompt11GuideFormTicket?) -> Bool {
        state.active && state.overlay != nil && ticket != nil && state.ticket == ticket
    }
    @discardableResult
    func transition(to next: Prompt11Overlay?) -> [Prompt11GuideFormCue] {
        guard state.active, state.overlay != next else { return [] }
        var cues: [Prompt11GuideFormCue] = []
        if state.overlay != nil { cues.append(.close) }
        if next != nil { cues.append(.open) }
        state = State(overlay: next, ticket: next.map { _ in .init(id: UUID()) })
        return cues
    }
    func suspend() {
        guard state.active else { return }
        state = State(overlay: state.overlay, ticket: nil, active: false)
    }
    func resume() {
        guard !state.active else { return }
        state = State(overlay: state.overlay, ticket: state.overlay.map { _ in .init(id: UUID()) })
    }
}
#if canImport(Combine)
extension Prompt11GuideFormSession: ObservableObject {}
#endif
