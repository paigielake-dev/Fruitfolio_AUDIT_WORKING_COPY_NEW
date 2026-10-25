import Foundation

enum Prompt27ScienceAssetAudit {
    static let expectedGeneticsAssetIDs: Set<Prompt27ScienceAssetID> = [
        .geneticsProtein,
        .geneticsRNA,
        .geneticsReceptor,
        .geneticsDNA,
        .geneticsChromosome,
        .geneticsCell,
        .geneticsCells,
        .geneticsMitochondrion,
        .geneticsNucleus
    ]

    static let expectedBodyAssetIDs: Set<Prompt27ScienceAssetID> = [
        .bodyGutMicrobiome,
        .bodyHeart,
        .bodyLiver,
        .bodyThyroid,
        .bodyStomach,
        .bodySkin,
        .bodyBone,
        .bodyKidneys,
        .bodyMuscle
    ]

    static let expectedLabAssetIDs: Set<Prompt27ScienceAssetID> = [
        .labAgarPlate,
        .labCentrifuge,
        .labMicroscope,
        .labCollectionSwab,
        .labMicrocentrifugeTube,
        .labTestTube,
        .labTransferPipette,
        .labSpecimenCup
    ]

    static let expectedAllAssetIDs: Set<Prompt27ScienceAssetID> =
        expectedGeneticsAssetIDs
        .union(expectedBodyAssetIDs)
        .union(expectedLabAssetIDs)

    static let expectedFilenames: Set<String> = Set(
        expectedAllAssetIDs.map(\.filename)
    )

    static func missingAssetIDs(
        in catalog: Prompt27ScientificAssetCatalog
    ) -> Set<Prompt27ScienceAssetID> {
        expectedAllAssetIDs.subtracting(catalog.allAssetIDs)
    }

    static func unexpectedAssetIDs(
        in catalog: Prompt27ScientificAssetCatalog
    ) -> Set<Prompt27ScienceAssetID> {
        catalog.allAssetIDs.subtracting(expectedAllAssetIDs)
    }

    static func allCanonicalAssetsAreProductionEligible(
        in catalog: Prompt27ScientificAssetCatalog
    ) -> Bool {
        missingAssetIDs(in: catalog).isEmpty
            && unexpectedAssetIDs(in: catalog).isEmpty
            && catalog.allAssets.allSatisfy(\.isProductionEligible)
    }
}
