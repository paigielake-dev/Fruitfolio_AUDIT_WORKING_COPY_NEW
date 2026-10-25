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
