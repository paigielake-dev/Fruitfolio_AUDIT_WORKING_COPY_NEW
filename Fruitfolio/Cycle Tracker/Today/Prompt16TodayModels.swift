import Foundation

nonisolated enum Prompt16TodayContext: String, Equatable, Sendable {
    case menstruation
    case reportedOpenPeriod = "reported_open_period"
    case cycleContext = "cycle_context"
    case insufficientData = "insufficient_data"

    var title: String {
        switch self {
        case .menstruation:
            return "bleeding recorded today"
        case .reportedOpenPeriod:
            return "reported open period"
        case .cycleContext:
            return "your cycle today"
        case .insufficientData:
            return "your cycle picture is building"
        }
    }

    var explanation: String {
        switch self {
        case .menstruation:
            return "you recorded bleeding for today. this observation stays separate from cycle estimates and does not establish bleeding on other days."
        case .reportedOpenPeriod:
            return "your saved period information says this period is still open. this earlier report does not establish bleeding on unlogged days; you can update the period end when you know it."
        case .cycleContext:
            return "Fruitfolio has your recorded cycle start. More biological context can appear as enough information becomes available."
        case .insufficientData:
            return "keep logging what you know and Fruitfolio will fill in the picture without guessing at missing pieces."
        }
    }
}

nonisolated struct Prompt16TodayState: Equatable, Sendable {
    let cycleDay: Int?
    let context: Prompt16TodayContext
    let bbtShortcutEnabled: Bool
    let bbtUnit: Prompt14TemperatureUnitPreference?
    let hasRecordedTemperatureToday: Bool
    let hasRecordedBleedingToday: Bool
    var hasReportedOpenPeriod: Bool = false

    static let empty = Prompt16TodayState(
        cycleDay: nil,
        context: .insufficientData,
        bbtShortcutEnabled: false,
        bbtUnit: nil,
        hasRecordedTemperatureToday: false,
        hasRecordedBleedingToday: false
    )
}

nonisolated struct Prompt16TodayStateBuilder: Sendable {
    func makeState(
        archive: Prompt13CycleArchive,
        derivedState: Prompt13DerivedState,
        onboarding: Prompt14OnboardingDraft
    ) -> Prompt16TodayState {
        let today = derivedState.currentDate

        let recordedBleedingToday = archive.bleedingObservations.contains { observation in
            !observation.metadata.isDeleted
                && observation.date == today
                && observation.flowLevel != .none
        }

        let onboardingSaysCurrentPeriod =
            onboarding.currentPeriodState == .supplied
                && onboarding.currentPeriodAnswer == .yes
                && onboarding.latestPeriodState == .supplied
                && onboarding.latestPeriodStart.map { $0 <= today } == true
                && !(onboarding.periodEndState == .supplied && onboarding.periodEnd != nil)

        let context: Prompt16TodayContext
        if recordedBleedingToday {
            context = .menstruation
        } else if onboardingSaysCurrentPeriod {
            context = .reportedOpenPeriod
        } else if derivedState.currentCycleDay != nil {
            context = .cycleContext
        } else {
            context = .insufficientData
        }

        let bbtShortcutEnabled =
            onboarding.trackingPreferences.contains(.bbt)
                && (onboarding.bbtTrackingChoice == .yes
                    || onboarding.bbtTrackingChoice == .wouldLikeToStart)

        let recordedTemperatureToday = archive.temperatureObservations.contains { observation in
            !observation.metadata.isDeleted
                && observation.date == today
        }

        return Prompt16TodayState(
            cycleDay: derivedState.currentCycleDay,
            context: context,
            bbtShortcutEnabled: bbtShortcutEnabled,
            bbtUnit: onboarding.bbtUnit,
            hasRecordedTemperatureToday: recordedTemperatureToday,
            hasRecordedBleedingToday: recordedBleedingToday,
            hasReportedOpenPeriod: onboardingSaysCurrentPeriod
        )
    }
}

nonisolated struct Prompt16TodayLoader: Sendable {
    let cycleStore: Prompt13CycleStore
    let onboardingStore: Prompt14CycleOnboardingStore
    let calendar: Calendar

    init(
        cycleStore: Prompt13CycleStore = .shared,
        onboardingStore: Prompt14CycleOnboardingStore = .shared,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.cycleStore = cycleStore
        self.onboardingStore = onboardingStore
        self.calendar = calendar
    }

    func load(now: Date = Date()) async throws -> Prompt16TodayState {
        try await loadSnapshot(now: now).state
    }

    func loadSnapshot(now: Date = Date()) async throws -> Prompt16TodayLoadSnapshot {
        let today = try Prompt13LocalDate(now, calendar: calendar)
        // Loading onboarding may resume a persisted cycle-history commit. Capture
        // archive + derived state only after that recovery has acknowledged.
        let onboarding = try await onboardingStore.snapshot()
        let cycle = try await cycleStore.snapshotWithDerivedState(on: today, generatedAt: now)
        try Task.checkCancellation()
        let state = Prompt16TodayStateBuilder().makeState(archive: cycle.archive,
            derivedState: cycle.derivedState, onboarding: onboarding)
        return Prompt16TodayLoadSnapshot(state: state, archive: cycle.archive,
            derivedState: cycle.derivedState, onboarding: onboarding, asOfDate: now)
    }
}

nonisolated struct Prompt16TodayLoadSnapshot: Sendable {
    let state: Prompt16TodayState
    let archive: Prompt13CycleArchive
    let derivedState: Prompt13DerivedState
    let onboarding: Prompt14OnboardingDraft
    let asOfDate: Date
}

nonisolated struct Prompt16PredictionLearningInfo: Equatable, Sendable {
    let title: String
    let body: String
    let progress: String
}
