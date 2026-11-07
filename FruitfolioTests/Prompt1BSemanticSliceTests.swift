import XCTest
@testable import Fruitfolio

final class Prompt1BSemanticSliceTests: XCTestCase {
    func testReviewedPassageRolesMatchActualEligibleCorpusWithoutChangingAnyWords() throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let package = try JSONDecoder().decode(FruitfolioResearchPackage.self, from: Data(contentsOf: url))
        for review in FruitfolioReviewedSemanticContexts.passages {
            let note = try XCTUnwrap(package.researchNoteChunks.first(where: { $0.chunkID == review.noteID }))
            XCTAssertNotEqual(note.retrievalEligibility, false)
            XCTAssertFalse(note.sourceIDs.isEmpty)
            XCTAssertTrue(note.sourceIDs.allSatisfy { id in package.sources.contains { $0.sourceID == id && $0.isApprovedForDisplay } })
            let original = note.sourceParagraphID.flatMap { package.sourceParagraphs?[$0] } ?? note.text
            XCTAssertEqual(review.originalText, original)
            let spans = FruitfolioSemanticPolicy.reviewedSourceSpans(original, serious: true)
            XCTAssertEqual(Data(spans.map(\.text).joined().utf8), Data(original.utf8))
            XCTAssertTrue(spans.contains { $0.emphasis != .plain })
            XCTAssertFalse(spans.contains { [.spokenItalic, .rareItalicUnderline, .absoluteBoldItalicUnderline].contains($0.emphasis) })
        }
    }

    func testFoodNamesAreCompleteAndUnreviewedContextsCannotAcquireKeywordEmphasis() throws {
        let review = try XCTUnwrap(FruitfolioReviewedSemanticContexts.passages.first { $0.noteID == "note_ca00d1045d9609459ec60f03" })
        let markup = try XCTUnwrap(FruitfolioEvidenceCopyPolicy.validatedPresentation(review.originalText, original: review.originalText))
        XCTAssertTrue(markup.contains("**apple slices**"))
        XCTAssertTrue(markup.contains("**peanut butter**"))
        XCTAssertTrue(markup.contains("**Greek yogurt**"))
        XCTAssertTrue(markup.contains("**frozen blueberries**"))
        XCTAssertFalse(markup.contains("**apple** slices"))
        let accented = try XCTUnwrap(FruitfolioReviewedSemanticContexts.passages.first { $0.noteID == "note_638477e8908b98b245971d44" })
        let decomposed = accented.originalText.decomposedStringWithCanonicalMapping
        XCTAssertEqual(decomposed, accented.originalText) // Swift's canonical-equivalent equality.
        XCTAssertFalse(decomposed.utf8.elementsEqual(accented.originalText.utf8))
        for text in ["apple slices estrogen cramps", review.originalText + " changed context", decomposed] {
            let spans = FruitfolioSemanticPolicy.reviewedSourceSpans(text)
            XCTAssertTrue(spans.map(\.text).joined().utf8.elementsEqual(text.utf8))
            XCTAssertTrue(spans.allSatisfy { $0.emphasis == .plain })
        }
    }

    func testReviewedSourceRolesSurviveActualPrefixAndSelectionOperations() throws {
        let review = try XCTUnwrap(FruitfolioReviewedSemanticContexts.passages.first { $0.noteID == "note_ca00d1045d9609459ec60f03" })
        let spans = FruitfolioSemanticPolicy.reviewedSourceSpans(review.originalText)
        let range = (review.originalText as NSString).range(of: "apple slices")
        let selection = FruitfolioSemanticSlices.selection(spans, utf16Range: range)
        XCTAssertEqual(selection.map(\.text).joined(), "apple slices")
        XCTAssertEqual(selection.map(\.emphasis), [.anchorBold])
        let end = try XCTUnwrap(Range(NSRange(location: 0, length: NSMaxRange(range)), in: review.originalText))
        let prefix = FruitfolioSemanticSlices.prefix(spans, characterCount: review.originalText[end].count)
        XCTAssertEqual(prefix.map(\.text).joined(), String(review.originalText[end]))
        XCTAssertEqual(prefix.last?.emphasis, .anchorBold)
    }


    func testExtremeEmphasisRequiresCanonicalVocabularyAndSeriousTextDropsVocalStress() {
        let spans = [FruitfolioSemanticSpan(text: "uncertainty", emphasis: .absoluteBoldItalicUnderline),
                     .init(text: "never", emphasis: .absoluteBoldItalicUnderline),
                     .init(text: "cramps", emphasis: .spokenItalic)]
        let normal = FruitfolioSemanticPolicy.normalized(spans)
        XCTAssertEqual(normal.map(\.emphasis), [.actionableBoldUnderline, .absoluteBoldItalicUnderline, .spokenItalic])
        let serious = FruitfolioSemanticPolicy.normalized(spans, serious: true)
        XCTAssertEqual(serious.map(\.emphasis), [.actionableBoldUnderline, .actionableBoldUnderline, .plain])
        XCTAssertEqual(serious.map(\.text), spans.map(\.text))
        XCTAssertEqual(serious.map(\.id), spans.map(\.id))
        // No medical-word lookup adds formatting to ordinary source prose.
        XCTAssertEqual(FruitfolioSemanticPolicy.normalized([.init(text: "estradiol cramps apple slices")]).first?.emphasis, .plain)
    }

    func testProgressiveTextKeepsExplicitEmphasisAndGraphemeBoundaries() {
        let spans = [FruitfolioSemanticSpan(text: "E2", emphasis: .anchorBold), .init(text: " 💛 μg")]
        let prefix = FruitfolioSemanticSlices.prefix(spans, characterCount: 4)
        XCTAssertEqual(prefix.map(\.text).joined(), "E2 💛")
        XCTAssertEqual(prefix.first?.emphasis, .anchorBold)
        XCTAssertEqual(prefix.first?.id, spans.first?.id)
        XCTAssertEqual(spans.map(\.text).joined(), "E2 💛 μg")
    }
    func testSelectionAcrossStyledSpansRetainsEachEmphasis() {
        let spans = [FruitfolioSemanticSpan(text: "E2", emphasis: .anchorBold), .init(text: " symptoms", emphasis: .symptomOrPracticalUnderline)]
        let selected = FruitfolioSemanticSlices.selection(spans, utf16Range: NSRange(location: 1, length: 5))
        XCTAssertEqual(selected.map(\.text).joined(), "2 sym")
        XCTAssertEqual(selected.map(\.emphasis), [.anchorBold, .symptomOrPracticalUnderline])
    }
    func testLiteralMarkdownIsEscapedAndExplicitUnderlineIsSerializable() throws {
        let original = [FruitfolioSemanticSpan(text: "2 * 3", emphasis: .symptomOrPracticalUnderline)]
        let encoded = FruitfolioSemanticMarkup.markdown(original)
        XCTAssertEqual(encoded, "<u>2 \\* 3</u>")
        let envelope = try FruitfolioScientificTranslationEnvelope(encoded)
        XCTAssertEqual(try envelope.restore(envelope.prepared), encoded)
    }

    func testInvalidSelectionAndZeroPrefixAreSafe() {
        let spans = [FruitfolioSemanticSpan(text: "💛")]
        XCTAssertTrue(FruitfolioSemanticSlices.selection(spans, utf16Range: NSRange(location: 1, length: 1)).isEmpty)
        XCTAssertTrue(FruitfolioSemanticSlices.prefix(spans, characterCount: 0).isEmpty)
        XCTAssertTrue(FruitfolioSemanticSlices.selection(spans, utf16Range: NSRange(location: NSNotFound, length: 1)).isEmpty)
    }
}
