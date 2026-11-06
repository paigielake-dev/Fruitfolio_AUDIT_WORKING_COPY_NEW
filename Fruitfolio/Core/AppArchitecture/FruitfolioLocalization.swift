import Foundation

/// Resolve runtime strings using the app preference, independently of the OS language.
enum FruitfolioLocalization {
    static func localized(
        _ key: String,
        language: FruitfolioLanguage,
        fallback: String? = nil,
        bundle: Bundle = .main
    ) -> String {
        // String(localized:locale:) supplies formatting locale, not an explicit
        // resource-language override. Open the exact language table instead.
        // In particular, never substitute one Chinese script for the other.
        var directories = [language.rawValue]
        if language == .english,
           bundle.developmentLocalization == nil || bundle.developmentLocalization == "en" {
            directories.append("Base")
        }
        for directory in directories {
            guard let root = bundle.resourceURL,
                  let selected = Bundle(url: root.appendingPathComponent(directory + ".lproj", isDirectory: true)) else { continue }
            let value = selected.localizedString(forKey: key, value: key, table: "Localizable")
            if value != key && !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return value
            }
        }
        return fallback ?? key
    }
}
