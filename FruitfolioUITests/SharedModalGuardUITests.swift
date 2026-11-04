import XCTest

final class SharedModalGuardUITests: XCTestCase {
    func testFirstTourInvitationGuardsHubUntilExplicitDismissal() {
        verifyInvitation(largest: false)
    }

    func testLargestTourInvitationKeepsDismissalReachableAndRestoresHub() {
        verifyInvitation(largest: true)
    }

    private func verifyInvitation(largest: Bool) {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1", "-FruitfolioIntroMode", "first",
                                "-fruitfolio.tutorialCompleted", "NO"]
        if largest {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        let dismiss = app.buttons["I'll explore"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["hub.utility.settings"].exists,
                       "A modal invitation must hide the underlying Hub from accessibility navigation")
        fruitfolioReachControl(app, dismiss)
        XCTAssertTrue(dismiss.isHittable)
        XCTAssertTrue(app.frame.insetBy(dx: 0, dy: 16).contains(dismiss.frame),
                      "The full dismissal control must remain visible after scrolling")
        let open = XCTAttachment(screenshot: app.screenshot())
        open.name = largest ? "SharedModal_Invitation_Largest" : "SharedModal_Invitation_Default"
        open.lifetime = .keepAlways; add(open)
        dismiss.tap()
        let settings = app.buttons["hub.utility.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10))
        fruitfolioReachControl(app, settings)
        XCTAssertTrue(settings.isHittable)
        let closed = XCTAttachment(screenshot: app.screenshot())
        closed.name = largest ? "SharedModal_Dismissed_Largest" : "SharedModal_Dismissed_Default"
        closed.lifetime = .keepAlways; add(closed)
    }
}
