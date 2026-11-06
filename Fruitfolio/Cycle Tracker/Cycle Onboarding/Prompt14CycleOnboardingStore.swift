import Foundation

nonisolated enum Prompt14CurrentPeriodUpdateError: Error, Equatable, Sendable {
    case noOpenPeriod
    case endBeforeStart
    case endInFuture
}

actor Prompt14CycleOnboardingStore {
    static let shared = Prompt14CycleOnboardingStore()

    private let persistence: any Prompt14OnboardingPersistence
    private let cycleStore: Prompt13CycleStore
    private var draft: Prompt14OnboardingDraft
    private var isLoaded: Bool

    init(
        draft: Prompt14OnboardingDraft = Prompt14OnboardingDraft(),
        persistence: any Prompt14OnboardingPersistence = Prompt14FileOnboardingPersistence(),
        cycleStore: Prompt13CycleStore = .shared,
        isLoaded: Bool = false
    ) {
        self.draft = draft
        self.persistence = persistence
        self.cycleStore = cycleStore
        self.isLoaded = isLoaded
    }

    static func inMemory(
        draft: Prompt14OnboardingDraft = Prompt14OnboardingDraft(),
        cycleStore: Prompt13CycleStore = .inMemory()
    ) -> Prompt14CycleOnboardingStore {
        Prompt14CycleOnboardingStore(
            draft: draft,
            persistence: Prompt14InMemoryOnboardingPersistence(draft: draft),
            cycleStore: cycleStore,
            isLoaded: true
        )
    }

    // Serializes the draft across suspension points, including cycle-store calls.
    // This protects one file; cross-file completion remains resumable, not atomic.
    private var persistedDuringOperation: Prompt14OnboardingDraft?
    private var operationActive = false
    private var operationWaiters: [CheckedContinuation<Void, Never>] = []

    private func acquireOperation() async {
        if !operationActive { operationActive = true; return }
        await withCheckedContinuation { operationWaiters.append($0) }
    }

    private func releaseOperation() {
        if operationWaiters.isEmpty { operationActive = false }
        else { operationWaiters.removeFirst().resume() }
    }

    private func withDraftOperation<T: Sendable>(
        persistChanges: Bool = true,
        _ body: (isolated Prompt14CycleOnboardingStore) async throws -> T
    ) async throws -> T {
        await acquireOperation()
        persistedDuringOperation = nil
        defer {
            persistedDuringOperation = nil
            releaseOperation()
        }
        try Task.checkCancellation()
        // Explicit erase may remove an unsupported current file without decoding
        // it. The file actor still checks the exact baseline before removal.
        if persistChanges { try await loadIfNeeded() }
        let baseline = draft
        do {
            let result = try await body(self)
            if persistChanges, draft != (persistedDuringOperation ?? baseline) {
                try await persistCurrentDraft()
            }
            return result
        } catch {
            draft = baseline
            isLoaded = false
            throw error
        }
    }

    func snapshot() async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            try await store.snapshotUnlocked()
        }
    }

    private func snapshotUnlocked() async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        return draft
    }

    /// The editor acknowledges saved answers and progress before replacing them.
    /// Comparison respects existing ISO8601 precision and excludes only the
    /// administrative update clock, including defaults for a missing file.
    func saveDraft(_ candidate: Prompt14OnboardingDraft, expecting expected: Prompt14OnboardingDraft) async throws -> Prompt14OnboardingDraft {
        try await withDraftOperation { store in
            // Refresh before issuing a receipt, including idempotent retries.
            // Receipt checking never saves the candidate or discards its editor.
            // An existing journal may resume its separately persisted request.
            try await store.refreshDraftForReceipt()
            if try store.snapshotBytes(store.draft) == store.snapshotBytes(candidate) {
                return store.draft
            }
            try store.requireSnapshot(expected)
            try await store.replaceDraftUnlocked(candidate)
            return store.draft
        }
    }

    /// Receipt recovery never saves the candidate. A different saved draft
    /// returns nil. Existing persisted journal requests may resume on loading.
    func savedReceipt(matching candidate: Prompt14OnboardingDraft) async throws -> Prompt14OnboardingDraft? {
        try await withDraftOperation { store in
            try await store.refreshDraftForReceipt()
            return try store.snapshotBytes(store.draft) == store.snapshotBytes(candidate) ? store.draft : nil
        }
    }

    private func refreshDraftForReceipt() async throws {
        draft = try await persistence.load()
        persistedDuringOperation = draft
        try await resumePendingCycleCommit()
    }

    private func persistedBytes(_ value: Prompt14OnboardingDraft) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(value)
    }

    private func snapshotBytes(_ value: Prompt14OnboardingDraft) throws -> Data {
        var snapshot = value
        // A missing file has a fresh default update clock on each read. That
        // administrative clock is not a change to an answer or progress field.
        snapshot.updatedAt = Date(timeIntervalSince1970: 0)
        return try persistedBytes(snapshot)
    }

    private func requireSnapshot(_ expected: Prompt14OnboardingDraft) throws {
        guard try snapshotBytes(draft) == snapshotBytes(expected) else {
            throw Prompt14OnboardingPersistenceError.editingConflict
        }
    }

    private func sameAnswers(_ first: Prompt14OnboardingDraft, _ second: Prompt14OnboardingDraft) throws -> Bool {
        func answers(_ value: Prompt14OnboardingDraft) -> Prompt14OnboardingDraft {
            var result = value
            result.step = .intro
            result.updatedAt = Date(timeIntervalSince1970: 0)
            result.completedAt = nil
            result.didCommitCycleStarts = false
            result.pendingCycleCommit = nil
            return result
        }
        return try persistedBytes(answers(first)) == persistedBytes(answers(second))
    }

    func replaceDraft(_ newDraft: Prompt14OnboardingDraft) async throws {
        return try await withDraftOperation { store in
            try await store.replaceDraftUnlocked(newDraft)
        }
    }

    private func replaceDraftUnlocked(_ newDraft: Prompt14OnboardingDraft) async throws {
        try await loadIfNeeded()
        guard newDraft.pendingCycleCommit == nil else {
            throw Prompt14OnboardingPersistenceError.unsupportedFormat
        }
        let wasCommitted = draft.didCommitCycleStarts
        draft = newDraft
        draft.markUpdated()
        if wasCommitted || draft.didCommitCycleStarts {
            try await reconcileCommittedCycleStarts(referenceDate: draft.allSuppliedCycleStarts.last)
            draft.didCommitCycleStarts = true
        }
        // The enclosing operation commits the complete candidate once.
    }

    func update(_ mutate: @Sendable (inout Prompt14OnboardingDraft) -> Void) async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            try await store.updateUnlocked(mutate)
        }
    }

    private func updateUnlocked(_ mutate: @Sendable (inout Prompt14OnboardingDraft) -> Void) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        let previousDates = draft.allSuppliedCycleStarts
        let wasCommitted = draft.didCommitCycleStarts
        mutate(&draft)
        guard draft.pendingCycleCommit == nil else {
            throw Prompt14OnboardingPersistenceError.unsupportedFormat
        }
        draft.markUpdated()
        if wasCommitted && draft.allSuppliedCycleStarts != previousDates {
            try await reconcileCommittedCycleStarts(referenceDate: draft.allSuppliedCycleStarts.last)
        }
        // Ordinary draft changes commit at the enclosing boundary.
        return draft
    }

    func markStarted(now: Date = Date()) async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            try await store.markStartedUnlocked(now: now)
        }
    }

    private func markStartedUnlocked(now: Date = Date()) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        if draft.startedAt == nil { draft.startedAt = now }
        draft.markUpdated(at: now)
        // The enclosing operation commits the complete candidate once.
        return draft
    }

    /// Commits only user-supplied period starts into Prompt 13.
    /// Existing active starts on the same date are reused so resume/retry cannot create duplicates.
    func complete(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent, expecting expected: Prompt14OnboardingDraft? = nil) async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            if let expected {
                try await store.refreshDraftForReceipt()
                // Retrying an acknowledged/lost-ack completion of the same saved
                // answers is read-only. Changed answers still require a fresh edit.
                if store.draft.isCompleted, try store.sameAnswers(store.draft, expected) {
                    return store.draft
                }
                try store.requireSnapshot(expected)
            }
            return try await store.completeUnlocked(now: now, calendar: calendar)
        }
    }

    private func completeUnlocked(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()

        let today = try Prompt13LocalDate(now, calendar: calendar)
        try await commitCycleHistory(
            replacingCommittedHistory: false,
            completionRequestedAt: now,
            now: now,
            today: today
        )
        return draft
    }

    func endCurrentPeriod(
        on endDate: Prompt13LocalDate,
        today: Prompt13LocalDate,
        now: Date = Date()
    ) async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            try await store.endCurrentPeriodUnlocked(on: endDate, today: today, now: now)
        }
    }

    private func endCurrentPeriodUnlocked(
        on endDate: Prompt13LocalDate,
        today: Prompt13LocalDate,
        now: Date = Date()
    ) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()

        guard
            draft.latestPeriodState == .supplied,
            let startDate = draft.latestPeriodStart,
            draft.currentPeriodState == .supplied,
            draft.currentPeriodAnswer == .yes
        else {
            throw Prompt14CurrentPeriodUpdateError.noOpenPeriod
        }

        guard endDate >= startDate else {
            throw Prompt14CurrentPeriodUpdateError.endBeforeStart
        }

        guard endDate <= today else {
            throw Prompt14CurrentPeriodUpdateError.endInFuture
        }

        draft.currentPeriodState = .supplied
        draft.currentPeriodAnswer = .no
        draft.periodEndState = .supplied
        draft.periodEnd = endDate
        draft.markUpdated(at: now)
        // The enclosing operation commits the complete candidate once.
        return draft
    }

    /// Keeps Prompt 13 history exactly aligned with the dates the user currently
    /// supplies through onboarding/My Context, without touching independently
    /// logged or imported cycle starts.
    private func reconcileCommittedCycleStarts(
        referenceDate: Prompt13LocalDate?,
        now: Date = Date(),
        calendar: Calendar = .autoupdatingCurrent
    ) async throws {
        let today = try Prompt13LocalDate(now, calendar: calendar)
        try await commitCycleHistory(
            replacingCommittedHistory: true,
            completionRequestedAt: nil,
            now: now,
            today: today
        )
    }

    func eraseOnboardingOnly() async throws {
        return try await withDraftOperation(persistChanges: false) { store in
            try await store.eraseOnboardingOnlyUnlocked()
        }
    }

    private func eraseOnboardingOnlyUnlocked() async throws {
        try await persistence.erase()
        draft = Prompt14OnboardingDraft()
        isLoaded = true
    }

    private func persistCurrentDraft() async throws {
        try Task.checkCancellation()
        try await persistence.save(draft)
        persistedDuringOperation = draft
    }

    private func commitCycleHistory(
        replacingCommittedHistory: Bool,
        completionRequestedAt: Date?,
        now: Date,
        today: Prompt13LocalDate
    ) async throws {
        let dates = draft.allSuppliedCycleStarts
        guard dates.allSatisfy({ $0 <= today }) else {
            throw Prompt13CycleError.futureObservationNotAllowed
        }
        draft.pendingCycleCommit = Prompt14PendingCycleCommit(
            dates: dates,
            replacingCommittedHistory: replacingCommittedHistory,
            completionRequestedAt: completionRequestedAt,
            requestedAt: now,
            today: today
        )
        // Persist the explicit request before touching the other file. A restart
        // can safely resume any phase without inventing dates or duplicating IDs.
        try await persistCurrentDraft()
        try await resumePendingCycleCommit()
    }

    private func resumePendingCycleCommit() async throws {
        guard let pending = draft.pendingCycleCommit else { return }
        guard pending.dates == draft.allSuppliedCycleStarts,
              pending.dates.allSatisfy({ $0 <= pending.today }) else {
            throw Prompt14OnboardingPersistenceError.unsupportedFormat
        }
        try await cycleStore.reconcileOnboardingCycleStarts(
            dates: Set(pending.dates),
            replacingCommittedHistory: pending.replacingCommittedHistory,
            now: pending.requestedAt,
            today: pending.today
        )
        draft.didCommitCycleStarts = true
        if let completedAt = pending.completionRequestedAt {
            draft.step = .complete
            draft.completedAt = draft.completedAt ?? completedAt
        }
        draft.pendingCycleCommit = nil
        draft.markUpdated(at: pending.requestedAt)
        try await persistCurrentDraft()
    }

    private func loadIfNeeded() async throws {
        guard !isLoaded else { return }
        do {
            draft = try await persistence.load()
            try await resumePendingCycleCommit()
            isLoaded = true
        } catch {
            isLoaded = false
            throw error
        }
    }
}
