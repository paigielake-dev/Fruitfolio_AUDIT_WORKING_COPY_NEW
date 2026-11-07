#if canImport(Combine)
import Combine
#endif
import Foundation
import XCTest
@testable import Fruitfolio

private final class Prompt1BLanguageWriteFaultDefaults: UserDefaults, @unchecked Sendable {
    enum Fault { case accept, drop, replace(String) }
    var fault: Fault = .accept
    var languageWriteAttempts = 0
    override func set(_ value: Any?, forKey key: String) {
        guard key == FruitfolioLanguagePreferences.defaultsKey else { super.set(value, forKey: key); return }
        languageWriteAttempts += 1
        switch fault {
        case .accept: super.set(value, forKey: key)
        case .drop: break
        case .replace(let replacement): super.set(replacement, forKey: key)
        }
    }
}

@MainActor
final class Prompt1BSettingsLanguageTests: XCTestCase {
    func testDroppedLanguageWriteCannotRetainUnacknowledgedSelection() async throws {
        let suite = "Fruitfolio.LanguageWrite.drop." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLanguageWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(FruitfolioLanguage.french.rawValue, forKey: FruitfolioLanguagePreferences.defaultsKey)
        let settings = SettingsStore(defaults: defaults)
        defaults.fault = .drop
        let attempts = defaults.languageWriteAttempts
        settings.language = .japanese
        XCTAssertEqual(defaults.languageWriteAttempts, attempts + 1)
        XCTAssertNotNil(settings.languagePersistenceMessage)
        XCTAssertEqual(settings.language, .french)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .french)
        XCTAssertEqual(defaults.string(forKey: FruitfolioLanguagePreferences.defaultsKey), FruitfolioLanguage.french.rawValue)
        defaults.fault = .accept
        settings.language = .japanese
        XCTAssertEqual(settings.language, .japanese)
        XCTAssertNil(settings.languagePersistenceMessage)
        XCTAssertFalse(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .japanese)
    }

    func testDroppedReplacementPreservesFutureLanguagePreferenceReview() async throws {
        let suite = "Fruitfolio.LanguageWrite.future." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLanguageWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("future-language", forKey: FruitfolioLanguagePreferences.defaultsKey)
        let settings = SettingsStore(defaults: defaults)
        defaults.fault = .drop
        let attempts = defaults.languageWriteAttempts
        settings.language = .japanese
        XCTAssertEqual(defaults.languageWriteAttempts, attempts + 1)
        XCTAssertNotNil(settings.languagePersistenceMessage)
        XCTAssertEqual(settings.language, .english)
        XCTAssertTrue(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(defaults.string(forKey: FruitfolioLanguagePreferences.defaultsKey), "future-language")
        defaults.fault = .accept
        settings.language = .japanese
        XCTAssertEqual(settings.language, .japanese)
        XCTAssertNil(settings.languagePersistenceMessage)
        XCTAssertFalse(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .japanese)
    }

    func testInterleavedLanguageReplacementCannotBeMistakenForRequestedSelection() async throws {
        let suite = "Fruitfolio.LanguageWrite.replace." + UUID().uuidString
        let defaults = try XCTUnwrap(Prompt1BLanguageWriteFaultDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        defaults.fault = .replace(FruitfolioLanguage.arabic.rawValue)
        let attempts = defaults.languageWriteAttempts
        settings.language = .japanese
        XCTAssertEqual(defaults.languageWriteAttempts, attempts + 1)
        XCTAssertNotNil(settings.languagePersistenceMessage)
        XCTAssertEqual(settings.language, .arabic)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .arabic)
        XCTAssertFalse(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(defaults.string(forKey: FruitfolioLanguagePreferences.defaultsKey), FruitfolioLanguage.arabic.rawValue)
        defaults.fault = .accept
        settings.language = .japanese
        XCTAssertEqual(settings.language, .japanese)
        XCTAssertNil(settings.languagePersistenceMessage)
        XCTAssertFalse(settings.languagePreferenceNeedsReview)
        XCTAssertEqual(SettingsStore(defaults: defaults).language, .japanese)
    }


    #if DEBUG
    func testRestartPreferenceFixturePreservesActualLanguageUntilExplicitCleanup() async throws {
        let token = UUID()
        var owner: FruitfolioRegressionPreferenceSuite? = FruitfolioRegressionPreferenceSuite(persistenceToken: token)
        let defaults = try XCTUnwrap(owner?.defaults)
        let name = try XCTUnwrap(owner?.suiteName)
        defer { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        XCTAssertTrue(try XCTUnwrap(owner).isPersistentFixture)
        let settings = SettingsStore(defaults: defaults)
        settings.language = .arabic
        XCTAssertNil(settings.languagePersistenceMessage)
        weak var reference = owner
        owner = nil
        XCTAssertNil(reference)
        let restored = FruitfolioRegressionPreferenceSuite(persistenceToken: token)
        XCTAssertEqual(restored.suiteName, name)
        XCTAssertEqual(SettingsStore(defaults: try XCTUnwrap(restored.defaults)).language, .arabic)
        restored.cleanUp()
        XCTAssertNil(restored.defaults?.object(forKey: FruitfolioLanguagePreferences.defaultsKey))
        XCTAssertEqual(SettingsStore(defaults: try XCTUnwrap(restored.defaults)).language, .english)
    }

    func testRestartPreferenceArgumentsCannotSelectArbitraryOrProductionDomains() async {
        let token = UUID()
        let flag = "-fruitfolioLanguagePersistenceQA", key = "-fruitfolioLanguagePersistenceToken"
        XCTAssertNil(FruitfolioRegressionPreferenceSuite.restartToken(arguments: [key, token.uuidString]))
        XCTAssertNil(FruitfolioRegressionPreferenceSuite.restartToken(arguments: [flag, key]))
        XCTAssertNil(FruitfolioRegressionPreferenceSuite.restartToken(arguments: [flag, key, "com.example.production"]))
        XCTAssertEqual(FruitfolioRegressionPreferenceSuite.restartToken(arguments: [flag, key, token.uuidString]), token)
    }

    func testIndependentRestartPreferenceFixturesCannotReadOrClearEachOther() async throws {
        let first = FruitfolioRegressionPreferenceSuite(persistenceToken: UUID())
        let second = FruitfolioRegressionPreferenceSuite(persistenceToken: UUID())
        defer { first.cleanUp(); second.cleanUp() }
        let a = SettingsStore(defaults: try XCTUnwrap(first.defaults))
        let b = SettingsStore(defaults: try XCTUnwrap(second.defaults))
        a.language = .french; b.language = .japanese
        XCTAssertNotEqual(first.suiteName, second.suiteName)
        first.cleanUp()
        XCTAssertNil(first.defaults?.object(forKey: FruitfolioLanguagePreferences.defaultsKey))
        XCTAssertEqual(SettingsStore(defaults: try XCTUnwrap(second.defaults)).language, .japanese)
    }

    func testActualTemporaryCatalogCanResolveProtectedFixtureWhileInferenceIsPaused() async throws {
        let fixture = try FruitfolioTranslationCatalogRegressionFixture()
        XCTAssertEqual(FruitfolioLocalization.catalogValue("**fixture source**", language: .french,
            bundle: fixture.bundle), "**fixture cible**")
        let service = FruitfolioTranslationService(runtime: FruitfolioMADLADRuntime.shared)
        let result = try await service.translateForDisplay("**fixture source**", language: .french,
            inferenceAllowed: false, bundle: fixture.bundle)
        XCTAssertEqual(result.origin, .catalog)
        XCTAssertEqual(result.text, "**fixture cible**")
    }

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

    func testActualPlaybackVolumeGatesFourIndependentChannelsWithoutChangingPreferences() async throws {
        let suite = "Fruitfolio.AudioPlaybackPolicy." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        settings.musicVolume = 0.71; settings.rainVolume = 0.62
        settings.soundEffectsVolume = 0.53; settings.typingVolume = 0.44
        let volumes: [FruitfolioAudioCategory: Float] = [.music: 0.71, .rainAmbience: 0.62, .soundEffects: 0.53, .typingASMR: 0.44]
        for category in FruitfolioAudioCategory.allCases {
            XCTAssertEqual(settings.playbackVolume(for: category), volumes[category]!, accuracy: 0.0001)
        }
        settings.globallyMuted = true
        for category in FruitfolioAudioCategory.allCases { XCTAssertEqual(settings.playbackVolume(for: category), 0) }
        settings.musicEnabled = false; settings.soundEffectsEnabled = false
        let reloaded = SettingsStore(defaults: defaults)
        reloaded.globallyMuted = false
        XCTAssertEqual(reloaded.playbackVolume(for: .music), 0)
        XCTAssertEqual(reloaded.playbackVolume(for: .soundEffects), 0)
        XCTAssertEqual(reloaded.playbackVolume(for: .rainAmbience), 0.62, accuracy: 0.0001)
        XCTAssertEqual(reloaded.playbackVolume(for: .typingASMR), 0.44, accuracy: 0.0001)
        XCTAssertEqual(reloaded.musicVolume, 0.71)
        XCTAssertEqual(reloaded.soundEffectsVolume, 0.53)
    }

    func testLiveAndReloadedPlaybackVolumesAreFiniteClampedForEveryChannel() async throws {
        let suite = "Fruitfolio.AudioFinitePlayback." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = SettingsStore(defaults: defaults)
        for raw in [-1.0, 2.0, Double.infinity, -Double.infinity, Double.nan] {
            settings.musicVolume = raw; settings.rainVolume = raw
            settings.soundEffectsVolume = raw; settings.typingVolume = raw
            let expected: Float = raw.isFinite ? Float(min(max(raw, 0), 1)) : 0
            let reloaded = SettingsStore(defaults: defaults)
            for category in FruitfolioAudioCategory.allCases {
                XCTAssertEqual(settings.playbackVolume(for: category), expected)
                XCTAssertEqual(reloaded.playbackVolume(for: category), expected)
                XCTAssertTrue(settings.playbackVolume(for: category).isFinite)
            }
        }
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
