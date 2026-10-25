import XCTest

final class FruitfolioUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 8))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Fruitfolio launch"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
