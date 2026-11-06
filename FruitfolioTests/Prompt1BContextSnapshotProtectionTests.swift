import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BContextSnapshotProtectionTests: XCTestCase {
    func testActualStoreRejectsStaleSettersPersonalHealthExportAndClearUntilReadOnlyReload() async throws {
        let suite = "Fruitfolio.ContextStale." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for clear in [false, true] {
            defaults.removeObject(forKey: "fixture")
            let stale = Prompt27AContextStore(defaults: defaults, key: "fixture")
            stale.setTrackingGoal(.generalCycleTracking)
            let original = stale.context
            let newer = Prompt27AContextStore(defaults: defaults, key: "fixture")
            try newer.savePersonalHealth(.thyroid, text: "newer user-provided note", provenance: .userReportsClinicianConfirmed)
            let bytes = try XCTUnwrap(defaults.data(forKey: "fixture"))
            // Existing context storage uses milliseconds-since-1970. Compare
            // reload with the actual saved baseline, not a pre-encoding Date's
            // extra floating-point precision that was never stored.
            let latest = try Prompt27AContextCodec().decode(bytes)
            if clear { defaults.removeObject(forKey: "fixture") }
            stale.setReproductiveStage(.pregnant)
            XCTAssertEqual(stale.storageProtectionReason, .storageChanged)
            XCTAssertEqual(stale.context, original)
            XCTAssertThrowsError(try stale.savePersonalHealth(.dna, text: "must not overwrite"))
            XCTAssertThrowsError(try stale.exportReadableJSON())
            XCTAssertFalse(stale.clearContext())
            XCTAssertNotNil(stale.persistenceMessage)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            stale.reloadSavedContext()
            XCTAssertNil(stale.storageProtectionReason)
            XCTAssertNil(stale.persistenceMessage)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            if clear { XCTAssertTrue(stale.context.isCompletelyUnspecified) }
            else { XCTAssertEqual(stale.context, latest) }
            stale.setTrackingGoal(.tryingToConceive)
            XCTAssertEqual(Prompt27AContextStore(defaults: defaults, key: "fixture").context.trackingGoal.value, .tryingToConceive)
        }
    }

    func testUnknownNestedContextFieldsPreserveReadableOptionalReportsAndProvenance() async throws {
        let suite = "Fruitfolio.ContextFuture." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var context = Prompt27AUserReproductiveContext(timestamp: Date(timeIntervalSince1970: 0))
        context.setReproductiveStage(.pregnant, at: Date(timeIntervalSince1970: 10))
        try context.setPersonalHealth(.thyroid, text: "exact user wording; not a diagnosis by the app",
            provenance: .userReportsClinicianConfirmed, at: Date(timeIntervalSince1970: 20))
        let codec = Prompt27AContextCodec()
        let known = try codec.encode(context)
        for location in ["root", "personalHealth"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: known) as? [String: Any])
            if location == "root" { object["futureContextPolicy"] = ["revision": 99] }
            else {
                var entries = try XCTUnwrap(object["personalHealthEntries"] as? [String: Any])
                var thyroid = try XCTUnwrap(entries["thyroid"] as? [String: Any])
                thyroid["futureProvenance"] = "do not discard"
                entries["thyroid"] = thyroid
                object["personalHealthEntries"] = entries
            }
            let future = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
            defaults.set(future, forKey: "fixture")
            let store = Prompt27AContextStore(defaults: defaults, key: "fixture")
            XCTAssertFalse(store.didRecoverCorruptStoredContext)
            XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
            XCTAssertEqual(store.context, context)
            store.setReproductiveStage(.postpartum)
            XCTAssertThrowsError(try store.savePersonalHealth(.thyroid, text: "changed"))
            XCTAssertThrowsError(try store.exportReadableJSON())
            XCTAssertEqual(store.context, context)
            XCTAssertEqual(defaults.data(forKey: "fixture"), future)
            store.reloadSavedContext()
            XCTAssertEqual(defaults.data(forKey: "fixture"), future)
            XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
            // The actual view invokes clear only after explicit destructive confirmation.
            XCTAssertTrue(store.clearContext())
            XCTAssertNil(defaults.object(forKey: "fixture"))
            XCTAssertTrue(store.context.isCompletelyUnspecified)
        }
    }

    func testActualCorruptStoreReloadAndConfirmedClearNeverTouchOtherDomains() async throws {
        let suite = "Fruitfolio.ContextCorruptStore." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data("unreadable original".utf8)
        let other = Data("independent cycle or library record".utf8)
        defaults.set(original, forKey: "fixture")
        defaults.set(other, forKey: "other-domain")
        let store = Prompt27AContextStore(defaults: defaults, key: "fixture")
        XCTAssertTrue(store.didRecoverCorruptStoredContext)
        XCTAssertEqual(store.storageProtectionReason, .unreadableStorage)
        store.setTrackingGoal(.tryingToConceive)
        store.reloadSavedContext()
        XCTAssertEqual(defaults.data(forKey: "fixture"), original)
        XCTAssertEqual(defaults.data(forKey: "other-domain"), other)
        XCTAssertTrue(store.eraseLocalContextData())
        XCTAssertNil(store.persistenceMessage)
        XCTAssertEqual(defaults.data(forKey: "other-domain"), other)
    }
}
