import Foundation

/// In-memory edit intent; never popup metadata, analytics or a saved record.
struct FruitfolioUsernameSaveIntent: Sendable {
    let raw: String
    let confirmedNonIdentifying: Bool
    let expected: FruitfolioUsernamePersistence.Snapshot
    let identifyingText: [String]
    init(raw: String, confirmedNonIdentifying: Bool, expected: FruitfolioUsernamePersistence.Snapshot,
         identifyingText: [String] = []) {
        self.raw = raw
        self.confirmedNonIdentifying = confirmedNonIdentifying
        self.expected = expected
        self.identifyingText = identifyingText
    }
    @MainActor
    func commit(to store: FruitfolioUsernameStore) -> String? {
        store.setUsername(raw, confirmedNonIdentifying: confirmedNonIdentifying,
            identifyingText: identifyingText, expecting: expected)
    }
}

/// Owns one username exit question. Its choice is delivered only after the
/// actual coordinator finishes dismissal; cancellation discards pending work.
@MainActor
final class FruitfolioUsernameExitSession {
    enum Choice {
        case keepEditing
        case save(FruitfolioUsernameSaveIntent)
        case discard
        case review
    }
    private let coordinator: PopupCoordinator
    private let owner: FruitfolioOwnedPopupSession
    private let scope = UUID()
    private var pending: Choice?
    var requestID: UUID? { owner.requestID }
    init(coordinator: PopupCoordinator) {
        self.coordinator = coordinator
        owner = FruitfolioOwnedPopupSession(coordinator: coordinator)
    }
    func present(intent: FruitfolioUsernameSaveIntent, canSave: Bool) {
        if pending != nil { return }
        if let id = owner.requestID, coordinator.containsRequest(id: id) { return }
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: canSave
                    ? "**unsaved username**\n\nyour username edit has not been saved. save it, discard only this edit, or keep editing. game progress and other saved information are separate."
                    : "**unsaved username**\n\nthe saved username record is protected. review it, discard only this edit, or keep editing. other saved information stays in place.",
                primaryAction: .init(label: "keep editing") { self.choose(.keepEditing, id: id) },
                secondaryAction: .init(label: canSave ? "save + leave" : "review saved username") {
                    self.choose(canSave ? .save(intent) : .review, id: id)
                },
                tertiaryAction: .init(label: "discard edit + leave") { self.choose(.discard, id: id) },
                dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "game-username-exit", deduplicationKey: "game-username-exit-" + scope.uuidString,
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
