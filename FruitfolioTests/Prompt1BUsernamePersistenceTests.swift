import XCTest
@testable import Fruitfolio

final class Prompt1BUsernamePersistenceTests: XCTestCase {
    func testActualPersistencePreservesIdentityOnFailedEditAndPreventsLegacyResurrection() throws {
        let suite = "FruitfolioUsernamePersistenceTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONSerialization.data(withJSONObject: ["leaderboardPseudonym": "old_berry"]), forKey: "fruitfolio.prompt28.fruitBasket.v1")
        let persistence = FruitfolioUsernamePersistence(defaults: defaults, key: "username")
        XCTAssertEqual(persistence.load().username, "old_berry")
        XCTAssertFalse(persistence.load().confirmedNonIdentifying)
        XCTAssertNil(persistence.save("new_berry", confirmedNonIdentifying: true, identifyingText: []))
        let saved = persistence.load()
        XCTAssertTrue(saved.confirmedNonIdentifying)
        for (text, confirmed) in [("Real Name", true), ("berry_22", false), (String(repeating: "a", count: 17), true)] {
            XCTAssertNotNil(persistence.save(text, confirmedNonIdentifying: confirmed, identifyingText: []))
            XCTAssertEqual(persistence.load(), saved)
        }
        persistence.clear()
        XCTAssertEqual(FruitfolioUsernamePersistence(defaults: defaults, key: "username").load().username, "")
        defaults.set("Real Name", forKey: "username")
        XCTAssertEqual(persistence.load().username, "")
        XCTAssertEqual(defaults.string(forKey: "username"), "Real Name")
    }
}

@MainActor
final class Prompt1BUsernameStoreIsolationTests: XCTestCase {
    func testSharedAuthorityEnforcesCurrentIdentityWithoutEditorSuppliedFragmentsAndPreservesCallerExclusions() async throws {
        let suite = "Fruitfolio.UsernameIdentityAuthority." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var currentIdentity = ["alice.garden@example.invalid"]
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username",
            identifyingTextProvider: { currentIdentity })
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let original = defaults.data(forKey: key)
        XCTAssertNotNil(store.setUsername("alice_77", confirmedNonIdentifying: true))
        XCTAssertEqual(defaults.data(forKey: key), original)
        XCTAssertNotNil(store.setUsername("draftname_3", confirmedNonIdentifying: true,
            identifyingText: ["draftname@example.invalid"]))
        XCTAssertEqual(defaults.data(forKey: key), original)
        currentIdentity = ["marina@example.invalid"]
        XCTAssertNotNil(store.setUsername("marina_77", confirmedNonIdentifying: true))
        XCTAssertEqual(store.username, "old_berry")
        XCTAssertNil(store.setUsername("plum_77", confirmedNonIdentifying: true))
        let bytes = try XCTUnwrap(defaults.data(forKey: key))
        let record = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
        XCTAssertEqual(Set(record.keys), Set(["schemaVersion", "username", "confirmedNonIdentifying"]))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("example.invalid"))
        XCTAssertEqual(FruitfolioUsernamePersistence(defaults: defaults, key: "username").load().username, "plum_77")
    }

    func testFrozenSaveRechecksActualCurrentAccountAtCommitInsteadOfCapturingStaleIdentity() async throws {
        let suite = "Fruitfolio.UsernameFrozenAccount." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let account = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "account-fixture")
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username", identifyingTextProvider: {
            account.account.map { [$0.email, $0.username] } ?? []
        })
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let intent = FruitfolioUsernameSaveIntent(raw: "alice_77", confirmedNonIdentifying: true,
            expected: store.snapshot)
        // Existing explicit development fixture creates a local test identity;
        // this does not claim real backend sign-in or identity verification.
        try account.signInForDevelopment(email: "alice.garden@example.invalid")
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let usernameBytes = defaults.data(forKey: key)
        let accountBytes = try XCTUnwrap(defaults.data(forKey: "account-fixture"))
        XCTAssertEqual(account.account?.email, "alice.garden@example.invalid")
        XCTAssertNotNil(intent.commit(to: store))
        XCTAssertEqual(defaults.data(forKey: key), usernameBytes)
        XCTAssertEqual(defaults.data(forKey: "account-fixture"), accountBytes)
        XCTAssertEqual(store.username, "old_berry")
        XCTAssertNil(store.setUsername("plum_77", confirmedNonIdentifying: true))
        XCTAssertEqual(defaults.data(forKey: "account-fixture"), accountBytes)
        XCTAssertEqual(FruitfolioUsernamePersistence(defaults: defaults, key: "username").load().username, "plum_77")
    }

    func testActualObservableStoreUsesInjectedSuiteWithoutCrossingUsernameNamespaces() async throws {
        let firstSuite = "Fruitfolio.UsernameFirst." + UUID().uuidString
        let secondSuite = "Fruitfolio.UsernameSecond." + UUID().uuidString
        let firstDefaults = try XCTUnwrap(UserDefaults(suiteName: firstSuite))
        let secondDefaults = try XCTUnwrap(UserDefaults(suiteName: secondSuite))
        defer {
            firstDefaults.removePersistentDomain(forName: firstSuite)
            secondDefaults.removePersistentDomain(forName: secondSuite)
        }
        let first = FruitfolioUsernameStore(defaults: firstDefaults, key: "username")
        let second = FruitfolioUsernameStore(defaults: secondDefaults, key: "username")
        XCTAssertNil(first.setUsername("sprout_one", confirmedNonIdentifying: true))
        XCTAssertEqual(first.username, "sprout_one")
        XCTAssertTrue(first.confirmedNonIdentifying)
        XCTAssertEqual(second.username, "")
        XCTAssertNil(secondDefaults.string(forKey: "username"))
        XCTAssertNil(second.setUsername("sprout_two", confirmedNonIdentifying: true))
        XCTAssertEqual(second.username, "sprout_two")
        XCTAssertEqual(first.username, "sprout_one")
        XCTAssertEqual(FruitfolioUsernameStore(defaults: firstDefaults, key: "username").username, "sprout_one")
    }
    func testActualAccountUIFixtureUsesDisposableFilesAndPrivateUsernameAuthority() async throws {
        let fixture = Prompt12AccountActionFixture()
        defer { fixture.cleanUp() }
        await fixture.prepare()
        XCTAssertTrue(fixture.ready); XCTAssertNil(fixture.error)
        XCTAssertTrue(fixture.directory.path.hasPrefix(FileManager.default.temporaryDirectory.path))
        XCTAssertEqual(fixture.username.username, "")
        XCTAssertEqual(fixture.identity, "fixture-a@example.invalid")
        XCTAssertEqual(fixture.pending, "yes")
        XCTAssertEqual(fixture.healthFileUnchanged, "yes")
        XCTAssertEqual(fixture.accountRecordUnchanged, "yes")
        let expected = fixture.store.accountActionSnapshot
        try fixture.store.signOut(expecting: expected)
        fixture.captureActualState()
        XCTAssertEqual(fixture.identity, "none")
        XCTAssertEqual(fixture.pending, "yes")
        XCTAssertEqual(fixture.healthFileUnchanged, "yes")
        XCTAssertEqual(fixture.accountRecordUnchanged, "no")
        XCTAssertEqual(fixture.username.username, "")
    }

}

