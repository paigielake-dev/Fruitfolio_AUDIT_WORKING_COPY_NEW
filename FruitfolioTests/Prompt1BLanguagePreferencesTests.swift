import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BLanguagePreferencesTests: XCTestCase {
    func testEverySelectableLanguageRoundTripsThroughActualPreferenceKey() throws {
        let suite = "Fruitfolio.language." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: defaults), .english)
        for language in FruitfolioLanguage.allCases {
            FruitfolioLanguagePreferences.save(language, to: defaults)
            XCTAssertEqual(defaults.string(forKey: "fruitfolio.settings.language"), language.rawValue)
            XCTAssertEqual(FruitfolioLanguagePreferences.load(from: try XCTUnwrap(UserDefaults(suiteName: suite))), language)
            XCTAssertFalse(language.nativeDisplayName.isEmpty)
        }
    }
    func testInjectedPreferencesStayIsolatedAndUnknownValueIsNotSilentlyRewritten() throws {
        let names = ["Fruitfolio.language.a.", "Fruitfolio.language.b."].map { $0 + UUID().uuidString }
        let a = try XCTUnwrap(UserDefaults(suiteName: names[0]))
        let b = try XCTUnwrap(UserDefaults(suiteName: names[1]))
        defer { for name in names { a.removePersistentDomain(forName: name) } }
        FruitfolioLanguagePreferences.save(.arabic, to: a)
        FruitfolioLanguagePreferences.save(.japanese, to: b)
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: a), .arabic)
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: b), .japanese)
        a.set("unknown-future-language", forKey: FruitfolioLanguagePreferences.defaultsKey)
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: a), .english)
        XCTAssertEqual(a.string(forKey: FruitfolioLanguagePreferences.defaultsKey), "unknown-future-language")
        XCTAssertTrue(FruitfolioLanguagePreferences.needsReview(in: a))
        XCTAssertFalse(FruitfolioLanguagePreferences.needsReview(in: b))
        FruitfolioLanguagePreferences.save(.quechua, to: a)
        XCTAssertFalse(FruitfolioLanguagePreferences.needsReview(in: a))
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: b), .japanese)
    }
    func testScriptSpecificLanguagesSelectRightToLeftLayout() {
        XCTAssertEqual(Set(FruitfolioLanguage.allCases.filter(\.isRightToLeft)), [.arabic, .persian, .urdu, .hebrew, .kurdishSorani])
        XCTAssertEqual(Set(FruitfolioLanguage.allCases.map(\.rawValue)).count, FruitfolioLanguage.allCases.count)
    }
    func testFounderSouthAmericanLanguagesAreIndividualSelectorsWithStableNativeLabels() {
        let expected: [FruitfolioLanguage: String] = [.quechua: "qu", .guarani: "gn", .aymara: "ay"]
        for (language, code) in expected {
            XCTAssertTrue(FruitfolioLanguage.allCases.contains(language))
            XCTAssertEqual(language.rawValue, code)
            XCTAssertNotEqual(language.nativeDisplayName, code)
        }
        // Selector availability is not a claim of installed tokenizer/model support.
    }
    func testMissingPreferenceNeedsNoWarningButWrongTypeIsRetainedForReview() throws {
        let suite = "Fruitfolio.language.invalid." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertFalse(FruitfolioLanguagePreferences.needsReview(in: defaults))
        defaults.set(["future": "record"], forKey: FruitfolioLanguagePreferences.defaultsKey)
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: defaults), .english)
        XCTAssertTrue(FruitfolioLanguagePreferences.needsReview(in: defaults))
        XCTAssertEqual(defaults.dictionary(forKey: FruitfolioLanguagePreferences.defaultsKey) as? [String: String], ["future": "record"])
    }

    func testExplicitFounderAsianEuropeanAndMiddleEasternLanguagesHaveDistinctPersistentSelectors() {
        let expected: [FruitfolioLanguage: String] = [
            .thai: "th",
            .mongolian: "mn",
            .indonesian: "id",
            .russian: "ru",
            .polish: "pl",
            .dutch: "nl",
            .swedish: "sv",
            .ukrainian: "uk",
            .turkish: "tr",
            .kurdishKurmanji: "ku",
            .kurdishSorani: "ckb",
            .hebrew: "he",
        ]
        for (language, tag) in expected {
            XCTAssertEqual(language.rawValue, tag)
            XCTAssertTrue(FruitfolioLanguage.allCases.contains(language))
            XCTAssertNotEqual(language.nativeDisplayName, tag)
        }
        XCTAssertFalse(FruitfolioLanguage.kurdishKurmanji.isRightToLeft)
        XCTAssertTrue(FruitfolioLanguage.kurdishSorani.isRightToLeft)
        XCTAssertTrue(FruitfolioLanguage.hebrew.isRightToLeft)
        // Listing a language does not assert installed MADLAD support or quality.
    }

}
