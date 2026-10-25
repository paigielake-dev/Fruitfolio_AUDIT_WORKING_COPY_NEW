import Foundation

// MARK: - Prompt 14 onboarding value types

nonisolated enum Prompt14TriState: String, Codable, CaseIterable, Sendable {
    case yes
    case no
    case notSure = "not_sure"
}

nonisolated enum Prompt14KnowledgeState: String, Codable, Sendable {
    case unanswered
    case supplied
    case unknown
    case notSure = "not_sure"
    case none
    case preferNotToSay = "prefer_not_to_say"
    case skipped
}

nonisolated enum Prompt14SubjectiveRegularity: String, Codable, CaseIterable, Sendable, Identifiable {
    case prettyPredictable = "pretty_predictable"
    case variesALittle = "varies_a_little"
    case variesALot = "varies_a_lot"
    case dontKnowYet = "dont_know_yet"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .prettyPredictable: return "pretty predictable"
        case .variesALittle: return "they vary a little"
        case .variesALot: return "they vary a lot"
        case .dontKnowYet: return "i don’t know yet"
        }
    }
}

nonisolated enum Prompt14CycleAffectingContext: String, Codable, CaseIterable, Sendable, Identifiable {
    case hormonalBirthControl = "hormonal_birth_control"
    case fertilityMedication = "fertility_medication"
    case otherHormoneMedication = "other_hormone_related_medication"
    case none
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hormonalBirthControl: return "hormonal birth control"
        case .fertilityMedication: return "fertility medication"
        case .otherHormoneMedication: return "other hormone-related medication"
        case .none: return "none"
        case .preferNotToSay: return "prefer not to say"
        }
    }
}

nonisolated enum Prompt14RecentContext: String, Codable, CaseIterable, Sendable, Identifiable {
    case recentPregnancy = "recent_pregnancy"
    case postpartum
    case breastfeeding
    case recentlyStoppedHormonalBirthControl = "recently_stopped_hormonal_birth_control"
    case none
    case preferNotToSay = "prefer_not_to_say"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentPregnancy: return "recent pregnancy"
        case .postpartum: return "postpartum"
        case .breastfeeding: return "breastfeeding"
        case .recentlyStoppedHormonalBirthControl: return "recently stopped hormonal birth control"
        case .none: return "none"
        case .preferNotToSay: return "prefer not to say"
        }
    }
}

nonisolated enum Prompt14TrackingPreference: String, Codable, CaseIterable, Sendable, Identifiable {
    case periods
    case symptoms
    case bbt
    case cervicalFluid = "cervical_fluid"
    case mood
    case energy
    case sleep
    case medication
    case notes
    case cyclePatterns = "cycle_patterns"
    case estimatedPeriodTiming = "estimated_period_timing"
    case fertilityRelatedEstimates = "fertility_related_estimates"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .periods: return "periods"
        case .symptoms: return "symptoms"
        case .bbt: return "BBT"
        case .cervicalFluid: return "cervical fluid"
        case .mood: return "mood"
        case .energy: return "energy"
        case .sleep: return "sleep"
        case .medication: return "medication"
        case .notes: return "notes"
        case .cyclePatterns: return "cycle patterns"
        case .estimatedPeriodTiming: return "estimated period timing"
        case .fertilityRelatedEstimates: return "fertility-related estimates"
        }
    }
}

nonisolated enum Prompt14FertilityEstimatePreference: String, Codable, CaseIterable, Sendable {
    case showEstimates = "show_estimates"
    case notRightNow = "not_right_now"
    case skipped
}

nonisolated enum Prompt14BBTTrackingChoice: String, Codable, CaseIterable, Sendable {
    case yes
    case wouldLikeToStart = "would_like_to_start"
    case notRightNow = "not_right_now"
    case skipped
}

nonisolated enum Prompt14TemperatureUnitPreference: String, Codable, CaseIterable, Sendable {
    case fahrenheit
    case celsius

    var symbol: String {
        switch self {
        case .fahrenheit: return "°F"
        case .celsius: return "°C"
        }
    }
}

