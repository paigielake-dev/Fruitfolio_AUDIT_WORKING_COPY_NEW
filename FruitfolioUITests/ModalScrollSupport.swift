import XCTest

/// Reach the actual owning viewport, including a canonical popup's writing area.
/// Partial clipping is determined by the leading edge, not the element midpoint.
func fruitfolioReachControl(_ app: XCUIApplication, _ target: XCUIElement,
                            container explicitContainer: XCUIElement? = nil) {
    XCTAssertTrue(target.waitForExistence(timeout: 10))
    let identifier = target.identifier.isEmpty ? target.label : target.identifier
    let popup = app.descendants(matching: .any).matching(identifier: "popup.writingArea").firstMatch
    let popupOwnsTarget = popup.exists && popup.descendants(matching: target.elementType)
        .matching(NSPredicate(format: "label == %@", target.label)).firstMatch.exists
    let scroll = app.scrollViews.containing(target.elementType, identifier: identifier).firstMatch
    let container = explicitContainer ?? (popupOwnsTarget ? popup : (scroll.exists ? scroll : app))
    // Use the actual owning viewport. Run80's screenshot proves the Hub
    // contact button is fully painted/hittable at y761.7...819.7 inside its
    // 874pt ScrollView. An invented 60pt bottom exclusion falsely rejected it
    // and could not be repaired by scrolling content that already fitted.
    // Modal writing-area clipping, complete bounds and hittability stay strict.
    let visible = app.frame.intersection(container.frame)
    for _ in 0..<14 {
        if target.isHittable && visible.contains(target.frame) { break }
        let towardEarlierContent = target.frame.minY < visible.minY
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: towardEarlierContent ? 0.25 : 0.80))
        let finish = container.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: towardEarlierContent ? 0.80 : 0.25))
        start.press(forDuration: 0.05, thenDragTo: finish)
    }
    if !target.isHittable || !visible.contains(target.frame) {
        let screen = XCTAttachment(screenshot: app.screenshot()); screen.name = "Unreachable_" + target.label
        screen.lifetime = .keepAlways; XCTContext.runActivity(named: "Actual unreachable control") { $0.add(screen) }
        let tree = XCTAttachment(string: app.debugDescription); tree.name = "UnreachableControlHierarchy"
        tree.lifetime = .keepAlways; XCTContext.runActivity(named: "Actual owning viewport") { $0.add(tree) }
    }
    XCTAssertTrue(visible.contains(target.frame), "Entire control must fit the actual owning viewport: \(target.label)")
    XCTAssertTrue(target.isHittable)
}
