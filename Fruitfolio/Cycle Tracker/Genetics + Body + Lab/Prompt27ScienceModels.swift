import Foundation

enum Prompt27ScienceVisualFamily: String, Codable, CaseIterable, Sendable {
    case genetics
    case body
    case lab
    case other
    case none
}

enum Prompt27ScienceVisualPriority: String, Codable, Sendable {
    case primary
}

enum Prompt27ScientificReviewStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case reviewRequired = "review_required"
    case approved
    case deprecated

    var isProductionEligible: Bool {
        self == .approved
    }
}

enum Prompt27ScienceAssetID: String, Codable, CaseIterable, Sendable {
    // Genetics / molecular biology — exact physical files
    case geneticsProtein = "genetics_protein"
    case geneticsRNA = "genetics_rna"
    case geneticsReceptor = "genetics_receptor"
    case geneticsDNA = "genetics_dna"
    case geneticsChromosome = "genetics_chromosome"
    case geneticsCell = "genetics_cell"
    case geneticsCells = "genetics_cells"
    case geneticsMitochondrion = "genetics_mitochondrion"
    case geneticsNucleus = "genetics_nucleus"

    // Body / anatomy + physiology — exact physical files
    case bodyGutMicrobiome = "body_gut_microbiome"
    case bodyHeart = "body_heart"
    case bodyLiver = "body_liver"
    case bodyThyroid = "body_thyroid"
    case bodyStomach = "body_stomach"
    case bodySkin = "body_skin"
    case bodyBone = "body_bone"
    case bodyKidneys = "body_kidneys"
    case bodyMuscle = "body_muscle"

    // Lab / testing + diagnostics — exact physical files
    case labAgarPlate = "lab_agar_plate"
    case labCentrifuge = "lab_centrifuge"
    case labMicroscope = "lab_microscope"
    case labCollectionSwab = "lab_collection_swab"
    case labMicrocentrifugeTube = "lab_microcentrifuge_tube"
    case labTestTube = "lab_test_tube"
    case labTransferPipette = "lab_transfer_pipette"
    case labSpecimenCup = "lab_specimen_cup"

    var imageName: String {
        rawValue
    }

    var filename: String {
        rawValue + ".png"
    }
}

struct Prompt27ScienceConcept: RawRepresentable, Codable, Hashable, Sendable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.rawValue = value
    }

    static let dna: Self = "dna"
    static let rna: Self = "rna"
    static let chromosome: Self = "chromosome"
    static let protein: Self = "protein"
    static let receptor: Self = "receptor"
    static let cell: Self = "cell"
    static let cells: Self = "cells"
    static let mitochondrion: Self = "mitochondrion"
    static let nucleus: Self = "nucleus"

    static let gutMicrobiome: Self = "gut_microbiome"
    static let heart: Self = "heart"
    static let liver: Self = "liver"
    static let thyroid: Self = "thyroid"
    static let stomach: Self = "stomach"
    static let skin: Self = "skin"
    static let bone: Self = "bone"
    static let kidneys: Self = "kidneys"
    static let muscle: Self = "muscle"

    static let culture: Self = "culture"
    static let centrifugation: Self = "centrifugation"
    static let microscopy: Self = "microscopy"
    static let sampleCollection: Self = "sample_collection"
    static let pcrReactionSetup: Self = "pcr_reaction_setup"
    static let testTube: Self = "test_tube"
    static let liquidTransfer: Self = "liquid_transfer"
    static let specimenCollection: Self = "specimen_collection"
}

struct Prompt27ScientificAsset: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: Prompt27ScienceAssetID
    let family: Prompt27ScienceVisualFamily
    let concept: Prompt27ScienceConcept
    let version: Int
    let scientificReviewStatus: Prompt27ScientificReviewStatus
    let altText: String
    let hotspotMapID: String?
    let sourceReferenceIDs: [String]

    var filename: String {
        id.filename
    }

    var imageName: String {
        id.imageName
    }

    var isProductionEligible: Bool {
        scientificReviewStatus.isProductionEligible
    }
}

struct Prompt27ScienceHotspot: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: String
    let label: String
    let normalizedX: Double
    let normalizedY: Double
    let educationalContentID: String

    init(
        id: String,
        label: String,
        normalizedX: Double,
        normalizedY: Double,
        educationalContentID: String
    ) {
        self.id = id
        self.label = label
        self.normalizedX = min(max(normalizedX, 0), 1)
        self.normalizedY = min(max(normalizedY, 0), 1)
        self.educationalContentID = educationalContentID
    }
}

struct Prompt27ContextualScienceSection: Identifiable, Codable, Equatable, Sendable {
    let id: String
    let title: String
    let bodyContentID: String
    let primaryVisualFamily: Prompt27ScienceVisualFamily
    let primaryIllustrationAssetID: Prompt27ScienceAssetID?
    let visualPriority: Prompt27ScienceVisualPriority
    let hotspotIDs: [String]
    let relatedTopicIDs: [String]
    let sourceIDs: [String]
    let altText: String

    init(
        id: String,
        title: String,
        bodyContentID: String,
        primaryVisualFamily: Prompt27ScienceVisualFamily,
        primaryIllustrationAssetID: Prompt27ScienceAssetID?,
        visualPriority: Prompt27ScienceVisualPriority = .primary,
        hotspotIDs: [String] = [],
        relatedTopicIDs: [String] = [],
        sourceIDs: [String] = [],
        altText: String
    ) {
        self.id = id
        self.title = title
        self.bodyContentID = bodyContentID
        self.primaryVisualFamily = primaryVisualFamily
        self.primaryIllustrationAssetID = primaryIllustrationAssetID
        self.visualPriority = visualPriority
        self.hotspotIDs = hotspotIDs
        self.relatedTopicIDs = relatedTopicIDs
        self.sourceIDs = sourceIDs
        self.altText = altText
    }
}

struct Prompt27ScienceVisualRoute: Equatable, Sendable {
    let family: Prompt27ScienceVisualFamily
    let primaryAsset: Prompt27ScientificAsset?

    var majorIllustrationsVisible: Int {
        primaryAsset == nil ? 0 : 1
    }
}

enum Prompt27ScienceRoutingError: Error, Equatable, Sendable {
    case missingAsset(Prompt27ScienceAssetID)
    case unapprovedAsset(Prompt27ScienceAssetID)
    case familyMismatch(
        expected: Prompt27ScienceVisualFamily,
        actual: Prompt27ScienceVisualFamily
    )
    case assetNotAllowedForNoneContext
    case assetRequiredForVisualContext(Prompt27ScienceVisualFamily)
}

struct Prompt27ApprovedScienceContent: Equatable, Sendable {
    let contentID: String
    let title: String
    let body: String
    let sourceIDs: [String]

    init(
        contentID: String,
        title: String,
        body: String,
        sourceIDs: [String]
    ) {
        self.contentID = contentID
        self.title = title
        self.body = body
        self.sourceIDs = sourceIDs
    }
}

enum Prompt27ScienceLoadFailure: Error, Equatable, Sendable {
    case researchUnavailable
    case unsupportedContent
    case invalidApprovedContent
}
