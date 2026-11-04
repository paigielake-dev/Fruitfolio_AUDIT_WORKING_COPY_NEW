import XCTest

final class SettingsVolumeUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private let names = ["music", "rain_sounds", "sound_effects", "typing_asmr"]
    private func scrollSettings(_ app: XCUIApplication, up: Bool) {
        let scroll = app.scrollViews["settings.mainScroll"]
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
        let owner = app.scrollViews["settings.mainScroll"]
        let visible = app.frame.insetBy(dx: 0, dy: 60).intersection(owner.frame)
        for _ in 0..<14 where !slider.isHittable || !visible.contains(slider.frame) {
            scrollSettings(app, up: slider.frame.midY > visible.midY)
        }
        if !slider.isHittable || !visible.contains(slider.frame) {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Settings_UnreachableVolume_" + slider.identifier; screenshot.lifetime = .keepAlways; add(screenshot)
            let tree = XCTAttachment(string: app.debugDescription)
            tree.name = "Settings_UnreachableVolumeHierarchy"; tree.lifetime = .keepAlways; add(tree)
        }
        XCTAssertTrue(slider.isHittable)
        XCTAssertTrue(visible.contains(slider.frame), "The entire real slider, including its thumb, must be inside its owning scroll viewport before interaction")
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
            let changedValue = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                guard let actual = slider.value as? String else { return false }
                return actual != original
            }, object: nil)
            XCTAssertEqual(XCTWaiter.wait(for: [changedValue], timeout: 3), .completed,
                           "The actual native slider must report the changed preference after its touch event")
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
        let master = app.descendants(matching: .any)["settings.globalMute"]
        for _ in 0..<10 where !master.isHittable { scrollSettings(app, up: false) }
        XCTAssertTrue(master.isHittable)
        let originalMaster = master.value as? String ?? ""
        XCTAssertTrue(["on", "off"].contains(originalMaster), "Master state must be accessible")
        var channels: [String:String] = [:]
        for name in names {
            let toggle = app.descendants(matching: .any)["settings.enabled." + name]
            let value = toggle.value as? String ?? ""
            XCTAssertTrue(["on", "off"].contains(value)); channels[name] = value
        }
        master.tap()
        let changedMaster = master.value as? String ?? ""
        XCTAssertTrue(["on", "off"].contains(changedMaster))
        XCTAssertNotEqual(changedMaster, originalMaster)
        for name in names {
            XCTAssertEqual(app.descendants(matching: .any)["settings.enabled." + name].value as? String,
                channels[name], "Master mute must preserve each category preference")
        }
        let mutedImage = XCTAttachment(screenshot: app.screenshot())
        mutedImage.name = "Settings_GlobalMute_Toggled"; mutedImage.lifetime = .keepAlways; add(mutedImage)
        app.terminate(); app.launch(); openSettings(app)
        XCTAssertEqual(master.value as? String, changedMaster, "Master mute must survive a real application restart")
        for name in names {
            XCTAssertEqual(app.descendants(matching: .any)["settings.enabled." + name].value as? String, channels[name])
        }
        for _ in 0..<8 where !master.isHittable { scrollSettings(app, up: false) }
        XCTAssertTrue(master.isHittable); master.tap()
        XCTAssertEqual(master.value as? String, originalMaster, "Restore only the tested master preference; never reset user data")
        var toggledChannels = channels
        for name in names {
            let toggle = app.descendants(matching: .any)["settings.enabled." + name]
            let visible = app.frame.insetBy(dx: 0, dy: 60)
            for _ in 0..<12 where !toggle.isHittable || !visible.contains(toggle.frame) {
                scrollSettings(app, up: toggle.frame.midY > visible.midY)
            }
            XCTAssertTrue(toggle.isHittable); toggle.tap()
            let changed = toggle.value as? String ?? ""
            XCTAssertTrue(["on", "off"].contains(changed)); XCTAssertNotEqual(changed, channels[name])
            toggledChannels[name] = changed
            for other in names where other != name {
                XCTAssertEqual(app.descendants(matching: .any)["settings.enabled." + other].value as? String,
                               toggledChannels[other], "Each category toggle must preserve the other category settings")
            }
        }
        app.terminate(); app.launch(); openSettings(app)
        for name in names {
            let toggle = app.descendants(matching: .any)["settings.enabled." + name]
            XCTAssertEqual(toggle.value as? String, toggledChannels[name], "Each enabled preference must survive restart")
            let visible = app.frame.insetBy(dx: 0, dy: 60)
            for _ in 0..<12 where !toggle.isHittable || !visible.contains(toggle.frame) {
                scrollSettings(app, up: toggle.frame.midY > visible.midY)
            }
            XCTAssertTrue(toggle.isHittable); toggle.tap()
            XCTAssertEqual(toggle.value as? String, channels[name], "Restore the original individual category preference")
        }
    }
}
