import XCTest
@testable import Fruitfolio

@MainActor
final class CycleSetupPersistenceSafetyTests: XCTestCase {
    func testRejectedDraftWritesRestoreEveryPreviouslySavedAnswer() async throws {
        var original = Prompt14OnboardingDraft()
        original.latestPeriodState = .supplied
        original.latestPeriodStart = try Prompt13LocalDate(year: 2026, month: 9, day: 3)
        original.currentPeriodState = .supplied
        original.currentPeriodAnswer = .yes
        let persistence = RejectingSetupPersistence(stored: original)
        let store = Prompt14CycleOnboardingStore(draft: original, persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        do { _ = try await store.update { $0.cervicalFluidSetupAcknowledged = true }; XCTFail("Expected failed write") }
        catch { XCTAssertEqual(error as? SetupWriteFailure, .rejected) }
        var snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot, original)
        do { _ = try await store.markStarted(); XCTFail("Expected failed write") }
        catch { XCTAssertEqual(error as? SetupWriteFailure, .rejected) }
        snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot, original)
        do {
            _ = try await store.endCurrentPeriod(on: Prompt13LocalDate(year: 2026, month: 9, day: 8),
                                                 today: Prompt13LocalDate(year: 2026, month: 9, day: 10))
            XCTFail("Expected failed write")
        } catch { XCTAssertEqual(error as? SetupWriteFailure, .rejected) }
        snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot, original)
        var replacement = original
        replacement.cervicalFluidSetupAcknowledged = true
        do { try await store.replaceDraft(replacement); XCTFail("Expected failed write") }
        catch { XCTAssertEqual(error as? SetupWriteFailure, .rejected) }
        snapshot = try await store.snapshot()
        XCTAssertEqual(snapshot, original)
        let stored = await persistence.load()
        XCTAssertEqual(stored, original)
    }

    func testSuspendedSaveCannotExposeUncommittedSnapshotOrOverwriteALaterEdit() async throws {
        let original = Prompt14OnboardingDraft()
        let persistence = BlockingFirstSetupSave(stored: original)
        let store = Prompt14CycleOnboardingStore(draft: original, persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        let first = Task { try await store.update { $0.cervicalFluidSetupAcknowledged = true } }
        await persistence.waitForSaveStart()
        var snapshotCompleted = false
        let read = Task { @MainActor in
            let value = try await store.snapshot()
            snapshotCompleted = true
            return value
        }
        let second = Task { try await store.update { $0.bbtUsualMeasurementMinutesAfterMidnight = 420 } }
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertFalse(snapshotCompleted, "A snapshot must not publish an unsaved draft during suspended persistence")
        await persistence.releaseFirstSave()
        _ = try await first.value
        _ = try await second.value
        _ = try await read.value
        let snapshot = try await store.snapshot()
        let persisted = await persistence.load()
        XCTAssertTrue(snapshot.cervicalFluidSetupAcknowledged)
        XCTAssertEqual(snapshot.bbtUsualMeasurementMinutesAfterMidnight, 420)
        XCTAssertEqual(persisted, snapshot, "An older suspended write must not overwrite the subsequent answer")
    }
    func testCancelledQueuedEditCannotMutateAnswersOrBlockSubsequentSaves() async throws {
        let persistence = BlockingFirstSetupSave(stored: Prompt14OnboardingDraft())
        let store = Prompt14CycleOnboardingStore(persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        let first = Task { try await store.update { $0.cervicalFluidSetupAcknowledged = true } }
        await persistence.waitForSaveStart()
        let cancelled = Task { try await store.update { $0.bbtUsualMeasurementMinutesAfterMidnight = 999 } }
        cancelled.cancel()
        await persistence.releaseFirstSave()
        _ = try await first.value
        do { _ = try await cancelled.value; XCTFail("Cancelled queued edits must not save") }
        catch { XCTAssertTrue(error is CancellationError) }
        let final = try await store.update { $0.bbtUsualMeasurementMinutesAfterMidnight = 420 }
        XCTAssertTrue(final.cervicalFluidSetupAcknowledged)
        XCTAssertEqual(final.bbtUsualMeasurementMinutesAfterMidnight, 420)
        let persisted = await persistence.load()
        XCTAssertEqual(persisted, final)
    }

}

private enum SetupWriteFailure: Error, Equatable { case rejected }

private actor RejectingSetupPersistence: Prompt14OnboardingPersistence {
    let stored: Prompt14OnboardingDraft
    init(stored: Prompt14OnboardingDraft) { self.stored = stored }
    func load() -> Prompt14OnboardingDraft { stored }
    func save(_ draft: Prompt14OnboardingDraft) throws { throw SetupWriteFailure.rejected }
    func erase() throws { throw SetupWriteFailure.rejected }
}

private actor BlockingFirstSetupSave: Prompt14OnboardingPersistence {
    private var stored: Prompt14OnboardingDraft
    private var shouldBlock = true
    private var started = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var saveWaiter: CheckedContinuation<Void, Never>?
    init(stored: Prompt14OnboardingDraft) { self.stored = stored }
    func load() -> Prompt14OnboardingDraft { stored }
    func save(_ draft: Prompt14OnboardingDraft) async {
        if shouldBlock {
            shouldBlock = false
            await withCheckedContinuation { continuation in
                saveWaiter = continuation
                started = true
                startWaiter?.resume(); startWaiter = nil
            }
        }
        stored = draft
    }
    func waitForSaveStart() async {
        if started { return }
        await withCheckedContinuation { startWaiter = $0 }
    }
    func releaseFirstSave() { saveWaiter?.resume(); saveWaiter = nil }
    func erase() { stored = Prompt14OnboardingDraft() }
}
