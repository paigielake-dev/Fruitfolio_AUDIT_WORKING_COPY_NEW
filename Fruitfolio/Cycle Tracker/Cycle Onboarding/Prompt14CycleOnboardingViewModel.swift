import Foundation
import SwiftUI
import Combine

@MainActor
final class Prompt14CycleOnboardingViewModel: ObservableObject {
    @Published private(set) var draft = Prompt14OnboardingDraft()
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var displayedMonth = Date()
    @Published var historyPickerVisible = false
    @Published var historyEditingDate: Prompt13LocalDate?

    private let store: Prompt14CycleOnboardingStore
    private let calendar: Calendar

    init(
        store: Prompt14CycleOnboardingStore = .shared,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.store = store
        self.calendar = calendar
    }

    func load() async {
        do {
            draft = try await store.snapshot()
            isLoading = false
        } catch {
            errorMessage = "your cycle setup couldn’t be opened right now ♡"
            isLoading = false
        }
    }

    /// Seeds only exact overlaps from My Context into onboarding. Existing
    /// explicit onboarding answers win; this never guesses an ambiguous state.
    func mergeSharedContextIfNeeded(_ context: Prompt27AUserReproductiveContext) {
        var copy = draft
        var changed = false

        if copy.cycleContextState == .unanswered || copy.cycleContextState == .skipped {
            var values = Set<Prompt14CycleAffectingContext>()
            switch context.contraceptionContext.value {
            case .hormonalContraception: values.insert(.hormonalBirthControl)
            case .preferNotToSpecify: values.insert(.preferNotToSay)
            default: break
            }
            switch context.fertilityTreatmentContext.value {
            case .currentlyUndergoing: values.insert(.fertilityMedication)
            case .preferNotToSpecify: values.insert(.preferNotToSay)
            default: break
            }
            if values.contains(.preferNotToSay) { values = [.preferNotToSay] }
            if !values.isEmpty {
                copy.cycleAffectingContexts = values
                copy.cycleContextState = .supplied
                changed = true
            }
        }

        if copy.recentContextState == .unanswered || copy.recentContextState == .skipped {
            var values = Set<Prompt14RecentContext>()
            switch context.reproductiveStage.value {
            case .postpartum: values.insert(.postpartum)
            case .preferNotToSpecify: values.insert(.preferNotToSay)
            default: break
            }
            switch context.lactationContext.value {
            case .breastfeedingOrLactating: values.insert(.breastfeeding)
            case .preferNotToSpecify: values.insert(.preferNotToSay)
            default: break
            }
            if values.contains(.preferNotToSay) { values = [.preferNotToSay] }
            if !values.isEmpty {
                copy.recentContexts = values
                copy.recentContextState = .supplied
                changed = true
            }
        }

        guard changed else { return }
        copy.markUpdated()
        draft = copy
        Task {
            do { try await store.replaceDraft(copy) }
            catch { await MainActor.run { self.errorMessage = "your shared context couldn’t be synced right now ♡" } }
        }
    }

    func getStarted() {
        mutate { draft in
            draft.startedAt = draft.startedAt ?? Date()
            draft.step = .latestPeriod
        }
    }

    func selectLatestPeriod(_ date: Date) {
        guard let local = localDate(from: date), !isFuture(local) else { return }
        mutate { draft in
            draft.latestPeriodStart = local
            draft.latestPeriodState = .supplied
        }
    }

    func latestPeriodUnknown() {
        mutate { draft in
            draft.latestPeriodStart = nil
            draft.latestPeriodState = .unknown
            draft.currentPeriodAnswer = nil
            draft.currentPeriodState = .skipped
            draft.periodEnd = nil
            draft.periodEndState = .skipped
        }
    }

    func selectCurrentPeriod(_ answer: Prompt14TriState) {
        mutate { draft in
            draft.currentPeriodAnswer = answer
            draft.currentPeriodState = answer == .notSure ? .notSure : .supplied
            if answer != .no {
                draft.periodEnd = nil
                draft.periodEndState = answer == .notSure ? .notSure : .skipped
            }
        }
    }

    func selectPeriodEnd(_ date: Date) {
        guard let local = localDate(from: date), !isFuture(local) else { return }
        guard let start = draft.latestPeriodStart, local >= start else {
            errorMessage = "that’s before the date your period began ♡"
            return
        }
        errorMessage = nil
        mutate { draft in
            draft.periodEnd = local
            draft.periodEndState = .supplied
        }
    }

    func periodEndUnknown() {
        mutate { draft in
            draft.periodEnd = nil
            draft.periodEndState = .unknown
        }
    }

    func setHistoryKnown(_ known: Bool) {
        mutate { draft in
            draft.previousHistoryState = known ? .supplied : .none
            if !known { draft.historicalPeriodStarts = [] }
        }
        historyPickerVisible = known
    }

