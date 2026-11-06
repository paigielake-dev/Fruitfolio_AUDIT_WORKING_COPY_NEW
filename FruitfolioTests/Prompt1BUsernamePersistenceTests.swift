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
        XCTAssertEqual(firstDefaults.string(forKey: "username"), "sprout_one")
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
