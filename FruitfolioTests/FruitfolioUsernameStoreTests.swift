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
        for rejected in ["a", "ab", "nude_friend", "f4ck_friend", "abcdefghijklmnopq", "berry friend", "berry✨friend", "berry/friend", "berry\nfriend"] {
            XCTAssertNotNil(store.setUsername(rejected))
            XCTAssertEqual(store.username, "berry_123")
            XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "berry_123")
        }
        XCTAssertNil(store.setUsername("peach_456"))
        XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults).username, "peach_456")
    }
    func testRejectedRawDraftNeverPersistsItsSanitizedAlternative() throws {
        let suite = "UsernameRawValidation-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "publicName"
        let store = FruitfolioUsernameStore(defaults: defaults, key: key)
        XCTAssertNil(store.setUsername("peach_456"))
        let originalBytes = try PropertyListSerialization.data(fromPropertyList: defaults.dictionaryRepresentation(),
                                                               format: .binary, options: 0)
        for invalid in ["a b c", "berry✨123", String(repeating: "b", count: 17)] {
            XCTAssertNotNil(store.setUsername(invalid))
            XCTAssertEqual(store.username, "peach_456")
            XCTAssertEqual(defaults.string(forKey: key), "peach_456")
            XCTAssertEqual(FruitfolioUsernameStore(defaults: defaults, key: key).username, "peach_456")
        }
        let afterBytes = try PropertyListSerialization.data(fromPropertyList: defaults.dictionaryRepresentation(),
                                                            format: .binary, options: 0)
        XCTAssertEqual(try PropertyListSerialization.propertyList(from: originalBytes, format: nil) as? NSDictionary,
                       try PropertyListSerialization.propertyList(from: afterBytes, format: nil) as? NSDictionary)
        XCTAssertNil(store.setUsername("  berry_123  "))
        XCTAssertEqual(store.username, "berry_123")
    }

}
