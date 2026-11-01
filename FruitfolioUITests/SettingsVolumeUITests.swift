import XCTest

final class SettingsVolumeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private let names = ["music", "rain_sounds", "sound_effects", "typing_asmr"]
    private func scrollSettings(_ app: XCUIApplication, up: Bool) {
        let scroll = app.scrollViews.firstMatch
        let container = scroll.exists ? scroll : app
        let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.82 : 0.25))
        let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: up ? 0.25 : 0.82))
        start.press(forDuration: 0.05, thenDragTo: end)
    }
    private func openSettings(_ app: XCUIApplication) {
        let explore = app.buttons["I'll explore"]
        if explore.waitForExistence(timeout: 12) { explore.tap() }
        let settings = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "settings")).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 15)); settings.tap()
        XCTAssertTrue(app.sliders["settings.volume.music"].waitForExistence(timeout: 10))
    }
    private func reach(_ app: XCUIApplication, _ slider: XCUIElement) {
        let visible = app.frame.insetBy(dx: 0, dy: 60)
        for _ in 0..<10 where !slider.isHittable || !visible.contains(slider.frame) { scrollSettings(app, up: true) }
        XCTAssertTrue(slider.isHittable)
    }
    func testOriginalArtworkControlsChangeIndependentlyAndPersistAfterRestart() {
        let app = XCUIApplication(); app.launchArguments += ["-fruitfolioUITest", "1"]; app.launch()
        openSettings(app)
        var saved: [String:String] = [:]
        for name in names {
            let slider = app.sliders["settings.volume." + name]
            reach(app, slider)
            saved[name] = slider.value as? String
        }
        for (index,name) in names.enumerated() {
            let slider = app.sliders["settings.volume." + name]
            // Return to the top before seeking an earlier category.
            for _ in 0..<8 where !slider.isHittable { scrollSettings(app, up: false) }
            reach(app, slider)
            let original = saved[name] ?? ""
            let target: CGFloat = original.hasPrefix("23") ? 0.71 : 0.23
            slider.adjust(toNormalizedSliderPosition: target)
            let changed = slider.value as? String
            XCTAssertNotNil(changed, "The actual adjustable control must expose its selected value")
            XCTAssertNotEqual(changed, original, "Dragging the painted \(name) slider must change its actual preference")
            saved[name] = changed
            for other in names where other != name {
                XCTAssertEqual(app.sliders["settings.volume." + other].value as? String, saved[other], "Only the selected category may change")
            }
            let image = XCTAttachment(screenshot: app.screenshot())
            image.name = "Settings_ArtworkVolume_\(index)_\(name)"; image.lifetime = .keepAlways; add(image)
        }
        app.terminate(); app.launch(); openSettings(app)
        for name in names {
            let slider = app.sliders["settings.volume." + name]; reach(app, slider)
            XCTAssertEqual(slider.value as? String, saved[name], "Selected volume must survive an actual application restart")
        }
    }
}
