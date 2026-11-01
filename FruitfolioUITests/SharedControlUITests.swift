import XCTest

final class SharedControlUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func contact(accessibilitySize: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        if accessibilitySize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let contact = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "contact")).firstMatch
        XCTAssertTrue(contact.waitForExistence(timeout: 15))
        contact.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Instagram")).firstMatch.waitForExistence(timeout: 10))
        return app
    }

    private func email(_ app: XCUIApplication) -> XCUIElement {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "fruitsoflifexo@gmail.com")).firstMatch
        let visible = app.frame.insetBy(dx: 0, dy: 60)
        for _ in 0..<8 where !button.isHittable || !visible.contains(button.frame) { app.swipeUp() }
        XCTAssertTrue(visible.contains(button.frame), "Audit and screenshot must include the entire painted control and its actual label")
        XCTAssertTrue(button.isHittable, "Long contact action must remain reachable")
        XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        return button
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testContactArtworkControlsAndReturnNavigation() throws {
        let app = contact(accessibilitySize: false)
        _ = email(app)
        capture(app, "SharedPill_Contact_Default")
        try fruitfolioStrictAccessibilityAudit(app)
        let back = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "back")).firstMatch
        for _ in 0..<5 where !back.isHittable { app.swipeDown() }
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch.waitForExistence(timeout: 10))
    }

    func testContactLongLabelGrowsAtAccessibilityTypeWithoutClipping() throws {
        var app = contact(accessibilitySize: false)
        let normalHeight = email(app).frame.height
        app.terminate()
        app = contact(accessibilitySize: true)
        let large = email(app)
        XCTAssertGreaterThan(large.frame.height, normalHeight,
                             "Dynamic Type must enlarge and wrap the actual control label")
        capture(app, "SharedPill_Contact_AccessibilityXXXL")
        try fruitfolioStrictAccessibilityAudit(app)
    }
}

extension SharedControlUITests {
    func testFAQExpandsAndCollapsesUsingApprovedWording() throws { try faq(accessibilitySize: false) }
    func testFAQAtAccessibilityTypeRetainsReadableAnswers() throws { try faq(accessibilitySize: true) }

    private func faq(accessibilitySize: Bool) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        if accessibilitySize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let destination = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "FAQ")).firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 15)); destination.tap()
        let question = app.buttons["faq.question.about-2"]
        XCTAssertTrue(question.waitForExistence(timeout: 10))
        let visible = app.frame.insetBy(dx: 0, dy: 60)
        for _ in 0..<8 where !question.isHittable || !visible.contains(question.frame) { app.swipeUp() }
        XCTAssertTrue(question.isHittable)
        XCTAssertEqual(question.value as? String, "collapsed")
        question.tap()
        let answer = app.staticTexts["faq.answer.about-2"]
        XCTAssertTrue(answer.waitForExistence(timeout: 8))
        XCTAssertEqual(answer.label, "no. Fruitfolio is educational and does not replace a qualified healthcare professional.")
        for _ in 0..<8 where !visible.contains(answer.frame) { app.swipeUp() }
        XCTAssertTrue(visible.contains(answer.frame))
        capture(app, accessibilitySize ? "FAQ_Expanded_AccessibilityXXXL" : "FAQ_Expanded_Default")
        try fruitfolioStrictAccessibilityAudit(app)
        for _ in 0..<8 where !question.isHittable { app.swipeDown() }
        question.tap()
        XCTAssertFalse(answer.exists)
        XCTAssertEqual(question.value as? String, "collapsed")
        capture(app, accessibilitySize ? "FAQ_Collapsed_AccessibilityXXXL" : "FAQ_Collapsed_Default")
    }
}
