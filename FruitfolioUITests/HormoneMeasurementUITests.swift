import XCTest

final class HormoneMeasurementUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "HormoneInformation_" + name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func button(_ app: XCUIApplication, prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", prefix)).firstMatch
    }

    private func openMeasurements(_ app: XCUIApplication) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = button(app, prefix: "settings")
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        settings.tap()
        let context = button(app, prefix: "my context")
        for _ in 0..<5 where !context.isHittable { app.swipeUp() }
        XCTAssertTrue(context.isHittable)
        context.tap()
        let hormones = button(app, prefix: "hormone information")
        XCTAssertTrue(hormones.waitForExistence(timeout: 8))
        hormones.tap()
        XCTAssertTrue(button(app, prefix: "add measurement").waitForExistence(timeout: 8))
    }

    func testCreateRestartEditAndDeleteMeasurement() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        app.launch()
        openMeasurements(app)
        capture(app, "HistoryBefore")
        button(app, prefix: "add measurement").tap()
        capture(app, "Entry")
        let result = app.textFields["numerical result"].exists
            ? app.textFields["numerical result"] : app.textViews["numerical result"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        result.typeText("9876.54321")
        let unitLabel = "unit (exactly as reported)"
        let unit = app.textFields[unitLabel].exists ? app.textFields[unitLabel] : app.textViews[unitLabel]
        unit.tap()
        let fixtureUnit = "fixture-" + String(UUID().uuidString.prefix(8)).lowercased()
        unit.typeText(fixtureUnit)
        let done = app.buttons["done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        let confirmDate = button(app, prefix: "confirm test date")
        for _ in 0..<6 where !confirmDate.isHittable { app.swipeUp() }
        XCTAssertTrue(confirmDate.isHittable)
        confirmDate.tap()
        let save = button(app, prefix: "save measurement")
        for _ in 0..<8 where !save.isHittable { app.swipeUp() }
        XCTAssertTrue(save.isEnabled && save.isHittable)
        save.tap()
        let displayed = "9876.54321 " + fixtureUnit
        XCTAssertTrue(app.staticTexts[displayed].waitForExistence(timeout: 8))
        capture(app, "Saved")
        app.terminate()
        app.launch()
        openMeasurements(app)
        XCTAssertTrue(app.staticTexts[displayed].waitForExistence(timeout: 8), "Measurement must persist through relaunch")
        capture(app, "AfterRestart")
        let row = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "hormone.measurement."))
            .containing(.staticText, identifier: displayed).firstMatch
        XCTAssertTrue(row.exists)
        let edit = row.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "open / edit measurement")).firstMatch
        for _ in 0..<5 where !edit.isHittable { app.swipeUp() }
        XCTAssertTrue(edit.isHittable)
        edit.tap()
        capture(app, "ReopenedEditor")
        let notesLabel = "notes (optional)"
        let notes = app.textFields[notesLabel].exists ? app.textFields[notesLabel] : app.textViews[notesLabel]
        for _ in 0..<8 where !notes.isHittable { app.swipeUp() }
        XCTAssertTrue(notes.isHittable)
        notes.tap()
        let fixtureNote = "edited " + fixtureUnit
        notes.typeText(fixtureNote)
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        let saveEdit = button(app, prefix: "save measurement")
        for _ in 0..<8 where !saveEdit.isHittable { app.swipeUp() }
        saveEdit.tap()
        XCTAssertTrue(app.staticTexts[fixtureNote].waitForExistence(timeout: 8))
        capture(app, "EditedAndSaved")
        let delete = row.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "delete measurement")).firstMatch
        for _ in 0..<5 where !delete.isHittable { app.swipeUp() }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        capture(app, "DeleteConfirmation")
        app.alerts.buttons["delete"].tap()
        XCTAssertFalse(app.staticTexts[displayed].waitForExistence(timeout: 2))
        capture(app, "AfterDeletion")
    }
}
