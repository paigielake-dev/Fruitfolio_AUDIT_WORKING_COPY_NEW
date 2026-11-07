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

        var limitations: [String] = []
        func include(_ text: String) {
            if !limitations.contains(text) { limitations.append(text) }
        }

        switch context.surrogacyContext.value {
        case .preparingForEmbryoTransfer:
            include("you told Fruitfolio you’re preparing for embryo transfer as a gestational carrier. your cycle data stays yours, and Fruitfolio does not treat preparation as proof of pregnancy.")
        case .pregnantGestationalCarrier:
            include("you told Fruitfolio you’re currently pregnant as a gestational carrier. ordinary current-cycle predictions are hidden here, while anything you already logged stays saved.")
        case .postpartumAfterSurrogatePregnancy:
            include("you told Fruitfolio you’re postpartum after a surrogate pregnancy. recovery and cycle-return context can be relevant here without assuming you’re parenting or caring for a newborn.")
        case .preferNotToSpecify, .unspecified:
            break
        }

        switch context.reproductiveStage.value {
        case .pregnant where context.surrogacyContext.value != .pregnantGestationalCarrier:
            include("you told Fruitfolio you’re pregnant. ordinary current-cycle predictions are hidden here, while anything you already logged stays saved.")
        case .menopause:
            include("you told Fruitfolio you’re in menopause. ordinary current-cycle predictions are hidden here, while your past cycle history stays available.")
        case .postpartum where context.surrogacyContext.value != .postpartumAfterSurrogatePregnancy:
            include("postpartum context can make ordinary cycle timing less predictable. Fruitfolio keeps estimates labeled as estimates and your logged observations separate.")
        case .perimenopause:
            include("perimenopause context can come with more cycle variation. Fruitfolio keeps your own recorded data separate from estimates.")
        case .pregnant, .postpartum, .cycling, .preferNotToSpecify, .unspecified:
            break
        }

        if context.lactationContext.value == .breastfeedingOrLactating {
            include("lactation does not tell Fruitfolio whether ovulation has resumed. any cycle timing shown here stays an estimate, not a confirmation.")
        }

        if context.trackingGoal.value == .avoidingPregnancy {
            include("cycle estimates are not a contraceptive guarantee or a “safe day.” Fruitfolio keeps uncertainty visible instead of treating an estimate as certainty.")
        }

        if limitations.isEmpty && (adapter.isSurfaced(.predictionUncertainty) ||
            adapter.isClarified(.predictionUncertainty)) {
            include("your context can make prediction limits especially relevant. Fruitfolio does not use it to increase prediction certainty.")
        }

        return limitations.isEmpty ? nil : limitations.joined(separator: "\n\n")
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

