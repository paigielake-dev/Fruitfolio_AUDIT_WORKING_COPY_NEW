import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BAudioSettingsTests: XCTestCase {
    #if DEBUG
    func testInteractionDiagnosticsAreOptInAndMuteDoesNotBecomePlaybackEvidence() async throws {
        let suite = "Fruitfolio.AudioDiagnostics." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.globallyMuted = true
        let audio = AudioManager(settings: settings)
        defer { audio.resetAllAudio() }
        audio.play(.buttonSoftPop)
        XCTAssertTrue(audio.debugInteractionRequests.isEmpty)
        audio.debugRecordInteractions(true)
        audio.play(.buttonSoftPop)
        audio.play(.typingSoft, loop: true)
        XCTAssertEqual(audio.debugInteractionRequests[FruitfolioAudioID.buttonSoftPop.rawValue], 1)
        XCTAssertNil(audio.debugInteractionRequests[FruitfolioAudioID.typingSoft.rawValue])
        XCTAssertEqual(audio.debugInteractionPlaybackStarts[FruitfolioAudioID.buttonSoftPop.rawValue, default: 0], 0)
        audio.debugRecordInteractions(false)
        audio.play(.buttonSoftPop)
        XCTAssertEqual(audio.debugInteractionRequests[FruitfolioAudioID.buttonSoftPop.rawValue], 1)
    }
    #endif

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

    func testOwnedTypingLoopHonorsMuteToggleAndCanBeForgotten() async throws {
        let suite = "Prompt1BTypingLoop.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        defer { audio.resetAllAudio() }
        audio.play(.typingSoft, loop: true)
        XCTAssertTrue(audio.debugLoopSnapshot(category: .typingASMR).requested)
        _ = try XCTUnwrap(audio.debugLoopSnapshot(category: .typingASMR).volume,
                          "The bundled ASMR asset must load for playback verification")
        settings.globallyMuted = true
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(audio.debugLoopSnapshot(category: .typingASMR).volume ?? -1, 0, accuracy: 0.001)
        settings.typingASMREnabled = false
        settings.globallyMuted = false
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(audio.debugLoopSnapshot(category: .typingASMR).volume ?? -1, 0, accuracy: 0.001)
        settings.typingASMREnabled = true
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertGreaterThan(audio.debugLoopSnapshot(category: .typingASMR).volume ?? 0, 0)
        audio.forgetLoop(category: .typingASMR)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .typingASMR).requested)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .typingASMR).playing)
    }

    func testNonfinitePersistedVolumesRecoverSafely() throws {
        let suite = "Prompt1BVolume.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Double.infinity, forKey: "fruitfolio.settings.musicVolume")
        XCTAssertEqual(SettingsStore(defaults: defaults).musicVolume, 0)
    }
}
