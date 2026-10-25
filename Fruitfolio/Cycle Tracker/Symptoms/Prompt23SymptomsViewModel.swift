import Foundation
import Combine

@MainActor
final class Prompt23SymptomsViewModel: ObservableObject {
    @Published private(set) var selectedIDs: Set<Prompt20SymptomID> = []
    @Published private(set) var isLoading = true
    @Published private(set) var saveState: Prompt23SaveState = .idle
    @Published private(set) var isFutureDate = false

    let activeDate: Date

    private let repository: any Prompt20DailyLogRepository
    private let ownerID: Prompt20DailyLogOwnerID
    private let calendar: Calendar
    private var existingLog: Prompt20DailyLog?
    private var originalSelectedIDs: Set<Prompt20SymptomID> = []
    private var loaded = false

    var hasUnsavedChanges: Bool {
        selectedIDs != originalSelectedIDs
    }

    var canSave: Bool {
        !isLoading && !isFutureDate && saveState != .saving && hasUnsavedChanges
    }

    init(
        activeDate: Date,
        repository: (any Prompt20DailyLogRepository)? = nil,
        ownerID: Prompt20DailyLogOwnerID? = nil,
        calendar: Calendar = .current
    ) {
        self.activeDate = activeDate
        self.repository = repository ?? Prompt20CycleDailyLogStore.shared
        self.ownerID = ownerID ?? .localDevice
        self.calendar = calendar
    }

    func loadIfNeeded(now: Date = Date()) async {
        guard !loaded else { return }
        loaded = true
        isLoading = true

        let localDay = Prompt20LocalDay(date: activeDate, calendar: calendar)
        isFutureDate = Prompt20DailyLogRules.isFuture(
            localDay,
            relativeTo: now,
            calendar: calendar
        )

        do {
            let log = try await repository.load(ownerID: ownerID, date: localDay)
            existingLog = log
            let restored = log?.symptoms?.selectedIDs ?? []
            selectedIDs = restored.intersection(Prompt23SymptomTaxonomy.selectableIDs)
            originalSelectedIDs = selectedIDs
            saveState = .idle
        } catch {
            // Loading failure must not masquerade as a valid empty day.
            saveState = .failed
        }

        isLoading = false
    }

    func toggle(_ symptomID: Prompt20SymptomID) {
        guard !isLoading, !isFutureDate, saveState != .saving else { return }
        guard Prompt23SymptomTaxonomy.selectableIDs.contains(symptomID) else { return }

        selectedIDs = Prompt23SymptomsRules.toggled(symptomID, in: selectedIDs)
        if saveState == .saved || saveState == .failed {
            saveState = .idle
        }
    }

    func save(now: Date = Date()) async -> Bool {
        guard canSave else { return false }
        guard Prompt23SymptomsRules.isValidRecordedSelection(selectedIDs) else {
            saveState = .failed
            return false
        }

        saveState = .saving
        let localDay = Prompt20LocalDay(date: activeDate, calendar: calendar)
        let draft = Prompt23SymptomsRules.draftPreservingOtherDailyLogFields(
            existingLog: existingLog,
            selectedSymptoms: selectedIDs
        )

        do {
            let saved = try await repository.save(
                ownerID: ownerID,
                date: localDay,
                draft: draft,
                now: now,
                requestID: UUID()
            )
            existingLog = saved
            originalSelectedIDs = selectedIDs
            saveState = .saved
            return true
        } catch {
            saveState = .failed
            return false
        }
    }
}
