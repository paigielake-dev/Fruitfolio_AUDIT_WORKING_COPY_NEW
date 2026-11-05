import XCTest
@testable import Fruitfolio

final class Prompt1BLibraryPersistenceTests: XCTestCase {
    func testFailedEncodingPreservesCommittedSnapshotAndStoredBytes() throws {
        let suite = "Prompt1BPersistence.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = "library"
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: key)
        let original = Prompt10Encyclopedia(name: "original", style: .sage)
        try persistence.commit([original])
        let bytes = try XCTUnwrap(defaults.data(forKey: key))
        let invalid = Prompt10Encyclopedia(name: "invalid", style: .pink, createdAt: Date(timeIntervalSinceReferenceDate: .infinity))
        XCTAssertThrowsError(try persistence.commit([original, invalid]))
        XCTAssertEqual(persistence.committed, [original])
        XCTAssertEqual(defaults.data(forKey: key), bytes)
        XCTAssertEqual(Prompt10SavedLibraryPersistence(defaults: defaults, key: key).committed, [original])
    }
    func testUnreadableAndWrongTypeOriginalsCannotBeOverwritten() throws {
        let suite = "Prompt1BCorruptLibrary.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let data = Data("unreadable original".utf8)
        defaults.set(data, forKey: "library")
        var corrupt = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        XCTAssertTrue(corrupt.storageUnreadable)
        XCTAssertThrowsError(try corrupt.commit([])) { XCTAssertEqual($0 as? Prompt10LibraryError, .unreadableStorage) }
        XCTAssertEqual(defaults.data(forKey: "library"), data)
        defaults.set("wrong stored type", forKey: "other")
        var wrongType = Prompt10SavedLibraryPersistence(defaults: defaults, key: "other")
        XCTAssertTrue(wrongType.storageUnreadable)
        XCTAssertThrowsError(try wrongType.commit([]))
        XCTAssertEqual(defaults.string(forKey: "other"), "wrong stored type")
    }
}
