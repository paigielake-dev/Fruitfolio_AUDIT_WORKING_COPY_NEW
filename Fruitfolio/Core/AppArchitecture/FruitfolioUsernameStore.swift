import Foundation
#if canImport(Combine)
import Combine
#endif

/// Shared local pseudonym authority. No health/cycle data or remote reservation.
@MainActor
final class FruitfolioUsernameStore {
    static let shared = FruitfolioUsernameStore()
    #if canImport(Combine)
    @Published
    #endif
    private(set) var username: String
    #if canImport(Combine)
    @Published
    #endif
    private(set) var confirmedNonIdentifying: Bool
    private let persistence: FruitfolioUsernamePersistence

    init(defaults: UserDefaults = .standard, key: String = "fruitfolio.identity.publicUsername.v1") {
        let persistence = FruitfolioUsernamePersistence(defaults: defaults, key: key)
        self.persistence = persistence
        let saved = persistence.load()
        username = saved.username
        confirmedNonIdentifying = saved.confirmedNonIdentifying
    }

    @discardableResult
    func setUsername(_ raw: String, confirmedNonIdentifying: Bool, identifyingText: [String] = []) -> String? {
        if let message = persistence.save(raw, confirmedNonIdentifying: confirmedNonIdentifying, identifyingText: identifyingText) { return message }
        refresh()
        return nil
    }
    #if DEBUG
    /// Actual persistence readback for a registered disposable username QA scene.
    var debugStoredUsername: FruitfolioUsernamePersistence.Snapshot { persistence.load() }
    #endif
    func clear() { persistence.clear(); refresh() }
    private func refresh() {
        let saved = persistence.load()
        username = saved.username
        confirmedNonIdentifying = saved.confirmedNonIdentifying
    }
}

#if canImport(Combine)
extension FruitfolioUsernameStore: ObservableObject {}
#endif
