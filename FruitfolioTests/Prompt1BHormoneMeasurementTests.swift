import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BHormoneMeasurementTests: XCTestCase {
    func testEditingIntentRejectsNewerSameStoreRecordWithoutChangingBytesOrRevision() async throws {
        let suite = "Prompt1BHormoneEditConflict.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.50"; record.unit = "pg/mL"
        try store.save(record, locale: Locale(identifier: "en_US"))
        let baseline = try XCTUnwrap(store.records.first)
        var draft = baseline; draft.notes = "unsaved draft"
        var newer = baseline; newer.result = "13.500"; newer.unit = "nmol/L"; newer.notes = "newer saved note"
        try store.save(newer)
        let bytes = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        let revision = store.savedRecordRevision
        XCTAssertThrowsError(try store.save(draft, intent: .edit(baseline))) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .editingConflict)
        }
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), bytes)
        XCTAssertEqual(store.savedRecordRevision, revision)
        XCTAssertEqual(store.records.first, newer)
        XCTAssertEqual(draft.notes, "unsaved draft")
        XCTAssertNil(store.storageProtectionReason)
    }

    func testEditingIntentCannotRecreateDeletedRecordOrOverwriteRecreatedIdentity() async throws {
        let suite = "Prompt1BHormoneDeletedEdit.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement(); record.result = "12.50"; record.unit = "pg/mL"
        try store.save(record, locale: Locale(identifier: "en_US"))
        let baseline = try XCTUnwrap(store.records.first)
        try store.delete(id: baseline.id)
        let empty = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        XCTAssertThrowsError(try store.save(baseline, intent: .edit(baseline)))
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), empty)
        XCTAssertTrue(store.records.isEmpty)
        var replacement = baseline; replacement.result = "20.5"; replacement.notes = "recreated record"
        try store.save(replacement)
        let bytes = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        XCTAssertThrowsError(try store.save(baseline, intent: .edit(baseline)))
        var wrongID = baseline; wrongID.id = UUID()
        XCTAssertThrowsError(try store.save(wrongID, intent: .edit(baseline)))
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), bytes)
        XCTAssertEqual(store.records.first, replacement)
    }

    func testCreationIntentIsSingleUseAndRequiresItsAllocatedIdentity() async throws {
        let suite = "Prompt1BHormoneCreateIntent.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement(); record.result = "12.50"; record.unit = "pg/mL"
        let intent = FruitfolioMeasurementSaveIntent.create(record.id)
        XCTAssertThrowsError(try store.save(record, intent: .create(UUID())))
        XCTAssertNil(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey))
        try store.save(record, locale: Locale(identifier: "en_US"), intent: intent)
        let bytes = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        record.notes = "replayed write"
        XCTAssertThrowsError(try store.save(record, intent: intent)) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .editingConflict)
        }
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), bytes)
        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.notes, "")
    }

    func testRecordSpecificEditingAllowsOtherMeasurementsToChangeAndPreservesReportedMetadata() async throws {
        let suite = "Prompt1BHormoneIndependentEdit.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var first = FruitfolioHormoneMeasurement(); first.result = "12,50"; first.unit = "pg/mL"
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        try first.setReportedTestDate(Date(timeIntervalSince1970: 1_792_108_800), calendar: calendar)
        try store.save(first, locale: Locale(identifier: "fr_FR"))
        let baseline = try XCTUnwrap(store.records.first)
        var second = FruitfolioHormoneMeasurement(); second.result = "3.20"; second.unit = "nmol/L"
        second.notes = "independent newer measurement"
        try store.save(second, locale: Locale(identifier: "en_US"))
        let savedSecond = try XCTUnwrap(store.records.first { $0.id == second.id })
        var draft = baseline; draft.notes = "updated first notes"
        try store.save(draft, locale: Locale(identifier: "en_US"), intent: .edit(baseline))
        let restored = FruitfolioHormoneMeasurementStore(defaults: defaults)
        let actual = try XCTUnwrap(restored.records.first { $0.id == baseline.id })
        XCTAssertEqual(actual.result, baseline.result)
        XCTAssertEqual(actual.unit, baseline.unit)
        XCTAssertEqual(actual.resultLocaleIdentifier, "fr_FR")
        XCTAssertEqual(actual.reportedTestDay, baseline.reportedTestDay)
        XCTAssertEqual(actual.testDate, baseline.testDate)
        XCTAssertEqual(actual.testDateEntryTimeZoneIdentifier, baseline.testDateEntryTimeZoneIdentifier)
        XCTAssertEqual(actual.notes, "updated first notes")
        XCTAssertEqual(restored.records.first { $0.id == second.id }, savedSecond)
    }

    func testEditingIntentCannotBypassOutsideWriterOrReloadedNewerBaseline() async throws {
        let suite = "Prompt1BHormoneExternalEdit.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var record = FruitfolioHormoneMeasurement(); record.result = "12.50"; record.unit = "pg/mL"
        try first.save(record, locale: Locale(identifier: "en_US"))
        let baseline = try XCTUnwrap(first.records.first)
        let writer = FruitfolioHormoneMeasurementStore(defaults: defaults)
        var newer = try XCTUnwrap(writer.records.first); newer.result = "14.50"
        try writer.save(newer)
        let bytes = defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey)
        var draft = baseline; draft.notes = "old draft"
        XCTAssertThrowsError(try first.save(draft, intent: .edit(baseline))) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .storageChanged)
        }
        first.reloadSavedMeasurements()
        XCTAssertThrowsError(try first.save(draft, intent: .edit(baseline))) {
            XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .editingConflict)
        }
        XCTAssertEqual(defaults.data(forKey: FruitfolioHormoneMeasurementStore.persistenceKey), bytes)
        let current = try XCTUnwrap(first.records.first)
        var reviewed = current; reviewed.notes = "notes against current baseline"
        try first.save(reviewed, intent: .edit(current))
        XCTAssertEqual(first.records.first?.result, "14.50")
        XCTAssertEqual(first.records.first?.notes, reviewed.notes)
    }

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
    func testUnrecognizedExplicitReportLocaleCannotBeGuessedForNewMeasurement() async throws {
        let suite = "Fruitfolio.UnknownReportFormat.New." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        let revision = store.savedRecordRevision
        for identifier in ["", "unknown-report-format", "Fruitfolio_unknown", "en_FAKE"] {
            var record = FruitfolioHormoneMeasurement()
            record.result = "12.50"; record.unit = "pg/mL"; record.resultLocaleIdentifier = identifier
            XCTAssertThrowsError(try store.save(record, locale: Locale(identifier: "en_US"))) {
                XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .resultFormatRequired)
            }
            XCTAssertTrue(store.records.isEmpty)
            XCTAssertNil(defaults.object(forKey: "fixture"))
            XCTAssertEqual(store.savedRecordRevision, revision)
        }
    }

    func testUnknownLegacyReportFormatAllowsMetadataEditWithoutReinterpretingOriginalResult() async throws {
        let suite = "Fruitfolio.UnknownReportFormat.Metadata." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var original = FruitfolioHormoneMeasurement()
        original.result = "12,500"; original.unit = " nmol/L "; original.resultLocaleIdentifier = "unknown-report-format"
        defaults.set(try JSONEncoder().encode([original]), forKey: "fixture")
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        var draft = original; draft.notes = "only my note changed"
        try store.save(draft, locale: Locale(identifier: "en_US"), intent: .edit(original))
        let saved = try XCTUnwrap(FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture").records.first)
        XCTAssertEqual(saved, draft)
        XCTAssertEqual(saved.result, "12,500")
        XCTAssertEqual(saved.unit, " nmol/L ")
        XCTAssertEqual(saved.resultLocaleIdentifier, "unknown-report-format")
    }

    func testChangedUnknownLegacyResultUnitOrOpaqueFormatNeedsExplicitRecognizedFormat() async throws {
        let suite = "Fruitfolio.UnknownReportFormat.Changed." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var original = FruitfolioHormoneMeasurement()
        original.result = "12.50"; original.unit = "pg/mL"; original.resultLocaleIdentifier = "unknown-report-format"
        defaults.set(try JSONEncoder().encode([original]), forKey: "fixture")
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        let bytes = defaults.data(forKey: "fixture")
        let revision = store.savedRecordRevision
        for field in 0..<3 {
            var draft = original
            if field == 0 { draft.result = "13.50" }
            else if field == 1 { draft.unit = "nmol/L" }
            else { draft.resultLocaleIdentifier = "another-unknown-format" }
            XCTAssertThrowsError(try store.save(draft, locale: Locale(identifier: "en_US"), intent: .edit(original))) {
                XCTAssertEqual($0 as? FruitfolioHormoneMeasurementError, .resultFormatRequired)
            }
            XCTAssertEqual(store.records, [original])
            XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
            XCTAssertEqual(store.savedRecordRevision, revision)
        }
        var reviewed = original
        reviewed.result = "13,50"; reviewed.resultLocaleIdentifier = "fr_FR"
        try store.save(reviewed, locale: Locale(identifier: "en_US"), intent: .edit(original))
        XCTAssertEqual(store.records.first, reviewed)
    }

    func testSupportedRegionalReportAliasesRetainExactStoredIdentifierAndValue() async throws {
        let suite = "Fruitfolio.ReportFormat.Aliases." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = FruitfolioHormoneMeasurementStore(defaults: defaults, key: "fixture")
        for (identifier, value) in [("en-US", "12.50"), ("en_US_POSIX", "12.50"), ("fr-FR", "12,50"), ("ar-EG", "١٢٫٥٠")] {
            var record = FruitfolioHormoneMeasurement()
            record.result = value; record.unit = "pg/mL"; record.resultLocaleIdentifier = identifier
            try store.save(record, locale: Locale(identifier: "de_DE"))
            let saved = try XCTUnwrap(store.records.first { $0.id == record.id })
            XCTAssertEqual(saved.result, value)
            XCTAssertEqual(saved.resultLocaleIdentifier, identifier)
        }
    }

}
