import Foundation
import XCTest
@testable import Fruitfolio

// Faults and suspension are injected only at the persistence boundary; every
// successful read/write below uses the actual production file actor and codec.
private actor CycleWriteBoundary: Prompt13CyclePersistence {
    let file: Prompt13FileCyclePersistence
    private var writes = 0
    private var failNext = false
    private var commitThenFail = false
    private var holdNext = false
    private var held: CheckedContinuation<Void, Never>?
    private var arrival: CheckedContinuation<Void, Never>?
    init(_ url: URL) { file = Prompt13FileCyclePersistence(fileURL: url) }
    func load() async throws -> Prompt13CycleArchive { try await file.load() }
    func save(_ archive: Prompt13CycleArchive) async throws {
        writes += 1
        if holdNext {
            holdNext = false
            await withCheckedContinuation { continuation in
                held = continuation
                arrival?.resume(); arrival = nil
            }
        }
        if failNext { failNext = false; throw Prompt13CycleError.persistenceFailure }
        try await file.save(archive)
        if commitThenFail { commitThenFail = false; throw Prompt13CycleError.persistenceFailure }
    }
    func erase() async throws { try await file.erase() }
    func fail(afterCommit: Bool = false) { if afterCommit { commitThenFail = true } else { failNext = true } }
    func count() -> Int { writes }
    func hold() { holdNext = true }
    func waitUntilHeld() async {
        if held != nil { return }
        await withCheckedContinuation { arrival = $0 }
    }
    func release() { held?.resume(); held = nil }
}

@MainActor
final class Prompt1BCycleTransactionTests: XCTestCase {
    private func url() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json") }
    private func day() throws -> Prompt13LocalDate { try Prompt13LocalDate(year: 2026, month: 9, day: 7) }

    func testObservationCommitsItsDailyLogAndLinkedNoteExactlyOnce() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        _ = try await store.recordNote(on: day, text: "recorded", today: day)
        let count = await backend.count(); XCTAssertEqual(count, 1)
        let archive = try await Prompt13FileCyclePersistence(fileURL: url).load()
        XCTAssertEqual(archive.dailyLogs.count, 1); XCTAssertEqual(archive.notes.count, 1)
        XCTAssertEqual(archive.notes[0].dailyLogID, archive.dailyLogs[0].id)
    }

    func testRejectedObservationLeavesNeitherEmptyLogNorUncommittedNote() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        await backend.fail()
        do { _ = try await store.recordNote(on: day, text: "rejected", today: day); XCTFail() } catch {}
        let snapshot = try await store.snapshot()
        XCTAssertTrue(snapshot.dailyLogs.isEmpty); XCTAssertTrue(snapshot.notes.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        _ = try await store.recordNote(on: day, text: "retry", today: day)
        let saved = try await store.snapshot(); XCTAssertEqual(saved.notes.map(\.text), ["retry"])
    }

    func testFailedClearPreservesActualFileAndReloadedRecords() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        _ = try await store.recordNote(on: day, text: "retain", today: day)
        let bytes = try Data(contentsOf: url)
        await backend.fail()
        do { try await store.eraseAllLocalCycleData(); XCTFail() } catch {}
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let snapshot = try await store.snapshot(); XCTAssertEqual(snapshot.notes.map(\.text), ["retain"])
        try await store.eraseAllLocalCycleData()
        let cleared = try await Prompt13FileCyclePersistence(fileURL: url).load()
        XCTAssertTrue(cleared.notes.isEmpty); XCTAssertTrue(cleared.dailyLogs.isEmpty)
        XCTAssertEqual(cleared.localProfileID, snapshot.localProfileID)
    }

    func testCommittedButFailedAcknowledgmentReloadsActualBackendBeforeNextWrite() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        await backend.fail(afterCommit: true)
        do { _ = try await store.recordNote(on: day, text: "committed", today: day); XCTFail() } catch {}
        let snapshot = try await store.snapshot(); XCTAssertEqual(snapshot.notes.map(\.text), ["committed"])
        _ = try await store.recordNote(on: day, text: "later", today: day)
        let saved = try await Prompt13FileCyclePersistence(fileURL: url).load()
        XCTAssertEqual(saved.notes.map(\.text), ["committed", "later"])
    }

    func testSuspendedWriteQueuesSnapshotAndOtherMutationsWithoutLosingRecords() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        await backend.hold()
        let first = Task { try await store.recordNote(on: day, text: "first", today: day) }
        await backend.waitUntilHeld()
        let others = (0..<20).map { index in Task { try await store.recordNote(on: day, text: "note \(index)", today: day) } }
        let snapshot = Task { try await store.snapshot() }
        await backend.release()
        _ = try await first.value
        for task in others { _ = try await task.value }
        let queuedSnapshot = try await snapshot.value
        XCTAssertFalse(queuedSnapshot.notes.isEmpty)
        let final = try await store.snapshot()
        XCTAssertEqual(final.notes.count, 21); XCTAssertEqual(final.dailyLogs.count, 1)
        XCTAssertEqual(Set(final.notes.map(\.id)).count, 21)
        let count = await backend.count(); XCTAssertEqual(count, 21)
        let disk = try await Prompt13FileCyclePersistence(fileURL: url).load()
        XCTAssertEqual(disk.notes.map(\.id), final.notes.map(\.id))
    }

    func testCanceledQueuedOperationReleasesGateWithoutWriting() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), day = try day()
        let store = Prompt13CycleStore(persistence: backend)
        await backend.hold()
        let first = Task { try await store.recordNote(on: day, text: "first", today: day) }
        await backend.waitUntilHeld()
        let canceled = Task { try await store.recordNote(on: day, text: "canceled", today: day) }
        canceled.cancel(); await backend.release()
        _ = try await first.value
        do { _ = try await canceled.value; XCTFail() } catch is CancellationError {} catch { XCTFail("\(error)") }
        let snapshot = try await store.snapshot(); XCTAssertEqual(snapshot.notes.map(\.text), ["first"])
        let count = await backend.count(); XCTAssertEqual(count, 1)
    }
}
