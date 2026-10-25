import Foundation

// MARK: - Prompt 25 / Phase 25
// Fertilization Education is educational-only. Nothing in this model represents
// the user's current biological state.

nonisolated enum Prompt25FertilizationStageID: String, CaseIterable, Codable, Sendable, Identifiable {
    case oocyte
    case fertilization
    case twoCell = "two_cell"
    case fourCell = "four_cell"
    case morula
    case blastocyst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oocyte: "oocyte"
        case .fertilization: "fertilization"
        case .twoCell: "2-cell"
        case .fourCell: "4-cell"
        case .morula: "morula"
        case .blastocyst: "blastocyst"
        }
    }

    var ordinal: Int {
        switch self {
        case .oocyte: 1
        case .fertilization: 2
        case .twoCell: 3
        case .fourCell: 4
        case .morula: 5
        case .blastocyst: 6
        }
    }

    var indicatorText: String {
        String(format: "%02d / 06", ordinal)
    }
}

nonisolated enum Prompt25FertilizationSemanticState: String, Codable, Sendable {
    case educational
}

nonisolated enum Prompt25FertilizationAssetID: String, CaseIterable, Codable, Sendable {
    // Primary plate for the oocyte stage comes from the existing Ovulation
    // biology library because the supplied Fertilization folder does not
    // contain a standalone oocyte file.
    case oocyte = "ovulation_mature_oocyte"

    // Exact physical Fertilization asset stems.
    case sperm = "fertilization_sperm"
    case spermOocyte = "fertilization_sperm_oocyte"
    case zygote = "fertilization_zygote"
    case embryoTwoCell = "fertilization_embryo_2_cell"
    case embryoFourCell = "fertilization_embryo_4_cell"
    case embryoEightCell = "fertilization_embryo_8_cell"
    case morula = "fertilization_morula"
    case blastocyst = "fertilization_blastocyst"
    case implantationUterus = "fertilization_implantation_uterus"

    var imageName: String { rawValue }
}

nonisolated enum Prompt25AuxiliaryArtRole: String, Codable, Sendable {
    case learnMore
    case relatedTopic
}

nonisolated struct Prompt25AuxiliaryArt: Identifiable, Equatable, Sendable {
    let assetID: Prompt25FertilizationAssetID
    let role: Prompt25AuxiliaryArtRole
    let accessibilityLabel: String

    var id: String {
        "\(assetID.rawValue)-\(role.rawValue)"
    }
}

nonisolated struct Prompt25FertilizationStage: Identifiable, Equatable, Sendable {
    let id: Prompt25FertilizationStageID
    let semanticState: Prompt25FertilizationSemanticState
    let primaryAssetID: Prompt25FertilizationAssetID
    let shortContentID: String
    let expandedContentID: String
    let sourceCollectionID: String
    let accessibilityLabel: String
    let auxiliaryArt: [Prompt25AuxiliaryArt]

    var order: Int { id.ordinal }
    var title: String { id.title }
    var indicatorText: String { id.indicatorText }
}

