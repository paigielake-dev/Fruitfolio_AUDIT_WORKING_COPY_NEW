#if canImport(Combine)
import Combine
#endif
import Foundation

/// Persistent preferences needed to prove Prompt 03 architecture.
/// UserDefaults is injectable so unit tests never modify the user's real preferences.
@MainActor
final class SettingsStore {
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

    #if canImport(Combine)
    @Published
    #endif
    var globallyMuted: Bool { didSet { defaults.set(globallyMuted, forKey: Key.globallyMuted) } }
    #if canImport(Combine)
    @Published
    #endif
    var musicEnabled: Bool { didSet { defaults.set(musicEnabled, forKey: Key.musicEnabled) } }
    #if canImport(Combine)
    @Published
    #endif
    var rainEnabled: Bool { didSet { defaults.set(rainEnabled, forKey: Key.rainEnabled) } }
    #if canImport(Combine)
    @Published
    #endif
    var soundEffectsEnabled: Bool { didSet { defaults.set(soundEffectsEnabled, forKey: Key.soundEffectsEnabled) } }
    #if canImport(Combine)
    @Published
    #endif
    var typingASMREnabled: Bool { didSet { defaults.set(typingASMREnabled, forKey: Key.typingASMREnabled) } }

    #if canImport(Combine)
    @Published
    #endif
    var musicVolume: Double { didSet { persistClamped(musicVolume, key: Key.musicVolume) } }
    #if canImport(Combine)
    @Published
    #endif
    var rainVolume: Double { didSet { persistClamped(rainVolume, key: Key.rainVolume) } }
    #if canImport(Combine)
    @Published
    #endif
    var soundEffectsVolume: Double { didSet { persistClamped(soundEffectsVolume, key: Key.soundEffectsVolume) } }
    #if canImport(Combine)
    @Published
    #endif
    var typingVolume: Double { didSet { persistClamped(typingVolume, key: Key.typingVolume) } }

    #if canImport(Combine)
    @Published
    #endif
    var reduceAnimationOverride: Bool { didSet { defaults.set(reduceAnimationOverride, forKey: Key.reduceAnimationOverride) } }
    #if canImport(Combine)
    @Published
    #endif
    var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) } }
    /// Transient process state, deliberately never written to user preferences.
    #if canImport(Combine)
    @Published
    #endif
    var translationPausedForMemoryPressure = false
    #if canImport(Combine)
    @Published
    #endif
    var translationPausedForLifecycle = false
    var translationInferenceAllowed: Bool {
        !translationPausedForMemoryPressure && !translationPausedForLifecycle
    }
    #if canImport(Combine)
    @Published
    #endif
    private(set) var languagePreferenceNeedsReview = false
    #if canImport(Combine)
    @Published
    #endif
    private(set) var languagePersistenceMessage: String? = nil
    #if canImport(Combine)
    @Published
    #endif
    var language: FruitfolioLanguage {
        didSet {
            if FruitfolioLanguagePreferences.save(language, to: defaults) {
                languagePreferenceNeedsReview = false
                languagePersistenceMessage = nil
            } else {
                // The saved authority may still contain the old value, or an
                // external replacement. Never repair or overwrite it here.
                language = FruitfolioLanguagePreferences.load(from: defaults)
                languagePreferenceNeedsReview = FruitfolioLanguagePreferences.needsReview(in: defaults)
                languagePersistenceMessage = "the language change could not be confirmed. review the saved selection before trying again."
            }
        }
    }

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
        self.languagePreferenceNeedsReview = FruitfolioLanguagePreferences.needsReview(in: defaults)
    }

    #if DEBUG
    /// Actual private-suite readback for disposable control QA; no health data.
    var debugStoredEffects: (enabled: Bool, volume: Double) {
        (defaults.bool(forKey: Key.soundEffectsEnabled), defaults.double(forKey: Key.soundEffectsVolume))
    }
    #endif

    /// Resolve a catalog string for an explicit Fruitfolio language. SwiftUI's
    /// environment locale handles most Text/Button literals automatically; this
    /// helper is for runtime/deterministic strings that are built outside a View.
    func localized(_ key: String, fallback: String? = nil, bundle: Bundle = .main) -> String {
        FruitfolioLocalization.localized(key, language: language, fallback: fallback, bundle: bundle)
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

    /// The actual audio engine and portable policy tests share one finite,
    /// category-specific gate. Stored preferences remain independent of mute.
    func playbackVolume(for category: FruitfolioAudioCategory) -> Float {
        guard allowsAudio(category) else { return 0 }
        let raw: Double
        switch category {
        case .music: raw = musicVolume
        case .rainAmbience: raw = rainVolume
        case .soundEffects: raw = soundEffectsVolume
        case .typingASMR: raw = typingVolume
        }
        return Float(Self.clamp(raw))
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

#if canImport(Combine)
extension SettingsStore: ObservableObject {}
#endif

#if DEBUG
/// Normal UI-test preferences follow root ownership, not one appearance.
/// Explicit UUID restart fixtures require cleanup after relaunch verification.
/// Production defaults never enter this authority.
@MainActor
final class FruitfolioRegressionPreferenceSuite {
    let suiteName: String
    let defaults: UserDefaults?
    let isPersistentFixture: Bool
    private let cleanupOnRelease: Bool

    nonisolated static func restartToken(arguments: [String]) -> UUID? {
        guard arguments.contains("-fruitfolioLanguagePersistenceQA"),
              let index = arguments.firstIndex(of: "-fruitfolioLanguagePersistenceToken"),
              index + 1 < arguments.count else { return nil }
        return UUID(uuidString: arguments[index + 1])
    }

    init(persistenceToken: UUID? = nil) {
        let name = persistenceToken.map { "fruitfolio.uiQA.languageRestart." + $0.uuidString }
            ?? ("fruitfolio.uiQA." + UUID().uuidString)
        suiteName = name
        defaults = UserDefaults(suiteName: name)
        isPersistentFixture = persistenceToken != nil
        cleanupOnRelease = persistenceToken == nil
    }

    func cleanUp() {
        defaults?.removePersistentDomain(forName: suiteName)
    }

    deinit {
        if cleanupOnRelease {
            UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        }
    }
}

#if canImport(Combine)
extension FruitfolioRegressionPreferenceSuite: ObservableObject {}
#endif
#endif
