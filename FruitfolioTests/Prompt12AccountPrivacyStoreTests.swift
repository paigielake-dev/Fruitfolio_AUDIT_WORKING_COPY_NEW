import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt12AccountPrivacyStoreTests: XCTestCase {
    func testDefaultStateIsPurchasedSignedOutAndLocalOnly() async {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        XCTAssertEqual(store.ownershipState, .purchased)
        XCTAssertEqual(store.authenticationState, .signedOut)
        XCTAssertEqual(store.syncState, .localOnly)
        XCTAssertNil(store.account)
    }

    func testDemoSignInCreatesAccountWithoutRawCredentials() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        try store.signInForDevelopment(email: "paige@example.com")

        XCTAssertTrue(store.isSignedIn)
        XCTAssertEqual(store.account?.email, "paige@example.com")
        XCTAssertEqual(store.account?.provider, "demo")
        XCTAssertEqual(store.syncState, .synced)
    }

    func testBlankEmailThrows() async {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        XCTAssertThrowsError(
            try store.signInForDevelopment(email: "   ")
        )
    }

    func testProductionSignInCannotFabricateAnAuthenticatedAccount() async {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertThrowsError(try store.requestSignIn(email: "person@example.com")) { error in
            XCTAssertEqual(error as? Prompt12AccountPrivacyError, .serviceNotConfigured)
        }
        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(store.account)
    }

    func testUnavailableCloudSyncPreservesPendingLocalEdits() async throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        try store.signInForDevelopment(email: "person@example.com")
        store.markLocalChangePending()
        store.syncNow()
        XCTAssertEqual(store.syncState, .unavailable)
        XCTAssertTrue(store.pendingLocalChanges)
    }

    func testUnavailableConsolidatedExportDoesNotCreateAReadinessRecord() async throws {
        let suite = "Fruitfolio.export-unavailable." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertThrowsError(try store.prepareDataExport()) {
            XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .consolidatedExportUnavailable)
        }
        XCTAssertNil(store.lastExport)
    }

    func testUnavailableRemoteDeletionKeepsIdentityAndPendingLocalChanges() async throws {
        let suite = "Fruitfolio.remote-delete-unavailable." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        try store.signInForDevelopment(email: "test@example.test")
        store.markLocalChangePending()
        let original = store.account
        XCTAssertThrowsError(try store.deleteAccountAndAssociatedRemoteData()) {
            XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .remoteDeletionUnavailable)
        }
        XCTAssertEqual(store.account, original)
        XCTAssertTrue(store.pendingLocalChanges)
        XCTAssertEqual(store.authenticationState, .signedIn)
    }
    func testReloadDoesNotFabricateAuthenticatedSessionOrRewriteOriginalIdentity() async throws {
        let suite = "Fruitfolio.auth-restore." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Prompt12AccountPrivacyStore(defaults: defaults)
        try original.signInForDevelopment(email: "test@example.test")
        original.markLocalChangePending()
        let bytes = defaults.data(forKey: "fruitfolio.prompt12.accountPrivacy.v1")
        let restored = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertFalse(restored.isSignedIn)
        XCTAssertEqual(restored.authenticationState, .sessionExpired)
        XCTAssertEqual(restored.account, original.account)
        XCTAssertTrue(restored.pendingLocalChanges)
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt12.accountPrivacy.v1"), bytes)
    }

}
