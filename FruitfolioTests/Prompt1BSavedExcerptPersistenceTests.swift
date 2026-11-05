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
