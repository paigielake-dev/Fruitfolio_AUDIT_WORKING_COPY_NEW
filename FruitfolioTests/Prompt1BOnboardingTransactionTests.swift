import Foundation
import XCTest
@testable import Fruitfolio

private actor OnboardingWriteBoundary: Prompt14OnboardingPersistence {
    private let file: Prompt14FileOnboardingPersistence
    private var failSave = false
    private var failErase = false
    private var acknowledgeFailure = false
    init(_ url: URL) { file = Prompt14FileOnboardingPersistence(fileURL: url) }
    func load() async throws -> Prompt14OnboardingDraft { try await file.load() }
    func save(_ draft: Prompt14OnboardingDraft) async throws {
        if failSave { failSave = false; throw Prompt14OnboardingPersistenceError.unavailable }
        try await file.save(draft)
        if acknowledgeFailure { acknowledgeFailure = false; throw Prompt14OnboardingPersistenceError.unavailable }
    }
    func erase() async throws {
        if failErase { failErase = false; throw Prompt14OnboardingPersistenceError.unavailable }
        try await file.erase()
    }
    func rejectSave(afterCommit: Bool = false) {
        if afterCommit { acknowledgeFailure = true } else { failSave = true }
    }
    func rejectErase() { failErase = true }
}

@MainActor
final class Prompt1BOnboardingTransactionTests: XCTestCase {
    private func url() -> URL { FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".json") }
    private func day(_ number: Int) throws -> Prompt13LocalDate { try Prompt13LocalDate(year: 2026, month: 8, day: number) }

    func testFailedUpdateReloadsUnchangedFileInsteadOfPublishingUnsavedChoices() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory())
        _ = try await store.markStarted(now: Date(timeIntervalSince1970: 100))
        let bytes = try Data(contentsOf: url)
        await backend.rejectSave()
        do { _ = try await store.update { $0.cervicalFluidSetupAcknowledged = true }; XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let snapshot = try await store.snapshot()
        XCTAssertFalse(snapshot.cervicalFluidSetupAcknowledged)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
    }

    func testFailedErasePreservesPriorDraftAndPhysicalFile() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory())
        _ = try await store.update { $0.cervicalFluidSetupAcknowledged = true }
        let bytes = try Data(contentsOf: url)
        await backend.rejectErase()
        do { try await store.eraseOnboardingOnly(); XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let snapshot = try await store.snapshot(); XCTAssertTrue(snapshot.cervicalFluidSetupAcknowledged)
        XCTAssertEqual(try Data(contentsOf: url), bytes)
        try await store.eraseOnboardingOnly()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        let cleared = try await store.snapshot(); XCTAssertFalse(cleared.cervicalFluidSetupAcknowledged)
    }

    func testAcknowledgmentLossReloadsActualSavedChoices() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory())
        await backend.rejectSave(afterCommit: true)
        do { _ = try await store.update { $0.cervicalFluidSetupAcknowledged = true }; XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let snapshot = try await store.snapshot(); XCTAssertTrue(snapshot.cervicalFluidSetupAcknowledged)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(disk, snapshot)
    }

    func testConcurrentUpdatesPreserveEveryDistinctSuppliedDate() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: .inMemory())
        let tasks = try (1...25).map { index in
            let date = try day(index)
            return Task { try await store.update { $0.historicalPeriodStarts.append(date) } }
        }
        for task in tasks { _ = try await task.value }
        let snapshot = try await store.snapshot()
        XCTAssertEqual(Set(snapshot.historicalPeriodStarts).count, 25)
        let disk = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertEqual(Set(disk.historicalPeriodStarts), Set(snapshot.historicalPeriodStarts))
    }

    func testFailedCompletionRetainsActualCycleStartsAndRetryDoesNotDuplicateThem() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        let cycleURL = self.url(); defer { try? FileManager.default.removeItem(at: cycleURL) }
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let backend = OnboardingWriteBoundary(url)
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle)
        let first = try day(1), second = try day(29)
        _ = try await store.update { draft in
            draft.latestPeriodStart = second; draft.latestPeriodState = .supplied
            draft.historicalPeriodStarts = [first]
        }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_789_516_800)
        await backend.rejectSave()
        do { _ = try await store.complete(now: now, calendar: calendar); XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let incomplete = try await store.snapshot(); XCTAssertFalse(incomplete.isCompleted)
        let committed = try await cycle.snapshot()
        XCTAssertEqual(Set(committed.cycleStarts.map(\.date)), [first, second])
        let finished = try await store.complete(now: now, calendar: calendar)
        XCTAssertTrue(finished.isCompleted)
        let retried = try await cycle.snapshot()
        XCTAssertEqual(retried.cycleStarts.map(\.id), committed.cycleStarts.map(\.id))
    }

    func testExplicitEraseOfUnsupportedFileDoesNotRequireLossyDecoding() async throws {
        let url = url(); defer { try? FileManager.default.removeItem(at: url) }
        try Data("{\"schemaVersion\":2,\"future\":true}".utf8).write(to: url)
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: .inMemory())
        try await store.eraseOnboardingOnly()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
