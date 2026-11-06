import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BHormoneMeasurementTests: XCTestCase {
    func testCreateEditDeletePreservesExactUnitsAndPersists() async throws {
        let suite = "Prompt1BHormone.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.50"
        record.unit = "pg/mL"
        try store.save(record, locale: Locale(identifier: "en_US"))
        record.notes = "reported by laboratory"
        try store.save(record, locale: Locale(identifier: "en_US"))
        let restored = FruitfolioHormoneMeasurementStore(defaults: defaults)
        XCTAssertEqual(restored.records.count, 1)
        XCTAssertEqual(restored.records.first?.result, "12.50")
        XCTAssertEqual(restored.records.first?.unit, "pg/mL")
        XCTAssertEqual(restored.records.first?.notes, record.notes)
        try restored.delete(id: record.id)
        XCTAssertTrue(FruitfolioHormoneMeasurementStore(defaults: defaults).records.isEmpty)
    }
    func testExplicitExportAndEraseContainOnlyMeasurements() async throws {
        let suite = "Prompt1BHormoneExport.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("preserve me", forKey: "unrelated.setting")
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement()
        record.result = "2.4"; record.unit = "nmol/L"
        try store.save(record, locale: Locale(identifier: "en_US"))
        let export = try store.exportJSON()
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: export) as? [[String: Any]])
        XCTAssertEqual(object.count, 1)
        XCTAssertEqual(object[0]["unit"] as? String, "nmol/L")
        try store.eraseAllMeasurements()
        XCTAssertNil(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey))
        XCTAssertEqual(defaults.string(forKey: "unrelated.setting"), "preserve me")
    }

    func testIncompleteOrMalformedMeasurementsAreRejected() async {
        var record = FruitfolioHormoneMeasurement()
        for value in ["", "NaN", "12invalid", "-2"] {
            record.result = value
            record.unit = "ng/mL"
            XCTAssertThrowsError(try record.validate(locale: Locale(identifier: "en_US")))
        }
    }
    func testCorruptStorageIsPreservedInsteadOfOverwritten() async throws {
        let suite = "Prompt1BHormoneCorrupt.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = Data([0, 1, 2])
        defaults.set(original, forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        XCTAssertTrue(store.storageUnreadable)
        XCTAssertThrowsError(try store.save(FruitfolioHormoneMeasurement()))
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), original)
    }
}
