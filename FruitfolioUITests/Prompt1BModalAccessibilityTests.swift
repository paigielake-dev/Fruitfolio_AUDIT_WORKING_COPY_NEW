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
                let progress = app.staticTexts["fruitBasket.classification.progress"]
                for _ in 0..<12 { if progress.isHittable { break }; scroll.swipeDown() }
                let expected = scenario == "star" ? "basket 0 of 10; star passes 1" : "basket 1 of 10; star passes 0"
                let updated = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expected), object: progress)
                XCTAssertEqual(XCTWaiter.wait(for: [updated], timeout: 5), .completed)
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
            let background = app.buttons["citationQA.background"]
            XCTAssertTrue(background.waitForExistence(timeout: 3))
            for _ in 0..<12 { if background.isHittable { break }; app.swipeDown() }
            background.tap()
            XCTAssertTrue(app.staticTexts["background actions: 1"].exists)
            app.terminate()
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
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioTourQA", "-fruitfolioModalReduceMotion",
                                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
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

    private func verifyModal(reduceMotion: Bool) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioModalQA"]
        if reduceMotion {
            app.launchArguments += ["-fruitfolioModalReduceMotion",
                                    "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let scroll = app.scrollViews["fruitPopup.scroll"]
        XCTAssertTrue(scroll.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["modalQA.background"].exists,
                       "Modal background must be absent from the accessibility tree.")
        let close = app.buttons["fruitPopup.action.primary"]
        for _ in 0..<30 {
            if close.exists && close.isHittable { break }
            scroll.swipeUp()
        }
        XCTAssertTrue(close.exists && close.isHittable,
                      "Long content must scroll to a reachable close action.")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = reduceMotion ? "modal-accessibility-reduce-motion" : "modal-scroll-actions"
        attachment.lifetime = .keepAlways
        add(attachment)
        close.tap()
        XCTAssertTrue(app.buttons["modalQA.background"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["modalQA.background"].isHittable)
        XCTAssertFalse(scroll.exists)
    }
}
