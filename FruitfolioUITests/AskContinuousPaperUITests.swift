import XCTest

final class AskContinuousPaperUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }

    func testTwoActualGroundedAnswersStayOnOneCenteredScrollablePaperAndClearOnExit() throws {
        try verifyContinuousConversation(largest: false)
    }

    func testLargestTextTwoActualAnswersRemainReachableOnTheSamePaper() throws {
        try verifyContinuousConversation(largest: true)
    }

    private func verifyContinuousConversation(largest: Bool) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let open = app.buttons["hub.action.Ask the Encyclopedia"]
        XCTAssertTrue(open.waitForExistence(timeout: 15)); open.tap()
        let input = app.textFields["ask.questionInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10))
        let first = "How does morning sunlight affect the body clock?"
        let second = "Why can bright light in the evening affect sleep?"
        let send = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Send question")).firstMatch
        func submit(_ question: String) {
            input.tap(); input.typeText(question)
            XCTAssertTrue(send.isEnabled && send.isHittable); send.tap()
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "ask.completedAnswer").firstMatch.waitForExistence(timeout: 180))
            XCTAssertGreaterThan(app.descendants(matching: .any).matching(identifier: "ask.completedAnswer").firstMatch.label.count, 30)
        }
        submit(first)
        capture(app, "AskContinuous_FirstGroundedAnswer_largest_\(largest)")
        submit(second)
        let latest = app.descendants(matching: .any).matching(identifier: "ask.completedAnswer").firstMatch
        let originalLatest = latest.label
        let scroll = app.scrollViews["ask.conversationScroll"]
        XCTAssertTrue(scroll.exists)
        let paper = app.descendants(matching: .any).matching(identifier: "ask.journalContent")
        XCTAssertEqual(paper.count, 1, "One real conversation container owns all question/answer content")
        XCTAssertEqual(paper.firstMatch.frame.midX, app.frame.midX, accuracy: 2,
                       "Paper must remain horizontally centered at the actual device size")
        capture(app, "AskContinuous_SecondGroundedAnswerAndSinglePaper_largest_\(largest)")
        let priorQuestion = app.staticTexts[first]
        reachJournalElement(app, scroll: scroll, target: priorQuestion, towardEarlier: true)
        XCTAssertTrue(priorQuestion.exists && priorQuestion.isHittable,
                      "Earlier questions remain reachable by actual backward scrolling")
        capture(app, "AskContinuous_BackwardScrollToEarlierAnswer_largest_\(largest)")
        let currentQuestion = app.staticTexts[second]
        reachJournalElement(app, scroll: scroll, target: currentQuestion, towardEarlier: false)
        XCTAssertTrue(currentQuestion.exists && currentQuestion.isHittable)
        reachJournalElement(app, scroll: scroll, target: latest, towardEarlier: false)
        XCTAssertEqual(latest.label, originalLatest, "Bidirectional scrolling must not regenerate or alter answers")
        scroll.swipeUp(); scroll.swipeUp()
        capture(app, "AskContinuous_FinalContentAndOverscrollPaper_largest_\(largest)")
        let source = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "ask.source.founder_")).firstMatch
        for _ in 0..<12 where !source.exists { scroll.swipeUp() }
        XCTAssertTrue(source.exists, "Original approved-document citations remain available")
        let back = app.buttons["ask.back"]
        XCTAssertTrue(back.isHittable); back.tap()
        XCTAssertTrue(open.waitForExistence(timeout: 10)); open.tap()
        XCTAssertFalse(app.staticTexts[first].exists)
        XCTAssertFalse(app.staticTexts[second].exists)
        XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "ask.completedAnswer").firstMatch.exists)
        capture(app, "AskContinuous_NewVisitClearsOnlyUnsavedSession_largest_\(largest)")
    }
    private func reachJournalElement(_ app: XCUIApplication, scroll: XCUIElement,
                                     target: XCUIElement, towardEarlier: Bool) {
        // Actual iOS26 evidence showed a selectable UITextView changes its
        // reported automation class after scrolling. Query its stable identity,
        // not a guessed class, and pan on the blank paper margin so selection
        // gestures and the right-hand scroll indicator cannot consume the pan.
        for attempt in 0..<80 {
            if target.exists && target.isHittable { return }
            print("ASK_JOURNAL_PAN attempt=\(attempt) earlier=\(towardEarlier) exists=\(target.exists) viewport=\(scroll.frame)")
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.03, dy: towardEarlier ? 0.22 : 0.80))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset:
                    CGVector(dx: 0.03, dy: towardEarlier ? 0.80 : 0.22)))
        }
        capture(app, "AskContinuous_StrictReachFailure_earlier_\(towardEarlier)")
        XCTAssertTrue(target.exists && target.isHittable,
                      "The complete earlier/current content must actually be reachable; no visibility assertion is weakened")
    }

}
