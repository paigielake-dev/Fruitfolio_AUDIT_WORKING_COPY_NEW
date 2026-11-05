import XCTest
@testable import Fruitfolio

final class Prompt1BSemanticSliceTests: XCTestCase {
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
