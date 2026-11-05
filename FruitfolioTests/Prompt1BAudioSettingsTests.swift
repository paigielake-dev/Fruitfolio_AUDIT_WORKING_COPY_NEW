import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BAudioSettingsTests: XCTestCase {
    func testGlobalMuteBlocksAllChannelsAndPreservesIndividualPreferences() throws {
        let suite = "Prompt1BAudio.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = false
        settings.rainVolume = 0.4
        settings.globallyMuted = true
        for category: FruitfolioAudioCategory in [.music, .rainAmbience, .soundEffects, .typingASMR] {
            XCTAssertFalse(settings.allowsAudio(category))
        }
        let restored = SettingsStore(defaults: defaults)
        XCTAssertTrue(restored.globallyMuted)
        XCTAssertEqual(restored.rainVolume, 0.4)
        restored.globallyMuted = false
        XCTAssertFalse(restored.allowsAudio(.music))
        XCTAssertTrue(restored.allowsAudio(.rainAmbience))
        XCTAssertTrue(restored.allowsAudio(.soundEffects))
        XCTAssertTrue(restored.allowsAudio(.typingASMR))
    }

    func testNonfinitePersistedVolumesRecoverSafely() throws {
        let suite = "Prompt1BVolume.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Double.infinity, forKey: "fruitfolio.settings.musicVolume")
        XCTAssertEqual(SettingsStore(defaults: defaults).musicVolume, 0)
    }
}
