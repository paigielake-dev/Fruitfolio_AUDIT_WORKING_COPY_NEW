#if canImport(Combine)
import Combine
import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BSettingsLanguageTests: XCTestCase {
    func testActualSettingsStorePersistsLanguageInItsInjectedAuthorityAndPublishesChanges() async throws {
        let suite = "Fruitfolio.SettingsLanguage." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.globallyMuted = true
        var observed: [FruitfolioLanguage] = []
        let subscription = settings.$language.sink { observed.append($0) }
        defer { subscription.cancel() }
        for language in FruitfolioLanguage.allCases {
            settings.language = language
            XCTAssertEqual(SettingsStore(defaults: defaults).language, language)
            XCTAssertTrue(SettingsStore(defaults: defaults).globallyMuted)
        }
        XCTAssertEqual(observed, [.english] + FruitfolioLanguage.allCases)
    }
    func testUnknownPreferenceIsDisclosedWithoutRewriteUntilExplicitSelection() async throws {
        let suite = "Fruitfolio.SettingsLanguageRecovery." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("future-language", forKey: FruitfolioLanguagePreferences.defaultsKey)
        let settings = SettingsStore(defaults: defaults)
        XCTAssertEqual(settings.language, .english)
        XCTAssertTrue(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(defaults.string(forKey: FruitfolioLanguagePreferences.defaultsKey), "future-language")
        settings.language = .guarani
        XCTAssertFalse(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .guarani)
    }

}
#endif
