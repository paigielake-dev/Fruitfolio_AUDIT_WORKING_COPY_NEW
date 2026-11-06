import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
final class Prompt12AccountPrivacyStore {
    static let shared = Prompt12AccountPrivacyStore()

    #if canImport(Combine)
    @Published
    #endif
    private(set) var ownershipState: Prompt12OwnershipState
    #if canImport(Combine)
    @Published
    #endif
    private(set) var ownershipValidationMessage: String? = nil
    #if canImport(Combine)
    @Published
    #endif
    private(set) var authenticationState: Prompt12AuthenticationState
    #if canImport(Combine)
    @Published
    #endif
    private(set) var syncState: Prompt12SyncState
    #if canImport(Combine)
    @Published
    #endif
    private(set) var account: Prompt12AccountIdentity?
    #if canImport(Combine)
    @Published
    #endif
    private(set) var lastExport: Prompt12DataExportRecord?
    #if canImport(Combine)
    @Published
    #endif
    private(set) var pendingLocalChanges: Bool
    #if canImport(Combine)
    @Published
    #endif
    private(set) var localDataContainerID: UUID
    #if canImport(Combine)
    @Published
    #endif
    var usePrivacyModeOnLockScreen: Bool {
        didSet {
            guard !isRestoringSnapshot else { return }
            guard checkPersistenceWritable() else {
                usePrivacyModeOnLockScreen = oldValue
                return
            }
            if !saveSnapshot() { usePrivacyModeOnLockScreen = oldValue }
        }
    }

    #if canImport(Combine)
    @Published
    #endif
    private(set) var persistenceRecoveryMessage: String? = nil
    var canPersistAccountChanges: Bool { persistenceRecoveryMessage == nil }


