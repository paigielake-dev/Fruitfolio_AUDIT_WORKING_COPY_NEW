import XCTest
@testable import Fruitfolio

final class UILocalizationResolutionTests: XCTestCase {
    private func fixture(_ localizations: [String: [String: String]]) throws -> (URL, Bundle) {
        let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let root = parent.appendingPathComponent("LocalizationFixture.bundle")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let info: [String: Any] = ["CFBundleIdentifier": "test.fruitfolio.\(UUID().uuidString)",
            "CFBundleName": "LocalizationFixture", "CFBundlePackageType": "BNDL",
            "CFBundleVersion": "1", "CFBundleDevelopmentRegion": "en",
            "CFBundleLocalizations": Array(localizations.keys)]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            .write(to: root.appendingPathComponent("Info.plist"))
        func escaped(_ text: String) -> String {
            text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        }
        for (language, strings) in localizations {
            let directory = root.appendingPathComponent(language + ".lproj")
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let contents = strings.map { "\"\(escaped($0.key))\" = \"\(escaped($0.value))\";" }.joined(separator: "\n")
            try contents.write(to: directory.appendingPathComponent("Localizable.strings"), atomically: true, encoding: .utf8)
        }
        return (parent, try XCTUnwrap(Bundle(url: root)))
    }

    func testValidTranslationEqualToItsKeyDoesNotBecomeACallerFallback() throws {
        let (directory, bundle) = try fixture(["en": ["no": "no"], "es": ["no": "no"]])
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = FruitfolioLocalization.resolve("no", locale: Locale(identifier: "es"), fallback: "English fallback", bundle: bundle)
        XCTAssertEqual(result.text, "no")
        XCTAssertEqual(result.languageIdentifier, "es")
        XCTAssertFalse(result.usedSourceFallback)
    }

    func testTraditionalSelectionNeverSilentlyUsesGenericOrSimplifiedChinese() throws {
        let (directory, bundle) = try fixture(["en": ["done": "done"],
            "zh": ["done": "GENERIC_CHINESE_FIXTURE"], "zh-Hans": ["done": "HANS_FIXTURE"]])
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = FruitfolioLocalization.resolve("done", locale: Locale(identifier: "zh-Hant"),
                                                    fallback: "English original", bundle: bundle)
        XCTAssertEqual(result.text, "English original")
        XCTAssertEqual(result.languageIdentifier, "en")
        XCTAssertTrue(result.usedSourceFallback)
        let simplified = FruitfolioLocalization.resolve("done", locale: Locale(identifier: "zh-Hans"), bundle: bundle)
        XCTAssertEqual(simplified.text, "HANS_FIXTURE")
    }

    func testBothChineseScriptsResolveTheirOwnResourceIndependently() throws {
        let (directory, bundle) = try fixture(["zh-Hans": ["done": "HANS_FIXTURE"],
                                              "zh-Hant": ["done": "HANT_FIXTURE"]])
        defer { try? FileManager.default.removeItem(at: directory) }
        let simplified = FruitfolioLocalization.resolve("done", locale: Locale(identifier: "zh-Hans"), bundle: bundle)
        let traditional = FruitfolioLocalization.resolve("done", locale: Locale(identifier: "zh-Hant"), bundle: bundle)
        XCTAssertEqual(simplified.text, "HANS_FIXTURE")
        XCTAssertEqual(traditional.text, "HANT_FIXTURE")
        XCTAssertNotEqual(simplified.languageIdentifier, traditional.languageIdentifier)
    }

    func testMissingSemanticKeyUsesAuthoredEnglishResourceInsteadOfTechnicalIdentifier() throws {
        let (directory, bundle) = try fixture(["en": ["fixture.semantic.key": "Original source title"]])
        defer { try? FileManager.default.removeItem(at: directory) }
        let result = FruitfolioLocalization.resolve("fixture.semantic.key", locale: Locale(identifier: "zz"), bundle: bundle)
        XCTAssertEqual(result.text, "Original source title")
        XCTAssertTrue(result.usedSourceFallback)
        XCTAssertEqual(result.languageIdentifier, "en")
        let explicit = FruitfolioLocalization.resolve("fixture.semantic.key", locale: Locale(identifier: "zz"),
                                                      fallback: "Caller source wording", bundle: bundle)
        XCTAssertEqual(explicit.text, "Caller source wording")
    }

    func testScriptCandidatesDoNotCrossAnExplicitScriptBoundary() {
        let traditional = FruitfolioLocalization.localeCandidates(for: Locale(identifier: "zh-TW"))
        XCTAssertTrue(traditional.contains("zh-Hant"))
        XCTAssertFalse(traditional.contains("zh"))
        XCTAssertFalse(traditional.contains("zh-Hans"))
        let explicit = FruitfolioLocalization.localeCandidates(for: Locale(identifier: "sr-Latn-RS"))
        XCTAssertTrue(explicit.contains("sr-Latn"))
        XCTAssertFalse(explicit.contains("sr"))
        XCTAssertEqual(Set(explicit).count, explicit.count)
    }
}