    func addHistoricalPeriod(_ date: Date) {
        guard let local = localDate(from: date), isValidHistoricalStart(local) else { return }
        mutate { draft in
            if let editing = historyEditingDate,
               let index = draft.historicalPeriodStarts.firstIndex(of: editing) {
                draft.historicalPeriodStarts[index] = local
            } else if !draft.historicalPeriodStarts.contains(local) {
                draft.historicalPeriodStarts.append(local)
            }
            draft.historicalPeriodStarts = Array(Set(draft.historicalPeriodStarts)).sorted(by: >)
            draft.previousHistoryState = .supplied
        }
        historyEditingDate = nil
        historyPickerVisible = false
    }

    func editHistoricalPeriod(_ date: Prompt13LocalDate) {
        historyEditingDate = date
        if let value = systemDate(from: date) { displayedMonth = value }
        historyPickerVisible = true
    }

    func removeHistoricalPeriod(_ date: Prompt13LocalDate) {
        mutate { draft in
            draft.historicalPeriodStarts.removeAll { $0 == date }
        }
    }

    func chooseRegularity(_ value: Prompt14SubjectiveRegularity) {
        mutate { draft in
            draft.subjectiveRegularity = value
            draft.regularityState = value == .dontKnowYet ? .notSure : .supplied
        }
    }

    func toggleCycleContext(_ value: Prompt14CycleAffectingContext) {
        mutate { $0.selectCycleContext(value) }
    }

    func toggleRecentContext(_ value: Prompt14RecentContext) {
        mutate { $0.selectRecentContext(value) }
    }

    func toggleTrackingPreference(_ value: Prompt14TrackingPreference) {
        mutate { $0.toggleTrackingPreference(value) }
    }

    func chooseFertilityPreference(_ value: Prompt14FertilityEstimatePreference) {
        mutate { $0.fertilityPreference = value }
    }

    func chooseBBTTracking(_ value: Prompt14BBTTrackingChoice) {
        mutate { draft in
            draft.bbtTrackingChoice = value
            if value == .notRightNow || value == .skipped {
                draft.bbtUnit = nil
                draft.bbtUsualMeasurementMinutesAfterMidnight = nil
            }
        }
    }

    func chooseBBTUnit(_ value: Prompt14TemperatureUnitPreference) {
        mutate { $0.bbtUnit = value }
    }

    func setBBTTime(_ date: Date?) {
        mutate { draft in
            guard let date else {
                draft.bbtUsualMeasurementMinutesAfterMidnight = nil
                return
            }
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            guard let hour = parts.hour, let minute = parts.minute else { return }
            draft.bbtUsualMeasurementMinutesAfterMidnight = hour * 60 + minute
        }
    }

    func acknowledgeCervicalFluid() {
        mutate { $0.cervicalFluidSetupAcknowledged = true }
        advance()
    }

    func advance() {
        errorMessage = nil
        let next: Prompt14OnboardingStep
        switch draft.step {
        case .intro:
            next = .latestPeriod
        case .latestPeriod:
            guard draft.latestPeriodState != .unanswered else { return }
            next = draft.latestPeriodStart == nil ? .previousHistory : .currentPeriod
        case .currentPeriod:
            guard draft.currentPeriodState != .unanswered else { return }
            next = draft.currentPeriodAnswer == .no ? .periodEnd : .previousHistory
        case .periodEnd:
            guard draft.periodEndState != .unanswered else { return }
            next = .previousHistory
        case .previousHistory:
            guard draft.previousHistoryState != .unanswered else { return }
            next = .subjectiveRegularity
        case .subjectiveRegularity:
            guard draft.regularityState != .unanswered else { return }
            next = .cycleAffectingContext
        case .cycleAffectingContext:
            guard draft.cycleContextState != .unanswered else { return }
            next = .recentContext
        case .recentContext:
            guard draft.recentContextState != .unanswered else { return }
            next = .trackingPreferences
        case .trackingPreferences:
            guard draft.trackingPreferencesState != .unanswered else { return }
            next = .fertilityEstimates
        case .fertilityEstimates:
            guard draft.fertilityPreference != nil else { return }
            if draft.trackingPreferences.contains(.bbt) {
                next = .bbtSetup
            } else if draft.trackingPreferences.contains(.cervicalFluid) {
                next = .cervicalFluidSetup
            } else {
                next = .complete
            }
        case .bbtSetup:
            guard draft.bbtTrackingChoice != nil else { return }
            if let choice = draft.bbtTrackingChoice,
               choice != .notRightNow,
               choice != .skipped,
               draft.bbtUnit == nil { return }
            next = draft.trackingPreferences.contains(.cervicalFluid) ? .cervicalFluidSetup : .complete
        case .cervicalFluidSetup:
            next = .complete
        case .complete:
            return
        }
        mutate { $0.step = next }
    }

