import XCTest
@testable import Fruitfolio

@MainActor
final class TypingAudioRuntimeTests: XCTestCase {
    func testRealTypingPlayerRespectsMuteAndAvoidsDuplicatePlayers() throws {
        let suite = "TypingAudioRuntimeTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = false
        settings.rainEnabled = false
        settings.typingASMREnabled = true
        settings.typingVolume = 0.08
        let manager = AudioManager(settings: settings)
        defer { manager.resetAllAudio() }
        manager.playTypingTick()
        let started = manager.typingPlaybackState
        XCTAssertEqual(started.playerCount, 1, "Actual bundled typing audio must load")
        XCTAssertTrue(started.isPlaying, "AVAudioPlayer must report active playback")
        XCTAssertEqual(started.volume, 0.08, accuracy: 0.001)
        for _ in 0..<20 { manager.playTypingTick() }
        XCTAssertEqual(manager.typingPlaybackState.playerCount, 1)
        settings.typingASMREnabled = false
        manager.stop(category: .typingASMR)
        manager.playTypingTick()
        XCTAssertFalse(manager.typingPlaybackState.isPlaying)
        let attachment = XCTAttachment(string: "Actual AVAudioPlayer API observation: started=\(started.isPlaying), players=\(started.playerCount), volume=\(started.volume). Repeated ticks retained one player. Mute/stop prevented playback. This is not a microphone recording or an audible-quality assessment.")
        attachment.name = "TypingAudio_RuntimePlaybackState"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
