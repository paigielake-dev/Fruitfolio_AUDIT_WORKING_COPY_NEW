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

#if DEBUG
/// Real temporary catalog for nonclinical UI/pipeline regressions only. This
/// does not add, approve or ship a foreign translation in the app's catalog.
nonisolated final class FruitfolioTranslationCatalogRegressionFixture {
    let directory: URL
    let bundle: Bundle
    init() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("Fruitfolio.syntheticCatalog." + UUID().uuidString + ".bundle")
        do {
            let french = root.appendingPathComponent("fr.lproj", isDirectory: true)
            try FileManager.default.createDirectory(at: french, withIntermediateDirectories: true)
            let info = ["CFBundleIdentifier": "org.fruitfolio.syntheticCatalog." + UUID().uuidString,
                        "CFBundlePackageType": "BNDL", "CFBundleDevelopmentRegion": "en"]
            try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
                .write(to: root.appendingPathComponent("Info.plist"))
            try #""**fixture source**" = "**fixture cible**";"#
                .write(to: french.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
            guard let loaded = Bundle(url: root) else { throw CocoaError(.fileReadCorruptFile) }
            directory = root
            bundle = loaded
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }
    deinit { try? FileManager.default.removeItem(at: directory) }
}
#endif
