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
        for _ in 0..<5 where !button.isHittable { app.swipeUp() }
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
        try app.performAccessibilityAudit()
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
        try app.performAccessibilityAudit()
    }
}
