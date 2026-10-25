import XCTest
@testable import Fruitfolio

final class Prompt04IntroTests: XCTestCase {
    func testLaunchStorePersistsSignatureCompletionSeparately() async throws {
        let suiteName = "Prompt04IntroTests.\(UUID().uuidString)"

        try await MainActor.run {
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
            defer { defaults.removePersistentDomain(forName: suiteName) }

            let store = IntroLaunchStore(defaults: defaults)
            XCTAssertFalse(store.hasCompletedSignatureIntro)
            store.markSignatureIntroComplete()
            XCTAssertTrue(store.hasCompletedSignatureIntro)

            let reloaded = IntroLaunchStore(defaults: defaults)
            XCTAssertTrue(reloaded.hasCompletedSignatureIntro)
        }
    }

    func testPrompt04RequiredCanonicalAssetsAreRegistered() {
        for id in Prompt04IntroConfiguration.requiredAssetIDs {
            let record = AssetRegistry.record(for: id)
            XCTAssertFalse(record.filename.isEmpty)
            XCTAssertNotEqual(record.status, .awaitingFutureAsset)
        }
    }

    func testAllFivePhysicalBookFilesAreInPrompt04Contract() {
        let requiredBookIDs: Set<FruitfolioAssetID> = [
            .book_closed_blank,
            .book_closed_logo,
            .book_slightly_open_logo,
            .book_page_turn,
            .book_open_blank
        ]
        XCTAssertTrue(requiredBookIDs.isSubset(of: Set(Prompt04IntroConfiguration.requiredAssetIDs)))
    }

    func testStandaloneHubPaperIsPreloaded() {
        XCTAssertTrue(Prompt04IntroConfiguration.requiredAssetIDs.contains(.ask_answer_paper))
    }

    func testAllFinalHubFounderAssetsAreInPrompt04Contract() {
        let requiredHubIDs: Set<FruitfolioAssetID> = [
            .button_mint, .button_sage, .button_peach,
            .button_coral, .button_yellow, .button_lavender,
            .ask_magnifying_glass, .hub_bookshelf, .guide_folder_add,
            .hub_calendar, .hub_basket, .hub_question,
            .hub_envelope, .hub_settings, .hub_account
        ]
        XCTAssertTrue(requiredHubIDs.isSubset(of: Set(Prompt04IntroConfiguration.requiredAssetIDs)))
    }

    func testFounderOverridePacingIsRestrainedAndReadable() {
        XCTAssertEqual(Prompt04IntroConfiguration.initialStillness, .milliseconds(250))
        XCTAssertTrue((.milliseconds(600)...(.milliseconds(700))).contains(Prompt04IntroConfiguration.firstLaunchBookArrival))
        XCTAssertTrue((.milliseconds(650)...(.milliseconds(850))).contains(Prompt04IntroConfiguration.logoReveal))
        XCTAssertTrue((.milliseconds(450)...(.milliseconds(700))).contains(Prompt04IntroConfiguration.rightPageFocus))
        XCTAssertLessThan(Prompt04IntroConfiguration.slightlyOpenTransition, .seconds(1))
        XCTAssertLessThan(Prompt04IntroConfiguration.fullyOpenTransition, .seconds(1))
    }

    func testAllCenteredBookStatesStayInsideSupportedPhoneWidths() {
        for viewport in [
            CGSize(width: 375, height: 667),
            CGSize(width: 393, height: 852),
            CGSize(width: 402, height: 874),
            CGSize(width: 440, height: 956)
        ] {
            let metrics = Prompt04BookLayout.metrics(for: viewport)
            XCTAssertGreaterThan(metrics.closedBookWidth, 0)
            XCTAssertGreaterThan(metrics.brandedBookWidth, 0)
            XCTAssertGreaterThan(metrics.slightlyOpenBookWidth, 0)
            XCTAssertGreaterThan(metrics.centeredOpenBookWidth, 0)
            XCTAssertLessThan(metrics.closedBookWidth, viewport.width)
            XCTAssertLessThan(metrics.brandedBookWidth, viewport.width)
            XCTAssertLessThan(metrics.slightlyOpenBookWidth, viewport.width)
            XCTAssertLessThan(metrics.centeredOpenBookWidth, viewport.width)
        }
    }

    func testFocusedRightPageActuallyZoomsAndMovesLeft() {
        let metrics = Prompt04BookLayout.metrics(for: CGSize(width: 393, height: 852))
        XCTAssertGreaterThan(metrics.focusedBookWidth, metrics.centeredOpenBookWidth)
        XCTAssertLessThan(metrics.focusedBookOffsetX, 0)
        XCTAssertGreaterThan(metrics.focusedBookHeight, metrics.centeredOpenBookHeight)
    }

    func testHubLayoutKeepsThreeEqualUtilityColumns() {
        for viewport in [
            CGSize(width: 375, height: 667),
            CGSize(width: 393, height: 852),
            CGSize(width: 402, height: 874),
            CGSize(width: 440, height: 956)
        ] {
            let metrics = Prompt04BookLayout.metrics(for: viewport)
            XCTAssertGreaterThan(metrics.hubContentWidth, 0)
            XCTAssertGreaterThan(metrics.hubContentHeight, 0)
            XCTAssertEqual(metrics.utilityItemWidth * 3, metrics.hubContentWidth, accuracy: 0.001)
            XCTAssertGreaterThanOrEqual(metrics.hubButtonHeight, 44)
            XCTAssertGreaterThanOrEqual(metrics.utilityIconSize, 24)
        }
    }

    func testLaunchModeSemantics() {
        XCTAssertTrue(Prompt04LaunchMode.firstLaunch.isFirstLaunch)
        XCTAssertFalse(Prompt04LaunchMode.returningLaunch.isFirstLaunch)
        XCTAssertTrue(Prompt04LaunchMode.reducedMotionFirstLaunch.usesReducedMotion)
        XCTAssertTrue(Prompt04LaunchMode.reducedMotionReturningLaunch.usesReducedMotion)
        XCTAssertFalse(Prompt04LaunchMode.firstLaunch.usesReducedMotion)
    }

    #if DEBUG
    func testDebugLaunchOverrideParsing() {
        XCTAssertEqual(
            Prompt04DebugLaunchOverride.resolve(arguments: ["Fruitfolio", "-FruitfolioIntroMode", "first"]),
            .firstLaunch
        )
        XCTAssertEqual(
            Prompt04DebugLaunchOverride.resolve(arguments: ["Fruitfolio", "-FruitfolioIntroMode", "reduced-returning"]),
            .reducedMotionReturningLaunch
        )
        XCTAssertNil(Prompt04DebugLaunchOverride.resolve(arguments: ["Fruitfolio"]))
    }
    #endif
}
