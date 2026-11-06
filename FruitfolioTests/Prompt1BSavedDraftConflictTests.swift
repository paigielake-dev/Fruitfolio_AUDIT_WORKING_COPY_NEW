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
    func testOldBookAndSectionMetadataDraftsCannotOverwriteNewerSharedEdits() async throws {
        for field in 0..<4 {
            let suite = "Fruitfolio.MetadataConflict." + UUID().uuidString
            let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }
            let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            let guide = try store.createGuideEncyclopedia(name: "QA original", subtitle: "original description", style: .sage)
            let chapter = try store.createChapter(in: guide.id, name: "original section")
            switch field {
            case 0: try store.renameEncyclopedia(id: guide.id, to: "newer name")
            case 1: try store.updateEncyclopediaDescription(id: guide.id, description: "newer description")
            case 2: try store.changeEncyclopediaStyle(id: guide.id, to: .pink)
            default: try store.renameChapter(encyclopediaID: guide.id, chapterID: chapter.id, to: "newer section")
            }
            let current = store.encyclopedias
            let bytes = defaults.data(forKey: "fixture")
            XCTAssertThrowsError(try {
                switch field {
                case 0: try store.renameEncyclopedia(id: guide.id, to: "stale name", expectedName: guide.name)
                case 1: try store.updateEncyclopediaDescription(id: guide.id, description: "stale description", expectedDescription: guide.subtitle)
                case 2: try store.changeEncyclopediaStyle(id: guide.id, to: .coral, expectedStyle: guide.style)
                default: try store.renameChapter(encyclopediaID: guide.id, chapterID: chapter.id, to: "stale section", expectedName: chapter.name)
                }
            }()) { XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged) }
            XCTAssertEqual(store.encyclopedias, current)
            XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
            XCTAssertNil(store.storageProtectionReason, "A field conflict must not poison unrelated writes")
            XCTAssertEqual(Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture").encyclopedias, current)
        }
    }

    func testMetadataEditorsMergeOnlyTheirFieldAndRetainUnrelatedSharedContent() async throws {
        let suite = "Fruitfolio.MetadataMerge." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let guide = try store.createGuideEncyclopedia(name: "QA original", subtitle: "original description", style: .sage)
        let chapter = try store.createChapter(in: guide.id, name: "original section")
        let page = try store.savePage(.init(chapterID: chapter.id, question: "QA question", answer: "QA exact answer", saveType: .fullAnswer, sourceIDs: ["qa-source"]), to: guide.id, chapterID: chapter.id)
        try store.changeEncyclopediaStyle(id: guide.id, to: .pink, expectedStyle: guide.style)
        try store.updateEncyclopediaDescription(id: guide.id, description: "edited description", expectedDescription: guide.subtitle)
        try store.renameEncyclopedia(id: guide.id, to: "edited name", expectedName: guide.name)
        try store.renameChapter(encyclopediaID: guide.id, chapterID: chapter.id, to: "edited section", expectedName: chapter.name)
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let current = try XCTUnwrap(reloaded.encyclopedia(id: guide.id))
        XCTAssertEqual(current.name, "edited name")
        XCTAssertEqual(current.subtitle, "edited description")
        XCTAssertEqual(current.style, .pink)
        XCTAssertEqual(current.chapters.first?.name, "edited section")
        XCTAssertEqual(current.chapters.first?.pages, [page])
        XCTAssertEqual(reloaded.prompt11Guides.first, current)
        XCTAssertEqual(reloaded.sorted(by: .alphabetical).first, current)
    }

    func testEmptyDescriptionBaselineIsCheckedAndConflictCanBeExplicitlyReopened() async throws {
        let suite = "Fruitfolio.EmptyMetadata." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let guide = try store.createGuideEncyclopedia(name: "QA original", subtitle: "", style: .sage)
        XCTAssertNil(guide.subtitle)
        try store.updateEncyclopediaDescription(id: guide.id, description: "newer description", expectedDescription: "")
        let bytes = defaults.data(forKey: "fixture")
        XCTAssertThrowsError(try store.updateEncyclopediaDescription(id: guide.id, description: "stale draft", expectedDescription: "")) {
            XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        try store.updateEncyclopediaDescription(id: guide.id, description: "explicitly reviewed draft", expectedDescription: "newer description")
        XCTAssertEqual(Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture").encyclopedia(id: guide.id)?.subtitle, "explicitly reviewed draft")
    }

}
