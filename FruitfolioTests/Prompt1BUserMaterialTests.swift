import XCTest
@testable import Fruitfolio

final class Prompt1BUserMaterialTests: XCTestCase {
    func testUserMaterialPreservesTextAndNeverClaimsApprovedResearchProvenance() throws {
        var draft = Prompt10UserMaterialDraft()
        draft.title = "sexual health reminders"
        draft.body = "  my independently collected material\nwith exact spacing  "
        draft.notes = "my reminder"
        draft.sourceURL = "https://example.org/user-supplied"
        let page = try draft.page(chapterID: UUID())
        XCTAssertEqual(page.answer, draft.body)
        XCTAssertEqual(page.notes, draft.notes)
        XCTAssertEqual(page.userMaterial?.sourceURL, draft.sourceURL)
        XCTAssertTrue(page.sourceIDs.isEmpty)
        XCTAssertNil(page.sourceRecords)
        XCTAssertNil(page.originalAnswerID)
        XCTAssertNil(page.knowledgeBaseVersion)
        let restored = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONEncoder().encode(page))
        XCTAssertEqual(restored, page)
    }
    func testEditingKeepsIdentityImagesAndCreationDateWhileAllowingChapterChange() throws {
        var draft = Prompt10UserMaterialDraft()
        draft.title = "my notes"; draft.body = "original"
        let firstDate = Date(timeIntervalSince1970: 20)
        var page = try draft.page(chapterID: UUID(), now: firstDate)
        page.importedImageIDs = ["owned-image"]
        draft = .init(page: page); draft.body = "edited by me"
        let chapter = UUID()
        let updated = try draft.page(chapterID: chapter, existing: page, now: Date(timeIntervalSince1970: 40))
        XCTAssertEqual(updated.id, page.id)
        XCTAssertEqual(updated.userMaterial?.addedAt, firstDate)
        XCTAssertEqual(updated.chapterID, chapter)
        XCTAssertEqual(updated.importedImageIDs, ["owned-image"])
        XCTAssertEqual(updated.answer, draft.body)
    }
    func testOriginalAskEvidenceCannotBeOverwrittenByUserEditor() throws {
        var draft = Prompt10UserMaterialDraft(); draft.title = "my notes"; draft.body = "new text"
        let approved = Prompt10SavedPage(chapterID: UUID(), question: "question", answer: "approved evidence", saveType: .fullAnswer)
        XCTAssertThrowsError(try draft.page(chapterID: approved.chapterID, existing: approved))
    }
    func testPersistedNoteEditsRefreshCleanDraftWithoutReplacingUnsavedText() {
        let id = UUID()
        var draft = Prompt10NoteDraft()
        draft.load(pageID: id, notes: "old")
        draft.load(pageID: id, notes: "edited in own-page editor")
        XCTAssertEqual(draft.text, "edited in own-page editor")
        draft.text = "unsaved"
        draft.load(pageID: id, notes: "external redraw")
        XCTAssertEqual(draft.text, "unsaved")
        XCTAssertTrue(draft.hasChanges)
    }
    func testReplacementPreservesOrderingAndRejectsADeletedOrDuplicateTarget() throws {
        XCTAssertEqual(try Prompt10ImageAttachmentMutation.attaching("new", replacing: "middle", to: ["first", "middle", "last"]), ["first", "new", "last"])
        XCTAssertThrowsError(try Prompt10ImageAttachmentMutation.attaching("new", replacing: "deleted", to: ["first"]))
        XCTAssertThrowsError(try Prompt10ImageAttachmentMutation.attaching("first", replacing: nil, to: ["first"]))
        XCTAssertEqual(try Prompt10ImageAttachmentMutation.attaching("new", replacing: nil, to: ["first"]), ["first", "new"])
    }
    func testInvalidAddressesAndEmptyContentFailBeforePersistence() {
        var draft = Prompt10UserMaterialDraft(); draft.title = "my notes"
        XCTAssertThrowsError(try draft.page(chapterID: UUID()))
        draft.body = "my text"
        for address in ["javascript:alert(1)", "file:///private/file", "https://user:password@example.org", "https://", "https://example.org/a b"] {
            draft.sourceURL = address
            XCTAssertThrowsError(try draft.page(chapterID: UUID()))
        }
    }
}
