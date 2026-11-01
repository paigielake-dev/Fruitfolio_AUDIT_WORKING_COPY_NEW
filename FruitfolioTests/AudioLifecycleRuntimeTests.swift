import XCTest
import UIKit
@testable import Fruitfolio

@MainActor
final class AudioLifecycleRuntimeTests: XCTestCase {
    func testActualMusicAndRainPlayersRemainIndependentAndSettingsMuteOnlyTheirCategory() async throws {
        let suite = "AudioLoops-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = true; settings.rainEnabled = true
        settings.musicVolume = 0.21; settings.rainVolume = 0.18
        let manager = AudioManager(settings: settings)
        defer { manager.resetAllAudio() }
        manager.play(.fruitBasketMusicbox, loop: true)
        manager.play(.fruitBasketRainAmbience, loop: true)
        for _ in 0..<10 { manager.play(.fruitBasketMusicbox, loop: true) }
        let music = manager.playbackObservation(for: .music)
        let rain = manager.playbackObservation(for: .rainAmbience)
        XCTAssertEqual(music.playerCount, 1); XCTAssertEqual(rain.playerCount, 1)
        XCTAssertTrue(music.isPlaying); XCTAssertTrue(rain.isPlaying)
        XCTAssertGreaterThan(try XCTUnwrap(music.durations.first), 0)
        XCTAssertGreaterThan(try XCTUnwrap(rain.durations.first), 0)
        XCTAssertEqual(try XCTUnwrap(rain.volumes.first), 0.18, accuracy: 0.001)
        settings.musicVolume = 0.09
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .music).volumes.first), 0.09, accuracy: 0.001,
                       "A live volume change must apply the newly published value, not the previous setting")
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .rainAmbience).volumes.first), 0.18, accuracy: 0.001)
        settings.musicEnabled = false
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .music).volumes.first), 0, accuracy: 0.001)
        XCTAssertFalse(manager.playbackObservation(for: .music).isPlaying, "Disabled music must actually pause")
        XCTAssertTrue(manager.playbackObservation(for: .rainAmbience).isPlaying)
        settings.rainEnabled = false
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .rainAmbience).volumes.first), 0, accuracy: 0.001)
        XCTAssertFalse(manager.playbackObservation(for: .rainAmbience).isPlaying, "Disabled rain must actually pause")
        let evidence = XCTAttachment(string: "Bundled AVAudioPlayer music/rain loaded and played independently; repeated start retained one music player; category settings muted only their own player. API observation, not an audible-quality recording.")
        evidence.name = "MusicRain_RuntimePlayers"; evidence.lifetime = .keepAlways; add(evidence)
    }

    func testActualLoopStopsAndRestoresAcrossApplicationLifecycleNotifications() async throws {
        let suite = "AudioLifecycle-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = true
        let manager = AudioManager(settings: settings)
        defer {
            manager.resetAllAudio()
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        }
        manager.play(.fruitBasketMusicbox, loop: true)
        XCTAssertTrue(manager.playbackObservation(for: .music).isPlaying)
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertFalse(manager.playbackObservation(for: .music).isPlaying)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        try await Task.sleep(for: .milliseconds(300))
        XCTAssertTrue(manager.playbackObservation(for: .music).isPlaying)
        XCTAssertEqual(manager.playbackObservation(for: .music).playerCount, 1)
        let evidence = XCTAttachment(string: "Real AVAudioPlayer stopped/restored in response to posted UIKit application lifecycle notifications. This verifies the manager handlers; physical-device interruption and audible quality remain NOT VERIFIED.")
        evidence.name = "AudioLifecycle_RuntimeObservation"; evidence.lifetime = .keepAlways; add(evidence)
    }
}

