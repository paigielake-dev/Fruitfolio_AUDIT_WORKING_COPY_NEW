import Foundation

struct Prompt27ScientificAssetCatalog: Sendable {
    private let assetsByID: [Prompt27ScienceAssetID: Prompt27ScientificAsset]

    init(assets: [Prompt27ScientificAsset] = Self.canonicalAssets) {
        var dictionary: [Prompt27ScienceAssetID: Prompt27ScientificAsset] = [:]
        for asset in assets {
            guard dictionary[asset.id] == nil else { continue }
            dictionary[asset.id] = asset
        }
        assetsByID = dictionary
    }

    func asset(for id: Prompt27ScienceAssetID) -> Prompt27ScientificAsset? {
        assetsByID[id]
    }

    var allAssets: [Prompt27ScientificAsset] {
        Prompt27ScienceAssetID.allCases.compactMap { assetsByID[$0] }
    }

    var allAssetIDs: Set<Prompt27ScienceAssetID> {
        Set(assetsByID.keys)
    }

    var productionAssets: [Prompt27ScientificAsset] {
        allAssets.filter(\.isProductionEligible)
    }

    static let canonicalAssets: [Prompt27ScientificAsset] = [
        // Genetics
        .init(
            id: .geneticsProtein,
            family: .genetics,
            concept: .protein,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a protein.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsRNA,
            family: .genetics,
            concept: .rna,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration representing RNA.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsReceptor,
            family: .genetics,
            concept: .receptor,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a cellular receptor.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsDNA,
            family: .genetics,
            concept: .dna,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of DNA.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsChromosome,
            family: .genetics,
            concept: .chromosome,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a chromosome.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsCell,
            family: .genetics,
            concept: .cell,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a cell.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsCells,
            family: .genetics,
            concept: .cells,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of multiple cells.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsMitochondrion,
            family: .genetics,
            concept: .mitochondrion,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a mitochondrion.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .geneticsNucleus,
            family: .genetics,
            concept: .nucleus,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a cell nucleus.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),

        // Body
        .init(
            id: .bodyGutMicrobiome,
            family: .body,
            concept: .gutMicrobiome,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration representing the gut microbiome.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyHeart,
            family: .body,
            concept: .heart,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of the heart.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyLiver,
            family: .body,
            concept: .liver,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of the liver.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyThyroid,
            family: .body,
            concept: .thyroid,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of the thyroid gland.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyStomach,
            family: .body,
            concept: .stomach,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of the stomach.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodySkin,
            family: .body,
            concept: .skin,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration representing skin.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyBone,
            family: .body,
            concept: .bone,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration representing bone.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyKidneys,
            family: .body,
            concept: .kidneys,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of the kidneys.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .bodyMuscle,
            family: .body,
            concept: .muscle,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration representing muscle.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),

        // Lab
        .init(
            id: .labAgarPlate,
            family: .lab,
            concept: .culture,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of an agar plate.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labCentrifuge,
            family: .lab,
            concept: .centrifugation,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a laboratory centrifuge.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labMicroscope,
            family: .lab,
            concept: .microscopy,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a microscope.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labCollectionSwab,
            family: .lab,
            concept: .sampleCollection,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a specimen collection swab.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labMicrocentrifugeTube,
            family: .lab,
            concept: .pcrReactionSetup,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a microcentrifuge reaction tube used in laboratory workflows such as PCR setup.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labTestTube,
            family: .lab,
            concept: .testTube,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a laboratory test tube.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labTransferPipette,
            family: .lab,
            concept: .liquidTransfer,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a transfer pipette.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        ),
        .init(
            id: .labSpecimenCup,
            family: .lab,
            concept: .specimenCollection,
            version: 1,
            scientificReviewStatus: .approved,
            altText: "Watercolor educational illustration of a specimen collection cup.",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        )
    ]
}
