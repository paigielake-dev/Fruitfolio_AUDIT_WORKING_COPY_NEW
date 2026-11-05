import XCTest
@testable import Fruitfolio

final class Prompt1BHormonePersistenceTests: XCTestCase {
    private func withStore(_ operation: (UserDefaults, FruitfolioHormoneMeasurementPersistence) throws -> Void) throws {
        let suite = "FruitfolioHormonePersistenceTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try operation(defaults, .init(defaults: defaults, key: "measurements"))
    }
    func testExactValuesAndUnitsSurviveRestartEditExportAndDelete() throws {
        try withStore { defaults, store in
            var record = FruitfolioHormoneMeasurement()
            record.resultLocaleIdentifier = "de_DE"
            record.result = "12,50"; record.unit = "µIU/mL"; record.notes = "exact user notes"
            record.testDate = Date(timeIntervalSince1970: 1_700_000_000)
            try store.save(record, locale: Locale(identifier: "de_DE"))
            let restarted = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
            XCTAssertEqual(restarted.records, [record])
            record.result = "13,25"
            // A device-language change must not reinterpret an existing value.
            try restarted.save(record, locale: Locale(identifier: "en_US"))
            XCTAssertEqual(restarted.records.count, 1)
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            let exported = try decoder.decode([FruitfolioHormoneMeasurement].self, from: restarted.exportJSON())
            XCTAssertEqual(exported, [record])
            try restarted.delete(id: record.id)
            XCTAssertTrue(FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements").records.isEmpty)
        }
    }
    func testWrongTypeAndCorruptDataArePreservedAndBlockWritesUntilExplicitErase() throws {
        try withStore { defaults, _ in
            for original: Any in ["wrong stored type", Data("not json".utf8)] {
                defaults.set(original, forKey: "measurements")
                let store = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
                XCTAssertTrue(store.storageUnreadable)
                var record = FruitfolioHormoneMeasurement(); record.result = "1.2"; record.unit = "ng/mL"
                XCTAssertThrowsError(try store.save(record))
                XCTAssertThrowsError(try store.delete(id: UUID()))
                XCTAssertThrowsError(try store.exportJSON())
                if let original = original as? Data { XCTAssertEqual(defaults.data(forKey: "measurements"), original) }
                else { XCTAssertEqual(defaults.string(forKey: "measurements"), original as? String) }
                store.eraseAllMeasurements()
                XCTAssertFalse(store.storageUnreadable)
                XCTAssertNil(defaults.object(forKey: "measurements"))
            }
        }
    }
    func testDuplicateIdentityIsQuarantinedRatherThanEditingAmbiguousRecords() throws {
        try withStore { defaults, _ in
            var record = FruitfolioHormoneMeasurement(); record.result = "1"; record.unit = "ng/mL"
            let data = try JSONEncoder().encode([record, record])
            defaults.set(data, forKey: "measurements")
            let store = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
            XCTAssertTrue(store.storageUnreadable)
            XCTAssertTrue(store.records.isEmpty)
            XCTAssertEqual(defaults.data(forKey: "measurements"), data)
        }
    }
}
