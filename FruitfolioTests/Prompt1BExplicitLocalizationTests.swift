import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BExplicitLocalizationTests: XCTestCase {
    private func fixture(development: String = "en", tables: [String: [String: String]]) throws -> (Bundle, URL) {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        do {
            let info: [String: Any] = ["CFBundleIdentifier": "test.fruitfolio." + UUID().uuidString,
                                       "CFBundleDevelopmentRegion": development]
            try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
                .write(to: root.appendingPathComponent("Info.plist"))
            for (locale, table) in tables {
                let folder = root.appendingPathComponent(locale + ".lproj")
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                try PropertyListSerialization.data(fromPropertyList: table, format: .binary, options: 0)
                    .write(to: folder.appendingPathComponent("Localizable.strings"))
            }
            return (try XCTUnwrap(Bundle(url: root)), root)
        } catch {
            try? FileManager.default.removeItem(at: root)
            throw error
        }
    }

    @MainActor
    func testActualSettingsSwitchesExactResourceLanguagesRepeatedly() async throws {
        let (bundle, root) = try fixture(tables: ["en": ["status": "Ready"], "es": ["status": "Listo"], "ar": ["status": "جاهز"]])
        defer { try? FileManager.default.removeItem(at: root) }
        let suite = "Fruitfolio.BundlePreference." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = SettingsStore(defaults: defaults)
        for (language, value) in [(FruitfolioLanguage.arabic, "جاهز"), (.spanish, "Listo"), (.english, "Ready"), (.arabic, "جاهز")] {
            store.language = language
            XCTAssertEqual(store.localized("status", bundle: bundle), value)
            XCTAssertEqual(SettingsStore(defaults: defaults).localized("status", bundle: bundle), value)
        }
    }

    func testMissingAndEmptyTranslationsPreserveExactScientificSourceFallback() throws {
        let (bundle, root) = try fixture(tables: ["en": ["status": "Ready"], "es": ["status": "  \n"]])
        defer { try? FileManager.default.removeItem(at: root) }
        let original = "Estradiol: 10.25 pg/mL; DOI:10.1000/example (2026)."
        for language in [FruitfolioLanguage.spanish, .arabic] {
            XCTAssertEqual(FruitfolioLocalization.localized("status", language: language, fallback: original, bundle: bundle), original)
            XCTAssertEqual(FruitfolioLocalization.localized("missing", language: language, bundle: bundle), "missing")
        }
    }

    func testChineseScriptsNeverBorrowEachOthersTable() throws {
        let (bundle, root) = try fixture(tables: ["zh-Hans": ["status": "简体"], "zh-Hant": ["status": "繁體", "traditionalOnly": "保留"]])
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertEqual(FruitfolioLocalization.localized("status", language: .chineseSimplified, bundle: bundle), "简体")
        XCTAssertEqual(FruitfolioLocalization.localized("status", language: .chineseTraditional, bundle: bundle), "繁體")
        XCTAssertEqual(FruitfolioLocalization.localized("traditionalOnly", language: .chineseSimplified, fallback: "Source", bundle: bundle), "Source")
    }

    func testBaseTableIsUsedOnlyForEnglishDevelopmentResources() throws {
        for development in ["en", "fr"] {
            let (bundle, root) = try fixture(development: development, tables: ["Base": ["status": "Base value"]])
            defer { try? FileManager.default.removeItem(at: root) }
            XCTAssertEqual(FruitfolioLocalization.localized("status", language: .english, fallback: "Source", bundle: bundle), development == "en" ? "Base value" : "Source")
            XCTAssertEqual(FruitfolioLocalization.localized("status", language: .spanish, fallback: "Source", bundle: bundle), "Source")
        }
    }
}
