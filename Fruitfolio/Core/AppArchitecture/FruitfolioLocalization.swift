import Foundation

/// One app-wide resolver for user-facing strings that must be produced outside
/// SwiftUI's Text/LocalizedStringKey pipeline (errors, deterministic fallbacks,
/// generated-status text, accessibility values, etc.).
enum FruitfolioLocalization {
    static func localized(
        _ key: String,
        language: FruitfolioLanguage = FruitfolioLanguagePreferences.current,
        fallback: String? = nil
    ) -> String {
        localized(key, locale: Locale(identifier: language.localeIdentifier), fallback: fallback)
    }

    /// Resolve the explicitly selected locale, not the system's preferred app
    /// language. Missing UI translations retain their original source wording.
    static func localized(_ key: String, locale: Locale, fallback: String? = nil) -> String {
        let exact = locale.identifier.replacingOccurrences(of: "_", with: "-")
        let language = locale.language.languageCode?.identifier ?? "en"
        var candidates = [exact]
        if let script = locale.language.script?.identifier { candidates.append(language + "-" + script) }
        candidates.append(language)
        for candidate in candidates {
            guard let directory = Bundle.main.url(forResource: candidate, withExtension: "lproj"),
                  let bundle = Bundle(url: directory) else { continue }
            let value = bundle.localizedString(forKey: key, value: key, table: "Localizable")
            if value != key && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return value }
        }
        return fallback ?? key
    }
}

/// Actual delivery readiness, separate from whether a tokenizer tag exists.
/// Model presence or preservation fixtures do not approve clinical display.
enum FruitfolioLanguageDisplayReadiness: Equatable {
    case originalEnglish
    case requiresVerification
    case unsupportedOfficialTarget
}

extension FruitfolioLocalization {
    static func displayReadiness(for language: FruitfolioLanguage) -> FruitfolioLanguageDisplayReadiness {
        if language == .english { return .originalEnglish }
        switch language {
        case .tokPisin, .tahitian, .cookIslandsMaori, .niuean, .kiribati:
            return .unsupportedOfficialTarget
        default:
            return .requiresVerification
        }
    }

    static func untranslatedContentNotice(for language: FruitfolioLanguage) -> String? {
        switch displayReadiness(for: language) {
        case .originalEnglish: return nil
        case .unsupportedOfficialTarget:
            return "offline generated-answer translation isn’t available for \(language.nativeDisplayName). original research and generated answers remain in English; your language selection is saved."
        case .requiresVerification:
            return "translation for \(language.nativeDisplayName) hasn’t been verified for safe scientific display yet. original research and generated answers remain in English; your language selection is saved."
        }
    }
}
