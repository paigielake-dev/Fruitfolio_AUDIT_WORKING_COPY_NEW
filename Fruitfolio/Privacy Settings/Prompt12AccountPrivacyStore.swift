import Foundation
import Combine

@MainActor
final class Prompt12AccountPrivacyStore: ObservableObject {
    static let shared = Prompt12AccountPrivacyStore()

    @Published private(set) var loadError: String?
    @Published private(set) var ownershipState: Prompt12OwnershipState
    @Published private(set) var ownershipVerifiedByStorefront = false
    @Published private(set) var authenticationState: Prompt12AuthenticationState
    @Published private(set) var syncState: Prompt12SyncState
    @Published private(set) var account: Prompt12AccountIdentity?
    @Published private(set) var lastExport: Prompt12DataExportRecord?
    @Published private(set) var pendingLocalChanges: Bool
    @Published private(set) var localDataContainerID: UUID
    @Published var usePrivacyModeOnLockScreen: Bool {
        didSet {
            guard loadError == nil else { usePrivacyModeOnLockScreen = oldValue; return }
            saveSnapshot()
        }
    }

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
            if snapshot.account?.provider == "demo" {
                // Preserve old fixture identity for export/local sign-out, but
                // do not restore an email-only demo as an authenticated session.
                authenticationState = .sessionExpired
                syncState = .unavailable
            }
        } else {
            ownershipState = .purchased
            authenticationState = .signedOut
            syncState = .localOnly
            account = nil
            lastExport = nil
            pendingLocalChanges = false
            localDataContainerID = UUID()
            usePrivacyModeOnLockScreen = true
            if defaults.object(forKey: persistenceKey) != nil {
                loadError = "your saved account settings could not be read. the original data is preserved; account export and changes are unavailable."
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

    /// No authenticated account service/configuration was supplied. Never turn
    /// an email string into a fabricated authenticated or remotely synced user.
    func signIn(email rawEmail: String) throws {
        guard loadError == nil else { throw Prompt12AccountPrivacyError.unreadableStoredData }
        guard !rawEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            authenticationState = .signInFailed
            saveSnapshot()
            throw Prompt12AccountPrivacyError.blankEmail
        }
        authenticationState = .signInFailed
        syncState = .unavailable
        saveSnapshot()
        throw Prompt12AccountPrivacyError.accountServiceUnavailable
    }

    func markLocalChangePending() {
        guard loadError == nil else { return }
        pendingLocalChanges = true
        syncState = isSignedIn ? .pendingLocalChanges : .localOnly
        saveSnapshot()
    }

    func syncNow() {
        guard loadError == nil else { return }
        // A local delay is not a network acknowledgement. Keep pending changes
        // and the local identity intact until a real account service exists.
        syncState = account == nil ? .localOnly : .unavailable
        saveSnapshot()
    }

    func signOut(
        keepLocalData: Bool = true
    ) throws {
        guard loadError == nil else { throw Prompt12AccountPrivacyError.unreadableStoredData }
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
        // Compatibility preview only. Preparing/exporting data is read-only:
        // it must not rewrite account snapshots or create a success record.
        guard loadError == nil else { throw Prompt12AccountPrivacyError.unreadableStoredData }
        return Prompt12DataExportRecord(scopes: Prompt12DataScope.exportedScopes,
            summary: "Readable JSON scope preview. A completed file requires the explicit system destination and successful readback.")
    }

    func deleteAccountAndAssociatedRemoteData() throws {
        guard loadError == nil else { throw Prompt12AccountPrivacyError.unreadableStoredData }
        guard account != nil else {
            throw Prompt12AccountPrivacyError.notSignedIn
        }

        // Local record deletion cannot certify deletion from a remote account.
        syncState = .unavailable
        saveSnapshot()
        throw Prompt12AccountPrivacyError.accountServiceUnavailable
    }

    func resetLocalAccountPrivacyStateForTesting() {
        loadError = nil
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
        guard loadError == nil else { return }
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
