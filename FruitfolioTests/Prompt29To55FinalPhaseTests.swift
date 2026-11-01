import XCTest
@testable import Fruitfolio

final class Prompt29To55FinalPhaseTests: XCTestCase {
    func testFAQContainsAllCanonicalSections() {
        let ids = Set(Prompt29FAQCatalog.sections.map(\.id))
        XCTAssertEqual(ids, ["about", "encyclopedia", "cycle", "basket", "privacy", "purchase", "brand"])
    }

    func testSeriousHealthRouterIsDeterministic() {
        let urgent = Prompt34LocalSafetyRouter.classify("I have severe bleeding and fainted")
        XCTAssertEqual(urgent.level, .urgent)
        XCTAssertTrue(urgent.requiresSeriousTone)
    }

    func testMinimumHitArea() {
        XCTAssertGreaterThanOrEqual(DesignTokens.Layout.minimumHitTarget, 44)
    }

    func testPageTurnAudioPolicyUsesExistingProductionAPI() {
        XCTAssertEqual(Prompt39PageTurnPolicy.soundID(for: .forward), "audio_page_turn")
        XCTAssertEqual(Prompt39PageTurnPolicy.soundID(for: .backward), "audio_page_turn")
    }

    @MainActor
    func testPageTurnNavigationTracksForwardAndBackwardDirection() {
        let popup = PopupCoordinator()
        let navigation = NavigationCoordinator(
            root: .hub,
            popupCoordinator: popup,
            minimumPushInterval: 0
        )

        var transitionCount = 0
        navigation.onNavigationTransition = {
            transitionCount += 1
        }

        XCTAssertTrue(navigation.navigate(to: .ask))
        XCTAssertEqual(navigation.lastNavigationDirection, .forward)

        navigation.back()
        XCTAssertEqual(navigation.lastNavigationDirection, .backward)

        XCTAssertEqual(transitionCount, 2)
        XCTAssertEqual(navigation.currentRoute, .hub)
    }

    func testPrivacyAnalyticsDoesNotExposeRawQuestionAPI() async {
        await Prompt43PrivacySafeAnalytics.shared.reset()
        await Prompt43PrivacySafeAnalytics.shared.recordRawHealthQuestion("sensitive health question")
        let events = await Prompt43PrivacySafeAnalytics.shared.events
        XCTAssertTrue(events.isEmpty)
    }

    func testSymptomSemanticRoleIsRecognized() {
        XCTAssertEqual(Prompt48SemanticStylePolicy.style(for: "symptom"), .symptom)
        XCTAssertEqual(FruitfolioSemanticSpan(text: "cramps", emphasis: .symptomOrPracticalUnderline).emphasis, .symptomOrPracticalUnderline)
    }

    @MainActor
    func testAutomaticSymptomUnderliningUsesProductionRenderer() {
        let answer = "Cramps and breast tenderness may occur. Rest can help."
        // Binding Prompt 1B prohibits word matching. Preserve the positive
        // symptom assertion using explicit contextual roles instead.
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "Cramps", emphasis: .symptomOrPracticalUnderline),
            .init(text: " and "),
            .init(text: "breast tenderness", emphasis: .symptomOrPracticalUnderline),
            .init(text: " may occur. Rest can help.")
        ])
        let styled = Prompt09MaroonSelectableAnswerText.styledAnswer(document)
        let nsText = answer as NSString

        for symptom in ["Cramps", "breast tenderness"] {
            let range = nsText.range(of: symptom)

            XCTAssertNotEqual(range.location, NSNotFound)

            let style = styled.attribute(
                .underlineStyle,
                at: range.location,
                effectiveRange: nil
            ) as? Int

            XCTAssertEqual(style, NSUnderlineStyle.single.rawValue)
        }

        let ordinaryRange = nsText.range(of: "Rest")

        XCTAssertNotEqual(ordinaryRange.location, NSNotFound)

        XCTAssertNil(
            styled.attribute(
                .underlineStyle,
                at: ordinaryRange.location,
                effectiveRange: nil
            )
        )

        XCTAssertEqual(styled.string, answer)
    }

    func testUnicodeRoundTrip() {
        XCTAssertTrue(Prompt51UnicodeIntegrity.isRoundTripStable("﹒ ⋆ ⋆ ₊⊹ ꩜ 𓂃 ♡"))
    }
}
