import XCTest
@testable import Fruitfolio

@MainActor
final class UserAuthoredPageTests: XCTestCase {
    func testCreateEditReloadAndFormattingAreSeparateFromApprovedResearch() throws {
        let suite = "UserPage-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "user-pages")
        let book = try store.createEncyclopedia(name: "my writing", style: .pink)
        let chapter = try XCTUnwrap(book.chapters.first)
        let text = "my reminder: ask my clinician."
        let plain = FruitfolioSemanticDocument(spans: [.init(text: text)])
        let styled = try XCTUnwrap(plain.applying(.actionableBoldUnderline,
            utf16Range: (text as NSString).range(of: "ask my clinician")))
        let page = try store.saveUserPage(pageID: nil, encyclopediaID: book.id, chapterID: chapter.id,
            title: "reminder", document: styled, imageIDs: [])
        XCTAssertEqual(page.isUserAuthored, true)
        XCTAssertTrue(page.sourceIDs.isEmpty, "User writing must not acquire fabricated approved citations")
        XCTAssertNil(page.originalAnswerID)
        store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "user-pages")
        let restored = try XCTUnwrap(store.encyclopedia(id: book.id)?.chapters.first?.pages.first)
        XCTAssertEqual(restored.resolvedSemanticDocument, styled)
        let edited = try store.saveUserPage(pageID: page.id, encyclopediaID: book.id, chapterID: chapter.id,
            title: "changed reminder", document: .init(spans: [.init(text: "edited writing")]), imageIDs: [])
        XCTAssertEqual(edited.id, page.id)
        store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "user-pages")
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.pages.count, 1)
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.pages.first?.answer, "edited writing")
    }

    func testManualEditorCannotRewriteSourcedEvidenceAndRejectsEmptyDraft() throws {
        let suite = "ReadOnly-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "user-pages")
        let book = try store.createEncyclopedia(name: "evidence", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let source = try store.savePage(.init(chapterID: chapter.id, question: "source", answer: "immutable source",
            saveType: .fullAnswer, sourceIDs: ["approved-fixture"]), to: book.id, chapterID: chapter.id)
        XCTAssertThrowsError(try store.saveUserPage(pageID: source.id, encyclopediaID: book.id,
            chapterID: chapter.id, title: "changed", document: .init(spans: [.init(text: "altered")]), imageIDs: []))
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.pages.first?.answer, "immutable source")
        XCTAssertThrowsError(try store.saveUserPage(pageID: nil, encyclopediaID: book.id,
            chapterID: chapter.id, title: "", document: .init(spans: [.init(text: "body")]), imageIDs: []))
        XCTAssertThrowsError(try store.saveUserPage(pageID: nil, encyclopediaID: book.id,
            chapterID: chapter.id, title: "title", document: .init(spans: []), imageIDs: []))
    }
}

extension UserAuthoredPageTests {
    func testEditorCombinesAndTogglesTraitsWithoutRewritingUserText() throws {
        let original = FruitfolioSemanticDocument(spans: [.init(text: "my own reminder 🧬")])
        let range = (original.plainText as NSString).range(of: "own reminder")
        let bold = try XCTUnwrap(original.toggling(.anchorBold, utf16Range: range))
        let both = try XCTUnwrap(bold.toggling(.symptomOrPracticalUnderline, utf16Range: range))
        XCTAssertEqual(try XCTUnwrap(both.slice(utf16Range: range)).spans.first?.emphasis, .actionableBoldUnderline)
        let underlineOnly = try XCTUnwrap(both.toggling(.anchorBold, utf16Range: range))
        XCTAssertEqual(try XCTUnwrap(underlineOnly.slice(utf16Range: range)).spans.first?.emphasis, .symptomOrPracticalUnderline)
        XCTAssertEqual(underlineOnly.plainText, original.plainText)
        let plain = try XCTUnwrap(underlineOnly.toggling(.plain, utf16Range: range))
        XCTAssertTrue(plain.spans.allSatisfy { $0.emphasis == .plain })
        let attributed = FruitfolioSemanticAttributedRenderer.render(both)
        let reconstructed = FruitfolioSemanticAttributedRenderer.document(from: attributed)
        XCTAssertEqual(reconstructed.plainText, original.plainText)
        XCTAssertEqual(try XCTUnwrap(reconstructed.slice(utf16Range: range)).spans.first?.emphasis, .actionableBoldUnderline)
    }
}
