import Foundation
import XCTest
@testable import Fruitfolio

actor OnboardingWriteBoundary: Prompt14OnboardingPersistence {
    private let file: Prompt14FileOnboardingPersistence
    private var failSave = false
    private var failErase = false
    private var acknowledgeFailure = false
    private var holdNext = false
    private var held: CheckedContinuation<Void, Never>?
    private var arrival: CheckedContinuation<Void, Never>?
    private var writeIndex = 0
    private var rejectedWrites: [Int: Bool] = [:]
    init(_ url: URL) { file = Prompt14FileOnboardingPersistence(fileURL: url) }
    func load() async throws -> Prompt14OnboardingDraft { try await file.load() }
    func save(_ draft: Prompt14OnboardingDraft) async throws {
        writeIndex += 1
        if holdNext {
            holdNext = false
            await withCheckedContinuation { continuation in
                held = continuation
                arrival?.resume(); arrival = nil
            }
        }
        let injected = rejectedWrites.removeValue(forKey: writeIndex)
        if injected == false { throw Prompt14OnboardingPersistenceError.unavailable }
        if failSave { failSave = false; throw Prompt14OnboardingPersistenceError.unavailable }
        try await file.save(draft)
        if injected == true { throw Prompt14OnboardingPersistenceError.unavailable }
        if acknowledgeFailure { acknowledgeFailure = false; throw Prompt14OnboardingPersistenceError.unavailable }
    }
    func erase() async throws {
        if failErase { failErase = false; throw Prompt14OnboardingPersistenceError.unavailable }
        try await file.erase()
    }
    func rejectSave(afterCommit: Bool = false) {
        if afterCommit { acknowledgeFailure = true } else { failSave = true }
    }
    func count() -> Int { writeIndex }
    func rejectErase() { failErase = true }
    func hold() { holdNext = true }
    func waitUntilHeld() async {
        if held != nil { return }
        await withCheckedContinuation { arrival = $0 }
    }
    func release() { held?.resume(); held = nil }
    func rejectWrite(_ upcoming: Int, afterCommit: Bool = false) { rejectedWrites[writeIndex + upcoming] = afterCommit }
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

    func testFailedFinalCompletionSaveRetainsIntentAndRetryDoesNotDuplicateStarts() async throws {
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
        await backend.rejectWrite(2)
        do { _ = try await store.complete(now: now, calendar: calendar); XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let pending = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
        XCTAssertNotNil(pending.pendingCycleCommit); XCTAssertFalse(pending.isCompleted)
        let recovered = try await store.snapshot(); XCTAssertTrue(recovered.isCompleted)
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
    func testRestartRecoversEveryDraftWritePhaseWithoutInventingDates() async throws {
        for phase in [1, 2] {
            for afterCommit in [false, true] {
                let url = url(), cycleURL = self.url()
                defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
                let backend = OnboardingWriteBoundary(url)
                let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
                let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle)
                let supplied = try day(1)
                _ = try await store.update { $0.latestPeriodStart = supplied; $0.latestPeriodState = .supplied }
                await backend.rejectWrite(phase, afterCommit: afterCommit)
                var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
                let now = Date(timeIntervalSince1970: 1_789_516_800)
                do { _ = try await store.complete(now: now, calendar: calendar); XCTFail("phase \(phase)") }
                catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
                let diskBeforeRestart = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
                let intentWasSaved = phase != 1 || afterCommit
                XCTAssertEqual(diskBeforeRestart.pendingCycleCommit != nil, intentWasSaved && !(phase == 2 && afterCommit))
                let restartedCycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
                let restarted = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: restartedCycle)
                let recovered = try await restarted.snapshot()
                XCTAssertEqual(recovered.isCompleted, intentWasSaved)
                XCTAssertNil(recovered.pendingCycleCommit)
                let archive = try await restartedCycle.snapshot()
                XCTAssertEqual(archive.cycleStarts.map(\.date), intentWasSaved ? [supplied] : [])
                XCTAssertTrue(archive.cycleStarts.allSatisfy { $0.source == .onboardingConfirmed })
                let again = try await restarted.snapshot()
                XCTAssertEqual(again, recovered)
                let diskAfter = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
                XCTAssertNil(diskAfter.pendingCycleCommit)
            }
        }
    }

    func testPendingIntentMismatchOrFutureDatesPreserveBothFilesWithoutRecoveryWrites() async throws {
        for variant in ["mismatch", "future", "duplicate"] {
            let url = url(), cycleURL = self.url()
            defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
            let supplied = try day(1), today = try day(29)
            var draft = Prompt14OnboardingDraft(); draft.latestPeriodStart = supplied
            let dates = variant == "mismatch" ? [today] : variant == "duplicate" ? [supplied, supplied] : [supplied]
            draft.pendingCycleCommit = Prompt14PendingCycleCommit(dates: dates, replacingCommittedHistory: false, completionRequestedAt: Date(), requestedAt: Date(), today: variant == "future" ? try Prompt13LocalDate(year: 2026, month: 7, day: 1) : today)
            try await Prompt14FileOnboardingPersistence(fileURL: url).save(draft)
            let bytes = try Data(contentsOf: url)
            let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
            let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: cycle)
            do { _ = try await store.snapshot(); XCTFail(variant) }
            catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unsupportedFormat) }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: cycleURL.path))
        }
    }

    func testFailedCommittedHistoryEditResumesExactReplacementBeforeLaterEdit() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        let backend = OnboardingWriteBoundary(url)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let store = Prompt14CycleOnboardingStore(persistence: backend, cycleStore: cycle)
        let original = try day(1), replacement = try day(15), later = try day(29)
        _ = try await store.update { $0.latestPeriodStart = original; $0.latestPeriodState = .supplied }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        _ = try await store.complete(now: Date(timeIntervalSince1970: 1_789_516_800), calendar: calendar)
        var edited = try await store.snapshot(); edited.latestPeriodStart = replacement
        await backend.rejectWrite(2)
        do { try await store.replaceDraft(edited); XCTFail() }
        catch { XCTAssertEqual(error as? Prompt14OnboardingPersistenceError, .unavailable) }
        let restartedCycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let restarted = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: restartedCycle)
        var recovered = try await restarted.snapshot()
        XCTAssertEqual(recovered.latestPeriodStart, replacement); XCTAssertTrue(recovered.isCompleted)
        recovered.latestPeriodStart = later
        try await restarted.replaceDraft(recovered)
        let archive = try await restartedCycle.snapshot()
        XCTAssertEqual(archive.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.date), [later])
        XCTAssertTrue(archive.cycleStarts.filter { $0.date == original || $0.date == replacement }.allSatisfy { $0.metadata.isDeleted })
    }

    func testExplicitOnboardingEraseCancelsPendingIntentWithoutImportingIt() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        var draft = Prompt14OnboardingDraft(); let supplied = try day(1)
        draft.latestPeriodStart = supplied
        draft.pendingCycleCommit = Prompt14PendingCycleCommit(dates: [supplied], replacingCommittedHistory: false, completionRequestedAt: Date(), requestedAt: Date(), today: try day(29))
        try await Prompt14FileOnboardingPersistence(fileURL: url).save(draft)
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: cycle)
        try await store.eraseOnboardingOnly()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: cycleURL.path))
        let snapshot = try await store.snapshot(); XCTAssertNil(snapshot.pendingCycleCommit)
        XCTAssertFalse(snapshot.isCompleted)
    }

    func testRestartRecoversCycleWriteFailureBeforeAndAfterPhysicalCommit() async throws {
        for afterCommit in [false, true] {
            let url = url(), cycleURL = self.url()
            defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
            let boundary = CycleWriteBoundary(cycleURL)
            let cycle = Prompt13CycleStore(persistence: boundary)
            let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: cycle)
            let supplied = try day(1)
            _ = try await store.update { $0.latestPeriodStart = supplied }
            await boundary.fail(afterCommit: afterCommit)
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            do { _ = try await store.complete(now: Date(timeIntervalSince1970: 1_789_516_800), calendar: calendar); XCTFail() }
            catch { XCTAssertEqual(error as? Prompt13CycleError, .persistenceFailure) }
            let pending = try await Prompt14FileOnboardingPersistence(fileURL: url).load()
            XCTAssertNotNil(pending.pendingCycleCommit)
            let restartedCycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
            let restarted = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: restartedCycle)
            let recovered = try await restarted.snapshot()
            XCTAssertTrue(recovered.isCompleted); XCTAssertNil(recovered.pendingCycleCommit)
            let archive = try await restartedCycle.snapshot()
            XCTAssertEqual(archive.cycleStarts.map(\.date), [supplied])
            let again = try await restarted.snapshot(); XCTAssertEqual(again, recovered)
        }
    }

    func testCompletedDraftDateUpdateUsesSameRecoverableHistoryPath() async throws {
        let url = url(), cycleURL = self.url()
        defer { try? FileManager.default.removeItem(at: url); try? FileManager.default.removeItem(at: cycleURL) }
        let cycle = Prompt13CycleStore(persistence: Prompt13FileCyclePersistence(fileURL: cycleURL))
        let store = Prompt14CycleOnboardingStore(persistence: Prompt14FileOnboardingPersistence(fileURL: url), cycleStore: cycle)
        let original = try day(1), replacement = try day(15)
        _ = try await store.update { $0.latestPeriodStart = original }
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        _ = try await store.complete(now: Date(timeIntervalSince1970: 1_789_516_800), calendar: calendar)
        _ = try await store.update { $0.latestPeriodStart = replacement }
        let archive = try await cycle.snapshot()
        XCTAssertEqual(archive.cycleStarts.filter { !$0.metadata.isDeleted }.map(\.date), [replacement])
        let draft = try await store.snapshot(); XCTAssertNil(draft.pendingCycleCommit)
    }

}
