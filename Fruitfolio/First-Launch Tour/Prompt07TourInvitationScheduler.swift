import Combine
import Foundation

/// One cancellable invitation per visible/active Hub. Cancellation invalidates
/// identity as well as the task: a delayed continuation from an old visit must
/// never deliver or clear a newer visit's pending invitation.
@MainActor
final class Prompt07TourInvitationScheduler: ObservableObject {
    private var task: Task<Void, Never>?
    private var generation: UUID?
    private let wait: @MainActor () async throws -> Void

    init(wait: @escaping @MainActor () async throws -> Void = {
        try await Task.sleep(nanoseconds: 600_000_000)
    }) {
        self.wait = wait
    }

    var isScheduled: Bool { task != nil }

    func schedule(eligible: @escaping @MainActor () -> Bool,
                  deliver: @escaping @MainActor () -> Void) {
        guard task == nil, eligible() else { return }
        let expected = UUID()
        generation = expected
        let wait = self.wait
        task = Task { @MainActor [weak self] in
            do { try await wait() }
            catch {
                guard self?.generation == expected else { return }
                self?.task = nil; self?.generation = nil
                return
            }
            guard !Task.isCancelled, let self, self.generation == expected else { return }
            self.task = nil; self.generation = nil
            guard eligible() else { return }
            deliver()
        }
    }

    func cancel() {
        generation = nil
        task?.cancel()
        task = nil
    }

    deinit { task?.cancel() }
}
