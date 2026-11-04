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

    func testExplicitBulkEraseRemovesOnlyTheIntendedHealthFileAndPreservesSiblingAndPreferenceBytes() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let suite = "Fruitfolio.HormoneEraseIsolation.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = HormoneMeasurementStore(fileURL: directory.appendingPathComponent("hormone-measurements-v1.json"))
        try store.save(record())
        let sibling = directory.appendingPathComponent("independent-cycle-records.json")
        let original = Data("{\"original-cycle-record\":\"2026-10-01\"}".utf8)
        try original.write(to: sibling)
        for key in ["account", "saved-guides", "game-progress", "health-context"] {
            defaults.set(Data((key + ":original-fixture-bytes").utf8), forKey: key)
        }
        let before = try XCTUnwrap(defaults.persistentDomain(forName: suite)) as NSDictionary
        try store.eraseAll()
        XCTAssertTrue(store.measurements.isEmpty)
        XCTAssertTrue(HormoneMeasurementStore(fileURL: directory.appendingPathComponent("hormone-measurements-v1.json")).measurements.isEmpty)
        XCTAssertEqual(try Data(contentsOf: sibling), original)
        XCTAssertEqual(try XCTUnwrap(defaults.persistentDomain(forName: suite)) as NSDictionary, before)
    }

    func testDuplicateStoredRecordIdentitiesFailClosedAcrossRestartsWithoutDiscardingOriginalValues() throws {
        struct Snapshot: Encodable { let version: Int; let measurements: [HormoneMeasurement] }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("measurements.json")
        let first = record()
        var conflicting = first
        conflicting.result = "99.1250"
        conflicting.notes = "separate stored observation sharing an invalid duplicate ID"
        let original = try JSONEncoder().encode(Snapshot(version: 1, measurements: [first, conflicting]))
        try original.write(to: file)
        for _ in 0..<2 {
            let reopened = HormoneMeasurementStore(fileURL: file)
            XCTAssertNotNil(reopened.loadError)
            XCTAssertThrowsError(try reopened.save(record()))
            XCTAssertThrowsError(try reopened.delete(id: first.id))
            XCTAssertEqual(try Data(contentsOf: file), original,
                           "Recovery must never deduplicate or select one of conflicting medical records")
        }
        let reopened = HormoneMeasurementStore(fileURL: file)
        try reopened.eraseAll() // Only an explicit guarded production action may discard these bytes.
        XCTAssertNil(reopened.loadError)
        try reopened.save(record())
        XCTAssertEqual(HormoneMeasurementStore(fileURL: file).measurements.count, 1)
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
    func testRetryReadsTheRecoveredSnapshotWithoutOverwritingUnreadableBytesOrInventingEmptyRecords() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("measurements.json")
        let originalStore = HormoneMeasurementStore(fileURL: file)
        let original = record()
        try originalStore.save(original)
        let goodBytes = try Data(contentsOf: file)
        let badBytes = Data("unreadable original fixture".utf8)
        try badBytes.write(to: file)
        let failed = HormoneMeasurementStore(fileURL: file)
        failed.retryLoad()
        XCTAssertNotNil(failed.loadError)
        XCTAssertThrowsError(try failed.save(record()))
        XCTAssertEqual(try Data(contentsOf: file), badBytes)
        try goodBytes.write(to: file) // Simulates the original snapshot becoming readable again.
        failed.retryLoad()
        XCTAssertNil(failed.loadError)
        XCTAssertEqual(try Data(contentsOf: file), goodBytes, "Retry must not rewrite metadata or timestamps")
        XCTAssertEqual(failed.measurements, originalStore.measurements)
        XCTAssertEqual(failed.measurements.first?.unit, " ng/mL ")
    }

    func testRetryDoesNotTreatADisappearedUnreadableFileAsASuccessfulEmptyReset() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("measurements.json")
        try Data("unreadable fixture".utf8).write(to: file)
        let failed = HormoneMeasurementStore(fileURL: file)
        try FileManager.default.removeItem(at: file)
        failed.retryLoad()
        XCTAssertNotNil(failed.loadError)
        XCTAssertThrowsError(try failed.save(record()))
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        try failed.eraseAll() // Existing separate explicit deletion/recovery path.
        try failed.save(record())
        XCTAssertEqual(HormoneMeasurementStore(fileURL: file).measurements.count, 1)
    }

    func testHistoryGroupsPreserveExactUnitAndSampleBytesRatherThanUnicodeNormalization() {
        var first = record(), second = record()
        first.unit = "\u{212B}"
        second.unit = "\u{00C5}"
        XCTAssertEqual(first.unit, second.unit, "Canonical String equality is insufficient for exact entered-unit grouping")
        let groups = HormoneMeasurementSeries.groups([first, second])
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(Set(groups.map { Data($0.id.unit.utf8) }), Set([Data(first.unit.utf8), Data(second.unit.utf8)]))
        XCTAssertEqual(groups.flatMap(\.records).count, 2)
        XCTAssertTrue(groups.allSatisfy { $0.records.count == 1 })
    }

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
