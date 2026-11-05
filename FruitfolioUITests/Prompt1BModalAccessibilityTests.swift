import XCTest

final class Prompt1BModalAccessibilityTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testScrollablePopupIsolatesBackgroundAndRestoresItOnClose() {
        verifyModal(reduceMotion: false)
    }

    func testScrollablePopupAtAccessibilitySizeWithReduceMotion() {
        verifyModal(reduceMotion: true)
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
