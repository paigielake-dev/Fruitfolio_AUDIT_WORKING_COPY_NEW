import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt26PregnancyEducationTests: XCTestCase {
    func testExactlySevenCanonicalTopicsExistInRequiredOrder() {
        XCTAssertEqual(
            Prompt26PregnancyEducationCatalog.topics.map(\.id),
            [
                .testing,
                .earlyDevelopment,
                .fetalDevelopment,
                .placenta,
                .umbilicalCord,
                .ultrasound,
                .prenatalVitamins
            ]
        )
    }

    func testEveryTopicIsEducationalOnly() {
        XCTAssertTrue(Prompt26PregnancyEducationCatalog.topics.allSatisfy { $0.kind == .educational })
    }

    func testExactlyTenCanonicalPregnancyAssetsAreRegistered() {
        XCTAssertEqual(Prompt26PregnancyAsset.allCases.count, 10)
        XCTAssertEqual(
            Set(Prompt26PregnancyAsset.allCases.map(\.physicalFilename)),
            Set([
                "pregnancy_placenta.png",
                "pregnancy_prenatal_vitamins.png",
                "pregnancy_test.png",
                "pregnancy_early_embryo.png",
                "pregnancy_stage_03.png",
                "pregnancy_stage_02.png",
                "pregnancy_stage_01.png",
                "pregnancy_stage_04.png",
                "pregnancy_umbilical_cord.png",
                "pregnancy_ultrasound_probe.png"
            ])
        )
    }

    func testAllTenPregnancyAssetsHaveReachableProductionUse() {
        XCTAssertTrue(Prompt26PregnancyAssetAudit.catalogReachabilityIsComplete)
        XCTAssertEqual(
            Prompt26PregnancyEducationCatalog.reachableAssets,
            Set(Prompt26PregnancyAsset.allCases)
        )
    }

    func testAllCanonicalPregnancyImagesResolveFromApplicationBundle() {
        #if canImport(UIKit)
        let result = Prompt26PregnancyAssetAudit.audit()
        XCTAssertTrue(
            result.isComplete,
            "Missing Prompt 26 pregnancy assets: \(result.missingImageNames.joined(separator: ", "))"
        )
        #endif
    }

    func testCanonicalTopicHeroAssetMapping() {
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.testing).heroAsset, .test)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.earlyDevelopment).heroAsset, .earlyEmbryo)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.fetalDevelopment).heroAsset, .stage01)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.placenta).heroAsset, .placenta)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.umbilicalCord).heroAsset, .umbilicalCord)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.ultrasound).heroAsset, .ultrasoundProbe)
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.topic(.prenatalVitamins).heroAsset, .prenatalVitamins)
    }

    func testFetalDevelopmentUsesReferencePeriodsNotUserPregnancyWeeks() {
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.fetalReferencePeriods.count, 4)
        XCTAssertEqual(
            Set(Prompt26PregnancyEducationCatalog.fetalReferencePeriods.map(\.illustrationAsset)),
            Set([.stage01, .stage02, .stage03, .stage04])
        )
        XCTAssertTrue(
            Prompt26PregnancyEducationCatalog.fetalReferencePeriods.allSatisfy {
                !$0.displayRange.lowercased().contains("your") &&
                !$0.displayRange.lowercased().contains("pregnant")
            }
        )
    }

    func testPredictedPeriodPassingNeverInfersPregnancy() {
        for daysPast in [0, 1, 7, 14, 30, 90] {
            let state = Prompt26PregnancyInferenceGuard.deriveState(
                from: .init(predictedPeriodDaysPast: daysPast)
            )
            assertNoPregnancyInference(state)
        }
    }

    func testSymptomCombinationsNeverInferPregnancy() {
        let inputs: [Prompt26PregnancyInferenceInput] = [
            .init(predictedPeriodDaysPast: 1, symptoms: ["nausea"]),
            .init(predictedPeriodDaysPast: 1, symptoms: ["breast tenderness"]),
            .init(predictedPeriodDaysPast: 1, symptoms: ["fatigue"]),
            .init(predictedPeriodDaysPast: 1, symptoms: ["spotting"]),
            .init(predictedPeriodDaysPast: 1, hasElevatedBBTObservation: true),
            .init(predictedPeriodDaysPast: 1, hasIntercourseLog: true),
            .init(predictedPeriodDaysPast: 1, hasEstimatedFertileWindowIntercourse: true),
            .init(
                predictedPeriodDaysPast: 14,
                symptoms: ["nausea", "breast tenderness", "fatigue", "spotting"],
                hasElevatedBBTObservation: true,
                hasIntercourseLog: true,
                hasEstimatedFertileWindowIntercourse: true,
                hasEstimatedOvulation: true,
                hasCervicalFluidObservation: true,
                hasLHObservation: true
            )
        ]

        for input in inputs {
            assertNoPregnancyInference(Prompt26PregnancyInferenceGuard.deriveState(from: input))
        }
    }

    func testPregnancySpecificArtworkRequiresIntentionalEducationalContext() {
        XCTAssertTrue(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .intentionalEncyclopediaOpen))
        XCTAssertTrue(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .directEducationalSearch))
        XCTAssertTrue(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .savedEducationalEntry))

        XCTAssertFalse(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .cyclePredictionPassed(days: 1)))
        XCTAssertFalse(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .cyclePredictionPassed(days: 14)))
        XCTAssertFalse(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .symptomTriggered))
        XCTAssertFalse(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .notification))
        XCTAssertFalse(Prompt26PregnancyArtworkGate.mayDisplayPregnancySpecificArtwork(in: .backgroundRecommendation))
    }

    func testSavedEntriesRemainEducational() {
        let topic = Prompt26PregnancyEducationCatalog.topic(.placenta)
        let saved = Prompt26SavedEducationEntry(
            topicID: topic.id,
            title: topic.title,
            contentID: topic.shortContentID,
            sourceIDs: ["source-1"]
        )
        XCTAssertEqual(saved.kind, .educational)
    }

    func testPersonalizedPregnancyQuestionNeverBecomesProbabilityAnswer() {
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "Am I pregnant?"),
            .testingAndCareEducationOnly
        )
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "My period is late. Am I pregnant?"),
            .testingAndCareEducationOnly
        )
    }

    func testImageInterpretationRequestsAreRejectedByBoundary() {
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "interpret my ultrasound"),
            .unsupportedMedicalInterpretation
        )
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "read my pregnancy test photo"),
            .unsupportedMedicalInterpretation
        )
    }

    func testOrdinaryEducationalQuestionsRemainAllowed() {
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "what does hCG do?"),
            .educationalAnswerAllowed
        )
        XCTAssertEqual(
            Prompt26PregnancyQuestionPolicy.boundary(forNormalizedQuery: "how does ultrasound create an image?"),
            .educationalAnswerAllowed
        )
    }

    func testAskIndexRequiresResearchSupportForEveryTopic() {
        XCTAssertEqual(Prompt26PregnancyEducationCatalog.askIndex.count, 7)
        XCTAssertTrue(Prompt26PregnancyEducationCatalog.askIndex.allSatisfy(\.requiresResearchSupport))
    }

    func testUnavailableProviderFailsClosedInsteadOfFabricatingContent() async {
        let provider = Prompt26UnavailableResearchProvider()
        do {
            _ = try await provider.approvedContent(for: "pregnancy.testing.core")
            XCTFail("Unavailable research must fail closed")
        } catch let error as Prompt26ResearchBridgeError {
            XCTAssertEqual(error, .contentUnavailable("pregnancy.testing.core"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testClosureProviderReturnsOnlyInjectedApprovedContent() async throws {
        let expected = Prompt26ApprovedContent(
            contentID: "pregnancy.testing.core",
            title: "pregnancy testing",
            summary: "Approved content fixture.",
            sections: [],
            sourceIDs: ["source-a"]
        )
        let provider = Prompt26ClosureResearchProvider { id in
            XCTAssertEqual(id, expected.contentID)
            return expected
        }
        let result = try await provider.approvedContent(for: expected.contentID)
        XCTAssertEqual(result, expected)
    }

    private func assertNoPregnancyInference(
        _ state: Prompt26PregnancyDerivedState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertFalse(state.pregnancyInferred, file: file, line: line)
        XCTAssertNil(state.pregnancyProbability, file: file, line: line)
        XCTAssertNil(state.gestationalAgeDays, file: file, line: line)
        XCTAssertNil(state.estimatedDueDate, file: file, line: line)
        XCTAssertFalse(state.showPregnancySpecificArtworkAutomatically, file: file, line: line)
        XCTAssertFalse(state.activatePregnancyMode, file: file, line: line)
    }
}

