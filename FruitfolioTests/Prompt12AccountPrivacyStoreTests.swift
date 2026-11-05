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

    func testDemoSignInCreatesAccountWithoutRawCredentials() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        try store.signInForDevelopment(email: "paige@example.com")

        XCTAssertTrue(store.isSignedIn)
        XCTAssertEqual(store.account?.email, "paige@example.com")
        XCTAssertEqual(store.account?.provider, "demo")
        XCTAssertEqual(store.syncState, .synced)
    }

    func testBlankEmailThrows() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        XCTAssertThrowsError(
            try store.signInForDevelopment(email: "   ")
        )
    }

    func testProductionSignInCannotFabricateAnAuthenticatedAccount() {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertThrowsError(try store.requestSignIn(email: "person@example.com")) { error in
            XCTAssertEqual(error as? Prompt12AccountPrivacyError, .serviceNotConfigured)
        }
        XCTAssertFalse(store.isSignedIn)
        XCTAssertNil(store.account)
    }

    func testUnavailableCloudSyncPreservesPendingLocalEdits() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)
        try store.signInForDevelopment(email: "person@example.com")
        store.markLocalChangePending()
        store.syncNow()
        XCTAssertEqual(store.syncState, .unavailable)
        XCTAssertTrue(store.pendingLocalChanges)
    }

    func testExportCreatesReadableExportRecord() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let store = Prompt12AccountPrivacyStore(defaults: defaults)

        let export = try store.prepareDataExport()

        XCTAssertFalse(export.scopes.isEmpty)
        XCTAssertNotNil(store.lastExport)
    }
}
