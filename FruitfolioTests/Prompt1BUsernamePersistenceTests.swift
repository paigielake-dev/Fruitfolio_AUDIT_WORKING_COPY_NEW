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
