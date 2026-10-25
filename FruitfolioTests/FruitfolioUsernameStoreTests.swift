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
}