nonisolated enum Prompt14OnboardingStep: String, Codable, CaseIterable, Sendable {
    case intro
    case latestPeriod
    case currentPeriod
    case periodEnd
    case previousHistory
    case subjectiveRegularity
    case cycleAffectingContext
    case recentContext
    case trackingPreferences
    case fertilityEstimates
    case bbtSetup
    case cervicalFluidSetup
    case complete
}

nonisolated struct Prompt14OnboardingDraft: Codable, Equatable, Sendable {
    var schemaVersion: Int = 1
    var step: Prompt14OnboardingStep = .intro

    var latestPeriodState: Prompt14KnowledgeState = .unanswered
    var latestPeriodStart: Prompt13LocalDate?

    var currentPeriodState: Prompt14KnowledgeState = .unanswered
    var currentPeriodAnswer: Prompt14TriState?

    var periodEndState: Prompt14KnowledgeState = .unanswered
    var periodEnd: Prompt13LocalDate?

    var previousHistoryState: Prompt14KnowledgeState = .unanswered
    var historicalPeriodStarts: [Prompt13LocalDate] = []

    var regularityState: Prompt14KnowledgeState = .unanswered
    var subjectiveRegularity: Prompt14SubjectiveRegularity?

    var cycleContextState: Prompt14KnowledgeState = .unanswered
    var cycleAffectingContexts: Set<Prompt14CycleAffectingContext> = []

    var recentContextState: Prompt14KnowledgeState = .unanswered
    var recentContexts: Set<Prompt14RecentContext> = []

    var trackingPreferencesState: Prompt14KnowledgeState = .unanswered
    var trackingPreferences: Set<Prompt14TrackingPreference> = []

    var fertilityPreference: Prompt14FertilityEstimatePreference?

    var bbtTrackingChoice: Prompt14BBTTrackingChoice?
    var bbtUnit: Prompt14TemperatureUnitPreference?
    /// Local clock preference only. This is not a temperature observation.
    var bbtUsualMeasurementMinutesAfterMidnight: Int?

    var cervicalFluidSetupAcknowledged: Bool = false

    var startedAt: Date?
    var updatedAt: Date = Date()
    var completedAt: Date?
    var didCommitCycleStarts: Bool = false

    var isCompleted: Bool { completedAt != nil }

    var allSuppliedCycleStarts: [Prompt13LocalDate] {
        var values = historicalPeriodStarts
        if let latestPeriodStart { values.append(latestPeriodStart) }
        return Array(Set(values)).sorted()
    }

    mutating func markUpdated(at date: Date = Date()) {
        updatedAt = date
    }

    mutating func selectCycleContext(_ value: Prompt14CycleAffectingContext) {
        cycleContextState = .supplied
        switch value {
        case .none:
            cycleAffectingContexts = [.none]
        case .preferNotToSay:
            cycleAffectingContexts = [.preferNotToSay]
        default:
            cycleAffectingContexts.remove(.none)
            cycleAffectingContexts.remove(.preferNotToSay)
            if cycleAffectingContexts.contains(value) {
                cycleAffectingContexts.remove(value)
            } else {
                cycleAffectingContexts.insert(value)
            }
        }
        markUpdated()
    }

    mutating func selectRecentContext(_ value: Prompt14RecentContext) {
        recentContextState = .supplied
        switch value {
        case .none:
            recentContexts = [.none]
        case .preferNotToSay:
            recentContexts = [.preferNotToSay]
        default:
            recentContexts.remove(.none)
            recentContexts.remove(.preferNotToSay)
            if recentContexts.contains(value) {
                recentContexts.remove(value)
            } else {
                recentContexts.insert(value)
            }
        }
        markUpdated()
    }

    mutating func toggleTrackingPreference(_ value: Prompt14TrackingPreference) {
        trackingPreferencesState = .supplied
        if trackingPreferences.contains(value) {
            trackingPreferences.remove(value)
        } else {
            trackingPreferences.insert(value)
        }
        markUpdated()
    }
}

