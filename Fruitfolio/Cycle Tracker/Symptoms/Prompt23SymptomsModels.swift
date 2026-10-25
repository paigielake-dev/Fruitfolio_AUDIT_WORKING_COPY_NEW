import Foundation

nonisolated struct Prompt23SymptomItem: Identifiable, Equatable, Sendable {
    let symptomID: Prompt20SymptomID
    let displayLabel: String
    let assetNames: [String]

    var id: Prompt20SymptomID { symptomID }
}

nonisolated enum Prompt23SymptomTaxonomy {
    /// Phase 23 deliberately reuses Prompt 20's established stable symptom IDs.
    /// It does not create a second symptom schema.
    static let items: [Prompt23SymptomItem] = [
        .init(symptomID: .cramps, displayLabel: "cramps", assetNames: ["symptom_cramps"]),
        .init(symptomID: .bloating, displayLabel: "bloating", assetNames: ["symptom_bloating"]),
        .init(symptomID: .headache, displayLabel: "headache", assetNames: ["symptom_headache"]),
        .init(symptomID: .breastTenderness, displayLabel: "breast tenderness", assetNames: ["symptom_breast_tenderness"]),
        .init(symptomID: .fatigue, displayLabel: "fatigue", assetNames: ["symptom_energy"]),
        .init(symptomID: .moodChanges, displayLabel: "mood changes", assetNames: ["symptom_mood"]),
        .init(symptomID: .skinChanges, displayLabel: "skin changes", assetNames: ["symptom_skin"]),
        .init(symptomID: .brainFog, displayLabel: "brain fog", assetNames: ["symptom_brain_fog"]),
        .init(symptomID: .nausea, displayLabel: "nausea", assetNames: ["symptom_nausea"]),
        .init(symptomID: .lowerBackPain, displayLabel: "lower back pain", assetNames: ["symptom_lower_back_pain"]),
        .init(symptomID: .cravings, displayLabel: "cravings", assetNames: ["symptom_appetite"]),
        .init(symptomID: .hydration, displayLabel: "hydration", assetNames: ["symptom_hydration"]),
        .init(symptomID: .exercise, displayLabel: "exercise", assetNames: ["symptom_exercise"]),
        .init(symptomID: .sleepChanges, displayLabel: "sleep changes", assetNames: ["symptom_sleep"]),
        .init(
            symptomID: .digestiveChanges,
            displayLabel: "digestive changes",
            assetNames: ["symptoms_digestive_changes"]
        )
    ]

    static let selectableIDs = Set(items.map(\.symptomID))
}

nonisolated struct Prompt23SymptomsSnapshot: Equatable, Sendable {
    let activeDate: Date
    let localDay: Prompt20LocalDay
    let selectedIDs: Set<Prompt20SymptomID>
    let existingLog: Prompt20DailyLog?
    let isFutureDate: Bool

    init(
        activeDate: Date,
        localDay: Prompt20LocalDay,
        selectedIDs: Set<Prompt20SymptomID>,
        existingLog: Prompt20DailyLog?,
        isFutureDate: Bool
    ) {
        self.activeDate = activeDate
        self.localDay = localDay
        self.selectedIDs = selectedIDs
        self.existingLog = existingLog
        self.isFutureDate = isFutureDate
    }
}

nonisolated enum Prompt23SaveState: Equatable, Sendable {
    case idle
    case saving
    case saved
    case failed
}
