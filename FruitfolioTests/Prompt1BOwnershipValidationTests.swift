#if canImport(Combine)
import Foundation
import XCTest
@testable import Fruitfolio

private actor Prompt1BSuspendedOwnershipVerifier: FruitfolioOwnershipVerifying {
    private var continuation: CheckedContinuation<FruitfolioOwnershipVerification, Never>?
    private var started: CheckedContinuation<Void, Never>?
    private(set) var starts = 0
    func verify(expectedBundleIdentifier: String) async -> FruitfolioOwnershipVerification {
        starts += 1
        return await withCheckedContinuation {
            continuation = $0
            started?.resume()
            started = nil
        }
    }
    func waitUntilStarted() async {
        if starts > 0 { return }
        await withCheckedContinuation { started = $0 }
    }
    func finish(_ result: FruitfolioOwnershipVerification) { continuation?.resume(returning: result); continuation = nil }
}

@MainActor
final class Prompt1BOwnershipValidationTests: XCTestCase {
    func testActualStoreCoalescesChecksAndDistinguishesTestInstallationWithoutRequiringSignIn() async throws {
        let suite = "Fruitfolio.ownership." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let verifier = Prompt1BSuspendedOwnershipVerifier()
        let store = Prompt12AccountPrivacyStore(defaults: defaults, ownershipVerifier: verifier, expectedBundleIdentifier: "test.app")
        let first = store.beginQuietOwnershipValidation()
        let second = store.beginQuietOwnershipValidation()
        XCTAssertEqual(store.ownershipState, .validating)
        await verifier.waitUntilStarted()
        let starts = await verifier.starts
        XCTAssertEqual(starts, 1)
        await verifier.finish(.verifiedTestInstallation)
        await first.value
        await second.value
        XCTAssertEqual(store.ownershipState, .verifiedTestInstallation)
        XCTAssertFalse(store.isSignedIn)
        XCTAssertEqual(Prompt12AccountPrivacyStore(defaults: defaults).ownershipState, .verifiedTestInstallation)
    }
    func testLateOwnershipResultCannotResurrectClearedSettingsOrOverwriteAnotherWriter() async throws {
        for cleared in [false, true] {
            let suite = "Fruitfolio.ownership-stale." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let verifier = Prompt1BSuspendedOwnershipVerifier()
            let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture", ownershipVerifier: verifier,
                                                    expectedBundleIdentifier: "test.app")
            let task = store.beginQuietOwnershipValidation()
            await verifier.waitUntilStarted()
            let newer = Data("newer independently stored record".utf8)
            if cleared { defaults.removeObject(forKey: "fixture") }
            else { defaults.set(newer, forKey: "fixture") }
            await verifier.finish(.verifiedProductionInstallation)
            await task.value
            XCTAssertEqual(defaults.data(forKey: "fixture"), cleared ? nil : newer)
            XCTAssertEqual(store.ownershipState, .validationUnavailable)
            XCTAssertNotNil(store.ownershipValidationMessage)
        }
    }
    func testUnreadableOriginalIsRetainedAndCancelledResetIgnoresLateResult() async throws {
        let suite = "Fruitfolio.ownership-recovery." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data("unreadable original".utf8)
        defaults.set(original, forKey: "bad")
        let invalid = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "bad")
        await invalid.beginQuietOwnershipValidation().value
        XCTAssertEqual(defaults.data(forKey: "bad"), original)
        XCTAssertNotNil(invalid.ownershipValidationMessage)
        let verifier = Prompt1BSuspendedOwnershipVerifier()
        let store = Prompt12AccountPrivacyStore(defaults: defaults, ownershipVerifier: verifier, expectedBundleIdentifier: "test.app")
        let task = store.beginQuietOwnershipValidation()
        await verifier.waitUntilStarted()
        store.resetLocalAccountPrivacyStateForTesting()
        let resetBytes = defaults.data(forKey: "fruitfolio.prompt12.accountPrivacy.v1")
        await verifier.finish(.verifiedTestInstallation)
        await task.value
        XCTAssertEqual(store.ownershipState, .purchased)
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt12.accountPrivacy.v1"), resetBytes)
    }
}
#endif
