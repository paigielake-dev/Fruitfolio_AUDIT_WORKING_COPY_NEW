import Foundation
import Combine
import SwiftUI

@MainActor
public final class Prompt20DailyLogViewModel: ObservableObject {
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

    @Published public private(set) var loadState: LoadState = .idle
    @Published public private(set) var saveState: SaveState = .idle
    @Published public var draft: Prompt20DailyLogDraft
    @Published public var expandedSections: Set<Prompt20DailyLogSection> = []
    @Published public private(set) var validationIssues: [Prompt20DailyLogValidationIssue] = []
    @Published public private(set) var existingLog: Prompt20DailyLog?
    @Published public private(set) var hasUnsavedChanges = false

    public let ownerID: Prompt20DailyLogOwnerID
    public let selectedDate: Date
    public let selectedDay: Prompt20LocalDay
    public let calendar: Calendar

    private let repository: any Prompt20DailyLogRepository
    private let nowProvider: @Sendable () -> Date
    private let initialExpandedSection: Prompt20DailyLogSection?
    private var baselineDraft: Prompt20DailyLogDraft
    private var activeSaveRequestID: UUID?

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
        guard loadState != .loading else {
            return
        }

        loadState = .loading
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

            loadState = .failed
        }
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
            let trimmed =
                draft.temperatureText
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

            if let value = Double(
                trimmed.replacingOccurrences(
                    of: ",",
                    with: "."
                )
            ) {
                let celsius: Double

                switch draft.temperatureUnit {
                case .celsius:
                    celsius = value

                case .fahrenheit:
                    celsius =
                        (value - 32.0) *
                        5.0 /
                        9.0
                }

                let converted: Double

                switch newUnit {
                case .celsius:
                    converted = celsius

                case .fahrenheit:
                    converted =
                        celsius *
                        9.0 /
                        5.0 +
                        32.0
                }

                draft.temperatureText =
                    Prompt20TemperatureFormatter.string(
                        converted,
                        unit: newUnit
                    )
            }

            draft.temperatureUnit =
                newUnit
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

        let requestID =
            activeSaveRequestID ?? UUID()

        activeSaveRequestID =
            requestID

        do {
            let saved =
                try await repository.save(
                    ownerID: ownerID,
                    date: selectedDay,
                    draft: draft,
                    now: nowProvider(),
                    requestID: requestID
                )

            guard !Task.isCancelled else {
                return false
            }

            existingLog = saved
            baselineDraft = draft
            hasUnsavedChanges = false
            activeSaveRequestID = nil
            saveState = .saved

            return true
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

            saveState = .failed
            return false
        } catch {
            guard !Task.isCancelled else {
                return false
            }

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
        case .bleedingLevelRequiredForNote:
            "choose the bleeding option that goes with this note"

        case .invalidTemperatureFormat:
            "enter the temperature as a number"

        case .implausibleTemperature:
            "that number looks like a typo — check the temperature and try again"

        case .temperatureValueRequired:
            "add the temperature value for this reading"

        case .cervicalCategoryRequiredForNote:
            "choose the cervical fluid option that goes with this note"

        case .medicationNameRequired:
            "add a name for this medication or supplement"
        }
    }
}
