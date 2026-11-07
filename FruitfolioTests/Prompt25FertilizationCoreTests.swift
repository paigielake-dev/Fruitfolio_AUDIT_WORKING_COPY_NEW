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

#if canImport(Combine) && canImport(SwiftUI)
/// Deliberately noncooperative provider to exercise actual Apple model ownership.
/// Its text is a nonclinical fixture, never approved embryology content.
private actor Prompt25HeldContentFixture: Prompt25FertilizationContentProviding {
    let started: XCTestExpectation
    private var pending: CheckedContinuation<Prompt25EducationalContent, Never>?
    init(started: XCTestExpectation) { self.started = started }
    func content(for stage: Prompt25FertilizationStage) async -> Prompt25EducationalContent {
        await withCheckedContinuation { continuation in
            pending = continuation
            started.fulfill()
        }
    }
    func finish() {
        pending?.resume(returning: .init(shortText: "old-stage nonclinical fixture",
            expandedSections: [], sourceCount: 1, isApproved: true))
        pending = nil
    }
}

@MainActor
final class Prompt25FertilizationLifecycleTests: XCTestCase {
    func testOldProviderCannotPublishUnderNewStageBeforeReplacementLoadStarts() async {
        let started = expectation(description: "old stage provider started")
        let provider = Prompt25HeldContentFixture(started: started)
        let model = Prompt25FertilizationViewModel(initialStage: .oocyte, contentProvider: provider)
        let old = Task { await model.loadContent() }
        await fulfillment(of: [started], timeout: 2)
        model.setStage(.fertilization, animated: false, reduceMotion: true)
        // Intentionally do not start the new stage load: this is the previous
        // gap between stage publication and SwiftUI's replacement .task.
        await provider.finish()
        await old.value
        XCTAssertEqual(model.stageID, .fertilization)
        XCTAssertEqual(model.content, .unavailable)
        XCTAssertEqual(model.contentState, .idle)
    }

    func testCanceledPresentationCannotPublishNoncooperativeProviderResult() async {
        let started = expectation(description: "provider started")
        let provider = Prompt25HeldContentFixture(started: started)
        let model = Prompt25FertilizationViewModel(initialStage: .oocyte, contentProvider: provider)
        let request = Task { await model.loadContent() }
        await fulfillment(of: [started], timeout: 2)
        model.suspendPresentation()
        request.cancel()
        await provider.finish()
        await request.value
        XCTAssertEqual(model.stageID, .oocyte)
        XCTAssertEqual(model.content, .unavailable)
        XCTAssertEqual(model.contentState, .idle)
    }

    func testSuspensionDropsDelayedCallbackAndReducedMotionSettlesOnlyCurrentTransition() async throws {
        let model = Prompt25FertilizationViewModel(initialStage: .oocyte,
            contentProvider: Prompt25UnavailableContentProvider())
        var completions = 0
        model.next(reduceMotion: false) { completions += 1 }
        XCTAssertTrue(model.isTransitioning)
        model.suspendPresentation()
        XCTAssertEqual(model.stageID, .fertilization)
        XCTAssertFalse(model.isTransitioning)
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertEqual(completions, 0)
        model.next(reduceMotion: false) { completions += 1 }
        model.settleTransitionForReducedMotion()
        XCTAssertEqual(model.stageID, .twoCell)
        XCTAssertFalse(model.isTransitioning)
        XCTAssertEqual(completions, 1)
        try await Task.sleep(for: .milliseconds(450))
        XCTAssertEqual(completions, 1)
    }
}
#endif