extension AudioLifecycleRuntimeTests {
    func testMasterMuteStopsActualPlayersAndOnlyResumesEnabledRequestedLoops() async throws {
        let suite = "AudioMasterMute-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = true; settings.rainEnabled = true
        settings.soundEffectsEnabled = true; settings.typingASMREnabled = true
        settings.musicVolume = 0.21; settings.rainVolume = 0.18
        let manager = AudioManager(settings: settings)
        defer { manager.resetAllAudio() }
        manager.play(.fruitBasketMusicbox, loop: true)
        manager.play(.fruitBasketRainAmbience, loop: true)
        manager.play(.gentleCheer); manager.playTypingTick()
        let started = FruitfolioAudioCategory.allCases.map { "\($0): \(manager.playbackObservation(for: $0))" }.joined(separator: "\n")
        XCTAssertTrue(manager.playbackObservation(for: .music).isPlaying)
        XCTAssertTrue(manager.playbackObservation(for: .rainAmbience).isPlaying)
        XCTAssertTrue(manager.playbackObservation(for: .soundEffects).isPlaying)
        XCTAssertTrue(manager.playbackObservation(for: .typingASMR).isPlaying)
        settings.soundEffectsVolume = 0.06; settings.typingVolume = 0.04
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .soundEffects).volumes.first), 0.06, accuracy: 0.001)
        XCTAssertEqual(manager.typingPlaybackState.volume, 0.04, accuracy: 0.001)
        settings.allAudioMuted = true
        let muted = FruitfolioAudioCategory.allCases.map { "\($0): \(manager.playbackObservation(for: $0))" }.joined(separator: "\n")
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertFalse(manager.playbackObservation(for: category).isPlaying,
                "Master mute must stop actual playback in \(category), not merely hide a preference")
        }
        XCTAssertTrue(settings.musicEnabled && settings.rainEnabled && settings.soundEffectsEnabled && settings.typingASMREnabled)
        manager.play(.fruitBasketMusicbox, loop: true)
        manager.play(.fruitBasketRainAmbience, loop: true)
        manager.play(.gentleCheer); manager.playTypingTick()
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertFalse(manager.playbackObservation(for: category).isPlaying, "Muted playback requests must remain silent")
        }
        settings.musicEnabled = false
        settings.musicVolume = 0.07
        settings.allAudioMuted = false
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertFalse(manager.playbackObservation(for: .music).isPlaying)
        XCTAssertTrue(manager.playbackObservation(for: .rainAmbience).isPlaying)
        XCTAssertFalse(manager.playbackObservation(for: .soundEffects).isPlaying, "Unmute must never replay old one-shot effects")
        XCTAssertFalse(manager.playbackObservation(for: .typingASMR).isPlaying, "Unmute must never replay old typing cues")
        settings.musicEnabled = true
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertTrue(manager.playbackObservation(for: .music).isPlaying)
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .music).volumes.first), 0.07, accuracy: 0.001)
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .rainAmbience).volumes.first), 0.18, accuracy: 0.001)
        let resumed = FruitfolioAudioCategory.allCases.map { "\($0): \(manager.playbackObservation(for: $0))" }.joined(separator: "\n")
        let attachment = XCTAttachment(string: "Actual bundled AVAudioPlayer observations. Started:\n\(started)\nMaster muted:\n\(muted)\nResumed after category checks:\n\(resumed)\nAPI observations; audible quality remains unverified.")
        attachment.name = "MasterMute_ActualPlayerObservation"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testPersistedMasterMutePreventsPlaybackAfterStoreAndManagerRestart() throws {
        let suite = "AudioMasterMuteRestart-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = true; settings.rainEnabled = false
        settings.allAudioMuted = true
        let reopened = SettingsStore(defaults: defaults)
        XCTAssertTrue(reopened.allAudioMuted)
        XCTAssertTrue(reopened.musicEnabled); XCTAssertFalse(reopened.rainEnabled)
        let manager = AudioManager(settings: reopened)
        defer { manager.resetAllAudio() }
        manager.play(.fruitBasketMusicbox, loop: true)
        manager.play(.fruitBasketRainAmbience, loop: true)
        manager.play(.gentleCheer); manager.playTypingTick()
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertEqual(manager.playbackObservation(for: category).playerCount, 0,
                "A muted restart must not initialize or start an audio player")
        }
    }
}
