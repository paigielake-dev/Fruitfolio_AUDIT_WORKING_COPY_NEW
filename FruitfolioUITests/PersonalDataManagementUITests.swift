import XCTest

final class PersonalDataManagementUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func button(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", name)).firstMatch
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 10))
        let owner = app.scrollViews.containing(target.elementType, identifier: target.identifier.isEmpty ? target.label : target.identifier).firstMatch
        let scroll = owner.exists ? owner : app
        let visible = app.frame.insetBy(dx: 0, dy: 60).intersection(scroll.frame)
        for _ in 0..<16 where !target.isHittable || !visible.contains(target.frame) {
            let up = target.frame.midY > visible.midY
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.82 : 0.25))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.25 : 0.82)))
        }
        XCTAssertTrue(target.isHittable)
    }
    private func openData() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = button(app, "settings"); XCTAssertTrue(settings.waitForExistence(timeout: 15)); settings.tap()
        let data = button(app, "data"); reach(app, data); data.tap()
        XCTAssertTrue(app.buttons["data.prepareExport"].waitForExistence(timeout: 10))
        return app
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "PersonalData_" + name; a.lifetime = .keepAlways; add(a)
    }
    func testBulkHormoneDeletionHasAnExplicitModalGuardAndCancelReturnsWithoutDeleting() throws {
        let app = openData(); let erase = app.buttons["data.deleteHormones"]
        reach(app, erase); erase.tap()
        XCTAssertTrue(app.staticTexts["delete all hormone measurements?"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["data.prepareExport"].exists, "Blurred background controls must not remain exposed to accessibility while confirming deletion")
        capture(app, "BulkHormoneDeletionGuard")
        try fruitfolioStrictAccessibilityAudit(app)
        let cancel = button(app, "cancel"); reach(app, cancel); cancel.tap()
        XCTAssertFalse(app.staticTexts["delete all hormone measurements?"].exists)
        XCTAssertTrue(app.buttons["data.prepareExport"].exists)
        XCTAssertFalse(app.staticTexts["hormone measurements have been deleted from this device."].exists)
        capture(app, "DeletionCancelled")
    }
    func testActualReadableExportOpensSystemDestinationAndCancellingDoesNotClaimAFileWasExported() {
        let app = openData(); let prepare = app.buttons["data.prepareExport"]
        reach(app, prepare); prepare.tap()
        let cancel = button(app, "cancel")
        XCTAssertTrue(cancel.waitForExistence(timeout: 30), "The real system file-export destination must open after actual local snapshot preparation")
        capture(app, "ActualSystemExportDestination")
        cancel.tap()
        XCTAssertTrue(app.buttons["data.prepareExport"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["your personal data JSON was exported. keep it somewhere private."].exists)
        capture(app, "SystemExportCancelled")
    }
}
