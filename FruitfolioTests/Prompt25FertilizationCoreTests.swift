import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt25FertilizationCoreTests: XCTestCase {
    func testCanonicalSequenceHasExactlySixPrimaryStages() {
        XCTAssertEqual(Prompt25FertilizationSequence.stages.count, 6)
        XCTAssertEqual(
            Prompt25FertilizationSequence.stages.map(\.id),
            [
                .oocyte,
                .fertilization,
                .twoCell,
                .fourCell,
                .morula,
                .blastocyst
            ]
        )
    }

    func testEveryStageIsEducationalOnly() {
        XCTAssertTrue(
            Prompt25FertilizationSequence.stages.allSatisfy {
                $0.semanticState == .educational
            }
        )
    }

    func testStageIndicatorsAreStable() {
        XCTAssertEqual(
            Prompt25FertilizationSequence.stages.map(\.indicatorText),
            [
                "01 / 06",
                "02 / 06",
                "03 / 06",
                "04 / 06",
                "05 / 06",
                "06 / 06"
            ]
        )
    }

    func testPreviousAndNextNeverSkipStages() {
        XCTAssertNil(
            Prompt25FertilizationSequence.previous(from: .oocyte)
        )
        XCTAssertEqual(
            Prompt25FertilizationSequence.next(from: .oocyte),
            .fertilization
        )
        XCTAssertEqual(
            Prompt25FertilizationSequence.previous(from: .blastocyst),
            .morula
        )
        XCTAssertNil(
            Prompt25FertilizationSequence.next(from: .blastocyst)
        )
    }

    func testNoExtraPrimaryEightCellZygoteOrImplantationStageExists() {
        let primaryIDs =
            Set(Prompt25FertilizationSequence.stages.map(\.id.rawValue))

        XCTAssertFalse(primaryIDs.contains("zygote"))
        XCTAssertFalse(primaryIDs.contains("eight_cell"))
        XCTAssertFalse(primaryIDs.contains("implantation"))
    }

    func testAllNineFertilizationFolderAssetsHaveReachableModuleUse() {
        let usedAssets = Set(
            Prompt25FertilizationSequence.stages.flatMap { stage in
                [stage.primaryAssetID]
                    + stage.auxiliaryArt.map(\.assetID)
            }
        )

        let required: Set<Prompt25FertilizationAssetID> = [
            .sperm,
            .spermOocyte,
            .zygote,
            .embryoTwoCell,
            .embryoFourCell,
            .embryoEightCell,
            .morula,
            .blastocyst,
            .implantationUterus
        ]

        XCTAssertTrue(required.isSubset(of: usedAssets))
    }

    func testOocytePrimaryArtIsNotMisrepresentedByFertilizationFolderArt() {
        XCTAssertEqual(
            Prompt25FertilizationSequence.stage(for: .oocyte)
                .primaryAssetID,
            .oocyte
        )
        XCTAssertEqual(
            Prompt25FertilizationAssetID.oocyte.imageName,
            "ovulation_mature_oocyte"
        )
    }

    func testUnavailableContentProviderNeverInventsScience() async {
        let provider = Prompt25UnavailableContentProvider()
        let content = await provider.content(
            for: Prompt25FertilizationSequence.stage(for: .oocyte)
        )

        XCTAssertFalse(content.isApproved)
        XCTAssertEqual(content.sourceCount, 0)
        XCTAssertTrue(content.expandedSections.isEmpty)
    }

    func testEveryStageHasStableContentAndSourceIDs() {
        for stage in Prompt25FertilizationSequence.stages {
            XCTAssertFalse(stage.shortContentID.isEmpty)
            XCTAssertFalse(stage.expandedContentID.isEmpty)
            XCTAssertFalse(stage.sourceCollectionID.isEmpty)
            XCTAssertFalse(stage.accessibilityLabel.isEmpty)
        }
    }

    func testAllAssetNamesAreLowercaseSnakeCase() {
        for asset in Prompt25FertilizationAssetID.allCases {
            XCTAssertEqual(asset.rawValue, asset.rawValue.lowercased())
            XCTAssertFalse(asset.rawValue.contains(" "))
            XCTAssertFalse(asset.rawValue.contains("-"))
        }
    }
}
