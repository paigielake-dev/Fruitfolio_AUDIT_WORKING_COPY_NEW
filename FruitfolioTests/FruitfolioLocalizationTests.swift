import Foundation
import Testing
@testable import Fruitfolio

struct FruitfolioLocalizationTests {
    @Test func everySupportedLanguageHasStableIdentityAndNativeName() {
        #expect(Set(FruitfolioLanguage.allCases.map(\.rawValue)).count == FruitfolioLanguage.allCases.count)
        for language in FruitfolioLanguage.allCases {
            #expect(!language.nativeDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            #expect(!language.localeIdentifier.isEmpty)
        }
    }

    @Test func rightToLeftLanguagesAreExplicit() {
        #expect(FruitfolioLanguage.persian.isRightToLeft)
        #expect(FruitfolioLanguage.arabic.isRightToLeft)
        #expect(FruitfolioLanguage.urdu.isRightToLeft)
        #expect(!FruitfolioLanguage.english.isRightToLeft)
        #expect(!FruitfolioLanguage.samoan.isRightToLeft)
    }

    @Test func vietnameseAndFilipinoRemainFirstClassChoices() {
        #expect(FruitfolioLanguage.allCases.contains(.vietnamese))
        #expect(FruitfolioLanguage.allCases.contains(.filipino))
        #expect(FruitfolioLanguage.vietnamese.rawValue == "vi")
        #expect(FruitfolioLanguage.filipino.rawValue == "fil")
    }

    @Test func pacificLanguagesRemainFirstClassChoices() {
        let required: Set<FruitfolioLanguage> = [
            .samoan, .tongan, .fijian, .hawaiian, .maori, .chamorro,
            .marshallese, .tokPisin, .tahitian, .palauan,
            .cookIslandsMaori, .niuean, .tuvaluan, .kiribati, .bislama
        ]
        #expect(required.isSubset(of: Set(FruitfolioLanguage.allCases)))
    }
}
