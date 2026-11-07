import Foundation

/// An in-memory reset target, never saved or included in popup metadata.
nonisolated struct Prompt28LevelResetContext: Equatable, Sendable {
    let normalizedTopic: String
    let sessionID: UUID?
    let origin: Prompt28ScreenState
    var isEligible: Bool {
        !normalizedTopic.isEmpty && (origin == .paused || origin == .basketReveal)
    }
    func matches(_ current: Self) -> Bool { isEligible && self == current }
}

/// A choice is available once, only after the actual shared host dismisses.
/// Queued/stale callbacks cannot reset a later topic or replace another choice.
@MainActor
final class Prompt28LevelResetSession {
    enum Choice { case cancel, reset(Prompt28LevelResetContext) }
    /// A level/speed reset has a narrower scope than deleting learning or
    /// scores. These roles annotate this full authored explanation only.
    static let messageSpans: [FruitfolioSemanticSpan] = [
        .init(text: "start this topic’s game level over?", emphasis: .anchorBold),
        .init(text: "\n\nthe catching will go back to the "),
        .init(text: "gentlest level", emphasis: .anchorBold),
        .init(text: ". your learning topic, question difficulty, saved encyclopedia entries, and scores "),
        .init(text: "won’t disappear", emphasis: .symptomOrPracticalUnderline),
        .init(text: ".")
    ]
    private let coordinator: PopupCoordinator
    private let owner: FruitfolioOwnedPopupSession
    private let scope = UUID()
    private var pending: Choice?
    var requestID: UUID? { owner.requestID }
    init(coordinator: PopupCoordinator) {
        self.coordinator = coordinator
        owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
    }
    func present(context: Prompt28LevelResetContext) {
        guard context.isEligible, pending == nil else { return }
        if let id = owner.requestID, coordinator.containsRequest(id: id) { return }
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: FruitfolioSemanticMarkup.markdown(
                    FruitfolioSemanticPolicy.normalized(Self.messageSpans, serious: true)),
                primaryAction: .init(label: "never mind") { self.choose(.cancel, id: id) },
                secondaryAction: .init(label: "yes, reset level") { self.choose(.reset(context), id: id) },
                dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "fruit-basket-level-reset", deduplicationKey: "fruit-basket-level-reset-" + scope.uuidString,
                surface: .tapedWhite)
        }
    }
    private func choose(_ choice: Choice, id: UUID) {
        guard owner.consumeAction(for: id) else { return }
        pending = choice
    }
    func takeCompletedChoice() -> Choice? {
        owner.observeDismissal()
        guard owner.requestID == nil, coordinator.currentPopup == nil else { return nil }
        defer { pending = nil }
        return pending
    }
    func cancel() {
        pending = nil
        owner.cancel()
    }
}
