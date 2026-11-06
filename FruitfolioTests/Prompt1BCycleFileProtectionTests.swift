import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BCycleFileProtectionTests: XCTestCase {
    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json")
    }
    private func archive() async throws -> Prompt13CycleArchive {
        let store = Prompt13CycleStore.inMemory()
        let day = try Prompt13LocalDate(year: 2026, month: 9, day: 7)
        _ = try await store.recordNote(on: day, text: "original recorded observation", today: day)
        return try await store.snapshot()
    }
    private func draft() throws -> Prompt14OnboardingDraft {
        var draft = Prompt14OnboardingDraft()
        draft.latestPeriodState = .supplied
        draft.latestPeriodStart = try Prompt13LocalDate(year: 2026, month: 9, day: 1)
        return draft
    }

    func testCycleFutureRootRecordMetadataAndSchemaPreserveOriginalFile() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let value = try await archive()
        let seed = Prompt13FileCyclePersistence(fileURL: file); try await seed.save(value)
        let original = try Data(contentsOf: file)
        for variant in ["root", "metadata", "schema", "explicit-null"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            var notes = try XCTUnwrap(object["notes"] as? [[String: Any]])
            switch variant {
            case "root": object["futureSourceMetadata"] = ["retain": true]
            case "schema": object["schemaVersion"] = 2
            case "metadata":
                var metadata = try XCTUnwrap(notes[0]["metadata"] as? [String: Any])
                metadata["futureProvenance"] = "retain"; notes[0]["metadata"] = metadata
            default: notes[0]["cycleID"] = NSNull()
            }
            object["notes"] = notes
            let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
            let persistence = Prompt13FileCyclePersistence(fileURL: file)
            do { _ = try await persistence.load(); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt13CycleError, .unsupportedPersistence) }
            do { try await persistence.save(value); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt13CycleError, .unsupportedPersistence) }
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    func testCycleOutsideWriterBlocksSaveAndStaleEraseUntilReadOnlyReload() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let original = try await archive()
        let first = Prompt13FileCyclePersistence(fileURL: file); try await first.save(original)
        let writer = Prompt13FileCyclePersistence(fileURL: file)
        var newer = try await writer.load(); newer.notes[0].text = "newer recorded observation"
        try await writer.save(newer)
        let bytes = try Data(contentsOf: file)
        do { try await first.save(original); XCTFail("Outside record must survive") }
        catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        do { try await first.erase(); XCTFail("Old erasure cannot remove newer file") }
        catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        let loaded = try await first.load()
        XCTAssertEqual(loaded.notes.first?.text, newer.notes.first?.text)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        try await first.erase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        do { try await writer.save(newer); XCTFail("Old cache cannot recreate erased data") }
        catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testCycleBlindWriterRequiresLoadAndDeletedBaselineDoesNotResurrect() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let value = try await archive()
        let first = Prompt13FileCyclePersistence(fileURL: file); try await first.save(value)
        let bytes = try Data(contentsOf: file)
        let blind = Prompt13FileCyclePersistence(fileURL: file)
        for _ in 0..<2 {
            do { try await blind.save(value); XCTFail("Existing file requires a loaded baseline") }
            catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        _ = try await blind.load()
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        try FileManager.default.removeItem(at: file)
        do { try await first.save(value); XCTFail("Cleared file must stay cleared") }
        catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testUnsupportedCycleBaselineErasureIsScopedToItsExactBytes() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let value = try await archive()
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoder.encode(value)) as? [String: Any])
        object["futureField"] = "first"; try JSONSerialization.data(withJSONObject: object).write(to: file)
        let persistence = Prompt13FileCyclePersistence(fileURL: file)
        do { _ = try await persistence.load(); XCTFail("Unsupported baseline") } catch { }
        object["futureField"] = "newer"
        let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
        do { try await persistence.erase(); XCTFail("Newer unsupported file must survive") }
        catch { XCTAssertEqual(error as? Prompt13CycleError, .storageChanged) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        do { _ = try await persistence.load(); XCTFail("Still unsupported") } catch { }
        try await persistence.erase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testOnboardingFutureFieldsDatesAndSchemaCannotBeDropped() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let value = try draft()
        let seed = Prompt14FileOnboardingPersistence(fileURL: file); try await seed.save(value)
        let original = try Data(contentsOf: file)
        for variant in ["root", "date", "schema", "explicit-null"] {
            var object = try XCTUnwrap(JSONSerialization.jsonObject(with: original) as? [String: Any])
            switch variant {
            case "root": object["futureSetupMetadata"] = "retain"
            case "date":
                var date = try XCTUnwrap(object["latestPeriodStart"] as? [String: Any])
                date["futureCalendarContext"] = "retain"; object["latestPeriodStart"] = date
            case "schema": object["schemaVersion"] = 2
            default: object["periodEnd"] = NSNull()
            }
            let bytes = try JSONSerialization.data(withJSONObject: object); try bytes.write(to: file)
            let persistence = Prompt14FileOnboardingPersistence(fileURL: file)
            do { _ = try await persistence.load(); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unsupportedFormat) }
            do { try await persistence.save(value); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unsupportedFormat) }
            XCTAssertEqual(try Data(contentsOf: file), bytes)
        }
    }

    func testOnboardingOutsideWriterAndErasureRequireExactSnapshot() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let original = try draft()
        let first = Prompt14FileOnboardingPersistence(fileURL: file); try await first.save(original)
        let writer = Prompt14FileOnboardingPersistence(fileURL: file)
        var newer = try await writer.load(); newer.latestPeriodState = .unknown; newer.latestPeriodStart = nil
        try await writer.save(newer)
        let bytes = try Data(contentsOf: file)
        do { try await first.save(original); XCTFail("Do not replace newer setup") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .storageChanged) }
        do { try await first.erase(); XCTFail("Do not erase newer setup") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .storageChanged) }
        let actual = try await first.load()
        XCTAssertEqual(actual.latestPeriodState, .unknown)
        XCTAssertNil(actual.latestPeriodStart)
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        try await first.erase()
        do { try await writer.save(newer); XCTFail("Do not resurrect erased setup") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .storageChanged) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testOnboardingBlindWriterRequiresLoadAndMalformedBaselineStaysProtected() async throws {
        let file = temporaryFile(); defer { try? FileManager.default.removeItem(at: file) }
        let original = try draft()
        let seed = Prompt14FileOnboardingPersistence(fileURL: file); try await seed.save(original)
        let bytes = try Data(contentsOf: file)
        let blind = Prompt14FileOnboardingPersistence(fileURL: file)
        do { try await blind.save(original); XCTFail("Must load existing baseline") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .storageChanged) }
        XCTAssertEqual(try Data(contentsOf: file), bytes)
        let corrupt = Data("not JSON".utf8); try corrupt.write(to: file)
        let persistence = Prompt14FileOnboardingPersistence(fileURL: file)
        do { _ = try await persistence.load(); XCTFail("Malformed baseline") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        do { try await persistence.save(original); XCTFail("Keep malformed bytes") }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        XCTAssertEqual(try Data(contentsOf: file), corrupt)
        try await persistence.erase()
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testCancelledCycleFileMutationsCannotWriteOrErase() async throws {
        let cycleFile = temporaryFile(); let onboardingFile = temporaryFile()
        defer { try? FileManager.default.removeItem(at: cycleFile); try? FileManager.default.removeItem(at: onboardingFile) }
        let value = try await archive(); let setup = try draft()
        let cycle = Prompt13FileCyclePersistence(fileURL: cycleFile); try await cycle.save(value)
        let onboarding = Prompt14FileOnboardingPersistence(fileURL: onboardingFile); try await onboarding.save(setup)
        let cycleBytes = try Data(contentsOf: cycleFile); let setupBytes = try Data(contentsOf: onboardingFile)
        let cycleTask = Task { withUnsafeCurrentTask { $0?.cancel() }; try await cycle.erase() }
        let setupTask = Task { withUnsafeCurrentTask { $0?.cancel() }; try await onboarding.save(setup) }
        do { try await cycleTask.value; XCTFail("Cancelled erase") } catch { XCTAssertTrue(error is CancellationError) }
        do { try await setupTask.value; XCTFail("Cancelled save") } catch { XCTAssertTrue(error is CancellationError) }
        XCTAssertEqual(try Data(contentsOf: cycleFile), cycleBytes)
        XCTAssertEqual(try Data(contentsOf: onboardingFile), setupBytes)
    }
}
