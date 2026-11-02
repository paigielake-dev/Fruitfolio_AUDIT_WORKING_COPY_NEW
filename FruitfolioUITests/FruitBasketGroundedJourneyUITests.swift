import XCTest

final class FruitBasketGroundedJourneyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let frame = XCTAttachment(screenshot: app.screenshot())
        frame.name = name; frame.lifetime = .keepAlways; add(frame)
    }

    private func tap(_ title: String, _ app: XCUIApplication) {
        let button = app.buttons.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch
        fruitfolioReachControl(app, button)
        XCTAssertTrue(button.exists, title)
        button.tap()
    }

    func testActualApprovedQuestionAnswerFeedbackCatchPauseExitAndFreshReentry() throws {
        try verifyQuestionJourney(accessibilitySize: false)
    }

    func testLargestTextApprovedQuestionKeepsBothCompleteChoicesReachableWithoutChangingThePassage() throws {
        try verifyQuestionJourney(accessibilitySize: true)
    }

    func testActualActiveGameBackgroundAndResumeRetainsPausedRoundUntilExplicitResume() throws {
        try verifyQuestionJourney(accessibilitySize: false, backgroundInterruption: true)
    }

    private func verifyQuestionJourney(accessibilitySize: Bool, backgroundInterruption: Bool = false) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        if accessibilitySize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        tap("fruit basket", app)
        let tour = app.buttons["skip tour"]
        if tour.waitForExistence(timeout: 3) { tour.tap(); tap("got it!", app) }
        tap("play", app)
        tap("nutrition", app)
        tap("easy", app)
        tap("let’s play!", app)
        let returning = app.buttons["keep my level"]
        if returning.waitForExistence(timeout: 2) { fruitfolioReachControl(app, returning); returning.tap() }
        let question = app.staticTexts["fruitBasket.researchQuestion"]
        XCTAssertTrue(question.waitForExistence(timeout: 30), "A real approved passage must replace the former unavailable-provider state")
        XCTAssertTrue(question.label.contains("_____"))
        let originalQuestion = question.label
        capture(app, accessibilitySize ? "FruitBasket_ActualApprovedResearchQuestion_Largest" : "FruitBasket_ActualApprovedResearchQuestion")
        // Exercise both complete choices before selecting either. Scrolling must
        // not submit an answer, shorten its evidence, or start the catch timer.
        for index in 0..<2 {
            let answer = app.buttons["fruitBasket.answer.\(index)"]
            fruitfolioReachControl(app, answer)
            XCTAssertEqual(question.label, originalQuestion)
            XCTAssertFalse(app.buttons["pause"].exists)
            capture(app, "FruitBasket_ReachableChoice_\(index)_largest_\(accessibilitySize)")
        }
        var reachedCorrectFeedback = false
        for index in 0..<2 {
            let answer = app.buttons["fruitBasket.answer.\(index)"]
            fruitfolioReachControl(app, answer); answer.tap()
            let catchButton = app.buttons["catch"]
            if catchButton.waitForExistence(timeout: 2) {
                reachedCorrectFeedback = true; break
            }
            XCTAssertTrue(app.buttons["got it ♡"].waitForExistence(timeout: 5))
            capture(app, "FruitBasket_ActualIncorrectAnswerAndOriginalExplanation")
            tap("got it ♡", app)
        }
        XCTAssertTrue(reachedCorrectFeedback, "Both actual choices were tried; one must match the original passage")
        capture(app, "FruitBasket_ActualCorrectFeedback")
        tap("catch", app)
        capture(app, "FruitBasket_ActualStarAndBadFruitInstructions")
        tap("ready ♡", app)
        XCTAssertTrue(app.buttons["pause"].waitForExistence(timeout: 5))
        capture(app, "FruitBasket_ActualLiveGameplayBeforePause")
        if backgroundInterruption {
            XCUIDevice.shared.press(.home)
            var backgrounded = app.wait(for: .runningBackground, timeout: 2)
                || app.wait(for: .runningBackgroundSuspended, timeout: 2)
            let homeState = app.state
            if !backgrounded {
                XCUIApplication(bundleIdentifier: "com.apple.springboard").activate()
                backgrounded = app.wait(for: .runningBackground, timeout: 2)
                    || app.wait(for: .runningBackgroundSuspended, timeout: 2)
            }
            let state = XCTAttachment(string: "Active gameplay Home state=\(homeState.rawValue); final actual state=\(app.state.rawValue); background observed=\(backgrounded)")
            state.name = "FruitBasket_ActualOSBackgroundState"; state.lifetime = .keepAlways; add(state)
            XCTAssertTrue(backgrounded, "A real OS transition is required; a direct model callback is insufficient")
            let springboard = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            springboard.name = "FruitBasket_ActualBackgroundScreen"; springboard.lifetime = .keepAlways; add(springboard)
            Thread.sleep(forTimeInterval: 3)
            app.activate()
            XCTAssertTrue(app.staticTexts["little game menu"].waitForExistence(timeout: 5))
            let resume = app.buttons["resume"]
            fruitfolioReachControl(app, resume)
            let pausedValues = try XCTUnwrap(resume.value as? String)
            XCTAssertTrue(pausedValues.contains("score "))
            capture(app, "FruitBasket_ActualForegroundStillPaused")
            Thread.sleep(forTimeInterval: 3)
            XCTAssertEqual(resume.value as? String, pausedValues, "Paused score, catches, passes and round must remain unchanged")
            XCTAssertFalse(app.buttons["pause"].exists, "Foregrounding must not silently resume gameplay")
            resume.tap()
            XCTAssertTrue(app.buttons["pause"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.staticTexts["little game menu"].exists)
            capture(app, "FruitBasket_ActualExplicitResumeAfterBackground")
        }
        app.buttons["pause"].tap()
        XCTAssertTrue(app.staticTexts["little game menu"].waitForExistence(timeout: 5))
        capture(app, "FruitBasket_ActualPausedRound")
        tap("exit fruit basket", app)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch.waitForExistence(timeout: 10))
        tap("fruit basket", app)
        XCTAssertFalse(app.staticTexts["little game menu"].exists, "Leaving must not retain the previous paused gameplay presentation")
        capture(app, "FruitBasket_ActualFreshReentry")
        tap("play", app)
        tap("nutrition", app)
        tap("let’s play!", app)
        if returning.waitForExistence(timeout: 2) { fruitfolioReachControl(app, returning); returning.tap() }
        XCTAssertTrue(question.waitForExistence(timeout: 30))
        capture(app, "FruitBasket_ActualNextGroundedQuestionAfterReentry")
    }
}
