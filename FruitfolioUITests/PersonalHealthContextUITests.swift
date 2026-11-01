import XCTest

final class PersonalHealthContextUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func button(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", name)).firstMatch
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 10))
        let scroll = app.scrollViews.allElementsBoundByIndex.last { $0.isHittable }
        let owner = scroll ?? app
        let visible = owner.frame.intersection(app.frame.insetBy(dx: 0, dy: 60))
        for _ in 0..<12 where !target.isHittable || !visible.contains(target.frame) {
            let up = target.frame.midY > visible.midY
            owner.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.82 : 0.25))
                .press(forDuration: 0.05, thenDragTo: owner.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.25 : 0.82)))
        }
        XCTAssertTrue(target.isHittable)
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "PersonalHealth_" + name; a.lifetime = .keepAlways; add(a)
    }
    private func open(_ app: XCUIApplication, personalHealth: Bool = true) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = button(app, "settings"); XCTAssertTrue(settings.waitForExistence(timeout: 15)); settings.tap()
        let context = button(app, "my context"); reach(app, context); context.tap()
        let profile = app.buttons[personalHealth ? "context.openPersonalHealth" : "context.editCycleSetup"]
        XCTAssertTrue(profile.waitForExistence(timeout: 10)); profile.tap()
        XCTAssertTrue(app.buttons[personalHealth ? "healthContext.field.heart" : "cycleSetup.edit.latestPeriod"].waitForExistence(timeout: 10))
    }
    func testOptionalReportedHistorySavesReopensAfterRestartAndDeletesWithoutAffectingOtherContext() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        open(app); capture(app, "Categories")
        let heart = app.buttons["healthContext.field.heart"]; heart.tap()
        let entry = app.descendants(matching: .any).matching(identifier: "healthContext.entryText").firstMatch
        XCTAssertTrue(entry.waitForExistence(timeout: 8)); entry.tap()
        let note = "my reported history " + UUID().uuidString
        entry.typeText(note)
        let done = button(app, "done"); XCTAssertTrue(done.waitForExistence(timeout: 5)); done.tap()
        let save = button(app, "save context"); reach(app, save); save.tap()
        XCTAssertEqual(heart.value as? String, "your reported context • saved")
        capture(app, "Saved")
        app.terminate(); app.launch(); open(app); heart.tap()
        XCTAssertTrue(entry.waitForExistence(timeout: 8)); XCTAssertEqual(entry.value as? String, note)
        capture(app, "PersistedOriginalText")
        let remove = button(app, "remove this context"); reach(app, remove); remove.tap()
        XCTAssertTrue(app.alerts.buttons["remove"].waitForExistence(timeout: 5)); app.alerts.buttons["remove"].tap()
        XCTAssertEqual(heart.value as? String, "optional • removed")
        heart.tap(); XCTAssertTrue(entry.waitForExistence(timeout: 8))
        XCTAssertNotEqual(entry.value as? String, note)
        capture(app, "RemovedTextAbsent")
        let skip = button(app, "skip / cancel"); reach(app, skip); skip.tap()
    }
    func testOneCycleSetupAnswerCanBeEditedAndRemovedWithoutRepeatingOnboarding() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        open(app, personalHealth: false)
        let section = app.buttons["cycleSetup.edit.subjectiveRegularity"]
        reach(app, section); section.tap()
        let choice = button(app, "they vary a little")
        XCTAssertTrue(choice.waitForExistence(timeout: 8)); choice.tap()
        XCTAssertEqual(choice.value as? String, "selected")
        capture(app, "CycleSetup_ExistingQuestionEdited")
        let next = button(app, "continue"); reach(app, next); next.tap()
        XCTAssertTrue(section.waitForExistence(timeout: 10), "Editing one answer must return to the section list, not require every onboarding step")
        app.terminate(); app.launch(); open(app, personalHealth: false)
        reach(app, section); section.tap()
        XCTAssertTrue(choice.waitForExistence(timeout: 8)); XCTAssertEqual(choice.value as? String, "selected")
        capture(app, "CycleSetup_AnswerPersistedAfterRestart")
        let skip = button(app, "skip"); reach(app, skip); skip.tap()
        XCTAssertTrue(section.waitForExistence(timeout: 10)); reach(app, section); section.tap()
        XCTAssertTrue(choice.waitForExistence(timeout: 8)); XCTAssertEqual(choice.value as? String, "not selected")
        capture(app, "CycleSetup_RemovedAnswerStaysUnknown")
    }

}
