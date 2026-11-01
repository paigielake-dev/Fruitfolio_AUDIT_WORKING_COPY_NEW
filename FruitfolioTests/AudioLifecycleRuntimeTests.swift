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
        settings.musicEnabled = false
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .music).volumes.first), 0, accuracy: 0.001)
        XCTAssertTrue(manager.playbackObservation(for: .rainAmbience).isPlaying)
        settings.rainEnabled = false
        try await Task.sleep(for: .milliseconds(400))
        XCTAssertEqual(try XCTUnwrap(manager.playbackObservation(for: .rainAmbience).volumes.first), 0, accuracy: 0.001)
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
