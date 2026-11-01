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

extension HormoneMeasurementTests {
    func testRepeatedResultsRetainTheirOwnDatesOptionalFieldsAndExactStrings() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("measurements.json")
        let store = HormoneMeasurementStore(fileURL: file)
        var first = record()
        first.result = "+2,500"
        first.testDate = Date(timeIntervalSince1970: 1_700_000_000)
        first.sampleType = "saliva (as reported)"
        first.cycleDay = "012"
        first.laboratoryReferenceRange = "lab text: 0.10–9.90 ng/mL"
        first.notes = "my original note — no interpretation"
        var second = first
        second.id = UUID()
        second.testDate = first.testDate.addingTimeInterval(86_400 * 7)
        second.result = "3.1250"
        second.unit = " pmol/L "
        try store.save(first); try store.save(second)
        let reopened = HormoneMeasurementStore(fileURL: file)
        XCTAssertEqual(reopened.measurements.count, 2)
        let old = try XCTUnwrap(reopened.measurements.first { $0.id == first.id })
        let newer = try XCTUnwrap(reopened.measurements.first { $0.id == second.id })
        XCTAssertEqual(old.result, "+2,500"); XCTAssertEqual(old.unit, " ng/mL ")
        XCTAssertEqual(old.testDate, first.testDate)
        XCTAssertEqual(old.sampleType, first.sampleType)
        XCTAssertEqual(old.cycleDay, "012")
        XCTAssertEqual(old.laboratoryReferenceRange, first.laboratoryReferenceRange)
        XCTAssertEqual(old.notes, first.notes)
        XCTAssertEqual(newer.result, "3.1250"); XCTAssertEqual(newer.unit, " pmol/L ")
        XCTAssertEqual(newer.testDate, second.testDate)
        try reopened.delete(id: first.id)
        let remaining = HormoneMeasurementStore(fileURL: file).measurements
        XCTAssertEqual(remaining.count, 1); XCTAssertEqual(remaining.first?.id, second.id)
        XCTAssertEqual(remaining.first?.result, "3.1250")
    }

    func testOtherHormoneNameAndMissingUnitRemainControlledWithoutInventedDefaults() {
        var value = record()
        value.hormone = .other
        XCTAssertNotNil(value.validationError)
        value.otherHormoneName = String(repeating: "a", count: 101)
        XCTAssertNotNil(value.validationError)
        value.otherHormoneName = "user-reported hormone"
        XCTAssertNil(value.validationError)
        value.unit = " \n "
        XCTAssertNotNil(value.validationError)
        XCTAssertEqual(value.unit, " \n ", "Validation must not silently replace an absent unit")
        value.unit = " user-unit "
        value.sampleType = ""; value.cycleDay = ""; value.laboratoryReferenceRange = ""; value.notes = ""
        XCTAssertNil(value.validationError)
        XCTAssertTrue(value.sampleType.isEmpty && value.cycleDay.isEmpty && value.laboratoryReferenceRange.isEmpty && value.notes.isEmpty)
        value.testDateWasProvided = false
        XCTAssertNotNil(value.validationError, "Today's default date must not count as a confirmed test date")
    }
}
