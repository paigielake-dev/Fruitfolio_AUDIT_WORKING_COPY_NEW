import Foundation

/// Read-only adapter used by existing Fruitfolio surfaces.
///
/// Prompt 27A never mutates prediction engines or stored observations. Existing
/// experiences ask this adapter whether a presentation is currently applicable,
/// then keep their own canonical data/biology architecture unchanged.
nonisolated struct Prompt27AExistingSystemPolicyAdapter: Sendable {
    let result: Prompt27AContextPolicyResult

    init(result: Prompt27AContextPolicyResult) {
        self.result = result
    }

    func effect(
        for feature: Prompt27AContextFeature
    ) -> Prompt27AContextPolicyEffect {
        result[feature].effect
    }

    func isSurfaced(
        _ feature: Prompt27AContextFeature
    ) -> Bool {
        result[feature].effect == .surface
    }

    func isClarified(
        _ feature: Prompt27AContextFeature
    ) -> Bool {
        result[feature].effect == .clarify
    }

    func isSuppressed(
        _ feature: Prompt27AContextFeature
    ) -> Bool {
        result[feature].effect == .suppress
    }

    var showCurrentNextPeriodPrediction: Bool {
        !isSuppressed(.nextPeriodPrediction)
    }

    var showCurrentFertileWindowPrediction: Bool {
        !isSuppressed(.fertileWindowPrediction)
    }

    var showCurrentOvulationPrediction: Bool {
        !isSuppressed(.ovulationPrediction)
    }

    var showHormoneRhythmContextMarker: Bool {
        !isSuppressed(.hormoneRhythmContextMarker)
    }

    var surfacedFeatures: Set<Prompt27AContextFeature> {
        result.surfacedFeatures
    }

    var clarifiedFeatures: Set<Prompt27AContextFeature> {
        result.clarifiedFeatures
    }
}

nonisolated struct Prompt27AContextModule: Sendable {
    let policyEngine: Prompt27AContextPolicyEngine
    let safety: Prompt27AContextSafety
    let codec: Prompt27AContextCodec

    init() {
        policyEngine = Prompt27AContextPolicyEngine()
        safety = Prompt27AContextSafety()
        codec = Prompt27AContextCodec()
    }

    func policy(
        for context: Prompt27AUserReproductiveContext
    ) -> Prompt27AContextPolicyResult {
        policyEngine.policy(for: context)
    }
}

