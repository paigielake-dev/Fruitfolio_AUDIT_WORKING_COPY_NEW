import Foundation

nonisolated enum Prompt27AContextProvenance: String, Codable, Equatable, Sendable {
    case userReported = "user_reported"
}

nonisolated struct Prompt27AReportedValue<Value>: Codable, Equatable, Sendable where Value: Codable & Equatable & Sendable {
    var value: Value
    var provenance: Prompt27AContextProvenance
    var lastUpdated: Date

    init(
        value: Value,
        provenance: Prompt27AContextProvenance = .userReported,
        lastUpdated: Date = Date()
    ) {
        self.value = value
        self.provenance = provenance
        self.lastUpdated = lastUpdated
    }
}

nonisolated enum Prompt27ATrackingGoal: String, Codable, CaseIterable, Equatable, Sendable {
    case generalCycleTracking = "general_cycle_tracking"
    case tryingToConceive = "trying_to_conceive"
    case avoidingPregnancy = "avoiding_pregnancy"
    case noSpecificGoal = "no_specific_goal"
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .generalCycleTracking: return "general cycle tracking"
        case .tryingToConceive: return "trying to conceive"
        case .avoidingPregnancy: return "avoiding pregnancy"
        case .noSpecificGoal: return "no specific goal"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27ASexualActivityContext: String, Codable, CaseIterable, Equatable, Sendable {
    case sexuallyActive = "sexually_active"
    case notCurrentlySexuallyActive = "not_currently_sexually_active"
    case preferNotToSay = "prefer_not_to_say"
    case unspecified

    var displayName: String {
        switch self {
        case .sexuallyActive: return "sexually active"
        case .notCurrentlySexuallyActive: return "not currently sexually active"
        case .preferNotToSay: return "prefer not to say"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27AReproductiveStage: String, Codable, CaseIterable, Equatable, Sendable {
    case cycling
    case pregnant
    case postpartum
    case perimenopause
    case menopause
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .cycling: return "cycling"
        case .pregnant: return "pregnant"
        case .postpartum: return "postpartum"
        case .perimenopause: return "perimenopause"
        case .menopause: return "menopause"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}


nonisolated enum Prompt27ASurrogacyContext: String, Codable, CaseIterable, Equatable, Sendable {
    case preparingForEmbryoTransfer = "preparing_for_embryo_transfer"
    case pregnantGestationalCarrier = "pregnant_gestational_carrier"
    case postpartumAfterSurrogatePregnancy = "postpartum_after_surrogate_pregnancy"
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .preparingForEmbryoTransfer: return "preparing for embryo transfer"
        case .pregnantGestationalCarrier: return "currently pregnant as a gestational carrier"
        case .postpartumAfterSurrogatePregnancy: return "postpartum after a surrogate pregnancy"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27ALactationContext: String, Codable, CaseIterable, Equatable, Sendable {
    case breastfeedingOrLactating = "breastfeeding_or_lactating"
    case notCurrentlyBreastfeedingOrLactating = "not_currently_breastfeeding_or_lactating"
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .breastfeedingOrLactating: return "breastfeeding / lactating"
        case .notCurrentlyBreastfeedingOrLactating: return "not currently breastfeeding / lactating"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27ACycleHealthContext: String, Codable, CaseIterable, Hashable, Sendable {
    case pcos
    case endometriosis
    case irregularCycles = "irregular_cycles"

    var displayName: String {
        switch self {
        case .pcos: return "PCOS"
        case .endometriosis: return "endometriosis"
        case .irregularCycles: return "irregular cycles"
        }
    }
}

nonisolated enum Prompt27AInfertilityContext: String, Codable, CaseIterable, Equatable, Sendable {
    case userReportedInfertility = "user_reported_infertility"
    case notReported = "not_reported"
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .userReportedInfertility: return "I have been told I have infertility / I identify this as part of my health context"
        case .notReported: return "not part of my reported context"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27AFertilityTreatmentContext: String, Codable, CaseIterable, Equatable, Sendable {
    case currentlyUndergoing = "currently_undergoing"
    case notCurrentlyUndergoing = "not_currently_undergoing"
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .currentlyUndergoing: return "currently undergoing fertility treatment"
        case .notCurrentlyUndergoing: return "not currently undergoing fertility treatment"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated enum Prompt27AContraceptionContext: String, Codable, CaseIterable, Equatable, Sendable {
    case hormonalContraception = "hormonal_contraception"
    case nonHormonalContraception = "non_hormonal_contraception"
    case none
    case preferNotToSpecify = "prefer_not_to_specify"
    case unspecified

    var displayName: String {
        switch self {
        case .hormonalContraception: return "hormonal contraception"
        case .nonHormonalContraception: return "non-hormonal contraception"
        case .none: return "none"
        case .preferNotToSpecify: return "prefer not to specify"
        case .unspecified: return "unspecified"
        }
    }
}

nonisolated struct Prompt27AUserReproductiveContext: Codable, Equatable, Sendable {
    var personalHealthFields: [Prompt27AHealthField: Prompt27AHealthEntry] = [:]
    var trackingGoal: Prompt27AReportedValue<Prompt27ATrackingGoal>
    var sexualActivityContext: Prompt27AReportedValue<Prompt27ASexualActivityContext>
    var reproductiveStage: Prompt27AReportedValue<Prompt27AReproductiveStage>
    var surrogacyContext: Prompt27AReportedValue<Prompt27ASurrogacyContext>
    var lactationContext: Prompt27AReportedValue<Prompt27ALactationContext>
    var cycleHealthContexts: Set<Prompt27ACycleHealthContext>
    var cycleHealthContextsLastUpdated: Date
    var infertilityContext: Prompt27AReportedValue<Prompt27AInfertilityContext>
    var fertilityTreatmentContext: Prompt27AReportedValue<Prompt27AFertilityTreatmentContext>
    var contraceptionContext: Prompt27AReportedValue<Prompt27AContraceptionContext>

    init(
        trackingGoal: Prompt27ATrackingGoal = .unspecified,
        sexualActivityContext: Prompt27ASexualActivityContext = .unspecified,
        reproductiveStage: Prompt27AReproductiveStage = .unspecified,
        surrogacyContext: Prompt27ASurrogacyContext = .unspecified,
        lactationContext: Prompt27ALactationContext = .unspecified,
        cycleHealthContexts: Set<Prompt27ACycleHealthContext> = [],
        infertilityContext: Prompt27AInfertilityContext = .unspecified,
        fertilityTreatmentContext: Prompt27AFertilityTreatmentContext = .unspecified,
        contraceptionContext: Prompt27AContraceptionContext = .unspecified,
        timestamp: Date = Date()
    ) {
        self.trackingGoal = .init(value: trackingGoal, lastUpdated: timestamp)
        self.sexualActivityContext = .init(value: sexualActivityContext, lastUpdated: timestamp)
        self.reproductiveStage = .init(value: reproductiveStage, lastUpdated: timestamp)
        self.surrogacyContext = .init(value: surrogacyContext, lastUpdated: timestamp)
        self.lactationContext = .init(value: lactationContext, lastUpdated: timestamp)
        self.cycleHealthContexts = cycleHealthContexts
        self.cycleHealthContextsLastUpdated = timestamp
        self.infertilityContext = .init(value: infertilityContext, lastUpdated: timestamp)
        self.fertilityTreatmentContext = .init(value: fertilityTreatmentContext, lastUpdated: timestamp)
        self.contraceptionContext = .init(value: contraceptionContext, lastUpdated: timestamp)
    }

    static var unspecified: Self { .init() }

    var isCompletelyUnspecified: Bool {
        !personalHealthFields.values.contains(where: { $0.status == .supplied && !$0.text.isEmpty }) &&
        trackingGoal.value == .unspecified &&
        sexualActivityContext.value == .unspecified &&
        reproductiveStage.value == .unspecified &&
        surrogacyContext.value == .unspecified &&
        lactationContext.value == .unspecified &&
        cycleHealthContexts.isEmpty &&
        infertilityContext.value == .unspecified &&
        fertilityTreatmentContext.value == .unspecified &&
        contraceptionContext.value == .unspecified
    }

    mutating func setTrackingGoal(_ value: Prompt27ATrackingGoal, at date: Date = Date()) {
        trackingGoal = .init(value: value, lastUpdated: date)
    }

    mutating func setSexualActivityContext(_ value: Prompt27ASexualActivityContext, at date: Date = Date()) {
        sexualActivityContext = .init(value: value, lastUpdated: date)
    }

    mutating func setReproductiveStage(_ value: Prompt27AReproductiveStage, at date: Date = Date()) {
        reproductiveStage = .init(value: value, lastUpdated: date)
    }

    mutating func setSurrogacyContext(_ value: Prompt27ASurrogacyContext, at date: Date = Date()) {
        surrogacyContext = .init(value: value, lastUpdated: date)
    }

    mutating func setLactationContext(_ value: Prompt27ALactationContext, at date: Date = Date()) {
        lactationContext = .init(value: value, lastUpdated: date)
    }

    mutating func setCycleHealthContext(_ value: Prompt27ACycleHealthContext, selected: Bool, at date: Date = Date()) {
        if selected { cycleHealthContexts.insert(value) }
        else { cycleHealthContexts.remove(value) }
        cycleHealthContextsLastUpdated = date
    }

    mutating func setInfertilityContext(_ value: Prompt27AInfertilityContext, at date: Date = Date()) {
        infertilityContext = .init(value: value, lastUpdated: date)
    }

    mutating func setFertilityTreatmentContext(_ value: Prompt27AFertilityTreatmentContext, at date: Date = Date()) {
        fertilityTreatmentContext = .init(value: value, lastUpdated: date)
    }

    mutating func setContraceptionContext(_ value: Prompt27AContraceptionContext, at date: Date = Date()) {
        contraceptionContext = .init(value: value, lastUpdated: date)
    }

    mutating func clear(at date: Date = Date()) {
        self = .init(timestamp: date)
    }

    private enum CodingKeys: String, CodingKey {
        case personalHealthFields
        case trackingGoal
        case sexualActivityContext
        case reproductiveStage
        case surrogacyContext
        case lactationContext
        case cycleHealthContexts
        case cycleHealthContextsLastUpdated
        case infertilityContext
        case fertilityTreatmentContext
        case contraceptionContext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        personalHealthFields = try container.decodeIfPresent([Prompt27AHealthField: Prompt27AHealthEntry].self, forKey: .personalHealthFields) ?? [:]
        trackingGoal = try container.decode(
            Prompt27AReportedValue<Prompt27ATrackingGoal>.self,
            forKey: .trackingGoal
        )
        sexualActivityContext = try container.decode(
            Prompt27AReportedValue<Prompt27ASexualActivityContext>.self,
            forKey: .sexualActivityContext
        )
        reproductiveStage = try container.decode(
            Prompt27AReportedValue<Prompt27AReproductiveStage>.self,
            forKey: .reproductiveStage
        )

        if let storedSurrogacy = try container.decodeIfPresent(
            Prompt27AReportedValue<Prompt27ASurrogacyContext>.self,
            forKey: .surrogacyContext
        ) {
            surrogacyContext = storedSurrogacy
        } else {
            let fallbackDate = try container.decodeIfPresent(
                Date.self,
                forKey: .cycleHealthContextsLastUpdated
            ) ?? Date(timeIntervalSince1970: 0)
            surrogacyContext = .init(
                value: .unspecified,
                lastUpdated: fallbackDate
            )
        }

        lactationContext = try container.decode(
            Prompt27AReportedValue<Prompt27ALactationContext>.self,
            forKey: .lactationContext
        )
        cycleHealthContexts = try container.decode(
            Set<Prompt27ACycleHealthContext>.self,
            forKey: .cycleHealthContexts
        )
        cycleHealthContextsLastUpdated = try container.decode(
            Date.self,
            forKey: .cycleHealthContextsLastUpdated
        )
        infertilityContext = try container.decodeIfPresent(
            Prompt27AReportedValue<Prompt27AInfertilityContext>.self,
            forKey: .infertilityContext
        ) ?? .init(value: .unspecified, lastUpdated: cycleHealthContextsLastUpdated)
        fertilityTreatmentContext = try container.decode(
            Prompt27AReportedValue<Prompt27AFertilityTreatmentContext>.self,
            forKey: .fertilityTreatmentContext
        )
        contraceptionContext = try container.decode(
            Prompt27AReportedValue<Prompt27AContraceptionContext>.self,
            forKey: .contraceptionContext
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(personalHealthFields, forKey: .personalHealthFields)
        try container.encode(trackingGoal, forKey: .trackingGoal)
        try container.encode(sexualActivityContext, forKey: .sexualActivityContext)
        try container.encode(reproductiveStage, forKey: .reproductiveStage)
        try container.encode(surrogacyContext, forKey: .surrogacyContext)
        try container.encode(lactationContext, forKey: .lactationContext)
        try container.encode(cycleHealthContexts, forKey: .cycleHealthContexts)
        try container.encode(cycleHealthContextsLastUpdated, forKey: .cycleHealthContextsLastUpdated)
        try container.encode(infertilityContext, forKey: .infertilityContext)
        try container.encode(fertilityTreatmentContext, forKey: .fertilityTreatmentContext)
        try container.encode(contraceptionContext, forKey: .contraceptionContext)
    }
}

nonisolated enum Prompt27AInformationKind: String, Codable, Equatable, Sendable {
    case recorded
    case userReportedContext = "user_reported_context"
    case calculated
    case estimatedOrPredicted = "estimated_or_predicted"
    case educational
}

