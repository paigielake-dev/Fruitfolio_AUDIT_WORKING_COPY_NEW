import XCTest
@testable import Fruitfolio

private struct OwnershipResultFixture: FruitfolioStorefrontOwnershipValidating {
    let result: FruitfolioStorefrontOwnershipResult
    func validate() async -> FruitfolioStorefrontOwnershipResult { result }
}

private struct DelayedOwnershipFixture: FruitfolioStorefrontOwnershipValidating {
    func validate() async -> FruitfolioStorefrontOwnershipResult {
        try? await Task.sleep(for: .milliseconds(30))
        return .verified(bundleID: "fixture.fruitfolio") // Deliberately returns even after cancellation.
    }
}

@MainActor
final class StorefrontOwnershipTests: XCTestCase {
    func testOnlyVerifiedMatchingBundleMarksStorefrontVerification() async throws {
        let suite = "StorefrontMatching-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults,
            ownershipValidator: OwnershipResultFixture(result: .verified(bundleID: "fixture.fruitfolio")),
            bundleIdentifier: "fixture.fruitfolio")
        XCTAssertFalse(store.ownershipVerifiedByStorefront, "Installed-app policy alone is not receipt verification")
        await store.validateOwnership()
        XCTAssertEqual(store.ownershipState, .purchased)
        XCTAssertTrue(store.ownershipVerifiedByStorefront)
        let reopened = Prompt12AccountPrivacyStore(defaults: defaults)
        XCTAssertFalse(reopened.ownershipVerifiedByStorefront,
            "A cached preference must never masquerade as a fresh signed StoreKit verification")
    }

    func testUnverifiedUnavailableAndWrongBundleCannotBecomeVerifiedOrAddPaywall() async throws {
        for result in [FruitfolioStorefrontOwnershipResult.unverified, .unavailable, .verified(bundleID: "another.app")] {
            let suite = "StorefrontRejection-\(UUID().uuidString)"
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt12AccountPrivacyStore(defaults: defaults,
                ownershipValidator: OwnershipResultFixture(result: result), bundleIdentifier: "fixture.fruitfolio")
            await store.validateOwnership()
            XCTAssertEqual(store.ownershipState, .validationUnavailable)
            XCTAssertFalse(store.ownershipVerifiedByStorefront)
            XCTAssertTrue(FruitfolioPurchasePolicy.normalInstalledUserHasAccess)
            XCTAssertFalse(FruitfolioPurchasePolicy.requiresPurchaseGate(for: .hub))
            XCTAssertFalse(FruitfolioPurchasePolicy.offersInAppUnlockPurchase)
            XCTAssertFalse(FruitfolioPurchasePolicy.offersSubscription)
        }
    }

    func testInterruptedPersistedCheckDoesNotRemainIndefinitelyValidatingAfterRestart() throws {
        let suite = "StorefrontInterrupted-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "ownership-interrupted"
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: key)
        store.markPurchasedForInstalledApp()
        let data = try XCTUnwrap(defaults.data(forKey: key))
        var snapshot = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String:Any])
        snapshot["ownershipState"] = "validating"
        snapshot.removeValue(forKey: "ownershipVerifiedByStorefront") // older schema fixture
        defaults.set(try JSONSerialization.data(withJSONObject: snapshot), forKey: key)
        let reopened = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: key)
        XCTAssertEqual(reopened.ownershipState, .validationUnavailable)
        XCTAssertFalse(reopened.ownershipVerifiedByStorefront)
    }

    func testCancelledCheckCannotRestoreAStaleVerifiedResultOrLeaveSpinner() async throws {
        let suite = "StorefrontCancel-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults,
            ownershipValidator: DelayedOwnershipFixture(), bundleIdentifier: "fixture.fruitfolio")
        store.beginQuietOwnershipValidation()
        await Task.yield()
        store.cancelOwnershipValidation()
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertNotEqual(store.ownershipState, .validating)
        XCTAssertFalse(store.ownershipVerifiedByStorefront)
        XCTAssertTrue(FruitfolioPurchasePolicy.normalInstalledUserHasAccess)
    }

    func testActualStoreKitAttemptReportsItsRealOutcome() async {
        let result = await FruitfolioAppleOwnershipValidator().validate()
        if case .verified(let bundleID) = result {
            XCTAssertEqual(bundleID, Bundle.main.bundleIdentifier,
                "An actual verified app transaction must belong to this test-host application")
        }
        let evidence = XCTAttachment(string: "Actual AppTransaction.shared attempt returned \(result). A missing/unverified transaction is NOT proof of paid ownership. No purchase, refresh prompt or subscription API was invoked. Production storefront/receipt acceptance requires its actual signed distribution environment.")
        evidence.name = "StoreKit_ActualAppTransactionOutcome"; evidence.lifetime = .keepAlways; add(evidence)
    }
}
