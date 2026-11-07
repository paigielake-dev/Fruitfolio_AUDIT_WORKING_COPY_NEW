import XCTest
import UIKit
import AVFoundation
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
    #if DEBUG
    func testFourLivePlayerVolumesUseNewPublishedValuesAfterRunLoopReconciliation() async throws {
        let suite = "Fruitfolio.LiveAudioVolumes." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        defer { audio.resetAllAudio() }
        let channels: [(FruitfolioAudioCategory, FruitfolioAudioID)] = [(.music, .fruitBasketMusicbox), (.rainAmbience, .fruitBasketRainAmbience), (.soundEffects, .buttonSoftPop), (.typingASMR, .typingSoft)]
        for (_, id) in channels { audio.play(id, loop: true) }
        try await Task.sleep(for: .milliseconds(250)) // Drain initial real Combine deliveries first.
        for (category, _) in channels { _ = try XCTUnwrap(audio.debugLoopSnapshot(category: category).volume, "Actual bundled AVAudioPlayer must load") }
        settings.musicVolume = 0.71; settings.rainVolume = 0.62
        settings.soundEffectsVolume = 0.53; settings.typingVolume = 0.44
        try await Task.sleep(for: .milliseconds(250))
        let expectedVolumes: [(FruitfolioAudioCategory, Float)] = [(.music, 0.71), (.rainAmbience, 0.62), (.soundEffects, 0.53), (.typingASMR, 0.44)]
        for (category, expected) in expectedVolumes {
            XCTAssertEqual(audio.debugLoopSnapshot(category: category).volume ?? -1, expected, accuracy: 0.001)
        }
        settings.musicVolume = 0.11; settings.musicVolume = 0.72; settings.musicVolume = 0.63
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertEqual(audio.debugLoopSnapshot(category: .music).volume ?? -1, 0.63, accuracy: 0.001)
        XCTAssertEqual(audio.debugLoopSnapshot(category: .rainAmbience).volume ?? -1, 0.62, accuracy: 0.001)
    }

    func testEnablingMusicAndRainWhileGloballyMutedCannotStartRequestedLoops() async throws {
        let suite = "Fruitfolio.AudioEnableMuted." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.globallyMuted = true; settings.musicEnabled = false; settings.rainEnabled = false
        let audio = AudioManager(settings: settings)
        defer { audio.resetAllAudio() }
        audio.play(.fruitBasketMusicbox, loop: true); audio.play(.fruitBasketRainAmbience, loop: true)
        try await Task.sleep(for: .milliseconds(250))
        settings.musicEnabled = true; settings.rainEnabled = true
        try await Task.sleep(for: .milliseconds(250))
        for category: FruitfolioAudioCategory in [.music, .rainAmbience] {
            XCTAssertTrue(audio.debugLoopSnapshot(category: category).requested)
            XCTAssertFalse(audio.debugLoopSnapshot(category: category).playing)
            XCTAssertEqual(audio.debugLoopSnapshot(category: category).volume ?? 0, 0)
        }
        settings.globallyMuted = false
        try await Task.sleep(for: .milliseconds(350))
        for category: FruitfolioAudioCategory in [.music, .rainAmbience] {
            XCTAssertTrue(audio.debugLoopSnapshot(category: category).playing, "Real playback must resume only after unmute")
            XCTAssertGreaterThan(audio.debugLoopSnapshot(category: category).volume ?? 0, 0)
        }
    }

    func testGlobalMutePausesAllExplicitLoopCategoriesAndDisabledChannelsStayPaused() async throws {
        let suite = "Fruitfolio.AudioPauseAll." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        defer { audio.resetAllAudio() }
        for id: FruitfolioAudioID in [.fruitBasketMusicbox, .fruitBasketRainAmbience, .buttonSoftPop, .typingSoft] { audio.play(id, loop: true) }
        try await Task.sleep(for: .milliseconds(250))
        for category in FruitfolioAudioCategory.allCases { _ = try XCTUnwrap(audio.debugLoopSnapshot(category: category).volume) }
        settings.globallyMuted = true
        try await Task.sleep(for: .milliseconds(250))
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertTrue(audio.debugLoopSnapshot(category: category).requested)
            XCTAssertFalse(audio.debugLoopSnapshot(category: category).playing)
            XCTAssertEqual(audio.debugLoopSnapshot(category: category).volume ?? -1, 0, accuracy: 0.001)
        }
        settings.soundEffectsEnabled = false; settings.typingASMREnabled = false
        settings.globallyMuted = false
        try await Task.sleep(for: .milliseconds(350))
        for category: FruitfolioAudioCategory in [.soundEffects, .typingASMR] {
            XCTAssertFalse(audio.debugLoopSnapshot(category: category).playing)
            XCTAssertEqual(audio.debugLoopSnapshot(category: category).volume ?? -1, 0, accuracy: 0.001)
        }
        audio.forgetLoop(category: .music)
        settings.musicEnabled = false; settings.musicEnabled = true
        try await Task.sleep(for: .milliseconds(250))
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).requested)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing)
    }
    func testResignationImmediatelyStopsAndGatesOwnedLoopsBeforeAnyQueuedTaskRuns() async throws {
        XCTAssertEqual(UIApplication.shared.applicationState, .active)
        let suite = "Fruitfolio.AudioInactive.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        defer {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            audio.resetAllAudio()
        }
        audio.play(.fruitBasketMusicbox, loop: true)
        _ = try XCTUnwrap(audio.debugLoopSnapshot(category: .music).volume)
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing)
        XCTAssertTrue(audio.debugLoopSnapshot(category: .music).requested)
        audio.play(.fruitBasketMusicbox, loop: true)
        audio.fadeIn(.fruitBasketMusicbox, duration: 0)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing)
        XCTAssertNil(audio.debugLoopSnapshot(category: .music).volume)
    }

    func testForegroundRestoresOnlyEligibleOwnedLoopsAcrossAllFourCategories() async throws {
        XCTAssertEqual(UIApplication.shared.applicationState, .active)
        let suite = "Fruitfolio.AudioRestoreAll.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        defer {
            NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            audio.resetAllAudio()
        }
        for id: FruitfolioAudioID in [.fruitBasketMusicbox, .fruitBasketRainAmbience, .buttonSoftPop, .typingSoft] {
            audio.play(id, loop: true)
        }
        for category in FruitfolioAudioCategory.allCases {
            _ = try XCTUnwrap(audio.debugLoopSnapshot(category: category).volume)
        }
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertFalse(audio.debugLoopSnapshot(category: category).playing)
            XCTAssertTrue(audio.debugLoopSnapshot(category: category).requested)
        }
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertTrue(audio.debugLoopSnapshot(category: category).playing,
                          "Owned effect loops must restore just like music, rain and typing")
        }
        NotificationCenter.default.post(name: UIApplication.willResignActiveNotification, object: nil)
        settings.soundEffectsEnabled = false
        audio.forgetLoop(category: .typingASMR)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .soundEffects).playing)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .typingASMR).requested)
    }
    func testSystemDeclinedResumeIsNotOverriddenByForegroundOrOneShotAndExplicitMusicIntentWorks() async throws {
        XCTAssertEqual(UIApplication.shared.applicationState, .active)
        let suite = "Fruitfolio.AudioSystemResume.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        let audio = AudioManager(settings: settings)
        let center = NotificationCenter.default
        func interrupt(_ type: AVAudioSession.InterruptionType, options: AVAudioSession.InterruptionOptions = []) {
            center.post(name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance(),
                userInfo: [AVAudioSessionInterruptionTypeKey: type.rawValue,
                           AVAudioSessionInterruptionOptionKey: options.rawValue])
        }
        defer {
            // Restore notification-driven owners as well as this test manager.
            center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
            interrupt(.began)
            interrupt(.ended, options: .shouldResume)
            audio.resetAllAudio()
        }
        audio.play(.fruitBasketMusicbox, loop: true)
        _ = try XCTUnwrap(audio.debugLoopSnapshot(category: .music).volume)
        interrupt(.began)
        interrupt(.ended)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing)
        audio.play(.buttonSoftPop)
        center.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing,
                       "An ordinary one-shot must not unlock held background music")
        audio.resumeAfterUserRequest(category: .music)
        XCTAssertTrue(audio.debugLoopSnapshot(category: .music).playing)
        interrupt(.began)
        interrupt(.ended, options: .shouldResume)
        XCTAssertTrue(audio.debugLoopSnapshot(category: .music).playing)
        settings.globallyMuted = true
        interrupt(.began)
        interrupt(.ended, options: .shouldResume)
        XCTAssertFalse(audio.debugLoopSnapshot(category: .music).playing,
                       "OS permission must never override the user's mute")
    }
    #endif

}