/// Human-facing copy for the presentation layer.
///
/// Policy-engine `reason` strings are intentionally implementation-facing. UI
/// surfaces use this helper instead so no internal architecture wording leaks
/// into the product and no context is converted into a medical conclusion.
nonisolated enum Prompt27AContextPresentationCopy {
    static func todayClarification(
        context: Prompt27AUserReproductiveContext,
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        let adapter = Prompt27AExistingSystemPolicyAdapter(result: policy)

        switch context.surrogacyContext.value {
        case .preparingForEmbryoTransfer:
            return "you told Fruitfolio you’re preparing for embryo transfer as a gestational carrier. your cycle data stays yours, and Fruitfolio does not treat preparation as proof of pregnancy or change prediction math."
        case .pregnantGestationalCarrier:
            return "you told Fruitfolio you’re currently pregnant as a gestational carrier. ordinary current-cycle predictions are hidden here, while anything you already logged stays saved."
        case .postpartumAfterSurrogatePregnancy:
            return "you told Fruitfolio you’re postpartum after a surrogate pregnancy. recovery and cycle-return context can be relevant here without assuming you’re parenting or caring for a newborn."
        case .preferNotToSpecify, .unspecified:
            break
        }

        switch context.reproductiveStage.value {
        case .pregnant:
            return "you told Fruitfolio you’re pregnant. ordinary current-cycle predictions are hidden here, while anything you already logged stays saved."
        case .menopause:
            return "you told Fruitfolio you’re in menopause. ordinary current-cycle predictions are hidden here, while your past cycle history stays available."
        case .postpartum:
            return "postpartum context can make ordinary cycle timing less predictable. Fruitfolio keeps estimates labeled as estimates and your logged observations separate."
        case .perimenopause:
            return "perimenopause context can come with more cycle variation. Fruitfolio keeps your own recorded data separate from estimates."
        case .cycling, .preferNotToSpecify, .unspecified:
            break
        }

        if context.lactationContext.value == .breastfeedingOrLactating {
            return "lactation does not tell Fruitfolio whether ovulation has resumed. any cycle timing shown here stays an estimate, not a confirmation."
        }

        if context.trackingGoal.value == .avoidingPregnancy {
            return "cycle estimates are not a contraceptive guarantee or a “safe day.” Fruitfolio keeps uncertainty visible instead of treating an estimate as certainty."
        }

        if adapter.isSurfaced(.predictionUncertainty) ||
            adapter.isClarified(.predictionUncertainty) {
            return "your context can make prediction limits especially relevant. Fruitfolio does not use it to increase prediction certainty."
        }

        return nil
    }

    static func calendarClarification(
        context: Prompt27AUserReproductiveContext,
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        let adapter = Prompt27AExistingSystemPolicyAdapter(result: policy)

        if context.reproductiveStage.value == .pregnant ||
            context.reproductiveStage.value == .menopause ||
            context.surrogacyContext.value == .pregnantGestationalCarrier {
            return "recorded history stays visible. ordinary current-cycle prediction overlays that are not presently applicable are hidden."
        }

        if adapter.isClarified(.calendar) ||
            adapter.isSurfaced(.predictionUncertainty) ||
            adapter.isClarified(.predictionUncertainty) {
            return "your context can change how useful an estimate is, but it never rewrites a day you actually logged."
        }

        return nil
    }

    static func hormoneClarification(
        context: Prompt27AUserReproductiveContext,
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        let adapter = Prompt27AExistingSystemPolicyAdapter(result: policy)

        guard adapter.isClarified(.hormoneRhythm) ||
                !adapter.showHormoneRhythmContextMarker else {
            return nil
        }

        switch context.contraceptionContext.value {
        case .hormonalContraception:
            return "this page still shows general natural-cycle education. the current-position marker is hidden because hormonal contraception changes how that reference should be interpreted."
        case .nonHormonalContraception, .none, .preferNotToSpecify, .unspecified:
            break
        }

        switch context.surrogacyContext.value {
        case .pregnantGestationalCarrier:
            return "this remains general natural-cycle education, not a picture of hormone levels during a gestational-carrier pregnancy. the current-position marker is hidden."
        case .postpartumAfterSurrogatePregnancy:
            return "this remains a general natural-cycle reference. postpartum-after-surrogacy context alone cannot establish where you are in an ovulatory cycle, so the current-position marker is hidden."
        case .preparingForEmbryoTransfer:
            return "this remains a general natural-cycle reference. preparing for embryo transfer does not let Fruitfolio infer your current hormone levels or change its prediction math."
        case .preferNotToSpecify, .unspecified:
            break
        }

        switch context.reproductiveStage.value {
        case .pregnant:
            return "this remains general natural-cycle education, not a picture of hormone levels during your pregnancy. the current-position marker is hidden."
        case .postpartum:
            return "this remains a general natural-cycle reference. postpartum context alone cannot establish where you are in an ovulatory cycle, so the current-position marker is hidden."
        case .menopause:
            return "this remains a general natural-cycle reference, not a measurement of your current hormones. the current-position marker is hidden."
        case .perimenopause:
            return "this is still a general natural-cycle reference, not a measurement or a claim that every cycle follows the same pattern."
        case .cycling, .preferNotToSpecify, .unspecified:
            break
        }

        if context.lactationContext.value == .breastfeedingOrLactating {
            return "this remains a general natural-cycle reference. lactation alone cannot establish current ovulation timing, so the current-position marker is hidden."
        }

        return "this page stays qualitative education rather than a measurement of your hormone levels."
    }

    static func dailyLogClarification(
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        let surfaced = policy.surfacedFeatures
        let relevant: Set<Prompt27AContextFeature> = [
            .bbtLogging,
            .cervicalFluidLogging,
            .medicationLogging,
            .treatmentNotes
        ]

        guard !surfaced.isDisjoint(with: relevant) else {
            return nil
        }

        return "your context only changes which logging tools are easier to reach. Fruitfolio never fills in an observation for you."
    }

    static func symptomsClarification(
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        guard policy[.symptoms].effect == .surface else {
            return nil
        }

        return "your context can make symptom logging easier to reach, but Fruitfolio will not label a symptom as being caused by a condition."
    }

    static func trendsClarification(
        policy: Prompt27AContextPolicyResult
    ) -> String? {
        let effect = policy[.trends].effect
        guard effect == .surface || effect == .clarify else {
            return nil
        }

        return "your reported context and Fruitfolio’s calculated patterns stay separate. Trends will not turn one into the other."
    }

    static func askDiscoveryQuestions(
        context: Prompt27AUserReproductiveContext,
        policy: Prompt27AContextPolicyResult
    ) -> [String] {
        let surfaced = policy.surfacedFeatures
        var questions: [String] = []

        if surfaced.contains(.pcosEducation) {
            questions.append("how can PCOS affect menstrual cycles?")
        }

        if surfaced.contains(.endometriosisEducation) {
            questions.append("what is endometriosis and what symptoms can occur?")
        }

        if surfaced.contains(.fertilityTreatmentEducation) {
            questions.append("what are the main types of fertility treatment?")
        } else if surfaced.contains(.fertilizationEducation) {
            questions.append("what happens from fertilization to the blastocyst stage?")
        }

        if surfaced.contains(.surrogacyEducation) {
            switch context.surrogacyContext.value {
            case .preparingForEmbryoTransfer:
                questions.append("what happens during preparation for a gestational-carrier embryo transfer?")
            case .pregnantGestationalCarrier:
                questions.append("what changes during a gestational-carrier pregnancy?")
            case .postpartumAfterSurrogatePregnancy:
                questions.append("what biological recovery changes are common after a surrogate pregnancy?")
            case .preferNotToSpecify, .unspecified:
                break
            }
        }

        if surfaced.contains(.pregnancyEducation) {
            questions.append("what happens during early pregnancy development?")
        }

        if surfaced.contains(.postpartumEducation) {
            questions.append("what biological changes are common postpartum?")
        }

        if surfaced.contains(.lactationEducation) {
            questions.append("how does lactation interact with menstrual-cycle return?")
        }

        if surfaced.contains(.perimenopauseEducation) {
            questions.append("how can menstrual cycles change during perimenopause?")
        }

        if surfaced.contains(.menopauseEducation) {
            questions.append("what changes biologically around menopause?")
        }

        if surfaced.contains(.contraceptionEducation) &&
            context.trackingGoal.value == .avoidingPregnancy {
            questions.append("why can’t a predicted fertile window guarantee a safe day?")
        }

        // Keep discovery compact and avoid turning context into a medical intake.
        return Array(questions.prefix(3))
    }
}
