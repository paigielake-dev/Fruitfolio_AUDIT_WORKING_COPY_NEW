import XCTest
import Combine
@testable import Fruitfolio

final class Prompt04IntroTests: XCTestCase {
    func testFirstLaunchScheduledDurationIsSixToEightSeconds() {
        XCTAssertGreaterThanOrEqual(Prompt04IntroConfiguration.firstLaunchDuration, .seconds(6))
        XCTAssertLessThanOrEqual(Prompt04IntroConfiguration.firstLaunchDuration, .seconds(8))
    }

    @MainActor
    func testReducedMotionFirstLaunchRetainsEveryImportantVisualStage() async throws {
        let suite = "Prompt1BReducedSequence.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        let machine = Prompt04IntroStateMachine()
        var stages: Set<Prompt04IntroStage> = []
        let observation = machine.$stage.sink { stages.insert($0) }
        defer {
            observation.cancel()
            machine.cancelSequence()
            audio.stop(category: .music)
            audio.stop(category: .rainAmbience)
        }
        let completed = expectation(description: "Same readable stages with reduced motion")
        machine.start(mode: .reducedMotionFirstLaunch, audioManager: audio, settings: settings) { _ in completed.fulfill() }
        await fulfillment(of: [completed], timeout: 10)
        for stage: Prompt04IntroStage in [.blankBookSettled, .logoRevealing, .brandedBookSettled,
                                         .slightlyOpenSettled, .fullyOpenSettled, .rightPageFocusing,
                                         .standalonePaperResolving, .hubRevealing] {
            XCTAssertTrue(stages.contains(stage), "Missing stage: \(stage)")
        }
    }

    @MainActor
    func testReducedMotionRemainsReducedAfterInterruption() async throws {
        let suite = "Prompt1BIntroResume.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        let machine = Prompt04IntroStateMachine()
        let resumed = expectation(description: "Reduced-motion resume completes using crossfades")
        machine.start(mode: .reducedMotionFirstLaunch, audioManager: audio, settings: settings) { _ in
            XCTFail("The cancelled original sequence must not complete")
        }
        machine.handleBackgrounding(audioManager: audio)
        machine.resolveAfterInterruption(audioManager: audio, completion: { firstLaunch in
            XCTAssertTrue(firstLaunch)
            resumed.fulfill()
        }, wasFirstLaunch: true)
        await fulfillment(of: [resumed], timeout: 4)
        XCTAssertTrue(machine.usesReducedMotion)
        XCTAssertEqual(machine.stage, .introComplete)
        XCTAssertTrue(machine.hubInteractionEnabled)
        audio.stop(category: .music)
        audio.stop(category: .rainAmbience)
    }

    @MainActor
    func testSkipCompletesOnceAndCancelsOriginalSequence() async throws {
        let suite = "Prompt1BSkip.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        let machine = Prompt04IntroStateMachine()
        var completions = 0
        machine.start(mode: .firstLaunch, audioManager: audio, settings: settings) { _ in completions += 1 }
        machine.skipToHub { firstLaunch in
            XCTAssertTrue(firstLaunch)
            completions += 1
        }
        machine.skipToHub { _ in completions += 1 }
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertEqual(completions, 1)
        XCTAssertEqual(machine.stage, .introComplete)
        XCTAssertTrue(machine.hubInteractionEnabled)
        audio.stop(category: .music)
        audio.stop(category: .rainAmbience)
    }

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
