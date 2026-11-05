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

    private func page(location: Int = 0, language: String = "en", saveType: Prompt10SavedPageType = .excerpt) -> Prompt10SavedPage {
        Prompt10SavedPage(chapterID: UUID(), question: "fixture", answer: "E2 and E2 [source-1]",
                         saveType: saveType, excerptText: "E2", originalAnswerID: "answer-1", sourceIDs: ["source-1"],
                         excerptSemanticSpans: [.init(text: "E2", emphasis: .anchorBold)],
                         excerptSelectionLocation: location, excerptSelectionLength: 2, excerptLanguage: language)
    }
    func testSemanticExcerptRoundTripPreservesProvenanceAndExactOccurrence() throws {
        let original = page(location: 7, language: "es")
        let decoded = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.excerptSemanticSpans?.first?.emphasis, .anchorBold)
        XCTAssertEqual(decoded.sourceIDs, ["source-1"])
        XCTAssertEqual(decoded.answer, "E2 and E2 [source-1]")
    }
    func testLegacyPagesDecodeWithoutNewOptionalFields() throws {
        let original = page()
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        for field in ["excerptSemanticSpans", "excerptSelectionLocation", "excerptSelectionLength", "excerptLanguage"] {
            object.removeValue(forKey: field)
        }
        let restored = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONSerialization.data(withJSONObject: object))
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
