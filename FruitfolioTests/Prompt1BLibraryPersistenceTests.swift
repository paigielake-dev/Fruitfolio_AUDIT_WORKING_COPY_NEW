import XCTest
@testable import Fruitfolio

private final class Prompt1BLibraryWriteFaultDefaults: UserDefaults, @unchecked Sendable {
    enum Fault { case accept, drop, replace(Data), wrongType }
    var fault: Fault = .accept
    private(set) var attempts = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == "library" else { super.set(value, forKey: key); return }
        attempts += 1
        switch fault {
        case .accept: super.set(value, forKey: key)
        case .drop: break
        case .replace(let bytes): super.set(bytes, forKey: key)
        case .wrongType: super.set("external replacement", forKey: key)
        }
    }
}

@MainActor
final class Prompt1BLibraryPersistenceTests: XCTestCase {
    func testFailedEncodingPreservesCommittedSnapshotAndStoredBytes() async throws {
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
    func testUnreadableAndWrongTypeOriginalsCannotBeOverwritten() async throws {
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
    func testDroppedFirstWriteCannotAdvanceCommittedSnapshot() async throws {
        let suite = "Fruitfolio.library-first-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        defaults.fault = .drop
        XCTAssertThrowsError(try persistence.commit([.init(name: "QA first", style: .sage)]))
        XCTAssertEqual(persistence.committed, [])
        XCTAssertNil(defaults.object(forKey: "library"))
        XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
    }
    func testDroppedReplacementBlocksUntilReloadWithoutLosingLastAcknowledgment() async throws {
        let suite = "Fruitfolio.library-replace-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        let original = Prompt10Encyclopedia(name: "QA original", style: .sage)
        let next = Prompt10Encyclopedia(name: "QA next", style: .pink)
        try persistence.commit([original])
        let bytes = try XCTUnwrap(defaults.data(forKey: "library"))
        defaults.fault = .drop
        XCTAssertThrowsError(try persistence.commit([next]))
        XCTAssertEqual(persistence.committed, [original])
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
        XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
        defaults.fault = .accept
        let attempts = defaults.attempts
        XCTAssertThrowsError(try persistence.commit([next])) { XCTAssertEqual($0 as? Prompt10LibraryError, .persistenceFailure) }
        XCTAssertEqual(defaults.attempts, attempts)
        persistence.reload()
        XCTAssertNil(persistence.protectionReason)
        XCTAssertEqual(persistence.committed, [original])
        try persistence.commit([next])
        XCTAssertEqual(Prompt10SavedLibraryPersistence(defaults: defaults, key: "library").committed, [next])
    }
    func testPostWriteForeignDataOrWrongTypeIsNeverRolledBack() async throws {
        for wrongType in [false, true] {
            let suite = "Fruitfolio.library-substitute." + UUID().uuidString
            let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
            let original = Prompt10Encyclopedia(name: "QA original", style: .sage)
            try persistence.commit([original])
            let foreign = try JSONEncoder().encode([Prompt10Encyclopedia(name: "QA external", style: .pink)])
            defaults.fault = wrongType ? .wrongType : .replace(foreign)
            XCTAssertThrowsError(try persistence.commit([]))
            XCTAssertEqual(persistence.committed, [original])
            XCTAssertEqual(persistence.protectionReason, .persistenceFailure)
            XCTAssertEqual(defaults.attempts, 2, "No rollback may overwrite an observed replacement")
            if wrongType { XCTAssertEqual(defaults.string(forKey: "library"), "external replacement") }
            else { XCTAssertEqual(defaults.data(forKey: "library"), foreign) }
        }
    }
    func testRealStoreRejectsDroppedGuideDescriptionAndCreationWithoutFalseMemorySuccess() async throws {
        let suite = "Fruitfolio.library-store-drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLibraryWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let original = try store.createGuideEncyclopedia(name: "QA guide", subtitle: "original", style: .sage)
        let bytes = try XCTUnwrap(defaults.data(forKey: "library"))
        defaults.fault = .drop
        XCTAssertThrowsError(try store.updateEncyclopediaDescription(id: original.id, description: "unacknowledged draft"))
        XCTAssertEqual(store.encyclopedia(id: original.id), original)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
        store.reloadSavedLibrary()
        XCTAssertNil(store.storageProtectionReason)
        XCTAssertThrowsError(try store.createGuideEncyclopedia(name: "unacknowledged guide", subtitle: "draft", style: .pink))
        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.data(forKey: "library"), bytes)
    }

}
