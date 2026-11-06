import Combine
import Foundation

/// Persistent preferences needed to prove Prompt 03 architecture.
/// UserDefaults is injectable so unit tests never modify the user's real preferences.
@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let globallyMuted = "fruitfolio.settings.globallyMuted"
        static let musicEnabled = "fruitfolio.settings.musicEnabled"
        static let rainEnabled = "fruitfolio.settings.rainEnabled"
        static let soundEffectsEnabled = "fruitfolio.settings.soundEffectsEnabled"
        static let typingASMREnabled = "fruitfolio.settings.typingASMREnabled"
        static let musicVolume = "fruitfolio.settings.musicVolume"
        static let rainVolume = "fruitfolio.settings.rainVolume"
        static let soundEffectsVolume = "fruitfolio.settings.soundEffectsVolume"
        static let typingVolume = "fruitfolio.settings.typingVolume"
        static let reduceAnimationOverride = "fruitfolio.settings.reduceAnimationOverride"
        static let onboardingCompleted = "fruitfolio.settings.onboardingCompleted"
    }

    private let defaults: UserDefaults

    @Published var globallyMuted: Bool { didSet { defaults.set(globallyMuted, forKey: Key.globallyMuted) } }
    @Published var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: Key.musicEnabled) } }
    @Published var rainEnabled: Bool { didSet { defaults.set(rainEnabled, forKey: Key.rainEnabled) } }
    @Published var soundEffectsEnabled: Bool { didSet { defaults.set(soundEffectsEnabled, forKey: Key.soundEffectsEnabled) } }
    @Published var typingASMREnabled: Bool { didSet { defaults.set(typingASMREnabled, forKey: Key.typingASMREnabled) } }

    @Published var musicVolume: Double { didSet { persistClamped(musicVolume, key: Key.musicVolume) } }
    @Published var rainVolume: Double { didSet { persistClamped(rainVolume, key: Key.rainVolume) } }
    @Published var soundEffectsVolume: Double { didSet { persistClamped(soundEffectsVolume, key: Key.soundEffectsVolume) } }
    @Published var typingVolume: Double { didSet { persistClamped(typingVolume, key: Key.typingVolume) } }

    @Published var reduceAnimationOverride: Bool { didSet { defaults.set(reduceAnimationOverride, forKey: Key.reduceAnimationOverride) } }
    @Published var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) } }
    @Published var language: FruitfolioLanguage { didSet { FruitfolioLanguagePreferences.save(language, to: defaults) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.globallyMuted = Self.bool(defaults, key: Key.globallyMuted, fallback: false)
        self.musicEnabled = Self.bool(defaults, key: Key.musicEnabled, fallback: true)
        self.rainEnabled = Self.bool(defaults, key: Key.rainEnabled, fallback: true)
        self.soundEffectsEnabled = Self.bool(defaults, key: Key.soundEffectsEnabled, fallback: true)
        self.typingASMREnabled = Self.bool(defaults, key: Key.typingASMREnabled, fallback: true)
        self.musicVolume = Self.double(defaults, key: Key.musicVolume, fallback: 0.35)
        self.rainVolume = Self.double(defaults, key: Key.rainVolume, fallback: 0.20)
        self.soundEffectsVolume = Self.double(defaults, key: Key.soundEffectsVolume, fallback: 0.15)
        self.typingVolume = Self.double(defaults, key: Key.typingVolume, fallback: 0.08)
        self.reduceAnimationOverride = Self.bool(defaults, key: Key.reduceAnimationOverride, fallback: false)
        self.onboardingCompleted = Self.bool(defaults, key: Key.onboardingCompleted, fallback: false)
        self.language = FruitfolioLanguagePreferences.load(from: defaults)
    }

    /// Resolve a catalog string for an explicit Fruitfolio language. SwiftUI's
    /// environment locale handles most Text/Button literals automatically; this
    /// helper is for runtime/deterministic strings that are built outside a View.
    func localized(_ key: String, fallback: String? = nil) -> String {
        FruitfolioLocalization.localized(key, language: language, fallback: fallback)
    }

    func allowsAudio(_ category: FruitfolioAudioCategory) -> Bool {
        guard !globallyMuted else { return false }
        switch category {
        case .music: return musicEnabled
        case .rainAmbience: return rainEnabled
        case .soundEffects: return soundEffectsEnabled
        case .typingASMR: return typingASMREnabled
        }
    }

    private func persistClamped(_ value: Double, key: String) {
        defaults.set(Self.clamp(value), forKey: key)
    }

    private static func bool(_ defaults: UserDefaults, key: String, fallback: Bool) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }

    private static func double(_ defaults: UserDefaults, key: String, fallback: Double) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return clamp(defaults.double(forKey: key))
    }

    private static func clamp(_ value: Double) -> Double {
        value.isFinite ? min(max(value, 0), 1) : 0
    }
}
