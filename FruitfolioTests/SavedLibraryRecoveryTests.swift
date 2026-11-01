import XCTest
@testable import Fruitfolio

@MainActor
final class SavedLibraryRecoveryTests: XCTestCase {
    func testCorruptLibraryCannotBeOverwrittenByCreatingNewBook() throws {
        let suite = "LibraryRecovery-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data("unreadable library fixture".utf8)
        defaults.set(original, forKey: "library")
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        XCTAssertNotNil(store.loadError)
        XCTAssertThrowsError(try store.createEncyclopedia(name: "must not overwrite", style: .sage))
        XCTAssertEqual(defaults.data(forKey: "library"), original)
        XCTAssertTrue(store.encyclopedias.isEmpty)
        store.retryLoad()
        XCTAssertEqual(defaults.data(forKey: "library"), original)
    }
    func testUnexpectedStoredTypeIsNotMistakenForEmptyLibrary() throws {
        let suite = "LibraryType-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("original stored value", forKey: "library")
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        XCTAssertNotNil(store.loadError)
        XCTAssertThrowsError(try store.createEncyclopedia(name: "new", style: .sage))
        XCTAssertEqual(defaults.string(forKey: "library"), "original stored value")
        defaults.removeObject(forKey: "library") // Explicit reset is independent of failed automatic loading.
        store.retryLoad()
        XCTAssertNil(store.loadError)
        XCTAssertNoThrow(try store.createEncyclopedia(name: "after reset", style: .sage))
    }
}
