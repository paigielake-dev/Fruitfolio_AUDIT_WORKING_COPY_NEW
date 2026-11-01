import XCTest
@testable import Fruitfolio

@MainActor
final class HormoneMeasurementTests: XCTestCase {
    private func record() -> HormoneMeasurement {
        var value = HormoneMeasurement()
        value.testDateWasProvided = true
        value.result = "2.50"
        value.unit = " ng/mL "
        return value
    }

    func testValidationAndExactUnitPreservation() {
        var value = record()
        XCTAssertNil(value.validationError)
        XCTAssertEqual(value.unit, " ng/mL ")
        value.testDateWasProvided = false
        XCTAssertNotNil(value.validationError)
        value.testDateWasProvided = true
        for invalid in ["", "NaN", "inf", "--2", "2.5 extra", "1,000.5"] {
            value.result = invalid
            XCTAssertNotNil(value.validationError, invalid)
        }
        value.result = "2,50"
        XCTAssertNil(value.validationError)
        value.hormone = .other
        XCTAssertNotNil(value.validationError)
        value.otherHormoneName = "user-reported hormone"
        XCTAssertNil(value.validationError)
        value.cycleDay = "0"
        XCTAssertNotNil(value.validationError)
        value.cycleDay = "12"
        XCTAssertNil(value.validationError)
    }

    func testSaveEditRestartAndDeletePreserveRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("measurements.json")
        let store = HormoneMeasurementStore(fileURL: file)
        var value = record()
        try store.save(value)
        var reopened = HormoneMeasurementStore(fileURL: file)
        XCTAssertEqual(reopened.measurements.first?.result, "2.50")
        XCTAssertEqual(reopened.measurements.first?.unit, " ng/mL ")
        value.result = "3.125"
        value.notes = "original user note"
        try reopened.save(value)
        reopened = HormoneMeasurementStore(fileURL: file)
        XCTAssertEqual(reopened.measurements.count, 1)
        XCTAssertEqual(reopened.measurements.first?.notes, "original user note")
        try reopened.delete(id: value.id)
        XCTAssertTrue(HormoneMeasurementStore(fileURL: file).measurements.isEmpty)
    }

    func testUnreadableStorageCannotBeSilentlyOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("measurements.json")
        let original = Data("unreadable fixture".utf8)
        try original.write(to: file)
        let store = HormoneMeasurementStore(fileURL: file)
        XCTAssertNotNil(store.loadError)
        XCTAssertThrowsError(try store.save(record()))
        XCTAssertThrowsError(try store.delete(id: UUID()))
        XCTAssertEqual(try Data(contentsOf: file), original)
        try store.eraseAll()
        XCTAssertNil(store.loadError)
        try store.save(record())
        XCTAssertEqual(store.measurements.count, 1)
    }
}
