import XCTest
@testable import Fruitfolio

final class SemanticUnicodeBoundaryTests: XCTestCase {
    func testProgressivePrefixPreservesCombiningClusterAcrossSemanticSpans() {
        let first = FruitfolioSemanticSpan(text: "e", emphasis: .anchorBold)
        let second = FruitfolioSemanticSpan(text: "\u{301} 2.500 ng/mL [source-1]", emphasis: .spokenItalic)
        let document = FruitfolioSemanticDocument(spans: [first, second])
        let result = document.prefix(characters: 1)
        XCTAssertEqual(Array(result.plainText.utf8), Array("e\u{301}".utf8))
        XCTAssertEqual(result.spans.map(\.id), [first.id, second.id])
        XCTAssertEqual(result.spans.map(\.emphasis), [.anchorBold, .spokenItalic])
        XCTAssertEqual(document.prefix(characters: 0).plainText, "")
        XCTAssertEqual(document.prefix(characters: Int.max).plainText, document.plainText)
    }

    func testProgressivePrefixPreservesJoinedEmojiAcrossStyledSpans() {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "👩", emphasis: .anchorBold),
            .init(text: "\u{200D}🔬", emphasis: .spokenItalic),
            .init(text: " — fixture", emphasis: .plain)
        ])
        XCTAssertEqual(document.prefix(characters: 1).plainText, "👩\u{200D}🔬")
        XCTAssertEqual(document.prefix(characters: 2).plainText, "👩\u{200D}🔬 ")
    }

    func testSelectionAfterCrossSpanClusterUsesTheActualOccurrenceWithoutLosingMeasurementBytes() throws {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "e", emphasis: .anchorBold),
            .init(text: "\u{301} first 2.500 ng/mL; second ", emphasis: .spokenItalic),
            .init(text: "2.500 ng/mL [source-1]", emphasis: .actionableBoldUnderline)
        ])
        let selected = "2.500 ng/mL [source-1]"
        let range = (document.plainText as NSString).range(of: selected)
        let sliced = try XCTUnwrap(document.slice(utf16Range: range))
        XCTAssertEqual(Array(sliced.plainText.utf8), Array(selected.utf8))
        XCTAssertEqual(sliced.spans.map(\.emphasis), [.actionableBoldUnderline])
    }

    func testPartialGraphemeOrOutOfBoundsSelectionFailsWithoutChangingOriginalDocument() {
        let document = FruitfolioSemanticDocument(spans: [.init(text: "e\u{301} 👩\u{200D}🔬 2.500")])
        let original = document.plainText
        for range in [NSRange(location: 0, length: 1), NSRange(location: NSNotFound, length: 1),
                      NSRange(location: 1, length: Int.max), NSRange(location: 0, length: 0),
                      NSRange(location: Int.max, length: 2)] {
            XCTAssertNil(document.slice(utf16Range: range))
        }
        XCTAssertEqual(document.plainText, original)
    }
}
