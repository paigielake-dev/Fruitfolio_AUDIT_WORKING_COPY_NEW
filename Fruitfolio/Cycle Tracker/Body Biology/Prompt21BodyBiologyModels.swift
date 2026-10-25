import Foundation

nonisolated enum Prompt21BodyBiologyState: String, Codable, CaseIterable, Sendable {
    case neutral
    case follicularEarly
    case follicularLater
    case estimatedOvulation
    case luteal
    case menstruation
}

nonisolated enum Prompt21BodyBiologyContextKind: String, Codable, Sendable {
    case educational
    case calculated
    case estimated
}

nonisolated struct Prompt21BodyBiologyInput: Equatable, Sendable {
    let state: Prompt21BodyBiologyState
    let contextKind: Prompt21BodyBiologyContextKind
    let cycleDay: Int?
    let confirmedCycleDayOne: Bool
    let upstreamContextTitle: String
    let upstreamContextExplanation: String

    init(
        state: Prompt21BodyBiologyState,
        contextKind: Prompt21BodyBiologyContextKind,
        cycleDay: Int? = nil,
        confirmedCycleDayOne: Bool = false,
        upstreamContextTitle: String = "",
        upstreamContextExplanation: String = ""
    ) {
        self.state = state
        self.contextKind = contextKind
        self.cycleDay = cycleDay
        self.confirmedCycleDayOne = confirmedCycleDayOne
        self.upstreamContextTitle = upstreamContextTitle
        self.upstreamContextExplanation = upstreamContextExplanation
    }

    static let neutral = Prompt21BodyBiologyInput(
        state: .neutral,
        contextKind: .educational
    )
}

nonisolated struct Prompt21BodyBiologyPresentation: Equatable, Sendable {
    let state: Prompt21BodyBiologyState
    let title: String
    let body: String
    let heroAssetName: String
    let heroAccessibilityLabel: String
    let supportingAssetName: String?
    let supportingAccessibilityLabel: String?
    let showsBlueberryUncertainty: Bool
    let showsPeachDayOne: Bool
    let permitsOocyteDrift: Bool
    let permitsFimbriaeDetail: Bool

    init(
        state: Prompt21BodyBiologyState,
        title: String,
        body: String,
        heroAssetName: String,
        heroAccessibilityLabel: String,
        supportingAssetName: String? = nil,
        supportingAccessibilityLabel: String? = nil,
        showsBlueberryUncertainty: Bool = false,
        showsPeachDayOne: Bool = false,
        permitsOocyteDrift: Bool = false,
        permitsFimbriaeDetail: Bool = false
    ) {
        self.state = state
        self.title = title
        self.body = body
        self.heroAssetName = heroAssetName
        self.heroAccessibilityLabel = heroAccessibilityLabel
        self.supportingAssetName = supportingAssetName
        self.supportingAccessibilityLabel = supportingAccessibilityLabel
        self.showsBlueberryUncertainty = showsBlueberryUncertainty
        self.showsPeachDayOne = showsPeachDayOne
        self.permitsOocyteDrift = permitsOocyteDrift
        self.permitsFimbriaeDetail = permitsFimbriaeDetail
    }
}

nonisolated enum Prompt21BodyBiologyAsset {
    static let follicularEarly = "ovulation_follicle_stage_02"
    static let follicularLater = "ovulation_follicle_stage_04"
    static let ovulationRelease = "ovulation_follicle_release"
    static let matureOocyte = "ovulation_mature_oocyte"
    static let fimbriae = "ovulation_fimbriae"
    static let corpusLuteum = "ovulation_corpus_luteum"
    static let ovary = "ovulation_ovary"
    static let uterus = "menstruation_uterus"
    static let endometrium = "menstruation_endometrium_shedding"
    static let blueberry = "fruit_blueberry_friendly"
    static let peach = "fruit_peach_soft"
    static let sprout = "cycledecor_sprout"
}
