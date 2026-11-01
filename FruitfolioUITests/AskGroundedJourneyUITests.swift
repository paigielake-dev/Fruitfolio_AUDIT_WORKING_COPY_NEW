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
        let ask = button(app, "Ask the Encyclopedia")
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
        let back = button(app, "Back")
        for _ in 0..<20 where !back.isHittable { app.swipeDown() }
        XCTAssertTrue(back.isHittable); back.tap()
        openAsk(app)
        XCTAssertFalse(app.textViews["ask.completedAnswer"].exists)
        XCTAssertFalse(app.staticTexts[question].exists, "Leaving Ask must clear session-only conversation")
        XCTAssertTrue((app.textFields["ask.questionInput"].value as? String ?? "").isEmpty
            || (app.textFields["ask.questionInput"].value as? String) == "ask Fruitfolio something…")
        capture(app, "Ask_ClearedAfterReturning")
    }
}
