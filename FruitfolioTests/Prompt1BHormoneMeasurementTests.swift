import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BHormoneMeasurementTests: XCTestCase {
    func testCycleDayAcceptsDecimalScriptsAndRejectsPartialOrOverflowingValues() throws {
        for text in ["12", "١٢", "۱۲", "१२", "１２", " ١٢\n"] {
            XCTAssertEqual(try FruitfolioHormoneMeasurement.parseCycleDay(text), 12)
        }
        XCTAssertNil(try FruitfolioHormoneMeasurement.parseCycleDay("  "))
        for text in ["0", "٠", "-1", "+2", "1.5", "١٫٥", "1,000", "²", "½", "12x", "1 2", String(repeating: "9", count: 100)] {
            XCTAssertThrowsError(try FruitfolioHormoneMeasurement.parseCycleDay(text), text)
        }
    }

    func testLegacyUnknownFormatSurvivesNotesEditAndRequiresExplicitFormatForChangedResult() async throws {
        let suite = "Prompt1BHormoneLegacyFormat.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var record = FruitfolioHormoneMeasurement()
        record.result = "١٢٫٥٠"; record.unit = "pg/mL"
        defaults.set(try JSONEncoder().encode([record]), forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        record = try XCTUnwrap(store.records.first)
        record.notes = "exact report retained"
        try store.save(record, locale: Locale(identifier: "en_US"))
        XCTAssertNil(store.records.first?.resultLocaleIdentifier)
        XCTAssertEqual(store.records.first?.result, "١٢٫٥٠")
        let baseline = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        record.result = "١٣٫٥٠"
        XCTAssertThrowsError(try store.save(record, locale: Locale(identifier: "en_US"))) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .resultFormatRequired)
        }
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), baseline)
        record.resultLocaleIdentifier = "ar_EG"
        record.cycleDay = try FruitfolioHormoneMeasurement.parseCycleDay("١٢")
        try store.save(record, locale: Locale(identifier: "en_US"))
        let restored = FruitfolioHormoneMeasurementStore(defaults: defaults)
        XCTAssertEqual(restored.records.first?.result, "١٣٫٥٠")
        XCTAssertEqual(restored.records.first?.resultLocaleIdentifier, "ar_EG")
        XCTAssertEqual(restored.records.first?.cycleDay, 12)
        XCTAssertEqual(restored.records.first?.unit, "pg/mL")
    }

    func testKnownFormatIsNotReplacedByLaterAppLocaleOrMissingDraftMetadata() async throws {
        let suite = "Prompt1BHormoneKnownFormat.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement()
        record.result = "12,50"; record.unit = "nmol/L"
        try store.save(record, locale: Locale(identifier: "fr_FR"))
        record.notes = "notes after language change"
        try store.save(record, locale: Locale(identifier: "en_US"))
        XCTAssertEqual(store.records.first?.resultLocaleIdentifier, "fr_FR")
        XCTAssertEqual(store.records.first?.result, "12,50")
        record.result = "13.50"
        XCTAssertThrowsError(try store.save(record, locale: Locale(identifier: "en_US")))
        record.resultLocaleIdentifier = "en_US"
        try store.save(record, locale: Locale(identifier: "fr_FR"))
        XCTAssertEqual(store.records.first?.resultLocaleIdentifier, "en_US")
        XCTAssertEqual(store.records.first?.result, "13.50")
    }

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
