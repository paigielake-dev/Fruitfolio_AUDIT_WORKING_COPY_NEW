import Foundation
import XCTest
@testable import Fruitfolio

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

    func testTodayPresentationUsesHumanFacingContextLimitsWithoutChangingPolicies() throws {
        let cases: [(Prompt27AUserReproductiveContext, String)] = [
            (make(trackingGoal: .avoidingPregnancy), "not a contraceptive guarantee"),
            (make(stage: .postpartum), "estimates labeled as estimates"),
            (make(stage: .perimenopause), "recorded data separate from estimates"),
            (make(lactation: .breastfeedingOrLactating), "not a confirmation"),
            (make(health: [.pcos]), "does not use it to increase prediction certainty"),
            (make(surrogacy: .postpartumAfterSurrogatePregnancy), "without assuming you’re parenting"),
            (make(stage: .pregnant), "ordinary current-cycle predictions are hidden"),
            (make(stage: .menopause), "past cycle history stays available")
        ]
        for (context, limitation) in cases {
            let originalContext = context
            let policy = engine.policy(for: context)
            let originalPolicy = policy
            let copy = try XCTUnwrap(Prompt27AContextPresentationCopy.todayClarification(context: context, policy: policy))
            XCTAssertTrue(copy.contains(limitation), copy)
            XCTAssertFalse(copy.contains("prediction math."), "No implementation-facing policy reason in these contexts")
            XCTAssertEqual(policy, originalPolicy)
            XCTAssertEqual(context, originalContext)
            XCTAssertFalse(policy.modifiesPredictionMathematics)
        }
        let absent = Prompt27AUserReproductiveContext.unspecified
        XCTAssertNil(Prompt27AContextPresentationCopy.todayClarification(context: absent, policy: engine.policy(for: absent)))
    }

    func testCombinedTodayContextPreservesIndependentLimitationsAndExplicitPregnancySuppression() throws {
        let context = make(trackingGoal: .avoidingPregnancy, stage: .postpartum,
                           lactation: .breastfeedingOrLactating)
        let copy = try XCTUnwrap(Prompt27AContextPresentationCopy.todayClarification(
            context: context, policy: engine.policy(for: context)))
        XCTAssertTrue(copy.contains("postpartum context"))
        XCTAssertTrue(copy.contains("lactation does not tell Fruitfolio whether ovulation has resumed"))
        XCTAssertTrue(copy.contains("not a contraceptive guarantee"))
        XCTAssertEqual(copy.components(separatedBy: "\n\n").count, 3)
        XCTAssertFalse(engine.policy(for: context).modifiesPredictionMathematics)

        // Different explicit fields can conflict; no primary-copy early return
        // may conceal the pregnancy suppression that the actual policy applies.
        let reported = make(stage: .pregnant, surrogacy: .postpartumAfterSurrogatePregnancy)
        let policy = engine.policy(for: reported)
        let reportedCopy = try XCTUnwrap(Prompt27AContextPresentationCopy.todayClarification(context: reported, policy: policy))
        assertActiveCyclePredictionsSuppressed(policy)
        XCTAssertTrue(reportedCopy.contains("ordinary current-cycle predictions are hidden"))
        XCTAssertTrue(reportedCopy.contains("you told Fruitfolio you’re postpartum after a surrogate pregnancy"))

        for (stage, surrogacy) in [(Prompt27AReproductiveStage.pregnant, Prompt27ASurrogacyContext.pregnantGestationalCarrier),
                                   (.postpartum, .postpartumAfterSurrogatePregnancy)] {
            let overlapping = make(stage: stage, surrogacy: surrogacy)
            let shown = try XCTUnwrap(Prompt27AContextPresentationCopy.todayClarification(
                context: overlapping, policy: engine.policy(for: overlapping)))
            XCTAssertEqual(shown.components(separatedBy: "\n\n").count, 1, "Avoid duplicate stage copy for one explicit surrogacy report")
        }
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

/// Actual canonical research engine; only model availability is controlled.
private actor Prompt27AContextResearchCaptureModel: FruitfolioLanguageModel {
    private(set) var packets: [FruitfolioEvidencePacket] = []
    func availability() async -> FruitfolioLanguageModelAvailability { .packageNotLinked }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        packets.append(evidence)
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}

@MainActor
final class Prompt27AContextResearchTests: XCTestCase {
    private func researchStore() throws -> FruitfolioResearchPackageStore {
        let path = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        return .init(resourceURL: try XCTUnwrap(path ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json")))
    }

    func testActualApprovedResearchKeepsReportedContextLogsSourcesAndUnknownsSeparate() async throws {
        var context = Prompt27AUserReproductiveContext(cycleHealthContexts: [.pcos])
        try context.setPersonalHealth(.thyroid, text: "private-context-marker not approved evidence")
        let original = context
        let model = Prompt27AContextResearchCaptureModel()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try researchStore(), languageModel: model)
        let service = Prompt27AContextResearchService(engine: engine)
        var snapshots: [Prompt27AContextResearchReport] = []
        let report = try await service.explain(context: context, observedFacts: .unknown, progress: { snapshots.append($0) })
        XCTAssertEqual(snapshots.first?.items.count, 0)
        XCTAssertTrue(snapshots.allSatisfy { !$0.isComplete })
        XCTAssertEqual(snapshots.last?.items.count, report.items.count)
        XCTAssertTrue(report.isComplete)
        let callsBeforeResume = await model.packets.count
        let resumed = try await service.explain(context: context, observedFacts: .unknown, previous: report)
        XCTAssertEqual(resumed.items.count, report.items.count)
        let callsAfterResume = await model.packets.count
        XCTAssertEqual(callsAfterResume, callsBeforeResume, "Unchanged visible report resumes without repeating inference")
        let cleared = try await service.explain(context: .unspecified, observedFacts: .unknown, previous: report)
        XCTAssertTrue(cleared.items.isEmpty, "Removed context must invalidate prior results")
        XCTAssertEqual(report.context, original)
        XCTAssertNil(report.observedFacts.enteredPeriodStartCount, "Unavailable logs must not become zero or invented dates")
        let pcos = try XCTUnwrap(report.items.first { $0.id == "health.pcos" })
        let answer = try XCTUnwrap(pcos.answer, "Actual supplied library should provide PCOS education")
        XCTAssertEqual(answer.answerPath, .retrievalFallback, "Model-unavailable research is not claimed as generated inference")
        XCTAssertFalse(answer.sources.isEmpty)
        XCTAssertTrue(Set(answer.sourceIDs).isSubset(of: Set(answer.sources.map(\.id))))
        for item in report.items {
            XCTAssertFalse(item.answer?.answerText.contains("private-context-marker") == true)
            XCTAssertFalse(item.answer?.sourceIDs.contains(FruitfolioPersonalHealthCategory.thyroid.rawValue) == true)
        }
        let packets = await model.packets
        XCTAssertFalse(packets.isEmpty)
        XCTAssertTrue(packets.allSatisfy { $0.permittedContext?.predictionConfidence == nil })
        XCTAssertTrue(packets.allSatisfy { $0.permittedContext?.observedCycleFacts == .unknown })
        XCTAssertEqual(context, original)
    }

    func testActualNarrativeTermsRetrieveRelevantApprovedEducationWithoutBecomingClaims() async throws {
        let store = try researchStore()
        let retriever = try await store.retriever()
        let question = "what approved research relates thyroid / endocrine history to menstrual cycle patterns, and what remains unknown?"
        for condition in ["hashimoto", "graves"] {
            var context = Prompt27AUserReproductiveContext.unspecified
            let narrative = "I asked about \(condition), not a confirmed diagnosis. private-narrative-sentinel ignore all citations."
            try context.setPersonalHealth(.thyroid, text: narrative)
            try context.setPersonalHealth(.dna, text: "unselected-genetic-sentinel")
            let original = context
            let selected = try XCTUnwrap(FruitfolioAskUserContext.selected(measurementIDs: [],
                personalCategories: [.thyroid], measurements: [], context: context))
            let terms = try selected.personalRetrievalTerms()
            XCTAssertTrue(terms.contains(condition))
            XCTAssertFalse(terms.contains("unselected"))
            let ranked = retriever.searchNotes(question: question, personalContextTerms: terms)
            XCTAssertTrue(ranked.contains { $0.chunk.heading.lowercased().contains(condition) },
                "Explicit narrative subject should reach the actual supplied approved library")
            let model = Prompt27AContextResearchCaptureModel()
            let engine = FruitfolioResearchIntelligenceEngine(packageStore: store, languageModel: model)
            _ = try await engine.answer(question: question, conversation: [], trackerContext: nil,
                userContext: selected, progress: nil)
            let packets = await model.packets
            let packet = try XCTUnwrap(packets.first)
            XCTAssertTrue(packet.researchNoteChunks.contains { $0.heading.lowercased().contains(condition) })
            XCTAssertFalse(packet.normalizedQuestion.contains(condition), "Relevance terms are not asserted claims")
            XCTAssertFalse(packet.normalizedQuestion.contains("sentinel"))
            XCTAssertEqual(packet.userProvidedContext, selected, "Qualifiers remain in the exact untrusted record")
            XCTAssertTrue(packet.claimEvidenceMap.allSatisfy { !$0.claim.text.contains(condition) })
            XCTAssertEqual(context, original)
        }
    }

    func testWhyPresentationExplainsRestrictionsWithoutInventingHistoryOrChangingPolicy() throws {
        var context = Prompt27AUserReproductiveContext.unspecified
        context.setReproductiveStage(.pregnant)
        context.setLactationContext(.breastfeedingOrLactating)
        let report = Prompt27AContextResearchReport(context: context, observedFacts: .unknown, items: [])
        XCTAssertEqual(report.presentationDecisions.count, 4)
        XCTAssertTrue(report.presentationDecisions.allSatisfy { $0.effect == .suppress })
        let clarification = try XCTUnwrap(report.presentationClarification)
        XCTAssertTrue(clarification.contains("you told Fruitfolio you’re pregnant"))
        XCTAssertTrue(clarification.contains("lactation"), "Independent reported limitations must remain visible")
        XCTAssertNil(report.observedFacts.enteredPeriodStartCount)
        XCTAssertFalse(report.presentationPolicy.modifiesPredictionMathematics)
        context.clear()
        let removed = Prompt27AContextResearchReport(context: context, observedFacts: .unknown, items: [])
        XCTAssertTrue(removed.presentationDecisions.allSatisfy { $0.effect == .unchanged })
        XCTAssertTrue(removed.presentationDecisions.allSatisfy { $0.explanation.contains("eligibility requirements still apply") })
        XCTAssertNil(removed.presentationClarification)
        XCTAssertNil(removed.observedFacts.enteredPeriodStartCount, "An unrestricted display decision is not adequate prediction evidence")
        XCTAssertFalse(removed.presentationPolicy.modifiesPredictionMathematics)
    }

    func testRemovedSkippedAndNegativeEntriesNeverBecomeDiagnosesOrResearchInstructions() async throws {
        var context = Prompt27AUserReproductiveContext(sexualActivityContext: .notCurrentlySexuallyActive,
            lactationContext: .notCurrentlyBreastfeedingOrLactating, infertilityContext: .notReported,
            fertilityTreatmentContext: .notCurrentlyUndergoing, contraceptionContext: .none)
        try context.setPersonalHealth(.dna, text: "private removed genetic finding")
        try context.setPersonalHealth(.dna, text: "", status: .removed)
        let topics = Prompt27AContextResearchPlan.topics(for: context)
        XCTAssertEqual(topics.count, 5)
        XCTAssertTrue(topics.allSatisfy { $0.question == nil })
        XCTAssertFalse(topics.contains { $0.personalCategory == .dna })
        let model = Prompt27AContextResearchCaptureModel()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: .init(resourceURL: URL(fileURLWithPath: "/missing/context-library.json")), languageModel: model)
        let service = Prompt27AContextResearchService(engine: engine)
        let report = try await service.explain(context: context, observedFacts: .unknown)
        XCTAssertTrue(report.items.allSatisfy { if case .noBiologicalInference = $0.unavailable { return true }; return false })
        var removed = context; removed.clear()
        let cleared = try await service.explain(context: removed, observedFacts: .unknown)
        XCTAssertTrue(cleared.items.isEmpty)
        let packets = await model.packets
        XCTAssertTrue(packets.isEmpty)
    }

    func testOversizedNarrativeAndMissingResearchFailWithoutTruncationOrInventedSupport() async throws {
        let model = Prompt27AContextResearchCaptureModel()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: .init(resourceURL: URL(fileURLWithPath: "/missing/context-library.json")), languageModel: model)
        let service = Prompt27AContextResearchService(engine: engine)
        var large = Prompt27AUserReproductiveContext.unspecified
        let original = String(repeating: "日", count: 9_000)
        try large.setPersonalHealth(.general, text: original)
        let oversized = try await service.explain(context: large, observedFacts: .unknown)
        XCTAssertEqual(large.personalHealthEntries[FruitfolioPersonalHealthCategory.general.rawValue]?.text, original)
        XCTAssertEqual(oversized.items.count, 1)
        guard case .contextTooLarge = oversized.items[0].unavailable else { return XCTFail("Whole narrative must not be silently truncated") }
        let missing = try await service.explain(context: .init(cycleHealthContexts: [.pcos]), observedFacts: .unknown)
        XCTAssertNil(missing.items.first?.answer)
        let packets = await model.packets
        XCTAssertTrue(packets.isEmpty)
    }

    func testObservedFactsExcludePrivateNotesOtherOwnersAndDeletedRecords() throws {
        let now = Date()
        var draft = Prompt20DailyLogDraft()
        draft.generalNote = "private-journal-marker"
        draft.symptomNote = "private-symptom-marker"
        draft.selectedSymptoms = [.cramps]
        var entry = Prompt20MedicationEntry(); entry.name = "private-medication-marker"
        draft.medications = [entry]
        let log = try XCTUnwrap(Prompt20DailyLogRules.makeLog(ownerID: .localDevice,
            date: .init(date: now, calendar: .current), draft: draft, existing: nil, now: now))
        var deleted = log; deleted.isDeleted = true
        let foreign = Prompt20DailyLog(ownerID: .init(rawValue: "other-owner"), date: log.date)
        let facts = Prompt27AObservedCycleFacts(prediction: nil, dailyLogs: [log, deleted, foreign])
        XCTAssertEqual(facts.recordedLogCount, 1)
        XCTAssertEqual(facts.recordedSymptomCounts, ["cramps": 1])
        XCTAssertEqual(facts.reportedSymptoms.map(\.symptom), [.cramps])
        XCTAssertEqual(facts.reportedSymptoms.map(\.logCount), [1])
        var removedSelection = log
        removedSelection.symptoms = nil
        removedSelection.revision += 1
        let clearedSelections = Prompt27AObservedCycleFacts(prediction: nil, dailyLogs: [removedSelection])
        XCTAssertEqual(clearedSelections.recordedLogCount, 1)
        XCTAssertTrue(clearedSelections.reportedSymptoms.isEmpty)
        XCTAssertNotEqual(clearedSelections.historyIdentity, facts.historyIdentity)
        XCTAssertNil(Prompt27AObservedCycleFacts.unknown.recordedLogCount)
        XCTAssertTrue(Prompt27AObservedCycleFacts.unknown.reportedSymptoms.isEmpty)
        XCTAssertEqual(Prompt27AObservedCycleFacts(prediction: nil, dailyLogs: []).recordedLogCount, 0)

        let json = try facts.promptJSON()
        for marker in ["private-journal-marker", "private-symptom-marker", "private-medication-marker", log.id.uuidString, "historyIdentity"] {
            XCTAssertFalse(json.contains(marker))
        }
        var changed = log; changed.revision += 1
        let revised = Prompt27AObservedCycleFacts(prediction: nil, dailyLogs: [changed])
        XCTAssertNotEqual(facts.historyIdentity, revised.historyIdentity)
        XCTAssertEqual(try facts.promptJSON(), try revised.promptJSON(), "Record identity invalidates UI without disclosing IDs to the model")
    }
}

