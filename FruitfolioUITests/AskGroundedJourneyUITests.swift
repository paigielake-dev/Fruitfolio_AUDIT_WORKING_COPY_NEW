import XCTest

final class AskGroundedJourneyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func button(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", name)).firstMatch
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    private func openAsk(_ app: XCUIApplication) {
        let ask = app.buttons["hub.action.Ask the Encyclopedia"]
        XCTAssertTrue(ask.waitForExistence(timeout: 15)); ask.tap()
        XCTAssertTrue(app.textFields["ask.questionInput"].waitForExistence(timeout: 10))
    }
    func testActualGroundedAnswerSourcesAndClearOnExit() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        openAsk(app)
        let question = "How does morning sunlight affect the body clock?"
        let input = app.textFields["ask.questionInput"]
        input.tap(); input.typeText(question)
        let send = button(app, "Send question")
        XCTAssertTrue(send.isEnabled && send.isHittable); send.tap()
        let answer = app.textViews["ask.completedAnswer"]
        XCTAssertTrue(answer.waitForExistence(timeout: 180), "The actual application must finish its request; file existence cannot satisfy this test")
        XCTAssertGreaterThan(answer.label.count, 30)
        capture(app, "Ask_ActualCompletedAnswer")
        let source = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "ask.source.founder_")).firstMatch
        for _ in 0..<20 where !source.exists { app.swipeUp() }
        XCTAssertTrue(source.exists, "Answer must expose the supplied document's real source identity")
        XCTAssertFalse(source.label.isEmpty)
        capture(app, "Ask_ActualDocumentSources")
        let record = XCTAttachment(string: "Question: \(question)\nAnswer: \(answer.label)\nActual source: \(source.identifier)\n\(source.label)\nThis UI journey does not independently prove medical entailment or distinguish native generation from bounded research fallback; the strict native integration test verifies those separate gates.")
        record.name = "Ask_ActualUIAnswerAndSource"; record.lifetime = .keepAlways; add(record)
        let back = app.buttons["ask.back"]
        for _ in 0..<20 where !back.isHittable { app.swipeDown() }
        XCTAssertTrue(back.isHittable); back.tap()
        openAsk(app)
        XCTAssertFalse(app.textViews["ask.completedAnswer"].exists)
        XCTAssertFalse(app.staticTexts[question].exists, "Leaving Ask must clear session-only conversation")
        XCTAssertTrue((app.textFields["ask.questionInput"].value as? String ?? "").isEmpty
            || (app.textFields["ask.questionInput"].value as? String) == "ask Fruitfolio something…")
        capture(app, "Ask_ClearedAfterReturning")
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        for _ in 0..<20 where !target.exists { app.swipeUp() }
        XCTAssertTrue(target.exists)
        let id = target.identifier.isEmpty ? target.label : target.identifier
        let owner = app.scrollViews.containing(target.elementType, identifier: id).firstMatch
        let scroll = owner.exists ? owner : app
        let visible = app.frame.insetBy(dx: 0, dy: 60).intersection(scroll.frame)
        for _ in 0..<14 where !target.isHittable || !visible.contains(target.frame) {
            let up = target.frame.midY > visible.midY
            scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.82 : 0.25))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.25 : 0.82)))
        }
        XCTAssertTrue(target.isHittable)
    }
    func testActualAnswerSaveRestartAndReopenRetainTheSameOriginalSourceReference() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let library = app.buttons["hub.action.My Encyclopedias"]
        XCTAssertTrue(library.waitForExistence(timeout: 15)); library.tap()
        let first = button(app, "build my first encyclopedia")
        let another = button(app, "add another little encyclopedia")
        _ = first.waitForExistence(timeout: 8)
        let create = first.exists ? first : another; reach(app, create); create.tap()
        let name = "Citations QA " + String(UUID().uuidString.prefix(6))
        let nameField = app.textFields["encyclopedia name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 8)); nameField.tap(); nameField.typeText(name + "\n")
        let make = button(app, "create encyclopedia"); reach(app, make); make.tap()
        let back = button(app, "back"); reach(app, back); back.tap()
        openAsk(app)
        let question = "How does morning sunlight affect the body clock?"
        let input = app.textFields["ask.questionInput"]; input.tap(); input.typeText(question)
        button(app, "Send question").tap()
        XCTAssertTrue(app.textViews["ask.completedAnswer"].waitForExistence(timeout: 180))
        let source = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "ask.source.founder_")).firstMatch
        for _ in 0..<20 where !source.exists { app.swipeUp() }
        XCTAssertTrue(source.exists)
        let originals = [
            "ask.source.founder_corpus_13d89a17c6a65d0272b9": "FruitsofLife.xo research corpus. (n.d.). Fruitfolio Research Library.",
            "ask.source.founder_guide_f0edba71bf43fb3a878e": "FruitsofLife.xo. (n.d.). Pregnancy, postpartum, & women’s wellness guide [Unpublished educational guide]."
        ]
        let originalReference = originals[source.identifier]
        XCTAssertNotNil(originalReference, "This journey must use one of the actual immutable bundled document references")
        XCTAssertTrue(source.label.contains(originalReference ?? "unavailable fixture"))
        let bookmark = button(app, "Add bookmark"); reach(app, bookmark); bookmark.tap()
        let destination = button(app, name); XCTAssertTrue(destination.waitForExistence(timeout: 8)); reach(app, destination); destination.tap()
        let save = button(app, "save here"); reach(app, save); XCTAssertTrue(save.isEnabled); save.tap()
        XCTAssertTrue(app.staticTexts["saved to my encyclopedia"].waitForExistence(timeout: 10))
        capture(app, "Citations_ActualAnswerSaved")
        app.terminate(); app.launch()
        let libraryAgain = app.buttons["hub.action.My Encyclopedias"]
        XCTAssertTrue(libraryAgain.waitForExistence(timeout: 15)); libraryAgain.tap()
        let book = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        reach(app, book); book.tap()
        let saved = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", question)).firstMatch
        reach(app, saved); saved.tap()
        let reference = app.staticTexts[originalReference ?? "missing original reference"]
        reach(app, reference)
        XCTAssertEqual(reference.label, originalReference)
        XCTAssertFalse(app.staticTexts["savedPage.unavailableReference.0"].exists)
        capture(app, "Citations_ExactOriginalReferenceAfterRestart")
    }

}
