import AVFoundation
import Combine
import Foundation
import UIKit

@MainActor
final class AudioManager: ObservableObject {

    private struct LoopRequest {
        let id: FruitfolioAudioID
        let bundle: Bundle
    }

    private weak var settings: SettingsStore?
    private var settingsCancellables = Set<AnyCancellable>()

    private var oneShotPlayers: [FruitfolioAudioCategory: [AVAudioPlayer]] = [:]
    private var loopPlayers: [FruitfolioAudioCategory: AVAudioPlayer] = [:]
    private var desiredLoops: [FruitfolioAudioCategory: LoopRequest] = [:]
    private var suspendedLoopCategories = Set<FruitfolioAudioCategory>()
    private var audioInterrupted = false
    private var applicationIsActive = true
    private var lastTypingTick: TimeInterval = -Double.infinity
    private var notificationObservers: [NSObjectProtocol] = []

    init(settings: SettingsStore? = nil) {
        configureAudioSession()
        observeAudioLifecycle()

        if let settings {
            attach(settings: settings)
        }
    }

    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func attach(settings: SettingsStore) {
        self.settings = settings
        observe(settings: settings)
        synchronizePlaybackWithSettings()
    }

    func play(
        _ id: FruitfolioAudioID,
        loop: Bool = false,
        bundle: Bundle = .main
    ) {
        let category = category(for: id)

        if loop || isContinuousCategory(category) {
            suspendedLoopCategories.remove(category)
            desiredLoops[category] = LoopRequest(
                id: id,
                bundle: bundle
            )

            guard isEnabled(category) else {
                return
            }

            if let existingPlayer = loopPlayers[category] {
                let targetVolume = volume(for: category)

                if !existingPlayer.isPlaying {
                    existingPlayer.prepareToPlay()

                    let didPlay = existingPlayer.play()

                    debugLog(
                        "restart \(semanticKey(for: id)) = \(didPlay)"
                    )

                    if !didPlay {
                        startLoop(
                            id,
                            category: category,
                            bundle: bundle,
                            fadeDuration: 0
                        )

                        return
                    }
                }

                existingPlayer.setVolume(
                    targetVolume,
                    fadeDuration: 0.12
                )

                return
            }

            startLoop(
                id,
                category: category,
                bundle: bundle,
                fadeDuration: 0
            )

            return
        }

        guard isEnabled(category) else {
            return
        }

        playOneShot(
            id,
            category: category,
            bundle: bundle
        )
    }

    /// Reuses one player and throttles dense character updates to avoid audio piles.
    func playTypingTick(bundle: Bundle = .main) {
        guard !audioInterrupted, applicationIsActive, isEnabled(.typingASMR) else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastTypingTick >= 0.08 else { return }
        lastTypingTick = now
        if let player = oneShotPlayers[.typingASMR]?.first {
            player.volume = volume(for: .typingASMR)
            player.currentTime = 0
            _ = player.play()
        } else {
            playOneShot(.typingSoft, category: .typingASMR, bundle: bundle)
        }
    }

    #if DEBUG
    var typingPlaybackState: (playerCount: Int, isPlaying: Bool, volume: Float) {
        let players = oneShotPlayers[.typingASMR] ?? []
        return (players.count, players.contains(where: \.isPlaying), players.first?.volume ?? 0)
    }
    #endif

    func fadeIn(
        _ id: FruitfolioAudioID,
        duration: TimeInterval,
        bundle: Bundle = .main
    ) {
        let category = category(for: id)

        if isContinuousCategory(category) {
            suspendedLoopCategories.remove(category)
            desiredLoops[category] = LoopRequest(
                id: id,
                bundle: bundle
            )

            guard isEnabled(category) else {
                return
            }

            if let existingPlayer = loopPlayers[category] {
                let targetVolume = volume(for: category)

                if !existingPlayer.isPlaying {
                    existingPlayer.volume =
                        duration > 0
                        ? 0
                        : targetVolume

                    existingPlayer.prepareToPlay()

                    let didPlay = existingPlayer.play()

                    debugLog(
                        "restart \(semanticKey(for: id)) = \(didPlay)"
                    )

                    if !didPlay {
                        startLoop(
                            id,
                            category: category,
                            bundle: bundle,
                            fadeDuration: max(duration, 0)
                        )

                        return
                    }
                }

                existingPlayer.setVolume(
                    targetVolume,
                    fadeDuration: max(duration, 0)
                )

                return
            }

            startLoop(
                id,
                category: category,
                bundle: bundle,
                fadeDuration: max(duration, 0)
            )

            return
        }

        guard isEnabled(category) else {
            return
        }

        playOneShot(
            id,
            category: category,
            bundle: bundle
        )
    }

