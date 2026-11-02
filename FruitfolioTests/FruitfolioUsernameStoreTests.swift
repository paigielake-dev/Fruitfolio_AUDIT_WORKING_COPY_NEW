import XCTest
@testable import Fruitfolio

@MainActor
final class FruitfolioUsernameStoreTests: XCTestCase {
    func testUsernamePersistsThroughSingleAuthority() {
        let suite = "FruitfolioUsernameStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults)
        XCTAssertNil(store.setUsername("berry_123"))
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "berry_123")
    }
    func testInvalidEditsCannotReplaceTheSharedPublicIdentityOrPersistAnExplicitName() throws {
        let suite = "UsernameRejectedEdits-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioUsernameStore(defaults: defaults)
        XCTAssertNil(store.setUsername("berry_123"))
        for rejected in ["a", "ab", "nude_friend", "f4ck_friend"] {
            XCTAssertNotNil(store.setUsername(rejected))
            XCTAssertEqual(store.username, "berry_123")
            XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "berry_123")
        }
        XCTAssertNil(store.setUsername("peach_456"))
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "peach_456")
    }
}
