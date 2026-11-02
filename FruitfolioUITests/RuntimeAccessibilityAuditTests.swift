import XCTest

final class RuntimeAccessibilityAuditTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func audit(destination: String?) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let targetLabel = destination ?? "settings"
        let predicate = destination == "account"
            ? NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", "account", "sign in")
            : NSPredicate(format: "label ==[c] %@ OR (%@ == %@ AND label ==[c] %@)", targetLabel, targetLabel, "account", "sign in")
        let target = app.buttons.matching(predicate).firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 20), "Required Hub destination not found: \(targetLabel)")
        XCTAssertTrue(target.isHittable, "Hub destination must be reachable: \(targetLabel)")
        if destination != nil {
            target.tap()
            let back = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "back")).firstMatch
            XCTAssertTrue(back.waitForExistence(timeout: 12), "Audit must run on the requested destination, not an unchanged Hub")
        }
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Accessibility_" + (destination ?? "Hub")
        image.lifetime = .keepAlways
        add(image)
        // Real XCTest audit. The diagnostic handler returns false for every issue.
        try fruitfolioStrictAccessibilityAudit(app)
    }

    func testHubLargestDynamicTypeKeepsAllDestinationsReachable() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1",
                                "-UIPreferredContentSizeCategoryName",
                                "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        XCTAssertTrue(app.staticTexts["Fruitfolio"].waitForExistence(timeout: 20))
        for label in ["ask the encyclopedia", "my encyclopedias", "build your own guide",
                      "cycle tracker", "fruit basket", "faq", "settings", "contact"] {
            let button = app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch
            for _ in 0..<8 {
                if button.exists && button.isHittable { break }
                app.swipeUp()
            }
            XCTAssertTrue(button.exists && button.isHittable,
                          "Largest Dynamic Type must keep the Hub destination reachable: \(label)")
        }
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = "Hub_LargestDynamicType_ScrolledUtilities"
        image.lifetime = .keepAlways
        add(image)
        app.swipeDown(); app.swipeDown(); app.swipeDown()
        let header = XCTAttachment(screenshot: app.screenshot())
        header.name = "Hub_LargestDynamicType_Branding"
        header.lifetime = .keepAlways
        add(header)
        try fruitfolioStrictAccessibilityAudit(app)
    }

    func testHubAccessibility() throws { try audit(destination: nil) }
    func testAskOpeningAccessibility() throws { try audit(destination: "ask the encyclopedia") }
    func testLibraryOpeningAccessibility() throws { try audit(destination: "my encyclopedias") }
    func testGuideOpeningAccessibility() throws { try audit(destination: "build your own guide") }
    func testCycleOpeningAccessibility() throws { try audit(destination: "cycle tracker") }
    func testFruitBasketOpeningAccessibility() throws { try audit(destination: "fruit basket") }
    func testFAQAccessibility() throws { try audit(destination: "faq") }
    func testContactAccessibility() throws { try audit(destination: "contact") }
    func testSettingsAccessibility() throws { try audit(destination: "settings") }
    func testAccountAccessibility() throws { try audit(destination: "account") }
}