    func skipCurrentStep() {
        mutate { draft in
            switch draft.step {
            case .latestPeriod:
                draft.latestPeriodState = .skipped
                draft.latestPeriodStart = nil
                draft.currentPeriodState = .skipped
                draft.periodEndState = .skipped
            case .currentPeriod:
                draft.currentPeriodState = .skipped
                draft.currentPeriodAnswer = nil
                draft.periodEndState = .skipped
            case .periodEnd:
                draft.periodEndState = .skipped
                draft.periodEnd = nil
            case .previousHistory:
                draft.previousHistoryState = .skipped
                draft.historicalPeriodStarts = []
            case .subjectiveRegularity:
                draft.regularityState = .skipped
                draft.subjectiveRegularity = nil
            case .cycleAffectingContext:
                draft.cycleContextState = .skipped
                draft.cycleAffectingContexts = []
            case .recentContext:
                draft.recentContextState = .skipped
                draft.recentContexts = []
            case .trackingPreferences:
                draft.trackingPreferencesState = .skipped
                draft.trackingPreferences = []
            case .fertilityEstimates:
                draft.fertilityPreference = .skipped
            case .bbtSetup:
                draft.bbtTrackingChoice = .skipped
                draft.bbtUnit = nil
                draft.bbtUsualMeasurementMinutesAfterMidnight = nil
            case .cervicalFluidSetup:
                draft.cervicalFluidSetupAcknowledged = false
            case .intro, .complete:
                break
            }
        }
        advance()
    }

    func goBack() -> Bool {
        let previous: Prompt14OnboardingStep?
        switch draft.step {
        case .intro: previous = nil
        case .latestPeriod: previous = .intro
        case .currentPeriod: previous = .latestPeriod
        case .periodEnd: previous = .currentPeriod
        case .previousHistory:
            if draft.latestPeriodStart == nil { previous = .latestPeriod }
            else if draft.currentPeriodAnswer == .no { previous = .periodEnd }
            else { previous = .currentPeriod }
        case .subjectiveRegularity: previous = .previousHistory
        case .cycleAffectingContext: previous = .subjectiveRegularity
        case .recentContext: previous = .cycleAffectingContext
        case .trackingPreferences: previous = .recentContext
        case .fertilityEstimates: previous = .trackingPreferences
        case .bbtSetup: previous = .fertilityEstimates
        case .cervicalFluidSetup:
            previous = draft.trackingPreferences.contains(.bbt) ? .bbtSetup : .fertilityEstimates
        case .complete:
            if draft.trackingPreferences.contains(.cervicalFluid) { previous = .cervicalFluidSetup }
            else if draft.trackingPreferences.contains(.bbt) { previous = .bbtSetup }
            else { previous = .fertilityEstimates }
        }
        guard let previous else { return false }
        mutate { $0.step = previous }
        return true
    }

    func finish() async -> Bool {
        do {
            draft = try await store.complete(calendar: calendar)
            return true
        } catch {
            errorMessage = "your setup is safe, but Fruitfolio couldn’t finish saving it yet ♡"
            return false
        }
    }

    var selectedBBTTime: Date {
        let minutes = draft.bbtUsualMeasurementMinutesAfterMidnight ?? (7 * 60)
        let start = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .minute, value: minutes, to: start) ?? Date()
    }

    func systemDate(from local: Prompt13LocalDate) -> Date? {
        var components = DateComponents()
        components.year = local.year
        components.month = local.month
        components.day = local.day
        components.hour = 12
        return calendar.date(from: components)
    }

    func localDate(from date: Date) -> Prompt13LocalDate? {
        try? Prompt13LocalDate(date, calendar: calendar)
    }

    func isFuture(_ local: Prompt13LocalDate) -> Bool {
        guard let today = try? Prompt13LocalDate(Date(), calendar: calendar) else { return false }
        return local > today
    }

    func isValidHistoricalStart(_ local: Prompt13LocalDate) -> Bool {
        if isFuture(local) { return false }
        if let latest = draft.latestPeriodStart, local >= latest { return false }
        return !draft.historicalPeriodStarts.contains(local) || historyEditingDate == local
    }

    private func mutate(
        _ transform: (inout Prompt14OnboardingDraft) -> Void
    ) {
        var copy = draft
        transform(&copy)
        copy.markUpdated()
        draft = copy
        Task {
            do { try await store.replaceDraft(copy) }
            catch { await MainActor.run { self.errorMessage = "your answer couldn’t be saved right now ♡" } }
        }
    }
}

