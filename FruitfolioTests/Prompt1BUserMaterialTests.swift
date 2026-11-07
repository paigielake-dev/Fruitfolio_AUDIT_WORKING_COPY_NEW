import XCTest
@testable import Fruitfolio

final class Prompt1BUserMaterialTests: XCTestCase {
    func testActualDraftValidationErrorsAuthorizeOnlyTypedCopyAndPreserveDraftBytes() throws {
        var valid = Prompt10UserMaterialDraft()
        valid.title = "my material"; valid.body = "  cafe\u{301} 12,50 µg/L\n"
        valid.notes = "  preserve my notes  "
        var empty = valid; empty.body = "  \n"
        var long = valid; long.body = String(repeating: "a", count: Prompt10UserMaterialDraft.maximumBodyLength + 1)
        var address = valid; address.sourceURL = "https://private:credential@example.org/author-input"
        let cases: [(Prompt10UserMaterialDraft, Prompt10UserMaterialDraft.Failure)] = [
            (empty, .emptyBody), (long, .tooLong), (address, .invalidSourceURL)]
        for (draft, expected) in cases {
            let snapshot = draft
            XCTAssertThrowsError(try draft.page(chapterID: UUID())) { error in
                let notice = Prompt10SavedPageNotice(error: error)
                XCTAssertEqual(notice, .userMaterial(expected))
                XCTAssertNotNil(notice.controlledSource)
                if expected == .tooLong { XCTAssertEqual(notice.protectedLiterals, ["100,000", "50,000"]) }
            }
            XCTAssertEqual(Data(draft.body.utf8), Data(snapshot.body.utf8))
            XCTAssertEqual(Data(draft.notes.utf8), Data(snapshot.notes.utf8))
            XCTAssertEqual(Data(draft.sourceURL.utf8), Data(snapshot.sourceURL.utf8))
        }
        let approved = Prompt10SavedPage(chapterID: UUID(), question: "original", answer: "approved source", saveType: .fullAnswer)
        XCTAssertThrowsError(try valid.page(chapterID: approved.chapterID, existing: approved)) { error in
            XCTAssertEqual(Prompt10SavedPageNotice(error: error), .userMaterial(.immutableEvidence))
        }
        XCTAssertNotNil(Prompt10SavedPageNotice.chooseChapter.controlledSource)
    }

    func testEditorCharacterLimitsRemainExactAcrossScientificTranslationEnvelope() throws {
        let notice = Prompt10SavedPageNotice.userMaterial(.tooLong)
        let envelope = try FruitfolioScientificTranslationEnvelope(notice.source, protectedLiterals: notice.protectedLiterals)
        XCTAssertFalse(envelope.prepared.contains("100,000"))
        XCTAssertFalse(envelope.prepared.contains("50,000"))
        XCTAssertEqual(try envelope.restore(envelope.prepared), notice.source)
        for limit in notice.protectedLiterals {
            XCTAssertThrowsError(try envelope.validateCatalogCandidate(notice.source.replacingOccurrences(of: limit, with: "999")))
        }
    }

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