/// Ephemeral descriptions of supplied history, not inferred biological events.
/// Private notes and medication names never enter this projection.
nonisolated struct Prompt27AObservedCycleFacts: Codable, Hashable, Sendable {
    let enteredPeriodStartCount: Int?
    let recentCompletedCycleLengths: [Int]
    let recordedLogCount: Int?
    let recordedBasalTemperatureCount: Int?
    let recordedCervicalFluidCount: Int?
    let recordedSymptomCounts: [String: Int]
    let historyIdentity: String

    static let unknown = Self(prediction: nil, dailyLogs: nil)

    init(prediction: Prompt17CyclePredictionResult?, dailyLogs: [Prompt20DailyLog]?, ownerID: Prompt20DailyLogOwnerID = .localDevice) {
        enteredPeriodStartCount = prediction?.normalizedCycleStartDates.count
        recentCompletedCycleLengths = Array(prediction?.recentCycleLengths.suffix(12) ?? [])
        let logs = dailyLogs?.filter { !$0.isDeleted && $0.ownerID == ownerID }
        recordedLogCount = logs?.count
        recordedBasalTemperatureCount = logs?.filter { $0.temperature?.readingType == .basalWaking }.count
        recordedCervicalFluidCount = logs?.filter { $0.cervicalFluid != nil }.count
        var symptoms: [String: Int] = [:]
        for log in logs ?? [] {
            for id in log.symptoms?.selectedIDs ?? [] { symptoms[id.rawValue, default: 0] += 1 }
        }
        recordedSymptomCounts = symptoms
        var identity = Hasher()
        identity.combine(prediction?.historyVersion)
        for log in (logs ?? []).sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            identity.combine(log.id); identity.combine(log.revision); identity.combine(log.updatedAt)
        }
        historyIdentity = String(identity.finalize()) // ephemeral, never persisted or supplied to the model
    }

    /// Counts of saved selections, not symptom frequency in unlogged time,
    /// severity, a medical finding, or evidence that a condition caused them.
    var reportedSymptoms: [Prompt27ARecordedSymptomCount] {
        Prompt20SymptomID.allCases.compactMap { symptom in
            guard let count = recordedSymptomCounts[symptom.rawValue], count > 0 else { return nil }
            return .init(symptom: symptom, logCount: count)
        }
    }

    func promptJSON() throws -> String {
        struct Payload: Encodable {
            let enteredPeriodStartCount: Int?
            let recentCompletedCycleLengths: [Int]
            let recordedLogCount: Int?
            let recordedBasalTemperatureCount: Int?
            let recordedCervicalFluidCount: Int?
            let recordedSymptomCounts: [String: Int]
        }
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(Payload(enteredPeriodStartCount: enteredPeriodStartCount,
            recentCompletedCycleLengths: recentCompletedCycleLengths, recordedLogCount: recordedLogCount,
            recordedBasalTemperatureCount: recordedBasalTemperatureCount,
            recordedCervicalFluidCount: recordedCervicalFluidCount, recordedSymptomCounts: recordedSymptomCounts)), as: UTF8.self)
    }
}

nonisolated struct Prompt27ARecordedSymptomCount: Identifiable, Sendable {
    let symptom: Prompt20SymptomID
    let logCount: Int
    var id: String { symptom.rawValue }
}

nonisolated struct Prompt27AContextResearchTopic: Equatable, Sendable, Identifiable {
    let id: String
    let reportedTitle: String
    let reportedValue: String
    let question: String?
    var personalCategory: FruitfolioPersonalHealthCategory? = nil
}

