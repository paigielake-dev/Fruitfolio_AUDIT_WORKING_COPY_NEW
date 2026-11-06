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
        defer { releaseOperation() }
        try Task.checkCancellation()
        // Explicit erase may remove an unsupported current file without decoding
        // it. The file actor still checks the exact baseline before removal.
        if persistChanges { try await loadIfNeeded() }
        let baseline = draft
        do {
            let result = try await body(self)
            if persistChanges {
                try Task.checkCancellation()
                if draft != baseline { try await persistence.save(draft) }
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

    func replaceDraft(_ newDraft: Prompt14OnboardingDraft) async throws {
        return try await withDraftOperation { store in
            try await store.replaceDraftUnlocked(newDraft)
        }
    }

    private func replaceDraftUnlocked(_ newDraft: Prompt14OnboardingDraft) async throws {
        try await loadIfNeeded()
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
        mutate(&draft)
        draft.markUpdated()
        // The enclosing operation commits the complete candidate once.
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
    func complete(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) async throws -> Prompt14OnboardingDraft {
        return try await withDraftOperation { store in
            try await store.completeUnlocked(now: now, calendar: calendar)
        }
    }

    private func completeUnlocked(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()

        let today = try Prompt13LocalDate(now, calendar: calendar)
        try await cycleStore.reconcileOnboardingCycleStarts(
            dates: Set(draft.allSuppliedCycleStarts),
            replacingCommittedHistory: false,
            now: now,
            today: today
        )

        draft.didCommitCycleStarts = true
        draft.step = .complete
        draft.completedAt = draft.completedAt ?? now
        draft.markUpdated(at: now)
        // The enclosing operation commits the complete candidate once.
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
        try await cycleStore.reconcileOnboardingCycleStarts(
            dates: Set(draft.allSuppliedCycleStarts),
            replacingCommittedHistory: true,
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

    private func loadIfNeeded() async throws {
        guard !isLoaded else { return }
        draft = try await persistence.load()
        isLoaded = true
    }
}
