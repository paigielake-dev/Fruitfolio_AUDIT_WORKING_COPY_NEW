import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BLibrarySnapshotProtectionTests: XCTestCase {
    func testActualStoreRollsBackStaleMutationAndReloadReadsLatestWithoutWriting() async throws {
        let suite = "Fruitfolio.LibraryStale." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for clear in [false, true] {
            defaults.removeObject(forKey: "fixture")
            let stale = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            let first = try stale.createEncyclopedia(name: "original", style: .sage)
            let newer = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            _ = try newer.createEncyclopedia(name: "newer", style: .pink)
            let bytes = defaults.data(forKey: "fixture")
            if clear { defaults.removeObject(forKey: "fixture") }
            XCTAssertThrowsError(try stale.deleteEncyclopedia(id: first.id)) {
                XCTAssertEqual($0 as? Prompt10LibraryError, .storageChanged)
            }
            XCTAssertEqual(stale.encyclopedias.map(\.id), [first.id])
            XCTAssertEqual(stale.storageProtectionReason, .storageChanged)
            XCTAssertFalse(stale.canCreateEncyclopedia)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            stale.reloadSavedLibrary()
            XCTAssertNil(stale.storageProtectionReason)
            XCTAssertEqual(stale.count, clear ? 0 : 2)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            _ = try stale.createEncyclopedia(name: "after explicit reload", style: .yellow)
            XCTAssertEqual(Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture").count, clear ? 1 : 3)
        }
    }

    func testUnknownNestedPageAndBookFieldsPreserveOriginalAndReadableRecords() async throws {
        let suite = "Fruitfolio.LibraryFuture." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let id = UUID(), chapterID = UUID()
        let page = Prompt10SavedPage(chapterID: chapterID, question: "question", answer: "12.500 pg/mL [A]",
            saveType: .fullAnswer, sourceIDs: ["A"], sourceVersions: ["A": "v1"], notes: "unchanged notes")
        let chapter = Prompt10Chapter(id: chapterID, encyclopediaID: id, name: "chapter", order: 0, pages: [page])
        let book = Prompt10Encyclopedia(id: id, name: "readable", style: .sage, chapters: [chapter])
        let original = try JSONEncoder().encode([book])
        for level in ["book", "page", "null"] {
            var objects = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [[String: Any]])
            if level == "book" { objects[0]["futurePolicy"] = ["revision": 99] }
            else if level == "null" { objects[0]["subtitle"] = NSNull() }
            else {
                var chapters = try XCTUnwrap(objects[0]["chapters"] as? [[String: Any]])
                var pages = try XCTUnwrap(chapters[0]["pages"] as? [[String: Any]])
                pages[0]["futureEvidence"] = ["newRequiredField": true]
                chapters[0]["pages"] = pages
                objects[0]["chapters"] = chapters
            }
            let future = try JSONSerialization.data(withJSONObject: objects, options: [.sortedKeys])
            defaults.set(future, forKey: "fixture")
            let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            XCTAssertFalse(store.storageUnreadable)
            XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
            XCTAssertEqual(store.encyclopedias.first?.chapters.first?.pages.first?.notes, "unchanged notes")
            XCTAssertFalse(store.canCreateEncyclopedia)
            XCTAssertThrowsError(try store.deleteEncyclopedia(id: id)) {
                XCTAssertEqual($0 as? Prompt10LibraryError, .unsupportedStorage)
            }
            XCTAssertEqual(store.count, 1)
            XCTAssertEqual(defaults.data(forKey: "fixture"), future)
            store.reloadSavedLibrary()
            XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
            XCTAssertEqual(defaults.data(forKey: "fixture"), future)
            defaults.set(original, forKey: "fixture")
            store.reloadSavedLibrary()
            XCTAssertNil(store.storageProtectionReason)
            XCTAssertEqual(defaults.data(forKey: "fixture"), original)
        }
    }

    func testFieldCoverageComparesNestedKeysWithoutNormalizingScientificValues() async {
        func data(_ string: String) -> Data { Data(string.utf8) }
        XCTAssertTrue(FruitfolioJSONFieldCoverage.preservesFields(original: data(#"{"value":"12.500","unit":"pg/mL"}"#),
            encoded: data(#"{"value":"12.500","unit":"pg/mL","knownDefault":true}"#)))
        XCTAssertFalse(FruitfolioJSONFieldCoverage.preservesFields(original: data(#"{"pages":[{"source":{"future":true}}]}"#),
            encoded: data(#"{"pages":[{"source":{}}]}"#)))
        XCTAssertFalse(FruitfolioJSONFieldCoverage.preservesFields(original: data(#"{"future":null}"#), encoded: data("{}")))
        XCTAssertFalse(FruitfolioJSONFieldCoverage.preservesFields(original: data("[1,2]"), encoded: data("[1]")))
        XCTAssertFalse(FruitfolioJSONFieldCoverage.preservesFields(original: data("invalid"), encoded: data("[]")))
        // Field coverage is not value/clinical equivalence; domain validation remains required.
    }
}