/// Planning uses explicit choices/category metadata, never diagnoses parsed from
/// narrative, names, symptoms, dates or laboratory values.
nonisolated enum Prompt27AContextResearchPlan {
    static func topics(for context: Prompt27AUserReproductiveContext) -> [Prompt27AContextResearchTopic] {
        var result: [Prompt27AContextResearchTopic] = []
        func add(_ id: String, _ title: String, _ value: String, _ question: String) {
            result.append(.init(id: id, reportedTitle: title, reportedValue: value, question: question))
        }
        switch context.trackingGoal.value {
        case .tryingToConceive: add("goal", "tracking goal", context.trackingGoal.value.displayName, "what can menstrual cycle estimates show when trying to conceive, and what are their limitations?")
        case .avoidingPregnancy: add("goal", "tracking goal", context.trackingGoal.value.displayName, "why can a predicted fertile window not guarantee contraception or a safe day?")
        case .generalCycleTracking, .noSpecificGoal: add("goal", "tracking goal", context.trackingGoal.value.displayName, "what can recorded menstrual cycle lengths show, and what remains uncertain?")
        case .preferNotToSpecify, .unspecified: break
        }
        switch context.sexualActivityContext.value {
        case .sexuallyActive, .notCurrentlySexuallyActive:
            result.append(.init(id: "sexualActivity", reportedTitle: "sexual activity context",
                reportedValue: context.sexualActivityContext.value.displayName, question: nil))
        case .preferNotToSay, .unspecified: break
        }
        switch context.reproductiveStage.value {
        case .pregnant: add("stage", "reproductive stage", context.reproductiveStage.value.displayName, "how does pregnancy affect menstrual cycles and ovulation?")
        case .postpartum: add("stage", "reproductive stage", context.reproductiveStage.value.displayName, "what biological changes can affect menstrual cycle return postpartum?")
        case .perimenopause: add("stage", "reproductive stage", context.reproductiveStage.value.displayName, "how can menstrual cycles change during perimenopause?")
        case .menopause: add("stage", "reproductive stage", context.reproductiveStage.value.displayName, "how does menopause affect menstrual cycles and ovulation?")
        case .cycling: add("stage", "reproductive stage", context.reproductiveStage.value.displayName, "what variation can occur in menstrual cycle lengths?")
        case .preferNotToSpecify, .unspecified: break
        }
        for health in context.cycleHealthContexts.sorted(by: { $0.rawValue < $1.rawValue }) {
            let question: String
            switch health {
            case .pcos: question = "how can PCOS be associated with irregular menstrual cycles?"
            case .endometriosis: question = "what is endometriosis and how can it relate to menstrual symptoms?"
            case .irregularCycles: question = "what can cause variation in menstrual cycle lengths, and what are prediction limitations?"
            }
            add("health." + health.rawValue, "cycle health context", health.displayName, question)
        }
        if context.lactationContext.value == .breastfeedingOrLactating {
            add("lactation", "lactation context", context.lactationContext.value.displayName, "how can lactation relate to menstrual cycle return and ovulation?")
        }
        if context.lactationContext.value == .notCurrentlyBreastfeedingOrLactating {
            result.append(.init(id: "lactation", reportedTitle: "lactation context",
                reportedValue: context.lactationContext.value.displayName, question: nil))
        }
        if context.infertilityContext.value == .notReported {
            result.append(.init(id: "infertility", reportedTitle: "fertility history",
                reportedValue: context.infertilityContext.value.displayName, question: nil))
        }
        if context.fertilityTreatmentContext.value == .notCurrentlyUndergoing {
            result.append(.init(id: "treatment", reportedTitle: "fertility treatment context",
                reportedValue: context.fertilityTreatmentContext.value.displayName, question: nil))
        }
        if context.infertilityContext.value == .userReportedInfertility {
            add("infertility", "fertility history", context.infertilityContext.value.displayName, "what does infertility mean, and what cannot be established by menstrual cycle tracking alone?")
        }
        if context.fertilityTreatmentContext.value == .currentlyUndergoing {
            add("treatment", "fertility treatment context", context.fertilityTreatmentContext.value.displayName, "what are the main types of fertility treatment and how can treatment affect menstrual cycles?")
        }
        switch context.contraceptionContext.value {
        case .hormonalContraception: add("contraception", "contraception context", context.contraceptionContext.value.displayName, "how can hormonal contraception affect bleeding and ovulation?")
        case .nonHormonalContraception: add("contraception", "contraception context", context.contraceptionContext.value.displayName, "what are non-hormonal contraception methods and their limitations?")
        case .none:
            result.append(.init(id: "contraception", reportedTitle: "contraception context",
                reportedValue: context.contraceptionContext.value.displayName, question: nil))
        case .preferNotToSpecify, .unspecified: break
        }
        switch context.surrogacyContext.value {
        case .preparingForEmbryoTransfer: add("surrogacy", "gestational carrier context", context.surrogacyContext.value.displayName, "what happens during gestational carrier embryo transfer preparation?")
        case .pregnantGestationalCarrier: add("surrogacy", "gestational carrier context", context.surrogacyContext.value.displayName, "what biological changes occur during a gestational carrier pregnancy?")
        case .postpartumAfterSurrogatePregnancy: add("surrogacy", "gestational carrier context", context.surrogacyContext.value.displayName, "what biological recovery changes can occur after a surrogate pregnancy, without assuming parenting?")
        case .preferNotToSpecify, .unspecified: break
        }
        for category in FruitfolioPersonalHealthCategory.allCases {
            guard let entry = context.personalHealthEntries[category.rawValue], entry.status == .provided,
                  entry.text != nil else { continue }
            result.append(.init(id: "personal." + category.rawValue, reportedTitle: category.title,
                reportedValue: entry.provenance.label,
                question: "what approved research relates \(category.title) to menstrual cycle patterns, and what remains unknown?",
                personalCategory: category))
        }
        return result
    }
}

