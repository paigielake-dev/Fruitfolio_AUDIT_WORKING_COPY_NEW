import XCTest
@testable import Fruitfolio

@MainActor
final class LanguagePreferencePersistenceTests: XCTestCase {
    func testEverySelectionSurvivesStoreRecreationWithoutChangingOtherStoredDataOrFallingBackSilently() throws {
        let suite = "Fruitfolio.LanguageDurability.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data("original sensitive fixture bytes; not translated".utf8), forKey: "unrelated.health.fixture")
        defaults.set("original user-authored text", forKey: "unrelated.authored.fixture")
        let original = defaults.persistentDomain(forName: suite) ?? [:]
        for language in FruitfolioLanguage.allCases {
            let settings = SettingsStore(defaults: defaults)
            settings.language = language
            let restored = SettingsStore(defaults: defaults)
            XCTAssertEqual(restored.language, language)
            XCTAssertEqual(defaults.string(forKey: FruitfolioLanguagePreferences.defaultsKey), language.rawValue)
            _ = FruitfolioLocalization.displayReadiness(for: restored.language)
            _ = FruitfolioLocalization.untranslatedContentNotice(for: restored.language)
            XCTAssertEqual(SettingsStore(defaults: defaults).language, language,
                "An unavailable target or unverified translation must not reset the stored choice")
            var after = defaults.persistentDomain(forName: suite) ?? [:]
            after.removeValue(forKey: FruitfolioLanguagePreferences.defaultsKey)
            XCTAssertTrue(NSDictionary(dictionary: after).isEqual(to: original),
                "Selecting language changes only that preference; original health/authored bytes remain intact")
        }
    }
}

extension LanguagePreferencePersistenceTests {
    func testCompiledInterfaceCatalogResolvesExplicitLocalesAndDistinctChineseScriptsWithoutModelInference() {
        for (locale, key, expected) in [
            ("es", "cancel", "cancelar"), ("fr", "save", "enregistrer"),
            ("ar", "save", "حفظ"), ("ja", "save", "保存"),
            ("zh-Hans", "delete", "删除"), ("zh-Hant", "delete", "刪除")
        ] {
            XCTAssertEqual(FruitfolioLocalization.localized(key, locale: Locale(identifier: locale)), expected,
                           "Actual compiled catalog lookup must follow the app's explicit locale")
        }
        XCTAssertEqual(FruitfolioLocalization.localized("PRIVATE_USER_AUTHORED_FIXTURE", locale: Locale(identifier: "es")), "PRIVATE_USER_AUTHORED_FIXTURE")
        XCTAssertEqual(FruitfolioLocalization.localized("PRIVATE_UNKNOWN_UI_KEY", locale: Locale(identifier: "ay")), "PRIVATE_UNKNOWN_UI_KEY")
        XCTAssertTrue(FruitfolioLanguage.arabic.isRightToLeft)
        XCTAssertTrue(FruitfolioLanguage.hebrew.isRightToLeft)
        XCTAssertFalse(FruitfolioLanguage.chineseTraditional.isRightToLeft)
    }
}
