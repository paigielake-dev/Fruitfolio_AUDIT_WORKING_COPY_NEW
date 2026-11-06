#if canImport(Combine)
import Combine
#endif
import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BSettingsLanguageTests: XCTestCase {
    #if DEBUG
    func testRegressionPreferencesSurviveStoreRecreationUntilOwnerRelease() async throws {
        var owner: FruitfolioRegressionPreferenceSuite? = FruitfolioRegressionPreferenceSuite()
        weak var reference = owner
        let suite = try XCTUnwrap(owner?.suiteName)
        let defaults = try XCTUnwrap(owner?.defaults)
        let settings = SettingsStore(defaults: defaults)
        settings.language = .french
        settings.soundEffectsEnabled = false
        settings.musicVolume = 0.73
        let reappearing = SettingsStore(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)))
        XCTAssertEqual(reappearing.language, .french)
        XCTAssertFalse(reappearing.soundEffectsEnabled)
        XCTAssertEqual(reappearing.musicVolume, 0.73)
        XCTAssertNotNil(reference)
        XCTAssertFalse(defaults.persistentDomain(forName: suite)?.isEmpty ?? true)
        owner = nil
        XCTAssertNil(reference)
        XCTAssertTrue(try XCTUnwrap(UserDefaults(suiteName: suite)).persistentDomain(forName: suite)?.isEmpty ?? true)
    }

    func testRegressionPreferenceOwnersHaveIsolatedDomainsAndIndependentCleanup() async throws {
        var first: FruitfolioRegressionPreferenceSuite? = FruitfolioRegressionPreferenceSuite()
        let second = FruitfolioRegressionPreferenceSuite()
        let firstName = try XCTUnwrap(first?.suiteName)
        XCTAssertNotEqual(firstName, second.suiteName)
        let key = "fixture-isolation-" + UUID().uuidString
        let standardBefore = UserDefaults.standard.object(forKey: key) as? String
        try XCTUnwrap(first?.defaults).set("first", forKey: key)
        try XCTUnwrap(second.defaults).set("second", forKey: key)
        first = nil
        XCTAssertNil(UserDefaults(suiteName: firstName)?.persistentDomain(forName: firstName)?[key])
        XCTAssertEqual(second.defaults?.string(forKey: key), "second")
        XCTAssertEqual(UserDefaults.standard.object(forKey: key) as? String, standardBefore)
    }
    #endif

    func testActualSettingsStorePersistsLanguageInItsInjectedAuthorityAndPublishesChanges() async throws {
        let suite = "Fruitfolio.SettingsLanguage." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.globallyMuted = true
        #if canImport(Combine)
        var observed: [FruitfolioLanguage] = []
        let subscription = settings.$language.sink { observed.append($0) }
        defer { subscription.cancel() }
        #endif
        for language in FruitfolioLanguage.allCases {
            settings.language = language
            XCTAssertEqual(SettingsStore(defaults: defaults).language, language)
            XCTAssertTrue(SettingsStore(defaults: defaults).globallyMuted)
        }
        #if canImport(Combine)
        XCTAssertEqual(observed, [.english] + FruitfolioLanguage.allCases)
        #endif
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

    func testMemoryPressurePauseIsTransientAndNeverResetsChosenLanguage() async throws {
        let suite = "Fruitfolio.SettingsMemory." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.language = .arabic
        settings.translationPausedForMemoryPressure = true
        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.language, .arabic)
        XCTAssertFalse(reloaded.translationPausedForMemoryPressure)
        XCTAssertTrue(settings.translationPausedForMemoryPressure)
    }

    func testGlobalMuteRetainsFourIndependentChannelChoicesAcrossReload() async throws {
        let suite = "Fruitfolio.SettingsAudio." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicEnabled = false
        settings.rainEnabled = true
        settings.soundEffectsEnabled = false
        settings.typingASMREnabled = true
        settings.globallyMuted = true
        for category in FruitfolioAudioCategory.allCases { XCTAssertFalse(settings.allowsAudio(category)) }
        let reloaded = SettingsStore(defaults: defaults)
        reloaded.globallyMuted = false
        XCTAssertFalse(reloaded.allowsAudio(.music))
        XCTAssertTrue(reloaded.allowsAudio(.rainAmbience))
        XCTAssertFalse(reloaded.allowsAudio(.soundEffects))
        XCTAssertTrue(reloaded.allowsAudio(.typingASMR))
    }

    func testPersistedVolumesAreClampedAndNonfiniteValuesNeverPersist() async throws {
        let suite = "Fruitfolio.SettingsVolume." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicVolume = -1
        settings.rainVolume = 2
        settings.soundEffectsVolume = .nan
        settings.typingVolume = .infinity
        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.musicVolume, 0)
        XCTAssertEqual(reloaded.rainVolume, 1)
        XCTAssertEqual(reloaded.soundEffectsVolume, 0)
        XCTAssertEqual(reloaded.typingVolume, 0)
    }

}

final class Prompt1BSettingsPercentageTests: XCTestCase {
    func testPercentageUsesSelectedLocaleDigitsAndSymbol() throws {
        XCTAssertEqual(FruitfolioSettingsPercentage.string(0.25, locale: Locale(identifier: "en_US")), "25%")
        let arabic = try XCTUnwrap(FruitfolioSettingsPercentage.string(0.25, locale: Locale(identifier: "ar")))
        XCTAssertTrue(arabic.contains("٢٥"))
        XCTAssertTrue(arabic.contains("٪"))
        let french = try XCTUnwrap(FruitfolioSettingsPercentage.string(0.25, locale: Locale(identifier: "fr")))
        XCTAssertTrue(french.contains("25"))
        XCTAssertTrue(french.contains("%"))
        XCTAssertNotEqual(arabic, "25 percent")
    }
    func testPercentageBoundsAndRoundingRejectInvalidValues() {
        let source = 0.375
        XCTAssertEqual(FruitfolioSettingsPercentage.string(source, locale: Locale(identifier: "en_US")), "38%")
        XCTAssertEqual(FruitfolioSettingsPercentage.string(0, locale: Locale(identifier: "en_US")), "0%")
        XCTAssertEqual(FruitfolioSettingsPercentage.string(1, locale: Locale(identifier: "en_US")), "100%")
        for invalid in [Double.nan, .infinity, -.infinity, -0.1, 1.1] {
            XCTAssertNil(FruitfolioSettingsPercentage.string(invalid, locale: Locale(identifier: "en_US")))
        }
    }
    @MainActor
    func testActualPrivateSettingsReadbackPreservesStoredVolumeAfterFormatting() async throws {
        let suite = "Fruitfolio.SettingsPercentage." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.soundEffectsEnabled = false
        settings.soundEffectsVolume = 0.375
        _ = FruitfolioSettingsPercentage.string(settings.soundEffectsVolume, locale: Locale(identifier: "ar"))
        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.soundEffectsVolume, 0.375)
        XCTAssertFalse(reloaded.soundEffectsEnabled)
        #if DEBUG
        XCTAssertEqual(settings.debugStoredEffects.volume, 0.375)
        XCTAssertFalse(settings.debugStoredEffects.enabled)
        #endif
    }
}