extension Prompt27AContextResearchPlan {
    /// Education requests follow actual recorded evidence, never a diagnosed
    /// pattern or a fabricated biological event. Unknown history adds no topic.
    static func topics(forObservedFacts facts: Prompt27AObservedCycleFacts) -> [Prompt27AContextResearchTopic] {
        var result: [Prompt27AContextResearchTopic] = []
        func include(_ id: String, _ title: String, _ question: String) {
            result.append(.init(id: "logs." + id, reportedTitle: title,
                reportedValue: "recorded history on this device", question: question))
        }
        if let starts = facts.enteredPeriodStartCount, starts < 2 {
            include("limitedStarts", "limited supplied period-start history",
                "what can a menstrual period estimate establish with insufficient recorded cycle history, and what remains unknown?")
        }
        if Set(facts.recentCompletedCycleLengths).count > 1 {
            include("cycleLengthDifferences", "differences between calculated cycle lengths",
                "what approved research explains differences between menstrual cycle lengths, without diagnosing a condition from differences alone?")
        }
        if (facts.recordedBasalTemperatureCount ?? 0) > 0 {
            include("basalTemperature", "recorded basal-temperature selections",
                "what can recorded basal body temperature observations show, and why must an isolated reading not be treated as confirmed ovulation?")
        }
        if (facts.recordedCervicalFluidCount ?? 0) > 0 {
            include("cervicalFluid", "recorded cervical-fluid selections",
                "how should recorded cervical fluid selections be understood without treating a log entry as confirmed ovulation or fertility?")
        }
        for selection in facts.reportedSymptoms {
            include("selection." + selection.symptom.rawValue,
                "recorded " + selection.symptom.displayName + " selections",
                "what approved research relates " + selection.symptom.displayName +
                    " to menstrual cycles, without inferring a cause or biological event from a saved selection?")
        }
        return result
    }
}

nonisolated struct Prompt27AContextResearchItem: Identifiable, Sendable {
    enum Unavailable: Sendable { case contextTooLarge, missingResearch, requestFailed, noBiologicalInference, narrativeNeedsValidatedModel }
    let topic: Prompt27AContextResearchTopic
    let answer: AskAnswer?
    let unavailable: Unavailable?
    var id: String { topic.id }
}

/// Never Codable/persisted. A caller must discard it on context/history changes
/// and presentation loss; sources remain the canonical engine's verified records.
nonisolated struct Prompt27AContextResearchReport: Sendable {
    let context: Prompt27AUserReproductiveContext
    let observedFacts: Prompt27AObservedCycleFacts
    let items: [Prompt27AContextResearchItem]
    let isComplete: Bool

    /// App presentation decisions, distinct from research-supported biological
    /// associations. Computed from this report's exact context snapshot only.
    var presentationPolicy: Prompt27AContextPolicyResult {
        Prompt27AContextPolicyEngine().policy(for: context)
    }
    var presentationClarification: String? {
        Prompt27AContextPresentationCopy.todayClarification(context: context, policy: presentationPolicy)
    }
    var presentationDecisions: [Prompt27AContextDisplayDecision] {
        let policy = presentationPolicy
        return [Prompt27AContextFeature.nextPeriodPrediction, .fertileWindowPrediction, .ovulationPrediction,
                .hormoneRhythmContextMarker].map { feature in
            .init(feature: feature, effect: policy[feature].effect)
        }
    }
    init(context: Prompt27AUserReproductiveContext, observedFacts: Prompt27AObservedCycleFacts,
         items: [Prompt27AContextResearchItem], isComplete: Bool = true) {
        self.context = context; self.observedFacts = observedFacts
        self.items = items; self.isComplete = isComplete
    }
}

