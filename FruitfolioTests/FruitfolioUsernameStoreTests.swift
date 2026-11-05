import XCTest
@testable import Fruitfolio

@MainActor
final class FruitfolioUsernameStoreTests: XCTestCase {
    func testUsernamePersistsThroughSingleAuthority() {
        let suite = "FruitfolioUsernameStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults)
        XCTAssertNil(store.setUsername("berry_123", confirmedNonIdentifying: true))
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "berry_123")
        XCTAssertTrue(FruitfolioUsernameStore(defaults: defaults).confirmedNonIdentifying)
        XCTAssertNotNil(store.setUsername("real name", confirmedNonIdentifying: true))
        XCTAssertEqual(store.username, "berry_123")
        XCTAssertNotNil(store.setUsername("new_berry", confirmedNonIdentifying: false))
        XCTAssertEqual(store.username, "berry_123")
    }

    func testClearDoesNotResurrectLegacyPseudonymAndInvalidStoredNameIsNotRewritten() throws {
        let suite = "FruitfolioUsernameStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(try JSONSerialization.data(withJSONObject: ["leaderboardPseudonym": "old_berry"]), forKey: "fruitfolio.prompt28.fruitBasket.v1")
        let store = FruitfolioUsernameStore(defaults: defaults)
        XCTAssertEqual(store.username, "old_berry")
        XCTAssertFalse(store.confirmedNonIdentifying)
        store.clear()
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "")
        defaults.set("Real Name", forKey: "fruitfolio.identity.publicUsername.v1")
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "")
        XCTAssertEqual(defaults.string(forKey: "fruitfolio.identity.publicUsername.v1"), "Real Name")
    }

}
