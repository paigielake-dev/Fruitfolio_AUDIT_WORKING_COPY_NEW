import XCTest

final class SimulatorSmokeEvidenceTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testRealIntroAndReachableHub() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1", "-FruitfolioIntroMode", "first"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15))
        let launch = XCTAttachment(screenshot: app.screenshot())
        launch.name = "Smoke_FirstObservedFrameAfterLaunch"
        launch.lifetime = .keepAlways
        add(launch)
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 14) { explore.tap() }
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        XCTAssertTrue(settings.isHittable, "Live Hub controls must be reachable after the intro")
        let hub = XCTAttachment(screenshot: app.screenshot())
        hub.name = "Smoke_ActualHub"
        hub.lifetime = .keepAlways
        add(hub)
    }
}
