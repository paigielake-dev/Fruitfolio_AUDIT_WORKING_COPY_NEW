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
        let locale = Locale(identifier: language.localeIdentifier)
        let value = String(
            localized: String.LocalizationValue(key),
            table: "Localizable",
            bundle: .main,
            locale: locale
        )
        if value == key || value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fallback ?? key
        }
        return value
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
            return "offline translation isn’t available for \(language.nativeDisplayName). this content remains in its original English; your language selection is saved."
        case .requiresVerification:
            return "translation for \(language.nativeDisplayName) hasn’t been verified for safe display yet. this content remains in its original English; your language selection is saved."
        }
    }
}
