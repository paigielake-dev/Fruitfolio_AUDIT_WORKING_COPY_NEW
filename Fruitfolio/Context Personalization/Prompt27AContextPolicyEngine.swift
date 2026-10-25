import Foundation

nonisolated enum Prompt27AContextFeature: String, Codable, CaseIterable, Hashable, Sendable {
    case today
    case calendar
    case dailyLog
    case symptoms
    case bbtLogging
    case cervicalFluidLogging
    case trends
    case bodyBiology
    case hormoneRhythm
    case hormoneRhythmContextMarker
    case nextPeriodPrediction
    case fertileWindowPrediction
    case ovulationPrediction
    case predictionUncertainty
    case fertilizationEducation
    case pregnancyEducation
    case contraceptionEducation
    case postpartumEducation
    case lactationEducation
    case perimenopauseEducation
    case menopauseEducation
    case pcosEducation
    case endometriosisEducation
    case fertilityTreatmentEducation
    case surrogacyEducation
    case medicationLogging
    case treatmentNotes
    case askEncyclopedia
}

nonisolated enum Prompt27AContextPolicyEffect: String, Codable, Equatable, Sendable {
    case surface
    case clarify
    case suppress
    case unchanged
}

nonisolated struct Prompt27AFeaturePolicy: Codable, Equatable, Sendable {
    let effect: Prompt27AContextPolicyEffect
    let reason: String?

    init(_ effect: Prompt27AContextPolicyEffect, reason: String? = nil) {
        self.effect = effect
        self.reason = reason
    }
}

nonisolated struct Prompt27AContextPolicyResult: Codable, Equatable, Sendable {
    private(set) var policies: [Prompt27AContextFeature: Prompt27AFeaturePolicy]

    init(policies: [Prompt27AContextFeature: Prompt27AFeaturePolicy] = [:]) {
        var normalized: [Prompt27AContextFeature: Prompt27AFeaturePolicy] = [:]
        for feature in Prompt27AContextFeature.allCases {
            normalized[feature] = policies[feature] ?? Prompt27AFeaturePolicy(.unchanged)
        }
        self.policies = normalized
    }

    subscript(feature: Prompt27AContextFeature) -> Prompt27AFeaturePolicy {
        policies[feature] ?? Prompt27AFeaturePolicy(.unchanged)
    }

    var surfacedFeatures: Set<Prompt27AContextFeature> {
        Set(policies.compactMap { $0.value.effect == .surface ? $0.key : nil })
    }

    var clarifiedFeatures: Set<Prompt27AContextFeature> {
        Set(policies.compactMap { $0.value.effect == .clarify ? $0.key : nil })
    }

    var suppressedFeatures: Set<Prompt27AContextFeature> {
        Set(policies.compactMap { $0.value.effect == .suppress ? $0.key : nil })
    }

    var unchangedFeatures: Set<Prompt27AContextFeature> {
        Set(policies.compactMap { $0.value.effect == .unchanged ? $0.key : nil })
    }

    var modifiesPredictionMathematics: Bool { false }
}

