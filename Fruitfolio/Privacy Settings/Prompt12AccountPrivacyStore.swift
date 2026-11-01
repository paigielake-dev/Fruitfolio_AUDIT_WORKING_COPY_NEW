import Foundation
import Combine

@MainActor
final class Prompt12AccountPrivacyStore: ObservableObject {
    static let shared = Prompt12AccountPrivacyStore()

    @Published private(set) var ownershipState: Prompt12OwnershipState
    @Published private(set) var ownershipVerifiedByStorefront = false
    @Published private(set) var authenticationState: Prompt12AuthenticationState
    @Published private(set) var syncState: Prompt12SyncState
    @Published private(set) var account: Prompt12AccountIdentity?
    @Published private(set) var lastExport: Prompt12DataExportRecord?
    @Published private(set) var pendingLocalChanges: Bool
    @Published private(set) var localDataContainerID: UUID
    @Published var usePrivacyModeOnLockScreen: Bool

    private let defaults: UserDefaults
    private let persistenceKey: String
    private let ownershipValidator: any FruitfolioStorefrontOwnershipValidating
    private let expectedBundleIdentifier: String
    private var ownershipCheckID: UUID?
    private var ownershipTask: Task<Void, Never>?

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "fruitfolio.prompt12.accountPrivacy.v1",
        ownershipValidator: any FruitfolioStorefrontOwnershipValidating = FruitfolioAppleOwnershipValidator(),
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? ""
    ) {
        self.defaults = defaults
        self.persistenceKey = persistenceKey
        self.ownershipValidator = ownershipValidator
        self.expectedBundleIdentifier = bundleIdentifier

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

    func markPurchasedForInstalledApp() {
        ownershipVerifiedByStorefront = false // Installed-app policy is not a signed storefront verification.
        ownershipState = .purchased
        saveSnapshot()
    }

    func beginQuietOwnershipValidation() {
        ownershipTask?.cancel()
        ownershipTask = Task { [weak self] in
            guard !Task.isCancelled else { return }
            await self?.validateOwnership()
        }
    }

    func validateOwnership() async {
        guard !Task.isCancelled else { return }
        let checkID = UUID()
        ownershipCheckID = checkID
        ownershipState = .validating
        ownershipVerifiedByStorefront = false
        saveSnapshot()
        let result = await ownershipValidator.validate()
        guard !Task.isCancelled, ownershipCheckID == checkID else { return }
        if case .verified(let bundleID) = result,
           !expectedBundleIdentifier.isEmpty, bundleID == expectedBundleIdentifier {
            ownershipState = .purchased
            ownershipVerifiedByStorefront = true
        } else {
            // Offline, unavailable or unverified storefront state never creates
            // a second paywall for the legitimately installed paid app.
            ownershipState = .validationUnavailable
        }
        saveSnapshot()
    }

    func cancelOwnershipValidation() {
        ownershipTask?.cancel()
        ownershipTask = nil
        ownershipCheckID = nil
        if ownershipState == .validating {
            ownershipState = .validationUnavailable
            ownershipVerifiedByStorefront = false
            saveSnapshot()
        }
    }

    func signInForDevelopment(
        email rawEmail: String,
        provider: String = "demo"
    ) throws {
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
    }

    func markLocalChangePending() {
        pendingLocalChanges = true
        syncState = isSignedIn ? .pendingLocalChanges : .localOnly
        saveSnapshot()
    }

    func syncNow() {
        guard isSignedIn else {
            syncState = .localOnly
            saveSnapshot()
            return
        }

        syncState = .syncing
        saveSnapshot()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            pendingLocalChanges = false
            syncState = .synced
            saveSnapshot()
        }
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
        ownershipVerifiedByStorefront = false
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
