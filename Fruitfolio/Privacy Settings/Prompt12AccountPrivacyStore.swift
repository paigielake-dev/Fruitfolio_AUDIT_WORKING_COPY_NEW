import Foundation
import Combine

@MainActor
final class Prompt12AccountPrivacyStore: ObservableObject {
    static let shared = Prompt12AccountPrivacyStore()

    @Published private(set) var ownershipState: Prompt12OwnershipState
    @Published private(set) var ownershipValidationMessage: String? = nil
    @Published private(set) var authenticationState: Prompt12AuthenticationState
    @Published private(set) var syncState: Prompt12SyncState
    @Published private(set) var account: Prompt12AccountIdentity?
    @Published private(set) var lastExport: Prompt12DataExportRecord?
    @Published private(set) var pendingLocalChanges: Bool
    @Published private(set) var localDataContainerID: UUID
    @Published var usePrivacyModeOnLockScreen: Bool

    private let defaults: UserDefaults
    private let persistenceKey: String
    private let ownershipVerifier: any FruitfolioOwnershipVerifying
    private let expectedBundleIdentifier: String?
    private var ownershipValidationTask: Task<Void, Never>?
    private var ownershipGeneration = UUID()

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

        if let data = defaults.data(forKey: persistenceKey),
           let snapshot = try? JSONDecoder().decode(
                Prompt12StoreSnapshot.self,
                from: data
           ) {
            ownershipState = snapshot.ownershipState == .validating ? .validationUnavailable : snapshot.ownershipState
            authenticationState = snapshot.authenticationState
            syncState = snapshot.syncState
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
        if defaults.object(forKey: persistenceKey) != nil {
            guard let bytes = defaults.data(forKey: persistenceKey),
                  (try? JSONDecoder().decode(Prompt12StoreSnapshot.self, from: bytes)) != nil else {
                ownershipState = .validationUnavailable
                ownershipValidationMessage = "the saved account/settings record could not be read. it has been preserved; this ownership check did not change it."
                return Task {}
            }
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
        pendingLocalChanges = true
        syncState = isSignedIn ? .pendingLocalChanges : .localOnly
        saveSnapshot()
    }

    func syncNow() {
        // Keep pending local edits. Successful cloud synchronization requires a
        // configured service and an acknowledged upload, neither exists here.
        syncState = isSignedIn ? .unavailable : .localOnly
        saveSnapshot()
    }

    func signOut(
        keepLocalData: Bool = true
    ) throws {
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
        let scopes: [Prompt12DataScope] = [
            .account,
            .savedLibrary,
            .guideBuilder,
            .settings,
            .cycleTracker,
            .askCache
        ]

        let summary =
            "Fruitfolio data export prepared from supported local/account domains."

        let export = Prompt12DataExportRecord(
            scopes: scopes,
            summary: summary
        )

        lastExport = export
        saveSnapshot()
        return export
    }

    func deleteAccountAndAssociatedRemoteData() throws {
        guard account != nil else {
            throw Prompt12AccountPrivacyError.notSignedIn
        }

        authenticationState = .deletingAccount
        syncState = .syncing
        saveSnapshot()

        account = nil
        authenticationState = .accountDeleted
        syncState = .localOnly
        pendingLocalChanges = false
        saveSnapshot()
    }

    func resetLocalAccountPrivacyStateForTesting() {
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
    }
}

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
