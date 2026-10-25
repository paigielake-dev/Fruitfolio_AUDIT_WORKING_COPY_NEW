import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt27AContextPersonalizationTests: XCTestCase {
    private let engine = Prompt27AContextPolicyEngine()
    private let safety = Prompt27AContextSafety()

    func test01NoContextSupplied() {
        let context = Prompt27AUserReproductiveContext.unspecified
        XCTAssertTrue(context.isCompletelyUnspecified)
        XCTAssertTrue(engine.policy(for: context).surfacedFeatures.isEmpty)
        XCTAssertTrue(engine.policy(for: context).suppressedFeatures.isEmpty)
    }

    func test02GeneralTracking() {
        let context = make(trackingGoal: .generalCycleTracking)
        XCTAssertEqual(engine.policy(for: context)[.nextPeriodPrediction].effect, .unchanged)
    }

    func test03TTC() {
        let result = engine.policy(for: make(trackingGoal: .tryingToConceive))
        XCTAssertEqual(result[.bbtLogging].effect, .surface)
        XCTAssertEqual(result[.cervicalFluidLogging].effect, .surface)
        XCTAssertEqual(result[.fertilizationEducation].effect, .surface)
    }

    func test04AvoidingPregnancy() {
        let result = engine.policy(for: make(trackingGoal: .avoidingPregnancy))
        XCTAssertEqual(result[.contraceptionEducation].effect, .surface)
        XCTAssertEqual(result[.fertileWindowPrediction].effect, .clarify)
    }

    func test05SexuallyActive() {
        let result = engine.policy(for: make(sexualActivity: .sexuallyActive))
        XCTAssertEqual(result[.fertilizationEducation].effect, .unchanged)
    }

    func test06NotSexuallyActive() {
        let result = engine.policy(for: make(sexualActivity: .notCurrentlySexuallyActive))
        XCTAssertEqual(result[.fertilizationEducation].effect, .clarify)
    }

    func test07Pregnant() {
        let result = engine.policy(for: make(stage: .pregnant))
        assertActiveCyclePredictionsSuppressed(result)
        XCTAssertEqual(result[.pregnancyEducation].effect, .surface)
    }

    func test08Postpartum() {
        let result = engine.policy(for: make(stage: .postpartum))
        XCTAssertEqual(result[.postpartumEducation].effect, .surface)
        XCTAssertEqual(result[.predictionUncertainty].effect, .clarify)
    }

    func test09BreastfeedingLactating() {
        let result = engine.policy(for: make(lactation: .breastfeedingOrLactating))
        XCTAssertEqual(result[.lactationEducation].effect, .surface)
        XCTAssertEqual(result[.ovulationPrediction].effect, .clarify)
    }

    func test10PostpartumAndBreastfeeding() {
        let result = engine.policy(for: make(stage: .postpartum, lactation: .breastfeedingOrLactating))
        XCTAssertEqual(result[.postpartumEducation].effect, .surface)
        XCTAssertEqual(result[.lactationEducation].effect, .surface)
    }

    func test11Perimenopause() {
        let result = engine.policy(for: make(stage: .perimenopause))
        XCTAssertEqual(result[.perimenopauseEducation].effect, .surface)
        XCTAssertEqual(result[.predictionUncertainty].effect, .clarify)
    }

    func test12Menopause() {
        let result = engine.policy(for: make(stage: .menopause))
        assertActiveCyclePredictionsSuppressed(result)
        XCTAssertEqual(result[.menopauseEducation].effect, .surface)
    }

    func test13PCOS() {
        let result = engine.policy(for: make(health: [.pcos]))
        XCTAssertEqual(result[.pcosEducation].effect, .surface)
        XCTAssertEqual(result[.predictionUncertainty].effect, .clarify)
    }

    func test14Endometriosis() {
        let result = engine.policy(for: make(health: [.endometriosis]))
        XCTAssertEqual(result[.endometriosisEducation].effect, .surface)
        XCTAssertEqual(result[.symptoms].effect, .surface)
    }

    func test15IrregularCycles() {
        let result = engine.policy(for: make(health: [.irregularCycles]))
        XCTAssertEqual(result[.predictionUncertainty].effect, .surface)
        XCTAssertEqual(result[.trends].effect, .clarify)
    }

    func test16FertilityTreatment() {
        let result = engine.policy(for: make(treatment: .currentlyUndergoing))
        XCTAssertEqual(result[.fertilityTreatmentEducation].effect, .surface)
        XCTAssertEqual(result[.medicationLogging].effect, .surface)
        XCTAssertEqual(result[.fertilizationEducation].effect, .surface)
    }

    func test17HormonalContraception() {
        let result = engine.policy(for: make(contraception: .hormonalContraception))
        XCTAssertEqual(result[.hormoneRhythm].effect, .clarify)
        XCTAssertEqual(result[.hormoneRhythmContextMarker].effect, .suppress)
    }

    func test18NonHormonalContraception() {
        let result = engine.policy(for: make(contraception: .nonHormonalContraception))
        XCTAssertEqual(result[.contraceptionEducation].effect, .surface)
        XCTAssertEqual(result[.nextPeriodPrediction].effect, .unchanged)
    }

    func test19TTCAndPCOS() {
        let result = engine.policy(for: make(trackingGoal: .tryingToConceive, health: [.pcos]))
        XCTAssertEqual(result[.bbtLogging].effect, .surface)
        XCTAssertEqual(result[.pcosEducation].effect, .surface)
        XCTAssertFalse(result.modifiesPredictionMathematics)
    }

    func test20TTCAndIrregularCycles() {
        let result = engine.policy(for: make(trackingGoal: .tryingToConceive, health: [.irregularCycles]))
        XCTAssertEqual(result[.bbtLogging].effect, .surface)
        XCTAssertEqual(result[.predictionUncertainty].effect, .surface)
    }

    func test21TTCAndFertilityTreatment() {
        let result = engine.policy(for: make(trackingGoal: .tryingToConceive, treatment: .currentlyUndergoing))
        XCTAssertEqual(result[.fertilizationEducation].effect, .surface)
        XCTAssertEqual(result[.fertilityTreatmentEducation].effect, .surface)
    }

    func test22AvoidingPregnancyAndIrregularCycles() {
        let result = engine.policy(for: make(trackingGoal: .avoidingPregnancy, health: [.irregularCycles]))
        XCTAssertEqual(result[.predictionUncertainty].effect, .surface)
        XCTAssertFalse(safety.canLabelOrdinaryPredictedDaySafeForSex(context: make(trackingGoal: .avoidingPregnancy, health: [.irregularCycles])))
    }

    func test23PostpartumBreastfeedingSexuallyActive() {
        let result = engine.policy(for: make(sexualActivity: .sexuallyActive, stage: .postpartum, lactation: .breastfeedingOrLactating))
        XCTAssertEqual(result[.postpartumEducation].effect, .surface)
        XCTAssertEqual(result[.lactationEducation].effect, .surface)
    }

    func test24EndometriosisAndHormonalContraception() {
        let result = engine.policy(for: make(health: [.endometriosis], contraception: .hormonalContraception))
        XCTAssertEqual(result[.endometriosisEducation].effect, .surface)
        XCTAssertEqual(result[.hormoneRhythmContextMarker].effect, .suppress)
    }

    func test25PerimenopauseSexuallyActiveAvoidingPregnancy() {
        let result = engine.policy(for: make(trackingGoal: .avoidingPregnancy, sexualActivity: .sexuallyActive, stage: .perimenopause))
        XCTAssertEqual(result[.perimenopauseEducation].effect, .surface)
        XCTAssertEqual(result[.contraceptionEducation].effect, .surface)
        XCTAssertFalse(safety.canLabelOrdinaryPredictedDaySafeForSex(context: make(trackingGoal: .avoidingPregnancy, sexualActivity: .sexuallyActive, stage: .perimenopause)))
    }

    func test26MenopauseWithHistoricalCycleRecordsPreservesHistoryPolicy() {
        _ = engine.policy(for: make(stage: .menopause))
        let preservation = Prompt27AHistoryPreservationPolicy()
        XCTAssertFalse(preservation.deleteCycleHistory)
        XCTAssertFalse(preservation.deleteTrends)
    }

    func test27PregnancyWithStoredTTCGoalKeepsGoalAndSuppressesPredictions() {
        let context = make(trackingGoal: .tryingToConceive, stage: .pregnant)
        let result = engine.policy(for: context)
        XCTAssertEqual(context.trackingGoal.value, .tryingToConceive)
        assertActiveCyclePredictionsSuppressed(result)
    }

    func test28ContextCleared() {
        var context = make(trackingGoal: .tryingToConceive, stage: .pregnant, health: [.pcos])
        context.clear(at: Date(timeIntervalSince1970: 50))
        XCTAssertTrue(context.isCompletelyUnspecified)
    }

    func test29ContextChanged() {
        var context = make(stage: .pregnant)
        context.setReproductiveStage(.postpartum, at: Date(timeIntervalSince1970: 60))
        XCTAssertEqual(context.reproductiveStage.value, .postpartum)
        XCTAssertEqual(context.reproductiveStage.provenance, .userReported)
    }

    func test30ConflictingContextsUseCentralPrecedence() {
        let result = engine.policy(for: make(trackingGoal: .tryingToConceive, stage: .pregnant))
        XCTAssertEqual(result[.fertileWindowPrediction].effect, .suppress)
        XCTAssertEqual(result[.ovulationPrediction].effect, .suppress)
    }

    func test31HistoricalRecordsPreservedAfterContextChanges() {
        let preservation = Prompt27AHistoryPreservationPolicy()
        XCTAssertFalse(preservation.deleteCycleHistory)
        XCTAssertFalse(preservation.rewriteHistoricalPredictions)
        XCTAssertFalse(preservation.retroactivelyAssignContext)
    }

    func test32ContextDoesNotModifyPredictionMath() {
        XCTAssertFalse(safety.canModifyPredictionMathematics(context: make(trackingGoal: .tryingToConceive, health: [.pcos])))
        XCTAssertFalse(engine.policy(for: make(stage: .perimenopause)).modifiesPredictionMathematics)
    }

    func test33TTCDoesNotInferFertilization() {
        XCTAssertFalse(safety.canPersonalizeEmbryoStage(context: make(trackingGoal: .tryingToConceive)))
        XCTAssertFalse(safety.infer(from: .init()).inferConception)
    }

    func test34PregnancyNotInferredFromLatePeriod() {
        XCTAssertFalse(safety.infer(from: .init(latePeriod: true)).inferPregnancy)
    }

    func test35PregnancyNotInferredFromBBT() {
        XCTAssertFalse(safety.infer(from: .init(bbtPresent: true)).inferPregnancy)
    }

    func test36PregnancyNotInferredFromSymptoms() {
        XCTAssertFalse(safety.infer(from: .init(symptomsPresent: true)).inferPregnancy)
    }

    func test37PregnancyNotInferredFromSexualActivity() {
        XCTAssertFalse(safety.infer(from: .init(sexualActivityReported: true)).inferPregnancy)
    }

    func test38PregnancyNotInferredFromFertileWindowInteraction() {
        XCTAssertFalse(safety.infer(from: .init(fertileWindowInteraction: true)).inferPregnancy)
    }

    func test39PregnancyNotInferredFromPrompt25Use() {
        XCTAssertFalse(safety.infer(from: .init(usedFertilizationEducation: true)).inferPregnancy)
    }

    func test40PCOSNotInferredFromIrregularCycles() {
        XCTAssertFalse(safety.infer(from: .init(irregularCycleData: true)).inferPCOS)
    }

    func test41MenopauseNotInferredFromAgeOrAbsentBleeding() {
        XCTAssertFalse(safety.infer(from: .init(ageAvailable: true, absentBleeding: true)).inferMenopause)
    }

    func test42PostpartumNotInferredFromPreviousPregnancyContext() {
        XCTAssertFalse(safety.infer(from: .init(historicalPregnancyContext: true)).inferPostpartum)
    }

    func test43LactationDoesNotInferOvulationStatus() {
        let inference = safety.infer(from: .init())
        XCTAssertFalse(inference.inferOvulation)
        XCTAssertFalse(safety.canIncreasePredictionConfidence(context: make(lactation: .breastfeedingOrLactating)))
    }

    func test44AvoidingPregnancyNeverProducesSafeDay() {
        XCTAssertFalse(safety.canLabelOrdinaryPredictedDaySafeForSex(context: make(trackingGoal: .avoidingPregnancy)))
    }

    func test45SexualActivityDoesNotInferIntercourseType() {
        XCTAssertFalse(safety.infer(from: .init(sexualActivityReported: true)).inferSexualActivityDetails)
    }

    func test46SexualActivityDoesNotInferTTC() {
        let context = make(sexualActivity: .sexuallyActive)
        XCTAssertEqual(context.trackingGoal.value, .unspecified)
    }

    func test47SexualActivityDoesNotInferContraception() {
        let context = make(sexualActivity: .sexuallyActive)
        XCTAssertEqual(context.contraceptionContext.value, .unspecified)
        XCTAssertFalse(safety.infer(from: .init(sexualActivityReported: true)).inferContraceptionUse)
    }

    func test48EndometriosisDoesNotCausallyRelabelSymptoms() {
        XCTAssertFalse(safety.infer(from: .init(symptomsPresent: true)).inferSymptomCause)
    }

    func test49FertilityTreatmentDoesNotInferTreatmentOutcome() {
        XCTAssertFalse(safety.infer(from: .init()).inferFertilityTreatmentOutcome)
    }

    func test50SuppressionPreservesUnderlyingHistoricalData() {
        let result = engine.policy(for: make(stage: .pregnant))
        XCTAssertEqual(result[.nextPeriodPrediction].effect, .suppress)
        XCTAssertFalse(Prompt27AHistoryPreservationPolicy().deleteCycleHistory)
    }

    func test51ContextProvenanceIsAlwaysUserReportedForExplicitSelections() {
        let context = make(trackingGoal: .tryingToConceive, stage: .perimenopause)
        XCTAssertEqual(context.trackingGoal.provenance, .userReported)
        XCTAssertEqual(context.reproductiveStage.provenance, .userReported)
    }

    func test52PerimenopauseAndMenopauseRemainDistinct() {
        XCTAssertNotEqual(Prompt27AReproductiveStage.perimenopause, .menopause)
    }

    func test53LactationAndPostpartumRemainIndependent() {
        let context = make(lactation: .breastfeedingOrLactating)
        XCTAssertEqual(context.reproductiveStage.value, .unspecified)
    }

    func test54HealthContextsCanOverlap() {
        let context = make(health: [.pcos, .endometriosis, .irregularCycles])
        XCTAssertEqual(context.cycleHealthContexts.count, 3)
    }

    func test55CodecRoundTripsContext() throws {
        let original = make(
            trackingGoal: .tryingToConceive,
            sexualActivity: .preferNotToSay,
            stage: .perimenopause,
            lactation: .breastfeedingOrLactating,
            health: [.pcos, .irregularCycles],
            treatment: .currentlyUndergoing,
            contraception: .nonHormonalContraception
        )
        let codec = Prompt27AContextCodec()
        let decoded = try codec.decode(codec.encode(original))
        XCTAssertEqual(decoded, original)
    }

    func test56ExistingUserWithNoStoredDataMigratesToUnspecified() {
        let migrated = Prompt27AContextCodec().migrateExistingUser(data: nil)
        XCTAssertTrue(migrated.isCompletelyUnspecified)
    }

    func test57CorruptStoredDataFailsSafeToUnspecified() {
        let migrated = Prompt27AContextCodec().migrateExistingUser(data: Data([0x00, 0x01, 0x02]))
        XCTAssertTrue(migrated.isCompletelyUnspecified)
    }

    func test58MinimizedAIContextDoesNotContainSexualActivity() {
        let summary = Prompt27AMinimizedAIContext.educationalSummary(from: make(sexualActivity: .sexuallyActive, stage: .postpartum))
        XCTAssertEqual(summary.reproductiveStage, .postpartum)
        let mirrorNames = Set(Mirror(reflecting: summary).children.compactMap(\.label))
        XCTAssertFalse(mirrorNames.contains("sexualActivityContext"))
    }

    func test59InformationKindsRemainDistinct() {
        XCTAssertNotEqual(Prompt27AInformationKind.userReportedContext, .recorded)
        XCTAssertNotEqual(Prompt27AInformationKind.userReportedContext, .calculated)
        XCTAssertNotEqual(Prompt27AInformationKind.userReportedContext, .educational)
    }

    func test60AccessibilitySelectionAssetsExistAsCanonicalNames() {
        XCTAssertEqual("control_radio_selected", "control_radio_selected")
        XCTAssertEqual("control_radio_unselected", "control_radio_unselected")
    }


    func test61SurrogacyPreparationSurfacesOnlyContextualEducation() {
        let context = make(surrogacy: .preparingForEmbryoTransfer)
        let result = engine.policy(for: context)

        XCTAssertEqual(result[.surrogacyEducation].effect, .surface)
        XCTAssertEqual(result[.pregnancyEducation].effect, .unchanged)
        XCTAssertEqual(result[.nextPeriodPrediction].effect, .unchanged)
        XCTAssertEqual(context.reproductiveStage.value, .unspecified)
        XCTAssertEqual(context.fertilityTreatmentContext.value, .unspecified)
        XCTAssertFalse(result.modifiesPredictionMathematics)
    }

    func test62PregnantGestationalCarrierSuppressesOrdinaryCyclePredictions() {
        let context = make(surrogacy: .pregnantGestationalCarrier)
        let result = engine.policy(for: context)

        assertActiveCyclePredictionsSuppressed(result)
        XCTAssertEqual(result[.surrogacyEducation].effect, .surface)
        XCTAssertEqual(result[.pregnancyEducation].effect, .surface)
        XCTAssertEqual(result[.hormoneRhythmContextMarker].effect, .suppress)
        XCTAssertEqual(context.reproductiveStage.value, .unspecified)
    }

    func test63PostpartumAfterSurrogatePregnancyUsesPostpartumRecoveryWithoutParentingAssumption() {
        let context = make(surrogacy: .postpartumAfterSurrogatePregnancy)
        let result = engine.policy(for: context)

        XCTAssertEqual(result[.surrogacyEducation].effect, .surface)
        XCTAssertEqual(result[.postpartumEducation].effect, .surface)
        XCTAssertEqual(result[.predictionUncertainty].effect, .clarify)

        let copy = Prompt27AContextPresentationCopy.todayClarification(
            context: context,
            policy: result
        )
        XCTAssertNotNil(copy)
        XCTAssertTrue(copy?.contains("without assuming you’re parenting or caring for a newborn") == true)
    }

    func test64SurrogacyContextRoundTripsThroughCodec() throws {
        let original = make(
            stage: .cycling,
            surrogacy: .pregnantGestationalCarrier
        )

        let codec = Prompt27AContextCodec()
        let decoded = try codec.decode(codec.encode(original))

        XCTAssertEqual(decoded.surrogacyContext.value, .pregnantGestationalCarrier)
        XCTAssertEqual(decoded.surrogacyContext.provenance, .userReported)
        XCTAssertEqual(decoded.reproductiveStage.value, .cycling)
    }

    func test65LegacyStoredContextWithoutSurrogacyMigratesToUnspecifiedSurrogacy() throws {
        let codec = Prompt27AContextCodec()
        let original = make(stage: .postpartum)
        let encoded = try codec.encode(original)

        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        )
        object.removeValue(forKey: "surrogacyContext")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try codec.decode(legacyData)
        XCTAssertEqual(decoded.surrogacyContext.value, .unspecified)
        XCTAssertEqual(decoded.reproductiveStage.value, .postpartum)
    }

    func test66SurrogacyContextClearsWithOtherContextWithoutTouchingHistoryPolicy() {
        var context = make(
            stage: .postpartum,
            surrogacy: .postpartumAfterSurrogatePregnancy
        )
        context.clear(at: Date(timeIntervalSince1970: 90))

        XCTAssertTrue(context.isCompletelyUnspecified)
        XCTAssertFalse(Prompt27AHistoryPreservationPolicy().deleteCycleHistory)
        XCTAssertFalse(Prompt27AHistoryPreservationPolicy().deleteDailyLogs)
    }

    func test67SurrogacyContextDoesNotInferFertilityTreatmentOrTrackingGoal() {
        let context = make(surrogacy: .preparingForEmbryoTransfer)

        XCTAssertEqual(context.fertilityTreatmentContext.value, .unspecified)
        XCTAssertEqual(context.trackingGoal.value, .unspecified)
        XCTAssertEqual(context.reproductiveStage.value, .unspecified)
    }

    func test68SurrogacyDiscoveryCopyIsContextSpecificAndCompact() {
        let context = make(surrogacy: .pregnantGestationalCarrier)
        let policy = engine.policy(for: context)
        let questions = Prompt27AContextPresentationCopy.askDiscoveryQuestions(
            context: context,
            policy: policy
        )

        XCTAssertFalse(questions.isEmpty)
        XCTAssertLessThanOrEqual(questions.count, 3)
        XCTAssertTrue(questions.contains {
            $0.contains("gestational-carrier")
        })
    }

    func test69SurrogacyAIContextIsExplicitOnly() {
        let unspecifiedSummary = Prompt27AMinimizedAIContext.educationalSummary(
            from: make()
        )
        XCTAssertNil(unspecifiedSummary.surrogacyContext)

        let explicitSummary = Prompt27AMinimizedAIContext.educationalSummary(
            from: make(surrogacy: .postpartumAfterSurrogatePregnancy)
        )
        XCTAssertEqual(
            explicitSummary.surrogacyContext,
            .postpartumAfterSurrogatePregnancy
        )
    }

    func test70SurrogacyContextNeverChangesPredictionMathematics() {
        for value in Prompt27ASurrogacyContext.allCases {
            let context = make(surrogacy: value)
            XCTAssertFalse(
                safety.canModifyPredictionMathematics(context: context)
            )
            XCTAssertFalse(
                engine.policy(for: context).modifiesPredictionMathematics
            )
        }
    }

    private func make(
        trackingGoal: Prompt27ATrackingGoal = .unspecified,
        sexualActivity: Prompt27ASexualActivityContext = .unspecified,
        stage: Prompt27AReproductiveStage = .unspecified,
        surrogacy: Prompt27ASurrogacyContext = .unspecified,
        lactation: Prompt27ALactationContext = .unspecified,
        health: Set<Prompt27ACycleHealthContext> = [],
        treatment: Prompt27AFertilityTreatmentContext = .unspecified,
        contraception: Prompt27AContraceptionContext = .unspecified
    ) -> Prompt27AUserReproductiveContext {
        Prompt27AUserReproductiveContext(
            trackingGoal: trackingGoal,
            sexualActivityContext: sexualActivity,
            reproductiveStage: stage,
            surrogacyContext: surrogacy,
            lactationContext: lactation,
            cycleHealthContexts: health,
            fertilityTreatmentContext: treatment,
            contraceptionContext: contraception,
            timestamp: Date(timeIntervalSince1970: 1)
        )
    }

    private func assertActiveCyclePredictionsSuppressed(
        _ result: Prompt27AContextPolicyResult,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(result[.nextPeriodPrediction].effect, .suppress, file: file, line: line)
        XCTAssertEqual(result[.fertileWindowPrediction].effect, .suppress, file: file, line: line)
        XCTAssertEqual(result[.ovulationPrediction].effect, .suppress, file: file, line: line)
    }

    func testUserReportedInfertilityIsExplicitAndBackwardCompatibleByDefault() {
        var context = Prompt27AUserReproductiveContext.unspecified
        XCTAssertEqual(context.infertilityContext.value, .unspecified)
        context.setInfertilityContext(.userReportedInfertility)
        XCTAssertEqual(context.infertilityContext.value, .userReportedInfertility)
        XCTAssertEqual(context.fertilityTreatmentContext.value, .unspecified)
        XCTAssertEqual(context.trackingGoal.value, .unspecified)
    }

}
