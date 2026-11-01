import XCTest

final class UserAuthoredPageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func button(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        for _ in 0..<10 where !target.isHittable { app.swipeUp() }
        XCTAssertTrue(target.isHittable)
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    private func library(_ app: XCUIApplication) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let library = button(app, "my encyclopedias")
        XCTAssertTrue(library.waitForExistence(timeout: 15)); library.tap()
    }
    func testCreateReopenEditAndDiscardUserPageThroughActualLibrary() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        library(app)
        let name = "My QA " + String(UUID().uuidString.prefix(6))
        let create = button(app, "build my first encyclopedia")
        if create.exists { reach(app, create); create.tap() }
        else { let another = button(app, "add another little encyclopedia"); reach(app, another); another.tap() }
        let title = app.textFields["encyclopedia name"]
        XCTAssertTrue(title.waitForExistence(timeout: 8)); title.tap(); title.typeText(name + "\n")
        let createBook = button(app, "create encyclopedia"); reach(app, createBook); createBook.tap()
        let book = button(app, name); XCTAssertTrue(book.waitForExistence(timeout: 10)); reach(app, book); book.tap()
        let chapter = button(app, "saved pages"); XCTAssertTrue(chapter.waitForExistence(timeout: 10)); chapter.tap()
        let add = button(app, "add my own page"); reach(app, add); add.tap()
        let pageTitle = app.textFields["userPage.title"]
        XCTAssertTrue(pageTitle.waitForExistence(timeout: 8)); pageTitle.tap(); pageTitle.typeText("My independent reminder")
        let content = app.textViews["userPage.content"]
        XCTAssertTrue(content.exists); content.tap(); content.typeText("my own writing stays separate from research.")
        button(app, "done").tap()
        let save = button(app, "save changes"); reach(app, save); save.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        capture(app, "UserPage_Saved")
        app.terminate(); app.launch(); library(app)
        let savedBook = button(app, name); reach(app, savedBook); savedBook.tap()
        let reopenedChapter = button(app, "saved pages")
        XCTAssertTrue(reopenedChapter.waitForExistence(timeout: 10)); reach(app, reopenedChapter); reopenedChapter.tap()
        let savedPage = button(app, "My independent reminder")
        XCTAssertTrue(savedPage.waitForExistence(timeout: 10)); reach(app, savedPage); savedPage.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        capture(app, "UserPage_AfterRelaunch")
        let edit = button(app, "edit my page"); reach(app, edit); edit.tap()
        let editor = app.textViews["userPage.content"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8)); editor.tap(); editor.typeText(" unsaved addition")
        button(app, "done").tap()
        let discard = button(app, "discard changes"); reach(app, discard); discard.tap()
        let confirm = button(app, "discard changes")
        XCTAssertTrue(confirm.waitForExistence(timeout: 6)); reach(app, confirm); confirm.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "unsaved addition")).firstMatch.exists)
        capture(app, "UserPage_DiscardPreservedOriginal")
    }
}
