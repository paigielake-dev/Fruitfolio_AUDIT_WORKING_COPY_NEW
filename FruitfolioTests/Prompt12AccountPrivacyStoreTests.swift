import XCTest
@testable import Fruitfolio

private struct UnreadableAccountOwnershipFixture: FruitfolioStorefrontOwnershipValidating {
    func validate() async -> FruitfolioStorefrontOwnershipResult { .unavailable }
}

@MainActor
final class Prompt12AccountPrivacyStoreTests: XCTestCase {
    func testDefaultStateIsPurchasedSignedOutAndLocalOnly() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        XCTAssertEqual(store.ownershipState, .purchased)
        XCTAssertEqual(store.authenticationState, .signedOut)
        XCTAssertEqual(store.syncState, .localOnly)
        XCTAssertNil(store.account)
    }

    func testUnavailableAccountServiceNeverFabricatesAuthenticationOrRemoteSync() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertThrowsError(try store.signIn(email: "paige@example.com")) {
            XCTAssertEqual($0 as? Prompt12AccountPrivacyError, .accountServiceUnavailable)
        }
        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(store.account)
        XCTAssertEqual(store.authenticationState, .signInFailed)
        XCTAssertEqual(store.syncState, .unavailable)
        let restarted = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertFalse(restarted.isSignedIn)
        XCTAssertNil(restarted.account, "An entered email must not become a fabricated account after restart")
    }

    func testUnavailableSyncDoesNotDiscardPendingLocalChanges() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        store.markLocalChangePending()
        store.syncNow()
        XCTAssertTrue(store.pendingLocalChanges)
        XCTAssertEqual(store.syncState, .localOnly)
        XCTAssertNil(store.account)
    }

    func testBlankEmailThrows() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        XCTAssertThrowsError(
            try store.signIn(email: "   ")
        )
    }

    func testPreparingExportPreviewKeepsStoredAccountRecordsAndDefaultsUnchanged() throws {
        let suite = "Fruitfolio.ExportPreview.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        let before = defaults.persistentDomain(forName: suite) ?? [:]
        let originalAccount = store.account
        let originalExport = store.lastExport
        let preview = try store.prepareDataExport()
        XCTAssertEqual(preview.scopes, Prompt12DataScope.exportedScopes)
        XCTAssertFalse(preview.scopes.contains(.askCache))
        XCTAssertTrue(preview.scopes.contains(.reportedContext))
        XCTAssertTrue(preview.scopes.contains(.hormoneMeasurements))
        XCTAssertTrue(preview.scopes.contains(.fruitBasket))
        XCTAssertEqual(store.account, originalAccount)
        XCTAssertEqual(store.lastExport, originalExport)
        XCTAssertTrue(NSDictionary(dictionary: before).isEqual(to: defaults.persistentDomain(forName: suite) ?? [:]))
    }
    func testPrivateNotificationPreferencePersistsImmediatelyWithoutAnUnrelatedOwnershipOrAccountAction() throws {
        let suite = "Fruitfolio.PrivacyPreference.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertTrue(store.usePrivacyModeOnLockScreen)
        store.usePrivacyModeOnLockScreen = false
        XCTAssertFalse(Prompt12AccountPrivacyStore(defaults: defaults).usePrivacyModeOnLockScreen)
        store.usePrivacyModeOnLockScreen = true
        XCTAssertTrue(Prompt12AccountPrivacyStore(defaults: defaults).usePrivacyModeOnLockScreen)
        XCTAssertNil(store.account)
    }

    func testUnreadableAccountSettingsSurviveQuietValidationEditsExportAndRestartWithoutFalseSuccess() async throws {
        let suite = "Fruitfolio.AccountCorrupt.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "fruitfolio.prompt12.accountPrivacy.v1"
        let original = Data([0xff, 0x00, 0x7f])
        defaults.set(original, forKey: key)
        let store = Prompt12AccountPrivacyStore(defaults: defaults,
            ownershipValidator: UnreadableAccountOwnershipFixture())
        XCTAssertNotNil(store.loadError)
        store.markPurchasedForInstalledApp()
        store.markLocalChangePending(); store.syncNow()
        store.usePrivacyModeOnLockScreen = false
        XCTAssertTrue(store.usePrivacyModeOnLockScreen)
        XCTAssertThrowsError(try store.signIn(email: "fixture@example.invalid"))
        XCTAssertThrowsError(try store.signOut())
        XCTAssertThrowsError(try store.prepareDataExport())
        XCTAssertThrowsError(try store.deleteAccountAndAssociatedRemoteData())
        await store.validateOwnership()
        XCTAssertFalse(store.ownershipVerifiedByStorefront)
        store.cancelOwnershipValidation()
        XCTAssertEqual(defaults.data(forKey: key), original)
        let reopened = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertNotNil(reopened.loadError)
        XCTAssertThrowsError(try reopened.prepareDataExport())
        XCTAssertEqual(defaults.data(forKey: key), original)
    }

}
