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
        app.launchArguments += ["-fruitfolioDataManagementQA", "-fruitfolioDataReduceMotion",
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

    private func verifyModal(reduceMotion: Bool, rightToLeft: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioModalQA"]
        if reduceMotion {
            app.launchArguments += ["-fruitfolioModalReduceMotion",
                                    "-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        if rightToLeft { app.launchArguments += ["-fruitfolioDialogueRTL"] }
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
        XCTAssertGreaterThanOrEqual(close.frame.height, 44)
        XCTAssertGreaterThanOrEqual(close.frame.minX, scroll.frame.minX)
        XCTAssertLessThanOrEqual(close.frame.maxX, scroll.frame.maxX)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = (reduceMotion ? "modal-accessibility-reduce-motion" : "modal-scroll-actions")
            + (rightToLeft ? "-rtl" : "-ltr")
        attachment.lifetime = .keepAlways
        add(attachment)
        close.tap()
        XCTAssertTrue(app.buttons["modalQA.background"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["modalQA.background"].isHittable)
        XCTAssertFalse(scroll.exists)
    }
}
