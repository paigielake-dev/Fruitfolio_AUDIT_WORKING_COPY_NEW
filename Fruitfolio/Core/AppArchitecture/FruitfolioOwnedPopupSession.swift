import Foundation

/// Ownership of one current/queued request. A departing feature cannot dismiss
/// someone else's popup, and an old/queued action cannot mutate feature state.
@MainActor
final class FruitfolioOwnedPopupSession {
    private let coordinator: PopupCoordinator
    private(set) var requestID: UUID?
    init(coordinator: PopupCoordinator) { self.coordinator = coordinator }

    func present(_ build: (UUID) -> FruitPopupRequest) {
        // A rapid second press must not cancel the first request then lose its
        // replacement to the coordinator's still-active deduplication key.
        if let id = requestID, coordinator.containsRequest(id: id) { return }
        cancel()
        let id = UUID()
        let request = build(id)
        precondition(request.id == id, "Owned request must use its allocated identity")
        requestID = id
        coordinator.request(request)
    }
    func consumeAction(for id: UUID) -> Bool {
        guard requestID == id, coordinator.currentPopup?.id == id,
              coordinator.presentationState != .dismissing else { return false }
        coordinator.cancelRequest(id: id)
        return true
    }
    func observeDismissal() {
        if let id = requestID, !coordinator.containsRequest(id: id) { requestID = nil }
    }
    func cancel() {
        if let id = requestID { coordinator.cancelRequest(id: id) }
        requestID = nil
    }
}
