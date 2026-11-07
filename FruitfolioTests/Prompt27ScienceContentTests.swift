import Foundation
import XCTest
@testable import Fruitfolio

#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class Prompt27ScienceContentTests: XCTestCase {
    private let catalog = Prompt27ScientificAssetCatalog()
    private let router = Prompt27ContextRouter()

    func testCanonicalCatalogContainsExactlyTwentySixPrompt27Assets() async {
        XCTAssertEqual(catalog.allAssets.count, 26)
        XCTAssertEqual(catalog.allAssetIDs, Prompt27ScienceAssetAudit.expectedAllAssetIDs)
        XCTAssertTrue(Prompt27ScienceAssetAudit.missingAssetIDs(in: catalog).isEmpty)
        XCTAssertTrue(Prompt27ScienceAssetAudit.unexpectedAssetIDs(in: catalog).isEmpty)
    }

    func testCanonicalAssetFamilyCountsAreExact() async {
        let genetics = catalog.allAssets.filter { $0.family == .genetics }
        let body = catalog.allAssets.filter { $0.family == .body }
        let lab = catalog.allAssets.filter { $0.family == .lab }

        XCTAssertEqual(genetics.count, 9)
        XCTAssertEqual(body.count, 9)
        XCTAssertEqual(lab.count, 8)
    }

    func testCanonicalFilenamesMatchPhysicalManifestExactly() async {
        let filenames = Set(catalog.allAssets.map(\.filename))

        XCTAssertEqual(
            filenames,
            [
                "genetics_protein.png",
                "genetics_rna.png",
                "genetics_receptor.png",
                "genetics_dna.png",
                "genetics_chromosome.png",
                "genetics_cell.png",
                "genetics_cells.png",
                "genetics_mitochondrion.png",
                "genetics_nucleus.png",
                "body_gut_microbiome.png",
                "body_heart.png",
                "body_liver.png",
                "body_thyroid.png",
                "body_stomach.png",
                "body_skin.png",
                "body_bone.png",
                "body_kidneys.png",
                "body_muscle.png",
                "lab_agar_plate.png",
                "lab_centrifuge.png",
                "lab_microscope.png",
                "lab_collection_swab.png",
                "lab_microcentrifuge_tube.png",
                "lab_test_tube.png",
                "lab_transfer_pipette.png",
                "lab_specimen_cup.png"
            ]
        )
    }

    func testAllCanonicalAssetsAreProductionEligible() async {
        XCTAssertTrue(
            Prompt27ScienceAssetAudit.allCanonicalAssetsAreProductionEligible(in: catalog)
        )
    }

    func testGeneticsSectionRoutesToOneExplicitGeneticsAsset() async throws {
        let section = makeSection(
            family: .genetics,
            assetID: .geneticsDNA
        )

        let route = try XCTUnwrap(try router.route(section: section).get())

        XCTAssertEqual(route.family, .genetics)
        XCTAssertEqual(route.primaryAsset?.id, .geneticsDNA)
        XCTAssertEqual(route.majorIllustrationsVisible, 1)
    }

    func testBodySectionRoutesToOneExplicitBodyAsset() async throws {
        let section = makeSection(
            family: .body,
            assetID: .bodyThyroid
        )

        let route = try XCTUnwrap(try router.route(section: section).get())

        XCTAssertEqual(route.family, .body)
        XCTAssertEqual(route.primaryAsset?.id, .bodyThyroid)
        XCTAssertEqual(route.majorIllustrationsVisible, 1)
    }

    func testLabSectionRoutesToOneExplicitLabAsset() async throws {
        let section = makeSection(
            family: .lab,
            assetID: .labCollectionSwab
        )

        let route = try XCTUnwrap(try router.route(section: section).get())

        XCTAssertEqual(route.family, .lab)
        XCTAssertEqual(route.primaryAsset?.id, .labCollectionSwab)
        XCTAssertEqual(route.majorIllustrationsVisible, 1)
    }

    func testRouterUsesCuratedMetadataRatherThanArticleKeywords() async throws {
        let section = Prompt27ContextualScienceSection(
            id: "mixed-topic",
            title: "DNA, thyroid, PCR, cervix, chromosome, microscope",
            bodyContentID: "mixed-topic",
            primaryVisualFamily: .lab,
            primaryIllustrationAssetID: .labCollectionSwab,
            hotspotIDs: [],
            relatedTopicIDs: [],
            sourceIDs: ["source-1"],
            altText: "Sample collection"
        )

        let route = try router.route(section: section).get()

        XCTAssertEqual(route.primaryAsset?.id, .labCollectionSwab)
        XCTAssertEqual(route.majorIllustrationsVisible, 1)
    }

    func testRouterRejectsFamilyMismatch() async {
        let section = makeSection(
            family: .genetics,
            assetID: .bodyLiver
        )

        XCTAssertEqual(
            router.route(section: section),
            .failure(
                .familyMismatch(
                    expected: .genetics,
                    actual: .body
                )
            )
        )
    }

    func testNoneContextRendersNoMajorIllustration() async throws {
        let section = Prompt27ContextualScienceSection(
            id: "text-only",
            title: "Text only",
            bodyContentID: "text-only",
            primaryVisualFamily: .none,
            primaryIllustrationAssetID: nil,
            sourceIDs: ["source-1"],
            altText: ""
        )

        let route = try router.route(section: section).get()

        XCTAssertNil(route.primaryAsset)
        XCTAssertEqual(route.majorIllustrationsVisible, 0)
    }

    func testRouterRejectsAssetInNoneContext() async {
        let section = Prompt27ContextualScienceSection(
            id: "invalid",
            title: "Invalid",
            bodyContentID: "invalid",
            primaryVisualFamily: .none,
            primaryIllustrationAssetID: .geneticsDNA,
            sourceIDs: ["source-1"],
            altText: "DNA"
        )

        XCTAssertEqual(
            router.route(section: section),
            .failure(.assetNotAllowedForNoneContext)
        )
    }

    func testVisualFamilyRequiresExplicitCuratedAsset() async {
        let section = Prompt27ContextualScienceSection(
            id: "missing-art",
            title: "DNA",
            bodyContentID: "dna",
            primaryVisualFamily: .genetics,
            primaryIllustrationAssetID: nil,
            sourceIDs: ["source-1"],
            altText: "DNA"
        )

        XCTAssertEqual(
            router.route(section: section),
            .failure(.assetRequiredForVisualContext(.genetics))
        )
    }

    func testUnapprovedScientificAssetFailsClosed() async {
        let draft = Prompt27ScientificAsset(
            id: .geneticsDNA,
            family: .genetics,
            concept: .dna,
            version: 1,
            scientificReviewStatus: .reviewRequired,
            altText: "DNA",
            hotspotMapID: nil,
            sourceReferenceIDs: []
        )

        let customRouter = Prompt27ContextRouter(
            catalog: Prompt27ScientificAssetCatalog(assets: [draft])
        )

        let section = makeSection(
            family: .genetics,
            assetID: .geneticsDNA
        )

        XCTAssertEqual(
            customRouter.route(section: section),
            .failure(.unapprovedAsset(.geneticsDNA))
        )
    }

    func testPCRContextUsesExistingCanonicalArtWithoutInventingFilename() async throws {
        let section = makeSection(
            family: .lab,
            assetID: .labMicrocentrifugeTube
        )

        let route = try router.route(section: section).get()

        XCTAssertEqual(route.primaryAsset?.concept, .pcrReactionSetup)
        XCTAssertEqual(
            route.primaryAsset?.filename,
            "lab_microcentrifuge_tube.png"
        )
        XCTAssertEqual(route.majorIllustrationsVisible, 1)
    }

    func testBrowsingDoesNotBecomeMedicalState() async {
        XCTAssertFalse(Prompt27ScienceSafety.browsingEstablishesMedicalState())
        XCTAssertFalse(Prompt27ScienceSafety.browsingEstablishesGenotype())
        XCTAssertFalse(Prompt27ScienceSafety.browsingEstablishesDiagnosis())
        XCTAssertFalse(
            Prompt27ScienceSafety.laboratoryIllustrationEstablishesUserTestingHistory()
        )
    }

    func testRuntimeGenerativeScienceArtAndKeywordRoutingAreForbidden() async {
        XCTAssertFalse(Prompt27ScienceSafety.permitsRuntimeGeneratedScientificArt())
        XCTAssertFalse(Prompt27ScienceSafety.permitsNaiveKeywordIllustrationRouting())
    }

    func testEducationalQuestionsRemainAllowed() async {
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .learnGenetics),
            .allowedEducational
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .learnAnatomy),
            .allowedEducational
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .learnHowTestingWorks),
            .allowedEducational
        )
    }

    func testPersonalizedRiskAndLabResultInterpretationRequireSeparateValidatedSystem() async {
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .personalizedGeneticRisk),
            .requiresSeparateValidatedSystem
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .interpretRawGeneticData),
            .requiresSeparateValidatedSystem
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .diagnoseFromLabResult),
            .requiresSeparateValidatedSystem
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .inventReferenceRange),
            .requiresSeparateValidatedSystem
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .inventDiagnosticThreshold),
            .requiresSeparateValidatedSystem
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .inventPCRPerformance),
            .requiresSeparateValidatedSystem
        )
    }

    func testForbiddenInferencesRemainForbidden() async {
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .inferGenotype),
            .prohibitedInference
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .inferAncestry),
            .prohibitedInference
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .diagnoseFromImage),
            .prohibitedInference
        )
        XCTAssertEqual(
            Prompt27ScienceSafety.boundary(for: .identifyMicrobeFromPhoto),
            .prohibitedInference
        )
    }

    func testUnavailableResearchProviderFailsClosed() async {
        let provider = Prompt27UnavailableScienceResearchProvider()

        do {
            _ = try await provider.approvedContent(for: "dna")
            XCTFail("Expected research provider to fail closed.")
        } catch {
            XCTAssertEqual(
                error as? Prompt27ScienceLoadFailure,
                .researchUnavailable
            )
        }
    }

    func testClosureResearchProviderAcceptsApprovedSourcedContent() async throws {
        let provider = Prompt27ClosureScienceResearchProvider { contentID in
            Prompt27ApprovedScienceContent(
                contentID: contentID,
                title: "DNA",
                body: "Approved educational content.",
                sourceIDs: ["source-1"]
            )
        }

        let content = try await provider.approvedContent(for: "dna")

        XCTAssertEqual(content.contentID, "dna")
        XCTAssertEqual(content.sourceIDs, ["source-1"])
    }

    func testClosureResearchProviderRejectsUnsourcedContent() async {
        let provider = Prompt27ClosureScienceResearchProvider { contentID in
            Prompt27ApprovedScienceContent(
                contentID: contentID,
                title: "DNA",
                body: "Approved educational content.",
                sourceIDs: []
            )
        }

        do {
            _ = try await provider.approvedContent(for: "dna")
            XCTFail("Expected unsourced content to fail closed.")
        } catch {
            XCTAssertEqual(
                error as? Prompt27ScienceLoadFailure,
                .invalidApprovedContent
            )
        }
    }

    func testHotspotCoordinatesAreClampedAndAccessibleByLabel() async {
        let hotspot = Prompt27ScienceHotspot(
            id: "centromere",
            label: "centromere",
            normalizedX: 1.5,
            normalizedY: -1,
            educationalContentID: "centromere"
        )

        XCTAssertEqual(hotspot.normalizedX, 1)
        XCTAssertEqual(hotspot.normalizedY, 0)
        XCTAssertEqual(hotspot.label, "centromere")
    }

    #if canImport(UIKit)
    func testAllPrompt27CanonicalImagesResolveFromApplicationBundle() async {
        for asset in catalog.allAssets {
            XCTAssertNotNil(
                UIImage(named: asset.imageName),
                "Missing Prompt 27 image in application bundle: \(asset.filename)"
            )
        }
    }
    #endif

    private func makeSection(
        family: Prompt27ScienceVisualFamily,
        assetID: Prompt27ScienceAssetID
    ) -> Prompt27ContextualScienceSection {
        Prompt27ContextualScienceSection(
            id: "section-\(assetID.rawValue)",
            title: "Educational section",
            bodyContentID: "content-\(assetID.rawValue)",
            primaryVisualFamily: family,
            primaryIllustrationAssetID: assetID,
            sourceIDs: ["source-1"],
            altText: "Educational illustration"
        )
    }
}


