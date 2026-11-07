import XCTest

final class Prompt1BModalAccessibilityTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testGameSaveDestinationRetainsDraftAcrossBackgroundAndSavesOriginalMetadataOnce() {
        for language in ["en", "fr"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "success",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let open = app.buttons["fruitBasket.result.saveQuestion"]
            XCTAssertTrue(open.waitForExistence(timeout: 8))
            for _ in 0..<24 { if open.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let newBook = app.buttons["library.saveDestination.newBook"]
            XCTAssertTrue(newBook.waitForExistence(timeout: 5)); newBook.tap()
            let field = app.textFields["library.saveDestination.bookName"]
            XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap(); field.typeText("QA private library 42 with a longer book title")
            XCUIDevice.shared.press(.home); app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            XCTAssertEqual(field.value as? String, "QA private library 42 with a longer book title")
            let create = app.buttons["library.saveDestination.createBook"]
            for _ in 0..<16 { if create.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(create.isHittable); create.tap()
            let cancel = app.buttons["library.saveDestination.cancel"]
            for _ in 0..<16 { if cancel.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(cancel.isHittable); cancel.tap()
            let readback = app.staticTexts["gameQA.savedQuestion"]
            XCTAssertTrue(readback.waitForExistence(timeout: 5))
            XCTAssertEqual(readback.label, "saved pages: 0; books: 1; metadata intact: true")
            for _ in 0..<24 { if open.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let save = app.buttons["library.saveDestination.save"]
            XCTAssertTrue(save.waitForExistence(timeout: 5))
            let book = app.buttons.matching(identifier: "library.saveDestination.bookRow").firstMatch
            let chapter = app.buttons.matching(identifier: "library.saveDestination.chapterRow").firstMatch
            XCTAssertTrue(book.isSelected); XCTAssertTrue(chapter.isSelected)
            XCTAssertTrue(book.label.contains("QA private library 42 with a longer book title"))
            for _ in 0..<16 { if save.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(save.isHittable); XCTAssertTrue(save.isEnabled); save.tap()
            let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@",
                "saved pages: 1; books: 1; metadata intact: true"), object: readback)
            XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 5), .completed)
            XCTAssertFalse(save.exists)
            captureGame(app, name: "game-save-original-metadata-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testUnifiedSymptomFiltersRestoreRecordedHistoryWithoutMutatingActualFixtureRecords() {
        for language in ["en", "fr"] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                app.launchArguments += ["-fruitfolioSymptomGraphQA", "-fruitfolioSymptomGraphLanguage", language,
                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
                if reduced { app.launchArguments += ["-fruitfolioSymptomGraphReduceMotion"] }
                app.launch()
                let symptoms = app.buttons["trends.tab.symptoms"]
                XCTAssertTrue(symptoms.waitForExistence(timeout: 8)); symptoms.tap()
                let scroll = app.scrollViews["symptomQA.scroll"]
                let cramps = app.buttons["trends.symptoms.filter.cramps"]
                let fatigue = app.buttons["trends.symptoms.filter.fatigue"]
                XCTAssertTrue(cramps.waitForExistence(timeout: 5))
                XCTAssertTrue(cramps.isSelected); XCTAssertTrue(fatigue.isSelected)
                for button in [cramps, fatigue] {
                    for _ in 0..<16 { if button.isHittable { break }; scroll.swipeUp() }
                    XCTAssertTrue(button.isHittable); button.tap()
                }
                let hidden = app.descendants(matching: .any).matching(identifier: "trends.symptoms.hiddenSelection").firstMatch
                XCTAssertTrue(hidden.waitForExistence(timeout: 5))
                XCTAssertFalse(cramps.isSelected); XCTAssertFalse(fatigue.isSelected)
                XCUIDevice.shared.press(.home); app.activate()
                XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
                XCTAssertTrue(hidden.waitForExistence(timeout: 8))
                let restore = app.buttons["trends.symptoms.showAll"]
                for _ in 0..<16 { if restore.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(restore.isHittable); restore.tap()
                XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "trends.symptoms.graph").firstMatch.waitForExistence(timeout: 5))
                XCTAssertTrue(cramps.isSelected); XCTAssertTrue(fatigue.isSelected)
                app.buttons["symptomQA.inspect"].tap()
                let reads = app.staticTexts["symptomQA.reads"]
                let readFinished = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "fixture reads: 1"), object: reads)
                XCTAssertEqual(XCTWaiter.wait(for: [readFinished], timeout: 5), .completed)
                XCTAssertEqual(app.staticTexts["symptomQA.records"].label, "fixture logs: 2; observations: 4; unchanged: true")
                XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "symptomQA.issue").firstMatch.exists)
                captureGame(app, name: "symptom-graph-filters-\(language)-\(reduced)")
                app.terminate()
            }
        }
    }

    func testContactFailureUsesMeasuredModalAndRestoresLinkAccess() {
        for arabic in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioContactQA", "-fruitfolioContactQAPauseInference", "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioContactReduceMotion"] }
            if arabic { app.launchArguments += ["-fruitfolioContactQAArabic"] }
            app.launch()
            let link = app.buttons["contact.link.instagram"]
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            for _ in 0..<8 { if link.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(link.label.contains("@fruitsoflife.xo"))
            link.tap()
            let close = app.buttons["contact.linkFailure.close"]
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 3))
            let url = app.staticTexts["contact.linkFailure.destinationURL"]
            XCTAssertTrue(url.waitForExistence(timeout: 3))
            XCTAssertEqual(url.label, "https://www.instagram.com/fruitsoflife.xo")
            XCTAssertFalse(app.buttons["contact.link.email"].exists)
            for _ in 0..<12 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            XCTAssertGreaterThanOrEqual(close.frame.height, 44)
            XCTAssertGreaterThanOrEqual(close.frame.minX, scroll.frame.minX)
            XCTAssertLessThanOrEqual(close.frame.maxX, scroll.frame.maxX)
            XCTAssertGreaterThanOrEqual(close.frame.minY, app.frame.minY)
            XCTAssertLessThanOrEqual(close.frame.maxY, app.frame.maxY)
            captureGame(app, name: "contact-protected-link-arabic-\(arabic)-reduced-\(reduced)")
            close.tap()
            XCTAssertTrue(link.waitForExistence(timeout: 3))
            app.terminate()
        }
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

    func testSetupFeedbackKeepsClinicalMessagesCalmAndNativeLevelLocalized() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
        for scenario in ["setup-unavailable", "setup-urgent", "setup-urgent-opaque", "setup-unsupported-sensitive", "setup-exhausted-sensitive"] {
            let serious = scenario != "setup-unavailable"
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", scenario,
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let message = app.descendants(matching: .any).matching(identifier: "fruitBasket.setup.message").firstMatch
            XCTAssertTrue(message.waitForExistence(timeout: 8))
            if serious {
                let raw = ([message.label] + message.descendants(matching: .staticText).allElementsBoundByIndex.map(\.label)).joined(separator: " ")
                let content = raw.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.joined(separator: " ")
                XCTAssertFalse(content.isEmpty)
                if scenario == "setup-unsupported-sensitive" { XCTAssertTrue(content.contains("not enough approved research")) }
                if scenario == "setup-exhausted-sensitive" { XCTAssertTrue(content.contains("available questions")) }
                XCTAssertFalse(content.contains(":,)")); XCTAssertFalse(content.contains("little patch"))
            }
            let level = app.descendants(matching: .any).matching(identifier: "fruitBasket.setup.startingLevel").firstMatch
            XCTAssertTrue(level.exists)
            XCTAssertTrue(level.label.contains(language == "ar" ? "١" : "1"))
            let probe = app.staticTexts["gameQA.setupFeedbackArtActive"]
            let expected = "setup feedback art active: \(!serious)"
            let art = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: probe)
            XCTAssertEqual(XCTWaiter.wait(for: [art], timeout: 5), .completed)
            captureGame(app, name: "setup-feedback-\(language)-reduced-\(reduced)-\(scenario)")
            app.terminate()
        }
        }
        }
    }

    func testGameHomeAndNativeTopicInputRemainReachableAtAccessibilitySize() {
        for language in ["en", "fr"] {
            for reduced in [false, true] {
                XCUIDevice.shared.orientation = .portrait
                let app = XCUIApplication()
                app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "home",
                    "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
                if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
                app.launch()
                let scroll = app.scrollViews["fruitBasket.home.scroll"]
                XCTAssertTrue(scroll.waitForExistence(timeout: 5))
                XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "fruitBasket.home.invitation").firstMatch.exists)
                for orientation in [XCUIDeviceOrientation.portrait, .landscapeLeft] {
                    XCUIDevice.shared.orientation = orientation
                    for id in ["fruitBasket.home.play", "fruitBasket.home.rules", "fruitBasket.openLeaderboard"] {
                        let button = app.buttons[id]
                        for _ in 0..<16 { if button.isHittable { break }; scroll.swipeUp() }
                        XCTAssertTrue(button.isHittable)
                        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                        XCTAssertGreaterThanOrEqual(button.frame.minX, app.frame.minX)
                        XCTAssertLessThanOrEqual(button.frame.maxX, app.frame.maxX)
                    }
                    for _ in 0..<16 { if app.buttons["fruitBasket.home.play"].isHittable { break }; scroll.swipeDown() }
                }
                XCUIDevice.shared.orientation = .portrait
                for _ in 0..<16 { if app.buttons["fruitBasket.home.play"].isHittable { break }; scroll.swipeDown() }
                app.buttons["fruitBasket.home.play"].tap()
                let input = app.textFields["fruitBasket.topicInput"]
                let anyInput = app.descendants(matching: .any).matching(identifier: "fruitBasket.topicInput").firstMatch
                XCTAssertTrue(anyInput.waitForExistence(timeout: 5))
                let native = input.exists ? input : app.textViews["fruitBasket.topicInput"]
                XCTAssertTrue(native.exists)
                let catchMode = app.buttons["fruitBasket.controlMode.catch"]
                let classificationMode = app.buttons["fruitBasket.controlMode.classification"]
                XCTAssertTrue(catchMode.exists); XCTAssertTrue(classificationMode.exists)
                for _ in 0..<16 { if catchMode.isHittable && classificationMode.isHittable { break }; app.swipeUp() }
                XCTAssertTrue(catchMode.isHittable); XCTAssertTrue(classificationMode.isHittable)
                XCTAssertNotEqual(catchMode.isSelected, classificationMode.isSelected)
                let chosen = catchMode.isSelected ? classificationMode : catchMode
                let previous = catchMode.isSelected ? catchMode : classificationMode
                chosen.tap()
                XCTAssertTrue(chosen.isSelected); XCTAssertFalse(previous.isSelected)
                for _ in 0..<16 { if native.isHittable { break }; app.swipeDown() }
                for _ in 0..<16 { if native.isHittable { break }; app.swipeUp() }
                XCTAssertTrue(native.isHittable); native.tap(); native.typeText("reproductive health")
                XCTAssertEqual(native.value as? String, "reproductive health")
                captureGame(app, name: "game-home-native-topic-\(language)-\(reduced)")
                app.terminate()
                XCUIDevice.shared.orientation = .portrait
            }
        }
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

    private func launchGuideSave(_ scenario: String, reduced: Bool, rtl: Bool, language: String = "en") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioGuideSaveQA", "-fruitfolioGuideSaveQAScenario", scenario, "-fruitfolioAudioDiagnostics", "-fruitfolioGuideSaveQALanguage", language,
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioGuideSaveReduceMotion", "-fruitfolioAudioMuted"] }
        if rtl { app.launchArguments += ["-fruitfolioGuideSaveRTL"] }
        app.launch()
        return app
    }

    private func tapGuideFormAction(_ identifier: String, in app: XCUIApplication) {
        let action = app.buttons[identifier]
        let scroll = app.scrollViews["fruitfolio.notebookPopup.scroll"]
        for _ in 0..<24 { if action.isHittable { break }; scroll.swipeUp() }
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        action.tap()
    }

    private func expectGuidePopupRequests(open: Int, close: Int, in app: XCUIApplication) {
        let opened = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "popup open requests: \(open)"), object: app.staticTexts["audioQA.openRequests"])
        let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "popup close requests: \(close)"), object: app.staticTexts["audioQA.closeRequests"])
        // The successful save card has its own real accessibility-aware timer;
        // this verifies the settled logical counts, not physical audibility.
        XCTAssertEqual(XCTWaiter.wait(for: [opened, closed], timeout: 6), .completed)
    }

    func testGuidePageDestinationSurvivesBackgroundAndSavesOnlyToChosenSection() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = launchGuideSave("pages", reduced: reduced, rtl: rtl)
            let open = app.buttons["guide.savedPages.open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            let workspace = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; workspace.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let destination = app.buttons["guide.savedPages.destination"]
            XCTAssertTrue(destination.waitForExistence(timeout: 3))
            let scroll = app.scrollViews["fruitfolio.notebookPopup.scroll"]
            for _ in 0..<24 { if destination.isHittable { break }; scroll.swipeUp() }
            destination.tap()
            app.buttons["QA second section"].tap()
            let selected = destination.label + " " + (destination.value as? String ?? "")
            XCTAssertTrue(selected.contains("QA second section"))
            let candidate = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "guide.savedPages.candidate.")).firstMatch
            for _ in 0..<24 { if candidate.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(candidate.isHittable); candidate.tap()
            XCUIDevice.shared.press(.home); app.activate()
            XCTAssertTrue(destination.waitForExistence(timeout: 5))
            XCTAssertEqual(destination.label + " " + (destination.value as? String ?? ""), selected)
            expectGuidePopupRequests(open: 1, close: 0, in: app)
            tapGuideFormAction("guide.savedPages.add", in: app)
            let second = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "second section pages: 1"), object: app.staticTexts["guideQA.secondSectionPages"])
            XCTAssertEqual(XCTWaiter.wait(for: [second], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["guideQA.firstSectionPages"].label, "first section pages: 0")
            expectGuidePopupRequests(open: 2, close: 2, in: app)
            captureGame(app, name: "guide-page-destination-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testGuideMultiplePageSelectionIsOneAcknowledgedSaveOrNoSavedStatus() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for dropped in [false, true] {
            let app = launchGuideSave(dropped ? "dropped-batch-pages" : "batch-pages", reduced: reduced, rtl: rtl)
            let open = app.buttons["guide.savedPages.open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            let workspace = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; workspace.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let scroll = app.scrollViews["fruitfolio.notebookPopup.scroll"]
            let candidates = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "guide.savedPages.candidate."))
            XCTAssertEqual(candidates.count, 2)
            for index in 0..<2 {
                let candidate = candidates.element(boundBy: index)
                for _ in 0..<24 { if candidate.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(candidate.isHittable); candidate.tap()
            }
            tapGuideFormAction("guide.savedPages.add", in: app)
            let expected = dropped ? "first section pages: 0" : "first section pages: 2"
            let persisted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: app.staticTexts["guideQA.firstSectionPages"])
            XCTAssertEqual(XCTWaiter.wait(for: [persisted], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["guideQA.secondSectionPages"].label, "second section pages: 0")
            XCTAssertEqual(app.staticTexts["guideQA.writeAttempts"].label, "library write attempts: 1")
            if dropped {
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
                XCTAssertEqual(app.staticTexts["guideQA.writeProtected"].label, "write protected: true")
                XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: 0")
                XCTAssertTrue(app.buttons["guide.savedPages.add"].exists)
                expectGuidePopupRequests(open: 1, close: 0, in: app)
            } else {
                XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: 1")
                expectGuidePopupRequests(open: 2, close: 2, in: app)
            }
            captureGame(app, name: "guide-batch-dropped-\(dropped)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testGuideReorderAcknowledgesPersistenceAndOffersReloadAfterRejectedWrite() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for dropped in [false, true] {
            let app = launchGuideSave(dropped ? "dropped-reorder" : "reorder", reduced: reduced, rtl: rtl)
            let toggle = app.buttons["guide.reorder.toggle"]
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<24 { if toggle.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(toggle.isHittable); toggle.tap()
            let move = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND enabled == true", "guide.section.moveUp.")).firstMatch
            for _ in 0..<24 { if move.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(move.isHittable); move.tap()
            let expected = "first section name: " + (dropped ? "QA first section" : "QA second section")
            let persisted = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: app.staticTexts["guideQA.firstSectionName"])
            XCTAssertEqual(XCTWaiter.wait(for: [persisted], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["guideQA.writeAttempts"].label, "library write attempts: 1")
            XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: \(dropped ? 0 : 1)")
            if dropped {
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
                XCTAssertEqual(app.staticTexts["guideQA.writeProtected"].label, "write protected: true")
                let reload = app.buttons["library.reloadSavedRecord"]
                for _ in 0..<24 { if reload.isHittable { break }; scroll.swipeDown() }
                XCTAssertTrue(reload.isHittable); reload.tap()
                let writable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "write protected: false"), object: app.staticTexts["guideQA.writeProtected"])
                XCTAssertEqual(XCTWaiter.wait(for: [writable], timeout: 3), .completed)
                XCTAssertEqual(app.staticTexts["guideQA.firstSectionName"].label, expected)
                XCTAssertEqual(app.staticTexts["guideQA.writeAttempts"].label, "library write attempts: 1")
            } else {
                expectGuidePopupRequests(open: 1, close: 1, in: app)
            }
            captureGame(app, name: "guide-reorder-dropped-\(dropped)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testGuideFormReplacementClosesAndOpensOneOwnerWithoutSavingOnCancel() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = launchGuideSave("description", reduced: reduced, rtl: rtl)
            let open = app.buttons["guide.savedPages.open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            let workspace = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; workspace.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            expectGuidePopupRequests(open: 1, close: 0, in: app)
            tapGuideFormAction("guide.savedPages.newSection", in: app)
            XCTAssertTrue(app.buttons["guide.section.cancel"].waitForExistence(timeout: 3))
            expectGuidePopupRequests(open: 2, close: 1, in: app)
            tapGuideFormAction("guide.section.cancel", in: app)
            expectGuidePopupRequests(open: 2, close: 2, in: app)
            XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
            XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: 0")
            captureGame(app, name: "guide-form-replacement-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testGuideContentsNativeOrdinalsAndSearchKeepAuthoredNamesAndQuery() {
        for language in ["fr", "ar"] {
            for reduced in [false, true] {
                let app = launchGuideSave("search", reduced: reduced, rtl: language == "ar", language: language)
                let workspace = app.scrollViews.firstMatch
                let entry = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@",
                    "guide.contents.entry.", "QA first section")).firstMatch
                for _ in 0..<24 { if entry.isHittable { break }; workspace.swipeUp() }
                XCTAssertTrue(entry.isHittable)
                XCTAssertGreaterThanOrEqual(entry.frame.height, 44)
                XCTAssertTrue(entry.label.contains(language == "ar" ? "٠١" : "01"))
                XCTAssertTrue(entry.label.contains("QA first section"))
                let field = app.textFields["guide.search"]
                for _ in 0..<24 { if field.isHittable { break }; workspace.swipeDown() }
                XCTAssertTrue(field.isHittable)
                field.tap(); field.typeText("QA unmatched 987654321")
                let query = field.value as? String
                XCTAssertTrue(query?.contains("987654321") == true)
                XCTAssertTrue(app.descendants(matching: .any)["guide.search.empty"].waitForExistence(timeout: 5))
                XCTAssertEqual(field.value as? String, query)
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
                XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: 0")
                captureGame(app, name: "guide-contents-search-\(language)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testGuideTypedValidationPreservesPrivateDraftAndCoverUntilCancel() {
        for language in ["fr", "ar"] {
            for reduced in [false, true] {
                let app = launchGuideSave("create", reduced: reduced, rtl: language == "ar", language: language)
                let open = app.buttons["guide.create.open"]
                XCTAssertTrue(open.waitForExistence(timeout: 5))
                for _ in 0..<24 { if open.isHittable { break }; app.swipeUp() }
                open.tap()
                tapGuideFormAction("guide.create.save", in: app)
                let error = app.descendants(matching: .any).matching(identifier: "guide.form.error").firstMatch
                XCTAssertTrue(error.waitForExistence(timeout: 5))
                XCTAssertEqual(app.staticTexts["guideQA.persistedCount"].label, "persisted guide count: 0")
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
                let name = app.descendants(matching: .any).matching(identifier: "guide.create.name").firstMatch
                let paper = app.scrollViews["fruitfolio.notebookPopup.scroll"]
                for _ in 0..<24 { if name.isHittable { break }; paper.swipeDown() }
                name.tap(); name.typeText("clinical notes 12.50")
                let authored = name.value as? String
                XCTAssertTrue(authored?.contains("clinical notes 12.50") == true)
                let cover = app.buttons["guide.cover.lavender"]
                for _ in 0..<24 { if cover.isHittable { break }; paper.swipeUp() }
                XCTAssertTrue(cover.isHittable)
                XCTAssertGreaterThanOrEqual(cover.frame.height, 44)
                cover.tap()
                XCTAssertTrue(cover.isSelected)
                XCTAssertEqual(name.value as? String, authored)
                expectGuidePopupRequests(open: 1, close: 0, in: app)
                tapGuideFormAction("guide.create.cancel", in: app)
                expectGuidePopupRequests(open: 1, close: 1, in: app)
                XCTAssertEqual(app.staticTexts["guideQA.persistedCount"].label, "persisted guide count: 0")
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: true")
                XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, "saved status requests: 0")
                captureGame(app, name: "guide-typed-validation-\(language)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testGuideCreationSaveAndCancelUseActualPersistenceAndCallbacks() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for save in [false, true] {
            let app = launchGuideSave("create", reduced: reduced, rtl: rtl)
            let open = app.buttons["guide.create.open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            let home = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; home.swipeUp() }
            open.tap()
            let name = app.descendants(matching: .any).matching(identifier: "guide.create.name").firstMatch
            XCTAssertTrue(name.waitForExistence(timeout: 3))
            let heading = app.descendants(matching: .any).matching(identifier: "guide.form.heading.create").firstMatch
            XCTAssertTrue(heading.exists)
            XCTAssertEqual(heading.label, "let’s make your guide ♡", "English source fallback is not foreign translation verification")
            expectGuidePopupRequests(open: 1, close: 0, in: app)
            name.tap(); name.typeText("QA created guide")
            let description = app.descendants(matching: .any).matching(identifier: "guide.create.description").firstMatch
            let scroll = app.scrollViews["fruitfolio.notebookPopup.scroll"]
            for _ in 0..<24 { if description.isHittable { break }; scroll.swipeUp() }
            description.tap(); description.typeText("QA created description")
            tapGuideFormAction(save ? "guide.create.save" : "guide.create.cancel", in: app)
            let requestCount = app.staticTexts["guideQA.savedStatusRequests"]
            let expected = "saved status requests: \(save ? 1 : 0)"
            let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: requestCount)
            XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 3), .completed)
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: name)
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["guideQA.persistedCount"].label, "persisted guide count: \(save ? 1 : 0)")
            XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: \(!save)")
            if save {
                let status = app.descendants(matching: .any).matching(identifier: "guide.savedConfirmation.label").firstMatch
                XCTAssertTrue(status.waitForExistence(timeout: 2))
                XCTAssertEqual(status.label, "saved!")
                let content = app.scrollViews["guide.savedConfirmation.content"]
                XCTAssertTrue(content.exists)
                XCTAssertGreaterThan(status.frame.height, 0)
                XCTAssertGreaterThanOrEqual(status.frame.minX, content.frame.minX - 2)
                XCTAssertLessThanOrEqual(status.frame.maxX, content.frame.maxX + 2)
                XCTAssertGreaterThanOrEqual(status.frame.minY, content.frame.minY - 2)
                XCTAssertLessThanOrEqual(status.frame.maxY, content.frame.maxY + 2)
                XCTAssertFalse(app.buttons["translation.originalToggle"].exists, "A compact save status has no long-form translation controls")
                XCTAssertEqual(app.staticTexts["guideQA.persistedName"].label, "persisted name: QA created guide")
                XCTAssertEqual(app.staticTexts["guideQA.persistedDescription"].label, "persisted description: QA created description")
            } else { XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "guide.savedConfirmation").firstMatch.exists) }
            expectGuidePopupRequests(open: save ? 2 : 1, close: save ? 2 : 1, in: app)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
            captureGame(app, name: "guide-create-save-\(save)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testGuideFixedHeadingAndSavedStatusKeepSourceFallbackWithoutLongFormControlsWhenInferencePaused() {
        for reduced in [false, true] {
        for rtl in [false, true] {
            let app = launchGuideSave("create", reduced: reduced, rtl: rtl, language: "fr")
            let open = app.buttons["guide.create.open"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            let home = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; home.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let heading = app.descendants(matching: .any).matching(identifier: "guide.form.heading.create").firstMatch
            XCTAssertTrue(heading.waitForExistence(timeout: 3))
            XCTAssertTrue(heading.label.contains("let’s make your guide ♡"))
            XCTAssertFalse(app.buttons["translation.originalToggle"].exists)
            XCTAssertFalse(app.buttons["translation.retryAfterMemoryPressure"].exists)
            let name = app.descendants(matching: .any).matching(identifier: "guide.create.name").firstMatch
            name.tap(); name.typeText("QA source fallback")
            tapGuideFormAction("guide.create.save", in: app)
            let status = app.descendants(matching: .any).matching(identifier: "guide.savedConfirmation.label").firstMatch
            XCTAssertTrue(status.waitForExistence(timeout: 2))
            XCTAssertTrue(status.label.contains("saved!"), "Paused inference retains source; this is not verified French translation")
            XCTAssertFalse(app.buttons["translation.originalToggle"].exists)
            XCTAssertFalse(app.buttons["translation.retryAfterMemoryPressure"].exists)
            XCTAssertEqual(app.staticTexts["guideQA.persistedName"].label, "persisted name: QA source fallback")
            expectGuidePopupRequests(open: 2, close: 2, in: app)
            captureGame(app, name: "guide-fixed-copy-source-fallback-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
    }

    func testGuideDescriptionSaveCancelAndRejectedSavePreserveActualDataAndDraft() {
        for reduced in [false, true] {
        for rtl in [false, true] {
        for action in ["save", "cancel", "rejected", "dropped", "conflict"] {
            let scenario = action == "rejected" ? "stale-description" : (action == "dropped" ? "dropped-description" : (action == "conflict" ? "live-description" : "description"))
            let app = launchGuideSave(scenario, reduced: reduced, rtl: rtl)
            let options = app.buttons["guide.options.open"]
            XCTAssertTrue(options.waitForExistence(timeout: 5))
            options.tap()
            let open = app.buttons["guide.description.open"]
            let workspace = app.scrollViews.firstMatch
            for _ in 0..<24 { if open.isHittable { break }; workspace.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let input = app.descendants(matching: .any).matching(identifier: "guide.description.input").firstMatch
            XCTAssertTrue(input.waitForExistence(timeout: 3))
            let heading = app.descendants(matching: .any).matching(identifier: "guide.form.heading.description").firstMatch
            XCTAssertTrue(heading.exists)
            XCTAssertEqual(heading.label, "edit little description")
            input.tap(); input.typeText("QAedit")
            let draft = input.value as? String ?? ""
            XCTAssertTrue(draft.contains("QAedit"))
            let owner = app.staticTexts["guideQA.owner"].label
            XCUIDevice.shared.press(.home); app.activate()
            XCTAssertTrue(input.waitForExistence(timeout: 5))
            XCTAssertEqual(input.value as? String, draft)
            XCTAssertEqual(app.staticTexts["guideQA.owner"].label, owner)
            expectGuidePopupRequests(open: 1, close: 0, in: app)
            tapGuideFormAction(action == "cancel" ? "guide.description.cancel" : "guide.description.save", in: app)
            let expected = "saved status requests: \(action == "save" ? 1 : 0)"
            let settled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: app.staticTexts["guideQA.savedStatusRequests"])
            XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 3), .completed)
            if action == "save" {
                let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: input)
                XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
                XCTAssertEqual(app.staticTexts["guideQA.persistedDescription"].label, "persisted description: " + draft)
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: false")
            } else {
                XCTAssertEqual(app.staticTexts["guideQA.originalBytesIntact"].label, "original bytes intact: \(action == "conflict" ? "false" : "true")")
                XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "guide.savedConfirmation").firstMatch.exists)
                if action == "cancel" {
                    let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: input)
                    XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
                    XCTAssertEqual(app.staticTexts["guideQA.persistedDescription"].label, "persisted description: QA original description")
                } else {
                    XCTAssertTrue(input.exists)
                    XCTAssertEqual(input.value as? String, draft)
                    let error = app.descendants(matching: .any).matching(identifier: "guide.form.error").firstMatch
                    XCTAssertTrue(error.waitForExistence(timeout: 3))
                    if action == "conflict" {
                        XCTAssertEqual(error.label, "this saved item changed while you were editing. your draft is still here, and nothing was overwritten. review the current saved item before trying again.")
                    }
                    let protected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "write protected: \(action == "conflict" ? "false" : "true")"), object: app.staticTexts["guideQA.writeProtected"])
                    XCTAssertEqual(XCTWaiter.wait(for: [protected], timeout: 3), .completed)
                    if action == "conflict" {
                        XCTAssertEqual(app.staticTexts["guideQA.persistedDescription"].label, "persisted description: QA newer description")
                        XCTAssertEqual(app.staticTexts["guideQA.writeAttempts"].label, "library write attempts: 1", "Only the newer background edit may write")
                    }
                    if action == "dropped" {
                        XCTAssertEqual(app.staticTexts["guideQA.persistedDescription"].label, "persisted description: QA original description")
                        XCTAssertEqual(app.staticTexts["guideQA.persistedCount"].label, "persisted guide count: 1")
                    }
                }
            }
            XCTAssertEqual(app.staticTexts["guideQA.savedStatusRequests"].label, expected)
            expectGuidePopupRequests(open: action == "save" ? 2 : 1,
                close: action == "save" ? 2 : (action == "cancel" ? 1 : 0), in: app)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 3")
            captureGame(app, name: "guide-description-\(action)-reduced-\(reduced)-rtl-\(rtl)")
            app.terminate()
        }
        }
        }
    }

    func testGameRulesRetainCompleteSourceFallbackAndReplayReturnActionsAtAccessibilitySize() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
        for replay in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "rules",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let heading = app.descendants(matching: .any).matching(identifier: "fruitBasket.rules.heading").firstMatch
            XCTAssertTrue(heading.waitForExistence(timeout: 5))
            XCTAssertEqual(heading.label, "how it works!")
            let scroll = app.scrollViews["fruitBasket.rules.scroll"]
            for title in ["1. pick what you want to learn", "2. answer", "3. catch", "4. fill your basket"] {
                let label = app.descendants(matching: .any).matching(identifier: "fruitBasket.rules.title." + title).firstMatch
                for _ in 0..<24 { if label.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(label.isHittable)
                XCTAssertEqual(label.label, title)
                XCTAssertFalse(label.label.contains("**"))
            }
            let action = app.buttons[replay ? "fruitBasket.rules.replayTour" : "fruitBasket.rules.returnHome"]
            for _ in 0..<24 { if action.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(action.isHittable)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
            captureGame(app, name: "rules-language-\(language)-reduced-\(reduced)-replay-\(replay)")
            action.tap()
            if replay { XCTAssertTrue(app.otherElements["fruitBasket.tour"].waitForExistence(timeout: 3)) }
            else { XCTAssertTrue(app.buttons["fruitBasket.openLeaderboard"].waitForExistence(timeout: 3)) }
            app.terminate()
        }
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
            XCTAssertEqual(pear.label, "pear. attached star marker. belongs in basket")
            XCTAssertEqual(lemon.label, "lemon. no attached star marker. does not belong in basket")
            XCTAssertEqual(star.label, "a standalone star — catch it to bank one star pass after it fully enters and settles. it does not fill the fruit basket or add points.")
            XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "fruitBasket.round.star").count, 1)
            XCTAssertFalse(pear.label.contains("**"))
            XCTAssertFalse(lemon.label.contains("**"))
            captureGame(app, name: "catch-object-labels-language-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testLargeStarBankRemainsNativeLocalizedAndAccessible() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "bank-large",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let bank = app.descendants(matching: .any).matching(identifier: "fruitBasket.classification.passes").firstMatch
            XCTAssertTrue(bank.waitForExistence(timeout: 8))
            XCTAssertEqual(bank.value as? String, language == "ar" ? "١٬٠٠١" : "1,001")
            XCTAssertFalse(bank.label.isEmpty)
            captureGame(app, name: "large-star-bank-\(language)-reduced-\(reduced)")
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
            let aid = app.buttons["fruitBasket.question.readingAid.toggle"]
            if language == "ar" {
                XCTAssertTrue(aid.exists)
                for _ in 0..<20 { if aid.isHittable { break }; scroll.swipeUp() }
                XCTAssertTrue(aid.isHittable); aid.tap()
                let content = app.descendants(matching: .any).matching(identifier: "fruitBasket.question.readingAid.content").firstMatch
                XCTAssertTrue(content.waitForExistence(timeout: 5))
                let original = content.descendants(matching: .staticText).matching(NSPredicate(format: "label == %@",
                    "UI fixture only: the selected word is [blank].")).firstMatch
                XCTAssertTrue(original.waitForExistence(timeout: 3))
                XCTAssertEqual(excerpt.label, "UI fixture only: the selected word is [blank].")
                captureGame(app, name: "game-reading-aid-paused-reduced-\(reduced)")
                for _ in 0..<20 { if aid.isHittable { break }; scroll.swipeDown() }
                XCTAssertTrue(aid.isHittable); aid.tap()
                XCTAssertFalse(content.exists)
            } else { XCTAssertFalse(aid.exists) }
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

    func testActualSettingsLanguageSurvivesFAQNavigationAndAppRelaunch() {
        for (code, nativeName) in [("fr", "Français"), ("ar", "العربية")] {
        for reduced in [false, true] {
            XCUIDevice.shared.orientation = .portrait
            let app = XCUIApplication()
            app.launchArguments = ["-fruitfolioLanguagePersistenceQA", "-fruitfolioLanguagePersistenceToken", UUID().uuidString,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioLanguagePersistenceReduceMotion"] }
            defer {
                app.terminate()
                app.launchArguments += ["-fruitfolioLanguagePersistenceCleanup"]
                app.launch()
                let saved = app.staticTexts["languagePersistence.saved"]
                XCTAssertTrue(saved.waitForExistence(timeout: 8))
                let cleared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "saved language: missing"), object: saved)
                XCTAssertEqual(XCTWaiter.wait(for: [cleared], timeout: 5), .completed)
                app.terminate()
            }
            app.launch()
            let fixture = app.staticTexts["languagePersistence.fixture"]
            XCTAssertTrue(fixture.waitForExistence(timeout: 8)); XCTAssertEqual(fixture.label, "persistent fixture: true")
            let menu = app.buttons["settings.language"]
            XCTAssertTrue(menu.waitForExistence(timeout: 5)); XCTAssertTrue(menu.isHittable); menu.tap()
            let identified = app.buttons["settings.language.option." + code]
            let option = identified.waitForExistence(timeout: 2) ? identified : app.buttons[nativeName]
            XCTAssertTrue(option.waitForExistence(timeout: 3)); option.tap()
            let selected = app.staticTexts["languagePersistence.selected"]
            let saved = app.staticTexts["languagePersistence.saved"]
            let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "selected language: " + code), object: selected)
            XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed)
            XCTAssertEqual(saved.label, "saved language: " + code)
            app.buttons["languagePersistence.showFAQ"].tap()
            XCTAssertTrue(app.buttons["faq.question.about-1"].waitForExistence(timeout: 5))
            XCTAssertEqual(selected.label, "selected language: " + code)
            let environment = app.staticTexts["languagePersistence.environment"]
            XCTAssertTrue(environment.label.hasPrefix("locale: " + code))
            XCTAssertTrue(environment.label.contains(code == "ar" ? "direction: rtl" : "direction: ltr"))
            app.buttons["languagePersistence.showSettings"].tap()
            XCTAssertTrue(menu.waitForExistence(timeout: 5)); XCTAssertEqual(menu.value as? String, nativeName)
            app.terminate(); app.launch()
            XCTAssertTrue(selected.waitForExistence(timeout: 8))
            XCTAssertEqual(selected.label, "selected language: " + code)
            XCTAssertEqual(saved.label, "saved language: " + code)
            XCTAssertEqual(menu.value as? String, nativeName)
            captureGame(app, name: "language-relaunch-\(code)-reduced-\(reduced)")
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
            captureGame(app, name: "faq-plain-question-expanded-arabic-\(arabic)-reduced-\(reduced)")
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

    private func openDraftFixturePage(_ app: XCUIApplication, reduced: Bool = true, rtl: Bool = false) {
        app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookDraftFixture", "-fruitfolioBookQAPauseInference"]
        if reduced { app.launchArguments += ["-fruitfolioBookReduceMotion"] }
        if rtl { app.launchArguments += ["-fruitfolioBookQAArabic"] }
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

    private func openLegacyExcerptFixture(_ app: XCUIApplication, reduced: Bool, rtl: Bool, missing: Bool = false, openPage: Bool = true) {
        app.launchArguments += ["-fruitfolioBookQA",
            missing ? "-fruitfolioBookMissingExcerptFixture" : "-fruitfolioBookLegacyExcerptFixture",
            "-fruitfolioBookQAPauseInference", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        if reduced { app.launchArguments += ["-fruitfolioBookReduceMotion"] }
        if rtl { app.launchArguments += ["-fruitfolioBookQAArabic"] }
        app.launch()
        let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA sage,")).firstMatch
        for _ in 0..<16 { if book.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(book.isHittable)
        book.tap()
        if !openPage { return }
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.textViews["savedPage.notes"].waitForExistence(timeout: 5))
    }

    func testGuideLongAuthoredTitleKeepsSeparateControlsAndNativeCountFallback() {
        for rtl in [false, true] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookLongGuideFixture", "-fruitfolioBookQAPauseInference",
                    "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
                if rtl { app.launchArguments += ["-fruitfolioBookQAArabic"] }
                if reduced { app.launchArguments += ["-fruitfolioBookReduceMotion"] }
                app.launch()
                let builder = app.buttons["QA guide builder"]
                XCTAssertTrue(builder.waitForExistence(timeout: 5)); builder.tap()
                let originalName = "QA extremely long clinical material guide"
                let tile = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", originalName)).firstMatch
                for _ in 0..<20 { if tile.isHittable { break }; app.swipeUp() }
                XCTAssertTrue(tile.isHittable)
                XCTAssertGreaterThanOrEqual(tile.frame.height, 44)
                tile.tap()
                let title = app.staticTexts["guide.workspace.title"]
                XCTAssertTrue(title.waitForExistence(timeout: 5))
                XCTAssertEqual(title.label, originalName)
                let back = app.buttons["guide.workspace.back"]
                let options = app.buttons["guide.options.open"]
                XCTAssertFalse(title.frame.intersects(back.frame))
                XCTAssertFalse(title.frame.intersects(options.frame))
                XCTAssertGreaterThanOrEqual(options.frame.height, 44)
                let pages = app.descendants(matching: .any)["guide.workspace.pageCount"]
                XCTAssertTrue(pages.label.contains(rtl ? "٠" : "0"))
                options.tap()
                XCTAssertEqual(title.label, originalName)
                options.tap()
                XCTAssertEqual(title.label, originalName)
                captureGame(app, name: "guide-long-title-rtl-\(rtl)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testBookContentsFixedControlsRespectDirectionAndPreserveAuthoredPageLabels() {
        for rtl in [false, true] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                openLegacyExcerptFixture(app, reduced: reduced, rtl: rtl, openPage: false)
                let heading = app.descendants(matching: .any)["savedBook.heading"]
                XCTAssertTrue(heading.waitForExistence(timeout: 5))
                XCTAssertFalse(heading.frame.intersects(app.buttons["savedBook.back"].frame))
                let contents = app.descendants(matching: .any)["savedBook.contents"]
                let savedContent = app.descendants(matching: .any)["savedBook.savedContent"]
                XCTAssertEqual(contents.label, rtl ? "contents, right book page" : "contents, left book page")
                XCTAssertEqual(savedContent.label, rtl ? "saved content, left book page" : "saved content, right book page")
                for identifier in ["savedBook.rename", "savedBook.delete", "savedBook.addOwnPage"] {
                    let button = app.buttons[identifier]
                    XCTAssertTrue(button.exists)
                    XCTAssertGreaterThanOrEqual(button.frame.height, 44)
                }
                let chapter = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.chapter.")).firstMatch
                XCTAssertTrue(chapter.exists)
                XCTAssertTrue(chapter.label.contains(rtl ? "١" : "1"))
                XCTAssertTrue((chapter.value as? String)?.contains("expanded") == true)
                chapter.tap()
                XCTAssertTrue((chapter.value as? String)?.contains("collapsed") == true)
                XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch.exists)
                chapter.tap()
                let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch
                XCTAssertTrue(row.waitForExistence(timeout: 5))
                XCTAssertTrue(row.label.contains("QA legacy excerpt"))
                row.tap()
                XCTAssertTrue(app.textViews["savedPage.notes"].waitForExistence(timeout: 5))
                XCTAssertFalse(contents.exists)
                captureGame(app, name: "book-contents-rtl-\(rtl)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testLegacyExcerptExplicitKeepThenCleanupPreservesNotesAcrossPaperAndPageRemount() {
        for rtl in [false, true] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                openLegacyExcerptFixture(app, reduced: reduced, rtl: rtl)
                let reading = app.scrollViews["savedPage.scroll"]
                let review = app.buttons["savedPage.reviewLegacyExcerpt"]
                for _ in 0..<20 { if review.isHittable { break }; reading.swipeUp() }
                XCTAssertTrue(review.isHittable)
                XCTAssertGreaterThanOrEqual(review.frame.height, 44)
                review.tap()
                let keep = app.buttons["fruitPopup.paper.action.primary"]
                XCTAssertTrue(keep.waitForExistence(timeout: 5))
                XCTAssertFalse(review.exists, "Background page must be hidden from accessibility")
                keep.tap()
                XCTAssertTrue(review.waitForExistence(timeout: 5))
                XCTAssertFalse(app.staticTexts["savedPage.legacyExcerptCleaned"].exists)
                review.tap()
                let confirm = app.buttons["fruitPopup.paper.action.secondary"]
                XCTAssertTrue(confirm.waitForExistence(timeout: 5))
                confirm.tap()
                XCTAssertTrue(app.staticTexts["savedPage.legacyExcerptCleaned"].waitForExistence(timeout: 5))
                XCTAssertEqual(app.textViews["savedPage.notes"].value as? String, "QA original note")
                let back = app.buttons["savedPage.back"]
                for _ in 0..<20 { if back.isHittable { break }; reading.swipeDown() }
                back.tap()
                let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "savedBook.page.")).firstMatch
                XCTAssertTrue(row.waitForExistence(timeout: 5)); row.tap()
                XCTAssertTrue(app.textViews["savedPage.notes"].waitForExistence(timeout: 5))
                XCTAssertFalse(app.buttons["savedPage.reviewLegacyExcerpt"].exists)
                XCTAssertFalse(app.staticTexts["savedPage.legacyExcerptNotice"].exists)
                XCTAssertEqual(app.textViews["savedPage.notes"].value as? String, "QA original note")
                captureGame(app, name: "legacy-excerpt-consent-rtl-\(rtl)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testSavedPageTypedNotesStatusPreservesAuthoredDraftWithPausedInference() {
        for rtl in [false, true] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                openLegacyExcerptFixture(app, reduced: reduced, rtl: rtl)
                let heading = app.descendants(matching: .any)["savedPage.heading"]
                XCTAssertTrue(heading.exists)
                XCTAssertFalse(heading.frame.intersects(app.buttons["savedPage.back"].frame))
                let reading = app.scrollViews["savedPage.scroll"]
                let notes = app.textViews["savedPage.notes"]
                for _ in 0..<20 { if notes.isHittable { break }; reading.swipeUp() }
                notes.tap(); notes.typeText(" QA saved 12.50 pg/mL")
                let authored = notes.value as? String
                XCTAssertTrue(authored?.contains("QA saved 12.50 pg/mL") == true)
                let save = app.buttons["savedPage.saveNotes"]
                for _ in 0..<20 { if save.isHittable { break }; reading.swipeUp() }
                XCTAssertTrue(save.isHittable); save.tap()
                let status = app.descendants(matching: .any)["savedPage.notesStatus"]
                XCTAssertTrue(status.waitForExistence(timeout: 5))
                XCTAssertEqual(notes.value as? String, authored)
                XCTAssertTrue(app.buttons["savedPage.reviewLegacyExcerpt"].exists,
                    "Saving notes never authorizes legacy answer deletion")
                for _ in 0..<20 { if notes.isHittable { break }; reading.swipeDown() }
                notes.tap(); notes.typeText(" unsaved draft")
                XCTAssertFalse(status.exists)
                XCTAssertTrue((notes.value as? String)?.contains("unsaved draft") == true)
                captureGame(app, name: "saved-page-notice-rtl-\(rtl)-reduced-\(reduced)")
                app.terminate()
            }
        }
    }

    func testLegacyExcerptMissingSelectionStaysReadableWithoutCleanupAction() {
        for reduced in [false, true] {
            let app = XCUIApplication()
            openLegacyExcerptFixture(app, reduced: reduced, rtl: true, missing: true)
            XCTAssertTrue(app.staticTexts["savedPage.legacyExcerptNotice"].exists)
            XCTAssertFalse(app.buttons["savedPage.reviewLegacyExcerpt"].exists)
            XCTAssertEqual(app.textViews["savedPage.notes"].value as? String, "QA original note")
            app.terminate()
        }
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

    func testLocalizedUserPageValidationKeepsExactAuthoredFieldsAndDiscardedOriginal() {
        for rtl in [false, true] {
            for reduced in [false, true] {
                let app = XCUIApplication()
                app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
                openDraftFixturePage(app, reduced: reduced, rtl: rtl)
                let reading = app.scrollViews["savedPage.scroll"]
                let edit = app.buttons["savedPage.editOwnPage"]
                for _ in 0..<20 { if edit.isHittable { break }; reading.swipeUp() }
                edit.tap()
                let paper = app.scrollViews["tapedWhitePopup.scroll"]
                let body = app.textViews["userPage.editor.body"]
                XCTAssertTrue(body.waitForExistence(timeout: 5))
                XCTAssertTrue(app.descendants(matching: .any)["userPage.editor.qualifier"].exists)
                XCTAssertEqual(app.textFields["userPage.editor.title"].value as? String, "QA editable page")
                for _ in 0..<20 { if body.isHittable { break }; paper.swipeUp() }
                body.tap(); body.typeText(" QA retained 12.50 pg/mL")
                let authored = body.value as? String
                let address = app.textFields["userPage.editor.source"]
                for _ in 0..<20 { if address.isHittable { break }; paper.swipeUp() }
                let invalidAddress = "https://user:password@example.org/author-input"
                address.tap(); address.typeText(invalidAddress)
                let save = app.buttons["userPage.editor.save"]
                for _ in 0..<20 { if save.isHittable { break }; paper.swipeUp() }
                save.tap()
                XCTAssertTrue(app.descendants(matching: .any)["userPage.editor.error"].waitForExistence(timeout: 5))
                XCTAssertEqual(body.value as? String, authored)
                XCTAssertEqual(address.value as? String, invalidAddress)
                let cancel = app.buttons["userPage.editor.cancel"]
                for _ in 0..<20 { if cancel.isHittable { break }; paper.swipeUp() }
                cancel.tap(); tapSharedPaperAction("primary", in: app)
                XCTAssertTrue(body.waitForExistence(timeout: 5))
                XCTAssertEqual(body.value as? String, authored)
                for _ in 0..<20 { if cancel.isHittable { break }; paper.swipeUp() }
                cancel.tap(); tapSharedPaperAction("tertiary", in: app)
                XCTAssertTrue(edit.waitForExistence(timeout: 5))
                for _ in 0..<20 { if edit.isHittable { break }; reading.swipeUp() }
                edit.tap()
                XCTAssertTrue(body.waitForExistence(timeout: 5))
                XCTAssertEqual(body.value as? String, "QA original own page text")
                XCTAssertFalse(app.descendants(matching: .any)["userPage.editor.error"].exists)
                captureGame(app, name: "user-page-validation-rtl-\(rtl)-reduced-\(reduced)")
                app.terminate()
            }
        }
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
        XCTAssertTrue(selected.isSelected)
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(selected.waitForExistence(timeout: 3))
        XCTAssertTrue(selected.isSelected)
        XCTAssertFalse(selected.isEnabled, "Reactivation must not bypass protected context storage")
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
        for language in ["en", "fr"] {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsLanguage", language]
        app.launch()
        let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
        XCTAssertTrue(edit.waitForExistence(timeout: 5))
        let heading = app.descendants(matching: .any).matching(identifier: "measurements.heading").firstMatch
        XCTAssertTrue(heading.label.contains("hormone information ♡"), "English/source fallback is not verified foreign localization")
        for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
        edit.tap()
        let editor = app.scrollViews["measurements.editor.scroll"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        let editorHeading = app.descendants(matching: .any).matching(identifier: "measurements.editor.heading").firstMatch
        XCTAssertTrue(editorHeading.label.contains("measurement"))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "measurements.editor.testDate").firstMatch.exists)
        let dateInstruction = app.descendants(matching: .any).matching(identifier: "measurements.editor.dateInstruction").firstMatch
        XCTAssertTrue(dateInstruction.label.contains("record the date as reported. the time of day is not collected."))
        let hormone = app.descendants(matching: .any).matching(identifier: "measurements.editor.hormone").firstMatch
        XCTAssertTrue((hormone.label + " " + (hormone.value as? String ?? "")).contains("E2"), "Controlled symbol remains literal under source fallback")
        let unit = app.textFields["measurements.editor.unit"]
        for _ in 0..<20 { if unit.isHittable { break }; editor.swipeUp() }
        XCTAssertEqual(unit.value as? String, "pg/mL")
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
        XCTAssertEqual(result.value as? String, "12.50", "Changing app language or a fixed prompt must not rewrite a laboratory result")
        for _ in 0..<20 { if unit.isHittable { break }; editor.swipeUp() }
        XCTAssertEqual(unit.value as? String, "pg/mL")
        for _ in 0..<20 { if day.isHittable { break }; editor.swipeUp() }
        XCTAssertEqual(day.value as? String, "12")
        captureGame(app, name: "measurement-field-prompts-language-\(language)")
        app.terminate()
        }
    }

    func testControlledOtherHormonePreservesEnteredNameAndExactLaboratoryFieldsUnderSourceFallback() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsLanguage", language]
            app.launch()
            let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            let editor = app.scrollViews["measurements.editor.scroll"]
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            let picker = app.descendants(matching: .any).matching(identifier: "measurements.editor.hormone").firstMatch
            XCTAssertTrue(picker.isHittable); picker.tap()
            let other = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Other Hormone")).firstMatch
            XCTAssertTrue(other.waitForExistence(timeout: 3)); other.tap()
            let name = app.textFields["measurements.editor.otherName"]
            XCTAssertTrue(name.waitForExistence(timeout: 3)); name.tap(); name.typeText("QA custom hormone")
            let save = app.buttons["measurements.editor.save"]
            for _ in 0..<24 { if save.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(save.isHittable); save.tap()
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["QA custom hormone"].exists)
            for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            XCTAssertEqual(name.value as? String, "QA custom hormone")
            let result = app.textFields["measurements.editor.result"]
            XCTAssertEqual(result.value as? String, "12.50")
            let unit = app.textFields["measurements.editor.unit"]
            for _ in 0..<20 { if unit.isHittable { break }; editor.swipeUp() }
            XCTAssertEqual(unit.value as? String, "pg/mL")
            captureGame(app, name: "controlled-other-hormone-source-fallback-\(language)")
            app.terminate()
        }
    }

    func testUnknownMeasurementFormatKeepsMetadataEditButRejectsChangedResultWithoutGuessing() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsUnknownFormat", "-fruitfolioMeasurementsLanguage", language]
            app.launch()
            let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            let editor = app.scrollViews["measurements.editor.scroll"]
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            let notes = app.descendants(matching: .any).matching(identifier: "measurements.editor.notes").firstMatch
            for _ in 0..<24 { if notes.isHittable { break }; editor.swipeUp() }
            notes.tap(); notes.typeText(" QA metadata only")
            let save = app.buttons["measurements.editor.save"]
            for _ in 0..<24 { if save.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(save.isHittable); save.tap()
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            for _ in 0..<16 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            let result = app.textFields["measurements.editor.result"]
            XCTAssertEqual(result.value as? String, "12,500")
            result.tap(); result.typeText("1")
            let draft = result.value as? String
            XCTAssertNotEqual(draft, "12,500")
            for _ in 0..<24 { if save.isHittable { break }; editor.swipeUp() }
            save.tap()
            let error = app.descendants(matching: .any).matching(identifier: "measurements.editor.errorText").firstMatch
            XCTAssertTrue(error.waitForExistence(timeout: 3))
            XCTAssertTrue(error.label.contains("choose the decimal separator used on the report"))
            XCTAssertTrue(editor.exists)
            for _ in 0..<24 { if result.isHittable { break }; editor.swipeDown() }
            XCTAssertEqual(result.value as? String, draft)
            captureGame(app, name: "unknown-measurement-format-source-fallback-\(language)")
            app.terminate()
        }
    }

    func testMeasurementEditorReloadRetainsRejectedDraftThenAcknowledgesRetry() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsDropNextWrite", "-fruitfolioMeasurementsLanguage", language,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            for _ in 0..<24 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            let editor = app.scrollViews["measurements.editor.scroll"]
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            let notes = app.descendants(matching: .any).matching(identifier: "measurements.editor.notes").firstMatch
            for _ in 0..<32 { if notes.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(notes.isHittable); notes.tap(); notes.typeText(" QA retry draft")
            let draft = notes.value as? String ?? ""
            XCTAssertTrue(draft.contains("QA retry draft"))
            let save = app.buttons["measurements.editor.save"]
            for _ in 0..<32 { if save.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(save.isHittable); save.tap()
            let error = app.descendants(matching: .any).matching(identifier: "measurements.editor.errorText").firstMatch
            XCTAssertTrue(error.waitForExistence(timeout: 3))
            XCTAssertTrue(error.label.contains("this measurement change could not be confirmed"))
            XCTAssertTrue(editor.exists)
            XCTAssertEqual(notes.value as? String, draft)
            XCUIDevice.shared.press(.home); app.activate()
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            XCTAssertEqual(notes.value as? String, draft)
            let reload = app.buttons["measurements.editor.reload"]
            for _ in 0..<32 { if reload.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(reload.isHittable); reload.tap()
            XCTAssertEqual(notes.value as? String, draft, "Reload must not reinitialize the native draft")
            XCTAssertFalse(error.exists)
            for _ in 0..<32 { if save.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(save.isHittable); save.tap()
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: editor)
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            let expected = "persisted notes: " + draft
            let acknowledged = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: app.staticTexts["measurementQA.persistedNotes"])
            XCTAssertEqual(XCTWaiter.wait(for: [acknowledged], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["measurementQA.persistedCount"].label, "persisted measurement count: 1")
            XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: 2")
            XCTAssertEqual(app.staticTexts["measurementQA.writeProtected"].label, "write protected: false")
            XCTAssertEqual(app.staticTexts["measurementQA.originalBytesIntact"].label, "original bytes intact: false")
            captureGame(app, name: "measurement-editor-reload-retry-language-\(language)")
            app.terminate()
        }
    }

    func testMeasurementDroppedDeletionPreservesRecordsUntilExplicitReloadAndFreshConfirmation() {
        for language in ["en", "fr"] {
        for all in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsLanguage", language,
                all ? "-fruitfolioMeasurementsDropNextErase" : "-fruitfolioMeasurementsDropNextWrite",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            let remove = app.buttons[all ? "measurements.eraseAll" : "measurements.delete.CF310000-0000-0000-0000-000000000001"]
            XCTAssertTrue(remove.waitForExistence(timeout: 5))
            let scroll = app.scrollViews.firstMatch
            for _ in 0..<32 { if remove.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(remove.isHittable); remove.tap()
            let paper = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(paper.waitForExistence(timeout: 5))
            let confirm = app.buttons["fruitPopup.paper.action.secondary"]
            for _ in 0..<24 { if confirm.isHittable { break }; paper.swipeUp() }
            XCTAssertTrue(confirm.isHittable); confirm.tap()
            let protected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "write protected: true"), object: app.staticTexts["measurementQA.writeProtected"])
            XCTAssertEqual(XCTWaiter.wait(for: [protected], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["measurementQA.persistedCount"].label, "persisted measurement count: 1")
            XCTAssertEqual(app.staticTexts["measurementQA.originalBytesIntact"].label, "original bytes intact: true")
            let reload = app.buttons["measurements.reloadSavedRecord"]
            for _ in 0..<32 { if reload.isHittable { break }; scroll.swipeDown() }
            XCTAssertTrue(reload.isHittable); reload.tap()
            let writable = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "write protected: false"), object: app.staticTexts["measurementQA.writeProtected"])
            XCTAssertEqual(XCTWaiter.wait(for: [writable], timeout: 3), .completed)
            for _ in 0..<32 { if remove.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(remove.isHittable); remove.tap()
            XCTAssertTrue(paper.waitForExistence(timeout: 5))
            for _ in 0..<24 { if confirm.isHittable { break }; paper.swipeUp() }
            XCTAssertTrue(confirm.isHittable); confirm.tap()
            let erased = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "persisted measurement count: 0"), object: app.staticTexts["measurementQA.persistedCount"])
            XCTAssertEqual(XCTWaiter.wait(for: [erased], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: \(all ? 0 : 2)")
            XCTAssertEqual(app.staticTexts["measurementQA.eraseAttempts"].label, "erase attempts: \(all ? 2 : 0)")
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "this measurement change could not be confirmed")).firstMatch.exists)
            captureGame(app, name: "measurement-deletion-retry-all-\(all)-language-\(language)")
            app.terminate()
        }
        }
    }

    func testMeasurementEditorReloadKeepsOldIntentAndCannotOverwriteNewerForeignRecord() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsForeignAfterDrop", "-fruitfolioMeasurementsLanguage", language]
            app.launch()
            let edit = app.buttons["measurements.edit.CF310000-0000-0000-0000-000000000001"]
            XCTAssertTrue(edit.waitForExistence(timeout: 5))
            for _ in 0..<20 { if edit.isHittable { break }; app.swipeUp() }
            edit.tap()
            let editor = app.scrollViews["measurements.editor.scroll"]
            XCTAssertTrue(editor.waitForExistence(timeout: 5))
            let notes = app.descendants(matching: .any).matching(identifier: "measurements.editor.notes").firstMatch
            for _ in 0..<24 { if notes.isHittable { break }; editor.swipeUp() }
            XCTAssertTrue(notes.isHittable); notes.tap(); notes.typeText(" QA still-open draft")
            let draft = notes.value as? String
            let save = app.buttons["measurements.editor.save"]
            for _ in 0..<24 { if save.isHittable { break }; editor.swipeUp() }
            save.tap()
            let reload = app.buttons["measurements.editor.reload"]
            XCTAssertTrue(reload.waitForExistence(timeout: 3))
            for _ in 0..<24 { if reload.isHittable { break }; editor.swipeUp() }
            reload.tap()
            XCTAssertEqual(notes.value as? String, draft)
            for _ in 0..<24 { if save.isHittable { break }; editor.swipeUp() }
            save.tap()
            let error = app.descendants(matching: .any).matching(identifier: "measurements.editor.errorText").firstMatch
            XCTAssertTrue(error.waitForExistence(timeout: 3))
            XCTAssertTrue(error.label.contains("this measurement changed or was removed while you were editing"))
            XCTAssertTrue(editor.exists)
            XCTAssertEqual(notes.value as? String, draft)
            let cancel = app.buttons["measurements.editor.cancel"]
            for _ in 0..<24 { if cancel.isHittable { break }; editor.swipeUp() }
            cancel.tap()
            let paper = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(paper.waitForExistence(timeout: 3))
            let discard = app.buttons["fruitPopup.paper.action.secondary"]
            for _ in 0..<24 { if discard.isHittable { break }; paper.swipeUp() }
            discard.tap()
            let closed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: editor)
            XCTAssertEqual(XCTWaiter.wait(for: [closed], timeout: 3), .completed)
            XCTAssertEqual(app.staticTexts["measurementQA.persistedResult"].label, "persisted result: 13.500")
            XCTAssertEqual(app.staticTexts["measurementQA.persistedNotes"].label, "persisted notes: QA newer independent record")
            XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: 1", "Reload must not rebase authority over a newer record")
            captureGame(app, name: "measurement-reload-keeps-conflict-language-\(language)")
            app.terminate()
        }
    }

    func testRhythmTranslationControlsPreserveOriginalMeasurementAndRestoreEducationalState() {
        for language in ["fr", "ar"] {
        for reduced in [false, true] {
            XCUIDevice.shared.orientation = .portrait
            let app = XCUIApplication()
            app.launchArguments = ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsRhythmQA",
                "-fruitfolioMeasurementsLanguage", language,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioMeasurementsReduceMotion"] }
            app.launch()
            let scroll = app.scrollViews["rhythmQA.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 8))
            func reveal(_ element: XCUIElement) {
                XCTAssertTrue(element.waitForExistence(timeout: 8))
                for _ in 0..<32 {
                    if element.isHittable { break }
                    if element.frame.midY < scroll.frame.midY { scroll.swipeDown() } else { scroll.swipeUp() }
                }
                XCTAssertTrue(element.isHittable)
            }
            func verifyOriginal() {
                let refresh = app.buttons["rhythmQA.refreshReadback"]
                XCTAssertTrue(refresh.isHittable); refresh.tap()
                XCTAssertEqual(app.staticTexts["measurementQA.persistedCount"].label, "persisted measurement count: 1")
                XCTAssertEqual(app.staticTexts["measurementQA.persistedResult"].label, "persisted result: 12.50")
                XCTAssertEqual(app.staticTexts["measurementQA.originalBytesIntact"].label, "original bytes intact: true")
                XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: 0")
            }
            let toggle = app.descendants(matching: .any).matching(identifier: "rhythm.adjustment.request").firstMatch
            reveal(toggle); toggle.tap()
            let unavailable = app.descendants(matching: .any).matching(identifier: "rhythm.adjustment.reviewedMethodUnavailable").firstMatch
            XCTAssertTrue(unavailable.waitForExistence(timeout: 5))
            verifyOriginal()
            let restore = app.buttons["rhythm.adjustment.restore"]
            reveal(restore); restore.tap()
            XCTAssertFalse(unavailable.exists)
            let open = app.buttons["rhythm.openMeasurements"]
            reveal(open); open.tap()
            let back = app.buttons["measurements.back"]
            XCTAssertTrue(back.waitForExistence(timeout: 5))
            for _ in 0..<20 { if back.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(back.isHittable); back.tap()
            XCTAssertTrue(toggle.waitForExistence(timeout: 5))
            verifyOriginal()
            captureGame(app, name: "rhythm-copy-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
    }

    func testMeasurementHormoneLibraryFixedHeadersRetainScientificSourcesAndRecords() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioMeasurementsLanguage", language,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            app.launch()
            let open = app.buttons["measurements.openLibrary"]
            XCTAssertTrue(open.waitForExistence(timeout: 5))
            for _ in 0..<24 { if open.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(open.isHittable); open.tap()
            let library = app.scrollViews["hormoneLibrary.scroll"]
            XCTAssertTrue(library.waitForExistence(timeout: 5))
            let heading = app.descendants(matching: .any).matching(identifier: "hormoneLibrary.heading").firstMatch
            XCTAssertTrue(heading.label.contains("hormone library"), "Paused source fallback is not verified French translation")
            let picker = app.descendants(matching: .any).matching(identifier: "hormoneLibrary.hormone").firstMatch
            XCTAssertTrue((picker.label + " " + (picker.value as? String ?? "")).contains("E2"))
            let firstSection = app.descendants(matching: .any).matching(identifier: "hormoneLibrary.section.functions").firstMatch
            XCTAssertTrue(firstSection.waitForExistence(timeout: 10), "Actual bundled research must load; an unavailable screen is not successful integration")
            for (key, source) in [("functions", "biological functions"), ("reproductiveRelevance", "reproductive relevance"),
                                  ("measurementLimitations", "measurement limitations"), ("testingContext", "testing context"),
                                  ("medicalGuidance", "medical guidance and interpretation")] {
                let section = app.descendants(matching: .any).matching(identifier: "hormoneLibrary.section." + key).firstMatch
                for _ in 0..<32 { if section.isHittable { break }; library.swipeUp() }
                XCTAssertTrue(section.exists)
                XCTAssertTrue(section.isHittable)
                XCTAssertTrue(section.label.contains(source))
                XCTAssertGreaterThan(section.frame.width, 0)
                XCTAssertGreaterThanOrEqual(section.frame.minX, library.frame.minX - 2)
                XCTAssertLessThanOrEqual(section.frame.maxX, library.frame.maxX + 2)
            }
            let estradiolArticle = app.otherElements["hormoneLibrary.article.estradiol"]
            XCTAssertTrue(estradiolArticle.exists)
            for _ in 0..<32 { if picker.isHittable { break }; library.swipeDown() }
            XCTAssertTrue(picker.isHittable); picker.tap()
            let amh = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Anti-Müllerian")).firstMatch
            XCTAssertTrue(amh.waitForExistence(timeout: 3)); amh.tap()
            let oldArticleGone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: estradiolArticle)
            XCTAssertEqual(XCTWaiter.wait(for: [oldArticleGone], timeout: 3), .completed)
            XCTAssertTrue(app.otherElements["hormoneLibrary.article.amh"].waitForExistence(timeout: 10))
            XCTAssertFalse(estradiolArticle.exists, "Only the selected hormone's real article may be exposed")
            XCTAssertTrue((picker.label + " " + (picker.value as? String ?? "")).contains("AMH"))
            let back = app.buttons["hormoneLibrary.back"]
            for _ in 0..<32 { if back.isHittable { break }; library.swipeDown() }
            XCTAssertTrue(back.isHittable); back.tap()
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "measurements.heading").firstMatch.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["measurementQA.persistedCount"].label, "persisted measurement count: 1")
            XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: 0")
            // Dismissing a native presentation must restore the root action owner.
            let reopen = app.buttons["measurements.openLibrary"]
            XCTAssertTrue(reopen.waitForExistence(timeout: 5))
            if !reopen.isHittable { app.swipeDown() }
            XCTAssertTrue(reopen.isHittable); reopen.tap()
            XCTAssertTrue(app.otherElements["hormoneLibrary.article.estradiol"].waitForExistence(timeout: 10))
            captureGame(app, name: "hormone-library-fixed-copy-source-fallback-\(language)")
            app.terminate()
        }
    }

    func testMeasurementLibraryRetryRecoversInjectedReadFailureUsingActualApprovedArticle() {
        for language in ["en", "fr"] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioMeasurementsQA", "-fruitfolioMeasurementsReduceMotion", "-fruitfolioHormoneLibraryRetryQA", "-fruitfolioMeasurementsLanguage", language]
            app.launch()
            let library = app.scrollViews["hormoneLibrary.scroll"]
            XCTAssertTrue(library.waitForExistence(timeout: 5))
            let retry = app.buttons["hormoneLibrary.retry"]
            XCTAssertTrue(retry.waitForExistence(timeout: 5))
            XCTAssertFalse(app.otherElements["hormoneLibrary.article.estradiol"].exists)
            for _ in 0..<32 { if retry.isHittable { break }; library.swipeUp() }
            XCTAssertTrue(retry.isHittable); retry.tap()
            XCTAssertTrue(app.otherElements["hormoneLibrary.article.estradiol"].waitForExistence(timeout: 10))
            XCTAssertFalse(retry.exists, "A prior request failure cannot cover a successfully loaded real article")
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "hormoneLibrary.section.functions").firstMatch.exists)
            XCTAssertEqual(app.staticTexts["measurementQA.persistedCount"].label, "persisted measurement count: 1")
            XCTAssertEqual(app.staticTexts["measurementQA.writeAttempts"].label, "write attempts: 0")
            XCTAssertEqual(app.staticTexts["measurementQA.originalBytesIntact"].label, "original bytes intact: true")
            captureGame(app, name: "library-injected-read-retry-source-fallback-\(language)")
            app.terminate()
        }
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
        let add = app.buttons["savedBook.addOwnPage"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let title = app.textFields["userPage.editor.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap(); title.typeText("my reminder")
        let body = app.textViews["userPage.editor.body"]
        body.tap(); body.typeText("my independently collected material")
        app.swipeUp()
        let save = app.buttons["userPage.editor.save"]
        for _ in 0..<10 { if save.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(save.isHittable)
        save.tap()
        XCTAssertTrue(app.descendants(matching: .any)["savedPage.userMaterialQualifier"].waitForExistence(timeout: 3))
    }

    func testLibraryCreateKeepsAuthoredNameNativeCountAndOneSoftPopPerAction() {
        for arabic in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioBookQA", "-fruitfolioBookEmptyFixture", "-fruitfolioBookQAPauseInference",
                "-fruitfolioBookAudioDiagnostics", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if arabic { app.launchArguments += ["-fruitfolioBookQAArabic"] }
            if reduced { app.launchArguments += ["-fruitfolioBookReduceMotion"] }
            app.launch()
            let build = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "build my first encyclopedia")).firstMatch
            XCTAssertTrue(build.waitForExistence(timeout: 5))
            for _ in 0..<16 { if build.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(build.isHittable); build.tap()
            let field = app.textFields["library.createBook.name"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            let submit = app.buttons["library.createBook.submit"]
            let scroll = app.scrollViews["fruitfolio.notebookPopup.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 3))
            for _ in 0..<18 { if submit.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(submit.isHittable); submit.tap()
            let error = app.descendants(matching: .any).matching(identifier: "library.createBook.error").firstMatch
            XCTAssertTrue(error.waitForExistence(timeout: 3))
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 2")
            for _ in 0..<18 { if field.isHittable { break }; scroll.swipeDown() }
            XCTAssertTrue(field.isHittable); field.tap(); field.typeText("QA private book")
            XCTAssertEqual(field.value as? String, "QA private book")
            let count = app.descendants(matching: .any).matching(identifier: "library.bookLabelGuidance.count").firstMatch
            XCTAssertTrue(count.waitForExistence(timeout: 3))
            XCTAssertTrue(count.label.contains(arabic ? "١٥" : "15"))
            XCTAssertTrue(count.label.contains(arabic ? "٤٨" : "48"))
            for _ in 0..<18 { if submit.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(submit.isHittable); submit.tap()
            XCTAssertFalse(submit.exists)
            let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "QA private book,")).firstMatch
            XCTAssertTrue(book.waitForExistence(timeout: 5))
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 3")
            let search = app.textFields["library.search.input"]
            XCTAssertTrue(search.waitForExistence(timeout: 3))
            for _ in 0..<20 { if search.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(search.isHittable); search.tap(); search.typeText("missing fixture")
            let noMatches = app.descendants(matching: .any).matching(identifier: "library.search.noMatches").firstMatch
            XCTAssertTrue(noMatches.waitForExistence(timeout: 3))
            let clear = app.buttons["library.search.clear"]
            XCTAssertTrue(clear.waitForExistence(timeout: 3)); XCTAssertTrue(clear.isHittable); clear.tap()
            XCTAssertFalse(noMatches.exists); XCTAssertTrue(book.exists)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 4")
            let sort = app.buttons["library.sort.toggle"]
            XCTAssertTrue(sort.waitForExistence(timeout: 3))
            for _ in 0..<20 { if sort.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(sort.isHittable); sort.tap()
            let alphabetical = app.buttons["library.sort.option.alphabetical"]
            let recent = app.buttons["library.sort.option.recentlyUpdated"]
            XCTAssertTrue(alphabetical.waitForExistence(timeout: 3))
            XCTAssertTrue(recent.isSelected); XCTAssertFalse(alphabetical.isSelected)
            for _ in 0..<20 { if alphabetical.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(alphabetical.isHittable); alphabetical.tap()
            XCTAssertFalse(alphabetical.exists)
            XCTAssertTrue(sort.label.contains("alphabetical"))
            XCTAssertTrue((sort.value as? String)?.contains("collapsed") == true)
            for _ in 0..<20 { if sort.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(sort.isHittable); sort.tap()
            XCTAssertTrue(alphabetical.waitForExistence(timeout: 3)); XCTAssertTrue(alphabetical.isSelected)
            XCTAssertFalse(recent.isSelected)
            for _ in 0..<20 { if sort.isHittable { break }; app.swipeDown() }
            XCTAssertTrue(sort.isHittable); sort.tap()
            XCTAssertFalse(alphabetical.exists)
            XCTAssertEqual(app.staticTexts["audioQA.softPopRequests"].label, "soft pop requests: 8")
            captureGame(app, name: "library-native-name-arabic-\(arabic)-reduced-\(reduced)")
            app.terminate()
        }
        }
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
        let dna = app.buttons["personalHealth.category.dna"]
        for _ in 0..<10 { if dna.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(dna.isHittable)
        dna.tap()
        let text = app.textViews["personalHealth.editor.text"]
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        text.tap(); text.typeText("only my explicitly supplied finding")
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(text.waitForExistence(timeout: 3))
        XCTAssertTrue((text.value as? String)?.contains("only my explicitly supplied finding") == true, "Unsent context draft survives backgrounding")
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
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
        XCTAssertTrue(measurement.waitForExistence(timeout: 3))
        XCTAssertEqual(measurement.value as? String, "1", "Backgrounding preserves the unsent selection")
        XCTAssertFalse(app.staticTexts["1 selected for one question"].exists, "Selection is not attachment")
        let done = app.buttons["attach selected context"]
        for _ in 0..<10 { if done.isHittable { break }; app.swipeUp() }
        done.tap()
        XCTAssertTrue(app.staticTexts["1 selected for one question"].waitForExistence(timeout: 3))
        app.buttons["remove attachments"].tap()
        XCTAssertFalse(app.staticTexts["1 selected for one question"].exists)
        attach.tap()
        XCTAssertTrue(measurement.waitForExistence(timeout: 3))
        XCTAssertEqual(measurement.value as? String, "0", "Removing attachments must not reselect patient records")
        XCTAssertTrue(app.staticTexts["12.50 ng/mL"].exists, "Original laboratory fields remain verbatim")
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

    func testAskFixedControlsKeepAuthoredQuestionAcrossHelpUnderPausedTranslation() {
        for arabic in [false, true] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioAskPaperQA", "-fruitfolioAskControlsQA", "-fruitfolioAskIllustrationQA",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if arabic { app.launchArguments += ["-fruitfolioAskControlsQAArabic"] }
            if reduced { app.launchArguments += ["-fruitfolioAskControlsQAReduceMotion"] }
            app.launch()
            let heading = app.descendants(matching: .any).matching(identifier: "ask.heading").firstMatch
            XCTAssertTrue(heading.waitForExistence(timeout: 10))
            XCTAssertTrue(heading.label.contains("ask the encyclopedia"))
            XCTAssertGreaterThanOrEqual(heading.frame.minX, app.frame.minX)
            XCTAssertLessThanOrEqual(heading.frame.maxX, app.frame.maxX)
            let input = app.descendants(matching: .any).matching(identifier: "ask.question.input").firstMatch
            XCTAssertTrue(input.waitForExistence(timeout: 5))
            input.tap()
            let authored = "My original question 12.50"
            input.typeText(authored)
            XCTAssertEqual(input.value as? String, authored)
            app.buttons["Ask help"].tap()
            let scroll = app.scrollViews["tapedWhitePopup.scroll"]
            XCTAssertTrue(scroll.waitForExistence(timeout: 3))
            let close = app.buttons["ask.help.close"]
            for _ in 0..<30 { if close.isHittable { break }; scroll.swipeUp() }
            XCTAssertTrue(close.isHittable)
            close.tap()
            XCTAssertTrue(input.waitForExistence(timeout: 3))
            XCTAssertEqual(input.value as? String, authored)
            XCUIDevice.shared.press(.home)
            app.activate()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
            XCTAssertTrue(input.waitForExistence(timeout: 3))
            XCTAssertEqual(input.value as? String, authored, "Unsent original draft survives inactivity")
            let conversation = app.scrollViews["ask.conversation"]
            let reveal = app.buttons["ask.illustration.reveal"]
            for _ in 0..<40 { if reveal.isHittable { break }; conversation.swipeUp() }
            XCTAssertTrue(reveal.isHittable)
            reveal.tap()
            let include = app.descendants(matching: .any).matching(identifier: "ask.illustration.include").firstMatch
            for _ in 0..<20 { if include.isHittable { break }; conversation.swipeUp() }
            XCTAssertTrue(include.isHittable)
            XCTAssertGreaterThanOrEqual(include.frame.height, 44)
            let initial = (include.value as? String)?.components(separatedBy: ". ").first
            XCTAssertNotNil(initial)
            include.tap()
            XCTAssertNotEqual((include.value as? String)?.components(separatedBy: ". ").first, initial)
            include.tap()
            XCTAssertEqual((include.value as? String)?.components(separatedBy: ". ").first, initial)
            let authority = app.staticTexts["askQA.fixtureLibraryAuthority"]
            XCTAssertTrue(authority.exists)
            let expectedAuthority = authority.label
            let imageSave = app.buttons["ask.illustration.saveOnly"]
            for _ in 0..<20 { if imageSave.isHittable { break }; conversation.swipeUp() }
            XCTAssertTrue(imageSave.isHittable)
            imageSave.tap()
            let dialogAuthority = app.staticTexts["askQA.dialogLibraryAuthority"]
            XCTAssertTrue(dialogAuthority.waitForExistence(timeout: 5))
            XCTAssertEqual(dialogAuthority.label, expectedAuthority, "Actual save dialog uses the fixture's private canonical store")
            let cancelSave = app.buttons["library.saveDestination.cancel"]
            for _ in 0..<30 { if cancelSave.isHittable { break }; app.swipeUp() }
            XCTAssertTrue(cancelSave.isHittable)
            cancelSave.tap()
            XCTAssertTrue(conversation.waitForExistence(timeout: 3))
            XCTAssertFalse(dialogAuthority.exists)
            XCTAssertEqual(input.value as? String, authored)
            captureGame(app, name: "ask-controls-paused-arabic-\(arabic)-reduced-\(reduced)")
            app.terminate()
        }
        }
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
                    XCUIDevice.shared.press(.home)
                    app.activate()
                    XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
                    XCTAssertTrue(editor.waitForExistence(timeout: 3))
                    XCTAssertTrue((editor.value as? String ?? "").contains("unsaved fixture edit"))
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

    func testUsernameLocaleCounterPreservesAuthoredDraftAndActualSavedName() {
        for language in ["en", "ar"] {
        for reduced in [false, true] {
            let app = XCUIApplication()
            app.launchArguments += ["-fruitfolioGameQA", "-fruitfolioGameQAScenario", "leaderboard",
                "-fruitfolioGameQALanguage", language, "-fruitfolioGameQAPauseInference",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
            if reduced { app.launchArguments += ["-fruitfolioGameReduceMotion"] }
            app.launch()
            let field = app.textFields["fruitBasket.publicUsername"]
            XCTAssertTrue(field.waitForExistence(timeout: 5))
            revealLeaderboardInput(field, app: app)
            field.tap(); field.typeText("sprout_one")
            XCTAssertEqual(field.value as? String, "sprout_one")
            let count = app.staticTexts["fruitBasket.usernameLength"]
            revealLeaderboardInput(count, app: app)
            XCTAssertEqual(count.label, language == "ar" ? "١٠ / ١٦" : "10 / 16")
            let confirm = app.descendants(matching: .any).matching(identifier: "fruitBasket.usernameConfirmation").firstMatch
            revealLeaderboardInput(confirm, app: app); confirm.tap()
            let save = app.buttons["fruitBasket.saveUsername"]
            revealLeaderboardInput(save, app: app)
            XCTAssertTrue(save.isEnabled); save.tap()
            XCTAssertEqual(app.staticTexts["fruitBasket.qa.savedUsername"].label, "saved username: sprout_one")
            captureGame(app, name: "username-native-count-\(language)-reduced-\(reduced)")
            app.terminate()
        }
        }
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
