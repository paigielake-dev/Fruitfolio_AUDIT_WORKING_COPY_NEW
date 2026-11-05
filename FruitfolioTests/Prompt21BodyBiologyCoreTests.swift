import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt21BodyBiologyCoreTests: XCTestCase {
    func testUnknownContextFallsBackToNeutral() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("still learning your pattern"),
            .neutral
        )
    }

    func testMenstruationContextMapsWithoutUsingBleedingObservation() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("menstruation"),
            .menstruation
        )
    }


    func testOvulationContextIsExplicitlyEstimatedState() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("estimated ovulation window"),
            .estimatedOvulation
        )
    }

    func testLutealContextMapsToLuteal() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("luteal phase"),
            .luteal
        )
    }

    func testBroadFollicularContextMapsToEarlyBroadPresentation() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("follicular phase"),
            .follicularEarly
        )
    }

    func testExplicitLaterFollicularContextMapsToLaterPresentation() async {
        XCTAssertEqual(
            Prompt21BodyBiologyLoader.mapEstablishedContextTitle("later follicular phase"),
            .follicularLater
        )
    }

    func testNeutralPresentationDoesNotClaimPersonalizedBiology() async {
        let presentation = Prompt21BodyBiologyEngine().presentation(for: .neutral)
        XCTAssertEqual(presentation.state, .neutral)
        XCTAssertEqual(presentation.heroAssetName, "ovulation_ovary")
        XCTAssertFalse(presentation.showsBlueberryUncertainty)
        XCTAssertFalse(presentation.showsPeachDayOne)
        XCTAssertFalse(presentation.permitsOocyteDrift)
        XCTAssertFalse(presentation.permitsFimbriaeDetail)
    }

    func testEstimatedOvulationUsesEstimateLanguageAndBlueberry() async {
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

    func testLutealUsesCorpusLuteumAsset() async {
        let input = Prompt21BodyBiologyInput(
            state: .luteal,
            contextKind: .calculated
        )
        let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
        XCTAssertEqual(presentation.heroAssetName, "ovulation_corpus_luteum")
        XCTAssertEqual(presentation.title, "luteal phase")
    }

    func testMenstruationUsesUterusAndEndometriumAssets() async {
        let input = Prompt21BodyBiologyInput(
            state: .menstruation,
            contextKind: .calculated
        )
        let presentation = Prompt21BodyBiologyEngine().presentation(for: input)
        XCTAssertEqual(presentation.heroAssetName, "menstruation_uterus")
        XCTAssertEqual(presentation.supportingAssetName, "menstruation_endometrium_shedding")
        XCTAssertFalse(presentation.showsPeachDayOne)
    }

    func testPeachAppearsOnlyForConfirmedDayOneInput() async {
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

    func testFollicularStatesUseDifferentApprovedStageArt() async {
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

    func testNoPresentationUsesForbiddenPersonalizedPhrases() async {
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
    func testTypedTodayContextDoesNotInventABiologicalPhaseFromCycleDay() async {
        for day in [1, 14, 21, 38] {
            let today = Prompt16TodayState(cycleDay: day, context: .cycleContext,
                bbtShortcutEnabled: false, bbtUnit: nil, hasRecordedTemperatureToday: false, hasRecordedBleedingToday: false)
            let input = Prompt21BodyBiologyLoader.makeInput(from: today)
            XCTAssertEqual(input.state, .neutral)
            XCTAssertEqual(input.contextKind, .educational)
            XCTAssertFalse(input.confirmedCycleDayOne)
        }
    }

    func testDayOneCharacterRequiresRecordedBleedingRatherThanOnlyContextTitle() async {
        for recorded in [false, true] {
            let today = Prompt16TodayState(cycleDay: 1, context: .menstruation,
                bbtShortcutEnabled: false, bbtUnit: nil, hasRecordedTemperatureToday: false, hasRecordedBleedingToday: recorded)
            let input = Prompt21BodyBiologyLoader.makeInput(from: today)
            XCTAssertEqual(input.state, recorded ? .menstruation : .neutral)
            XCTAssertEqual(input.confirmedCycleDayOne, recorded)
        }
    }

    func testReportedOpenPeriodCannotBecomeCurrentBiologyOrDayOneConfirmation() async {
        let today = Prompt16TodayState(cycleDay: 1, context: .reportedOpenPeriod,
            bbtShortcutEnabled: false, bbtUnit: nil, hasRecordedTemperatureToday: false, hasRecordedBleedingToday: false)
        let input = Prompt21BodyBiologyLoader.makeInput(from: today)
        XCTAssertEqual(input.state, .neutral)
        XCTAssertFalse(input.confirmedCycleDayOne)
    }

    func testBleedingWithoutReportedPeriodDoesNotEstablishMenstruation() async {
        let today = Prompt16TodayState(cycleDay: 15, context: .menstruation,
            bbtShortcutEnabled: false, bbtUnit: nil, hasRecordedTemperatureToday: false, hasRecordedBleedingToday: true)
        XCTAssertEqual(Prompt21BodyBiologyLoader.makeInput(from: today).state, .neutral)
        var reported = today
        reported.hasReportedOpenPeriod = true
        XCTAssertEqual(Prompt21BodyBiologyLoader.makeInput(from: reported).state, .menstruation)
    }

}
