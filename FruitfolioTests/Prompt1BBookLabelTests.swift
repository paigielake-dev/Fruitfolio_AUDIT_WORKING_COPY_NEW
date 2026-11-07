import Foundation
import XCTest
@testable import Fruitfolio

private actor LibraryTileFixtureRuntime: FruitfolioLocalTranslationRuntime {
    let dropIdentity: Bool
    private(set) var inputs: [String] = []
    init(dropIdentity: Bool = false) { self.dropIdentity = dropIdentity }
    func translate(_ text: String, targetTag: String) async throws -> String {
        inputs.append(text)
        if dropIdentity { return "metadata only" }
        return text.replacingOccurrences(of: "chapter", with: "chapitre")
            .replacingOccurrences(of: "open encyclopedia", with: "ouvrir le livre")
    }
    func releaseResources() async {}
}

final class Prompt1BBookLabelTests: XCTestCase {
    @MainActor
    func testActualLibraryTileMetadataProtectsAuthoredFieldsAndKeepsStoredBytes() async throws {
        let suite = "Fruitfolio.LibraryTileCopy." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let name = "QA _notes* [cafe\u{301}]"
        let subtitle = "private x_y *draft*"
        let created = try store.createEncyclopedia(name: name, style: .sage)
        try store.updateEncyclopediaDescription(id: created.id, description: subtitle)
        let book = try XCTUnwrap(store.encyclopedia(id: created.id))
        let original = defaults.data(forKey: "fixture")
        let copy = Prompt10BookTileCopy(name: book.name, subtitle: book.subtitle,
            chapters: book.chapterCount, pages: book.savedPageCount, language: .french)
        XCTAssertEqual(copy.metadataSource, "1 chapter · 0 pages")
        let arabic = Prompt10BookTileCopy(name: book.name, subtitle: book.subtitle,
            chapters: book.chapterCount, pages: book.savedPageCount, language: .arabic)
        XCTAssertEqual(arabic.numericLiterals, ["١", "٠"])
        let runtime = LibraryTileFixtureRuntime()
        let owner = FruitfolioControlTranslationState(service: FruitfolioTranslationService(runtime: runtime))
        let key = FruitfolioControlTranslationState.Key(source: copy.accessibilitySource, language: .french,
            protectedLiterals: copy.accessibilityProtectedLiterals)
        await owner.resolve(key, inferenceAllowed: true)
        let display = owner.presentation(for: key)
        XCTAssertEqual(display.status, .machine)
        XCTAssertTrue(display.text.contains(FruitfolioSemanticMarkup.markdown([.init(text: name)])))
        XCTAssertTrue(display.text.contains(FruitfolioSemanticMarkup.markdown([.init(text: subtitle)])))
        let inputs = await runtime.inputs
        XCTAssertEqual(inputs.count, 1)
        XCTAssertFalse(try XCTUnwrap(inputs.first).contains("notes"))
        XCTAssertFalse(try XCTUnwrap(inputs.first).contains("private"))
        XCTAssertEqual(defaults.data(forKey: "fixture"), original)
        XCTAssertEqual(Data(try XCTUnwrap(store.encyclopedia(id: created.id)).name.utf8), Data(name.utf8))
        XCTAssertEqual(store.encyclopedia(id: created.id)?.subtitle, subtitle)
    }

    @MainActor
    func testLibraryTileDroppedIdentityFallsBackToOriginalProtectedCopy() async throws {
        let copy = Prompt10BookTileCopy(name: "private _name", subtitle: "private draft", chapters: 2, pages: 4, language: .french)
        let owner = FruitfolioControlTranslationState(service: FruitfolioTranslationService(runtime: LibraryTileFixtureRuntime(dropIdentity: true)))
        let key = FruitfolioControlTranslationState.Key(source: copy.accessibilitySource, language: .french,
            protectedLiterals: copy.accessibilityProtectedLiterals)
        await owner.resolve(key, inferenceAllowed: true)
        XCTAssertEqual(owner.presentation(for: key).status, .unavailable)
        XCTAssertEqual(Data(owner.presentation(for: key).text.utf8), Data(copy.accessibilitySource.utf8))
    }

    @MainActor
    func testLibraryOpeningCopyKeepsEscapedAuthoredNameOutOfInference() async throws {
        let name = "private _book* [cafe\u{301}]"
        let copy = Prompt10BookTileCopy.opening(name: name)
        let runtime = LibraryTileFixtureRuntime()
        let owner = FruitfolioControlTranslationState(service: FruitfolioTranslationService(runtime: runtime))
        let key = FruitfolioControlTranslationState.Key(source: copy.source, language: .french,
            protectedLiterals: copy.protectedLiterals)
        await owner.resolve(key, inferenceAllowed: true)
        XCTAssertEqual(owner.presentation(for: key).status, .machine)
        XCTAssertTrue(owner.presentation(for: key).text.contains(FruitfolioSemanticMarkup.markdown([.init(text: name)])))
        XCTAssertTrue(owner.presentation(for: key).text.contains("ouvrir le livre"))
        let inputs = await runtime.inputs
        XCTAssertFalse(try XCTUnwrap(inputs.first).contains("private"))
    }

    func testClinicalAndSexualHealthLabelsAreAllowedWithoutSubstringRejection() throws {
        for title in ["sexual health", "sex education", "consent after trauma", "rape recovery", "breast and cervical health", "assessment", "classical genetics"] {
            XCTAssertEqual(try Prompt10BookLabelPolicy.title(title), title)
        }
    }
    func testLimitsCountGraphemesAndNeverSilentlyTruncate() throws {
        let title = String(repeating: "👩🏽‍⚕️", count: 48)
        XCTAssertEqual(try Prompt10BookLabelPolicy.title(title), title)
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(title + "a"))
        XCTAssertEqual(try Prompt10BookLabelPolicy.description(String(repeating: "é", count: 160)).count, 160)
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.description(String(repeating: "é", count: 161)))
        XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(" \n "))
    }
    func testExplicitLabelsAndThreatsRejectedWithCaseWidthNormalization() {
        for text in ["FUCK", "ｓｈｉｔ", "kill yourself", "I will murder you", "my asshole guide"] {
            XCTAssertThrowsError(try Prompt10BookLabelPolicy.title(text))
            XCTAssertThrowsError(try Prompt10BookLabelPolicy.description(text))
        }
    }
}
