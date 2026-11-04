import XCTest
@testable import Fruitfolio

final class SemanticDocumentTests: XCTestCase {
    func testPersistenceAndProgressiveDisplayPreserveNegationRolesAndUnicode() throws {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "⚠️ 2.5 ng/mL ", emphasis: .anchorBold),
            .init(text: "does not", emphasis: .absoluteBoldItalicUnderline),
            .init(text: " confirm ovulation. café\u{301}")
        ])
        let restored = try JSONDecoder().decode(FruitfolioSemanticDocument.self,
                                                from: JSONEncoder().encode(document))
        XCTAssertEqual(restored, document)
        for n in 0...document.plainText.count {
            let partial = restored.prefix(characters: n)
            XCTAssertEqual(partial.plainText, String(document.plainText.prefix(n)))
            for span in partial.spans {
                let original = try XCTUnwrap(document.spans.first { $0.id == span.id })
                XCTAssertEqual(span.emphasis, original.emphasis)
                XCTAssertTrue(original.text.hasPrefix(span.text))
            }
        }
        XCTAssertEqual(restored.prefix(characters: -1).plainText, "")
        XCTAssertEqual(restored.prefix(characters: 10000), restored)
    }
}
