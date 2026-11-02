import XCTest

final class LanguageSelectionJourneyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let frame = XCTAttachment(screenshot: app.screenshot())
        frame.name = name; frame.lifetime = .keepAlways; add(frame)
    }

    private func openSettings(_ app: XCUIApplication) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = app.buttons["hub.utility.settings"]
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        fruitfolioReachControl(app, settings); settings.tap()
        XCTAssertTrue(app.buttons["settings.languageMenu"].waitForExistence(timeout: 10))
    }

    func testSelectionSurvivesActualRestartAndUnverifiedDisplayIsDisclosedWithoutClaimingTranslationAcceptance() {
        let app = XCUIApplication()
        app.launchArguments += ["-fruitfolioUITest", "1"]
        app.launch(); openSettings(app)
        func volumeValues() -> [String: String] {
            Dictionary(uniqueKeysWithValues: ["music", "rain_sounds", "sound_effects", "typing_asmr"].map { name in
                let slider = app.sliders["settings.volume." + name]
                XCTAssertTrue(slider.exists)
                let value = slider.value as? String
                XCTAssertNotNil(value)
                return (name, value ?? "MISSING")
            })
        }
        let originalVolumes = volumeValues()
        let menu = app.buttons["settings.languageMenu"]
        fruitfolioReachControl(app, menu); menu.tap()
        let spanish = app.buttons.matching(identifier: "Español").firstMatch
        XCTAssertTrue(spanish.waitForExistence(timeout: 5)); spanish.tap()
        XCTAssertEqual(menu.value as? String, "Español")
        XCTAssertEqual(volumeValues(), originalVolumes, "Scrolling to the menu and choosing a language must not drag a volume control")
        let notice = app.staticTexts["settings.translationAvailability"]
        XCTAssertTrue(notice.waitForExistence(timeout: 5))
        XCTAssertTrue(notice.label.contains("hasn’t been verified"))
        capture(app, "Language_ActualSelectedSpanishAndUnverifiedDisplayNotice")
        app.terminate(); app.launch(); openSettings(app)
        fruitfolioReachControl(app, menu)
        XCTAssertEqual(menu.value as? String, "Español", "Actual termination/relaunch must retain selection")
        XCTAssertEqual(volumeValues(), originalVolumes, "Unrelated actual audio preferences must also survive restart unchanged")
        capture(app, "Language_ActualPersistedSelectionAfterRestart")
        menu.tap()
        let english = app.buttons.matching(identifier: "English").firstMatch
        XCTAssertTrue(english.waitForExistence(timeout: 5)); english.tap()
        XCTAssertEqual(menu.value as? String, "English")
        XCTAssertEqual(volumeValues(), originalVolumes)
        XCTAssertFalse(app.staticTexts["settings.translationAvailability"].exists)
        capture(app, "Language_ActualReturnToOriginalEnglish")
    }
    func testRTLControlsAndDistinctChineseInterfaceScriptsPersistThroughActualRestarts() {
        verifyScriptsAndDirection(largest: false)
    }
    func testLargestTextRTLAndChineseInterfaceControlsRemainFullyReachable() {
        verifyScriptsAndDirection(largest: true)
    }

    private func verifyScriptsAndDirection(largest: Bool) {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]
        if largest { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch(); openSettings(app)
        let menu = app.buttons["settings.languageMenu"]
        for (autonym, heading, backName, rtl) in [
            ("العربية", "الإعدادات", "رجوع", true),
            ("עברית", "הגדרות", "חזרה", true),
            ("简体中文", "设置", "返回", false),
            ("繁體中文", "設定", "返回", false)
        ] {
            reachLocaleControl(app, menu, rtl: ["العربية", "עברית"].contains(menu.value as? String ?? ""))
            menu.tap()
            let option = app.buttons.matching(identifier: autonym).firstMatch
            XCTAssertTrue(option.waitForExistence(timeout: 5)); option.tap()
            XCTAssertEqual(menu.value as? String, autonym)
            let title = app.staticTexts["route.header.settings"]
            let back = app.buttons.matching(identifier: backName).firstMatch
            reachLocaleControl(app, back, rtl: rtl)
            XCTAssertEqual(title.label, heading, "Actual compiled interface wording must distinguish the selected script")
            XCTAssertGreaterThanOrEqual(back.frame.width, 44)
            XCTAssertGreaterThanOrEqual(back.frame.height, 44)
            if rtl { XCTAssertGreaterThan(back.frame.midX, app.frame.midX) }
            else { XCTAssertLessThan(back.frame.midX, app.frame.midX) }
            capture(app, "Language_ActualScriptAndBackPlacement_\(autonym)_largest_\(largest)")
            app.terminate(); app.launch(); openSettings(app)
            XCTAssertEqual(menu.value as? String, autonym)
            XCTAssertEqual(app.staticTexts["route.header.settings"].label, heading)
            capture(app, "Language_ScriptRetainedAfterActualRestart_\(autonym)_largest_\(largest)")
        }
        reachLocaleControl(app, menu, rtl: false); menu.tap()
        let english = app.buttons.matching(identifier: "English").firstMatch
        XCTAssertTrue(english.waitForExistence(timeout: 5)); english.tap()
        XCTAssertEqual(menu.value as? String, "English")
    }

    private func reachLocaleControl(_ app: XCUIApplication, _ target: XCUIElement, rtl: Bool) {
        let scroll = app.scrollViews["settings.mainScroll"]
        XCTAssertTrue(scroll.exists)
        let viewport = scroll.frame.intersection(app.frame.insetBy(dx: 0, dy: 16))
        for _ in 0..<40 {
            if target.exists && target.isHittable && viewport.contains(target.frame) { return }
            let up = !target.exists || target.frame.midY > viewport.midY
            // RTL puts the system scroll indicator on the left. Use the other
            // blank margin, never the volume slider or the indicator thumb.
            let x: CGFloat = rtl ? 0.97 : 0.03
            scroll.coordinate(withNormalizedOffset: CGVector(dx: x, dy: up ? 0.80 : 0.22))
                .press(forDuration: 0.05, thenDragTo: scroll.coordinate(withNormalizedOffset:
                    CGVector(dx: x, dy: up ? 0.22 : 0.80)))
        }
        XCTAssertTrue(target.exists && target.isHittable && viewport.contains(target.frame),
                      "The actual localized control must be completely visible and reachable")
    }

}
