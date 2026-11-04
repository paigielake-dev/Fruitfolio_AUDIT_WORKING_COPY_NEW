import XCTest
@testable import Fruitfolio

final class PhotoImportOwnershipTests: XCTestCase {
    func testOldCancelledCompletionCannotEnableSaveWhileReplacementPhotoIsLoading() {
        var owner = Prompt10ImportOwnership()
        let old = owner.begin()
        let current = owner.begin()
        XCTAssertFalse(owner.owns(old))
        XCTAssertFalse(owner.finish(old))
        XCTAssertTrue(owner.isImporting, "The newer transfer must retain the actual save/discard guard")
        XCTAssertTrue(owner.owns(current))
        XCTAssertTrue(owner.finish(current))
        XCTAssertFalse(owner.isImporting)
    }

    func testDismissedEditorCannotAcceptLatePhotoOrClearTheNextEditorsTransfer() {
        var owner = Prompt10ImportOwnership()
        let abandoned = owner.begin()
        owner.invalidate()
        XCTAssertFalse(owner.owns(abandoned))
        XCTAssertFalse(owner.finish(abandoned))
        let reopened = owner.begin()
        XCTAssertFalse(owner.finish(abandoned))
        XCTAssertTrue(owner.owns(reopened))
        XCTAssertTrue(owner.isImporting)
        owner.invalidate()
        XCTAssertFalse(owner.isImporting)
    }
}

final class SavedSemanticByteIntegrityTests: XCTestCase {
    func testStylingCannotNormalizeOriginalSavedAnswerOrUserExcerptBytes() {
        let original = "2.500 ng/mL — café [original-source]"
        let altered = original.replacingOccurrences(of: "é", with: "e\u{301}")
        let semantic = FruitfolioSemanticDocument(spans: [.init(text: altered, emphasis: .anchorBold)])
        let full = Prompt10SavedPage(chapterID: UUID(), question: "original record", answer: original,
            saveType: .fullAnswer, semanticDocument: semantic)
        XCTAssertEqual(Array(full.resolvedSemanticDocument.plainText.utf8), Array(original.utf8))
        XCTAssertTrue(full.resolvedSemanticDocument.spans.allSatisfy { $0.emphasis == .plain })
        let excerpt = Prompt10SavedPage(chapterID: UUID(), question: "my writing", answer: "source body",
            saveType: .excerpt, excerptText: original, semanticDocument: semantic, isUserAuthored: true)
        XCTAssertEqual(Array(excerpt.resolvedSemanticDocument.plainText.utf8), Array(original.utf8))
        XCTAssertEqual(excerpt.answer, "source body")
    }
}
