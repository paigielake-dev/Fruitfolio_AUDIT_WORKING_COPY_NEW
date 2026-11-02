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
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15))
        fruitfolioReachControl(app, settings); settings.tap()
        XCTAssertTrue(app.buttons["language"].waitForExistence(timeout: 10))
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
        let menu = app.buttons["language"]
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
}
