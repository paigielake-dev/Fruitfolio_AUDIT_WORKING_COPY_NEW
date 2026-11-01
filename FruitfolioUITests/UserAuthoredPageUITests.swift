import XCTest

final class UserAuthoredPageUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func button(_ app: XCUIApplication, _ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 8))
        let identifier = target.identifier.isEmpty ? target.label : target.identifier
        let scroll = app.scrollViews.containing(target.elementType, identifier: identifier).firstMatch
        let container = scroll.exists ? scroll : app
        let visible = app.frame.insetBy(dx: 0, dy: 60).intersection(container.frame)
        for _ in 0..<14 where !target.isHittable || !visible.contains(target.frame) {
            let downward = target.frame.midY < visible.minY
            // Drag within the owning scroll view's clear side margin. A full-app
            // swipe can land in the nested text editor or outside a paper popup.
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: downward ? 0.25 : 0.80))
            let finish = container.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: downward ? 0.80 : 0.25))
            start.press(forDuration: 0.05, thenDragTo: finish)
        }
        if !target.isHittable || !visible.contains(target.frame) {
            capture(app, "Unreachable_" + target.label)
            let tree = XCTAttachment(string: app.debugDescription); tree.name = "UnreachableControlHierarchy"; tree.lifetime = .keepAlways; add(tree)
        }
        XCTAssertTrue(visible.contains(target.frame))
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
        let another = button(app, "add another little encyclopedia")
        XCTAssertTrue(create.waitForExistence(timeout: 10) || another.exists, "Wait for the actual library before choosing its empty/populated flow")
        if create.exists { reach(app, create); create.tap() }
        else { reach(app, another); another.tap() }
        let title = app.textFields["encyclopedia name"]
        XCTAssertTrue(title.waitForExistence(timeout: 8)); title.tap(); title.typeText(name + "\n")
        let createBook = button(app, "create encyclopedia"); reach(app, createBook); createBook.tap()
        let book = button(app, name); XCTAssertTrue(book.waitForExistence(timeout: 10)); reach(app, book); book.tap()
        let chapter = button(app, "saved pages"); XCTAssertTrue(chapter.waitForExistence(timeout: 10)); chapter.tap()
        capture(app, "Library_InsideBook_ChapterExpanded")
        let add = button(app, "add my own page"); reach(app, add); add.tap()
        let pageTitle = app.textFields["userPage.title"]
        XCTAssertTrue(pageTitle.waitForExistence(timeout: 8)); pageTitle.tap(); pageTitle.typeText("My independent reminder")
        let content = app.textViews["userPage.content"]
        XCTAssertTrue(content.exists); content.tap(); content.typeText("my own writing stays separate from research.")
        button(app, "done").tap()
        let addImage = button(app, "add image"); reach(app, addImage); addImage.tap()
        // The observed iOS 26 system picker exposes photo tiles as Images,
        // not collection-view Cells. Keep selection scoped to its real grid.
        let photo = app.scrollViews["photosView_content_scroll_view"].images
            .matching(identifier: "PXGGridLayout-Info").firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 15), "Select a real photo from the system picker; simulator photo fixture must be installed")
        XCTAssertTrue(app.frame.contains(photo.frame), "The actual selected photo must be visible inside the picker")
        XCTAssertGreaterThan(photo.frame.width, 40)
        capture(app, "UserPage_ActualSystemPhotoPicker")
        // iOS26 PhotosUI exposes informational Image nodes without an AX hit
        // point (-1,-1), despite a visible, selectable native photo tile.
        // Tap its observed center; actual import/persistence assertions below
        // still have to succeed through the real system picker and app code.
        photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        let imported = app.images["my imported image"]
        XCTAssertTrue(imported.waitForExistence(timeout: 15), "Actual photo import must finish before saving")
        reach(app, imported); capture(app, "UserPage_ActualPhotoImported")
        let save = button(app, "save changes"); reach(app, save); save.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        capture(app, "UserPage_Saved")
        app.terminate(); app.launch(); library(app)
        let savedBook = button(app, name); reach(app, savedBook); savedBook.tap()
        let reopenedChapter = button(app, "saved pages")
        XCTAssertTrue(reopenedChapter.waitForExistence(timeout: 10)); reach(app, reopenedChapter);
        if (reopenedChapter.value as? String) != "expanded" { reopenedChapter.tap() }
        let savedPage = button(app, "My independent reminder")
        XCTAssertTrue(savedPage.waitForExistence(timeout: 10)); reach(app, savedPage); savedPage.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        let persistedImage = app.images["user imported image"]
        XCTAssertTrue(persistedImage.waitForExistence(timeout: 8), "Imported image bytes must survive the actual application restart")
        reach(app, persistedImage)
        capture(app, "UserPage_AfterRelaunch")
        let edit = button(app, "edit my page"); reach(app, edit); edit.tap()
        let editor = app.textViews["userPage.content"]
        XCTAssertTrue(editor.waitForExistence(timeout: 8)); editor.tap(); editor.typeText(" unsaved addition")
        XCTAssertTrue((editor.value as? String)?.contains(" unsaved addition") == true,
            "Typing must preserve the exact entered character order before discard")
        button(app, "done").tap()
        let discard = button(app, "discard changes"); reach(app, discard); discard.tap()
        let confirm = button(app, "discard changes")
        XCTAssertTrue(confirm.waitForExistence(timeout: 6)); reach(app, confirm); confirm.tap()
        XCTAssertTrue(app.staticTexts["my own writing stays separate from research."].waitForExistence(timeout: 8))
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "unsaved addition")).firstMatch.exists)
        capture(app, "UserPage_DiscardPreservedOriginal")
        let editAgain = button(app, "edit my page"); reach(app, editAgain); editAgain.tap()
        let savedEditor = app.textViews["userPage.content"]
        XCTAssertTrue(savedEditor.waitForExistence(timeout: 8)); savedEditor.tap()
        savedEditor.typeText(" saved addition")
        let editedText = savedEditor.value as? String ?? ""
        XCTAssertTrue(editedText.contains(" saved addition"))
        XCTAssertEqual(editedText.replacingOccurrences(of: " saved addition", with: ""),
            "my own writing stays separate from research.", "Typing must preserve all existing writing")
        button(app, "done").tap()
        let saveEdit = button(app, "save changes"); reach(app, saveEdit); saveEdit.tap()
        XCTAssertTrue(app.staticTexts[editedText].waitForExistence(timeout: 8))
        capture(app, "UserPage_EditedAndSaved")
        app.terminate(); app.launch(); library(app)
        let updatedBook = button(app, name); reach(app, updatedBook); updatedBook.tap()
        let updatedChapter = button(app, "saved pages"); reach(app, updatedChapter)
        if (updatedChapter.value as? String) != "expanded" { updatedChapter.tap() }
        let updatedPage = button(app, "My independent reminder"); reach(app, updatedPage); updatedPage.tap()
        XCTAssertTrue(app.staticTexts[editedText].waitForExistence(timeout: 8), "Saved edits must survive another actual restart")
        XCTAssertTrue(app.images["user imported image"].exists, "Editing text must retain the independently stored imported image")
        capture(app, "UserPage_EditedAfterRestart")
        let remove = button(app, "delete saved page"); reach(app, remove); remove.tap()
        let keep = button(app, "keep page"); XCTAssertTrue(keep.waitForExistence(timeout: 8)); reach(app, keep); keep.tap()
        XCTAssertTrue(app.staticTexts[editedText].exists)
        reach(app, remove); remove.tap()
        let delete = app.buttons.matching(NSPredicate(format: "label == %@", "delete page")).firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 8)); reach(app, delete); delete.tap()
        XCTAssertFalse(app.staticTexts[editedText].waitForExistence(timeout: 3))
        capture(app, "UserPage_Deleted")
    }
}
