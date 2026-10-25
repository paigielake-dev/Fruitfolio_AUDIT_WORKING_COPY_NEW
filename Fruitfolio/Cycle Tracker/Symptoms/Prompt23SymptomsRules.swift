import Foundation

nonisolated enum Prompt23SymptomsRules {
    static func toggled(
        _ symptomID: Prompt20SymptomID,
        in selected: Set<Prompt20SymptomID>
    ) -> Set<Prompt20SymptomID> {
        var copy = selected
        if copy.contains(symptomID) {
            copy.remove(symptomID)
        } else {
            copy.insert(symptomID)
        }
        return copy
    }

    @MainActor
    static func draftPreservingOtherDailyLogFields(
        existingLog: Prompt20DailyLog?,
        selectedSymptoms: Set<Prompt20SymptomID>,
        displayTemperatureUnit: Prompt20TemperatureUnit = .fahrenheit
    ) -> Prompt20DailyLogDraft {
        var draft: Prompt20DailyLogDraft
        if let existingLog {
            draft = Prompt20DailyLogDraft(
                log: existingLog,
                displayTemperatureUnit: displayTemperatureUnit
            )
        } else {
            draft = Prompt20DailyLogDraft()
        }

        draft.selectedSymptoms = selectedSymptoms
        return draft
    }

    static func isValidRecordedSelection(
        _ selected: Set<Prompt20SymptomID>
    ) -> Bool {
        selected.isSubset(of: Prompt23SymptomTaxonomy.selectableIDs)
    }
}
