import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
public final class Prompt20DailyLogViewModel {
    public enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed
    }

    public enum SaveState: Equatable {
        case idle
        case saving
        case saved
        case failed
    }

    #if canImport(Combine)
    @Published
    #endif
    public private(set) var loadState: LoadState = .idle
    #if canImport(Combine)
    @Published
    #endif
    public private(set) var saveState: SaveState = .idle
    #if canImport(Combine)
    @Published
    #endif
    public var draft: Prompt20DailyLogDraft
    #if canImport(Combine)
    @Published
    #endif
    public var expandedSections: Set<Prompt20DailyLogSection> = []
    #if canImport(Combine)
    @Published
    #endif
    public private(set) var validationIssues: [Prompt20DailyLogValidationIssue] = []
    #if canImport(Combine)
    @Published
    #endif
    public private(set) var existingLog: Prompt20DailyLog?
    #if canImport(Combine)
    @Published
    #endif
    public private(set) var hasUnsavedChanges = false

    #if canImport(Combine)
    @Published
    #endif
    public private(set) var loadFailureMessage: String?
    #if canImport(Combine)
    @Published
    #endif
    public private(set) var saveFailureMessage: String?

    public let ownerID: Prompt20DailyLogOwnerID
    public let selectedDate: Date
    public let selectedDay: Prompt20LocalDay
    public let calendar: Calendar

    private let repository: any Prompt20DailyLogRepository
    private let nowProvider: @Sendable () -> Date
    private let initialExpandedSection: Prompt20DailyLogSection?
    private var baselineDraft: Prompt20DailyLogDraft
    private var pendingWrite: Prompt20DailyLogWrite?

    public init(
        ownerID: Prompt20DailyLogOwnerID,
        selectedDate: Date,
        repository: (any Prompt20DailyLogRepository)? = nil,
        calendar: Calendar = .current,
        preferredTemperatureUnit: Prompt20TemperatureUnit = .fahrenheit,
        initialExpandedSection: Prompt20DailyLogSection? = nil,
        nowProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.ownerID = ownerID
        self.selectedDate = selectedDate
        self.calendar = calendar
        self.selectedDay = Prompt20LocalDay(
            date: selectedDate,
            calendar: calendar
        )
        self.repository =
            repository ?? Prompt20CycleDailyLogStore.shared
        self.nowProvider = nowProvider
        self.initialExpandedSection = initialExpandedSection

        var initialDraft = Prompt20DailyLogDraft()
        initialDraft.temperatureUnit = preferredTemperatureUnit
        self.draft = initialDraft
        self.baselineDraft = initialDraft
    }

    public var isFutureDate: Bool {
        Prompt20DailyLogRules.isFuture(
            selectedDay,
            relativeTo: nowProvider(),
            calendar: calendar
        )
    }

    public var isToday: Bool {
        selectedDay == Prompt20LocalDay(
            date: nowProvider(),
            calendar: calendar
        )
    }

    public var saveButtonTitle: String {
        isToday ? "save today’s log" : "save log"
    }

    public var canSave: Bool {
        loadState == .loaded &&
        saveState != .saving &&
        !isFutureDate &&
        (draft.hasAnyContent || existingLog != nil) &&
        Prompt20DailyLogRules.validate(draft).isValid
    }

    public func load() async {
        guard loadState != .loading, loadState != .loaded else {
            return
        }

        loadState = .loading
        loadFailureMessage = nil
        // Cancellation must leave the same view model reloadable on reappearance.
        defer { if loadState == .loading { loadState = .idle } }
        saveState = .idle
        validationIssues = []

        do {
            let log = try await repository.load(
                ownerID: ownerID,
                date: selectedDay
            )

            guard !Task.isCancelled else {
                return
            }

            existingLog = log

            if let log {
                let loadedDraft = Prompt20DailyLogDraft(
                    log: log,
                    displayTemperatureUnit: draft.temperatureUnit
                )

                draft = loadedDraft
                baselineDraft = loadedDraft

                // Existing content is restored immediately, but the journal stays
                // visually quiet. Saved values remain visible through the collapsed
                // summaries, and only an explicitly requested deep-link section opens.
                expandedSections =
                    initialExpandedSection.map { [$0] } ?? []
            } else {
                baselineDraft = draft
                expandedSections =
                    initialExpandedSection.map { [$0] } ?? []
            }

            hasUnsavedChanges = false
            loadState = .loaded
        } catch {
            guard !Task.isCancelled else {
                return
            }

            loadFailureMessage = persistenceMessage(error)
            loadState = .failed
        }
    }

    /// Only an initial failed load can reload its saved reference. A loaded
    /// editor's draft is never replaced by a retry/recovery action.
    public func retryLoad() async {
        guard loadState == .failed, !hasUnsavedChanges else { return }
        loadState = .loading
        loadFailureMessage = nil
        defer { if loadState == .loading { loadState = .idle } }
        do {
            if let reloadable = repository as? any Prompt20ReloadableDailyLogRepository {
                try await reloadable.reloadSavedLogs()
            }
            guard !Task.isCancelled else { return }
            loadState = .idle
            await load()
        } catch {
            guard !Task.isCancelled else { return }
            loadFailureMessage = persistenceMessage(error)
            loadState = .failed
        }
    }

    private func persistenceMessage(_ error: Error) -> String {
        (error as? Prompt20DailyLogDomainError)?.errorDescription
            ?? "saved logs could not be accessed. please try again."
    }

    public func setExpanded(
        _ section: Prompt20DailyLogSection,
        expanded: Bool
    ) {
        if expanded {
            expandedSections.insert(section)
        } else {
            expandedSections.remove(section)
        }
    }

    public func toggle(
        _ section: Prompt20DailyLogSection
    ) {
        if expandedSections.contains(section) {
            expandedSections.remove(section)
        } else {
            expandedSections.insert(section)
        }
    }

    public func mutateDraft(
        _ change: (inout Prompt20DailyLogDraft) -> Void
    ) {
        change(&draft)

        validationIssues =
            Prompt20DailyLogRules.validate(draft).issues

        hasUnsavedChanges =
            draft != baselineDraft

        if saveState == .saved ||
            saveState == .failed {
            saveFailureMessage = nil
            saveState = .idle
        }
    }

    public func toggleSymptom(
        _ symptom: Prompt20SymptomID
    ) {
        mutateDraft { draft in
            if draft.selectedSymptoms.contains(symptom) {
                draft.selectedSymptoms.remove(symptom)
            } else {
                draft.selectedSymptoms.insert(symptom)
            }
        }
    }

    public func addMedication() {
        mutateDraft { draft in
            draft.medications.append(
                Prompt20MedicationEntry()
            )
        }
    }

    public func removeMedication(
        id: UUID
    ) {
        mutateDraft { draft in
            draft.medications.removeAll {
                $0.id == id
            }
        }
    }

    public func updateMedication(
        id: UUID,
        change: (inout Prompt20MedicationEntry) -> Void
    ) {
        mutateDraft { draft in
            guard let index =
                draft.medications.firstIndex(
                    where: {
                        $0.id == id
                    }
                )
            else {
                return
            }

            change(
                &draft.medications[index]
            )
        }
    }

    public func changeTemperatureUnit(
        to newUnit: Prompt20TemperatureUnit
    ) {
        guard newUnit != draft.temperatureUnit else {
            return
        }

        mutateDraft { draft in
            // This chooses the unit reported by the thermometer. Conversion
            // helpers remain available for read-only displays, never this edit.
            draft.temperatureUnit = newUnit
        }
    }

    @discardableResult
    public func save() async -> Bool {
        guard loadState == .loaded else {
            return false
        }

        guard saveState != .saving else {
            return false
        }

        saveFailureMessage = nil
        guard !isFutureDate else {
            saveState = .failed
            return false
        }

        let validation =
            Prompt20DailyLogRules.validate(
                draft
            )

        validationIssues =
            validation.issues

        guard validation.isValid else {
            saveState = .failed
            return false
        }

        saveState = .saving

        let write = Prompt20DailyLogWrite.begin(draft: draft, retrying: pendingWrite)
        pendingWrite = write
        defer { if saveState == .saving { saveState = .idle } }

        do {
            let saved =
                try await repository.save(
                    ownerID: ownerID,
                    date: selectedDay,
                    draft: write.draft,
                    now: nowProvider(),
                    requestID: write.id
                )

            // Storage may have committed even if the presentation was cancelled.
            // Reconcile the exact written snapshot, preserving subsequent edits.
            existingLog = saved
            baselineDraft = write.draft
            hasUnsavedChanges = write.hasLaterEdits(draft)
            pendingWrite = nil
            saveState = hasUnsavedChanges ? .idle : .saved

            return !Task.isCancelled
        } catch let error
            as Prompt20DailyLogDomainError {

            guard !Task.isCancelled else {
                return false
            }

            if case .validation(
                let issues
            ) = error {
                validationIssues =
                    issues
            }

            saveFailureMessage = persistenceMessage(error)
            saveState = .failed
            return false
        } catch {
            guard !Task.isCancelled else {
                return false
            }

            saveFailureMessage = persistenceMessage(error)
            saveState = .failed
            return false
        }
    }

    public func retrySave() async -> Bool {
        await save()
    }

    public func validationMessage(
        for issue:
            Prompt20DailyLogValidationIssue
    ) -> String {
        switch issue {
        case .invalidDate: return "choose a valid calendar date before saving."
        case .bleedingLevelRequiredForNote:
            return "choose the bleeding option that goes with this note"

        case .invalidTemperatureFormat:
            return "enter the temperature as a number"

        case .implausibleTemperature:
            return "that number looks like a typo — check the temperature and try again"

        case .temperatureValueRequired:
            return "add the temperature value for this reading"

        case .cervicalCategoryRequiredForNote:
            return "choose the cervical fluid option that goes with this note"

        case .medicationNameRequired:
            return "add a name for this medication or supplement"
        }
    }
}

#if canImport(Combine)
extension Prompt20DailyLogViewModel: ObservableObject {}
#endif
