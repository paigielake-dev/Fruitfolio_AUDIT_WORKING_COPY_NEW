import XCTest

final class Prompt1BModalAccessibilityTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testScrollablePopupIsolatesBackgroundAndRestoresItOnClose() {
        verifyModal(reduceMotion: false)
    }

    func testScrollablePopupAtAccessibilitySizeWithReduceMotion() {
        verifyModal(reduceMotion: true)
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
