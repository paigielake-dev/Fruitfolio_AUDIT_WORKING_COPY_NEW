import XCTest
import UIKit
@testable import Fruitfolio

@MainActor
final class SemanticPipelineTests: XCTestCase {
    func testSameWordsReceiveOnlyTheirDeclaredContextualRole() {
        let ordinary = Prompt09MaroonSelectableAnswerText.styledAnswer("the book is titled cramps")
        XCTAssertNil(ordinary.attribute(.underlineStyle, at: 19, effectiveRange: nil))
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "cramps", emphasis: .symptomOrPracticalUnderline),
            .init(text: " is also a book title: cramps")
        ])
        let rendered = Prompt09MaroonSelectableAnswerText.styledAnswer(document)
        XCTAssertNotNil(rendered.attribute(.underlineStyle, at: 0, effectiveRange: nil))
        XCTAssertNil(rendered.attribute(.underlineStyle, at: rendered.length - 1, effectiveRange: nil))
        XCTAssertEqual(rendered.string, document.plainText)
    }

    func testRepeatedExcerptUsesSelectedOccurrenceAndUnicodeBoundaries() throws {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "cramps", emphasis: .symptomOrPracticalUnderline),
            .init(text: " ♡ "), .init(text: "cramps", emphasis: .anchorBold)
        ])
        let range = (document.plainText as NSString).range(of: "cramps", options: .backwards)
        let excerpt = try XCTUnwrap(document.slice(utf16Range: range))
        XCTAssertEqual(excerpt.plainText, "cramps")
        XCTAssertEqual(excerpt.spans.first?.emphasis, .anchorBold)
        XCTAssertNil(document.slice(utf16Range: NSRange(location: NSNotFound, length: 1)))
        let emoji = FruitfolioSemanticDocument(spans: [.init(text: "🧬")])
        XCTAssertNil(emoji.slice(utf16Range: NSRange(location: 0, length: 1)))
    }

    func testSavedPageAndGuideReopenRetainFormattingSourceAndImages() throws {
        let suite = "SemanticPipeline-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "semantic")
        let library = try store.createEncyclopedia(name: "research", style: .sage)
        let chapter = try XCTUnwrap(library.chapters.first)
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "2.5 ng/mL ", emphasis: .anchorBold),
            .init(text: "does not", emphasis: .absoluteBoldItalicUnderline),
            .init(text: " confirm ovulation.")
        ])
        let page = Prompt10SavedPage(chapterID: chapter.id, question: "fixture",
            answer: document.plainText, saveType: .fullAnswer,
            sourceIDs: ["fixture-source"], sourceVersions: ["fixture-source":"v1"],
            importedImageIDs: ["fixture-image"], semanticDocument: document)
        let saved = try store.savePage(page, to: library.id, chapterID: chapter.id)
        let guide = try store.createGuideEncyclopedia(name: "guide", subtitle: "", style: .pink)
        let section = try store.createChapter(in: guide.id, name: "section")
        _ = try store.prompt11AddSavedMaterial(saved, to: guide.id, chapterID: section.id)
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "semantic")
        let copy = try XCTUnwrap(reopened.encyclopedia(id: guide.id)?.chapters.first?.pages.first)
        XCTAssertEqual(copy.resolvedSemanticDocument, document)
        XCTAssertEqual(copy.sourceIDs, page.sourceIDs)
        XCTAssertEqual(copy.sourceVersions, page.sourceVersions)
        XCTAssertEqual(copy.importedImageIDs, page.importedImageIDs)
        XCTAssertEqual(copy.sourceSavedPageID, saved.id)
    }

    func testLegacyPageDecodesWithoutFormattingAndMismatchedMetadataCannotRewriteEvidence() throws {
        let page = Prompt10SavedPage(chapterID: UUID(), question: "q", answer: "original evidence", saveType: .fullAnswer)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(page)) as? [String:Any])
        object.removeValue(forKey: "semanticDocument")
        let legacy = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertEqual(legacy.resolvedSemanticDocument.plainText, "original evidence")
        var corrupt = legacy
        corrupt.semanticDocument = .init(spans: [.init(text: "invented statement", emphasis: .anchorBold)])
        XCTAssertEqual(corrupt.resolvedSemanticDocument.plainText, "original evidence")
    }
}
