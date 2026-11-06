import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BHormoneSnapshotProtectionTests: XCTestCase {
    private func measurement() throws -> FruitfolioHormoneMeasurement {
        var record = FruitfolioHormoneMeasurement()
        record.result = "12,500"
        record.unit = "µIU/mL"
        record.resultLocaleIdentifier = "de_DE"
        record.notes = "original note — do not normalize"
        record.reportedTestDay = try .init(year: 2026, month: 10, day: 16)
        return record
    }

    func testActualStoreRejectsStaleSaveDeleteExportAndEraseUntilReadOnlyReload() async throws {
        let suite = "Fruitfolio.MeasurementStale." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for clear in [false, true] {
            defaults.removeObject(forKey: "fixture")
            let stale = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
            let original = try measurement()
            try stale.save(original)
            let newer = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
            var changed = original
            changed.notes = "newer independently saved note"
            try newer.save(changed)
            let bytes = defaults.data(forKey: "fixture")
            if clear { defaults.removeObject(forKey: "fixture") }
            XCTAssertThrowsError(try stale.save(original)) { XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .storageChanged) }
            XCTAssertThrowsError(try stale.delete(id: original.id))
            XCTAssertThrowsError(try stale.exportJSON())
            XCTAssertThrowsError(try stale.eraseAllMeasurements())
            XCTAssertEqual(stale.storageProtectionReason, .storageChanged)
            XCTAssertEqual(stale.records.first?.notes, original.notes)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            stale.reloadSavedMeasurements()
            XCTAssertNil(stale.storageProtectionReason)
            XCTAssertEqual(stale.records.count, clear ? 0 : 1)
            XCTAssertEqual(stale.records.first?.notes, clear ? nil : changed.notes)
            XCTAssertEqual(defaults.data(forKey: "fixture"), clear ? nil : bytes)
            try stale.save(original)
            XCTAssertEqual(FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture").records.first?.result, "12,500")
        }
    }

    func testUnknownFieldsKeepReadableValuesAndRawOriginalUntilExplicitErase() async throws {
        let suite = "Fruitfolio.MeasurementFuture." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = try measurement()
        let known = try JSONEncoder().encode([original])
        var objects = try XCTUnwrap(JSONSerialization.jsonObject(with: known) as? [[String: Any]])
        objects[0]["futureAssayMethod"] = ["revision": 99, "mustKeep": true]
        let future = try JSONSerialization.data(withJSONObject: objects, options: [.sortedKeys])
        defaults.set(future, forKey: "fixture")
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        XCTAssertFalse(store.storageUnreadable)
        XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
        XCTAssertEqual(store.records, [original])
        XCTAssertEqual(store.history().first?.unit, "µIU/mL")
        XCTAssertEqual(store.history().first?.reportedTestDay, original.reportedTestDay)
        XCTAssertThrowsError(try store.save(original))
        XCTAssertThrowsError(try store.delete(id: original.id))
        XCTAssertThrowsError(try store.exportJSON())
        XCTAssertEqual(defaults.data(forKey: "fixture"), future)
        store.reloadSavedMeasurements()
        XCTAssertEqual(defaults.data(forKey: "fixture"), future)
        XCTAssertEqual(store.storageProtectionReason, .unsupportedStorage)
        // This API is called by UI only after the existing destructive confirmation.
        try store.eraseAllMeasurements()
        XCTAssertNil(defaults.object(forKey: "fixture"))
        XCTAssertNil(store.storageProtectionReason)
        XCTAssertTrue(store.records.isEmpty)
    }
}
