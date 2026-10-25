import XCTest

// Standalone XCTest class: add this file to the FruitfolioUITests target.
// Every test runs against the dedicated, disposable audit simulator.
// These tests deliberately FAIL when a required control cannot be found;
// screenshots alone are not counted as functional passes.
final class FruitfolioDeepCoverageTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private let destinations: [(String, [String])] = [
        ("Ask", ["ask the encyclopedia", "ask"]),
        ("My Encyclopedias", ["my encyclopedias", "encyclopedias"]),
        ("Guide Builder", ["build your own guide", "build guide"]),
        ("Cycle Tracker", ["cycle tracker"]),
        ("Fruit Basket", ["fruit basket"]),
        ("FAQ", ["faq", "frequently asked"]),
        ("Contact", ["contact"]),
        ("Settings", ["settings"]),
        ("Account", ["sign in", "account"])
    ]

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15), "App failed to launch")
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 10) {
            XCTAssertTrue(explore.isHittable, "First-launch dismissal is not hittable")
            explore.tap()
            XCTAssertFalse(
                explore.waitForExistence(timeout: 2),
                "First-launch invitation did not dismiss"
            )
        }
        return app
    }

    private func button(_ app: XCUIApplication, _ words: [String]) -> XCUIElement? {
        for word in words {
            let candidate = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", word)).firstMatch
            if candidate.exists && candidate.isHittable { return candidate }
        }
        return nil
    }

    @discardableResult
    private func tap(_ app: XCUIApplication, _ words: [String], _ context: String) -> XCUIElement {
        guard let match = button(app, words) else {
            record(app, "MISSING_\(context)")
            XCTFail("\(context): expected hittable button matching \(words)")
            return app.buttons.firstMatch
        }
        match.tap()
        return match
    }

    private func record(_ app: XCUIApplication, _ title: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = title
        attachment.lifetime = .keepAlways
        add(attachment)
        print("DEEP_COVERAGE_SCREENSHOT: \(title)")
    }

    
    private func waitForDestination(
        _ app: XCUIApplication,
        _ destination: String,
        timeout: TimeInterval = 12
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            switch destination {
            case "Cycle Tracker":
                if app.staticTexts["your cycle, little by little"].exists ||
                   app.staticTexts["your cycle, with the biology underneath"].exists ||
                   app.staticTexts["Loading cycle setup"].exists ||
                   app.buttons["get started"].exists ||
                   app.descendants(matching: .any)["today"].exists {
                    return true
                }

            case "Contact":
                if app.staticTexts[
                    "questions, feedback, or just a little hello ♡"
                ].exists ||
                   app.buttons.matching(
                    NSPredicate(format: "label CONTAINS[c] %@", "Instagram")
                   ).firstMatch.exists {
                    return true
                }

            default:
                return app.windows.firstMatch.exists
            }

            RunLoop.current.run(
                until: Date().addingTimeInterval(0.2)
            )
        }

        return false
    }

