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
            saveSnapshot()
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
                self.saveSnapshot()
                return
            }
            switch result {
            case .verifiedProductionInstallation: self.ownershipState = .purchased
            case .verifiedTestInstallation: self.ownershipState = .verifiedTestInstallation
            case .unverified, .unavailable: self.ownershipState = .validationUnavailable
            }
            self.saveSnapshot()
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

    func syncNow() {
        guard checkPersistenceWritable() else { return }
        // Keep pending local edits. Successful cloud synchronization requires a
        // configured service and an acknowledged upload, neither exists here.
        syncState = isSignedIn ? .unavailable : .localOnly
        saveSnapshot()
    }

    func signOut(
        keepLocalData: Bool = true
    ) throws {
        guard checkPersistenceWritable() else { throw Prompt12AccountPrivacyError.localRecordProtected }
        guard account != nil else {
            authenticationState = .signedOut
            syncState = .localOnly
            saveSnapshot()
            return
        }

        authenticationState = .signingOut
        saveSnapshot()

        account = nil
        authenticationState = .signedOut
        syncState = keepLocalData ? .localOnly : .localOnly
        pendingLocalChanges = false
        saveSnapshot()
    }

    func prepareDataExport() throws -> Prompt12DataExportRecord {
        // A summary/metadata record is not an exported user-data document.
        // Keep existing historical metadata, but never fabricate a new success.
        throw Prompt12AccountPrivacyError.consolidatedExportUnavailable
    }

    func deleteAccountAndAssociatedRemoteData() throws {
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

    private func saveSnapshot() {
        guard checkPersistenceWritable() else { return }
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

        guard let data = try? JSONEncoder().encode(snapshot) else {
            return
        }

        defaults.set(data, forKey: persistenceKey)
        expectedPersistedObject = data as NSData
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
        return try? JSONDecoder().decode(Prompt12StoreSnapshot.self, from: data)
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
