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
    case thai = "th"
    case mongolian = "mn"
    case indonesian = "id"
    case russian = "ru"
    case polish = "pl"
    case dutch = "nl"
    case swedish = "sv"
    case ukrainian = "uk"
    case turkish = "tr"
    case kurdishKurmanji = "ku"
    case kurdishSorani = "ckb"
    case hebrew = "he"
    case quechua = "qu"
    case guarani = "gn"
    case aymara = "ay"


    var id: String { rawValue }
    var localeIdentifier: String { rawValue }
    /// Exact official model tokenizer tags. Script selection is not collapsed
    /// into a generic Chinese target; absent language tags remain unsupported.
    var madladTargetCode: String {
        switch self {
        case .chineseSimplified: return "zh"
        case .chineseTraditional: return "zh_Hant"
        default: return rawValue
        }
    }
    var isRightToLeft: Bool { self == .persian || self == .arabic || self == .urdu || self == .hebrew || self == .kurdishSorani }

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
        case .thai: return "ไทย"
        case .mongolian: return "Монгол хэл"
        case .indonesian: return "Bahasa Indonesia"
        case .russian: return "Русский"
        case .polish: return "Polski"
        case .dutch: return "Nederlands"
        case .swedish: return "Svenska"
        case .ukrainian: return "Українська"
        case .turkish: return "Türkçe"
        case .kurdishKurmanji: return "Kurmancî"
        case .kurdishSorani: return "کوردی (سۆرانی)"
        case .hebrew: return "עברית"
        case .quechua: return "Runasimi"
        case .guarani: return "Avañe’ẽ"
        case .aymara: return "Aymar aru"

        }
    }
}

enum FruitfolioLanguagePreferences {
    static let defaultsKey = "fruitfolio.settings.language"

    static func decodeStoredLanguage(_ value: Any?) -> FruitfolioLanguage? {
        guard let raw = value as? String else { return nil }
        return FruitfolioLanguage(rawValue: raw)
            ?? FruitfolioLanguage(rawValue: raw.replacingOccurrences(of: "_", with: "-"))
    }

    static var current: FruitfolioLanguage {
        decodeStoredLanguage(UserDefaults.standard.object(forKey: defaultsKey)) ?? .english
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

    @Published var musicVolume: Double {
        didSet {
            let normalized = Self.clamp(musicVolume)
            if musicVolume != normalized { musicVolume = normalized }
            defaults.set(normalized, forKey: Key.musicVolume)
        }
    }
    @Published var rainVolume: Double {
        didSet {
            let normalized = Self.clamp(rainVolume)
            if rainVolume != normalized { rainVolume = normalized }
            defaults.set(normalized, forKey: Key.rainVolume)
        }
    }
    @Published var soundEffectsVolume: Double {
        didSet {
            let normalized = Self.clamp(soundEffectsVolume)
            if soundEffectsVolume != normalized { soundEffectsVolume = normalized }
            defaults.set(normalized, forKey: Key.soundEffectsVolume)
        }
    }
    @Published var typingVolume: Double {
        didSet {
            let normalized = Self.clamp(typingVolume)
            if typingVolume != normalized { typingVolume = normalized }
            defaults.set(normalized, forKey: Key.typingVolume)
        }
    }

    @Published var reduceAnimationOverride: Bool { didSet { defaults.set(reduceAnimationOverride, forKey: Key.reduceAnimationOverride) } }
    @Published var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) } }
    @Published private(set) var languagePreferenceWarning: String? = nil
    @Published var language: FruitfolioLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Key.language)
            languagePreferenceWarning = nil
        }
    }

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
        let storedLanguage = defaults.object(forKey: Key.language)
        let decodedLanguage = FruitfolioLanguagePreferences.decodeStoredLanguage(storedLanguage)
        self.language = decodedLanguage ?? .english
        if storedLanguage != nil && decodedLanguage == nil {
            languagePreferenceWarning = "your saved language setting could not be recognized. English is being used for now, and the original setting is preserved. choose a language to replace it."
        }
    }

    /// Resolve a catalog string for an explicit Fruitfolio language. SwiftUI's
    /// environment locale handles most Text/Button literals automatically; this
    /// helper is for runtime/deterministic strings that are built outside a View.
    func localized(_ key: String, fallback: String? = nil) -> String {
        FruitfolioLocalization.localized(key, language: language, fallback: fallback)
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
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }
}
