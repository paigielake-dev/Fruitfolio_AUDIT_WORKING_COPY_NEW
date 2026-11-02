import XCTest
@testable import Fruitfolio

final class FAQSemanticContentTests: XCTestCase {
    func testAuthoredMeaningPreservesEveryApprovedFAQAnswerVerbatim() {
        for section in Prompt29FAQCatalog.sections {
            for item in section.items {
                XCTAssertEqual(item.semanticDocument.plainText, item.answer, item.id)
                XCTAssertFalse(item.semanticDocument.spans.isEmpty)
            }
        }
        let medical = Prompt29FAQCatalog.sections.flatMap(\.items).first { $0.id == "about-2" }
        XCTAssertEqual(medical?.semanticDocument.spans.first { $0.emphasis == .anchorBold }?.text, "educational")
        let game = Prompt29FAQCatalog.sections.flatMap(\.items).first { $0.id == "basket-1" }
        XCTAssertTrue(game?.semanticDocument.spans.allSatisfy { $0.emphasis == .plain } == true,
                      "Fruit names do not acquire emphasis from keyword matching")
    }
}
