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

    func testFailedOptimisticAnswerCannotAlterSharedHealthContextOrCompleteOlderSetup() async throws {
        let suite = "FailedSetupContext-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let context = Prompt27AContextStore(defaults: defaults)
        let original = Prompt14OnboardingDraft()
        let persistence = RejectingSetupPersistence(stored: original)
        let store = Prompt14CycleOnboardingStore(draft: original, persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        let model = Prompt14CycleOnboardingViewModel(store: store)
        model.onPersistedDraftChange = { saved, previous in
            context.syncFromCycleOnboarding(saved, previous: previous)
        }
        await model.load()
        let before = context.context
        model.toggleCycleContext(.hormonalBirthControl)
        XCTAssertTrue(model.draft.cycleAffectingContexts.contains(.hormonalBirthControl))
        await model.waitForPendingSaves()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertEqual(context.context, before, "A failed draft must never become shared health information")
        XCTAssertEqual(model.persistedDraft, original)
        model.errorMessage = nil // Dismissing an error must not make unsaved answers safe to complete.
        let finished = await model.finish()
        XCTAssertFalse(finished)
        let attempts = await persistence.saveAttempts
        XCTAssertEqual(attempts, 1, "Completion must not save an older draft after the latest answer failed")
    }

    func testSharedContextChangesOnlyAfterSaveAndExplicitRemovalStillSynchronizes() async throws {
        let suite = "SavedSetupContext-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let context = Prompt27AContextStore(defaults: defaults)
        let persistence = BlockingFirstSetupSave(stored: Prompt14OnboardingDraft())
        let store = Prompt14CycleOnboardingStore(persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        let model = Prompt14CycleOnboardingViewModel(store: store)
        model.onPersistedDraftChange = { saved, previous in
            context.syncFromCycleOnboarding(saved, previous: previous)
        }
        await model.load()
        let before = context.context
        model.toggleCycleContext(.hormonalBirthControl)
        await persistence.waitForSaveStart()
        XCTAssertEqual(context.context, before)
        await persistence.releaseFirstSave()
        await model.waitForPendingSaves()
        XCTAssertEqual(context.context.contraceptionContext.value, .hormonalContraception)
        model.toggleCycleContext(.hormonalBirthControl)
        await model.waitForPendingSaves()
        XCTAssertEqual(context.context.contraceptionContext.value, .unspecified)
        XCTAssertNil(model.errorMessage)
    }

    func testReloadWaitsForExistingSaveQueueInsteadOfReplacingPendingAnswer() async throws {
        let persistence = BlockingFirstSetupSave(stored: Prompt14OnboardingDraft())
        let store = Prompt14CycleOnboardingStore(persistence: persistence,
                                                 cycleStore: .inMemory(), isLoaded: true)
        let model = Prompt14CycleOnboardingViewModel(store: store)
        await model.load()
        model.toggleCycleContext(.hormonalBirthControl)
        await persistence.waitForSaveStart()
        let reload = Task { await model.load() }
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertTrue(model.isLoading)
        XCTAssertTrue(model.draft.cycleAffectingContexts.contains(.hormonalBirthControl))
        await persistence.releaseFirstSave()
        await reload.value
        XCTAssertFalse(model.isLoading)
        XCTAssertTrue(model.draft.cycleAffectingContexts.contains(.hormonalBirthControl))
        let saved = try await store.snapshot()
        XCTAssertEqual(model.draft, saved)
        XCTAssertEqual(model.persistedDraft, saved)
    }

}

private enum SetupWriteFailure: Error, Equatable { case rejected }

private actor RejectingSetupPersistence: Prompt14OnboardingPersistence {
    private(set) var saveAttempts = 0
    let stored: Prompt14OnboardingDraft
    init(stored: Prompt14OnboardingDraft) { self.stored = stored }
    func load() -> Prompt14OnboardingDraft { stored }
    func save(_ draft: Prompt14OnboardingDraft) throws {
        saveAttempts += 1
        throw SetupWriteFailure.rejected
    }
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
