import XCTest
@testable import Fruitfolio

final class Prompt23CoreTests: XCTestCase {
    func testTaxonomyUsesEveryEstablishedPrompt20SymptomIDExactlyOnce() {
        let ids = Prompt23SymptomTaxonomy.items.map(\.symptomID)
        XCTAssertEqual(Set(ids), Set(Prompt20SymptomID.allCases))
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testStableCanonicalOrder() {
        XCTAssertEqual(
            Prompt23SymptomTaxonomy.items.map(\.symptomID),
            [
                .cramps, .bloating, .headache, .breastTenderness,
                .fatigue, .moodChanges, .skinChanges, .brainFog, .nausea,
                .lowerBackPain, .cravings, .hydration, .exercise,
                .sleepChanges, .digestiveChanges
            ]
        )
    }

    func testDigestiveChangesUsesDedicatedFounderArtwork() {
        let item = Prompt23SymptomTaxonomy.items.first { $0.symptomID == .digestiveChanges }
        XCTAssertEqual(
            item?.assetNames,
            ["symptoms_digestive_changes"]
        )
    }

    func testMappedArtworkUsesCanonicalPhysicalStems() {
        let mapped = Set(Prompt23SymptomTaxonomy.items.flatMap(\.assetNames))
        XCTAssertEqual(
            mapped,
            Set([
                "symptom_cramps", "symptom_bloating", "symptom_headache",
                "symptom_breast_tenderness", "symptom_energy", "symptom_mood",
                "symptom_skin", "symptom_brain_fog", "symptom_nausea",
                "symptom_lower_back_pain", "symptom_appetite", "symptom_hydration",
                "symptom_exercise", "symptom_sleep", "symptoms_digestive_changes"
            ])
        )
    }

    func testToggleIsTrueMultiSelect() {
        var selected: Set<Prompt20SymptomID> = []
        selected = Prompt23SymptomsRules.toggled(.cramps, in: selected)
        selected = Prompt23SymptomsRules.toggled(.headache, in: selected)
        XCTAssertEqual(selected, [.cramps, .headache])

        selected = Prompt23SymptomsRules.toggled(.cramps, in: selected)
        XCTAssertEqual(selected, [.headache])
    }

    func testEmptySelectionIsValid() {
        XCTAssertTrue(Prompt23SymptomsRules.isValidRecordedSelection([]))
    }

    @MainActor
    func testDraftPreservesOtherDailyLogFields() {
        let owner = Prompt20DailyLogOwnerID(rawValue: "test")
        let day = Prompt20LocalDay(year: 2026, month: 9, day: 8)
        let existing = Prompt20DailyLog(
            ownerID: owner,
            date: day,
            bleeding: Prompt20BleedingObservation(level: .light),
            symptoms: Prompt20SymptomObservation(selectedIDs: [.cramps], note: "keep note"),
            temperature: Prompt20TemperatureObservation(originalValue: 98.1, originalUnit: .fahrenheit),
            cervicalFluid: Prompt20CervicalFluidObservation(category: .creamy),
            generalNote: Prompt20GeneralNote(text: "keep general note")
        )

        let draft = Prompt23SymptomsRules.draftPreservingOtherDailyLogFields(
            existingLog: existing,
            selectedSymptoms: [.headache]
        )

        XCTAssertEqual(draft.bleedingLevel, .light)
        XCTAssertEqual(draft.selectedSymptoms, [.headache])
        XCTAssertEqual(draft.symptomNote, "keep note")
        XCTAssertFalse(draft.temperatureText.isEmpty)
        XCTAssertEqual(draft.cervicalFluidCategory, .creamy)
        XCTAssertEqual(draft.generalNote, "keep general note")
    }
}

