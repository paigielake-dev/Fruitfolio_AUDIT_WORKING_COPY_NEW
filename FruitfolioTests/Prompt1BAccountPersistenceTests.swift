import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BAccountPersistenceTests: XCTestCase {
    private func exerciseBlockedMutations(_ store: Prompt12AccountPrivacyStore) async {
        let privacy = store.usePrivacyModeOnLockScreen
        store.markLocalChangePending()
        store.syncNow()
        XCTAssertThrowsError(try store.signInForDevelopment(email: "fixture@example.invalid"))
        XCTAssertThrowsError(try store.signOut())
        store.usePrivacyModeOnLockScreen = !privacy
        XCTAssertEqual(store.usePrivacyModeOnLockScreen, privacy)
        store.resetLocalAccountPrivacyStateForTesting()
        await store.beginQuietOwnershipValidation().value
        XCTAssertFalse(store.canPersistAccountChanges)
        XCTAssertNotNil(store.persistenceRecoveryMessage)
    }

    func testCorruptAndWrongTypeOriginalsAreNeverOverwrittenByAnyMutator() async throws {
        let suite = "Fruitfolio.AccountUnreadable." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for original: NSObject in [Data("broken original".utf8) as NSData, "future format" as NSString, ["future": "shape"] as NSDictionary] {
            defaults.set(original, forKey: "fixture")
            let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
            XCTAssertFalse(store.canPersistAccountChanges)
            await exerciseBlockedMutations(store)
            XCTAssertEqual(defaults.object(forKey: "fixture") as? NSObject, original)
            store.reloadSavedAccountState()
            XCTAssertFalse(store.canPersistAccountChanges)
            XCTAssertEqual(defaults.object(forKey: "fixture") as? NSObject, original)
        }
    }

    func testFutureRootAndNestedFieldsRemainByteForBytePreserved() async throws {
        let suite = "Fruitfolio.AccountFuture." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let initial = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        try initial.signInForDevelopment(email: "fixture@example.invalid")
        let bytes = try XCTUnwrap(defaults.data(forKey: "fixture"))
        let known = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        for location in ["root", "account", "lastExport"] {
            var object = known
            if location == "root" { object["schemaVersion"] = 999 }
            else if location == "account" {
                var account = try XCTUnwrap(object["account"] as? [String: Any])
                account["futureField"] = "do not discard"
                object["account"] = account
            } else {
                object["lastExport"] = ["id": UUID().uuidString, "createdAt": 1, "scopes": ["settings"],
                                        "summary": "historical", "futureField": "do not discard"]
            }
            let future = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            defaults.set(future, forKey: "fixture")
            let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
            await exerciseBlockedMutations(store)
            XCTAssertEqual(defaults.data(forKey: "fixture"), future)
        }
    }

    func testStaleAndClearedRecordsStayProtectedUntilExplicitReadOnlyReload() async throws {
        let suite = "Fruitfolio.AccountStale." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for clear in [false, true] {
            defaults.removeObject(forKey: "fixture")
            let stale = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
            stale.markLocalChangePending()
            let newer = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
            newer.usePrivacyModeOnLockScreen = false
            let latest = defaults.data(forKey: "fixture")
            if clear { defaults.removeObject(forKey: "fixture") }
            await exerciseBlockedMutations(stale)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : latest)
            stale.reloadSavedAccountState()
            XCTAssertTrue(stale.canPersistAccountChanges)
            XCTAssertNil(stale.persistenceRecoveryMessage)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : latest)
            XCTAssertEqual(stale.usePrivacyModeOnLockScreen, clear)
            stale.markLocalChangePending()
            XCTAssertNotNil(defaults.data(forKey: "fixture"))
            XCTAssertTrue(Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture").pendingLocalChanges)
        }
    }

    func testPrivacyTogglePersistsImmediatelyWithoutAnotherAccountAction() async throws {
        let suite = "Fruitfolio.AccountPrivacyToggle." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        XCTAssertTrue(store.usePrivacyModeOnLockScreen)
        store.usePrivacyModeOnLockScreen = false
        let bytes = try XCTUnwrap(defaults.data(forKey: "fixture"))
        let reloaded = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "fixture")
        XCTAssertFalse(reloaded.usePrivacyModeOnLockScreen)
        reloaded.reloadSavedAccountState()
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
    }
}