    private let defaults: UserDefaults
    private let persistenceKey: String
    private let ownershipVerifier: any FruitfolioOwnershipVerifying
    private let expectedBundleIdentifier: String?
    private var ownershipValidationTask: Task<Void, Never>?
    private var ownershipGeneration = UUID()
    private var expectedPersistedObject: NSObject?
    private var isRestoringSnapshot = false

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "fruitfolio.prompt12.accountPrivacy.v1",
        ownershipVerifier: any FruitfolioOwnershipVerifying = FruitfolioStoreKitOwnershipVerifier(),
        expectedBundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) {
        self.defaults = defaults
        self.persistenceKey = persistenceKey
        self.ownershipVerifier = ownershipVerifier
        self.expectedBundleIdentifier = expectedBundleIdentifier
        self.expectedPersistedObject = defaults.object(forKey: persistenceKey) as? NSObject

        if let data = defaults.data(forKey: persistenceKey),
           let snapshot = Self.readableSnapshot(data) {
            ownershipState = snapshot.ownershipState == .validating ? .validationUnavailable : snapshot.ownershipState
            authenticationState = Prompt12SessionRestorationPolicy.authentication(snapshot.authenticationState,
                                                                                  hasLocalAccount: snapshot.account != nil)
            syncState = Prompt12SessionRestorationPolicy.sync(snapshot.syncState)
            account = snapshot.account
            lastExport = snapshot.lastExport
            pendingLocalChanges = snapshot.pendingLocalChanges
            localDataContainerID = snapshot.localDataContainerID
            usePrivacyModeOnLockScreen = snapshot.usePrivacyModeOnLockScreen
        } else {
            ownershipState = .purchased
            authenticationState = .signedOut
            syncState = .localOnly
            account = nil
            lastExport = nil
            pendingLocalChanges = false
            localDataContainerID = UUID()
            usePrivacyModeOnLockScreen = true
            if expectedPersistedObject != nil {
                persistenceRecoveryMessage = "the saved account/settings record is unreadable or uses a newer format. it has been preserved. account changes are paused; other local features remain available."
            }
        }
    }

    var isSignedIn: Bool {
        authenticationState == .signedIn && account != nil
    }

    var accountDisplayName: String {
        account?.username ?? "local Fruitfolio"
    }

    var ownershipDisplayText: String {
        ownershipState.displayTitle
    }

    deinit { ownershipValidationTask?.cancel() }

    /// Compatibility entry point performs verification rather than fabricating
    /// a new receipt. Installed paid-app access remains independent of this check.
    func markPurchasedForInstalledApp() { _ = beginQuietOwnershipValidation() }

    @discardableResult
    func beginQuietOwnershipValidation() -> Task<Void, Never> {
        if let ownershipValidationTask { return ownershipValidationTask }
        guard checkPersistenceWritable() else {
            ownershipState = .validationUnavailable
            ownershipValidationMessage = persistenceRecoveryMessage
            return Task {}
        }
        ownershipValidationMessage = nil
        ownershipGeneration = UUID()
        let generation = ownershipGeneration
        let verifier = ownershipVerifier
        let bundleIdentifier = expectedBundleIdentifier
        ownershipState = .validating
        saveSnapshot()
        let expectedBytes = defaults.data(forKey: persistenceKey)
        let task = Task { [weak self] in
            let result: FruitfolioOwnershipVerification
            if let bundleIdentifier {
                result = await verifier.verify(expectedBundleIdentifier: bundleIdentifier)
            } else { result = .unavailable }
            guard let self, self.ownershipGeneration == generation else { return }
            self.ownershipValidationTask = nil
            guard let expectedBytes, self.defaults.data(forKey: self.persistenceKey) == expectedBytes else {
                _ = self.checkPersistenceWritable()
                self.ownershipState = .validationUnavailable
                self.ownershipValidationMessage = "the local account/settings record changed during this check. the newer record was preserved; try again when ready."
                return
            }
            guard !Task.isCancelled else {
                self.ownershipState = .validationUnavailable
                self.ownershipValidationMessage = "ownership checking was cancelled. local features remain available."
                _ = self.saveSnapshot()
                return
            }
            switch result {
            case .verifiedProductionInstallation: self.ownershipState = .purchased
            case .verifiedTestInstallation: self.ownershipState = .verifiedTestInstallation
            case .unverified, .unavailable: self.ownershipState = .validationUnavailable
            }
            _ = self.saveSnapshot()
        }
        ownershipValidationTask = task
        return task
    }

    func requestSignIn(email: String) throws {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Prompt12AccountPrivacyError.blankEmail
        }
        // No approved authentication service is configured in this project.
        // Never turn an email address into a fabricated authenticated session.
        throw Prompt12AccountPrivacyError.serviceNotConfigured
    }

    func signInForDevelopment(
        email rawEmail: String,
        provider: String = "demo"
    ) throws {
        #if !DEBUG
        throw Prompt12AccountPrivacyError.serviceNotConfigured
        #else
        guard checkPersistenceWritable() else { throw Prompt12AccountPrivacyError.localRecordProtected }
        let cleanEmail = rawEmail.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanEmail.isEmpty else {
            authenticationState = .signInFailed
            saveSnapshot()
            throw Prompt12AccountPrivacyError.blankEmail
        }

        authenticationState = .signingIn
        syncState = .syncing
        saveSnapshot()

        let username = cleanEmail
            .split(separator: "@")
            .first
            .map(String.init) ?? "Fruitfolio friend"

        account = Prompt12AccountIdentity(
            provider: provider,
            email: cleanEmail,
            username: username
        )

        authenticationState = .signedIn
        syncState = .synced
        pendingLocalChanges = false
        saveSnapshot()
        #endif
    }

    func markLocalChangePending() {
        guard checkPersistenceWritable() else { return }
        pendingLocalChanges = true
        syncState = isSignedIn ? .pendingLocalChanges : .localOnly
        saveSnapshot()
    }

    var accountActionSnapshot: Prompt12AccountActionSnapshot {
        Prompt12AccountActionSnapshot(account: account, authenticationState: authenticationState,
            pendingLocalChanges: pendingLocalChanges, localDataContainerID: localDataContainerID)
    }

    private func requireAccountAction(_ expected: Prompt12AccountActionSnapshot?) throws {
        guard checkPersistenceWritable() else { throw Prompt12AccountPrivacyError.localRecordProtected }
        if let expected, accountActionSnapshot != expected { throw Prompt12AccountPrivacyError.accountChanged }
    }

    @discardableResult
    func syncNow() -> Bool {
        guard checkPersistenceWritable() else { return false }
        // Keep pending edits: there is no configured/acknowledged cloud upload.
        let previous = syncState
        syncState = isSignedIn ? .unavailable : .localOnly
        guard saveSnapshot() else { syncState = previous; return false }
        return true
    }

    func attemptSyncNow(expecting expected: Prompt12AccountActionSnapshot) throws {
        try requireAccountAction(expected)
        guard isSignedIn else { throw Prompt12AccountPrivacyError.notSignedIn }
        guard syncNow() else { throw Prompt12AccountPrivacyError.localRecordProtected }
        throw Prompt12AccountPrivacyError.serviceNotConfigured
    }

    func signOut(
        keepLocalData: Bool = true,
        expecting expected: Prompt12AccountActionSnapshot? = nil
    ) throws {
        try requireAccountAction(expected)
        guard keepLocalData else { throw Prompt12AccountPrivacyError.localDataDeletionRequiresReview }
        let previousAccount = account
        let previousAuthentication = authenticationState
        let previousSync = syncState
        account = nil
        authenticationState = .signedOut
        syncState = .localOnly
        // Signing out is not an upload acknowledgment. Keep the pending marker
        // and local container identity along with the actual local health files.
        guard saveSnapshot() else {
            account = previousAccount
            authenticationState = previousAuthentication
            syncState = previousSync
            throw Prompt12AccountPrivacyError.localRecordProtected
        }
    }

    func deleteAccountAndAssociatedRemoteData(expecting expected: Prompt12AccountActionSnapshot? = nil) throws {
        try requireAccountAction(expected)
        guard account != nil else { throw Prompt12AccountPrivacyError.notSignedIn }
        // A local mutation cannot prove an unconfigured remote account was erased.
        throw Prompt12AccountPrivacyError.remoteDeletionUnavailable
    }

    func resetLocalAccountPrivacyStateForTesting() {
        guard checkPersistenceWritable() else { return }
        ownershipGeneration = UUID()
        ownershipValidationTask?.cancel()
        ownershipValidationTask = nil
        ownershipState = .purchased
        authenticationState = .signedOut
        syncState = .localOnly
        account = nil
        lastExport = nil
        pendingLocalChanges = false
        localDataContainerID = UUID()
        usePrivacyModeOnLockScreen = true
        saveSnapshot()
    }

    @discardableResult
    private func saveSnapshot() -> Bool {
        guard checkPersistenceWritable() else { return false }
        let snapshot = Prompt12StoreSnapshot(
            ownershipState: ownershipState,
            authenticationState: authenticationState,
            syncState: syncState,
            account: account,
            lastExport: lastExport,
            pendingLocalChanges: pendingLocalChanges,
            localDataContainerID: localDataContainerID,
            usePrivacyModeOnLockScreen: usePrivacyModeOnLockScreen
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: persistenceKey)
        guard defaults.data(forKey: persistenceKey) == data else {
            persistenceRecoveryMessage = "the account/settings update could not be acknowledged locally. reload the saved record before making another change."
            return false
        }
        expectedPersistedObject = data as NSData
        return true
    }

    /// Read the latest record explicitly; never restore/repair by writing defaults.
    func reloadSavedAccountState() {
        ownershipGeneration = UUID()
        ownershipValidationTask?.cancel()
        ownershipValidationTask = nil
        let fresh = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: persistenceKey,
            ownershipVerifier: ownershipVerifier, expectedBundleIdentifier: expectedBundleIdentifier)
        isRestoringSnapshot = true
        ownershipState = fresh.ownershipState
        ownershipValidationMessage = nil
        authenticationState = fresh.authenticationState
        syncState = fresh.syncState
        account = fresh.account
        lastExport = fresh.lastExport
        pendingLocalChanges = fresh.pendingLocalChanges
        localDataContainerID = fresh.localDataContainerID
        usePrivacyModeOnLockScreen = fresh.usePrivacyModeOnLockScreen
        expectedPersistedObject = fresh.expectedPersistedObject
        persistenceRecoveryMessage = fresh.persistenceRecoveryMessage
        isRestoringSnapshot = false
    }

    private func checkPersistenceWritable() -> Bool {
        guard persistenceRecoveryMessage == nil else { return false }
        let current = defaults.object(forKey: persistenceKey) as? NSObject
        guard current == expectedPersistedObject else {
            persistenceRecoveryMessage = "the saved account/settings record changed or was cleared elsewhere. the latest record has been preserved. reload the saved record before making account changes."
            return false
        }
        return true
    }

    /// Codable ignores unknown keys. Refuse to rewrite such records because a
    /// newer app may depend on fields this version cannot round-trip.
    private static func readableSnapshot(_ data: Data) -> Prompt12StoreSnapshot? {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(object.keys).isSubset(of: ["ownershipState", "authenticationState", "syncState", "account", "lastExport",
                  "pendingLocalChanges", "localDataContainerID", "usePrivacyModeOnLockScreen"]) else { return nil }
        for (name, keys) in [
            ("account", Set(["accountID", "provider", "email", "username", "createdAt", "updatedAt"])),
            ("lastExport", Set(["id", "createdAt", "scopes", "summary"]))
        ] {
            if let nested = object[name] as? [String: Any], !Set(nested.keys).isSubset(of: keys) { return nil }
        }
        guard let snapshot = try? JSONDecoder().decode(Prompt12StoreSnapshot.self, from: data),
              let encoded = try? JSONEncoder().encode(snapshot),
              FruitfolioJSONFieldCoverage.preservesFields(original: data, encoded: encoded) else { return nil }
        return snapshot
    }
}

#if canImport(Combine)
extension Prompt12AccountPrivacyStore: ObservableObject {}
#endif

private struct Prompt12StoreSnapshot: Codable, Equatable, Sendable {
    var ownershipState: Prompt12OwnershipState
    var authenticationState: Prompt12AuthenticationState
    var syncState: Prompt12SyncState
    var account: Prompt12AccountIdentity?
    var lastExport: Prompt12DataExportRecord?
    var pendingLocalChanges: Bool
    var localDataContainerID: UUID
    var usePrivacyModeOnLockScreen: Bool
}
