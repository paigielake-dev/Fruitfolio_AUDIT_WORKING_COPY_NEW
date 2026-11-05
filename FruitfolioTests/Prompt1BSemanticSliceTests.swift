import XCTest
@testable import Fruitfolio

final class Prompt1BSemanticSliceTests: XCTestCase {
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
    func testInvalidSelectionAndZeroPrefixAreSafe() {
        let spans = [FruitfolioSemanticSpan(text: "💛")]
        XCTAssertTrue(FruitfolioSemanticSlices.selection(spans, utf16Range: NSRange(location: 1, length: 1)).isEmpty)
        XCTAssertTrue(FruitfolioSemanticSlices.prefix(spans, characterCount: 0).isEmpty)
        XCTAssertTrue(FruitfolioSemanticSlices.selection(spans, utf16Range: NSRange(location: NSNotFound, length: 1)).isEmpty)
    }
}
