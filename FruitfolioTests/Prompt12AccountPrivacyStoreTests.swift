import XCTest
@testable import Fruitfolio

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

    func testExportCreatesReadableExportRecord() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        let export = try store.prepareDataExport()

        XCTAssertFalse(export.scopes.isEmpty)
        XCTAssertNotNil(store.lastExport)
    }
}
