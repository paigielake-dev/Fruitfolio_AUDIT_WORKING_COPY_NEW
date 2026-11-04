import XCTest
@testable import Fruitfolio

@MainActor
final class ChapterManagementTests: XCTestCase {
    func testMoveRenameAndReloadPreserveTheSameEvidenceAndUserFormatting() throws {
        let suite = "ChapterMoves-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "chapters")
        let book = try store.createEncyclopedia(name: "my materials", style: .pink)
        let first = try XCTUnwrap(book.chapters.first)
        let target = try store.createChapter(in: book.id, name: "my reminders")
        let document = FruitfolioSemanticDocument(spans: [.init(text: "keep this wording", emphasis: .spokenItalic)])
        let original = try store.savePage(.init(chapterID: first.id, question: "approved answer",
            answer: document.plainText, saveType: .fullAnswer, sourceIDs: ["source"],
            sourceVersions: ["source":"v2"], semanticDocument: document), to: book.id, chapterID: first.id)
        try store.movePage(encyclopediaID: book.id, pageID: original.id, fromChapterID: first.id, toChapterID: target.id)
        try store.renameChapter(encyclopediaID: book.id, chapterID: target.id, to: "chosen location")
        store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "chapters")
        let chapters = try XCTUnwrap(store.encyclopedia(id: book.id)?.chapters)
        XCTAssertTrue(try XCTUnwrap(chapters.first { $0.id == first.id }).pages.isEmpty)
        let restored = try XCTUnwrap(chapters.first { $0.id == target.id })
        XCTAssertEqual(restored.name, "chosen location")
        let page = try XCTUnwrap(restored.pages.first)
        XCTAssertEqual(page.id, original.id)
        XCTAssertEqual(page.chapterID, target.id)
        XCTAssertEqual(page.sourceIDs, original.sourceIDs)
        XCTAssertEqual(page.sourceVersions, original.sourceVersions)
        XCTAssertEqual(page.resolvedSemanticDocument, document)
        XCTAssertEqual(page.order, 0)
    }

    func testInvalidChapterChangeDoesNotRemovePagesAndDeletionLeavesOtherChaptersIntact() throws {
        let suite = "ChapterDelete-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "chapters")
        let book = try store.createEncyclopedia(name: "my materials", style: .sage)
        let first = try XCTUnwrap(book.chapters.first)
        let target = try store.createChapter(in: book.id, name: "keep me")
        let page = try store.savePage(.init(chapterID: first.id, question: "q", answer: "body", saveType: .fullAnswer),
            to: book.id, chapterID: first.id)
        XCTAssertThrowsError(try store.renameChapter(encyclopediaID: book.id, chapterID: first.id, to: "  "))
        XCTAssertThrowsError(try store.movePage(encyclopediaID: book.id, pageID: page.id,
            fromChapterID: first.id, toChapterID: UUID()))
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.pages.first?.id, page.id)
        try store.deleteChapter(encyclopediaID: book.id, chapterID: first.id)
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.count, 1)
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.id, target.id)
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.order, 0)
    }
}
