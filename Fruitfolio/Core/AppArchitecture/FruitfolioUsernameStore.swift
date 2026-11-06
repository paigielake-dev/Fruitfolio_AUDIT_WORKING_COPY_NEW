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
    #if canImport(Combine)
    @Published
    #endif
    private(set) var persistenceMessage: String?
    var canPersistUsername: Bool { persistenceMessage == nil }
    var snapshot: FruitfolioUsernamePersistence.Snapshot {
        .init(username: username, confirmedNonIdentifying: confirmedNonIdentifying)
    }
    private let persistence: FruitfolioUsernamePersistence

    init(defaults: UserDefaults = .standard, key: String = FruitfolioUsernamePersistence.defaultKey) {
        let persistence = FruitfolioUsernamePersistence(defaults: defaults, key: key)
        self.persistence = persistence
        let saved = persistence.load()
        username = saved.username
        confirmedNonIdentifying = saved.confirmedNonIdentifying
        persistenceMessage = persistence.storageIssue
    }

    @discardableResult
    func setUsername(_ raw: String, confirmedNonIdentifying: Bool, identifyingText: [String] = [],
                     expecting: FruitfolioUsernamePersistence.Snapshot? = nil) -> String? {
        if let expecting, expecting != snapshot {
            return "the saved username changed. your edit is still here; review the current name and confirm your edit again."
        }
        if let message = persistence.save(raw, confirmedNonIdentifying: confirmedNonIdentifying, identifyingText: identifyingText) {
            refresh()
            return message
        }
        refresh()
        return nil
    }
    #if DEBUG
    /// Actual persistence readback for a registered disposable username QA scene.
    var debugStoredUsername: FruitfolioUsernamePersistence.Snapshot { persistence.inspect() }
    #endif
    func reloadSavedUsername() { refresh() }
    @discardableResult
    func clear() -> String? {
        let message = persistence.clear()
        refresh()
        return message
    }
    private func refresh() {
        let saved = persistence.load()
        username = saved.username
        confirmedNonIdentifying = saved.confirmedNonIdentifying
        persistenceMessage = persistence.storageIssue
    }
}

#if canImport(Combine)
extension FruitfolioUsernameStore: ObservableObject {}
#endif
