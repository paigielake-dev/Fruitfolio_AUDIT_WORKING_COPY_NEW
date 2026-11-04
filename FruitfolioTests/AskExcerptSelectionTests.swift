import XCTest
@testable import Fruitfolio

final class AskExcerptSelectionTests: XCTestCase {
    private func answer(_ document: FruitfolioSemanticDocument) -> AskAnswer {
        AskAnswer(originalQuestion: "selection identity fixture", answerText: document.plainText,
            support: .supported, sourceIDs: ["fixture-source-v1"],
            sources: [.init(id: "fixture-source-v1", title: "Fixture", contentVersion: "original-v1")],
            knowledgeBaseVersion: "fixture-library-v1", semanticDocument: document)
    }

    func testIdenticalWordsFromDifferentAnswersAndDifferentOccurrencesHaveDistinctSavedBadges() throws {
        let text = "2.500 ng/mL; second observation: 2.500 ng/mL"
        let document = FruitfolioSemanticDocument(spans: [.init(text: text, emphasis: .anchorBold)])
        let first = answer(document), second = answer(document)
        let rangeA = (text as NSString).range(of: "2.500 ng/mL")
        let rangeB = (text as NSString).range(of: "2.500 ng/mL", options: .backwards)
        let a = try XCTUnwrap(AskExcerptSelection(text: "2.500 ng/mL", range: rangeA).validated(for: first))
        let b = try XCTUnwrap(AskExcerptSelection(text: "2.500 ng/mL", range: rangeB).validated(for: first))
        let c = try XCTUnwrap(AskExcerptSelection(text: "2.500 ng/mL", range: rangeA).validated(for: second))
        let saved: Set<AskExcerptIdentity> = [a.identity]
        XCTAssertFalse(saved.contains(b.identity), "Saving one occurrence must not falsely mark a different occurrence saved")
        XCTAssertFalse(saved.contains(c.identity), "Identical wording from another answer retains its own source attribution and save state")
        XCTAssertEqual(Set([a.identity, b.identity, c.identity]).count, 3)
    }

    func testSelectedBytesAndSemanticRolesRemainOriginalWithoutChangingAnswerCitations() throws {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "e\u{301} — "), .init(text: "2.500 ng/mL", emphasis: .anchorBold),
            .init(text: " does not establish a diagnosis [fixture-source-v1].")
        ])
        let original = answer(document)
        let bytes = try JSONEncoder().encode(original)
        let range = (original.answerText as NSString).range(of: "2.500 ng/mL")
        let selected = try XCTUnwrap(AskExcerptSelection(text: "2.500 ng/mL", range: range).validated(for: original))
        XCTAssertEqual(Array(selected.document.plainText.utf8), Array("2.500 ng/mL".utf8))
        XCTAssertTrue(selected.document.spans.allSatisfy { $0.emphasis == .anchorBold })
        XCTAssertEqual(selected.identity.answerID, original.id)
        let restored = try JSONDecoder().decode(AskAnswer.self, from: bytes)
        XCTAssertEqual(restored, original)
        XCTAssertEqual(restored.sources.first?.contentVersion, "original-v1")
    }

    func testStaleTextOrInvalidUnicodeSelectionCannotCreateASavePayload() {
        let original = answer(.init(spans: [.init(text: "e\u{301} 2.500 ng/mL")]))
        for selection in [AskExcerptSelection(text: "e", range: NSRange(location: 0, length: 1)),
                          .init(text: "3.500 ng/mL", range: (original.answerText as NSString).range(of: "2.500 ng/mL")),
                          .init(text: "2.500 ng/mL", range: nil),
                          .init(text: "", range: NSRange(location: 0, length: 0)),
                          .init(text: "2.500 ng/mL", range: NSRange(location: Int.max, length: 1))] {
            XCTAssertNil(selection.validated(for: original))
        }
    }

    func testCanonicalUnicodeEquivalenceCannotSilentlyReplaceOriginalAnswerBytesDuringStyling() {
        let originalText = "2.500 ng/mL — café [fixture-source-v1]"
        let changedBytes = originalText.replacingOccurrences(of: "é", with: "e\u{301}")
        XCTAssertEqual(originalText, changedBytes, "Swift textual equality alone accepts canonical equivalence")
        XCTAssertNotEqual(Array(originalText.utf8), Array(changedBytes.utf8))
        let original = AskAnswer(originalQuestion: "byte preservation fixture", answerText: originalText,
            support: .supported, knowledgeBaseVersion: "fixture-v1",
            semanticDocument: .init(spans: [.init(text: changedBytes, emphasis: .anchorBold)]))
        XCTAssertEqual(Array(original.resolvedSemanticDocument.plainText.utf8), Array(originalText.utf8))
        XCTAssertTrue(original.resolvedSemanticDocument.spans.allSatisfy { $0.emphasis == .plain })
    }
}