private func open(_ app: XCUIApplication, _ name: String) {
        guard let item = destinations.first(where: { $0.0 == name }) else {
            XCTFail("Unknown destination: \(name)")
            return
        }
        tap(app, item.1, "Hub_\(name)")
        if name == "Cycle Tracker" || name == "Contact" {
            let destinationOpened = waitForDestination(app, name)
            if !destinationOpened {
                print("FRUITFOLIO_NAVIGATION_FAILURE: " + name)
                print("FRUITFOLIO_SCREEN_HIERARCHY_BEGIN")
                print(app.debugDescription)
                print("FRUITFOLIO_SCREEN_HIERARCHY_END")
            }
            XCTAssertTrue(
                destinationOpened,
                "\(name) did not open after Hub navigation"
            )
        } else {
            XCTAssertTrue(app.windows.firstMatch.exists)
        }
        record(app, "Entered_\(name)")
    }

    func test01EveryHubDestinationIsHittable() {
        for (name, _) in destinations {
            let app = launch()
            open(app, name)
            app.terminate()
        }
    }

    func test02AskSuggestedQuestionDoesNotLoseEntireInterface() {
        let app = launch(); open(app, "Ask")
        let before = app.buttons.count
        if let suggestion = button(app, ["what", "how", "why"]) {
            suggestion.tap()
            record(app, "Ask_After_Suggestion")
            XCTAssertTrue(app.windows.firstMatch.exists, "Ask crashed after suggestion")
            XCTAssertGreaterThan(app.buttons.count, 0, "Ask lost all controls")
        } else {
            record(app, "Ask_No_Hittable_Suggestion")
            XCTFail("No suggested question accessible; submit-question lifecycle remains unverified")
        }
        XCTAssertGreaterThan(before, 0)
    }

    // Source audit: the guide cover control is named "change cover" and
    // appears in guide options, not as a "pink cover" button on the initial page.

    func test03GuideBuilderCoverSelectorAccessible() {
        let app = launch()
        open(app, "Guide Builder")
        record(app, "Guide_Initial")

        // A new library has no guide workspace yet.
        if let first = button(app, ["make my first guide"]) {
            first.tap()
            record(app, "Guide_CreatePopup")
        } else if let newGuide = button(app, ["new guide"]) {
            newGuide.tap()
            record(app, "Guide_CreatePopup")
        }

        if app.textFields["ex. my hormone guide"].exists {
            let field = app.textFields["ex. my hormone guide"]
            field.tap()
            field.typeText("Fruitfolio QA Guide")
            record(app, "Guide_NameEntered")

            if let create = button(app, ["create my guide"]) {
                create.tap()
                record(app, "Guide_AfterCreation")
            } else {
                XCTFail("Guide creation button inaccessible")
                return
            }
        }

        // The options button exists inside an opened guide.
        if button(app, ["guide options"]) == nil {
            record(app, "Guide_WorkspaceNotOpen")
            print("GUIDE_TREE: \(app.debugDescription.prefix(12000))")
            XCTFail("Could not reach an opened guide workspace")
            return
        }

        tap(app, ["guide options"], "Guide_Options")
        record(app, "Guide_OptionsOpen")

        guard let cover = button(app, ["change cover"]) else {
            record(app, "Guide_CoverControlMissing")
            XCTFail("Change Cover unavailable after opening guide options")
            return
        }

        cover.tap()
        record(app, "Guide_CoverPicker")

        XCTAssertTrue(
            app.staticTexts["choose a cover"].exists ||
            app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", "cover")
            ).count > 0,
            "Cover picker did not expose its expected controls"
        )
    }


    // The source defines "get started" as a WatercolorPrimaryButton, but
    // accessibility may expose it as another element type or below the fold.
    // Diagnose the actual state instead of assuming app.buttons contains it.

    private func startCycle(_ app: XCUIApplication) -> Bool {
        // Onboarding can resume on an intermediate screen.
        // Never require Get Started if the user is already past it.

        // Persistent simulator state can already be past onboarding.
        // This is a valid tracker state, not an onboarding failure.
        if app.descendants(matching: .any)["today"].exists && app.descendants(matching: .any)["calendar"].exists {
            record(app, "Cycle_AlreadyOnTracker")
            return true
        }

        for attempt in 0..<4 {
            if app.staticTexts.matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@",
                    "when did your latest period begin"
                )
            ).firstMatch.exists {
                record(app, "Cycle_AlreadyAtPeriodStep")
                return true
            }

            if button(app, [
                "continue",
                "i’m not sure",
                "i'm not sure",
                "skip",
                "open my cycle tracker"
            ]) != nil {
                record(app, "Cycle_OnboardingAlreadyStarted")
                return true
            }

            if let start = button(app, ["get started"]) {
                start.tap()
                record(app, "Cycle_AfterGetStarted")
                return true
            }

            if attempt < 3 {
                app.swipeUp()
            }
        }

        record(app, "Cycle_NoRecognizedStep")
        print("CYCLE_TREE: \(app.debugDescription.prefix(14000))")
        return false
    }



    func test04CycleOnboardingCanAdvanceBeyondIntro() {
        let app = launch()
        open(app, "Cycle Tracker")

        XCTAssertTrue(
            startCycle(app),
            "No recognizable Cycle Tracker onboarding state"
        )

        // Do not attempt onboarding actions once the tracker is already open.
        if app.descendants(matching: .any)["today"].exists && app.descendants(matching: .any)["calendar"].exists {
            XCTAssertTrue(app.buttons["today"].exists)
            record(app, "Cycle_ExistingTrackerVerified")
            return
        }

        record(app, "Cycle_BeforeFirstAction")

        if let unsure = button(app, [
            "i’m not sure",
            "i'm not sure"
        ]) {
            unsure.tap()
            record(app, "Cycle_AfterUnsure")
        }

        if let next = button(app, ["continue"]) {
            next.tap()
            record(app, "Cycle_AfterContinue")
            XCTAssertTrue(app.windows.firstMatch.exists)
        } else if let skip = button(app, ["skip"]) {
            skip.tap()
            record(app, "Cycle_AfterSkip")
            XCTAssertTrue(app.windows.firstMatch.exists)
        } else {
            record(app, "Cycle_FirstActionBlocked")
            XCTFail("No accessible action to advance onboarding")
        }
    }




    func test05CycleOnboardingCompleteOrReportFirstBlocker() {
        let app = launch()
        open(app, "Cycle Tracker")

        XCTAssertTrue(
            startCycle(app),
            "Could not identify Cycle Tracker onboarding state"
        )

        if app.descendants(matching: .any)["today"].exists && app.descendants(matching: .any)["calendar"].exists {
            XCTAssertTrue(app.descendants(matching: .any)["calendar"].exists)
            record(app, "Cycle_AlreadyCompletedOnboarding")
            return
        }

        func screenText() -> String {
            app.staticTexts.allElementsBoundByIndex
                .filter { $0.exists }
                .map { $0.label }
                .joined(separator: " | ")
        }

        func choose(_ names: [String]) -> Bool {
            for name in names {
                if let item = button(app, [name]), item.isEnabled {
                    item.tap()
                    return true
                }
            }
            return false
        }

        for step in 1...30 {
            let before = screenText()
            let lower = before.lowercased()

            print("🍓 CYCLE STEP \(step)")
            print("SCREEN BEFORE: \(before.prefix(1200))")

            if let finish = button(app, ["open my cycle tracker"]) {
                finish.tap()
                print("🍓 ONBOARDING COMPLETE — TRACKER OPENED")
                return
            }

            var selected = false

            if lower.contains("period before") {
                selected = choose(["no"])
            } else if lower.contains("predictable") {
                selected = choose([
                    "somewhat predictable",
                    "usually predictable",
                    "fairly predictable",
                    "sometimes",
                    "regular",
                    "irregular",
                    "not predictable",
                    "i'm not sure",
                    "i’m not sure"
                ])
            } else {
                selected = choose([
                    "i'm not sure",
                    "i’m not sure",
                    "not right now",
                    "no",
                    "sometimes",
                    "none",
                    "prefer not to say"
                ])
            }

            print("ANSWER SELECTED: \(selected)")

            var action = "none"

            if let next = button(app, ["continue"]), next.isEnabled {
                next.tap()
                action = "continue"
            } else if let next = button(app, ["next"]), next.isEnabled {
                next.tap()
                action = "next"
            } else if let skip = button(app, ["skip"]), skip.isEnabled {
                skip.tap()
                action = "skip"
            } else if choose(["got it ♡", "got it"]) {
                action = "got it"
            } else {
                print("AVAILABLE CONTROLS:")
                print(String(app.debugDescription.prefix(12000)))
                XCTFail("No valid enabled action at onboarding step \(step)")
                return
            }

            sleep(2)

            let after = screenText()

            print("ACTION: \(action)")
            print("SCREEN AFTER: \(after.prefix(1200))")

            if before == after {
                print("AVAILABLE CONTROLS:")
                print(String(app.debugDescription.prefix(12000)))
                XCTFail(
                    "Onboarding did not advance at step \(step) after \(action)"
                )
                return
            }
        }

        XCTFail("Onboarding did not complete within 30 steps")
    }



    func test06FruitBasketTourAndMenu() {
        let app = launch(); open(app, "Fruit Basket")
        record(app, "FruitBasket_Entry")
        // First-launch tour's Skip route opens How It Works, not the menu.
        if let skip = button(app, ["skip tour"]) {
            skip.tap()
            record(app, "FruitBasket_AfterSkipToRules")
            tap(app, ["fruit basket"], "FruitBasket_RulesReturnHome")
        } else if let close = button(app, ["i'll explore", "got it", "close"]) {
            close.tap()
            record(app, "FruitBasket_After_Overlay")
        }
        guard let menu = button(app, ["how it works", "play", "leaderboard"]) else {
            XCTFail("Fruit Basket home controls blocked by tour or inaccessible")
            return
        }
        let title = menu.label
        menu.tap()
        record(app, "FruitBasket_Selected_\(title)")
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func test07FruitBasketLeaderboardAndTutorialFreshSessions() {
        for name in ["leaderboard", "howItWorks", "play"] {
            let app = launch()
            open(app, "Fruit Basket")

            // A fresh installation presents a ten-step tour over the home
            // buttons. Its final action opens game setup, not the home menu.
            if let skip = button(app, ["skip tour"]) {
                if name == "play" {
                    // Exercise the actual first-run Play route through the tour.
                    for step in 0..<10 {
                        let next = step == 9 ? ["let’s play!", "let's play!"] : ["next"]
                        tap(app, next, "FruitBasket_TourStep_\(step + 1)")
                    }
                    record(app, "FruitBasket_Play_SetupAfterTour")
                    XCTAssertNotNil(button(app, ["let’s play!", "let's play!", "controls", "topic"]),
                                    "Fruit Basket tour did not reach playable setup")
                    app.terminate()
                    continue
                }
                skip.tap()
                // Skipping the tour opens How It Works; use the built-in
                // Fruit Basket navigation control to return to its home menu.
                let home = button(app, ["fruit basket"])
                XCTAssertNotNil(home, "Fruit Basket rules screen has no return-to-home control")
                home?.tap()
            }

            let labels: [String] = name == "leaderboard" ? ["leaderboard"]
                : name == "howItWorks" ? ["how it works"] : ["play"]
            tap(app, labels, "FruitBasket_\(name)")
            record(app, "FruitBasket_\(name)")
            XCTAssertTrue(app.windows.firstMatch.exists, "Fruit Basket lost its window")
            app.terminate()
        }
    }

    func test08ContactLinksAreHittableInFreshSessions() {
        for (name, labels) in [("Instagram", ["Instagram"]), ("TikTok", ["TikTok"]), ("Email", ["email"]), ("Carrd", ["Carrd"])] {
            let app = launch(); open(app, "Contact")
            // Verify the link exists independently of scroll position.
            // Hittability is checked after bringing it into the viewport.
            let target = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", labels[0])).firstMatch
            var found = target.waitForExistence(timeout: 3)
            for _ in 0..<5 where !found {
                app.swipeUp()
                found = target.exists
            }
            XCTAssertTrue(found, "Contact \(name) link missing after scrolling")
            if found && !target.isHittable { app.swipeUp() }
            XCTAssertTrue(target.isHittable, "Contact \(name) link exists but cannot be reached")
            record(app, "Contact_\(name)_BeforeTap")
            // Do not open third-party apps during unattended tests.
            app.terminate()
        }
    }

    func test09SettingsAccessibilityInventoryAndRelaunch() {
        let app = launch(); open(app, "Settings")
        record(app, "Settings_Before")
        let controls = app.buttons.count + app.switches.count + app.sliders.count
        XCTAssertGreaterThan(controls, 1, "Settings has no accessible controls")
        print("DEEP_COVERAGE_SETTINGS_CONTROLS: \(controls)")
        app.terminate(); app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15))
        open(app, "Settings")
        record(app, "Settings_AfterRelaunch")
    }

    func test10AccountPrivacyNavigation() {
        let app = launch(); open(app, "Account")
        if let privacy = button(app, ["privacy"]) {
            privacy.tap(); record(app, "Account_Privacy")
            XCTAssertTrue(app.windows.firstMatch.exists)
        } else {
            record(app, "Account_Privacy_NotVisible")
            XCTFail("Account → Privacy is not hittable without scrolling; needs explicit scroll/identifier test")
        }
    }

    func test11ScreenAccessibilityInventory() {
        for (name, _) in destinations {
            let app = launch(); open(app, name)
            // Avoid stale XCUIElement snapshots while SwiftUI is animating.
            // Capture a stable hierarchy and report empty labels without
            // dereferencing an old indexed element after a UI transition.
            let snapshot = app.debugDescription
            print("DEEP_COVERAGE_ACCESSIBILITY_TREE \(name): \(snapshot.prefix(14000))")
            record(app, "Accessibility_\(name)")
            XCTAssertTrue(app.windows.firstMatch.exists, "\(name) lost its window")
            // Diagnostic only: no false PASS claim for unlabeled buttons.
            print("DEEP_COVERAGE_ACCESSIBILITY_LABEL_AUDIT_REQUIRES_STABLE_SNAPSHOT: \(name)")
            app.terminate()
        }
    }

    func test12BackgroundForegroundForEveryMajorSection() {
        for (name, _) in destinations {
            let app = launch(); open(app, name)
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 10), "\(name) did not recover from background")
            record(app, "Resumed_\(name)")
            app.terminate()
        }
    }
}
