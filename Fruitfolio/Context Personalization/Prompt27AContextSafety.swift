import Foundation

nonisolated struct Prompt27AInferenceSignals: Equatable, Sendable {
    var latePeriod: Bool = false
    var symptomsPresent: Bool = false
    var bbtPresent: Bool = false
    var cervicalFluidPresent: Bool = false
    var sexualActivityReported: Bool = false
    var fertileWindowInteraction: Bool = false
    var estimatedOvulationPresent: Bool = false
    var lhInformationPresent: Bool = false
    var missedPrediction: Bool = false
    var usedFertilizationEducation: Bool = false
    var usedPregnancyEducation: Bool = false
    var ageAvailable: Bool = false
    var absentBleeding: Bool = false
    var historicalPregnancyContext: Bool = false
    var irregularCycleData: Bool = false
}

nonisolated struct Prompt27AContextInferenceResult: Equatable, Sendable {
    let inferPregnancy: Bool
    let inferConception: Bool
    let inferImplantation: Bool
    let inferOvulation: Bool
    let inferPCOS: Bool
    let inferMenopause: Bool
    let inferPostpartum: Bool
    let inferFertilityTreatmentOutcome: Bool
    let inferSymptomCause: Bool
    let inferSexualActivityDetails: Bool
    let inferContraceptionUse: Bool

    static let none = Self(
        inferPregnancy: false,
        inferConception: false,
        inferImplantation: false,
        inferOvulation: false,
        inferPCOS: false,
        inferMenopause: false,
        inferPostpartum: false,
        inferFertilityTreatmentOutcome: false,
        inferSymptomCause: false,
        inferSexualActivityDetails: false,
        inferContraceptionUse: false
    )
}

nonisolated struct Prompt27AContextSafety: Sendable {
    init() {}

    func infer(from signals: Prompt27AInferenceSignals) -> Prompt27AContextInferenceResult {
        _ = signals
        return .none
    }

    func canLabelOrdinaryPredictedDaySafeForSex(
        context: Prompt27AUserReproductiveContext
    ) -> Bool {
        _ = context
        return false
    }

    func canModifyPredictionMathematics(
        context: Prompt27AUserReproductiveContext
    ) -> Bool {
        _ = context
        return false
    }

    func canIncreasePredictionConfidence(
        context: Prompt27AUserReproductiveContext
    ) -> Bool {
        _ = context
        return false
    }

    func canPersonalizeEmbryoStage(
        context: Prompt27AUserReproductiveContext
    ) -> Bool {
        _ = context
        return false
    }
}

nonisolated struct Prompt27AHistoryPreservationPolicy: Equatable, Sendable {
    let deleteCycleHistory = false
    let deleteDailyLogs = false
    let deleteTrends = false
    let rewriteHistoricalPredictions = false
    let rewriteRecordedObservations = false
    let retroactivelyAssignContext = false
    let inventDeliveryDate = false
}

nonisolated struct Prompt27AMinimizedAIContext: Codable, Equatable, Sendable {
    let trackingGoal: Prompt27ATrackingGoal?
    let reproductiveStage: Prompt27AReproductiveStage?
    let surrogacyContext: Prompt27ASurrogacyContext?
    let lactationContext: Prompt27ALactationContext?
    let cycleHealthContexts: Set<Prompt27ACycleHealthContext>
    let fertilityTreatmentContext: Prompt27AFertilityTreatmentContext?
    let contraceptionContext: Prompt27AContraceptionContext?

    static func educationalSummary(
        from context: Prompt27AUserReproductiveContext,
        includeSexualActivity: Bool = false
    ) -> Self {
        // Sexual activity is deliberately excluded from this coarse AI-facing summary.
        // A future narrowly scoped feature may pass it separately only when genuinely required.
        _ = includeSexualActivity
        return Self(
            trackingGoal: context.trackingGoal.value == .unspecified ? nil : context.trackingGoal.value,
            reproductiveStage: context.reproductiveStage.value == .unspecified ? nil : context.reproductiveStage.value,
            surrogacyContext: context.surrogacyContext.value == .unspecified ? nil : context.surrogacyContext.value,
            lactationContext: context.lactationContext.value == .unspecified ? nil : context.lactationContext.value,
            cycleHealthContexts: context.cycleHealthContexts,
            fertilityTreatmentContext: context.fertilityTreatmentContext.value == .unspecified ? nil : context.fertilityTreatmentContext.value,
            contraceptionContext: context.contraceptionContext.value == .unspecified ? nil : context.contraceptionContext.value
        )
    }
}