nonisolated struct Prompt27AContextPolicyEngine: Sendable {
    init() {}

    func policy(for context: Prompt27AUserReproductiveContext) -> Prompt27AContextPolicyResult {
        var p = Dictionary(uniqueKeysWithValues: Prompt27AContextFeature.allCases.map {
            ($0, Prompt27AFeaturePolicy(.unchanged))
        })

        func set(_ feature: Prompt27AContextFeature, _ effect: Prompt27AContextPolicyEffect, _ reason: String) {
            let existing = p[feature] ?? .init(.unchanged)
            if precedence(of: effect) >= precedence(of: existing.effect) {
                p[feature] = .init(effect, reason: reason)
            }
        }

        switch context.trackingGoal.value {
        case .tryingToConceive:
            set(.bbtLogging, .surface, "TTC makes existing BBT logging more relevant.")
            set(.cervicalFluidLogging, .surface, "TTC makes existing cervical-fluid logging more relevant.")
            set(.fertilizationEducation, .surface, "TTC may increase discoverability of educational fertilization content.")
            set(.trends, .surface, "TTC may make existing fertility-related Trends easier to reach.")
            set(.predictionUncertainty, .clarify, "TTC does not increase prediction certainty.")

        case .avoidingPregnancy:
            set(.contraceptionEducation, .surface, "Avoiding pregnancy makes contraception education more relevant.")
            set(.predictionUncertainty, .surface, "Prediction limitations should be especially discoverable when avoiding pregnancy.")
            set(.fertileWindowPrediction, .clarify, "Estimated fertile windows are not contraceptive guarantees.")
            set(.ovulationPrediction, .clarify, "Estimated ovulation is not a contraceptive guarantee.")

        case .generalCycleTracking, .noSpecificGoal, .preferNotToSpecify, .unspecified:
            break
        }

        switch context.sexualActivityContext.value {
        case .notCurrentlySexuallyActive:
            set(.fertilizationEducation, .clarify, "Automatic conception-oriented surfacing may be reduced; deliberate access remains available.")
        case .sexuallyActive, .preferNotToSay, .unspecified:
            break
        }

        switch context.reproductiveStage.value {
        case .pregnant:
            set(.nextPeriodPrediction, .suppress, "Ordinary current-cycle period prediction is not presently applicable in user-reported pregnancy context.")
            set(.fertileWindowPrediction, .suppress, "Ordinary current-cycle fertile-window prediction is not presently applicable in user-reported pregnancy context.")
            set(.ovulationPrediction, .suppress, "Ordinary current-cycle ovulation prediction is not presently applicable in user-reported pregnancy context.")
            set(.pregnancyEducation, .surface, "User-reported pregnancy may make Pregnancy Education easier to reach.")
            set(.calendar, .clarify, "Historical records remain; current active-cycle prediction overlays may be suppressed.")
            set(.today, .clarify, "Today should not present ordinary active-cycle predictions as currently applicable.")
            set(.hormoneRhythm, .clarify, "Hormone Rhythm stays general natural-cycle education rather than a picture of pregnancy hormone levels.")
            set(.hormoneRhythmContextMarker, .suppress, "A natural-cycle current-position marker is not appropriate in explicit pregnancy context.")

        case .postpartum:
            set(.postpartumEducation, .surface, "Postpartum education is relevant to explicit postpartum context.")
            set(.predictionUncertainty, .clarify, "Ordinary cycle assumptions may be limited postpartum.")
            set(.calendar, .clarify, "Historical records remain while current predictions may require added context.")
            set(.hormoneRhythm, .clarify, "Natural-cycle hormone education requires added framing postpartum.")
            set(.hormoneRhythmContextMarker, .suppress, "Postpartum context alone does not establish current ovulatory-cycle position.")

        case .perimenopause:
            set(.perimenopauseEducation, .surface, "Perimenopause education is relevant to explicit user-reported context.")
            set(.predictionUncertainty, .clarify, "Prediction limitations should remain clear when cycles vary.")
            set(.trends, .clarify, "Calculated variability and user-reported perimenopause remain distinct facts.")

        case .menopause:
            set(.nextPeriodPrediction, .suppress, "Ordinary current-cycle next-period prediction is not presently applicable in user-reported menopause context.")
            set(.fertileWindowPrediction, .suppress, "Ordinary current-cycle fertile-window prediction is not presently applicable in user-reported menopause context.")
            set(.ovulationPrediction, .suppress, "Ordinary current-cycle ovulation prediction is not presently applicable in user-reported menopause context.")
            set(.menopauseEducation, .surface, "Menopause-relevant education is appropriate to surface.")
            set(.trends, .clarify, "Historical Trends remain available without rewriting prior cycle history.")
            set(.calendar, .clarify, "Historical cycle records remain preserved.")
            set(.hormoneRhythm, .clarify, "Hormone Rhythm remains qualitative education and requires context-appropriate framing.")
            set(.hormoneRhythmContextMarker, .suppress, "A current natural-cycle position marker is not appropriate in explicit menopause context.")

        case .cycling, .preferNotToSpecify, .unspecified:
            break
        }

        switch context.surrogacyContext.value {
        case .preparingForEmbryoTransfer:
            set(.surrogacyEducation, .surface, "Surrogacy education is relevant to explicit gestational-carrier preparation context.")
            set(.askEncyclopedia, .surface, "Relevant approved surrogacy education may be easier to discover.")
            set(.predictionUncertainty, .clarify, "Surrogacy preparation does not authorize changes to cycle-prediction mathematics.")

        case .pregnantGestationalCarrier:
            set(.surrogacyEducation, .surface, "Surrogacy education is relevant to explicit gestational-carrier pregnancy context.")
            set(.pregnancyEducation, .surface, "Pregnancy education may be relevant without assuming parenting or intended-parent status.")
            set(.nextPeriodPrediction, .suppress, "Ordinary current-cycle period prediction is not presently applicable during an explicitly reported gestational-carrier pregnancy.")
            set(.fertileWindowPrediction, .suppress, "Ordinary current-cycle fertile-window prediction is not presently applicable during an explicitly reported gestational-carrier pregnancy.")
            set(.ovulationPrediction, .suppress, "Ordinary current-cycle ovulation prediction is not presently applicable during an explicitly reported gestational-carrier pregnancy.")
            set(.calendar, .clarify, "Historical records remain while current active-cycle prediction overlays may be suppressed.")
            set(.today, .clarify, "Today should not present ordinary active-cycle predictions as currently applicable.")
            set(.hormoneRhythm, .clarify, "Hormone Rhythm stays general natural-cycle education rather than a picture of pregnancy hormone levels.")
            set(.hormoneRhythmContextMarker, .suppress, "A natural-cycle current-position marker is not appropriate during an explicitly reported gestational-carrier pregnancy.")
            set(.askEncyclopedia, .surface, "Relevant approved surrogacy education may be easier to discover.")

        case .postpartumAfterSurrogatePregnancy:
            set(.surrogacyEducation, .surface, "Surrogacy education is relevant to explicit postpartum-after-surrogacy context.")
            set(.postpartumEducation, .surface, "Postpartum recovery education is relevant without assuming parenting or newborn-care responsibilities.")
            set(.predictionUncertainty, .clarify, "Ordinary cycle assumptions may be limited postpartum.")
            set(.calendar, .clarify, "Historical records remain while current predictions may require added context.")
            set(.hormoneRhythm, .clarify, "Natural-cycle hormone education requires added framing postpartum.")
            set(.hormoneRhythmContextMarker, .suppress, "Postpartum-after-surrogacy context alone does not establish current ovulatory-cycle position.")
            set(.askEncyclopedia, .surface, "Relevant approved surrogacy education may be easier to discover.")

        case .preferNotToSpecify, .unspecified:
            break
        }

        switch context.lactationContext.value {
        case .breastfeedingOrLactating:
            set(.lactationEducation, .surface, "Lactation education is relevant to explicit lactation context.")
            set(.predictionUncertainty, .clarify, "Lactation does not establish whether ovulation has resumed.")
            set(.ovulationPrediction, .clarify, "Lactation status alone does not confirm or exclude ovulation.")
            set(.hormoneRhythm, .clarify, "Natural-cycle hormone education requires added framing during lactation.")
            set(.hormoneRhythmContextMarker, .suppress, "Lactation status alone does not establish current ovulatory-cycle position.")
        case .notCurrentlyBreastfeedingOrLactating, .preferNotToSpecify, .unspecified:
            break
        }

        if context.cycleHealthContexts.contains(.pcos) {
            set(.pcosEducation, .surface, "PCOS education is relevant to explicit user-reported PCOS context.")
            set(.predictionUncertainty, .clarify, "PCOS context does not authorize a new prediction algorithm.")
            set(.askEncyclopedia, .surface, "Relevant approved PCOS education may be easier to discover.")
        }

        if context.cycleHealthContexts.contains(.endometriosis) {
            set(.endometriosisEducation, .surface, "Endometriosis education is relevant to explicit user-reported context.")
            set(.symptoms, .surface, "Existing symptom logging may be easier to reach without causal relabeling.")
            set(.askEncyclopedia, .surface, "Relevant approved endometriosis education may be easier to discover.")
        }

        if context.cycleHealthContexts.contains(.irregularCycles) {
            set(.predictionUncertainty, .surface, "User-reported irregular cycles make prediction limitations especially relevant.")
            set(.trends, .clarify, "User-reported irregularity remains distinct from calculated variability.")
        }

        switch context.fertilityTreatmentContext.value {
        case .currentlyUndergoing:
            set(.fertilityTreatmentEducation, .surface, "Fertility-treatment education is relevant to explicit treatment context.")
            set(.medicationLogging, .surface, "Existing medication logging may be easier to reach.")
            set(.treatmentNotes, .surface, "Existing notes may be easier to reach for treatment context.")
            set(.fertilizationEducation, .surface, "Fertilization Education may be easier to discover as education only.")
        case .notCurrentlyUndergoing, .preferNotToSpecify, .unspecified:
            break
        }

        switch context.contraceptionContext.value {
        case .hormonalContraception:
            set(.hormoneRhythm, .clarify, "Natural-cycle hormone patterns must not be presented as measured individual physiology under hormonal contraception.")
            set(.hormoneRhythmContextMarker, .suppress, "Current-context marker should be suppressed when established altered-context rules make it inappropriate.")
            set(.contraceptionEducation, .surface, "Contraception education may be relevant.")
        case .nonHormonalContraception:
            set(.contraceptionEducation, .surface, "Contraception education may be relevant.")
        case .none, .preferNotToSpecify, .unspecified:
            break
        }

        // Central conflict resolution: explicit pregnancy or menopause outranks goal-driven
        // surfacing for ordinary active-cycle predictions, but never deletes stored goals.
        if context.reproductiveStage.value == .pregnant ||
            context.reproductiveStage.value == .menopause ||
            context.surrogacyContext.value == .pregnantGestationalCarrier {
            for feature in [Prompt27AContextFeature.nextPeriodPrediction, .fertileWindowPrediction, .ovulationPrediction] {
                p[feature] = .init(.suppress, reason: "Explicit reproductive stage makes the ordinary active-cycle prediction presently inapplicable.")
            }
        }

        return Prompt27AContextPolicyResult(policies: p)
    }

    private func precedence(of effect: Prompt27AContextPolicyEffect) -> Int {
        switch effect {
        case .unchanged: return 0
        case .clarify: return 1
        case .surface: return 2
        case .suppress: return 3
        }
    }
}

