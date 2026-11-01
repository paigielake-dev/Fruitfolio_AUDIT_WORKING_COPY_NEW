import XCTest

final class UsernameSynchronizationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func button(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label ==[c] %@", name)).firstMatch
    }
    private func reach(_ app: XCUIApplication, _ target: XCUIElement) {
        XCTAssertTrue(target.waitForExistence(timeout: 10))
        let scroll = app.scrollViews.containing(target.elementType, identifier: target.identifier).firstMatch
        let container = scroll.exists ? scroll : app
        let visible = app.frame.insetBy(dx: 0, dy: 60).intersection(container.frame)
        for _ in 0..<12 where !target.isHittable || !visible.contains(target.frame) {
            let upward = target.frame.midY > visible.midY
            container.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: upward ? 0.82 : 0.25))
                .press(forDuration: 0.05, thenDragTo: container.coordinate(withNormalizedOffset: CGVector(dx: 0.96, dy: upward ? 0.25 : 0.82)))
        }
        XCTAssertTrue(target.isHittable)
        XCTAssertTrue(visible.contains(target.frame))
    }
    private func replace(_ field: XCUIElement, with value: String) {
        field.tap()
        let old = field.value as? String ?? ""
        if old != "public username" { field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count)) }
        // Individual keystrokes exercise incomplete one- and two-character drafts.
        for character in value { field.typeText(String(character)) }
        XCTAssertEqual(field.value as? String, value)
        field.typeText("\n")
    }
    private func capture(_ app: XCUIApplication, _ title: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = title; a.lifetime = .keepAlways; add(a)
    }
    private func account(_ app: XCUIApplication) {
        let action = button(app, "sign in")
        XCTAssertTrue(action.waitForExistence(timeout: 12)); action.tap()
        XCTAssertTrue(app.textFields["account.publicUsername"].waitForExistence(timeout: 10))
    }
    func testOrdinaryTypingSynchronizesAccountAndFruitBasketAndSurvivesRestart() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        account(app)
        let accountName = app.textFields["account.publicUsername"]
        reach(app, accountName); replace(accountName, with: "berry_qa12")
        let save = button(app, "save username"); reach(app, save); save.tap()
        XCTAssertTrue(app.staticTexts["saved!"].waitForExistence(timeout: 5))
        capture(app, "Username_AccountSaved")
        let back = button(app, "Back"); reach(app, back); back.tap()
        let basket = app.buttons["hub.action.Fruit Basket"]
        XCTAssertTrue(basket.waitForExistence(timeout: 10)); basket.tap()
        let skip = button(app, "skip tour")
        if skip.waitForExistence(timeout: 5) {
            skip.tap()
            let home = button(app, "fruit basket"); XCTAssertTrue(home.waitForExistence(timeout: 8)); home.tap()
        }
        let leaderboard = button(app, "leaderboard"); reach(app, leaderboard); leaderboard.tap()
        let basketName = app.textFields["fruitBasket.publicUsername"]
        reach(app, basketName); XCTAssertEqual(basketName.value as? String, "berry_qa12")
        replace(basketName, with: "peach_qa34")
        capture(app, "Username_FruitBasketActualTyping")
        reach(app, back); back.tap(); account(app)
        reach(app, accountName); XCTAssertEqual(accountName.value as? String, "peach_qa34")
        capture(app, "Username_AccountSynchronized")
        app.terminate(); app.launch()
        account(app); reach(app, accountName)
        XCTAssertEqual(accountName.value as? String, "peach_qa34")
        capture(app, "Username_PersistedAcrossRestart")
    }
}
