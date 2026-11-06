import Foundation
import XCTest
@testable import Fruitfolio

@MainActor
final class Prompt1BSavedDraftConflictTests: XCTestCase {
    func testOldNoteDraftCannotOverwriteNewerNotesOrSourceMetadata() async throws {
        let suite = "Fruitfolio.NoteConflict." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let book = try store.createEncyclopedia(name: "QA book", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let page = try store.savePage(.init(chapterID: chapter.id, question: "QA source question",
            answer: "12.500 pg/mL [fixture-source]", saveType: .fullAnswer, originalAnswerID: "fixture-answer",
            sourceIDs: ["fixture-source"], sourceVersions: ["fixture-source": "original-v1"], notes: "original notes"),
            to: book.id, chapterID: chapter.id)
        try store.updatePageNotes(encyclopediaID: book.id, chapterID: chapter.id, pageID: page.id,
            notes: "newer note", expectedNotes: "original notes")
        let bytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.updatePageNotes(encyclopediaID: book.id, chapterID: chapter.id,
            pageID: page.id, notes: "stale editor note", expectedNotes: "original notes")) {
            XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        let current = try XCTUnwrap(store.encyclopedia(id: book.id)?.chapters.first?.pages.first)
        XCTAssertEqual(current.notes, "newer note")
        XCTAssertEqual(current.answer, page.answer)
        XCTAssertEqual(current.sourceIDs, page.sourceIDs)
        XCTAssertEqual(current.sourceVersions, page.sourceVersions)
        XCTAssertEqual(current.originalAnswerID, page.originalAnswerID)
    }

    func testIndependentImageUpdatesSurviveBothNoteAndUserPageSaves() async throws {
        let suite = "Fruitfolio.DraftMedia." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let book = try store.createEncyclopedia(name: "QA book", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        var draft = Prompt10UserMaterialDraft()
        draft.title = "my page"; draft.body = "exact original own wording"; draft.notes = "original notes"
        let page = try store.saveUserMaterial(draft, to: book.id, chapterID: chapter.id)
        let baseline = Prompt10UserMaterialEditingBaseline(page: page)
        let image = UUID().uuidString.lowercased()
        try store.setImportedImageIDs(encyclopediaID: book.id, chapterID: chapter.id, pageID: page.id, imageIDs: [image])
        var edited = draft
        edited.body = "my explicitly edited wording"
        let saved = try store.saveUserMaterial(edited, to: book.id, chapterID: chapter.id,
            existingPageID: page.id, expectedBaseline: baseline)
        XCTAssertEqual(saved.importedImageIDs, [image])
        XCTAssertEqual(saved.answer, edited.body)
        let secondImage = UUID().uuidString.lowercased()
        try store.setImportedImageIDs(encyclopediaID: book.id, chapterID: chapter.id, pageID: page.id, imageIDs: [image, secondImage])
        try store.updatePageNotes(encyclopediaID: book.id, chapterID: chapter.id, pageID: page.id,
            notes: "my newly saved note", expectedNotes: saved.notes)
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let current = try XCTUnwrap(reloaded.encyclopedia(id: book.id)?.chapters.first?.pages.first)
        XCTAssertEqual(current.importedImageIDs, [image, secondImage])
        XCTAssertEqual(current.notes, "my newly saved note")
        XCTAssertEqual(current.answer, edited.body)
        XCTAssertNil(current.originalAnswerID)
        XCTAssertTrue(current.sourceIDs.isEmpty)
    }

    func testOldUserPageDraftCannotOverwriteTextNotesSourceOrChapterChanges() async throws {
        let suite = "Fruitfolio.UserPageConflict." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let book = try store.createEncyclopedia(name: "QA book", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        var draft = Prompt10UserMaterialDraft()
        draft.title = "my page"; draft.body = "original body"; draft.notes = "original notes"
        let page = try store.saveUserMaterial(draft, to: book.id, chapterID: chapter.id)
        let baseline = Prompt10UserMaterialEditingBaseline(page: page)
        var newer = draft
        newer.notes = "newer notes"; newer.sourceURL = "https://example.invalid/user-supplied"
        let current = try store.saveUserMaterial(newer, to: book.id, chapterID: chapter.id, existingPageID: page.id)
        let bytes = defaults.data(forKey: "fixture")
        var oldEdit = draft; oldEdit.body = "stale body edit"
        XCTAssertThrowsError(try store.saveUserMaterial(oldEdit, to: book.id, chapterID: chapter.id,
            existingPageID: page.id, expectedBaseline: baseline)) {
            XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        XCTAssertEqual(store.encyclopedia(id: book.id)?.chapters.first?.pages.first, current)
        let currentBaseline = Prompt10UserMaterialEditingBaseline(page: current)
        let otherChapter = try store.createChapter(in: book.id, name: "another chapter")
        _ = try store.saveUserMaterial(newer, to: book.id, chapterID: otherChapter.id, existingPageID: page.id)
        let movedBytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.saveUserMaterial(oldEdit, to: book.id, chapterID: chapter.id,
            existingPageID: page.id, expectedBaseline: currentBaseline))
        XCTAssertEqual(defaults.data(forKey: "fixture"), movedBytes)
    }
}
