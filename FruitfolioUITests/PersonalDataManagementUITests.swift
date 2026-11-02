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
    private func openData(accessibilitySize: Bool = false, reducedMotion: Bool = false) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]
        // Foundation's real argument-domain preference is process-local; it
        // exercises the existing production setting without persisting test
        // state or adding an alternate application path.
        if reducedMotion { app.launchArguments += ["-fruitfolio.settings.reduceAnimationOverride", "YES"] }
        if accessibilitySize { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = button(app, "settings"); XCTAssertTrue(settings.waitForExistence(timeout: 15)); settings.tap()
        if reducedMotion {
            let control = app.switches["reduced motion"]
            fruitfolioReachControl(app, control)
            XCTAssertEqual(control.value as? String, "on", "Observe the real production preference in Settings before auditing its popup")
        }
        let data = button(app, "data"); reach(app, data); data.tap()
        XCTAssertTrue(app.buttons["data.prepareExport"].waitForExistence(timeout: 10))
        return app
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "PersonalData_" + name; a.lifetime = .keepAlways; add(a)
    }
    func testBulkHormoneDeletionHasAnExplicitModalGuardAndCancelReturnsWithoutDeleting() throws {
        try verifyBulkHormoneGuard(accessibilitySize: false)
    }
    func testBulkHormoneDeletionGuardAtLargestTypeKeepsTheCompleteActionsReachable() throws {
        try verifyBulkHormoneGuard(accessibilitySize: true)
    }
    func testReducedMotionBulkDeletionGuardRetainsReadableNamedActionsAndSafeCancellation() throws {
        try verifyBulkHormoneGuard(accessibilitySize: false, reducedMotion: true)
    }
    private func verifyBulkHormoneGuard(accessibilitySize: Bool, reducedMotion: Bool = false) throws {
        let app = openData(accessibilitySize: accessibilitySize, reducedMotion: reducedMotion); let erase = app.buttons["data.deleteHormones"]
        reach(app, erase); erase.tap()
        XCTAssertTrue(app.staticTexts["delete all hormone measurements?"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["data.prepareExport"].exists, "Blurred background controls must not remain exposed to accessibility while confirming deletion")
        capture(app, "BulkHormoneDeletionGuard")
        let cancel = button(app, "cancel")
        let pane = app.descendants(matching: .any).matching(identifier: "popup.writingArea").firstMatch
        XCTAssertTrue(pane.waitForExistence(timeout: 10))
        fruitfolioReachControl(app, cancel, container: pane)
        capture(app, "BulkHormoneDeletionVisibleActions")
        try fruitfolioStrictAccessibilityAudit(app)
        fruitfolioReachControl(app, cancel, container: pane)
        cancel.tap()
        XCTAssertFalse(app.staticTexts["delete all hormone measurements?"].exists)
        XCTAssertTrue(app.buttons["data.prepareExport"].exists)
        XCTAssertFalse(app.staticTexts["hormone measurements have been deleted from this device."].exists)
        capture(app, "DeletionCancelled")
    }
    private func openHormoneHistoryFromTheActualHub(_ app: XCUIApplication) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        func prefix(_ text: String) -> XCUIElement {
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", text)).firstMatch
        }
        for label in ["settings", "my context", "hormone information"] {
            let control = prefix(label)
            XCTAssertTrue(control.waitForExistence(timeout: 15))
            fruitfolioReachControl(app, control); control.tap()
        }
        XCTAssertTrue(prefix("add measurement").waitForExistence(timeout: 10))
    }

    func testCancellingBulkDeletionPreservesAnActuallyEnteredMeasurementAcrossApplicationRestart() throws {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        openHormoneHistoryFromTheActualHub(app)
        let add = button(app, "add measurement")
        fruitfolioReachControl(app, add); add.tap()
        let result = app.textFields["numerical result"].exists
            ? app.textFields["numerical result"] : app.textViews["numerical result"]
        XCTAssertTrue(result.waitForExistence(timeout: 8)); result.tap(); result.typeText("731.002")
        let unitTitle = "unit (exactly as reported)"
        let unit = app.textFields[unitTitle].exists ? app.textFields[unitTitle] : app.textViews[unitTitle]
        let fixtureUnit = "cancel-fixture-" + String(UUID().uuidString.prefix(8)).lowercased()
        unit.tap(); unit.typeText(fixtureUnit)
        let done = app.buttons["hormone.keyboardDone"]
        XCTAssertTrue(done.waitForExistence(timeout: 8)); done.tap()
        let confirmDate = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "confirm test date")).firstMatch
        fruitfolioReachControl(app, confirmDate); confirmDate.tap()
        let save = button(app, "save measurement")
        fruitfolioReachControl(app, save); XCTAssertTrue(save.isEnabled); save.tap()
        let displayed = "731.002 " + fixtureUnit
        XCTAssertTrue(app.staticTexts[displayed].waitForExistence(timeout: 10))
        capture(app, "ActualMeasurementBeforeBulkCancellation")
        app.terminate()
        let dataApp = openData()
        let erase = dataApp.buttons["data.deleteHormones"]
        fruitfolioReachControl(dataApp, erase); erase.tap()
        XCTAssertTrue(dataApp.staticTexts["delete all hormone measurements?"].waitForExistence(timeout: 10))
        let cancel = button(dataApp, "cancel")
        let pane = dataApp.descendants(matching: .any).matching(identifier: "popup.writingArea").firstMatch
        fruitfolioReachControl(dataApp, cancel, container: pane); cancel.tap()
        XCTAssertTrue(dataApp.buttons["data.prepareExport"].waitForExistence(timeout: 8))
        dataApp.terminate()
        app.launch(); openHormoneHistoryFromTheActualHub(app)
        let preserved = app.staticTexts[displayed]
        XCTAssertTrue(preserved.waitForExistence(timeout: 10), "A real record created through the actual entry UI must survive cancellation and process restart")
        fruitfolioReachControl(app, preserved)
        capture(app, "ActualMeasurementPreservedAfterBulkCancellationAndRestart")
        // Now confirm the separate destructive action through its real modal.
        // This is the disposable owned CI simulator, never a user's records.
        app.terminate()
        let deletionApp = openData()
        let guardedErase = deletionApp.buttons["data.deleteHormones"]
        fruitfolioReachControl(deletionApp, guardedErase); guardedErase.tap()
        XCTAssertTrue(deletionApp.staticTexts["delete all hormone measurements?"].waitForExistence(timeout: 10))
        let destructive = button(deletionApp, "delete hormone measurements")
        let writing = deletionApp.descendants(matching: .any).matching(identifier: "popup.writingArea").firstMatch
        fruitfolioReachControl(deletionApp, destructive, container: writing)
        capture(deletionApp, "ActualExplicitDestructiveActionBeforeConfirmation")
        destructive.tap()
        XCTAssertTrue(deletionApp.staticTexts["hormone measurements have been deleted from this device."].waitForExistence(timeout: 10))
        deletionApp.terminate()
        app.launch(); openHormoneHistoryFromTheActualHub(app)
        XCTAssertFalse(app.staticTexts[displayed].exists,
            "Only the explicit confirmed operation may remove the previously preserved real measurement")
        capture(app, "ActualConfirmedHormoneDeletionAfterRestart")
    }

    func testActualReadableExportOpensSystemDestinationAndCancellingDoesNotClaimAFileWasExported() {
        let app = openData(); let prepare = app.buttons["data.prepareExport"]
        reach(app, prepare); prepare.tap()
        let destination = app.descendants(matching: .any).matching(identifier: "Browse View (Picker)").firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 30), "The real system file-export destination must open after actual local snapshot preparation")
        XCTAssertTrue(app.buttons["Save"].exists, "Require the observed native save action; filename controls vary by picker state")
        capture(app, "ActualSystemExportDestination")
        // The actual Run80 recording shows On My iPhone with Back/More/Save.
        // Its unhittable Other labelled Cancel is a host proxy over More, not
        // a usable cancel button. Navigate the real observed BackButton first.
        func usableCancel() -> XCUIElement? {
            app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", "Cancel"))
                .allElementsBoundByIndex.first(where: { $0.exists && $0.isHittable })
        }
        if usableCancel() == nil {
            let browse = app.buttons["BackButton"]
            if browse.exists && browse.isHittable { browse.tap() }
        }
        if let cancel = usableCancel() {
            XCTAssertTrue(cancel.isHittable)
            cancel.tap()
        } else {
            // Native sheet dismissal is also a real user cancellation path.
            // Drag its observed top navigation area, not the empty file list.
            let start = destination.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.02))
            let end = destination.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.72))
            start.press(forDuration: 0.10, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.20)
        }
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: destination)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["data.prepareExport"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["your personal data JSON was exported. keep it somewhere private."].exists)
        capture(app, "SystemExportCancelled")
    }

    func testSystemExportActuallySavesAndReadsBackJSONBeforeReportingSuccess() {
        let app = openData(); let prepare = app.buttons["data.prepareExport"]
        reach(app, prepare); prepare.tap()
        let destination = app.descendants(matching: .any).matching(identifier: "Browse View (Picker)").firstMatch
        XCTAssertTrue(destination.waitForExistence(timeout: 30))
        let save = app.buttons["Save"]
        XCTAssertTrue(save.exists && save.isHittable)
        capture(app, "SystemExportBeforeActualSave")
        save.tap()
        // Some system states request the filename in a second sheet. Enter a
        // unique synthetic name only when that observed system field appears.
        let filename = app.textFields["DOCPicker.filenameTextField"]
        if filename.waitForExistence(timeout: 3) {
            filename.tap()
            if let current = filename.value as? String, !current.isEmpty {
                filename.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
            }
            filename.typeText("Fruitfolio-QA-" + UUID().uuidString + ".json")
            XCTAssertTrue(save.isHittable); save.tap()
        }
        let replace = app.buttons["Replace"]
        if replace.waitForExistence(timeout: 2) { replace.tap() }
        let success = app.staticTexts["your personal data JSON was exported. keep it somewhere private."]
        XCTAssertTrue(success.waitForExistence(timeout: 30),
            "Success is emitted only after reading the returned real file and checking exact JSON bytes")
        fruitfolioReachControl(app, success)
        capture(app, "ActualSavedJSONReadBackVerified")
        XCTAssertTrue(app.buttons["data.prepareExport"].exists)
    }

}
