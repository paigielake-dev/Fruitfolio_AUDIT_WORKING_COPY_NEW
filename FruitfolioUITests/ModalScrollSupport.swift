import XCTest

/// Reach the actual owning viewport, including a canonical popup's writing area.
/// Partial clipping is determined by the leading edge, not the element midpoint.
func fruitfolioReachControl(_ app: XCUIApplication, _ target: XCUIElement,
                            container explicitContainer: XCUIElement? = nil) {
    if !target.waitForExistence(timeout: 2) {
        // Offscreen LazyVGrid cells are not accessibility elements until the
        // actual owning ScrollView brings them into its rendered range.
        let owner = explicitContainer ?? app.scrollViews.allElementsBoundByIndex.first(where: {
            $0.isHittable && !$0.frame.intersection(app.frame).isEmpty
        }) ?? app
        for _ in 0..<12 where !target.exists {
            let lazyPanX: CGFloat = ["popup.writingArea", "fruitBasket.tourWritingArea"].contains(owner.identifier) ? 0.50 : min(0.08, 16 / max(owner.frame.width, 1))
            owner.coordinate(withNormalizedOffset: CGVector(dx: lazyPanX, dy: 0.72))
                .press(forDuration: 0.05, thenDragTo: owner.coordinate(withNormalizedOffset: CGVector(dx: lazyPanX, dy: 0.28)),
                       withVelocity: .slow, thenHoldForDuration: 0.35)
        }
    }
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
    // The actual Settings hierarchy puts sliders across x36...366 and the
    // scroll thumb at x369...399. Center pans hit a slider; right-edge pans
    // scrub its scrollbar. Use the empty left gutter of full-page content.
    // A small popup has no such gutter and contains no sliders: use its center.
    let panX: CGFloat = popupOwnsTarget || ["popup.writingArea", "fruitBasket.tourWritingArea"].contains(container.identifier)
        ? 0.50 : min(0.08, 16 / max(container.frame.width, 1))
    // Keep the strict containment test, but budget real pans from measured
    // distance. A complete large-type scientific passage may legitimately
    // span far more than14small pans; never truncate it to satisfy a helper.
    let distance = abs(target.frame.midY - visible.midY)
    let estimatedPans = distance.isFinite
        ? Int(min(74, ceil(distance / max(visible.height * 0.40, 1)))) : 14
    let maximumAttempts = min(80, max(14, estimatedPans + 6))
    for attempt in 0..<maximumAttempts {
        let frame = target.frame
        print("REACH_CONTROL attempt=\(attempt) identifier=\(identifier) target=\(frame) viewport=\(visible) hittable=\(target.isHittable)")
        if target.isHittable && visible.contains(frame) { break }
        // Run85 left Cancel just9.7pt clipped and oscillated with12–24pt
        // edge corrections. Center the target with a reliable pan, preserving
        // full bounds and giving the control breathing room inside the paper.
        let delta = frame.midY - visible.midY
        let towardEarlierContent = delta < 0
        let distance = min(max(abs(delta), 32), visible.height * 0.45)
        let fraction = distance / max(container.frame.height, 1)
        let startY = towardEarlierContent ? 0.50 - fraction / 2 : 0.50 + fraction / 2
        let endY = towardEarlierContent ? 0.50 + fraction / 2 : 0.50 - fraction / 2
        // Run93's actual hierarchy places the interactive scrollbar at
        // x312...342 inside a x104...345 viewport. The previous dx0.95
        // starts at x333, on that thumb; attempts5/10 scrubbed backwards
        // by423pt instead of panning94pt. Pan the real content center.
        // Full containment, original viewport and hittability stay unchanged.
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: panX, dy: startY))
        let finish = container.coordinate(withNormalizedOffset: CGVector(dx: panX, dy: endY))
        // Run80's actual trace oscillated past the small writing viewport.
        // A proportional slow drag with a stationary release avoids momentum
        // overshoot without relaxing full containment or hittability.
        start.press(forDuration: 0.05, thenDragTo: finish, withVelocity: .slow, thenHoldForDuration: 0.35)
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
