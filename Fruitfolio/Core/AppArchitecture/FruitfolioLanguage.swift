import Foundation

enum FruitfolioLanguage: String, CaseIterable, Codable, Identifiable, Sendable {
    case english = "en"
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
    case spanish = "es"
    case portuguese = "pt"
    case quechua = "qu"
    case guarani = "gn"
    case aymara = "ay"
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
    var isRightToLeft: Bool { self == .persian || self == .arabic || self == .urdu || self == .hebrew || self == .kurdishSorani }

    /// Native/autonym labels deliberately remain recognizable even when the current UI language changes.
    var nativeDisplayName: String {
        switch self {
        case .english: return "English"
        case .thai: return "ไทย"
        case .mongolian: return "Монгол"
        case .indonesian: return "Bahasa Indonesia"
        case .russian: return "Русский"
        case .polish: return "Polski"
        case .dutch: return "Nederlands"
        case .swedish: return "Svenska"
        case .ukrainian: return "Українська"
        case .turkish: return "Türkçe"
        case .kurdishKurmanji: return "Kurdî (Kurmancî)"
        case .kurdishSorani: return "کوردی (سۆرانی)"
        case .hebrew: return "עברית"
        case .spanish: return "Español"
        case .portuguese: return "Português"
        case .quechua: return "Runa Simi"
        case .guarani: return "Avañeʼẽ"
        case .aymara: return "Aymar aru"
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

    static func load(from defaults: UserDefaults) -> FruitfolioLanguage {
        guard let raw = defaults.string(forKey: defaultsKey),
              let language = FruitfolioLanguage(rawValue: raw) else { return .english }
        return language
    }

    /// Preserve unknown/future raw preferences; show an explicit display fallback.
    static func needsReview(in defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: defaultsKey) != nil else { return false }
        guard let raw = defaults.string(forKey: defaultsKey) else { return true }
        return FruitfolioLanguage(rawValue: raw) == nil
    }

    @discardableResult
    static func save(_ language: FruitfolioLanguage, to defaults: UserDefaults) -> Bool {
        defaults.set(language.rawValue, forKey: defaultsKey)
        return defaults.object(forKey: defaultsKey) as? String == language.rawValue
    }
}
