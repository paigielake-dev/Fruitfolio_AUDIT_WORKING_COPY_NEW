import XCTest

final class Prompt1BModalAccessibilityTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testContactFailureUsesMeasuredModalAndRestoresLinkAccess() {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioContactQA", "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioContactReduceMotion"] }
            app.launch()
            let link = app.buttons["contact.link.instagram"]
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            for _ in 0..<8 { if link.isHittable { break }; app.swipeUp() }
            link.tap()
            let close = app.buttons["contact.linkFailure.close"]
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 3))
            XCTAssertFalse(app.buttons["contact.link.email"].exists)
            for _ in 0..<12 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            XCTAssertGreaterThanOrEqual(close.frame.height, 44)
            XCTAssertGreaterThanOrEqual(close.frame.minX, scroll.frame.minX)
            XCTAssertLessThanOrEqual(close.frame.maxX, scroll.frame.maxX)
            XCTAssertGreaterThanOrEqual(close.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(close.frame.maxY, app.frame.maxY)
            close.tap()
            XCTAssertTrue(link.waitForExistence(timeout: 3))
            app.terminate()
        }
    }

    private func launchGame(_ scenario: String, reduced: Bool) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", scenario,
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
        app.launch()
        return app
    }

    private func tapSharedPaperAction(_ name: String, in app: XCUIApplication) {
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let action = app.buttons["fruitPopup.paper.action." + name]
        for _ in 0..<20 { if action.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        action.tap()
    }

    private func captureGame(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testGameClassificationDistinguishesGoodFruitAndBonusStarAtAccessibilitySize() {
        for reduced in [false, true] {
            for scenario in ["good", "star"] {
                let app = launchGame(scenario, reduced: reduced)
                let scroll = app.scrollViews["fruitBasket.classification.scroll"]
                XCTAssertTrue(scroll.waitForExistence(timeout: 5))
                let buttonID = scenario == "star" ? "fruitBasket.classification.catchStar" : "fruitBasket.classification.catchFruit"
                let button = app.buttons[buttonID]
                for _ in 0..<12 { if button.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(button.isHittable)
                captureGame(app, name: "game-\(scenario)-reduced-\(reduced)-before")
                button.tap()
                let basket = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.basket").firstMatch
                let passes = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.passes").firstMatch
                for _ in 0..<12 { if basket.isHittable { break }; scroll.swipeDown() }
                let expectedBasket = scenario == "star" ? "0 / 10" : "1 / 10"
                let expectedPasses = scenario == "star" ? "1" : "0"
                let updatedBasket = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expectedBasket), object: basket)
                let updatedPasses = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expectedPasses), object: passes)
                XCTAssertEqual(XCTWaiter.wait(for: [updatedBasket, updatedPasses], timeout: 5), .completed)
                captureGame(app, name: "game-\(scenario)-reduced-\(reduced)-settled")
                app.terminate()
            }
        }
    }

    func testGameActualResultsExposeSevenFruitFailureAndTenFruitSuccess() {
        for reduced in [false, true] {
            for scenario in ["failure", "success"] {
                let app = launchGame(scenario, reduced: reduced)
                let count = app.descendants(matching: .any).matching(identifier: "fruitBasket.result.fruitCount").firstMatch
                XCTAssertTrue(count.waitForExistence(timeout: 5))
                let expected = scenario == "success" ? "10 / 10" : "7 / 10"
                XCTAssertTrue((count.label + " " + String(describing: count.value ?? "")).contains(expected))
                captureGame(app, name: "game-\(scenario)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testGameStormUsesLargeCardAndExcludesBackgroundUntilAcknowledged() {
        for reduced in [false, true] {
            let app = launchGame("storm", reduced: reduced)
            let note = app.otherElements.matching(identifier: "fruitBasket.stormNote").firstMatch
            XCTAssertTrue(note.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["fruitBasket.classification.catchFruit"].exists)
            let acknowledge = app.buttons["got it"]
            for _ in 0..<12 { if acknowledge.isHittable { break }; note.swipeUp() }
            XCTAssertTrue(acknowledge.isHittable)
            captureGame(app, name: "game-storm-reduced-\(reduced)")
            acknowledge.tap()
            XCTAssertTrue(app.scrollViews["fruitBasket.classification.scroll"].waitForExistence(timeout: 3))
            app.terminate()
        }
    }

    func testGameRulesAndLeaderboardCapturePortraitAndLandscapeAtAccessibilitySize() {
        for scenario in ["rules", "leaderboard"] {
            let app = launchGame(scenario, reduced: true)
            let marker = scenario == "rules" ? app.staticTexts["how it works!"] : app.textFields["fruitBasket.publicUsername"]
            if !marker.waitForExistence(timeout: 5) { XCTFail("Missing game QA state: \(scenario)") }
            captureGame(app, name: "game-\(scenario)-portrait")
            XCUIDevice.shared.orientation = .landscapeLeft
            captureGame(app, name: "game-\(scenario)-landscape")
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }

    func testNestedHostReusesOneRootCharacterPopupAndExcludesAllBackground() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioCitationQA", "-fruitfolioCitationReduceMotion",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let open = app.buttons["citationQA.characterPopup"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        for _ in 0..<10 { if open.isHittable { break }; app.swipeUp() }
        open.tap()
        let popupScroll = app.scrollViews.matching(identifier: "fruitPopup.scroll")
        XCTAssertTrue(popupScroll.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(popupScroll.count, 1)
        XCTAssertFalse(app.buttons["citationQA.background"].exists)
        let close = app.buttons["fruitPopup.action.primary"]
        for _ in 0..<12 { if close.isHittable { break }; popupScroll.firstMatch.swipeUp() }
        XCTAssertTrue(close.isHittable)
        captureGame(app, name: "one-root-character-popup")
        close.tap()
        XCTAssertTrue(app.buttons["citationQA.background"].waitForExistence(timeout: 3))
        app.terminate()
    }

    func testSourceLinkFailureUsesOneRootPaperPopupAndRestoresWholePageAccess() {
        for inSheet in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioCitationQA", "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioCitationReduceMotion"] }
            if inSheet { app.launchArguments += ["-fruitfolioCitationQAInSheet"] }
            app.launch()
            let source = app.buttons["sourceCitation.open.qa-citation"]
            XCTAssertTrue(source.waitForExistence(timeout: 5))
            for _ in 0..<12 { if source.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(source.isHittable)
            XCTAssertGreaterThanOrEqual(source.frame.height, 44)
            XCTAssertGreaterThanOrEqual(source.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(source.frame.maxX, app.frame.maxX)
            source.tap()
            let paper = app.otherElements.matching(identifier: "fruitPopup.tapedWhite")
            XCTAssertTrue(paper.firstMatch.waitForExistence(timeout: 3))
            XCTAssertEqual(paper.count, 1)
            XCTAssertFalse(app.buttons["citationQA.background"].exists)
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            let close = app.buttons["fruitPopup.paper.action.primary"]
            for _ in 0..<12 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            captureGame(app, name: "citation-paper-inSheet-\(inSheet)-reduced-\(reduced)")
            close.tap()
            XCTAssertTrue(source.waitForExistence(timeout: 3))
            for _ in 0..<16 { if source.isHittable { break }; app.swipeUp() }
            source.tap()
            XCTAssertTrue(paper.firstMatch.waitForExistence(timeout: 3))
            XCTAssertEqual(paper.count, 1)
            for _ in 0..<16 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            close.tap()
            let background = app.buttons["citationQA.background"]
            XCTAssertTrue(background.waitForExistence(timeout: 3))
            for _ in 0..<12 { if background.isHittable { break }; app.swipeDown() }
            background.tap()
            XCTAssertTrue(app.staticTexts["background actions: 1"].exists)
            app.terminate()
        }
        }
    }

    func testSeriousBasketRevealRetainsActualBestWithoutCelebrationOrCheer() {
        for serious in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", serious ? "success-serious" : "success",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference", "-fruitfolioAudioDiagnostics",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion", "-fruitfolioAudioMuted"] }
            app.launch()
            let heading = app.descendants(matching: .any).matching(identifier: "fruitBasket.result.heading").firstMatch
            XCTAssertTrue(heading.waitForExistence(timeout: 5))
            XCTAssertEqual(heading.label, serious ? "round complete" : "your basket reveal! ♡")
            XCTAssertEqual(app.staticTexts["gameQA.actualPersonalBest"].label, "actual personal best: true")
            let summary = app.descendants(matching: .any).matching(identifier: "fruitBasket.result.basketSummary").firstMatch
            XCTAssertEqual(summary.label, "completed basket. personal best.")
            XCTAssertEqual((summary.value as? String ?? "").compactMap(\.wholeNumberValue), [1, 0, 1, 0])
            let art = app.staticTexts["gameQA.celebrationArtActive"]
            let expectedArt = "celebration art active: \(!serious)"
            let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expectedArt), object: art)
            XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 3), .completed)
            let cheer = "gentle cheer requests: \(serious ? 0 : 1)"
            XCTAssertEqual(app.staticTexts["audioQA.cheerRequests"].label, cheer)
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(heading.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["audioQA.cheerRequests"].label, cheer)
            XCTAssertEqual(app.staticTexts["gameQA.actualPersonalBest"].label, "actual personal best: true")
            captureGame(app, name: "reveal-serious-\(serious)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testProtectedGameRecoveryReloadAndBackgroundPreserveOriginalBytesAndOwner() {
        for scenario in ["protected-progress-top", "protected-progress-null"] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", scenario,
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let recovery = app.scrollViews["fruitBasket.progressRecovery"]
            XCTAssertTrue(recovery.waitForExistence(timeout: 5))
            let heading = app.descendants(matching: .any).matching(identifier: "fruitBasket.progressRecovery.heading").firstMatch
            XCTAssertEqual(heading.label, "game progress is protected")
            XCTAssertFalse(app.buttons["fruitBasket.gameplay.pause"].exists)
            XCTAssertFalse(app.buttons["fruitBasket.pause.resetLevel"].exists)
            let owner = app.staticTexts["gameQA.recoveryOwner"].label
            XCTAssertTrue(owner.hasPrefix("recovery owner: "))
            let reload = app.buttons["fruitBasket.progressRecovery.reload"]
            for attempt in 0..<2 {
                if attempt == 1 { XCUIDevice.shared.press(.home); app.activate() }
                XCTAssertTrue(recovery.waitForExistence(timeout: 5))
                for _ in 0..<24 { if reload.isHittable { break }; recovery.swipeUp() }
                XCTAssertTrue(reload.isHittable)
                XCTAssertGreaterThanOrEqual(reload.frame.height, 44)
                reload.tap()
                XCTAssertTrue(recovery.exists)
                XCTAssertEqual(app.staticTexts["gameQA.protectedStore"].label, "protected store: true")
                XCTAssertEqual(app.staticTexts["gameQA.protectedBlobIntact"].label, "protected blob intact: true")
                XCTAssertEqual(app.staticTexts["gameQA.recoveryOwner"].label, owner)
                XCTAssertFalse(app.buttons["fruitBasket.gameplay.pause"].exists)
            }
            captureGame(app, name: "protected-game-\(scenario)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testSharedGameLevelResetPreservesOriginAndConservedProgress() {
        for origin in ["paused", "result"] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
        for confirm in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "reset-" + origin,
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let reset = app.buttons[origin == "paused" ? "fruitBasket.pause.resetLevel" : "fruitBasket.result.resetLevel"]
            XCTAssertTrue(reset.waitForExistence(timeout: 5))
            let scroll = origin == "paused" ? app.scrollViews["fruitBasket.pause.scroll"] : app.scrollViews.firstMatch
            for _ in 0..<24 { if reset.isHittable { break }; scroll.swipeUp() }
            let level = app.staticTexts["gameQA.storedCurrentLevel"]
            let originalLevel = level.label
            let totals = app.staticTexts["gameQA.conservedTotals"].label
            XCTAssertNotEqual(originalLevel, "stored current level: 1")
            XCTAssertFalse(totals.isEmpty)
            reset.tap()
            XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 3))
            XCTAssertFalse(reset.exists)
            tapSharedPaperAction(confirm ? "secondary" : "primary", in: app)
            let expected = confirm ? "stored current level: 1" : originalLevel
            let updated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: level)
            XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 5), .completed)
            XCTAssertEqual(app.staticTexts["gameQA.conservedTotals"].label, totals)
            if confirm {
                XCTAssertFalse(reset.exists)
                XCTAssertEqual(app.staticTexts["gameQA.screen"].label, "game screen: learningSetup")
            } else {
                XCTAssertTrue(reset.waitForExistence(timeout: 3))
                XCTAssertFalse(app.scrollViews["tapedWhitePopup.scroll"].exists)
            }
            captureGame(app, name: "reset-origin-\(origin)-language-\(language)-reduced-\(reduced)-confirm-\(confirm)")
            app.terminate()
        }
        }
        }
        }
    }

    func testMovingFruitAndStandaloneStarRetainDistinctTranslatedAccessibility() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "catch-objects",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let pear = app.descendants(matching: .any).matching(identifier: "fruitBasket.round.fruit.pear").firstMatch
            let lemon = app.descendants(matching: .any).matching(identifier: "fruitBasket.round.fruit.lemon").firstMatch
            let star = app.descendants(matching: .any).matching(identifier: "fruitBasket.round.star").firstMatch
            XCTAssertTrue(pear.waitForExistence(timeout: 5))
            XCTAssertEqual(pear.label, "pear, belongs in basket")
            XCTAssertEqual(lemon.label, "lemon, does not belong in basket")
            XCTAssertEqual(star.label, "star pass")
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "fruitBasket.round.star").count, 1)
            XCTAssertFalse(pear.label.contains("**"))
            XCTAssertFalse(lemon.label.contains("**"))
            captureGame(app, name: "catch-object-labels-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testBasketArtworkUsesSeparateLocalizedLabelAndNumericValue() {
        for catchMode in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", catchMode ? "hud-catch" : "hud-classification",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let identifier = catchMode ? "fruitBasket.round.basket" : "fruitBasket.classification.basketArt"
            let basket = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            XCTAssertTrue(basket.waitForExistence(timeout: 5))
            if !catchMode {
                let scroll = app.scrollViews["fruitBasket.classification.scroll"]
                for _ in 0..<24 { if basket.isHittable { break }; scroll.swipeUp() }
            }
            XCTAssertEqual(basket.label, "basket")
            let value = basket.value as? String ?? ""
            XCTAssertEqual(value.compactMap(\.wholeNumberValue), [0, 1, 0])
            XCTAssertEqual(value.contains("on dry ground"), catchMode)
            XCTAssertFalse(value.contains("in a puddle"))
            XCTAssertFalse(basket.label.contains("0"))
            captureGame(app, name: "basket-catch-\(catchMode)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testClassificationLocalizedPresentationRetainsRealCatchAndPassLedger() {
        for serious in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", serious ? "good-serious" : "good",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let scroll = app.scrollViews["fruitBasket.classification.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 5))
            let fruit = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.fruit").firstMatch
            XCTAssertTrue(fruit.label.contains("pear. attached star marker."))
            let basket = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.basket").firstMatch
            let value = basket.value as? String ?? ""
            XCTAssertEqual(value.compactMap(\.wholeNumberValue), [0, 1, 0])
            let catchFruit = app.buttons["fruitBasket.classification.catchFruit"]
            let passFruit = app.buttons["fruitBasket.classification.passFruit"]
            for _ in 0..<24 { if catchFruit.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(catchFruit.isHittable)
            XCTAssertTrue(catchFruit.label.contains(serious ? "catch fruit" : "yes ♡"))
            XCTAssertTrue(passFruit.label.contains(serious ? "let fruit pass" : "nope!"))
            catchFruit.tap()
            let actualCount = app.staticTexts["gameQA.rawBasketCount"]
            let caught = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "raw basket count: 1"), object: actualCount)
            XCTAssertEqual(XCTWaiter.wait(for: [caught], timeout: 5), .completed)
            XCTAssertEqual(app.staticTexts["gameQA.rawSessionScore"].label, "raw session score: 10")
            let basketArt = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.basketArt").firstMatch
            XCTAssertEqual((basketArt.value as? String ?? "").compactMap(\.wholeNumberValue), [1, 1, 0])
            for _ in 0..<24 { if passFruit.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(passFruit.isHittable)
            passFruit.tap()
            XCTAssertEqual(actualCount.label, "raw basket count: 1")
            XCTAssertEqual(app.staticTexts["gameQA.rawSessionScore"].label, "raw session score: 10")
            captureGame(app, name: "classification-serious-\(serious)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testPauseMenuOwnsOneCuePairAcrossBackgroundResumeAndEscapeHandler() {
        for actionID in ["fruitBasket.pause.resume", "gameQA.pauseEscape"] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "hud-classification",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-fruitfolioAudioDiagnostics", "-fruitfolioGameQAEscape",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion", "-fruitfolioAudioMuted"] }
            app.launch()
            let pause = app.buttons["fruitBasket.gameplay.pause"]
            XCTAssertTrue(pause.waitForExistence(timeout: 5))
            let header = app.scrollViews["fruitBasket.gameplayHeader.scroll"]
            for presentation in 1...2 {
                for _ in 0..<16 { if pause.isHittable { break }; header.swipeDown() }
                XCTAssertTrue(pause.isHittable)
                pause.tap()
                let menu = app.scrollViews["fruitBasket.pause.scroll"]
                XCTAssertTrue(menu.waitForExistence(timeout: 3))
                XCTAssertFalse(pause.exists)
                XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "fruitBasket.pause.heading").firstMatch.exists)
                let opened = app.staticTexts["audioQA.openRequests"]
                let openOnce = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
                    "popup open requests: \(presentation)"), object: opened)
                XCTAssertEqual(XCTWaiter.wait(for: [openOnce], timeout: 3), .completed)
                XCUIDevice.shared.press(.home)
                app.activate()
                XCTAssertTrue(menu.waitForExistence(timeout: 5))
                XCTAssertEqual(opened.label, "popup open requests: \(presentation)")
                XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: \(presentation - 1)")
                let action = app.buttons[actionID]
                for _ in 0..<24 { if action.isHittable { break }; menu.swipeUp() }
                XCTAssertTrue(action.isHittable)
                action.tap()
                XCTAssertTrue(pause.waitForExistence(timeout: 3))
                let closed = app.staticTexts["audioQA.closeRequests"]
                let closeOnce = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
                    "popup close requests: \(presentation)"), object: closed)
                XCTAssertEqual(XCTWaiter.wait(for: [closeOnce], timeout: 3), .completed)
            }
            captureGame(app, name: "pause-action-\(actionID)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testGameplayHeaderReservesASeparateVisiblePlayfieldAtAccessibilitySize() {
        for scenario in ["hud-catch", "hud-classification"] {
        for language in ["en", "ar"] {
        for landscape in [false, true] {
        for reduced in [false, true] {
            XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", scenario,
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let header = app.scrollViews["fruitBasket.gameplayHeader.scroll"]
            XCTAssertTrue(header.waitForExistence(timeout: 5))
            let field = app.descendants(matching: .any).matching(identifier: "fruitBasket.playfield").firstMatch
            XCTAssertTrue(field.exists)
            XCTAssertGreaterThanOrEqual(field.frame.height, 132)
            XCTAssertGreaterThanOrEqual(field.frame.minY, header.frame.maxY - 1)
            XCTAssertLessThanOrEqual(field.frame.maxY, app.frame.maxY + 1)
            if scenario == "hud-catch" {
                let basket = app.descendants(matching: .any).matching(identifier: "fruitBasket.round.basket").firstMatch
                XCTAssertTrue(basket.exists)
                XCTAssertGreaterThanOrEqual(basket.frame.minY, field.frame.minY - 1)
                XCTAssertLessThanOrEqual(basket.frame.maxY, field.frame.maxY + 1)
            }
            let pause = app.buttons["fruitBasket.gameplay.pause"]
            for _ in 0..<12 { if pause.isHittable { break }; header.swipeDown() }
            XCTAssertTrue(pause.isHittable)
            XCTAssertGreaterThanOrEqual(pause.frame.height, 44)
            captureGame(app, name: "hud-\(scenario)-language-\(language)-landscape-\(landscape)-reduced-\(reduced)")
            pause.tap()
            let menu = app.scrollViews["fruitBasket.pause.scroll"]
            XCTAssertTrue(menu.waitForExistence(timeout: 3))
            XCTAssertFalse(pause.exists)
            let resume = app.buttons["fruitBasket.pause.resume"]
            for _ in 0..<12 { if resume.isHittable { break }; menu.swipeDown() }
            XCTAssertTrue(resume.isHittable)
            resume.tap()
            XCTAssertTrue(header.waitForExistence(timeout: 3))
            app.terminate()
        }
        }
        }
        }
        XCUIDevice.shared.orientation = .portrait
    }

    func testStormModalOwnsFocusBoundaryAndOneCloseAcrossAllDismissalHandlers() {
        for serious in [false, true] {
        for actionID in ["fruitBasket.storm.close", "fruitBasket.storm.acknowledge", "gameQA.stormEscape"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", serious ? "storm-serious" : "storm",
                "-fruitfolioAudioDiagnostics", "-fruitfolioGameQAEscape",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion", "-fruitfolioGameRTL", "-fruitfolioAudioMuted"] }
            app.launch()
            let note = app.otherElements["fruitBasket.stormNote"]
            XCTAssertTrue(note.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["fruitBasket.classification.catchFruit"].exists)
            let heading = app.descendants(matching: .any).matching(identifier: "fruitBasket.storm.heading").firstMatch
            XCTAssertEqual(heading.label, serious ? "a rain obstacle is active." : "uh oh! a little storm is passing. o__o")
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(note.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 0")
            let action = app.buttons[actionID]
            for _ in 0..<24 {
                if action.isHittable { break }
                if actionID == "fruitBasket.storm.close" { note.swipeDown() } else { note.swipeUp() }
            }
            XCTAssertTrue(action.isHittable)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            action.tap()
            XCTAssertFalse(note.exists)
            XCTAssertTrue(app.scrollViews["fruitBasket.classification.scroll"].waitForExistence(timeout: 3))
            let closed = app.staticTexts["audioQA.closeRequests"]
            let once = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "popup close requests: 1"), object: closed)
            XCTAssertEqual(XCTWaiter.wait(for: [once], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            captureGame(app, name: "storm-serious-\(serious)-action-\(actionID)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testGameTutorialBackgroundKeepsPageAndEscapeHandlerClosesOnePresentation() {
        for language in ["en", "ar"] {
        for muted in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "tour",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-fruitfolioAudioDiagnostics", "-fruitfolioGameQAEscape",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let next = app.buttons["fruitBasket.tour.next"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            for _ in 0..<2 {
                for _ in 0..<24 { if next.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(next.isHittable)
                next.tap()
            }
            let counter = app.descendants(matching: .any).matching(identifier: "fruitBasket.tour.step").firstMatch
            let beforeBackground = counter.value as? String
            XCTAssertNotNil(beforeBackground)
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 0")
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            XCTAssertEqual(counter.value as? String, beforeBackground)
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 0")
            let escape = app.buttons["gameQA.tourEscape"]
            for _ in 0..<24 { if escape.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(escape.isHittable)
            escape.tap() // Invokes the same real handler as the accessibility escape action.
            XCTAssertFalse(next.exists)
            XCTAssertEqual(app.staticTexts["gameQA.screen"].label, "game screen: howItWorks")
            XCTAssertEqual(app.staticTexts["gameQA.tourCompleted"].label, "tour completed: true")
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 1")
            captureGame(app, name: "game-tour-background-language-\(language)-muted-\(muted)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testGameTutorialKeepsTenStepsAndRealCompletionAcrossLocaleFallback() throws {
        for skip in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "tour",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let next = app.buttons["fruitBasket.tour.next"]
            XCTAssertTrue(next.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["gameQA.tourCompleted"].label, "tour completed: false")
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: language)
            formatter.numberStyle = .decimal
            if skip {
                let skipButton = app.buttons["fruitBasket.tour.skip"]
                for _ in 0..<24 { if skipButton.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(skipButton.isHittable)
                XCTAssertGreaterThanOrEqual(skipButton.frame.height, 44)
                skipButton.tap()
                XCTAssertEqual(app.staticTexts["gameQA.screen"].label, "game screen: howItWorks")
            } else {
                for step in 1...10 {
                    let counter = app.descendants(matching: .any).matching(identifier: "fruitBasket.tour.step").firstMatch
                    let number = try XCTUnwrap(formatter.string(from: NSNumber(value: step)))
                    let total = try XCTUnwrap(formatter.string(from: 10))
                    XCTAssertEqual(counter.value as? String, number + " / " + total)
                    for _ in 0..<24 { if next.isHittable { break }; scroll.swipeUp() }
                    XCTAssertTrue(next.isHittable)
                    XCTAssertGreaterThanOrEqual(next.frame.height, 44)
                    next.tap()
                }
                XCTAssertEqual(app.staticTexts["gameQA.screen"].label, "game screen: learningSetup")
            }
            XCTAssertFalse(next.exists)
            XCTAssertEqual(app.staticTexts["gameQA.tourCompleted"].label, "tour completed: true")
            captureGame(app, name: "game-tour-skip-\(skip)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testOriginalTranslationControlUsesCanonicalSelectionAndSingleCueWithRealCatalog() {
        for muted in [false, true] {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioTranslationDisclosureQA",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            if reduced { app.launchArguments += ["-fruitfolioTranslationDisclosureReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioTranslationDisclosureRTL"] }
            app.launch()
            let display = app.descendants(matching: .any).matching(identifier: "translationQA.displayed").firstMatch
            let target = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "fixture cible"), object: display)
            XCTAssertEqual(XCTWaiter.wait(for: [target], timeout: 5), .completed)
            let toggle = app.buttons["translation.originalToggle"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 3))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<12 { if toggle.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(toggle.isHittable)
            XCTAssertGreaterThanOrEqual(toggle.frame.height, 44)
            XCTAssertGreaterThanOrEqual(toggle.frame.width, 44)
            XCTAssertFalse(toggle.isSelected)
            let original = app.descendants(matching: .any).matching(identifier: "translation.originalText").firstMatch
            XCTAssertFalse(original.exists)
            toggle.tap()
            XCTAssertTrue(toggle.isSelected)
            XCTAssertTrue(original.waitForExistence(timeout: 3))
            XCTAssertEqual(original.label, "fixture source")
            XCTAssertEqual(display.label, "fixture cible")
            toggle.tap()
            XCTAssertFalse(toggle.isSelected)
            XCTAssertFalse(original.exists)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
            XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 2)")
            captureGame(app, name: "original-control-muted-\(muted)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testFailedAttemptKeepsLedgerValuesWhileLabelsAndNumberLocaleChange() throws {
        for serious in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", serious ? "failure-serious" : "failure",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let count = app.descendants(matching: .any).matching(identifier: "fruitBasket.result.fruitCount").firstMatch
            XCTAssertTrue(count.waitForExistence(timeout: 5))
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: language)
            formatter.numberStyle = .decimal
            let seven = try XCTUnwrap(formatter.string(from: 7))
            let ten = try XCTUnwrap(formatter.string(from: 10))
            XCTAssertEqual(count.value as? String, seven + " / " + ten)
            XCTAssertEqual(app.staticTexts["gameQA.rawResultFruit"].label, "raw fruit count: 7 / 10")
            let retry = app.buttons["fruitBasket.failure.retry"]
            let scroll = app.scrollViews["fruitBasket.failure.scroll"]
            for _ in 0..<24 { if retry.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(retry.isHittable)
            XCTAssertGreaterThanOrEqual(retry.frame.height, 44)
            if serious { XCTAssertFalse(retry.label.contains("♡")) }
            if language == "en" {
                let feedback = serious ? "that catch attempt ended. review the visual catch rule before retrying."
                    : "oopsie :,) that one didn’t belong in this basket."
                XCTAssertTrue(app.staticTexts[feedback].exists)
            }
            captureGame(app, name: "failed-result-serious-\(serious)-language-\(language)-reduced-\(reduced)")
            retry.tap()
            XCTAssertTrue(app.scrollViews["fruitBasket.classification.scroll"].waitForExistence(timeout: 3))
            XCTAssertFalse(app.staticTexts["gameQA.rawResultFruit"].exists)
            app.terminate()
        }
        }
        }
    }

    func testGameFeedbackKeepsSeriousSelectionAndExactQuestionAcrossTranslationFallback() {
        for serious in [false, true] {
        for correct in [false, true] {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario",
                serious ? "question-excerpt-serious" : "question-excerpt",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let scroll = app.scrollViews["fruitBasket.question.scroll"]
            let answer = app.buttons["fruitBasket.question.answer." + (correct ? "first" : "second")]
            XCTAssertTrue(answer.waitForExistence(timeout: 5))
            for _ in 0..<24 { if answer.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(answer.isHittable)
            answer.tap()
            let feedbackID = correct ? "fruitBasket.question.correctFeedback" : "fruitBasket.question.incorrectFeedback"
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: feedbackID).firstMatch.waitForExistence(timeout: 3))
            if language == "en" {
                let expected: String
                if correct {
                    expected = serious ? "that answer matches the source. continue when you’re ready." : "YAYYY! catch your fruit! :-)"
                } else {
                    expected = serious ? "that answer does not match the original source. review the excerpt and its citations below."
                        : "not quite :,) here’s the little reason why."
                }
                XCTAssertTrue(app.staticTexts[expected].exists)
            }
            let action = app.buttons[correct ? "fruitBasket.question.correctContinue" : "fruitBasket.question.review"]
            for _ in 0..<24 { if action.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(action.isHittable)
            action.tap()
            if correct {
                XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "fruitBasket.question.catchRule").firstMatch.exists)
                XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "fruitBasket.question.catchLegend").firstMatch.exists)
            } else {
                XCTAssertFalse(app.descendants(matching: .any).matching(identifier: feedbackID).firstMatch.exists)
            }
            let excerpt = app.descendants(matching: .any).matching(identifier: "fruitBasket.question.literalExcerpt").firstMatch
            XCTAssertEqual(excerpt.label, "UI fixture only: the selected word is [blank].")
            XCTAssertEqual(app.buttons["fruitBasket.question.answer.first"].label, "first")
            captureGame(app, name: "game-feedback-serious-\(serious)-correct-\(correct)-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
        }
    }

    func testCorrectAnswerNavigationOwnsOnlyItsCanonicalPopWhileStarBankKeepsItsEventCue() {
        for muted in [false, true] {
        for reduced in [false, true] {
        for scenario in ["question-excerpt", "star"] {
            XCUIDevice.shared.orientation = .portrait
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", scenario,
                "-fruitfolioGameQAPauseInference", "-fruitfolioAudioDiagnostics",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            if scenario == "question-excerpt" {
                let scroll = app.scrollViews["fruitBasket.question.scroll"]
                let answer = app.buttons["fruitBasket.question.answer.first"]
                XCTAssertTrue(answer.waitForExistence(timeout: 5))
                for _ in 0..<24 { if answer.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(answer.isHittable)
                answer.tap()
                let proceed = app.buttons["fruitBasket.question.correctContinue"]
                XCTAssertTrue(proceed.waitForExistence(timeout: 3))
                for _ in 0..<24 { if proceed.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(proceed.isHittable)
                proceed.tap()
                XCTAssertTrue(app.buttons["fruitBasket.question.continue"].waitForExistence(timeout: 3))
                XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
                XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 2)")
                XCTAssertEqual(app.staticTexts["audioQA.starChimeRequests"].label, "star chime requests: 0")
            } else {
                let catchStar = app.buttons["fruitBasket.classification.catchStar"]
                XCTAssertTrue(catchStar.waitForExistence(timeout: 5))
                let scroll = app.scrollViews["fruitBasket.classification.scroll"]
                for _ in 0..<24 { if catchStar.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(catchStar.isHittable)
                catchStar.tap()
                let star = app.staticTexts["audioQA.starChimeRequests"]
                let earned = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "star chime requests: 1"), object: star)
                XCTAssertEqual(XCTWaiter.wait(for: [earned], timeout: 5), .completed)
                XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 1")
                XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 1)")
            }
            captureGame(app, name: "game-cue-\(scenario)-muted-\(muted)-reduced-\(reduced)")
            app.terminate()
        }
        }
        }
    }

    func testExactExcerptQuestionScrollsWithoutTranslatingItsWordMatchingChoices() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "question-excerpt",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let instruction = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.question.instruction").firstMatch
            XCTAssertTrue(instruction.waitForExistence(timeout: 5))
            let excerpt = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.question.literalExcerpt").firstMatch
            XCTAssertEqual(excerpt.label, "UI fixture only: the selected word is [blank].")
            let notice = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.question.sourceLanguageNotice").firstMatch
            XCTAssertTrue(notice.exists)
            let scroll = app.scrollViews["fruitBasket.question.scroll"]
            XCTAssertTrue(scroll.exists)
            let first = app.buttons["fruitBasket.question.answer.first"]
            let second = app.buttons["fruitBasket.question.answer.second"]
            for _ in 0..<24 { if second.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(second.isHittable)
            XCTAssertEqual(first.label, "first")
            XCTAssertEqual(second.label, "second")
            XCTAssertGreaterThanOrEqual(first.frame.height, 44)
            for _ in 0..<12 { if first.isHittable { break }; scroll.swipeDown() }
            XCTAssertTrue(first.isHittable)
            first.tap()
            XCTAssertTrue(app.buttons["fruitBasket.question.correctContinue"].waitForExistence(timeout: 3))
            captureGame(app, name: "source-excerpt-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testFAQQuestionTranslationFallbackRetainsDisclosureAndSingleCueOwnership() {
        for arabic in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioFAQQA", "-fruitfolioFAQQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if arabic { app.launchArguments += ["-fruitfolioFAQQAArabic"] }
            if reduced { app.launchArguments += ["-fruitfolioFAQQAReduceMotion"] }
            app.launch()
            let question = app.buttons["faq.question.about-1"]
            XCTAssertTrue(question.waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<12 { if question.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(question.isHittable)
            XCTAssertGreaterThanOrEqual(question.frame.height, 44)
            XCTAssertGreaterThanOrEqual(question.frame.width, 44)
            XCTAssertFalse(question.label.isEmpty)
            let collapsed = question.value as? String
            XCTAssertNotNil(collapsed)
            if !arabic { XCTAssertEqual(collapsed, "collapsed") }
            question.tap()
            let answer = app.descendants(matching: .any)
                .matching(identifier: "faq.answer.about-1").firstMatch
            XCTAssertTrue(answer.waitForExistence(timeout: 3))
            XCTAssertNotEqual(question.value as? String, collapsed)
            if !arabic { XCTAssertEqual(question.value as? String, "expanded") }
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 1")
            question.tap()
            XCTAssertFalse(answer.exists)
            XCTAssertEqual(question.value as? String, collapsed)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
            captureGame(app, name: "faq-disclosure-arabic-\(arabic)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testLeaderboardTotalUsesAppNumberLocaleWithoutChangingStoredCount() throws {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "leaderboard",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let category = app.buttons["fruitBasket.leaderboard.category.highest level"]
            XCTAssertTrue(category.waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<24 { if category.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(category.isHittable)
            category.tap()
            let total = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.leaderboard.localTotal").firstMatch
            XCTAssertTrue(total.exists)
            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: language)
            formatter.numberStyle = .decimal
            let expected = try XCTUnwrap(formatter.string(from: 0))
            XCTAssertTrue(total.label.hasSuffix(" " + expected))
            XCTAssertEqual(app.staticTexts["gameQA.storedHighestLevel"].label, "stored highest level: 0")
            captureGame(app, name: "leaderboard-count-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testLeaderboardCategoriesGrowAndRetainSelectedTraitsAtAccessibilitySize() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "leaderboard",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
            app.launch()
            let fruit = app.buttons["fruitBasket.leaderboard.category.fruit collected"]
            XCTAssertTrue(fruit.waitForExistence(timeout: 5))
            XCTAssertTrue(fruit.isSelected)
            let heading = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.leaderboard.heading").firstMatch
            XCTAssertTrue(heading.exists)
            let serviceStatus = app.descendants(matching: .any)
                .matching(identifier: "fruitBasket.leaderboard.serviceStatus").firstMatch
            XCTAssertTrue(serviceStatus.exists)
            let scroll = app.scrollViews.firstMatch
            for unit in ["stars earned", "basket reveals", "highest level"] {
                let category = app.buttons["fruitBasket.leaderboard.category." + unit]
                for _ in 0..<24 { if category.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(category.isHittable)
                XCTAssertGreaterThanOrEqual(category.frame.width, 44)
                XCTAssertGreaterThanOrEqual(category.frame.height, 44)
                category.tap()
                XCTAssertTrue(category.isSelected)
                XCTAssertFalse(fruit.isSelected)
            }
            let board = app.otherElements["fruitBasket.leaderboard.board"]
            XCTAssertTrue(board.exists)
            XCTAssertGreaterThan(board.frame.height, 220)
            for rank in 1...3 {
                let row = app.descendants(matching: .any)
                    .matching(identifier: "fruitBasket.leaderboard.rank.\(rank)").firstMatch
                XCTAssertTrue(row.exists)
                XCTAssertEqual(row.label, "\(rank) place, awaiting player")
                XCTAssertGreaterThanOrEqual(row.frame.minX, board.frame.minX + 44)
                XCTAssertLessThanOrEqual(row.frame.maxX, board.frame.maxX - 44)
                XCTAssertGreaterThanOrEqual(row.frame.minY, board.frame.minY)
                XCTAssertLessThanOrEqual(row.frame.maxY, board.frame.maxY)
            }
            captureGame(app, name: "leaderboard-categories-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testGameSuggestedTopicsWrapAndKeepOriginalResearchInput() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "setup",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
            app.launch()
            let scroll = app.scrollViews.firstMatch
            for title in ["reproductive health", "women’s wellness"] {
                let chip = app.buttons["fruitBasket.suggestedTopic." + title]
                XCTAssertTrue(chip.waitForExistence(timeout: 5))
                for _ in 0..<24 { if chip.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(chip.isHittable)
                XCTAssertEqual(chip.label, title)
                XCTAssertGreaterThanOrEqual(chip.frame.width, 44)
                XCTAssertGreaterThan(chip.frame.height, 48)
                chip.tap()
                let input = app.descendants(matching: .any).matching(identifier: "fruitBasket.topicInput").firstMatch
                XCTAssertEqual(input.value as? String, title)
            }
            captureGame(app, name: "game-topic-chips-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testGameCompactSelectorsWrapAndRetainSelectionAtAccessibilitySize() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "setup",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
            app.launch()
            let medium = app.buttons["fruitBasket.difficulty.medium"]
            XCTAssertTrue(medium.waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<24 { if medium.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(medium.isHittable)
            XCTAssertGreaterThanOrEqual(medium.frame.height, 44)
            XCTAssertGreaterThanOrEqual(medium.frame.width, 44)
            XCTAssertEqual(medium.label, "medium")
            medium.tap()
            XCTAssertTrue(medium.isSelected)
            XCTAssertFalse(app.buttons["fruitBasket.difficulty.easy"].isSelected)
            let classification = app.buttons["fruitBasket.controlMode.classification"]
            for _ in 0..<24 { if classification.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(classification.isHittable)
            XCTAssertEqual(classification.label, "classification")
            XCTAssertGreaterThan(classification.frame.height, 52, "Large label must grow instead of shrinking into the old fixed height")
            let catching = app.buttons["fruitBasket.controlMode.catch"]
            catching.tap()
            XCTAssertTrue(catching.isSelected)
            XCTAssertFalse(classification.isSelected)
            classification.tap()
            XCTAssertTrue(classification.isSelected)
            captureGame(app, name: "game-compact-selector-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testSettingsToggleEnablesBeforeItsSingleCueAndVolumePersists() {
        for reduced in [false, true] {
        for muted in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioSettingsControlsQA",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioSettingsControlsReduceMotion"] }
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            if rtl { app.launchArguments += ["-fruitfolioSettingsControlsRTL"] }
            app.launch()
            let toggle = app.descendants(matching: .any).matching(identifier: "settingsControls.effects").firstMatch
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            XCTAssertTrue(toggle.isHittable)
            XCTAssertGreaterThanOrEqual(toggle.frame.height, 44)
            XCTAssertEqual(toggle.value as? String, "off")
            toggle.tap()
            XCTAssertEqual(toggle.value as? String, "on")
            XCTAssertEqual(app.staticTexts["settingsControls.savedEffects"].label, "saved effects: true")
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 1)")
            let volume = app.sliders.firstMatch
            for _ in 0..<12 { if volume.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(volume.isHittable)
            XCTAssertGreaterThanOrEqual(volume.frame.height, 44)
            XCTAssertEqual(volume.value as? String, "25%")
            volume.adjust(toNormalizedSliderPosition: 0.75)
            let saved = app.staticTexts["settingsControls.savedVolume"]
            for _ in 0..<8 { if saved.exists { break }; app.swipeUp() }
            let amount = Double(saved.label.replacingOccurrences(of: "saved volume: ", with: ""))
            XCTAssertNotNil(amount)
            XCTAssertEqual(amount ?? -1, 0.75, accuracy: 0.05)
            let savedBeforeBackground = saved.label
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(saved.waitForExistence(timeout: 5))
            XCTAssertEqual(saved.label, savedBeforeBackground)
            XCTAssertEqual(app.staticTexts["settingsControls.savedEffects"].label, "saved effects: true")
            for _ in 0..<12 { if toggle.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(toggle.isHittable)
            XCTAssertEqual(toggle.value as? String, "on")
            captureGame(app, name: "settings-toggle-volume-muted-\(muted)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testDataManagementReopeningOwnsExactlyOneOpenAndCloseRequest() {
        for reduced in [false, true] {
        for muted in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioDataManagementQA", "-fruitfolioAudioDiagnostics",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioDataReduceMotion"] }
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            if rtl { app.launchArguments += ["-fruitfolioDataRTL"] }
            app.launch()
            for count in 1...2 {
                let scroll = app.scrollViews["tapedWhitePopup.scroll"]
                XCTAssertTrue(scroll.waitForExistence(timeout: 5))
                XCTAssertFalse(app.buttons["dataQA.background"].exists)
                XCTAssertTrue(app.staticTexts["dataManagement.heading"].exists)
                XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: \(count)")
                let close = app.buttons["dataManagement.close"]
                for _ in 0..<24 { if close.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(close.isHittable)
                XCTAssertGreaterThanOrEqual(close.frame.height, 44)
                close.tap()
                let background = app.buttons["dataQA.background"]
                XCTAssertTrue(background.waitForExistence(timeout: 3))
                XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: \(count)")
                XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: \(count)")
                XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label,
                               "soft pop starts: \(muted ? 0 : count)")
                captureGame(app, name: "data-popup-reopen-\(count)-muted-\(muted)-reduced-\(reduced)-rtl-\(rtl)")
                if count == 1 { background.tap() }
            }
            app.terminate()
        }
        }
        }
    }

    func testDataManagementUsesMeasuredPaperAndTruthfulAvailableActions() {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioDataManagementQA", "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioDataReduceMotion"] }
            app.launch()
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["dataQA.background"].exists)
            let export = app.buttons["dataManagement.measurementExport"]
            for _ in 0..<12 { if export.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(export.isHittable)
            XCTAssertGreaterThanOrEqual(export.frame.height, 44)
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "your data is ready")).firstMatch.exists)
            let review = app.buttons["dataManagement.reviewDeletion"]
            for _ in 0..<18 { if review.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(review.isHittable)
            review.tap()
            let books = app.buttons["dataManagement.books"]
            for _ in 0..<18 { if books.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(books.isHittable)
            captureGame(app, name: "data-management-options-reduced-\(reduced)")
            let close = app.buttons["dataManagement.close"]
            for _ in 0..<18 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            close.tap()
            XCTAssertTrue(app.buttons["dataQA.background"].waitForExistence(timeout: 3))
            app.terminate()
        }
    }

    private func openDraftFixturePage(_ app: XCUIApplication) {
        app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookDraftFixture", "-fruitfolioBookReduceMotion"]
        app.launch()
        let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA sage,")).firstMatch
        for _ in 0..<16 { if book.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(book.isHittable)
        book.tap()
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.textViews["savedPage.notes"].waitForExistence(timeout: 5))
    }

    func testSavedNotesKeepDiscardAndSaveThroughOwnedPaper() {
        let app = XCUIApplication()
        openDraftFixturePage(app)
        let scroll = app.scrollViews["savedPage.scroll"]
        let notes = app.textViews["savedPage.notes"]
        for _ in 0..<20 { if notes.isHittable { break }; scroll.swipeUp() }
        notes.tap(); notes.typeText(" QA kept note draft")
        let back = app.buttons["savedPage.back"]
        for _ in 0..<20 { if back.isHittable { break }; scroll.swipeDown() }
        back.tap()
        XCTAssertTrue(app.buttons["fruitPopup.paper.action.tertiary"].waitForExistence(timeout: 5))
        XCTAssertFalse(notes.exists)
        captureGame(app, name: "saved-note-three-choice-paper")
        tapSharedPaperAction("primary", in: app)
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        XCTAssertTrue((notes.value as? String)?.contains("QA kept note draft") == true)
        for _ in 0..<20 { if back.isHittable { break }; scroll.swipeDown() }
        back.tap()
        tapSharedPaperAction("tertiary", in: app)
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        XCTAssertEqual(notes.value as? String, "QA original note")
        for _ in 0..<20 { if notes.isHittable { break }; scroll.swipeUp() }
        notes.tap(); notes.typeText(" QA saved note")
        for _ in 0..<20 { if back.isHittable { break }; scroll.swipeDown() }
        back.tap()
        tapSharedPaperAction("secondary", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        XCTAssertTrue((notes.value as? String)?.contains("QA saved note") == true)
        XCTAssertTrue(app.staticTexts["QA original own page text"].exists)
        app.terminate()
    }

    func testUserPageOverlayKeepDiscardAndSaveRetainOriginalUntilExplicitSave() {
        let app = XCUIApplication()
        openDraftFixturePage(app)
        let reading = app.scrollViews["savedPage.scroll"]
        let edit = app.buttons["savedPage.editOwnPage"]
        for _ in 0..<20 { if edit.isHittable { break }; reading.swipeUp() }
        edit.tap()
        let paper = app.scrollViews["tapedWhitePopup.scroll"]
        let body = app.textViews["userPage.editor.body"]
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        for _ in 0..<20 { if body.isHittable { break }; paper.swipeUp() }
        body.tap(); body.typeText(" QA kept page draft")
        let cancel = app.buttons["userPage.editor.cancel"]
        for _ in 0..<20 { if cancel.isHittable { break }; paper.swipeUp() }
        cancel.tap()
        XCTAssertTrue(app.buttons["fruitPopup.paper.action.tertiary"].waitForExistence(timeout: 5))
        XCTAssertFalse(body.exists)
        XCTAssertEqual(app.scrollViews.matching(identifier: "tapedWhitePopup.scroll").count, 1)
        captureGame(app, name: "user-page-overlay-three-choice-paper")
        tapSharedPaperAction("primary", in: app)
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        XCTAssertTrue((body.value as? String)?.contains("QA kept page draft") == true)
        for _ in 0..<20 { if cancel.isHittable { break }; paper.swipeUp() }
        cancel.tap()
        tapSharedPaperAction("tertiary", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["QA original own page text"].exists)
        for _ in 0..<20 { if edit.isHittable { break }; reading.swipeUp() }
        edit.tap()
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        XCTAssertEqual(body.value as? String, "QA original own page text")
        for _ in 0..<20 { if body.isHittable { break }; paper.swipeUp() }
        body.tap(); body.typeText(" QA saved page change")
        for _ in 0..<20 { if cancel.isHittable { break }; paper.swipeUp() }
        cancel.tap()
        tapSharedPaperAction("secondary", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        let saved = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "QA saved page change")).firstMatch
        XCTAssertTrue(saved.exists)
        XCTAssertEqual(app.textViews["savedPage.notes"].value as? String, "QA original note")
        app.terminate()
    }

    func testContextClearUsesSharedPaperAndCancelPreservesUnsupportedOriginal() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioContextStorageQA", "-fruitfolioContextReduceMotion",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let clear = app.buttons["myContext.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        for _ in 0..<60 { if clear.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(clear.isHittable)
        clear.tap()
        XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(clear.exists)
        captureGame(app, name: "my-context-clear-shared-paper-large-text")
        tapSharedPaperAction("primary", in: app)
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["myContext.reloadSavedRecord"].exists)
        for _ in 0..<20 { if clear.isHittable { break }; app.swipeUp() }
        clear.tap()
        tapSharedPaperAction("secondary", in: app)
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["myContext.reloadSavedRecord"].exists)
        let goal = app.buttons.matching(NSPredicate(format: "label == %@", "trying to conceive")).firstMatch
        for _ in 0..<60 { if goal.isHittable { break }; app.swipeDown() }
        XCTAssertTrue(goal.isEnabled)
        XCTAssertEqual(goal.value as? String, "not selected")
        app.terminate()
    }

    func testPersonalHealthDirtyDraftRetainsAllThreeChoicesAndScopedRemoval() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioPersonalHealthQA"]
        app.launch()
        let group = app.buttons["family, genetic and biological context"]
        XCTAssertTrue(group.waitForExistence(timeout: 5))
        group.tap()
        let category = app.buttons["personalHealth.category.dna"]
        for _ in 0..<20 { if category.isHittable { break }; app.swipeUp() }
        category.tap()
        let editor = app.scrollViews["personalHealth.editor.scroll"]
        let text = app.textViews["personalHealth.editor.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap(); text.typeText("QA original draft")
        let close = app.buttons["personalHealth.editor.close"]
        for _ in 0..<20 { if close.isHittable { break }; editor.swipeUp() }
        close.tap()
        let paper = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(paper.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["fruitPopup.paper.action.primary"].exists)
        XCTAssertTrue(app.buttons["fruitPopup.paper.action.secondary"].exists)
        XCTAssertTrue(app.buttons["fruitPopup.paper.action.tertiary"].exists)
        XCTAssertFalse(text.exists)
        captureGame(app, name: "personal-health-three-choice-native-sheet")
        tapSharedPaperAction("primary", in: app)
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertEqual(text.value as? String, "QA original draft")
        for _ in 0..<20 { if close.isHittable { break }; editor.swipeUp() }
        close.tap()
        tapSharedPaperAction("secondary", in: app)
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        XCTAssertEqual(category.value as? String, "saved user-provided context · edit")
        category.tap()
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        text.tap(); text.typeText(" QA discarded addition")
        for _ in 0..<20 { if close.isHittable { break }; editor.swipeUp() }
        close.tap()
        tapSharedPaperAction("tertiary", in: app)
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        category.tap()
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertEqual(text.value as? String, "QA original draft")
        let remove = app.buttons["personalHealth.editor.remove"]
        for _ in 0..<20 { if remove.isHittable { break }; editor.swipeUp() }
        remove.tap()
        tapSharedPaperAction("primary", in: app)
        XCTAssertTrue(remove.waitForExistence(timeout: 5))
        for _ in 0..<20 { if remove.isHittable { break }; editor.swipeUp() }
        remove.tap()
        tapSharedPaperAction("secondary", in: app)
        XCTAssertTrue(category.waitForExistence(timeout: 5))
        XCTAssertEqual(category.value as? String, "removed · add again")
        app.terminate()
    }

    func testContextUnknownFieldsKeepKnownSelectionAndPauseEditsAfterReadOnlyReload() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioContextStorageQA", "-fruitfolioContextReduceMotion",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let reload = app.buttons["myContext.reloadSavedRecord"]
        XCTAssertTrue(reload.waitForExistence(timeout: 5))
        for _ in 0..<16 { if reload.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(reload.isHittable)
        XCTAssertGreaterThanOrEqual(reload.frame.height, 44)
        reload.tap()
        XCTAssertTrue(reload.exists)
        let selected = app.buttons.matching(NSPredicate(format: "label == %@", "trying to conceive")).firstMatch
        for _ in 0..<20 { if selected.exists { break }; app.swipeUp() }
        XCTAssertTrue(selected.exists)
        XCTAssertFalse(selected.isEnabled)
        XCTAssertEqual(selected.value as? String, "selected")
        captureGame(app, name: "context-protected-known-selection-large-text")
        app.terminate()
    }

    func testMeasurementDeletionUsesOneSharedPaperWithCancelAndConfirmedDelete() {
        let id = "CF310000-0000-0000-0000-000000000001"
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioMeasurementsReduceMotion"] }
            app.launch()
            let delete = app.buttons["measurements.delete." + id]
            XCTAssertTrue(delete.waitForExistence(timeout: 5))
            for _ in 0..<16 { if delete.isHittable { break }; app.swipeUp() }
            delete.tap()
            let paper = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(paper.waitForExistence(timeout: 5))
            XCTAssertFalse(delete.exists)
            let keep = app.buttons["fruitPopup.paper.action.primary"]
            for _ in 0..<12 { if keep.isHittable { break }; paper.swipeUp() }
            XCTAssertTrue(keep.isHittable)
            XCTAssertGreaterThanOrEqual(keep.frame.height, 44)
            captureGame(app, name: "measurement-delete-cancel-large-text-reduced-\(reduced)")
            keep.tap()
            XCTAssertTrue(delete.waitForExistence(timeout: 5))
            for _ in 0..<16 { if delete.isHittable { break }; app.swipeUp() }
            delete.tap()
            XCTAssertTrue(paper.waitForExistence(timeout: 5))
            let confirm = app.buttons["fruitPopup.paper.action.secondary"]
            for _ in 0..<16 { if confirm.isHittable { break }; paper.swipeUp() }
            XCTAssertTrue(confirm.isHittable)
            confirm.tap()
            XCTAssertTrue(app.buttons["measurements.add"].waitForExistence(timeout: 5))
            XCTAssertFalse(delete.exists)
            app.terminate()
        }
    }

    func testMeasurementEditorNativeSheetHostsDirtyDraftPaperWithoutSavingDiscardedText() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion"]
        app.launch()
        let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
        edit.tap()
        let editor = app.scrollViews["measurements.editor.scroll"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let notes = app.descendants(matching: .any).matching(identifier: "measurements.editor.notes").firstMatch
        for _ in 0..<16 { if notes.isHittable { break }; editor.swipeUp() }
        XCTAssertTrue(notes.isHittable)
        notes.tap()
        notes.typeText(" QA unsaved change")
        let cancel = app.buttons["measurements.editor.cancel"]
        for _ in 0..<16 { if cancel.isHittable { break }; editor.swipeUp() }
        cancel.tap()
        let paper = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(paper.waitForExistence(timeout: 5))
        XCTAssertFalse(cancel.exists)
        let keep = app.buttons["fruitPopup.paper.action.primary"]
        for _ in 0..<12 { if keep.isHittable { break }; paper.swipeUp() }
        keep.tap()
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        XCTAssertTrue((notes.value as? String)?.contains("QA unsaved change") == true)
        for _ in 0..<16 { if cancel.isHittable { break }; editor.swipeUp() }
        cancel.tap()
        XCTAssertTrue(paper.waitForExistence(timeout: 5))
        let discard = app.buttons["fruitPopup.paper.action.secondary"]
        for _ in 0..<16 { if discard.isHittable { break }; paper.swipeUp() }
        captureGame(app, name: "measurement-editor-native-sheet-discard-paper")
        discard.tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["QA original note"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "QA unsaved change")).firstMatch.exists)
        app.terminate()
    }

    func testMeasurementEditorSavesArabicDecimalCycleDayAndKeepsReportedResult() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion"]
        app.launch()
        let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
        edit.tap()
        let editor = app.scrollViews["measurements.editor.scroll"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let day = app.textFields["measurements.editor.cycleDay"]
        for _ in 0..<20 { if day.isHittable { break }; editor.swipeUp() }
        XCTAssertTrue(day.isHittable)
        day.tap(); day.typeText("١٢")
        let save = app.buttons["measurements.editor.save"]
        for _ in 0..<20 { if save.isHittable { break }; editor.swipeUp() }
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        for _ in 0..<20 { if edit.isHittable { break }; app.swipeUp() }
        edit.tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let result = app.textFields["measurements.editor.result"]
        for _ in 0..<20 { if result.isHittable { break }; editor.swipeDown() }
        XCTAssertEqual(result.value as? String, "12.50")
        for _ in 0..<20 { if day.isHittable { break }; editor.swipeUp() }
        XCTAssertEqual(day.value as? String, "12")
    }

    func testMeasurementFutureRecordNoticeKeepsExactReadableValue() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsFutureRecord", "-fruitfolioMeasurementsReduceMotion"]
        app.launch()
        let reload = app.buttons["measurements.reloadSavedRecord"]
        XCTAssertTrue(reload.waitForExistence(timeout: 5))
        for _ in 0..<12 { if reload.isHittable { break }; app.swipeUp() }
        reload.tap()
        XCTAssertTrue(reload.exists)
        XCTAssertFalse(app.buttons["measurements.add"].isEnabled)
        let value = app.staticTexts["12.50 pg/mL"]
        for _ in 0..<16 { if value.exists { break }; app.swipeUp() }
        XCTAssertTrue(value.exists)
        captureGame(app, name: "measurement-protected-original-value")
        app.terminate()
    }

    func testUnsupportedSavedLibraryKeepsReadableBooksAndMeasuredReloadAvailable() {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioLibraryStorageQA", "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioLibraryReduceMotion"] }
            app.launch()
            let reload = app.buttons["library.reloadSavedRecord"]
            XCTAssertTrue(reload.waitForExistence(timeout: 5))
            for _ in 0..<12 { if reload.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(reload.isHittable)
            XCTAssertGreaterThanOrEqual(reload.frame.height, 44)
            reload.tap()
            XCTAssertTrue(reload.exists)
            let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA readable book,")).firstMatch
            for _ in 0..<16 { if book.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(book.isHittable)
            captureGame(app, name: "library-protected-readable-large-text-reduced-\(reduced)")
            book.tap()
            XCTAssertTrue(app.otherElements["library.openBook"].waitForExistence(timeout: 5))
            captureGame(app, name: "library-protected-open-book-reduced-\(reduced)")
            app.terminate()
        }
    }

    func testLocalDataExportOpensRealSavePickerAndCancellationDoesNotClaimSaved() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioDataManagementQA", "-fruitfolioDataReduceMotion", "-fruitfolioAudioDiagnostics",
            "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let export = app.buttons["dataManagement.localExport"]
        for _ in 0..<16 { if export.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(export.isHittable)
        XCTAssertGreaterThanOrEqual(export.frame.height, 44)
        export.tap()
        let cancel = app.buttons.matching(identifier: "Cancel").firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 15))
        captureGame(app, name: "local-data-export-system-save-picker-private-fixture")
        cancel.tap()
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let cancelled = app.staticTexts["export cancelled. your saved data has not changed."]
        for _ in 0..<12 { if cancelled.exists { break }; scroll.swipeUp() }
        XCTAssertTrue(cancelled.exists)
        XCTAssertFalse(app.staticTexts["your local data export was saved."].exists)
        XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
        XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 0")
        app.terminate()
    }

    func testUnreadableAccountNoticeCanReloadWithoutBlockingLocalDataNavigation() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioDataManagementQA", "-fruitfolioDataUnreadableAccount",
            "-fruitfolioDataReduceMotion", "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let reload = app.buttons["account.reloadSavedRecord"]
        for _ in 0..<12 { if reload.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(reload.isHittable)
        XCTAssertGreaterThanOrEqual(reload.frame.height, 44)
        reload.tap()
        XCTAssertTrue(reload.exists) // Invalid bytes remain protected, not silently repaired.
        let export = app.buttons["dataManagement.measurementExport"]
        for _ in 0..<12 { if export.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(export.isHittable)
        captureGame(app, name: "account-preserved-record-data-options")
        let close = app.buttons["dataManagement.close"]
        for _ in 0..<24 { if close.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(app.buttons["dataQA.background"].waitForExistence(timeout: 3))
        app.terminate()
    }

    func testContactButtonOwnsOneSoftPopAndMutePreventsSoftwarePlayback() {
        for muted in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioContactQA", "-fruitfolioContactReduceMotion", "-fruitfolioAudioDiagnostics"]
            if muted { app.launchArguments += ["-fruitfolioAudioMuted"] }
            app.launch()
            let link = app.buttons["contact.link.instagram"]
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            link.tap()
            let close = app.buttons["contact.linkFailure.close"]
            XCTAssertTrue(close.waitForExistence(timeout: 3))
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 1")
            XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 1)")
            XCTAssertEqual(app.staticTexts["audioQA.openRequests"].label, "popup open requests: 1")
            captureGame(app, name: "contact-audio-muted-\(muted)")
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            for _ in 0..<12 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            close.tap()
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
            XCTAssertEqual(app.staticTexts["audioQA.softPopStarts"].label, "soft pop starts: \(muted ? 0 : 2)")
            XCTAssertEqual(app.staticTexts["audioQA.closeRequests"].label, "popup close requests: 1")
            app.terminate()
        }
    }

    func testScrollablePopupIsolatesBackgroundAndRestoresItOnClose() {
        verifyModal(reduceMotion: false)
    }

    func testScrollablePopupAtAccessibilitySizeWithReduceMotion() {
        verifyModal(reduceMotion: true)
    }

    func testSelectedBookRemainsBoundedAndReturnsToShelf() {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioBookQA"]
            if reduced { app.launchArguments += ["-fruitfolioBookReduceMotion"] }
            app.launch()
            let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA sage,")).firstMatch
            for _ in 0..<8 { if book.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(book.isHittable)
            book.tap()
            let rename = app.buttons["rename"]
            XCTAssertTrue(rename.waitForExistence(timeout: 5))
            let open = app.otherElements.matching(identifier: "library.openBook").firstMatch
            XCTAssertTrue(open.exists)
            XCTAssertGreaterThanOrEqual(open.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(open.frame.maxX, app.frame.maxX)
            XCTAssertLessThanOrEqual(open.frame.maxY, app.frame.maxY)
            app.buttons.matching(identifier: "Back").firstMatch.tap()
            XCTAssertTrue(book.waitForExistence(timeout: 3))
            app.terminate()
        }
    }

    func testOwnMaterialSavesIntoChosenBookWithoutBecomingVerifiedResearch() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookReduceMotion"]
        app.launch()
        let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA sage,")).firstMatch
        for _ in 0..<8 { if book.isHittable { break }; app.swipeUp() }
        book.tap()
        let add = app.buttons["add my own page"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let title = app.textFields["page title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap(); title.typeText("my reminder")
        let body = app.textViews["my page text"]
        body.tap(); body.typeText("my independently collected material")
        app.swipeUp()
        let save = app.buttons["save my page"]
        for _ in 0..<10 { if save.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.staticTexts["your own material · not verified research"].waitForExistence(timeout: 3))
    }

    func testLibraryCreatedBookIsSameGuideAndRenamePropagatesBack() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookReduceMotion"]
        app.launch()
        app.buttons["QA guide builder"].tap()
        let guide = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "QA sage")).firstMatch
        for _ in 0..<10 { if guide.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(guide.isHittable)
        guide.tap()
        let options = app.buttons["guide options"]
        XCTAssertTrue(options.waitForExistence(timeout: 3))
        options.tap()
        app.buttons["rename"].tap()
        let field = app.textFields["guide name"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText(" updated")
        let save = app.buttons["save name"]
        for _ in 0..<8 { if save.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(save.isHittable)
        save.tap()
        app.buttons["QA library"].tap()
        let renamed = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA sage updated,")).firstMatch
        for _ in 0..<10 { if renamed.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(renamed.isHittable)
    }

    func testHormoneLibraryOriginalSourcesRemainReachableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioHormoneLibraryQA", "-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let scroll = app.scrollViews["hormoneLibrary.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let source = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "open source:")).firstMatch
        for _ in 0..<35 { if source.exists && source.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(source.isHittable)
        XCTAssertGreaterThanOrEqual(source.frame.height, 44)
        XCTAssertGreaterThanOrEqual(source.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(source.frame.maxX, app.frame.maxX)
    }

    func testOptionalPersonalContextCanBeAddedEditedAndRemoved() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioPersonalHealthQA"]
        app.launch()
        let group = app.buttons["family, genetic and biological context"]
        XCTAssertTrue(group.waitForExistence(timeout: 5))
        group.tap()
        let dna = app.buttons["known DNA / genetic findings"]
        for _ in 0..<10 { if dna.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(dna.isHittable)
        dna.tap()
        let text = app.textViews["optional personal health context"]
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        text.tap(); text.typeText("only my explicitly supplied finding")
        let save = app.buttons["save my context"]
        for _ in 0..<10 { if save.isHittable { break }; app.swipeUp() }
        save.tap()
        XCTAssertTrue(dna.waitForExistence(timeout: 3))
        dna.tap()
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        XCTAssertTrue((text.value as? String)?.contains("explicitly supplied") == true)
        let remove = app.buttons["remove this context"]
        for _ in 0..<10 { if remove.isHittable { break }; app.swipeUp() }
        remove.tap()
        app.buttons["remove context"].tap()
        XCTAssertTrue(dna.waitForExistence(timeout: 3))
        XCTAssertEqual(dna.value as? String, "removed · add again")
    }

    func testAskContextRequiresAttachAndCancelDoesNotShare() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioAskPaperQA"]
        app.launch()
        let attach = app.buttons["attach my context"]
        XCTAssertTrue(attach.waitForExistence(timeout: 5))
        attach.tap()
        let measurement = app.switches.matching(NSPredicate(format: "label CONTAINS %@", "Progesterone")).firstMatch
        XCTAssertTrue(measurement.waitForExistence(timeout: 3))
        measurement.tap()
        let cancel = app.buttons["cancel"]
        for _ in 0..<10 { if cancel.isHittable { break }; app.swipeUp() }
        cancel.tap()
        XCTAssertFalse(app.staticTexts["1 selected for one question"].exists)
        attach.tap()
        XCTAssertTrue(measurement.waitForExistence(timeout: 3))
        measurement.tap()
        let done = app.buttons["attach selected context"]
        for _ in 0..<10 { if done.isHittable { break }; app.swipeUp() }
        done.tap()
        XCTAssertTrue(app.staticTexts["1 selected for one question"].waitForExistence(timeout: 3))
        app.buttons["remove attachments"].tap()
        XCTAssertFalse(app.staticTexts["1 selected for one question"].exists)
    }

    func testWheelNoteActionsStayReachableAtAccessibilitySize() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioWheelQA", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let region = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "menstruation, cycle days")).firstMatch
        for _ in 0..<15 { if region.exists && region.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(region.isHittable)
        region.tap()
        let learn = app.buttons["learn why →"]
        for _ in 0..<25 { if learn.exists && learn.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(learn.isHittable)
        XCTAssertGreaterThanOrEqual(learn.frame.height, 44)
        learn.tap()
        let result = app.staticTexts["wheelQA.biology"]
        for _ in 0..<12 { if result.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(result.exists)
    }

    func testTourActionsRemainReachableAtAccessibilitySize() {
        verifyTour(rightToLeft: false)
    }

    func testRTLTourActionsRemainReachableAtAccessibilitySize() {
        verifyTour(rightToLeft: true)
    }

    private func verifyTour(rightToLeft: Bool) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioTourQA", "-fruitfolioModalReduceMotion",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if rightToLeft { app.launchArguments += ["-fruitfolioDialogueRTL"] }
        app.launch()
        let scroll = app.scrollViews["tour.dialogue.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        for _ in 0..<5 {
            let next = app.buttons["tour.next"]
            for _ in 0..<30 {
                if next.exists && next.isHittable { break }
                scroll.swipeUp()
            }
            XCTAssertTrue(next.isHittable)
            XCTAssertGreaterThanOrEqual(next.frame.height, 44)
            next.tap()
        }
        let finish = app.buttons["tour.finish"]
        for _ in 0..<30 {
            if finish.exists && finish.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(finish.isHittable)
        XCTAssertGreaterThanOrEqual(finish.frame.height, 44)
        captureGame(app, name: "tour-ready-rtl-\(rightToLeft)")
        finish.tap()
        XCTAssertTrue(app.staticTexts["tourQA.finished"].waitForExistence(timeout: 3))
    }

    func testLongAskSessionKeepsBothQuestionsReachableWithinTheViewport() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioAskPaperQA"]
        app.launch()
        let scroll = app.scrollViews["ask.conversation"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        let second = app.staticTexts["Second regression question"]
        for _ in 0..<35 {
            if second.exists && second.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(second.isHittable)
        XCTAssertGreaterThanOrEqual(second.frame.minX, scroll.frame.minX)
        XCTAssertLessThanOrEqual(second.frame.maxX, scroll.frame.maxX)
        let first = app.staticTexts["First regression question"]
        for _ in 0..<35 {
            if first.exists && first.isHittable { break }
            scroll.swipeDown()
        }
        XCTAssertTrue(first.isHittable)
        for text in app.textViews.allElementsBoundByIndex where text.isHittable && scroll.frame.intersects(text.frame) {
            XCTAssertLessThanOrEqual(text.frame.width, scroll.frame.width)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "continuous-ask-paper-earlier-turn"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAskHelpIsAScrollableModalAndRestoresConversationOnClose() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioAskPaperQA", "-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let help = app.buttons["Ask help"]
        XCTAssertTrue(help.waitForExistence(timeout: 10))
        help.tap()
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 3))
        XCTAssertFalse(app.scrollViews["ask.conversation"].exists)
        let close = app.buttons["ask.help.close"]
        for _ in 0..<30 {
            if close.exists && close.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(app.scrollViews["ask.conversation"].waitForExistence(timeout: 3))
    }

    func testRTLCharacterDialogueKeepsActionsWithinWritingArea() {
        verifyModal(reduceMotion: true, rightToLeft: true)
    }

    func testEveryCharacterUsesTheRootHostInBothDirectionsAndLogicalSides() {
        for character in ["strawberry", "blueberry", "peach"] {
            for rightToLeft in [false, true] {
                for trailing in [false, true] {
                    verifyModal(reduceMotion: true, rightToLeft: rightToLeft,
                                character: character, trailing: trailing)
                }
            }
        }
    }

    private func verifyModal(reduceMotion: Bool, rightToLeft: Bool = false,
                             character: String = "blueberry", trailing: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioModalQA", "-fruitfolioDialogueCharacter", character]
        if trailing { app.launchArguments += ["-fruitfolioDialogueTrailing"] }
        if reduceMotion {
            app.launchArguments += ["-fruitfolioModalReduceMotion",
                                    "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        if rightToLeft { app.launchArguments += ["-fruitfolioDialogueRTL"] }
        app.launch()
        let scroll = app.scrollViews["fruitPopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertEqual(app.scrollViews.matching(identifier: "fruitPopup.scroll").count, 1)
        XCTAssertFalse(app.buttons["modalQA.background"].exists,
                       "Modal background must be absent from the accessibility tree.")
        let close = app.buttons["fruitPopup.action.primary"]
        for _ in 0..<30 {
            if close.exists && close.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(close.exists && close.isHittable,
                      "Long content must scroll to a reachable close action.")
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        XCTAssertGreaterThanOrEqual(close.frame.minX, scroll.frame.minX)
        XCTAssertLessThanOrEqual(close.frame.maxX, scroll.frame.maxX)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = (reduceMotion ? "modal-accessibility-reduce-motion" : "modal-scroll-actions")
            + (rightToLeft ? "-rtl" : "-ltr") + "-" + character + (trailing ? "-trailing" : "-leading")
        attachment.lifetime = .keepAlways
        add(attachment)
        close.tap()
        XCTAssertTrue(app.buttons["modalQA.background"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["modalQA.background"].isHittable)
        XCTAssertFalse(scroll.exists)
        app.terminate()
    }
    private func qaArgument(_ flag: String, in app: XCUIApplication) -> String {
        let args = app.launchArguments
        guard let index = args.firstIndex(of: flag), args.indices.contains(index + 1) else { return "default" }
        return args[index + 1]
    }

    private func launchCycleModal(_ scenario: String, reduced: Bool, rtl: Bool, landscape: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = landscape ? .landscapeLeft : .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioCycleModalQA", "-fruitfolioCycleModalQAScenario", scenario,
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioCycleModalReduceMotion"] }
        if rtl { app.launchArguments += ["-fruitfolioCycleModalRTL"] }
        app.launch()
        return app
    }

    private func closeDirtyDailyLog(_ app: XCUIApplication) {
        let close = app.buttons["dailyLog.close"]
        let journal = app.scrollViews["dailyLog.scroll"]
        for _ in 0..<20 { if close.isHittable { break }; journal.swipeDown() }
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["dailyLog.close"].exists)
        XCTAssertFalse(app.textViews["dailyLog.notes"].exists)
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.keyboards.firstMatch)
        waitForExpectations(timeout: 3)
    }

    private func tapCyclePaperAction(_ label: String, app: XCUIApplication) {
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 5))
        let slots = ["keep editing": "primary", "keep entry": "primary",
                     "save and close": "secondary", "remove entry": "secondary", "save and leave": "secondary",
                     "discard changes": "tertiary", "discard unsaved answers": "tertiary"]
        guard let slot = slots[label] else { XCTFail("Unknown cycle modal action: \(label)"); return }
        let action = app.buttons["fruitPopup.paper.action." + slot]
        for _ in 0..<20 { if action.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(action.isHittable)
        XCTAssertEqual(action.label, label)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        XCTAssertGreaterThanOrEqual(action.frame.minX, scroll.frame.minX - 1)
        XCTAssertLessThanOrEqual(action.frame.maxX, scroll.frame.maxX + 1)
        XCTAssertGreaterThanOrEqual(action.frame.minY, scroll.frame.minY - 1)
        XCTAssertLessThanOrEqual(action.frame.maxY, scroll.frame.maxY + 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "cycle-" + qaArgument("-fruitfolioCycleModalQAScenario", in: app)
            + "-override-" + String(app.launchArguments.contains("-fruitfolioCycleModalReduceMotion"))
            + "-rtl-" + String(app.launchArguments.contains("-fruitfolioCycleModalRTL")) + "-" + label
        screenshot.lifetime = .keepAlways
        add(screenshot)
        action.tap()
    }

    func testDailyLogOwnedExitChoicesUsePresentedPaperAtAccessibilitySize() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                for choice in ["keep editing", "discard changes", "save and close"] {
                    let app = launchCycleModal("daily-notes", reduced: reduced, rtl: rtl)
                    let editor = app.textViews["dailyLog.notes"]
                    XCTAssertTrue(editor.waitForExistence(timeout: 5))
                    let journal = app.scrollViews["dailyLog.scroll"]
                    for _ in 0..<20 { if editor.isHittable { break }; journal.swipeUp() }
                    XCTAssertTrue(editor.isHittable)
                    editor.tap(); editor.typeText(" unsaved fixture edit")
                    closeDirtyDailyLog(app)
                    tapCyclePaperAction(choice, app: app)
                    if choice == "keep editing" {
                        XCTAssertTrue(editor.waitForExistence(timeout: 5))
                        XCTAssertTrue((editor.value as? String ?? "").contains("unsaved fixture edit"))
                        closeDirtyDailyLog(app)
                        tapCyclePaperAction("discard changes", app: app)
                    }
                    let status = app.staticTexts["cycleModalQA.status"]
                    XCTAssertTrue(status.waitForExistence(timeout: 5))
                    let note = app.staticTexts["cycleModalQA.savedNote"]
                    if choice == "save and close" {
                        let predicate = NSPredicate(format: "label CONTAINS %@", "unsaved fixture edit")
                        expectation(for: predicate, evaluatedWith: note)
                        waitForExpectations(timeout: 5)
                    } else {
                        let predicate = NSPredicate(format: "label == %@", "original fixture note")
                        expectation(for: predicate, evaluatedWith: note)
                        waitForExpectations(timeout: 5)
                    }
                    XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "cycleModalQA.error").firstMatch.exists)
                    app.terminate()
                }
            }
        }
    }

    func testMedicationRemovalUsesOwnedPaperAndPersistsOnlyAfterSavingDay() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                let app = launchCycleModal("daily-medication", reduced: reduced, rtl: rtl)
                let remove = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "dailyLog.removeMedication.")).firstMatch
                XCTAssertTrue(remove.waitForExistence(timeout: 5))
                let journal = app.scrollViews["dailyLog.scroll"]
                for _ in 0..<20 { if remove.isHittable { break }; journal.swipeUp() }
                XCTAssertTrue(remove.isHittable); remove.tap()
                tapCyclePaperAction("keep entry", app: app)
                XCTAssertTrue(remove.waitForExistence(timeout: 5)); remove.tap()
                tapCyclePaperAction("remove entry", app: app)
                closeDirtyDailyLog(app)
                tapCyclePaperAction("save and close", app: app)
                let count = app.staticTexts["cycleModalQA.savedMedicationCount"]
                expectation(for: NSPredicate(format: "label == %@", "0"), evaluatedWith: count)
                waitForExpectations(timeout: 5)
                XCTAssertEqual(app.staticTexts["cycleModalQA.savedNote"].label, "original fixture note")
                app.terminate()
            }
        }
    }

    func testOnboardingFailedAutosaveOffersKeepDiscardOrSaveWithoutLosingSavedAnswers() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                for choice in ["keep editing", "discard unsaved answers", "save and leave"] {
                    let scenario = choice == "save and leave" ? "onboarding-retry" : "onboarding-failure"
                    let app = launchCycleModal(scenario, reduced: reduced, rtl: rtl)
                    let failure = app.descendants(matching: .any).matching(identifier: "cycleOnboarding.saveFailure").firstMatch
                    XCTAssertTrue(failure.waitForExistence(timeout: 5))
                    let back = app.buttons["cycleOnboarding.back"]
                    XCTAssertTrue(back.isHittable); back.tap()
                    XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
                    XCTAssertFalse(back.exists)
                    tapCyclePaperAction(choice, app: app)
                    if choice == "keep editing" {
                        XCTAssertTrue(back.waitForExistence(timeout: 5))
                        XCTAssertTrue(failure.exists)
                        back.tap()
                        tapCyclePaperAction("discard unsaved answers", app: app)
                    }
                    let count = app.staticTexts["cycleModalQA.savedContextCount"]
                    let expected = choice == "save and leave" ? "1" : "0"
                    expectation(for: NSPredicate(format: "label == %@", expected), evaluatedWith: count)
                    waitForExpectations(timeout: 5)
                    app.terminate()
                }
            }
        }
    }

    func testWoodenPredictionUsesSharedMeasuredHostInBothOrientationsAndDirections() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                for landscape in [false, true] {
                    let app = launchCycleModal("prediction-sign", reduced: reduced, rtl: rtl, landscape: landscape)
                    let trigger = app.buttons["cycleModalQA.predictionInfo"]
                    XCTAssertTrue(trigger.waitForExistence(timeout: 5)); trigger.tap()
                    let scroll = app.scrollViews["woodenSignPopup.scroll"]
                    XCTAssertTrue(scroll.waitForExistence(timeout: 5))
                    XCTAssertFalse(trigger.exists)
                    let close = app.buttons["fruitPopup.paper.action.primary"]
                    for _ in 0..<30 { if close.isHittable { break }; scroll.swipeUp() }
                    XCTAssertTrue(close.isHittable)
                    XCTAssertEqual(close.label, "got it ♡")
                    XCTAssertGreaterThanOrEqual(close.frame.height, 44)
                    XCTAssertGreaterThanOrEqual(close.frame.minX, scroll.frame.minX - 1)
                    XCTAssertLessThanOrEqual(close.frame.maxX, scroll.frame.maxX + 1)
                    XCTAssertGreaterThanOrEqual(close.frame.minY, scroll.frame.minY - 1)
                    XCTAssertLessThanOrEqual(close.frame.maxY, scroll.frame.maxY + 1)
                    let image = XCTAttachment(screenshot: app.screenshot())
                    image.name = "wooden-prediction-reduced-\(reduced)-rtl-\(rtl)-landscape-\(landscape)"
                    image.lifetime = .keepAlways
                    add(image)
                    close.tap()
                    XCTAssertTrue(trigger.waitForExistence(timeout: 5)); XCTAssertTrue(trigger.isHittable)
                    XCTAssertEqual(app.staticTexts["cycleModalQA.predictionStatus"].label, "prediction explanation closed")
                    app.terminate()
                }
            }
        }
        XCUIDevice.shared.orientation = .portrait
    }

    private func launchAccountAction(_ scenario: String, reduced: Bool, rtl: Bool) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioAccountActionQA", "-fruitfolioAccountActionQAScenario", scenario,
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioAccountActionReduceMotion"] }
        if rtl { app.launchArguments += ["-fruitfolioAccountActionRTL"] }
        app.launch()
        let target = app.buttons["account.signOut"]
        XCTAssertTrue(target.waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["accountQA.username"].label, "empty private username")
        return app
    }

    private func openAccountAction(_ identifier: String, app: XCUIApplication) {
        let target = app.buttons[identifier], scroll = app.scrollViews["account.scroll"]
        for _ in 0..<25 { if target.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(target.isHittable); target.tap()
        XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["account.signOut"].exists)
        XCTAssertFalse(app.buttons["account.deleteAccount"].exists)
    }

    private func tapAccountPaperAction(_ slot: String, label: String, app: XCUIApplication) {
        let context = "account-" + qaArgument("-fruitfolioAccountActionQAScenario", in: app)
            + "-override-" + String(app.launchArguments.contains("-fruitfolioAccountActionReduceMotion"))
            + "-rtl-" + String(app.launchArguments.contains("-fruitfolioAccountActionRTL"))
        tapMeasuredPaperAction(slot, label: label, app: app, context: context)
    }

    private func tapMeasuredPaperAction(_ slot: String, label: String, app: XCUIApplication, context: String) {
        let scroll = app.scrollViews["tapedWhitePopup.scroll"]
        let action = app.buttons["fruitPopup.paper.action." + slot]
        for _ in 0..<25 { if action.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(action.isHittable); XCTAssertEqual(action.label, label)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        XCTAssertGreaterThanOrEqual(action.frame.minX, scroll.frame.minX - 1)
        XCTAssertLessThanOrEqual(action.frame.maxX, scroll.frame.maxX + 1)
        XCTAssertGreaterThanOrEqual(action.frame.minY, scroll.frame.minY - 1)
        XCTAssertLessThanOrEqual(action.frame.maxY, scroll.frame.maxY + 1)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = context + "-" + slot + "-" + label
        screenshot.lifetime = .keepAlways
        add(screenshot)
        action.tap()
    }

    private func waitForLabelValue(_ identifier: String, value: String, app: XCUIApplication) {
        let element = app.staticTexts[identifier]
        expectation(for: NSPredicate(format: "label == %@", value), evaluatedWith: element)
        waitForExpectations(timeout: 5)
    }

    private func assertReadableAccountFailure(_ fragment: String, app: XCUIApplication) {
        let message = app.descendants(matching: .any).matching(identifier: "account.actionMessage").firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: 5))
        let scroll = app.scrollViews["account.scroll"]
        for _ in 0..<25 { if message.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(message.isHittable)
        XCTAssertTrue(message.label.contains(fragment), message.label)
    }

    private func launchGameUsernameExit(reduced: Bool, rtl: Bool, future: Bool = false) -> XCUIApplication {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario",
            future ? "leaderboard-username-future" : "leaderboard",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
        if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
        app.launch()
        XCTAssertTrue(app.textFields["fruitBasket.publicUsername"].waitForExistence(timeout: 5))
        return app
    }

    private func openGameUsernameExit(_ app: XCUIApplication) {
        let back = app.buttons["fruitBasket.back"]
        revealLeaderboardInput(back, app: app)
        back.tap()
        XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["fruitBasket.publicUsername"].exists)
        expectation(for: NSPredicate { _, _ in app.keyboards.count == 0 }, evaluatedWith: app)
        waitForExpectations(timeout: 5)
    }

    func testGameUsernameExitKeepsSavesOrDiscardsOnlyItsDraft() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for choice in ["keep", "save", "discard"] {
            let app = launchGameUsernameExit(reduced: reduced, rtl: rtl)
            let field = app.textFields["fruitBasket.publicUsername"]
            revealLeaderboardInput(field, app: app)
            field.tap(); field.typeText("sprout_one")
            if choice == "save" {
                let confirm = app.descendants(matching: .any).matching(identifier: "fruitBasket.usernameConfirmation").firstMatch
                revealLeaderboardInput(confirm, app: app); confirm.tap()
            }
            openGameUsernameExit(app)
            let context = "game-username-exit-" + choice + "-reduced-\(reduced)-rtl-\(rtl)"
            let slot = choice == "keep" ? "primary" : (choice == "save" ? "secondary" : "tertiary")
            let label = choice == "keep" ? "keep editing" : (choice == "save" ? "save + leave" : "discard edit + leave")
            tapMeasuredPaperAction(slot, label: label, app: app, context: context)
            waitForLabelValue("gameQA.backRequests", value: "back requests: \(choice == "keep" ? 0 : 1)", app: app)
            revealLeaderboardInput(field, app: app)
            if choice == "discard" { XCTAssertNotEqual(field.value as? String, "sprout_one") }
            else { XCTAssertEqual(field.value as? String, "sprout_one") }
            let saved = app.staticTexts["fruitBasket.qa.savedUsername"].label
            XCTAssertEqual(saved.contains("sprout_one"), choice == "save")
            captureGame(app, name: context + "-after-dismissal")
            app.terminate()
        }
        }
        }
    }

    func testGameUsernameExitCannotSaveUnconfirmedOrProtectedNames() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for future in [false, true] {
            let app = launchGameUsernameExit(reduced: reduced, rtl: rtl, future: future)
            let field = app.textFields["fruitBasket.publicUsername"]
            revealLeaderboardInput(field, app: app)
            field.tap(); field.typeText(future ? "_draft" : "sprout_one")
            let draft = field.value as? String ?? ""
            XCTAssertFalse(draft.isEmpty)
            openGameUsernameExit(app)
            let context = "game-username-exit-failure-future-\(future)-reduced-\(reduced)-rtl-\(rtl)"
            tapMeasuredPaperAction("secondary", label: future ? "review saved username" : "save + leave",
                app: app, context: context)
            waitForLabelValue("gameQA.backRequests", value: "back requests: 0", app: app)
            let message = app.descendants(matching: .any).matching(identifier: "fruitBasket.usernameMessage").firstMatch
            XCTAssertTrue(message.waitForExistence(timeout: 5))
            revealLeaderboardInput(field, app: app)
            XCTAssertEqual(field.value as? String, draft)
            if future { XCTAssertFalse(app.buttons["fruitBasket.saveUsername"].isEnabled) }
            app.terminate()
        }
        }
        }
    }

    private func revealLeaderboardInput(_ element: XCUIElement, app: XCUIApplication) {
        let scroll = app.scrollViews["fruitBasket.leaderboard.scroll"]
        for _ in 0..<28 {
            if element.isHittable { break }
            if element.exists, element.frame.midY < scroll.frame.midY { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
    }

    func testFruitBasketUsernameDraftSurvivesReappearanceAndSavesToActualAuthority() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "leaderboard",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
            app.launch()
            let field = app.textFields["fruitBasket.publicUsername"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            revealLeaderboardInput(field, app: app)
            field.tap(); field.typeText("sprout_one")
            let home = app.buttons["fruitBasket.home"]
            revealLeaderboardInput(home, app: app)
            home.tap()
            let open = app.buttons["fruitBasket.openLeaderboard"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            for _ in 0..<12 { if open.isHittable { break }; app.swipeUp() }
            open.tap()
            revealLeaderboardInput(field, app: app)
            XCTAssertEqual(field.value as? String, "sprout_one")
            XCUIDevice.shared.press(.home)
            app.activate()
            revealLeaderboardInput(field, app: app)
            XCTAssertEqual(field.value as? String, "sprout_one")
            let confirm = app.descendants(matching: .any).matching(identifier: "fruitBasket.usernameConfirmation").firstMatch
            revealLeaderboardInput(confirm, app: app)
            confirm.tap()
            let save = app.buttons["fruitBasket.saveUsername"]
            revealLeaderboardInput(save, app: app)
            XCTAssertTrue(save.isEnabled)
            XCTAssertGreaterThanOrEqual(save.frame.height, 44)
            save.tap()
            XCTAssertEqual(app.staticTexts["fruitBasket.qa.savedUsername"].label, "saved username: sprout_one")
            captureGame(app, name: "game-username-draft-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testFruitBasketFutureUsernameRecordKeepsDraftAndBlocksSaveAfterReload() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "leaderboard-username-future",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioGameRTL"] }
            app.launch()
            let field = app.textFields["fruitBasket.publicUsername"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            revealLeaderboardInput(field, app: app)
            XCTAssertEqual(field.value as? String, "future_berry")
            field.tap(); field.typeText("_draft")
            let draft = field.value as? String ?? ""
            XCTAssertTrue(draft.contains("_draft"))
            let reload = app.buttons["fruitBasket.reloadUsername"]
            revealLeaderboardInput(reload, app: app)
            reload.tap()
            let save = app.buttons["fruitBasket.saveUsername"]
            revealLeaderboardInput(save, app: app)
            XCTAssertFalse(save.isEnabled)
            revealLeaderboardInput(field, app: app)
            XCTAssertEqual(field.value as? String, draft)
            captureGame(app, name: "game-username-future-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    private func revealAccountInput(_ element: XCUIElement, app: XCUIApplication) {
        let scroll = app.scrollViews["account.scroll"]
        for _ in 0..<24 {
            if element.isHittable { break }
            if element.exists, element.frame.midY < scroll.frame.midY { scroll.swipeDown() }
            else { scroll.swipeUp() }
        }
        XCTAssertTrue(element.isHittable)
    }

    func testAccountDraftExitKeepsOrDiscardsEmailAndOnlySavesUsername() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for mode in ["username", "email", "both"] {
        for choice in (mode == "email" ? ["keep", "discard"] : ["keep", "save", "discard"]) {
            let app = launchAccountAction("sign-out", reduced: reduced, rtl: rtl)
            if mode != "username" {
                openAccountAction("account.signOut", app: app)
                tapAccountPaperAction("secondary", label: "keep on this device + sign out", app: app)
                waitForLabelValue("accountQA.identity", value: "none", app: app)
            }
            let username = app.textFields["account.publicUsername"]
            if mode != "email" {
                revealAccountInput(username, app: app)
                username.tap(); username.typeText("sprout_one")
                if choice == "save" {
                    let confirm = app.descendants(matching: .any).matching(identifier: "account.usernameConfirmation").firstMatch
                    revealAccountInput(confirm, app: app); confirm.tap()
                }
            }
            let email = app.textFields["account.email"]
            if mode != "username" {
                revealAccountInput(email, app: app)
                email.tap(); email.typeText("fixture+note@example.invalid")
            }
            let back = app.buttons["settings.routeHeader.back"]
            revealAccountInput(back, app: app); back.tap()
            XCTAssertTrue(app.scrollViews["tapedWhitePopup.scroll"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.textFields["account.publicUsername"].exists)
            let context = "account-draft-exit-\(mode)-\(choice)-reduced-\(reduced)-rtl-\(rtl)"
            let slot = choice == "keep" ? "primary" : (choice == "save" || mode == "email" ? "secondary" : "tertiary")
            let label = choice == "keep" ? "keep editing" : (choice == "save" ? "save username + leave" : "discard drafts + leave")
            tapMeasuredPaperAction(slot, label: label, app: app, context: context)
            waitForLabelValue("accountQA.backRequests", value: "back requests: \(choice == "keep" ? 0 : 1)", app: app)
            if mode != "email" {
                revealAccountInput(username, app: app)
                if choice == "discard" { XCTAssertNotEqual(username.value as? String, "sprout_one") }
                else { XCTAssertEqual(username.value as? String, "sprout_one") }
            }
            if mode != "username" {
                revealAccountInput(email, app: app)
                if choice == "keep" { XCTAssertEqual(email.value as? String, "fixture+note@example.invalid") }
                else { XCTAssertNotEqual(email.value as? String, "fixture+note@example.invalid") }
                waitForLabelValue("accountQA.identity", value: "none", app: app)
            }
            let saved = app.staticTexts["account.qa.savedUsername"].label
            XCTAssertEqual(saved.contains("sprout_one"), choice == "save")
            waitForLabelValue("accountQA.healthUnchanged", value: "yes", app: app)
            captureGame(app, name: context + "-after-dismissal")
            app.terminate()
        }
        }
        }
        }
    }

    func testAccountInputLabelsPreserveTypedUsernameAndEmail() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = launchAccountAction("sign-out", reduced: reduced, rtl: rtl)
            let username = app.textFields["account.publicUsername"]
            revealAccountInput(username, app: app)
            XCTAssertEqual(username.label, "public username")
            username.tap()
            username.typeText("sprout_one")
            XCTAssertEqual(username.value as? String, "sprout_one")
            let confirmation = app.descendants(matching: .any).matching(identifier: "account.usernameConfirmation").firstMatch
            revealAccountInput(confirmation, app: app)
            confirmation.tap()
            XCTAssertEqual(confirmation.value as? String, "on")
            let save = app.buttons["account.saveUsername"]
            revealAccountInput(save, app: app)
            XCTAssertGreaterThanOrEqual(save.frame.height, 44)
            save.tap()
            XCTAssertEqual(app.staticTexts["account.qa.savedUsername"].label, "saved username: sprout_one")
            openAccountAction("account.signOut", app: app)
            tapAccountPaperAction("secondary", label: "keep on this device + sign out", app: app)
            waitForLabelValue("accountQA.identity", value: "none", app: app)
            let email = app.textFields["account.email"]
            revealAccountInput(email, app: app)
            XCTAssertEqual(email.label, "email")
            XCTAssertGreaterThanOrEqual(email.frame.height, 44)
            email.tap()
            email.typeText("fixture+note@example.invalid")
            XCTAssertEqual(email.value as? String, "fixture+note@example.invalid")
            captureGame(app, name: "account-literal-input-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testAccountHeaderAndIdentityRemainReadableAtAccessibilitySize() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioAccountActionQA", "-fruitfolioAccountActionQAScenario", "sign-out",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioAccountActionReduceMotion"] }
            if rtl { app.launchArguments += ["-fruitfolioAccountActionRTL"] }
            app.launch()
            let heading = app.staticTexts["settings.routeHeader.title"]
            XCTAssertTrue(heading.waitForExistence(timeout: 5))
            XCTAssertEqual(heading.label, "your account")
            XCTAssertGreaterThan(heading.frame.height, 0)
            XCTAssertGreaterThanOrEqual(heading.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(heading.frame.maxX, app.frame.maxX)
            let scroll = app.scrollViews["account.scroll"]
            let identity = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "fixture-a@example.invalid")).firstMatch
            for _ in 0..<20 { if identity.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(identity.isHittable)
            captureGame(app, name: "account-header-identity-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testAccountCancelAndSignOutKeepPendingLocalHealthInformation() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                let app = launchAccountAction("sign-out", reduced: reduced, rtl: rtl)
                openAccountAction("account.signOut", app: app)
                tapAccountPaperAction("primary", label: "cancel", app: app)
                XCTAssertTrue(app.buttons["account.signOut"].waitForExistence(timeout: 5))
                waitForLabelValue("accountQA.recordUnchanged", value: "yes", app: app)
                waitForLabelValue("accountQA.identity", value: "fixture-a@example.invalid", app: app)
                openAccountAction("account.signOut", app: app)
                tapAccountPaperAction("secondary", label: "keep on this device + sign out", app: app)
                waitForLabelValue("accountQA.identity", value: "none", app: app)
                waitForLabelValue("accountQA.pending", value: "yes", app: app)
                waitForLabelValue("accountQA.healthUnchanged", value: "yes", app: app)
                XCTAssertFalse(app.buttons["account.deleteAccount"].exists)
                app.terminate()
            }
        }
    }

    func testUnavailableAccountDeletionAndSyncReportFailureWithoutErasingLocalData() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                for operation in ["delete", "sync"] {
                    let app = launchAccountAction("unavailable-" + operation, reduced: reduced, rtl: rtl)
                    if operation == "delete" {
                        openAccountAction("account.deleteAccount", app: app)
                        tapAccountPaperAction("secondary", label: "request account deletion", app: app)
                        assertReadableAccountFailure("could not be completed", app: app)
                        waitForLabelValue("accountQA.recordUnchanged", value: "yes", app: app)
                    } else {
                        openAccountAction("account.signOut", app: app)
                        tapAccountPaperAction("tertiary", label: "try cloud sync", app: app)
                        assertReadableAccountFailure("not available yet", app: app)
                    }
                    waitForLabelValue("accountQA.identity", value: "fixture-a@example.invalid", app: app)
                    waitForLabelValue("accountQA.pending", value: "yes", app: app)
                    waitForLabelValue("accountQA.healthUnchanged", value: "yes", app: app)
                    app.terminate()
                }
            }
        }
    }

    func testStaleOrUnacknowledgedAccountSignOutKeepsCurrentIdentityAndShowsError() {
        for reduced in [false, true] {
            for rtl in [false, true] {
                for scenario in ["stale-sign-out", "rejected-write"] {
                    let app = launchAccountAction(scenario, reduced: reduced, rtl: rtl)
                    openAccountAction("account.signOut", app: app)
                    tapAccountPaperAction("secondary", label: "keep on this device + sign out", app: app)
                    assertReadableAccountFailure(scenario == "stale-sign-out" ? "changed" : "preserved", app: app)
                    waitForLabelValue("accountQA.identity", value: scenario == "stale-sign-out" ? "fixture-b@example.invalid" : "fixture-a@example.invalid", app: app)
                    waitForLabelValue("accountQA.recordUnchanged", value: "yes", app: app)
                    waitForLabelValue("accountQA.pending", value: "yes", app: app)
                    waitForLabelValue("accountQA.healthUnchanged", value: "yes", app: app)
                    app.terminate()
                }
            }
        }
    }

}
