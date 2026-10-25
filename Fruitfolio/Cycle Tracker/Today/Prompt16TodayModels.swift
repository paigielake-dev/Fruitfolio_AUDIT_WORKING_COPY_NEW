import Foundation

nonisolated enum Prompt16TodayContext: String, Equatable, Sendable {
    case menstruation
    case cycleContext = "cycle_context"
    case insufficientData = "insufficient_data"

    var title: String {
        switch self {
        case .menstruation:
            return "menstruation"
        case .cycleContext:
            return "your cycle today"
        case .insufficientData:
            return "your cycle picture is building"
        }
    }

    var explanation: String {
        switch self {
        case .menstruation:
            return "you logged that your period is happening now. Fruitfolio will keep this recorded information separate from later estimates."
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
                && onboarding.latestPeriodStart != nil

        let context: Prompt16TodayContext
        if recordedBleedingToday || onboardingSaysCurrentPeriod {
            context = .menstruation
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
            hasRecordedBleedingToday: recordedBleedingToday
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
        let today = try Prompt13LocalDate(now, calendar: calendar)
        async let archive = cycleStore.snapshot()
        async let derived = cycleStore.derivedState(on: today, generatedAt: now)
        async let onboarding = onboardingStore.snapshot()

        return try Prompt16TodayStateBuilder().makeState(
            archive: await archive,
            derivedState: await derived,
            onboarding: await onboarding
        )
    }
}
