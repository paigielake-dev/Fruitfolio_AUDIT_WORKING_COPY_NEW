import Foundation

/// Resolve runtime strings using the app preference, independently of the OS language.
enum FruitfolioLocalization {
    static func localized(
        _ key: String,
        language: FruitfolioLanguage,
        fallback: String? = nil,
        bundle: Bundle = .main
    ) -> String {
        catalogValue(key, language: language, bundle: bundle) ?? fallback ?? key
    }

    /// Distinguish missing keys from intentional identical translations such as
    /// scientific abbreviations/proper names. No OS-language fallback is used.
    static func catalogValue(_ key: String, language: FruitfolioLanguage, bundle: Bundle = .main) -> String? {
        // String(localized:locale:) supplies formatting locale, not an explicit
        // resource-language override. Open the exact language table instead.
        var directories = [language.rawValue]
        if language == .english,
           bundle.developmentLocalization == nil || bundle.developmentLocalization == "en" {
            directories.append("Base")
        }
        let missing = "\u{001f}fruitfolio.missing." + UUID().uuidString
        for directory in directories {
            guard let root = bundle.resourceURL,
                  let selected = Bundle(url: root.appendingPathComponent(directory + ".lproj", isDirectory: true)) else { continue }
            let value = selected.localizedString(forKey: key, value: missing, table: "Localizable")
            if value != missing && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return value }
        }
        return nil
    }
}
