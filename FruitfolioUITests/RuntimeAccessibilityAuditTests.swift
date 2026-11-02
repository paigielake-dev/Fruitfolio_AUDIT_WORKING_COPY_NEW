import XCTest

final class RuntimeAccessibilityAuditTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func audit(destination: String?, accessibilitySize: Bool = false) throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        if accessibilitySize {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
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
            if destination == "fruit basket" {
                let skip = app.buttons["skip tour"]
                if !skip.waitForExistence(timeout: 3) {
                    // Earlier game journeys may already have completed the
                    // first-use tour. Replay it through the real public UI so
                    // normal/largest audits cannot silently omit this state.
                    let instructions = app.buttons["how it works"]
                    XCTAssertTrue(instructions.waitForExistence(timeout: 8))
                    fruitfolioReachControl(app, instructions); instructions.tap()
                    let replay = app.buttons["show me the tour again"]
                    XCTAssertTrue(replay.waitForExistence(timeout: 8))
                    fruitfolioReachControl(app, replay); replay.tap()
                }
                XCTAssertTrue(skip.waitForExistence(timeout: 8), "The real requested/replayed tour must be audited, not silently omitted")
                if skip.exists {
                    XCTAssertTrue(app.alerts.firstMatch.exists, "The observed first-use tour is the actual foreground modal")
                    XCTAssertTrue(app.staticTexts["welcome to the Fruit Basket!"].exists)
                    XCTAssertFalse(back.exists, "The blurred background Back action must not remain accessible through the tour")
                    let tour = XCTAttachment(screenshot: app.screenshot())
                    tour.name = accessibilitySize ? "FruitBasket_Tour_AccessibilityXXXL" : "FruitBasket_Tour_Default"
                    tour.lifetime = .keepAlways; add(tour)
                    try fruitfolioStrictAccessibilityAudit(app)
                    fruitfolioReachControl(app, skip); skip.tap()
                    let rules = app.buttons["got it!"]
                    XCTAssertTrue(rules.waitForExistence(timeout: 8))
                    let page = XCTAttachment(screenshot: app.screenshot())
                    page.name = accessibilitySize ? "FruitBasket_Rules_AccessibilityXXXL" : "FruitBasket_Rules_Default"
                    page.lifetime = .keepAlways; add(page)
                    try fruitfolioStrictAccessibilityAudit(app)
                    fruitfolioReachControl(app, rules); rules.tap()
                }
            }
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
            fruitfolioReachControl(app, button)
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
    func testFruitBasketLargestDynamicTypeAccessibility() throws { try audit(destination: "fruit basket", accessibilitySize: true) }
    func testFAQAccessibility() throws { try audit(destination: "faq") }
    func testContactAccessibility() throws { try audit(destination: "contact") }
    func testSettingsAccessibility() throws { try audit(destination: "settings") }
    func testAccountAccessibility() throws { try audit(destination: "account") }
}
