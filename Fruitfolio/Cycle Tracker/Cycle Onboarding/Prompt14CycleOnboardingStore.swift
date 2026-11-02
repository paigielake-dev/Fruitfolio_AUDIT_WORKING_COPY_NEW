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

    func snapshot() async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        return draft
    }

    func replaceDraft(_ newDraft: Prompt14OnboardingDraft) async throws {
        try await loadIfNeeded()
        let wasCommitted = draft.didCommitCycleStarts
        draft = newDraft
        draft.markUpdated()
        if wasCommitted || draft.didCommitCycleStarts {
            try await reconcileCommittedCycleStarts(referenceDate: draft.allSuppliedCycleStarts.last)
            draft.didCommitCycleStarts = true
        }
        try await persistence.save(draft)
    }

    func update(_ mutate: @Sendable (inout Prompt14OnboardingDraft) -> Void) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        mutate(&draft)
        draft.markUpdated()
        try await persistence.save(draft)
        return draft
    }

    func markStarted(now: Date = Date()) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()
        if draft.startedAt == nil { draft.startedAt = now }
        draft.markUpdated(at: now)
        try await persistence.save(draft)
        return draft
    }

    /// Commits only user-supplied period starts into Prompt 13.
    /// Existing active starts on the same date are reused so resume/retry cannot create duplicates.
    func complete(now: Date = Date(), calendar: Calendar = .autoupdatingCurrent) async throws -> Prompt14OnboardingDraft {
        try await loadIfNeeded()

        let today = try Prompt13LocalDate(now, calendar: calendar)
        let existing = try await cycleStore.snapshot().cycleStarts.filter { !$0.metadata.isDeleted }
        var existingDates = Set(existing.map(\.date))

        for date in draft.allSuppliedCycleStarts where !existingDates.contains(date) {
            _ = try await cycleStore.recordCycleStart(on: date, source: .onboardingConfirmed, now: now, today: today)
            existingDates.insert(date)
        }

        draft.didCommitCycleStarts = true
        draft.step = .complete
        draft.completedAt = draft.completedAt ?? now
        draft.markUpdated(at: now)
        try await persistence.save(draft)
        return draft
    }

    func endCurrentPeriod(
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
        try await persistence.save(draft)
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
        let desired = Set(draft.allSuppliedCycleStarts)
        // Migrate dates committed by older Fruitfolio builds before Prompt 14
        // had a dedicated provenance value. Only currently supplied dates are
        // adopted; unrelated user-entered history is never claimed.
        try await cycleStore.adoptCycleStartsAsOnboarding(dates: desired, now: now)
        let snapshot = try await cycleStore.snapshot()
        let onboardingRecords = snapshot.cycleStarts.filter {
            !$0.metadata.isDeleted && $0.source == .onboardingConfirmed
        }

        for record in onboardingRecords where !desired.contains(record.date) {
            try await cycleStore.deleteCycleStart(
                id: record.id,
                now: now,
                referenceDate: referenceDate ?? record.date
            )
        }

        let refreshed = try await cycleStore.snapshot().cycleStarts.filter { !$0.metadata.isDeleted }
        var activeDates = Set(refreshed.map(\.date))
        for date in desired where !activeDates.contains(date) {
            _ = try await cycleStore.recordCycleStart(
                on: date,
                source: .onboardingConfirmed,
                now: now,
                today: today
            )
            activeDates.insert(date)
        }
    }

    func eraseOnboardingOnly() async throws {
        // Keep the visible saved answers intact if storage refuses deletion.
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