/// Selected fault only; all reads and other writes use the actual private suite.
private final class UsernameAcknowledgmentDefaults: UserDefaults {
    var rejectAllWrites = false
    var rejectLegacyConfirmation = false
    private(set) var rejectedWrites = 0
    override func set(_ value: Any?, forKey defaultName: String) {
        if rejectAllWrites || (rejectLegacyConfirmation && defaultName == "username.nonIdentifyingConfirmation") {
            rejectedWrites += 1
            return
        }
        super.set(value, forKey: defaultName)
    }
}

@MainActor
final class Prompt1BUsernameAcknowledgmentTests: XCTestCase {
    func testRefusedActualUsernameWritesCannotReportSaved() async throws {
        let suite = "Fruitfolio.UsernameRefused." + UUID().uuidString
        let defaults = try XCTUnwrap(UsernameAcknowledgmentDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        defaults.rejectAllWrites = true
        XCTAssertNotNil(store.setUsername("new_berry", confirmedNonIdentifying: true))
        XCTAssertGreaterThan(defaults.rejectedWrites, 0)
        XCTAssertEqual(store.username, "old_berry")
        XCTAssertTrue(store.confirmedNonIdentifying)
        let loaded = FruitfolioUsernamePersistence(defaults: defaults, key: "username").load()
        XCTAssertEqual(loaded.username, "old_berry")
        XCTAssertTrue(loaded.confirmedNonIdentifying)
    }
    func testAReportedSaveCannotSplitUsernameFromItsNonIdentifyingConsent() async throws {
        let suite = "Fruitfolio.UsernamePartial." + UUID().uuidString
        let defaults = try XCTUnwrap(UsernameAcknowledgmentDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        defaults.rejectLegacyConfirmation = true
        let error = store.setUsername("new_berry", confirmedNonIdentifying: true)
        let loaded = FruitfolioUsernamePersistence(defaults: defaults, key: "username").load()
        if error == nil {
            XCTAssertEqual(loaded.username, "new_berry")
            XCTAssertTrue(loaded.confirmedNonIdentifying, "Reported success must include acknowledged consent")
        } else {
            XCTAssertEqual(loaded.username, "old_berry")
            XCTAssertTrue(loaded.confirmedNonIdentifying)
        }
    }
}

@MainActor
final class Prompt1BUsernameRecordProtectionTests: XCTestCase {
    private func fixture() throws -> (UsernameAcknowledgmentDefaults, String) {
        let suite = "Fruitfolio.UsernameRecord." + UUID().uuidString
        return (try XCTUnwrap(UsernameAcknowledgmentDefaults(suiteName: suite)), suite)
    }
    func testLegacyMigrationAndClearPreserveOriginalsWithoutResurrectingAnActiveName() async throws {
        let (defaults, suite) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("old_berry", forKey: "username")
        defaults.set(true, forKey: "username.initialized")
        defaults.set("old_berry", forKey: "username.nonIdentifyingConfirmation")
        let game = Data(#"{"leaderboardPseudonym":"game_berry","futureProgress":9}"#.utf8)
        defaults.set(game, forKey: "fruitfolio.prompt28.fruitBasket.v1")
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertEqual(store.username, "old_berry"); XCTAssertTrue(store.confirmedNonIdentifying)
        XCTAssertNil(store.setUsername("new_berry", confirmedNonIdentifying: true))
        let restored = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertEqual(restored.username, "new_berry"); XCTAssertTrue(restored.confirmedNonIdentifying)
        XCTAssertEqual(defaults.string(forKey: "username"), "old_berry")
        XCTAssertEqual(defaults.string(forKey: "username.nonIdentifyingConfirmation"), "old_berry")
        XCTAssertEqual(defaults.data(forKey: "fruitfolio.prompt28.fruitBasket.v1"), game)
        defaults.rejectAllWrites = true
        XCTAssertNotNil(store.clear())
        XCTAssertEqual(store.username, "new_berry"); XCTAssertTrue(store.confirmedNonIdentifying)
        defaults.rejectAllWrites = false
        XCTAssertNil(store.clear())
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults, key: "username").username, "")
        XCTAssertEqual(defaults.string(forKey: "username"), "old_berry")
    }
    func testFutureUnknownNullMalformedAndWrongTypeRecordsArePreserved() async throws {
        for value: Any in [
            Data(#"{"schemaVersion":3,"username":"new_berry","confirmedNonIdentifying":true}"#.utf8),
            Data(#"{"schemaVersion":2,"username":"new_berry","confirmedNonIdentifying":true,"future":null}"#.utf8),
            Data(#"{"schemaVersion":2,"username":"new_berry","confirmedNonIdentifying":false}"#.utf8),
            Data("not JSON".utf8), "unknown representation"] {
            let (defaults, suite) = try fixture()
            defer { defaults.removePersistentDomain(forName: suite) }
            let key = FruitfolioUsernamePersistence.recordKey(for: "username")
            defaults.set(value, forKey: key)
            let before = defaults.object(forKey: key) as? NSObject
            let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
            XCTAssertFalse(store.canPersistUsername)
            XCTAssertFalse(store.confirmedNonIdentifying)
            XCTAssertNotNil(store.setUsername("later_berry", confirmedNonIdentifying: true))
            XCTAssertNotNil(store.clear())
            XCTAssertEqual(defaults.object(forKey: key) as? NSObject, before)
        }
    }
    func testDebugInspectionCannotRebaseAStaleWriter() async throws {
        let (defaults, suite) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(first.setUsername("old_berry", confirmedNonIdentifying: true))
        let second = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(second.setUsername("new_berry", confirmedNonIdentifying: true))
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let bytes = defaults.data(forKey: key)
        #if DEBUG
        XCTAssertEqual(first.debugStoredUsername.username, "new_berry")
        #endif
        XCTAssertNotNil(first.setUsername("later_berry", confirmedNonIdentifying: true))
        XCTAssertEqual(defaults.data(forKey: key), bytes)
        XCTAssertEqual(first.username, "new_berry")
    }
    func testCapturedSameAuthorityIntentCannotOverwriteLaterName() async throws {
        let (defaults, suite) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        let expected = store.snapshot
        XCTAssertNil(store.setUsername("new_berry", confirmedNonIdentifying: true))
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let bytes = defaults.data(forKey: key)
        XCTAssertNotNil(store.setUsername("later_berry", confirmedNonIdentifying: true, expecting: expected))
        XCTAssertEqual(defaults.data(forKey: key), bytes)
    }
    func testLegacyWriterAndUnsupportedLegacyTypesCannotBeSilentlyRebased() async throws {
        let (defaults, suite) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("old_berry", forKey: "username")
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        defaults.set("new_berry", forKey: "username")
        XCTAssertNotNil(store.setUsername("later_berry", confirmedNonIdentifying: true))
        XCTAssertNil(defaults.data(forKey: FruitfolioUsernamePersistence.recordKey(for: "username")))
        defaults.set("future flag", forKey: "username.initialized")
        store.reloadSavedUsername()
        XCTAssertFalse(store.canPersistUsername)
        XCTAssertNotNil(store.setUsername("later_berry", confirmedNonIdentifying: true))
        XCTAssertEqual(defaults.string(forKey: "username.initialized"), "future flag")
    }
    func testAcknowledgedIdenticalRecordReturnsReceiptWithoutRewritingBytes() async throws {
        let (defaults, suite) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = FruitfolioUsernamePersistence.recordKey(for: "username")
        let bytes = Data(#"{ "username":"old_berry", "confirmedNonIdentifying":true, "schemaVersion":2 }"#.utf8)
        defaults.set(bytes, forKey: key)
        let store = FruitfolioUsernameStore(defaults: defaults, key: "username")
        defaults.rejectAllWrites = true
        XCTAssertNil(store.setUsername("old_berry", confirmedNonIdentifying: true))
        XCTAssertEqual(defaults.rejectedWrites, 0)
        XCTAssertEqual(defaults.data(forKey: key), bytes)
    }
}
