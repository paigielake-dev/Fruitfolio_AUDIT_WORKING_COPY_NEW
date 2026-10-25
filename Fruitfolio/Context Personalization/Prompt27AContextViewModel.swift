#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt27AContextViewModel: ObservableObject {
    @Published private(set) var policy: Prompt27AContextPolicyResult

    let store: Prompt27AContextStore
    private let policyEngine: Prompt27AContextPolicyEngine
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: Prompt27AContextStore,
        policyEngine: Prompt27AContextPolicyEngine? = nil
    ) {
        self.store = store
        let engine = policyEngine ?? Prompt27AContextPolicyEngine()
        self.policyEngine = engine
        self.policy = engine.policy(for: store.context)

        store.$context
            .dropFirst()
            .sink { [weak self] context in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.policy = self.policyEngine.policy(for: context)
                }
            }
            .store(in: &cancellables)
    }
}
#endif