    func fadeOut(
        category: FruitfolioAudioCategory,
        duration: TimeInterval
    ) {
        suspendedLoopCategories.insert(category)
        guard let player = loopPlayers[category] else {
            return
        }

        player.setVolume(
            0,
            fadeDuration: max(duration, 0)
        )
    }

    func pause(
        category: FruitfolioAudioCategory
    ) {
        if isContinuousCategory(category) {
            loopPlayers[category]?.setVolume(
                0,
                fadeDuration: 0.12
            )
        }

        if let players = oneShotPlayers[category] {
            for player in players {
                player.pause()
            }
        }
    }

    func stop(
        category: FruitfolioAudioCategory
    ) {
        stopOneShots(
            category: category
        )

        stopPhysicalLoop(
            category: category
        )
    }

    func stopAll() {
        for category in Array(oneShotPlayers.keys) {
            stopOneShots(
                category: category
            )
        }

        for category in Array(loopPlayers.keys) {
            stopPhysicalLoop(
                category: category
            )
        }
    }

    func forgetLoop(
        category: FruitfolioAudioCategory
    ) {
        suspendedLoopCategories.remove(category)
        stopPhysicalLoop(
            category: category
        )

        desiredLoops[category] = nil
    }

    func resetAllAudio() {
        stopAll()
        desiredLoops.removeAll()
        suspendedLoopCategories.removeAll()
    }

    // MARK: - Settings

    private func observe(
        settings: SettingsStore
    ) {
        settingsCancellables.removeAll()

        settings.$musicEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.handleContinuousSettingChange(
                    category: .music,
                    enabled: enabled
                )
            }
            .store(
                in: &settingsCancellables
            )

