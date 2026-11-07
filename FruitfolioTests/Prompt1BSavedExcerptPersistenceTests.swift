import XCTest
@testable import Fruitfolio

final class Prompt1BSavedExcerptPersistenceTests: XCTestCase {
    func testNoteDraftSurvivesMediaRefreshAndResetsOnlyForAnotherPage() {
        var draft = Prompt10NoteDraft()
        let id = UUID()
        draft.load(pageID: id, notes: "original")
        draft.text = "  my draft\n"
        draft.load(pageID: id, notes: "stale snapshot")
        XCTAssertEqual(draft.text, "  my draft\n")
        XCTAssertTrue(draft.hasChanges)
        draft.didSave()
        XCTAssertFalse(draft.hasChanges)
        draft.text = "discard me"
        draft.discard()
        XCTAssertEqual(draft.text, "  my draft\n")
        draft.load(pageID: UUID(), notes: "another page")
        XCTAssertEqual(draft.text, "another page")
        XCTAssertFalse(draft.hasChanges)
    }

    func testImageRemainsReferencedAfterOriginalSnapshotDetachesIt() throws {
        let bookID = UUID(), chapterID = UUID()
        var original = page()
        original.importedImageIDs = ["shared-image"]
        var reference = original
        reference.sourceSavedPageID = original.id
        original.importedImageIDs = []
        let book = Prompt10Encyclopedia(id: bookID, name: "fixture", style: .sage,
            chapters: [.init(id: chapterID, encyclopediaID: bookID, name: "chapter", order: 0, pages: [original, reference])])
        XCTAssertTrue(Prompt10MediaReferences.contains("shared-image", in: [book]))
        var detached = book
        detached.chapters[0].pages = [original]
        XCTAssertFalse(Prompt10MediaReferences.contains("shared-image", in: [detached]))
        let restored = try JSONDecoder().decode(Prompt10Encyclopedia.self, from: JSONEncoder().encode(book))
        XCTAssertTrue(Prompt10MediaReferences.contains("shared-image", in: [restored]))
    }

    func testScientificImageSelectionPersistsWithoutUnsavedAnswerAndDistinguishesSaveVariants() throws {
        let art: FruitfolioAssetID = .ovarian_cycle_follicle_development_stages
        var textOnly = page()
        var withImage = textOnly
        withImage.educationalAssetIDs = [art]
        XCTAssertFalse(textOnly.isDuplicateSave(of: withImage))
        let restored = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONEncoder().encode(withImage))
        XCTAssertEqual(restored.educationalAssetIDs, [art])
        var imageOnly = withImage
        imageOnly.answer = ""
        imageOnly.excerptText = ""
        imageOnly.excerptSelectionLocation = nil
        imageOnly.excerptSelectionLength = nil
        XCTAssertTrue(imageOnly.isDuplicateSave(of: imageOnly))
        XCTAssertFalse(imageOnly.isDuplicateSave(of: textOnly))
        textOnly.educationalAssetIDs = []
        XCTAssertNil(page().educationalAssetIDs)
    }

    private func page(location: Int = 0, language: String = "en", saveType: Prompt10SavedPageType = .excerpt) -> Prompt10SavedPage {
        Prompt10SavedPage(chapterID: UUID(), question: "fixture", answer: "E2 and E2 [source-1]",
                         saveType: saveType, excerptText: "E2", originalAnswerID: "answer-1", sourceIDs: ["source-1"],
                         excerptSemanticSpans: [.init(text: "E2", emphasis: .anchorBold)],
                         excerptSelectionLocation: location, excerptSelectionLength: 2, excerptLanguage: language,
                         sourceRecords: [.init(id: "source-1", title: "Original verified reference", urlString: "https://example.org/source", doi: "10.1000/fixture", publicationData: "2024", contentVersion: "v1")])
    }
    func testSemanticExcerptRoundTripPreservesProvenanceAndExactOccurrence() throws {
        let original = page(location: 7, language: "es")
        let decoded = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.excerptSemanticSpans?.first?.emphasis, .anchorBold)
        XCTAssertEqual(decoded.sourceIDs, ["source-1"])
        XCTAssertEqual(decoded.sourceRecords, original.sourceRecords)
        XCTAssertEqual(decoded.answer, "E2 and E2 [source-1]")
    }
    func testLegacyPagesDecodeWithoutNewOptionalFields() throws {
        let original = page()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        for field in ["excerptSemanticSpans", "excerptSelectionLocation", "excerptSelectionLength", "excerptLanguage", "sourceRecords", "educationalAssetIDs"] {
            object.removeValue(forKey: field)
        }
        let restored = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(restored.educationalAssetIDs)
        XCTAssertNil(restored.sourceRecords)
        XCTAssertNil(restored.excerptSemanticSpans)
        XCTAssertNil(restored.excerptSelectionLocation)
        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.sourceIDs, original.sourceIDs)
    }
    func testDifferentExcerptsAndFullAnswerCanBeSavedFromSameAnswer() {
        let first = page(location: 0)
        XCTAssertFalse(first.isDuplicateSave(of: page(location: 7)))
        XCTAssertFalse(first.isDuplicateSave(of: page(language: "es")))
        XCTAssertFalse(first.isDuplicateSave(of: page(saveType: .fullAnswer)))
        XCTAssertTrue(first.isDuplicateSave(of: page(location: 0)))
    }
}