private actor Prompt27HeldLifecycleProvider: Prompt27ScienceResearchProviding {
    let started: [XCTestExpectation]
    private var pending: [(String, CheckedContinuation<Prompt27ApprovedScienceContent, any Error>)] = []
    init(started: [XCTestExpectation]) { self.started = started }
    func approvedContent(for contentID: String) async throws -> Prompt27ApprovedScienceContent {
        try await withCheckedThrowingContinuation { continuation in
            let index = pending.count
            pending.append((contentID, continuation))
            started[index].fulfill()
        }
    }
    func finish(_ index: Int, title: String, invalid: Bool = false) {
        let (id, continuation) = pending[index]
        continuation.resume(returning: .init(contentID: invalid ? "unrelated-topic" : id,
            title: title, body: "nonclinical lifecycle fixture", sourceIDs: ["fixture-source"]))
    }
}

@MainActor
final class Prompt27SciencePresentationLifecycleTests: XCTestCase {
    private var section: Prompt27ContextualScienceSection {
        .init(id: "nonclinical-section-fixture", title: "nonclinical section", bodyContentID: "nonclinical-body-fixture",
              primaryVisualFamily: .genetics, primaryIllustrationAssetID: .geneticsDNA,
              hotspotIDs: ["allowed-hotspot"], altText: "nonclinical source-art fixture")
    }
    func testNoncooperativeCanceledProviderCannotReplaceCurrentScienceOrHotspotSelection() async throws {
        let started = [expectation(description: "first provider"), expectation(description: "visible provider")]
        let provider = Prompt27HeldLifecycleProvider(started: started)
        let model = Prompt27ScienceViewModel(section: section, provider: provider)
        model.selectHotspot("allowed-hotspot")
        model.selectHotspot("unregistered-hotspot")
        XCTAssertEqual(model.selectedHotspotID, "allowed-hotspot")
        let old = try XCTUnwrap(model.loadIfNeeded())
        let firstStarted = await XCTWaiter.fulfillment(of: [started[0]], timeout: 2)
        XCTAssertEqual(firstStarted, .completed)
        model.suspendPresentation()
        XCTAssertEqual(model.state, .idle)
        let replacement = try XCTUnwrap(model.loadIfNeeded())
        let nextStarted = await XCTWaiter.fulfillment(of: [started[1]], timeout: 2)
        XCTAssertEqual(nextStarted, .completed)
        await provider.finish(1, title: "current science")
        await replacement.value
        await provider.finish(0, title: "stale science")
        await old.value
        XCTAssertEqual(model.loadedContent?.title, "current science")
        XCTAssertEqual(model.visualRoute?.primaryAsset?.id, .geneticsDNA)
        model.suspendPresentation()
        XCTAssertEqual(model.loadedContent?.title, "current science")
        XCTAssertEqual(model.selectedHotspotID, "allowed-hotspot")
        XCTAssertNil(model.loadIfNeeded())
    }
    func testWrongTopicResponseCannotPublishEvenFromCustomProtocolProvider() async throws {
        let started = expectation(description: "wrong-topic provider")
        let provider = Prompt27HeldLifecycleProvider(started: [started])
        let model = Prompt27ScienceViewModel(section: section, provider: provider)
        let request = try XCTUnwrap(model.loadIfNeeded())
        let began = await XCTWaiter.fulfillment(of: [started], timeout: 2)
        XCTAssertEqual(began, .completed)
        await provider.finish(0, title: "wrong-topic content", invalid: true)
        await request.value
        XCTAssertEqual(model.state, .unavailable)
        XCTAssertNil(model.loadedContent)
        XCTAssertNil(model.visualRoute)
    }
    func testDecodedOutOfCanvasHotspotIsRejectedWithoutRelocatingAnatomicalAnchor() async throws {
        let raw = Data(#"{"id":"fixture","label":"nonclinical","normalizedX":4,"normalizedY":0.5,"educationalContentID":"fixture-detail"}"#.utf8)
        let decoded = try JSONDecoder().decode(Prompt27ScienceHotspot.self, from: raw)
        XCTAssertEqual(decoded.normalizedX, 4, "Do not silently move decoded anatomical anchors")
        XCTAssertFalse(decoded.hasValidCanvasPlacement)
        let valid = Prompt27ScienceHotspot(id: "valid", label: "nonclinical", normalizedX: 0, normalizedY: 1, educationalContentID: "fixture")
        XCTAssertTrue(valid.hasValidCanvasPlacement)
    }
}