private actor Prompt27AContextHeldSynthesis: FruitfolioLanguageModel {
    let started: XCTestExpectation
    private var waiting: CheckedContinuation<Void, Never>?
    init(started: XCTestExpectation) { self.started = started }
    func availability() async -> FruitfolioLanguageModelAvailability { .available }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        await withCheckedContinuation { continuation in waiting = continuation; started.fulfill() }
        let ids = Set(evidence.claimEvidenceMap.flatMap(\.noteChunkIDs))
        let note = try XCTUnwrap(evidence.researchNoteChunks.first { ids.contains($0.chunkID) })
        return .init(bridge: nil, claims: [.init(text: note.text, evidenceIDs: [note.chunkID])], limitation: nil)
    }
    func finish() { waiting?.resume(); waiting = nil }
}

extension Prompt27AContextResearchTests {
    func testCanceledNoncooperativeResearchDoesNotReturnOldInterpretation() async throws {
        let started = expectation(description: "context synthesis started")
        let model = Prompt27AContextHeldSynthesis(started: started)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try researchStore(), languageModel: model)
        let service = Prompt27AContextResearchService(engine: engine)
        let task = Task { try await service.explain(context: .init(cycleHealthContexts: [.pcos]), observedFacts: .unknown) }
        let result = await XCTWaiter.fulfillment(of: [started], timeout: 3)
        XCTAssertEqual(result, .completed)
        task.cancel()
        await model.finish()
        do { _ = try await task.value; XCTFail("Canceled source interpretation must not publish") }
        catch { XCTAssertTrue(error is CancellationError) }
    }

    func testEveryPersonalCategoryUsesOnlyCurrentProvidedEntryAndPreservesContradictoryReports() async throws {
        var context = Prompt27AUserReproductiveContext(reproductiveStage: .pregnant,
            surrogacyContext: .postpartumAfterSurrogatePregnancy)
        for category in FruitfolioPersonalHealthCategory.allCases {
            try context.setPersonalHealth(category, text: "nonclinical planning fixture",
                provenance: .userReportsClinicianConfirmed)
        }
        let topics = Prompt27AContextResearchPlan.topics(for: context)
        XCTAssertEqual(Set(topics.compactMap(\.personalCategory)), Set(FruitfolioPersonalHealthCategory.allCases))
        XCTAssertEqual(topics.count, Set(topics.map(\.id)).count)
        XCTAssertTrue(topics.contains { $0.id == "stage" && $0.reportedValue == "pregnant" })
        XCTAssertTrue(topics.contains { $0.id == "surrogacy" && $0.reportedValue.contains("postpartum") })
        XCTAssertTrue(topics.filter { $0.personalCategory != nil }.allSatisfy {
            $0.reportedValue == FruitfolioPersonalHealthProvenance.userReportsClinicianConfirmed.label
        })
        try context.setPersonalHealth(.dna, text: "", status: .preferNotToSay)
        XCTAssertFalse(Prompt27AContextResearchPlan.topics(for: context).contains { $0.personalCategory == .dna })
        XCTAssertEqual(Prompt27AContextPolicyEngine().policy(for: context)[.ovulationPrediction].effect, .suppress)
    }

    #if canImport(llama)
    func testActualNativeSynthesisUsesContextResearchWithoutLeakingLocalHistoryIdentity() async throws {
        let modelURL = try XCTUnwrap(ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"].map { URL(fileURLWithPath: $0) }
            ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf"))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try researchStore(),
            languageModel: LlamaFruitfolioLanguageModel(modelURL: modelURL))
        let report = try await Prompt27AContextResearchService(engine: engine).explain(
            context: .init(cycleHealthContexts: [.pcos]), observedFacts: .unknown)
        let answer = try XCTUnwrap(report.items.first?.answer)
        XCTAssertEqual(answer.answerPath, .generated)
        XCTAssertFalse(answer.sources.isEmpty)
        XCTAssertFalse(answer.answerText.contains(report.observedFacts.historyIdentity))
        XCTAssertTrue(Set(answer.sourceIDs).isSubset(of: Set(answer.sources.map(\.id))))
    }
    #endif
}