nonisolated struct Prompt27AContextDisplayDecision: Identifiable, Sendable {
    let feature: Prompt27AContextFeature
    let effect: Prompt27AContextPolicyEffect
    var id: String { feature.rawValue }
    var title: String {
        switch feature {
        case .nextPeriodPrediction: return "period estimates"
        case .fertileWindowPrediction: return "fertile-window estimates"
        case .ovulationPrediction: return "ovulation estimates"
        case .hormoneRhythmContextMarker: return "natural-cycle position marker"
        default: return "context-dependent presentation"
        }
    }
    var explanation: String {
        switch effect {
        case .suppress: return "hidden for your reported context. your saved observations are kept."
        case .clarify: return "context-specific caution applies. this is not confirmation of a biological event."
        case .surface, .unchanged: return "not hidden by context. recorded-history and other eligibility requirements still apply."
        }
    }
}

@MainActor
final class Prompt27AContextResearchService {
    private let engine: FruitfolioResearchIntelligenceEngine
    init(engine: FruitfolioResearchIntelligenceEngine? = nil) {
        self.engine = engine ?? .shared
    }

    func explain(context: Prompt27AUserReproductiveContext,
                 observedFacts: Prompt27AObservedCycleFacts,
                 previous: Prompt27AContextResearchReport? = nil,
                 progress: (@MainActor (Prompt27AContextResearchReport) -> Void)? = nil) async throws -> Prompt27AContextResearchReport {
        try Task.checkCancellation()
        let topics = Prompt27AContextResearchPlan.topics(for: context)
            + Prompt27AContextResearchPlan.topics(forObservedFacts: observedFacts)
        var items = previous.flatMap { $0.context == context && $0.observedFacts == observedFacts ? $0.items : nil } ?? []
        let completed = Set(items.map(\.id))
        func publish() {
            progress?(.init(context: context, observedFacts: observedFacts, items: items, isComplete: false))
        }
        publish()
        let tracker = FruitfolioBoundedTrackerContext(predictionConfidence: nil,
            reasonCode: "reported_context_education_not_diagnostic",
            trackingGoal: context.trackingGoal.value.rawValue,
            reproductiveStage: context.reproductiveStage.value.rawValue,
            cycleHealthContext: context.cycleHealthContexts.map(\.rawValue).sorted().joined(separator: ","),
            observedCycleFacts: observedFacts)
        for topic in topics where !completed.contains(topic.id) {
            try Task.checkCancellation()
            defer { if !Task.isCancelled { publish() } }
            guard let question = topic.question else {
                items.append(.init(topic: topic, answer: nil, unavailable: .noBiologicalInference))
                continue
            }
            let userContext: FruitfolioAskUserContext?
            do {
                userContext = try topic.personalCategory.flatMap { category in
                    try FruitfolioAskUserContext.selected(measurementIDs: [], personalCategories: [category],
                        measurements: [], context: context)
                }
            } catch {
                items.append(.init(topic: topic, answer: nil, unavailable: .contextTooLarge))
                continue // Never truncate qualifiers or silently use an oversized narrative.
            }
            do {
                let answer = try await engine.answer(question: question, conversation: [],
                    trackerContext: tracker, userContext: userContext, progress: nil)
                try Task.checkCancellation()
                guard !answer.isDevelopmentPreview, !answer.sources.isEmpty, !answer.sourceIDs.isEmpty,
                      answer.answerPath == .generated || answer.answerPath == .retrievalFallback else {
                    items.append(.init(topic: topic, answer: nil, unavailable: .missingResearch))
                    continue
                }
                if topic.personalCategory != nil && answer.answerPath != .generated {
                    // A generic retrieval match does not interpret a narrative.
                    // The default model must select/validate its evidence first.
                    items.append(.init(topic: topic, answer: nil, unavailable: .narrativeNeedsValidatedModel))
                    continue
                }
                items.append(.init(topic: topic, answer: answer, unavailable: nil))
            } catch is CancellationError { throw CancellationError() }
            catch {
                try Task.checkCancellation()
                items.append(.init(topic: topic, answer: nil, unavailable: .requestFailed))
            }
        }
        try Task.checkCancellation()
        return .init(context: context, observedFacts: observedFacts, items: items)
    }
}