        settings.$rainEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                self?.handleContinuousSettingChange(
                    category: .rainAmbience,
                    enabled: enabled
                )
            }
            .store(
                in: &settingsCancellables
            )

        settings.$soundEffectsEnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else {
                    return
                }

                if !enabled {
                    self.stopOneShots(
                        category: .soundEffects
                    )
                }
            }
            .store(
                in: &settingsCancellables
            )

        settings.$typingASMREnabled
            .removeDuplicates()
            .sink { [weak self] enabled in
                guard let self else {
                    return
                }

                if !enabled {
                    self.stopOneShots(
                        category: .typingASMR
                    )
                }
            }
            .store(
                in: &settingsCancellables
            )

        settings.$musicVolume
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyCurrentVolume(
                    to: .music
                )
            }
            .store(
                in: &settingsCancellables
            )

        settings.$rainVolume
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyCurrentVolume(
                    to: .rainAmbience
                )
            }
            .store(
                in: &settingsCancellables
            )

        settings.$soundEffectsVolume
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyCurrentVolume(
                    to: .soundEffects
                )
            }
            .store(
                in: &settingsCancellables
            )

        settings.$typingVolume
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.applyCurrentVolume(
                    to: .typingASMR
                )
            }
            .store(
                in: &settingsCancellables
            )
    }

    private func handleContinuousSettingChange(
        category: FruitfolioAudioCategory,
        enabled: Bool
    ) {
        if enabled {
            resumeContinuousAudio(
                category: category
            )
        } else {
            muteContinuousAudio(
                category: category
            )
        }
    }

    private func muteContinuousAudio(
        category: FruitfolioAudioCategory
    ) {
        guard let player = loopPlayers[category] else {
            return
        }

        player.setVolume(
            0,
            fadeDuration: 0.12
        )

        debugLog(
            "muted \(String(describing: category))"
        )
    }

    private func resumeContinuousAudio(
        category: FruitfolioAudioCategory
    ) {
        guard !audioInterrupted, applicationIsActive,
              !suspendedLoopCategories.contains(category) else {
            return
        }

        if let player = loopPlayers[category] {
            let targetVolume = volume(for: category)

            if !player.isPlaying {
                player.prepareToPlay()

                let didPlay = player.play()

                debugLog(
                    "restarted \(String(describing: category)) = \(didPlay)"
                )

                if !didPlay {
                    guard let request = desiredLoops[category] else {
                        debugLog(
                            "no stored loop request for \(String(describing: category))"
                        )

                        return
                    }

                    startLoop(
                        request.id,
                        category: category,
                        bundle: request.bundle,
                        fadeDuration: 0.20
                    )

                    return
                }
            }

            player.setVolume(
                targetVolume,
                fadeDuration: 0.12
            )

            debugLog(
                "unmuted \(String(describing: category))"
            )

            return
        }

        guard let request = desiredLoops[category] else {
            debugLog(
                "no stored loop request for \(String(describing: category))"
            )

            return
        }

        startLoop(
            request.id,
            category: category,
            bundle: request.bundle,
            fadeDuration: 0.20
        )
    }

    private func synchronizePlaybackWithSettings() {
        if isEnabled(.music) {
            resumeContinuousAudio(
                category: .music
            )
        } else {
            muteContinuousAudio(
                category: .music
            )
        }

        if isEnabled(.rainAmbience) {
            resumeContinuousAudio(
                category: .rainAmbience
            )
        } else {
            muteContinuousAudio(
                category: .rainAmbience
            )
        }

        if !isEnabled(.soundEffects) {
            stopOneShots(
                category: .soundEffects
            )
        }

        if !isEnabled(.typingASMR) {
            stopOneShots(
                category: .typingASMR
            )
        }
    }

    // MARK: - Continuous playback

    private func startLoop(
        _ id: FruitfolioAudioID,
        category: FruitfolioAudioCategory,
        bundle: Bundle,
        fadeDuration: TimeInterval
    ) {
        guard !audioInterrupted, applicationIsActive else { return }
        configureAudioSession()

        stopPhysicalLoop(
            category: category
        )

        do {
            let player = try makePlayer(for: id, bundle: bundle)

            player.numberOfLoops = -1
            player.prepareToPlay()

            let targetVolume =
                volume(for: category)

            if fadeDuration > 0 {
                player.volume = 0
            } else {
                player.volume = targetVolume
            }

            loopPlayers[category] =
                player

            let didPlay =
                player.play()

            debugLog(
                "start \(semanticKey(for: id)) = \(didPlay)"
            )

            guard didPlay else {
                loopPlayers[category] = nil
                return
            }

            if fadeDuration > 0 {
                player.setVolume(
                    targetVolume,
                    fadeDuration: fadeDuration
                )
            }

        } catch {
            loopPlayers[category] = nil

            debugLog(
                "loop playback failed for \(semanticKey(for: id)): \(error)"
            )
        }
    }

    private func stopPhysicalLoop(
        category: FruitfolioAudioCategory
    ) {
        guard let player = loopPlayers[category] else {
            return
        }

        player.stop()
        player.currentTime = 0

        loopPlayers[category] = nil
    }

    // MARK: - One-shot playback

    private func playOneShot(
        _ id: FruitfolioAudioID,
        category: FruitfolioAudioCategory,
        bundle: Bundle
    ) {
        guard !audioInterrupted, applicationIsActive else { return }
        configureAudioSession()

        do {
            pruneFinishedOneShots(
                category: category
            )

            let player = try makePlayer(for: id, bundle: bundle)

            player.numberOfLoops = 0

            player.volume =
                volume(for: category)

            player.prepareToPlay()

            oneShotPlayers[
                category,
                default: []
            ].append(player)

            let didPlay =
                player.play()

            debugLog(
                "one-shot \(semanticKey(for: id)) = \(didPlay)"
            )

            if !didPlay {
                pruneFinishedOneShots(
                    category: category
                )
            }

        } catch {
            pruneFinishedOneShots(
                category: category
            )

            debugLog(
                "one-shot playback failed for \(semanticKey(for: id)): \(error)"
            )
        }
    }

    private func stopOneShots(
        category: FruitfolioAudioCategory
    ) {
        guard let players =
                oneShotPlayers[category] else {
            return
        }

        for player in players {
            player.stop()
            player.currentTime = 0
        }

        oneShotPlayers[category] = []
    }

    private func pruneFinishedOneShots(
        category: FruitfolioAudioCategory
    ) {
        oneShotPlayers[category] =
            oneShotPlayers[
                category,
                default: []
            ]
            .filter {
                $0.isPlaying
            }
    }

    // MARK: - Current settings

    private func isEnabled(
        _ category: FruitfolioAudioCategory
    ) -> Bool {
        guard let settings else {
            return true
        }

        switch category {

        case .music:
            return settings.musicEnabled

        case .rainAmbience:
            return settings.rainEnabled

        case .soundEffects:
            return settings.soundEffectsEnabled

        case .typingASMR:
            return settings.typingASMREnabled
        }
    }

    private func volume(
        for category: FruitfolioAudioCategory
    ) -> Float {
        guard let settings else {
            switch category {

            case .music:
                return 0.35

            case .rainAmbience:
                return 0.20

            case .soundEffects:
                return 0.15

            case .typingASMR:
                return 0.08
            }
        }

        let value: Double

        switch category {

        case .music:
            value = settings.musicVolume

        case .rainAmbience:
            value = settings.rainVolume

        case .soundEffects:
            value = settings.soundEffectsVolume

        case .typingASMR:
            value = settings.typingVolume
        }

        return Float(
            min(
                max(value, 0),
                1
            )
        )
    }

    private func applyCurrentVolume(
        to category: FruitfolioAudioCategory
    ) {
        let currentVolume =
            isEnabled(category)
            ? volume(for: category)
            : 0

        loopPlayers[category]?.volume =
            currentVolume

        if let players = oneShotPlayers[category] {
            for player in players {
                player.volume =
                    currentVolume
            }
        }
    }

    private func isContinuousCategory(
        _ category: FruitfolioAudioCategory
    ) -> Bool {
        switch category {

        case .music,
             .rainAmbience:
            return true

        case .soundEffects,
             .typingASMR:
            return false
        }
    }

    // MARK: - Category lookup

    private func category(
        for id: FruitfolioAudioID
    ) -> FruitfolioAudioCategory {
        FruitfolioAudioDesign
            .descriptors[id]?
            .category
            ?? .soundEffects
    }

    // MARK: - File lookup

    private func semanticKey(
        for id: FruitfolioAudioID
    ) -> String {
        String(describing: id)
    }

    private func canonicalFileStem(
        for id: FruitfolioAudioID
    ) -> String {
        let key =
            semanticKey(for: id)

        let mapping: [String: String] = [
            "typingSoft":
                "audio_typing_soft",

            "buttonSoftPop":
                "audio_button_soft_pop",

            "pageTurn":
                "audio_page_turn",

            "bookOpen":
                "audio_book_open",

            "bookClose":
                "audio_book_close",

            "popupOpen":
                "audio_popup_open",

            "popupClose":
                "audio_popup_close",

            "successChime":
                "audio_success_chime",

            "gentleCheer":
                "audio_gentle_cheer",

            "errorSoft":
                "audio_error_soft",

            "starChime":
                "audio_star_chime",

            "vineRustle":
                "audio_vine_rustle",

            "bubblePop":
                "audio_bubble_pop",

            "fruitCatch":
                "audio_fruit_catch",

            "basketReveal":
                "audio_basket_reveal",

            "gameCorrect":
                "audio_game_correct",

            "gameIncorrect":
                "audio_game_incorrect",

            "fruitBasketMusicbox":
                "audio_fruitbasket_musicbox",

            "fruitBasketRainAmbience":
                "audio_fruitbasket_rain",

            "fruitBasketRainObstacle":
                "audio_fruitbasket_rain_OBSTACLE",

            "fruitBasketWind":
                "audio_fruitbasket_wind_gust",

            "notificationSoftSparkle":
                "audio_notification",

            "ambientSoft":
                "audio_ambient_soft",

            "audio_typing_soft":
                "audio_typing_soft",

            "audio_button_soft_pop":
                "audio_button_soft_pop",

            "audio_page_turn":
                "audio_page_turn",

            "audio_book_open":
                "audio_book_open",

            "audio_book_close":
                "audio_book_close",

            "audio_popup_open":
                "audio_popup_open",

            "audio_popup_close":
                "audio_popup_close",

            "audio_success_chime":
                "audio_success_chime",

            "audio_gentle_cheer":
                "audio_gentle_cheer",

            "audio_error_soft":
                "audio_error_soft",

            "audio_star_chime":
                "audio_star_chime",

            "audio_vine_rustle":
                "audio_vine_rustle",

            "audio_bubble_pop":
                "audio_bubble_pop",

            "audio_fruit_catch":
                "audio_fruit_catch",

            "audio_basket_reveal":
                "audio_basket_reveal",

            "audio_game_correct":
                "audio_game_correct",

            "audio_game_incorrect":
                "audio_game_incorrect",

            "audio_fruitbasket_musicbox":
                "audio_fruitbasket_musicbox",

            "audio_fruitbasket_rain":
                "audio_fruitbasket_rain",

            "audio_fruitbasket_rain_OBSTACLE":
                "audio_fruitbasket_rain_OBSTACLE",

            "audio_fruitbasket_wind_gust":
                "audio_fruitbasket_wind_gust",

            "audio_notification":
                "audio_notification",

            "audio_ambient_soft":
                "audio_ambient_soft"
        ]

        return mapping[key] ?? key
    }

    private func audioURL(
        for id: FruitfolioAudioID,
        bundle: Bundle
    ) -> URL? {
        let resourceName =
            canonicalFileStem(for: id)

        let subdirectories: [String?] = [
            nil,
            "Audio",
            "Audio:",
            "Fruitfolio Assets/Audio",
            "Fruitfolio Assets/Audio:"
        ]

        for subdirectory in subdirectories {
            if let url = bundle.url(
                forResource: resourceName,
                withExtension: "mp3",
                subdirectory: subdirectory
            ) {
                return url
            }
        }

        return nil
    }

    // MARK: - Compiled asset-catalog data and audio lifecycle

    private func makePlayer(for id: FruitfolioAudioID, bundle: Bundle) throws -> AVAudioPlayer {
        let name = canonicalFileStem(for: id)
        // Xcode .dataset audio is compiled as NSDataAsset, not necessarily a loose .mp3.
        if let asset = NSDataAsset(name: name, bundle: bundle) {
            return try AVAudioPlayer(data: asset.data)
        }
        if let url = audioURL(for: id, bundle: bundle) {
            return try AVAudioPlayer(contentsOf: url)
        }
        throw NSError(domain: "FruitfolioAudio", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "Missing audio asset: \(name)"])
    }

    private func observeAudioLifecycle() {
        let center = NotificationCenter.default
        notificationObservers.append(center.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(), queue: .main
        ) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self,
                      let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                      let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
                switch type {
                case .began:
                    self.audioInterrupted = true
                    self.stopAll()
                case .ended:
                    self.audioInterrupted = false
                    self.configureAudioSession()
                    self.restoreDesiredLoops()
                @unknown default: break
                }
            }
        })
        notificationObservers.append(center.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.applicationIsActive = false
                self?.stopAll()
            }
        })
        notificationObservers.append(center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.applicationIsActive = true
                self.configureAudioSession()
                self.restoreDesiredLoops()
            }
        })
    }

    private func restoreDesiredLoops() {
        guard !audioInterrupted, applicationIsActive else { return }
        for category in [FruitfolioAudioCategory.music, .rainAmbience] {
            guard isEnabled(category),
                  !suspendedLoopCategories.contains(category),
                  let request = desiredLoops[category] else { continue }
            startLoop(request.id, category: category,
                      bundle: request.bundle, fadeDuration: 0.20)
        }
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        do {
            let session =
                AVAudioSession.sharedInstance()

            try session.setCategory(
                .ambient,
                mode: .default
            )

            try session.setActive(true)

        } catch {
            debugLog(
                "audio session configuration failed: \(error)"
            )
        }
    }

    // MARK: - Debug

    private func debugLog(
        _ message: String
    ) {
        #if DEBUG
        print(
            "Fruitfolio AudioManager: \(message)"
        )
        #endif
    }
}
