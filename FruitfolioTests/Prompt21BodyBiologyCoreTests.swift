import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt21BodyBiologyCoreTests: XCTestCase {
    func testUnknownContextFallsBackToNeutral() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("still learning your pattern"),
            .neutral
        )
    }

    func testMenstruationContextMapsWithoutUsingBleedingObservation() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("menstruation"),
            .menstruation
        )
    }


    func testOvulationContextIsExplicitlyEstimatedState() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("estimated ovulation window"),
            .estimatedOvulation
        )
    }

    func testLutealContextMapsToLuteal() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("luteal phase"),
            .luteal
        )
    }

    func testBroadFollicularContextMapsToEarlyBroadPresentation() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("follicular phase"),
            .follicularEarly
        )
    }

    func testExplicitLaterFollicularContextMapsToLaterPresentation() {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("later follicular phase"),
            .follicularLater
        )
    }

    func testNeutralPresentationDoesNotClaimPersonalizedBiology() {
        let presentation = Prompt21BodyBiologyEngine().presentation(for: .neutral)
        XCTAssertEqual(presentation.state, .neutral)
        XCTAssertEqual(presentation.heroAssetName, "ovulation_ovary")
        XCTAssertFalse(presentation.showsBlueberryUncertainty)
        XCTAssertFalse(presentation.showsPeachDayOne)
        XCTAssertFalse(presentation.permitsOocyteDrift)
        XCTAssertFalse(presentation.permitsFimbriaeDetail)
    }

    func testEstimatedOvulationUsesEstimateLanguageAndBlueberry() {
        let input = Prompt21BodyBiologyInput(
            state: .estimatedOvulation,
            contextKind: .estimated
        )
        let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
        XCTAssertEqual(presentation.title, "estimated ovulation window")
        XCTAssertTrue(presentation.body.contains("may"))
        XCTAssertTrue(presentation.showsBlueberryUncertainty)
        XCTAssertTrue(presentation.permitsOocyteDrift)
        XCTAssertTrue(presentation.permitsFimbriaeDetail)
        XCTAssertEqual(presentation.heroAssetName, "ovulation_follicle_release")
        XCTAssertEqual(presentation.supportingAssetName, "ovulation_mature_oocyte")
    }

    func testLutealUsesCorpusLuteumAsset() {
        let input = Prompt21BodyBiologyInput(
            state: .luteal,
            contextKind: .calculated
        )
        let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
        XCTAssertEqual(presentation.heroAssetName, "ovulation_corpus_luteum")
        XCTAssertEqual(presentation.title, "luteal phase")
    }

    func testMenstruationUsesUterusAndEndometriumAssets() {
        let input = Prompt21BodyBiologyInput(
            state: .menstruation,
            contextKind: .calculated
        )
        let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
        XCTAssertEqual(presentation.heroAssetName, "menstruation_uterus")
        XCTAssertEqual(presentation.supportingAssetName, "menstruation_endometrium_shedding")
        XCTAssertFalse(presentation.showsPeachDayOne)
    }

    func testPeachAppearsOnlyForConfirmedDayOneInput() {
        let ordinary = Prompt21BodyBiologyEngine().presentation(
            for: Prompt21BodyBiologyInput(
                state: .menstruation,
                contextKind: .calculated,
                cycleDay: 2,
                confirmedCycleDayOne: false
            )
        )
        let dayOne = Prompt21BodyBiologyEngine().presentation(
            for: Prompt21BodyBiologyInput(
                state: .menstruation,
                contextKind: .calculated,
                cycleDay: 1,
                confirmedCycleDayOne: true
            )
        )
        XCTAssertFalse(ordinary.showsPeachDayOne)
        XCTAssertTrue(dayOne.showsPeachDayOne)
    }

    func testFollicularStatesUseDifferentApprovedStageArt() {
        let early = Prompt21BodyBiologyEngine().presentation(
            for: Prompt21BodyBiologyInput(
                state: .follicularEarly,
                contextKind: .calculated
            )
        )
        let later = Prompt21BodyBiologyEngine().presentation(
            for: Prompt21BodyBiologyInput(
                state: .follicularLater,
                contextKind: .calculated
            )
        )
        XCTAssertEqual(early.heroAssetName, "ovulation_follicle_stage_02")
        XCTAssertEqual(later.heroAssetName, "ovulation_follicle_stage_04")
        XCTAssertNotEqual(early.heroAssetName, later.heroAssetName)
    }

    func testNoPresentationUsesForbiddenPersonalizedPhrases() {
        let inputs: [Prompt21BodyBiologyInput] = [
            .neutral,
            .init(state: .follicularEarly, contextKind: .calculated),
            .init(state: .follicularLater, contextKind: .calculated),
            .init(state: .estimatedOvulation, contextKind: .estimated),
            .init(state: .luteal, contextKind: .calculated),
            .init(state: .menstruation, contextKind: .calculated)
        ]

        let forbidden = [
            "this is your follicle",
            "you are ovulating",
            "your egg was released",
            "fertilization occurred",
            "implantation occurred",
            "pregnancy occurred"
        ]

        for input in inputs {
            let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
            let combined = "\(presentation.title) \(presentation.body)".lowercased()
            for phrase in forbidden {
                XCTAssertFalse(combined.contains(phrase))
            }
        }
    }
}
