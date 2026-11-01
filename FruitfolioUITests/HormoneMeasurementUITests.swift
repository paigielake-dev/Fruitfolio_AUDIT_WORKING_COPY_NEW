import XCTest

final class HormoneMeasurementUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func scrollSettings(_ app: XCUIApplication, up: Bool) {
        let identifiers = ["hormoneRhythm.sheetScroll", "hormone.entryScroll", "hormone.measurementsScroll", "prompt27a.myContext", "settings.mainScroll"]
        let identified = identifiers.map { app.scrollViews[$0] }.first { $0.exists && $0.isHittable }
        let visible = app.scrollViews.allElementsBoundByIndex.last { $0.isHittable }
        let container = identified ?? visible ?? app
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.82 : 0.25))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.25 : 0.82))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
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
        for _ in 0..<5 where !context.isHittable { scrollSettings(app, up: true) }
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
        let done = app.buttons["hormone.keyboardDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        let confirmDate = button(app, prefix: "confirm test date")
        for _ in 0..<6 where !confirmDate.isHittable { scrollSettings(app, up: true) }
        XCTAssertTrue(confirmDate.isHittable)
        confirmDate.tap()
        let save = button(app, prefix: "save measurement")
        for _ in 0..<8 where !save.isHittable { scrollSettings(app, up: true) }
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
        let measurementID = row.identifier.replacingOccurrences(of: "hormone.measurement.", with: "")
        let edit = row.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "open / edit measurement")).firstMatch
        for _ in 0..<5 where !edit.isHittable { scrollSettings(app, up: true) }
        XCTAssertTrue(edit.isHittable)
        edit.tap()
        capture(app, "ReopenedEditor")
        let notesLabel = "notes (optional)"
        let notes = app.textFields[notesLabel].exists ? app.textFields[notesLabel] : app.textViews[notesLabel]
        for _ in 0..<8 where !notes.isHittable { scrollSettings(app, up: true) }
        XCTAssertTrue(notes.isHittable)
        notes.tap()
        let fixtureNote = "edited " + fixtureUnit
        notes.typeText(fixtureNote)
        XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        let saveEdit = button(app, prefix: "save measurement")
        for _ in 0..<8 where !saveEdit.isHittable { scrollSettings(app, up: true) }
        saveEdit.tap()
        XCTAssertTrue(app.staticTexts[fixtureNote].waitForExistence(timeout: 8))
        capture(app, "EditedAndSaved")
        let openRhythm = app.buttons["hormone.openRhythm"]
        for _ in 0..<8 where !openRhythm.isHittable { scrollSettings(app, up: false) }
        XCTAssertTrue(openRhythm.isHittable); openRhythm.tap()
        let rhythm = app.scrollViews["hormoneRhythm.sheetScroll"]
        XCTAssertTrue(rhythm.waitForExistence(timeout: 8))
        let mode = app.buttons["hormoneRhythm.mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 15)); mode.tap()
        app.buttons.matching(NSPredicate(format: "label == %@", "my measurements")).firstMatch.tap()
        let reference = rhythm.descendants(matching: .any)["hormoneRhythm.recorded." + measurementID]
        XCTAssertTrue(reference.waitForExistence(timeout: 8))
        XCTAssertTrue(reference.label.contains(displayed), "Reference mode must expose the actual entered value and unit")
        XCTAssertTrue(reference.label.contains(fixtureNote), "The actual user note must remain separate from educational curves")
        capture(app, "Rhythm_ActualMeasurementReferences")
        mode.tap()
        app.buttons.matching(NSPredicate(format: "label == %@", "adjusted rhythm")).firstMatch.tap()
        let insufficient = rhythm.staticTexts["hormoneRhythm.insufficientInformation"]
        XCTAssertTrue(insufficient.waitForExistence(timeout: 8))
        XCTAssertEqual(insufficient.label, "your measurement has been saved, but there isn’t enough information to adjust this illustration reliably. you can still explore the typical hormone rhythm and view your actual result in my measurements.")
        capture(app, "Rhythm_UnsupportedAdjustmentRetainsOriginal")
        let restore = rhythm.buttons["hormoneRhythm.restoreOriginal"]
        for _ in 0..<6 where !restore.isHittable { scrollSettings(app, up: true) }
        XCTAssertTrue(restore.isHittable); restore.tap()
        XCTAssertFalse(insufficient.exists)
        capture(app, "Rhythm_OriginalRestored")
        let rhythmBack = rhythm.buttons.matching(NSPredicate(format: "label ==[c] %@", "back")).firstMatch
        for _ in 0..<6 where !rhythmBack.isHittable { scrollSettings(app, up: false) }
        XCTAssertTrue(rhythmBack.isHittable); rhythmBack.tap()
        XCTAssertTrue(app.staticTexts[displayed].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts[fixtureNote].exists, "Opting in and restoring must leave the measurement unchanged")
        let delete = row.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "delete measurement")).firstMatch
        for _ in 0..<5 where !delete.isHittable { scrollSettings(app, up: true) }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        capture(app, "DeleteConfirmation")
        app.alerts.buttons["delete"].tap()
        XCTAssertFalse(app.staticTexts[displayed].waitForExistence(timeout: 2))
        capture(app, "AfterDeletion")
    }
}
