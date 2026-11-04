import XCTest

final class LifeBridgeInformationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func button(_ app: XCUIApplication, _ title: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "LifeBridge_" + name; a.lifetime = .keepAlways; add(a)
    }
    private func launch() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        XCTAssertTrue(button(app, "faq").waitForExistence(timeout: 15))
        return app
    }
    func testFAQDiscoveryShowsLocalFallbackAndExternalLinkRequiresConfirmation() {
        let app = launch(); button(app, "faq").tap()
        let entry = app.buttons["faq.lifebridge"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10)); entry.tap()
        let status = app.staticTexts["lifebridge.contentAvailability"]
        XCTAssertTrue(status.waitForExistence(timeout: 10))
        XCTAssertTrue(status.label.contains("have not been verified")); capture(app, "LocalAvailability")
        let official = app.buttons["lifebridge.link.official"]
        for _ in 0..<12 where !official.isHittable { app.swipeUp() }
        XCTAssertTrue(official.isHittable); official.tap()
        XCTAssertTrue(app.staticTexts["leave Fruitfolio?"].waitForExistence(timeout: 8)); capture(app, "IntentionalExternalNotice")
        let stay = button(app, "stay in Fruitfolio"); XCTAssertTrue(stay.waitForExistence(timeout: 8)); stay.tap()
        XCTAssertTrue(official.waitForExistence(timeout: 8))
        for _ in 0..<14 where !button(app, "back").isHittable { app.swipeDown() }
        button(app, "back").tap()
        XCTAssertTrue(app.buttons["faq.lifebridge"].waitForExistence(timeout: 10))
        button(app, "back").tap()
        XCTAssertTrue(button(app, "settings").waitForExistence(timeout: 10))
    }
    func testExplicitAskQueryMakesDirectoryDiscoverableAndReturningPreservesTheDraft() {
        let app = launch(); app.buttons["hub.action.Ask the Encyclopedia"].tap()
        let input = app.textFields["ask.questionInput"]
        XCTAssertTrue(input.waitForExistence(timeout: 10)); input.tap(); input.typeText("LifeBridge surrogacy support")
        let entry = app.buttons["ask.lifebridge"]
        XCTAssertTrue(entry.waitForExistence(timeout: 10)); entry.tap()
        XCTAssertTrue(app.staticTexts["lifebridge.contentAvailability"].waitForExistence(timeout: 10)); capture(app, "AskDiscovery")
        button(app, "back").tap()
        XCTAssertTrue(input.waitForExistence(timeout: 10)); XCTAssertEqual(input.value as? String, "LifeBridge surrogacy support")
        capture(app, "AskDraftRetained")
    }
}