nonisolated enum Prompt25FertilizationSequence {
    static let stages: [Prompt25FertilizationStage] = [
        Prompt25FertilizationStage(
            id: .oocyte,
            semanticState: .educational,
            primaryAssetID: .oocyte,
            shortContentID: "fertilization.oocyte.short",
            expandedContentID: "fertilization.oocyte.expanded",
            sourceCollectionID: "fertilization.oocyte.sources",
            accessibilityLabel:
                "Watercolor scientific illustration of a human oocyte and its surrounding cellular layers.",
            auxiliaryArt: []
        ),
        Prompt25FertilizationStage(
            id: .fertilization,
            semanticState: .educational,
            primaryAssetID: .spermOocyte,
            shortContentID: "fertilization.fertilization.short",
            expandedContentID: "fertilization.fertilization.expanded",
            sourceCollectionID: "fertilization.fertilization.sources",
            accessibilityLabel:
                "Watercolor scientific illustration showing sperm around a human oocyte during fertilization education.",
            auxiliaryArt: [
                Prompt25AuxiliaryArt(
                    assetID: .sperm,
                    role: .learnMore,
                    accessibilityLabel:
                        "Watercolor scientific illustration of a human sperm cell."
                ),
                Prompt25AuxiliaryArt(
                    assetID: .zygote,
                    role: .learnMore,
                    accessibilityLabel:
                        "Watercolor scientific illustration of a fertilized single-cell developmental stage."
                )
            ]
        ),
        Prompt25FertilizationStage(
            id: .twoCell,
            semanticState: .educational,
            primaryAssetID: .embryoTwoCell,
            shortContentID: "fertilization.two_cell.short",
            expandedContentID: "fertilization.two_cell.expanded",
            sourceCollectionID: "fertilization.two_cell.sources",
            accessibilityLabel:
                "Watercolor scientific illustration of an early embryo at the two-cell cleavage stage.",
            auxiliaryArt: []
        ),
        Prompt25FertilizationStage(
            id: .fourCell,
            semanticState: .educational,
            primaryAssetID: .embryoFourCell,
            shortContentID: "fertilization.four_cell.short",
            expandedContentID: "fertilization.four_cell.expanded",
            sourceCollectionID: "fertilization.four_cell.sources",
            accessibilityLabel:
                "Watercolor scientific illustration of an early embryo at the four-cell cleavage stage.",
            auxiliaryArt: [
                Prompt25AuxiliaryArt(
                    assetID: .embryoEightCell,
                    role: .learnMore,
                    accessibilityLabel:
                        "Watercolor scientific illustration of an early embryo at the eight-cell cleavage stage."
                )
            ]
        ),
        Prompt25FertilizationStage(
            id: .morula,
            semanticState: .educational,
            primaryAssetID: .morula,
            shortContentID: "fertilization.morula.short",
            expandedContentID: "fertilization.morula.expanded",
            sourceCollectionID: "fertilization.morula.sources",
            accessibilityLabel:
                "Watercolor scientific illustration of a compact multicellular morula.",
            auxiliaryArt: []
        ),
        Prompt25FertilizationStage(
            id: .blastocyst,
            semanticState: .educational,
            primaryAssetID: .blastocyst,
            shortContentID: "fertilization.blastocyst.short",
            expandedContentID: "fertilization.blastocyst.expanded",
            sourceCollectionID: "fertilization.blastocyst.sources",
            accessibilityLabel:
                "Watercolor scientific illustration of a blastocyst showing its internal cellular organization.",
            auxiliaryArt: [
                Prompt25AuxiliaryArt(
                    assetID: .implantationUterus,
                    role: .relatedTopic,
                    accessibilityLabel:
                        "Watercolor educational illustration of a uterus with an implantation-related highlight."
                )
            ]
        )
    ]

    static func stage(for id: Prompt25FertilizationStageID) -> Prompt25FertilizationStage {
        stages.first(where: { $0.id == id }) ?? stages[0]
    }

    static func index(of id: Prompt25FertilizationStageID) -> Int {
        stages.firstIndex(where: { $0.id == id }) ?? 0
    }

    static func previous(from id: Prompt25FertilizationStageID) -> Prompt25FertilizationStageID? {
        let index = index(of: id)
        guard index > 0 else { return nil }
        return stages[index - 1].id
    }

    static func next(from id: Prompt25FertilizationStageID) -> Prompt25FertilizationStageID? {
        let index = index(of: id)
        guard index + 1 < stages.count else { return nil }
        return stages[index + 1].id
    }
}

nonisolated struct Prompt25EducationalContent: Equatable, Sendable {
    let shortText: String
    let expandedSections: [Prompt25EducationalSection]
    let sourceCount: Int
    let isApproved: Bool

    static let unavailable = Prompt25EducationalContent(
        shortText:
            "approved educational content isn’t available right now.",
        expandedSections: [],
        sourceCount: 0,
        isApproved: false
    )
}

nonisolated struct Prompt25EducationalSection: Identifiable, Equatable, Sendable {
    let id: String
    let heading: String
    let body: String
}

nonisolated enum Prompt25RelatedTopic: String, CaseIterable, Identifiable, Sendable {
    case implantation
    case ovulation
    case reproductiveAnatomy = "reproductive_anatomy"
    case menstrualCycleBiology = "menstrual_cycle_biology"
    case earlyPregnancyBiology = "early_pregnancy_biology"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .implantation: "implantation"
        case .ovulation: "ovulation"
        case .reproductiveAnatomy: "reproductive anatomy"
        case .menstrualCycleBiology: "menstrual cycle biology"
        case .earlyPregnancyBiology: "early pregnancy biology"
        }
    }
}
