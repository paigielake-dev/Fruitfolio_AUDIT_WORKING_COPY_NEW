import XCTest
@testable import Fruitfolio

private final class HormoneFaultDefaults: UserDefaults, @unchecked Sendable {
    enum Fault { case accept, drop, replace(Data), wrongType }
    var writeFault: Fault = .accept
    var eraseFault: Fault = .accept
    private(set) var writes = 0
    private(set) var erasures = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == "measurements" else { super.set(value, forKey: key); return }
        writes += 1
        switch writeFault {
        case .accept: super.set(value, forKey: key)
        case .drop: break
        case .replace(let bytes): super.set(bytes, forKey: key)
        case .wrongType: super.set("foreign replacement", forKey: key)
        }
    }
    override func removeObject(forKey key: String) {
        guard key == "measurements" else { super.removeObject(forKey: key); return }
        erasures += 1
        switch eraseFault {
        case .accept: super.removeObject(forKey: key)
        case .drop: break
        case .replace(let bytes): super.removeObject(forKey: key); super.set(bytes, forKey: key)
        case .wrongType: super.removeObject(forKey: key); super.set("foreign replacement", forKey: key)
        }
    }
}

final class Prompt1BHormonePersistenceTests: XCTestCase {
    func testDeletingMissingIDDoesNotWriteOrInvalidateAcknowledgedRevision() throws {
        let suite = "FruitfolioMissingMeasurementDelete." + UUID().uuidString
        let defaults = try XCTUnwrap(HormoneFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements")
        let emptyRevision = store.revision
        try store.delete(id: UUID())
        XCTAssertEqual(defaults.writes, 0)
        XCTAssertNil(defaults.object(forKey: "measurements"))
        XCTAssertEqual(store.revision, emptyRevision)
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.50"; record.unit = "ng/mL"
        try store.save(record, locale: Locale(identifier: "en_US"))
        let bytes = defaults.data(forKey: "measurements")
        let revision = store.revision
        let writes = defaults.writes
        try store.delete(id: UUID())
        XCTAssertEqual(defaults.writes, writes)
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(store.revision, revision)
        XCTAssertEqual(store.records.map(\.id), [record.id])
        // A no-op still must detect a foreign snapshot and never hide protection.
        defaults.set("foreign replacement", forKey: "measurements")
        XCTAssertThrowsError(try store.delete(id: UUID()))
        XCTAssertEqual(defaults.string(forKey: "measurements"), "foreign replacement")
        XCTAssertEqual(store.revision, revision)
    }

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
                try store.eraseAllMeasurements()
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
    private func faultFixture() throws -> (String, HormoneFaultDefaults, FruitfolioHormoneMeasurementPersistence) {
        let suite = "Fruitfolio.MeasurementAck." + UUID().uuidString
        let defaults = try XCTUnwrap(HormoneFaultDefaults(suiteName: suite))
        return (suite, defaults, FruitfolioHormoneMeasurementPersistence(defaults: defaults, key: "measurements"))
    }
    private func faultRecord() -> FruitfolioHormoneMeasurement {
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.500"; record.unit = " pg/mL "; record.resultLocaleIdentifier = "en_US"
        record.notes = "QA exact original"
        return record
    }

    func testDroppedFirstMeasurementWriteCannotAdvanceCacheOrRevision() throws {
        let (suite, defaults, store) = try faultFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let revision = store.revision
        defaults.writeFault = .drop
        XCTAssertThrowsError(try store.save(faultRecord()))
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertNil(defaults.object(forKey: "measurements"))
        XCTAssertEqual(store.revision, revision)
        XCTAssertEqual(store.protectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.writes, 1)
    }

    func testDroppedMeasurementEditAndSingleDeleteKeepAcknowledgmentUntilExplicitReload() throws {
        let (suite, defaults, store) = try faultFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = faultRecord()
        try store.save(original)
        let bytes = defaults.data(forKey: "measurements")
        let revision = store.revision
        var draft = original; draft.notes = "unsaved draft"
        defaults.writeFault = .drop
        XCTAssertThrowsError(try store.save(draft, intent: .edit(original)))
        XCTAssertEqual(store.records, [original])
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(store.revision, revision)
        let writes = defaults.writes
        XCTAssertThrowsError(try store.delete(id: original.id))
        XCTAssertEqual(defaults.writes, writes, "No write may retry without explicit reload")
        store.reload()
        XCTAssertNil(store.protectionReason)
        let reloadedRevision = store.revision
        XCTAssertThrowsError(try store.delete(id: original.id))
        XCTAssertEqual(store.records, [original])
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(store.revision, reloadedRevision)
    }

    func testMeasurementForeignPostWriteDataOrWrongTypeIsNeverRolledBack() throws {
        for wrongType in [false, true] {
            let (suite, defaults, store) = try faultFixture()
            defer { defaults.removePersistentDomain(forName: suite) }
            let original = faultRecord()
            try store.save(original)
            let revision = store.revision
            let foreign = Data("{\"futureSchema\":3,\"retain\":null}".utf8)
            defaults.writeFault = wrongType ? .wrongType : .replace(foreign)
            var draft = original; draft.notes = "unacknowledged draft"
            XCTAssertThrowsError(try store.save(draft))
            XCTAssertEqual(store.records, [original])
            XCTAssertEqual(store.revision, revision)
            XCTAssertEqual(store.protectionReason, .persistenceFailure)
            XCTAssertEqual(defaults.writes, 2, "No rollback may overwrite observed replacement data")
            if wrongType { XCTAssertEqual(defaults.string(forKey: "measurements"), "foreign replacement") }
            else { XCTAssertEqual(defaults.data(forKey: "measurements"), foreign) }
        }
    }

    func testDroppedMeasurementErasureCannotClearCacheOrClaimDeletion() throws {
        let (suite, defaults, store) = try faultFixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = faultRecord()
        try store.save(original)
        let bytes = defaults.data(forKey: "measurements")
        let revision = store.revision
        defaults.eraseFault = .drop
        XCTAssertThrowsError(try store.eraseAllMeasurements())
        XCTAssertEqual(store.records, [original])
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(store.revision, revision)
        XCTAssertEqual(store.protectionReason, .persistenceFailure)
        let erasures = defaults.erasures
        XCTAssertThrowsError(try store.eraseAllMeasurements())
        XCTAssertEqual(defaults.erasures, erasures, "A failed erase requires explicit reload")
        store.reload()
        defaults.eraseFault = .accept
        try store.eraseAllMeasurements()
        XCTAssertTrue(store.records.isEmpty)
        XCTAssertNil(defaults.object(forKey: "measurements"))
        XCTAssertNil(store.protectionReason)
    }

    func testMeasurementPostEraseForeignReplacementIsPreservedWithoutRollback() throws {
        for wrongType in [false, true] {
            let (suite, defaults, store) = try faultFixture()
            defer { defaults.removePersistentDomain(forName: suite) }
            let original = faultRecord()
            try store.save(original)
            let revision = store.revision
            let foreign = Data("{\"futureField\":{\"keep\":null}}".utf8)
            defaults.eraseFault = wrongType ? .wrongType : .replace(foreign)
            XCTAssertThrowsError(try store.eraseAllMeasurements())
            XCTAssertEqual(store.records, [original])
            XCTAssertEqual(store.revision, revision)
            XCTAssertEqual(defaults.erasures, 1)
            XCTAssertEqual(defaults.writes, 1, "Only the original seed write; no rollback")
            XCTAssertEqual(store.protectionReason, .persistenceFailure)
            if wrongType { XCTAssertEqual(defaults.string(forKey: "measurements"), "foreign replacement") }
            else { XCTAssertEqual(defaults.data(forKey: "measurements"), foreign) }
        }
    }

    @MainActor
    func testActualMeasurementStoreRefreshRetainsLastAcknowledgedRecordAfterRejectedSave() async throws {
        let suite = "Fruitfolio.MeasurementStoreAck." + UUID().uuidString
        let defaults = try XCTUnwrap(HormoneFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "measurements")
        let original = faultRecord()
        try store.save(original)
        let revision = store.savedRecordRevision
        let bytes = defaults.data(forKey: "measurements")
        var draft = original; draft.result = "13.500"
        defaults.writeFault = .drop
        XCTAssertThrowsError(try store.save(draft, intent: .edit(original)))
        XCTAssertEqual(store.records, [original])
        XCTAssertEqual(store.savedRecordRevision, revision)
        XCTAssertEqual(store.storageProtectionReason, .persistenceFailure)
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(FruitfolioHormoneMeasurementStore(defaults: defaults, key: "measurements").records, [original])
        store.reloadSavedMeasurements()
        XCTAssertNil(store.storageProtectionReason)
        defaults.writeFault = .accept
        try store.save(draft, intent: .edit(original))
        XCTAssertEqual(FruitfolioHormoneMeasurementStore(defaults: defaults, key: "measurements").records, [draft])
    }

    @MainActor
    func testExplicitReloadCannotAuthorizeOldMeasurementIntentOverNewerSavedRecord() async throws {
        let suite = "Fruitfolio.MeasurementReloadConflict." + UUID().uuidString
        let defaults = try XCTUnwrap(HormoneFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "measurements")
        let original = faultRecord()
        try store.save(original)
        let frozenIntent = FruitfolioMeasurementSaveIntent.edit(original)
        var draft = original; draft.notes = "my still-open draft"
        var newer = original; newer.result = "13.500"; newer.notes = "newer independent record"
        defaults.set(try JSONEncoder().encode([newer]), forKey: "measurements")
        store.reloadSavedMeasurements()
        let bytes = defaults.data(forKey: "measurements")
        let revision = store.savedRecordRevision
        XCTAssertThrowsError(try store.save(draft, intent: frozenIntent)) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .editingConflict)
        }
        XCTAssertEqual(store.records, [newer])
        XCTAssertEqual(store.savedRecordRevision, revision)
        XCTAssertEqual(defaults.data(forKey: "measurements"), bytes)
        XCTAssertEqual(draft.notes, "my still-open draft")
    }

}
