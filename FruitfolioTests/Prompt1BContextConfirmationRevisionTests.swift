import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BContextConfirmationRevisionTests: XCTestCase {
    func testOldClearCannotEraseNewerSameStoreContextAndSuccessfulClearCannotReplay() async throws {
        let suite = "Fruitfolio.ContextClearIntent." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults, key: "fixture")
        store.setTrackingGoal(.generalCycleTracking)
        let oldRevision = store.savedRecordRevision
        try store.savePersonalHealth(.thyroid, text: "newer private report")
        let latest = defaults.data(forKey: "fixture")
        XCTAssertFalse(store.clearContext(expectedRevision: oldRevision))
        XCTAssertEqual(defaults.data(forKey: "fixture"), latest)
        XCTAssertEqual(store.context.personalHealthEntries["thyroid"]?.text, "newer private report")
        let current = store.savedRecordRevision
        XCTAssertTrue(store.clearContext(expectedRevision: current))
        XCTAssertNil(defaults.object(forKey: "fixture"))
        XCTAssertFalse(store.clearContext(expectedRevision: current))
        XCTAssertNil(defaults.object(forKey: "fixture"))
    }

    func testOldEditorSaveAndRemovalCannotOverwriteANewerContextButCurrentRemovalErasesText() async throws {
        let suite = "Fruitfolio.ContextEditorIntent." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults, key: "fixture")
        try store.savePersonalHealth(.dna, text: "private original wording", provenance: .userProvided)
        let editorRevision = store.savedRecordRevision
        store.setTrackingGoal(.tryingToConceive)
        let latest = defaults.data(forKey: "fixture")
        for status in [FruitfolioPersonalHealthStatus.provided, .removed] {
            XCTAssertThrowsError(try store.savePersonalHealth(.dna, text: "old editor draft", status: status,
                expectedRevision: editorRevision)) {
                XCTAssertEqual($0 as? Prompt27ALocalContextPersistence.Failure, .confirmationChanged)
            }
            XCTAssertEqual(defaults.data(forKey: "fixture"), latest)
            XCTAssertEqual(store.context.personalHealthEntries["dna"]?.text, "private original wording")
        }
        try store.savePersonalHealth(.dna, text: "ignored removal text", status: .removed,
            expectedRevision: store.savedRecordRevision)
        XCTAssertNil(store.context.personalHealthEntries["dna"]?.text)
        let bytes = try XCTUnwrap(defaults.data(forKey: "fixture"))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("private original wording"))
        XCTAssertFalse(String(decoding: bytes, as: UTF8.self).contains("ignored removal text"))
        XCTAssertEqual(store.context.trackingGoal.value, .tryingToConceive)
    }

    func testReloadInvalidatesOldEditorEvenWhenPersistedValuesDoNotChange() async throws {
        let suite = "Fruitfolio.ContextReloadIntent." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt27AContextStore(defaults: defaults, key: "fixture")
        try store.savePersonalHealth(.thyroid, text: "original wording")
        let revision = store.savedRecordRevision
        let bytes = defaults.data(forKey: "fixture")
        store.reloadSavedContext()
        XCTAssertThrowsError(try store.savePersonalHealth(.thyroid, text: "stale draft", expectedRevision: revision))
        XCTAssertFalse(store.clearContext(expectedRevision: revision))
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        XCTAssertEqual(store.context.personalHealthEntries["thyroid"]?.text, "original wording")
    }
}
