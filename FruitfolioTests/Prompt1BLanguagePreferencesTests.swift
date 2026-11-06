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
        XCTAssertEqual(FruitfolioLanguagePreferences.load(from: b), .japanese)
    }
    func testOnlyArabicPersianAndUrduSelectRightToLeftLayout() {
        XCTAssertEqual(Set(FruitfolioLanguage.allCases.filter(\.isRightToLeft)), [.arabic, .persian, .urdu])
        XCTAssertEqual(Set(FruitfolioLanguage.allCases.map(\.rawValue)).count, FruitfolioLanguage.allCases.count)
    }
}
