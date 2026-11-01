import Combine
import Foundation

enum FruitfolioLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"
    case portuguese = "pt"
    case french = "fr"
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case german = "de"
    case italian = "it"
    case vietnamese = "vi"
    case filipino = "fil"
    case persian = "fa"
    case arabic = "ar"
    case hindi = "hi"
    case bengali = "bn"
    case gujarati = "gu"
    case kannada = "kn"
    case malayalam = "ml"
    case marathi = "mr"
    case punjabi = "pa"
    case tamil = "ta"
    case telugu = "te"
    case urdu = "ur"
    case amharic = "am"
    case hausa = "ha"
    case igbo = "ig"
    case swahili = "sw"
    case yoruba = "yo"
    case zulu = "zu"
    case samoan = "sm"
    case tongan = "to"
    case fijian = "fj"
    case hawaiian = "haw"
    case maori = "mi"
    case chamorro = "ch"
    case marshallese = "mh"
    case tokPisin = "tpi"
    case tahitian = "ty"
    case palauan = "pau"
    case cookIslandsMaori = "rar"
    case niuean = "niu"
    case tuvaluan = "tvl"
    case kiribati = "gil"
    case bislama = "bi"

    var id: String { rawValue }
    var localeIdentifier: String { rawValue }
    var isRightToLeft: Bool { self == .persian || self == .arabic || self == .urdu }

    /// Native/autonym labels deliberately remain recognizable even when the current UI language changes.
    var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .french: return "Français"
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .vietnamese: return "Tiếng Việt"
        case .filipino: return "Filipino"
        case .persian: return "فارسی"
        case .arabic: return "العربية"
        case .hindi: return "हिन्दी"
        case .bengali: return "বাংলা"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .marathi: return "मराठी"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .urdu: return "اردو"
        case .amharic: return "አማርኛ"
        case .hausa: return "Hausa"
        case .igbo: return "Igbo"
        case .swahili: return "Kiswahili"
        case .yoruba: return "Yorùbá"
        case .zulu: return "isiZulu"
        case .samoan: return "Gagana Sāmoa"
        case .tongan: return "Lea faka-Tonga"
        case .fijian: return "Vosa Vakaviti"
        case .hawaiian: return "ʻŌlelo Hawaiʻi"
        case .maori: return "Te Reo Māori"
        case .chamorro: return "CHamoru"
        case .marshallese: return "Kajin M̧ajeļ"
        case .tokPisin: return "Tok Pisin"
        case .tahitian: return "Reo Tahiti"
        case .palauan: return "Tekoi er a Belau"
        case .cookIslandsMaori: return "Māori Kūki ‘Āirani"
        case .niuean: return "Ko e vagahau Niuē"
        case .tuvaluan: return "Te Gagana Tuuvalu"
        case .kiribati: return "Te Taetae ni Kiribati"
        case .bislama: return "Bislama"
        }
    }
}

enum FruitfolioLanguagePreferences {
    static let defaultsKey = "fruitfolio.settings.language"

    static var current: FruitfolioLanguage {
        guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
              let language = FruitfolioLanguage(rawValue: raw) else { return .english }
        return language
    }
}

/// Persistent preferences needed to prove Prompt 03 architecture.
/// UserDefaults is injectable so unit tests never modify the user's real preferences.
@MainActor
final class SettingsStore: ObservableObject {
    private enum Key {
        static let allAudioMuted = "fruitfolio.settings.allAudioMuted"
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
        static let language = FruitfolioLanguagePreferences.defaultsKey
    }

    private let defaults: UserDefaults

    @Published var allAudioMuted: Bool { didSet { defaults.set(allAudioMuted, forKey: Key.allAudioMuted) } }
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
    @Published var language: FruitfolioLanguage { didSet { defaults.set(language.rawValue, forKey: Key.language) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.allAudioMuted = Self.bool(defaults, key: Key.allAudioMuted, fallback: false)
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
        self.language = defaults.string(forKey: Key.language).flatMap(FruitfolioLanguage.init(rawValue:)) ?? .english
    }

    /// Resolve a catalog string for an explicit Fruitfolio language. SwiftUI's
    /// environment locale handles most Text/Button literals automatically; this
    /// helper is for runtime/deterministic strings that are built outside a View.
    func localized(_ key: String, fallback: String? = nil) -> String {
        FruitfolioLocalization.localized(key, language: language, fallback: fallback)
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
        min(max(value, 0), 1)
    }
}
