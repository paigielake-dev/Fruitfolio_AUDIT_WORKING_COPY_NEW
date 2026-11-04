import XCTest
@testable import Fruitfolio

@MainActor
final class LanguagePreferenceRecoveryTests: XCTestCase {
    func testUnknownSavedPreferenceIsPreservedAndDisclosedUntilAnIntentionalNewSelection() throws {
        let suite = "LanguageUnknownRecovery-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = FruitfolioLanguagePreferences.defaultsKey
        let original = "future-language-not-recognized"
        defaults.set(original, forKey: key)
        for _ in 0..<2 {
            let store = SettingsStore(defaults: defaults)
            XCTAssertEqual(store.language, .english)
            XCTAssertNotNil(store.languagePreferenceWarning)
            XCTAssertEqual(defaults.string(forKey: key), original)
        }
        let store = SettingsStore(defaults: defaults)
        store.language = .spanish
        XCTAssertNil(store.languagePreferenceWarning)
        XCTAssertEqual(defaults.string(forKey: key), "es")
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .spanish)
    }

    func testUnreadablePreferenceTypeIsNotSilentlyReplacedOnLaunch() throws {
        let suite = "LanguageTypeRecovery-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = FruitfolioLanguagePreferences.defaultsKey
        let original = Data("unreadable preference fixture".utf8)
        defaults.set(original, forKey: key)
        let store = SettingsStore(defaults: defaults)
        XCTAssertNotNil(store.languagePreferenceWarning)
        XCTAssertEqual(defaults.data(forKey: key), original)
        store.language = .english
        XCTAssertNil(store.languagePreferenceWarning)
        XCTAssertEqual(defaults.string(forKey: key), "en")
    }

    func testLegacyUnderscoreChineseScriptKeepsItsExactLanguageAndOriginalStoredSpelling() throws {
        let suite = "LanguageScriptRecovery-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = FruitfolioLanguagePreferences.defaultsKey
        defaults.set("zh_Hant", forKey: key)
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.language, .chineseTraditional)
        XCTAssertNil(store.languagePreferenceWarning)
        XCTAssertEqual(defaults.string(forKey: key), "zh_Hant")
        store.language = .chineseSimplified
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .chineseSimplified)
        XCTAssertEqual(defaults.string(forKey: key), "zh-Hans")
    }

    func testEveryExistingLanguageIdentityLoadsWithoutARecoveryWarning() throws {
        let suite = "LanguageValidRecovery-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        for language in FruitfolioLanguage.allCases {
            defaults.set(language.rawValue, forKey: FruitfolioLanguagePreferences.defaultsKey)
            let store = SettingsStore(defaults: defaults)
            XCTAssertEqual(store.language, language)
            XCTAssertNil(store.languagePreferenceWarning)
        }
    }
}