@MainActor
final class Prompt1BLegacyExcerptRecoveryTests: XCTestCase {
    private func fixture() throws -> (UserDefaults, String, Prompt10SavedLibraryStore, Prompt10Encyclopedia) {
        let suite = "fruitfolio.legacyExcerpt." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let book = try store.createEncyclopedia(name: "fixture", style: .sage)
        return (defaults, suite, store, book)
    }
    private func legacy(_ chapter: UUID) -> Prompt10SavedPage {
        .init(chapterID: chapter, question: "original", answer: "selected + private remainder", saveType: .excerpt,
              excerptText: "selected", originalAnswerID: "original-answer", sourceIDs: ["source-1"],
              notes: "independent note", importedImageIDs: ["independent-image"], excerptLanguage: "es")
    }
    func testInspectionNeverMutatesLegacyBytesAndMissingSelectionCannotBeCleaned() async throws {
        let (defaults, suite, store, book) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        var page = legacy(book.chapters[0].id)
        page.excerptText = nil
        let saved = try store.savePage(page, to: book.id, chapterID: page.chapterID)
        let before = defaults.data(forKey: "library")
        XCTAssertTrue(saved.hasLegacyExcerptRemainder)
        XCTAssertFalse(saved.canReviewLegacyExcerptCleanup)
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        XCTAssertEqual(reopened.encyclopedias, store.encyclopedias)
        XCTAssertThrowsError(try store.removeLegacyExcerptRemainder(afterConfirming: saved))
        XCTAssertEqual(defaults.data(forKey: "library"), before)
        var full = saved; full.saveType = .fullAnswer
        XCTAssertFalse(full.hasLegacyExcerptRemainder)
        var selected = saved; selected.excerptText = selected.answer
        XCTAssertFalse(selected.hasLegacyExcerptRemainder)
        selected.excerptText = ""; selected.answer = ""
        XCTAssertFalse(selected.hasLegacyExcerptRemainder)
    }
    func testExplicitCleanupUpdatesLinkedCopiesAndPreservesIndependentFieldsAndReload() async throws {
        let (defaults, suite, store, book) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let saved = try store.savePage(legacy(book.chapters[0].id), to: book.id, chapterID: book.chapters[0].id)
        let other = try store.createEncyclopedia(name: "linked", style: .sage)
        var linked = Prompt10SavedPage(chapterID: other.chapters[0].id, question: saved.question,
            answer: saved.answer, saveType: .excerpt, excerptText: saved.excerptText,
            originalAnswerID: saved.originalAnswerID, notes: "separate linked note", sourceSavedPageID: saved.id,
            excerptLanguage: saved.excerptLanguage)
        linked.importedImageIDs = ["linked-image"]
        _ = try store.savePage(linked, to: other.id, chapterID: linked.chapterID)
        try store.updatePageNotes(encyclopediaID: book.id, chapterID: saved.chapterID, pageID: saved.id, notes: "new independent note")
        let result = try store.removeLegacyExcerptRemainder(afterConfirming: saved)
        XCTAssertEqual(result.answer, "selected")
        XCTAssertEqual(result.notes, "new independent note")
        XCTAssertEqual(result.importedImageIDs, saved.importedImageIDs)
        XCTAssertEqual(result.sourceIDs, saved.sourceIDs)
        XCTAssertEqual(result.excerptLanguage, "es")
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let pages = reopened.encyclopedias.flatMap(\.chapters).flatMap(\.pages)
        XCTAssertEqual(pages.count, 2)
        XCTAssertTrue(pages.allSatisfy { $0.answer == "selected" && !$0.hasLegacyExcerptRemainder })
        XCTAssertEqual(pages.first { $0.id == linked.id }?.notes, "separate linked note")
        XCTAssertEqual(pages.first { $0.id == linked.id }?.importedImageIDs, ["linked-image"])
        XCTAssertThrowsError(try store.removeLegacyExcerptRemainder(afterConfirming: saved))
    }
    func testConflictingLinkedCopyRejectsEntireCleanupWithoutWriting() async throws {
        let (defaults, suite, store, book) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        let saved = try store.savePage(legacy(book.chapters[0].id), to: book.id, chapterID: book.chapters[0].id)
        var linked = Prompt10SavedPage(chapterID: saved.chapterID, question: saved.question, answer: "different original",
            saveType: .excerpt, excerptText: saved.excerptText, originalAnswerID: saved.originalAnswerID,
            sourceSavedPageID: saved.id, excerptLanguage: "es")
        linked.notes = "do not overwrite"
        _ = try store.savePage(linked, to: book.id, chapterID: saved.chapterID)
        let before = defaults.data(forKey: "library"), snapshot = store.encyclopedias
        XCTAssertThrowsError(try store.removeLegacyExcerptRemainder(afterConfirming: saved)) {
            XCTAssertEqual($0 as? Prompt10LibraryError, .contentChanged)
        }
        XCTAssertEqual(defaults.data(forKey: "library"), before)
        XCTAssertEqual(store.encyclopedias, snapshot)
    }
    func testCleanupStripsLegacyFullConceptMapAndProtectedFutureDataIsPreserved() async throws {
        let (defaults, suite, store, book) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        var page = legacy(book.chapters[0].id)
        let response = AskAnswer(originalQuestion: "fixture", answerText: page.answer, support: .partiallySupported,
            supportMap: [.init(concept: "private remainder concept", support: .genuinelyNovel)], knowledgeBaseVersion: "fixture")
        // Reproduce a decoded legacy full-answer support map on an excerpt.
        page.evidenceSupport = Prompt09SavedAnswerSupport(answer: response)
        let saved = try store.savePage(page, to: book.id, chapterID: page.chapterID)
        let bytes = try XCTUnwrap(defaults.data(forKey: "library"))
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [[String: Any]])
        root[0]["futureLibraryField"] = "preserve original"
        let future = try JSONSerialization.data(withJSONObject: root)
        defaults.set(future, forKey: "library")
        let protected = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        XCTAssertThrowsError(try protected.removeLegacyExcerptRemainder(afterConfirming: saved))
        XCTAssertEqual(defaults.data(forKey: "library"), future)
        defaults.set(bytes, forKey: "library")
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "library")
        let cleaned = try reopened.removeLegacyExcerptRemainder(afterConfirming: saved)
        XCTAssertNil(cleaned.evidenceSupport?.concepts)
        XCTAssertEqual(cleaned.evidenceSupport?.scope, .excerpt)
        XCTAssertEqual(cleaned.evidenceSupport?.classification, .partiallySupported)
        XCTAssertFalse(String(decoding: try XCTUnwrap(defaults.data(forKey: "library")), as: UTF8.self).contains("private remainder concept"))
    }

    func testUnicodeByteDifferenceIsNotSilentlyTreatedAsSamePayload() async throws {
        let (defaults, suite, store, book) = try fixture()
        defer { defaults.removePersistentDomain(forName: suite) }
        var page = legacy(book.chapters[0].id)
        page.answer = "café"; page.excerptText = "cafe\u{301}"
        let saved = try store.savePage(page, to: book.id, chapterID: page.chapterID)
        XCTAssertTrue(saved.hasLegacyExcerptRemainder)
        var stale = saved; stale.answer = "cafe\u{301} plus remainder"
        let before = defaults.data(forKey: "library")
        XCTAssertThrowsError(try store.removeLegacyExcerptRemainder(afterConfirming: stale))
        XCTAssertEqual(defaults.data(forKey: "library"), before)
        let cleaned = try store.removeLegacyExcerptRemainder(afterConfirming: saved)
        XCTAssertEqual(Data(cleaned.answer.utf8), Data("cafe\u{301}".utf8))
    }
}
