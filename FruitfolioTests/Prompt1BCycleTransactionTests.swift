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
    func testOnboardingImportCommitsAllDatesOnceAndRetryKeepsRecordIdentities() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), today = try day()
        let store = Prompt13CycleStore(persistence: backend)
        let dates: Set<Prompt13LocalDate> = [today, try Prompt13LocalDate(year: 2026, month: 8, day: 10), try Prompt13LocalDate(year: 2026, month: 7, day: 12)]
        try await store.reconcileOnboardingCycleStarts(dates: dates, replacingCommittedHistory: false, today: today)
        let count = await backend.count(); XCTAssertEqual(count, 1)
        let snapshot = try await store.snapshot()
        XCTAssertEqual(Set(snapshot.cycleStarts.map(\.date)), dates)
        XCTAssertTrue(snapshot.cycleStarts.allSatisfy { $0.source == .onboardingConfirmed })
        try await store.reconcileOnboardingCycleStarts(dates: dates, replacingCommittedHistory: false, today: today)
        let retried = try await store.snapshot()
        XCTAssertEqual(retried.cycleStarts.map(\.id), snapshot.cycleStarts.map(\.id))
        let retryCount = await backend.count(); XCTAssertEqual(retryCount, 1)
    }

    func testInvalidOnboardingDateRejectsWholeCandidateBeforeAnyHistoryChange() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), today = try day()
        let store = Prompt13CycleStore(persistence: backend)
        _ = try await store.recordCycleStart(on: today, source: .onboardingConfirmed, today: today)
        let bytes = try Data(contentsOf: url)
        let future = try Prompt13LocalDate(year: 2027, month: 1, day: 1)
        do {
            try await store.reconcileOnboardingCycleStarts(dates: [future], replacingCommittedHistory: true, today: today)
            XCTFail()
        } catch { XCTAssertEqual(error as? Prompt13CycleError, .futureObservationNotAllowed) }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.date), [today])
        let count = await backend.count(); XCTAssertEqual(count, 1)
    }

    func testFailedOnboardingReplacementPreservesAllOldDatesAndNoPartialNewRecords() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), today = try day()
        let store = Prompt13CycleStore(persistence: backend)
        _ = try await store.recordCycleStart(on: today, source: .onboardingConfirmed, today: today)
        let before = try await Prompt13FileCyclePersistence(fileURL: url).load(), bytes = try Data(contentsOf: url)
        let replacement = try Prompt13LocalDate(year: 2026, month: 8, day: 10)
        await backend.fail()
        do {
            try await store.reconcileOnboardingCycleStarts(dates: [replacement], replacingCommittedHistory: true, today: today)
            XCTFail()
        } catch { XCTAssertEqual(error as? Prompt13CycleError, .persistenceFailure) }
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        let after = try await store.snapshot()
        XCTAssertEqual(after.cycleStarts, before.cycleStarts)
        try await store.reconcileOnboardingCycleStarts(dates: [replacement], replacingCommittedHistory: true, today: today)
        let replaced = try await store.snapshot()
        XCTAssertEqual(replaced.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.date), [replacement])
        XCTAssertTrue(replaced.cycleStarts.first { $0.id == before.cycleStarts[0].id }!.metadata.isDeleted)
    }

    func testOnboardingReplacementPreservesIndependentRecordsAndExistingIDs() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = CycleWriteBoundary(url), today = try day()
        let store = Prompt13CycleStore(persistence: backend)
        let old = try Prompt13LocalDate(year: 2026, month: 7, day: 12)
        let matching = try Prompt13LocalDate(year: 2026, month: 8, day: 10)
        let independent = try Prompt13LocalDate(year: 2026, month: 6, day: 15)
        let oldRecord = try await store.recordCycleStart(on: old, source: .onboardingConfirmed, today: today)
        let matchingRecord = try await store.recordCycleStart(on: matching, today: today)
        let independentRecord = try await store.recordCycleStart(on: independent, source: .importedUserRecord, today: today)
        let count = await backend.count()
        try await store.reconcileOnboardingCycleStarts(dates: [matching, today], replacingCommittedHistory: true, today: today)
        let afterCount = await backend.count(); XCTAssertEqual(afterCount, count + 1)
        let snapshot = try await store.snapshot()
        let retained = try XCTUnwrap(snapshot.cycleStarts.first { $0.id == independentRecord.id })
        XCTAssertEqual(retained, independentRecord)
        let adopted = try XCTUnwrap(snapshot.cycleStarts.first { $0.id == matchingRecord.id })
        XCTAssertEqual(adopted.date, matching); XCTAssertEqual(adopted.source, .onboardingConfirmed)
        XCTAssertTrue(snapshot.cycleStarts.first { $0.id == oldRecord.id }!.metadata.isDeleted)
    }

}
