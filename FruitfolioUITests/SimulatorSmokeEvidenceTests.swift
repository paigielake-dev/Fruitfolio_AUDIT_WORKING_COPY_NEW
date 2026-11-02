import XCTest

final class SimulatorSmokeEvidenceTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testRealIntroAndReachableHub() { verifyIntro(mode: "first") }
    func testRealReducedMotionIntroAndReachableHub() { verifyIntro(mode: "reduced-first") }

    func testSkipControlShowsItsVisibleWordingAndEntersTheLiveHub() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1", "-FruitfolioIntroMode", "first"]
        app.launch()
        let skip = app.buttons["skip introduction"]
        XCTAssertTrue(skip.waitForExistence(timeout: 2))
        XCTAssertTrue(skip.isHittable)
        XCTAssertGreaterThanOrEqual(skip.frame.width, 44)
        XCTAssertGreaterThanOrEqual(skip.frame.height, 44)
        XCTAssertTrue(app.staticTexts["skip tour"].exists, "The real visible wording remains distinct from the action's accessible name")
        let frame = XCTAttachment(screenshot: app.screenshot())
        frame.name = "Intro_ActualBottomLeftSkipControl"; frame.lifetime = .keepAlways; add(frame)
        let start = ContinuousClock.now
        skip.tap()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 2) { explore.tap() }
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        XCTAssertTrue(settings.isHittable)
        let elapsed = start.duration(to: ContinuousClock.now)
        XCTAssertLessThan(elapsed, .seconds(7), "Skip should enter the live Hub without waiting for the full signature sequence")
        let result = XCTAttachment(screenshot: app.screenshot())
        result.name = "Intro_ActualSkippedToLiveHub"; result.lifetime = .keepAlways; add(result)
    }

    @MainActor
    func testActualBackgroundLongerThanTheIntroFreezesItUntilForegroundResume() async throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1", "-FruitfolioIntroMode", "first"]
        app.launch()
        let skip = app.buttons["skip introduction"]
        XCTAssertTrue(skip.waitForExistence(timeout: 2), "Begin while the actual introduction is still present")
        let before = XCTAttachment(screenshot: app.screenshot())
        before.name = "Intro_ActualBeforeHomeInterruption"; before.lifetime = .keepAlways; add(before)
        XCUIDevice.shared.press(.home)
        XCTAssertTrue(app.wait(for: .runningBackground, timeout: 1)
            || app.wait(for: .runningBackgroundSuspended, timeout: 2), "The actual app must leave the foreground")
        // Longer than the entire6–8s signature. This is a real OS lifecycle
        // transition, not a direct call to the view model's pause handler.
        try await Task.sleep(for: .seconds(9))
        app.activate()
        XCTAssertTrue(skip.waitForExistence(timeout: 2),
            "An unfinished introduction must not finish invisibly while the app is backgrounded")
        let resumed = XCTAttachment(screenshot: app.screenshot())
        resumed.name = "Intro_ActualLogicalResumeAfterNineSecondsInBackground"
        resumed.lifetime = .keepAlways; add(resumed)
        XCTAssertTrue(skip.isHittable); skip.tap()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 2) { explore.tap() }
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch.waitForExistence(timeout: 10))
    }

    private func verifyIntro(mode: String) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1", "-FruitfolioIntroMode", mode]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15))
        let launch = XCTAttachment(screenshot: app.screenshot())
        launch.name = "Smoke_" + mode + "_FirstObservedFrameAfterLaunch"
        launch.lifetime = .keepAlways
        add(launch)
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 14) { explore.tap() }
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        XCTAssertTrue(settings.isHittable, "Live Hub controls must be reachable after the intro")
        let hub = XCTAttachment(screenshot: app.screenshot())
        hub.name = "Smoke_" + mode + "_ActualHub"
        hub.lifetime = .keepAlways
        add(hub)
    }
}
