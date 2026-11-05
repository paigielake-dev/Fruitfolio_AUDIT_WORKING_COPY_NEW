import XCTest
import UIKit
@testable import Fruitfolio

@MainActor
final class Prompt1BSemanticTextTests: XCTestCase {
    func testExplicitEmphasisPreservesCitationNumbersUnitsAndLineBreaks() {
        let source = "**estradiol** was *measured* at 20 pg/mL. [source-2]\nUncertainty remains."
        let spans = FruitfolioSemanticDocument.spans(from: source)
        XCTAssertEqual(spans.map(\.text).joined(), "estradiol was measured at 20 pg/mL. [source-2]\nUncertainty remains.")
        XCTAssertTrue(spans.contains { $0.text == "estradiol" && $0.emphasis == .anchorBold })
        XCTAssertTrue(spans.contains { $0.text == "measured" && $0.emphasis == .spokenItalic })
    }

    func testMentioningASymptomDoesNotAutomaticallyUnderlineIt() {
        let rendered = FruitfolioSemanticRenderer.attributed(
            markdown: "The word cramps appears in a quotation, not a clinical finding.",
            font: .systemFont(ofSize: 16), color: .black)
        rendered.enumerateAttribute(.underlineStyle, in: NSRange(location: 0, length: rendered.length)) { value, _, _ in
            XCTAssertNil(value)
        }
    }

    func testStructuredEmphasisSurvivesCodableRoundTrip() throws {
        let original = [FruitfolioSemanticSpan(text: "uncertainty", emphasis: .symptomOrPracticalUnderline)]
        let restored = try JSONDecoder().decode([FruitfolioSemanticSpan].self, from: JSONEncoder().encode(original))
        XCTAssertEqual(restored, original)
        let rendered = FruitfolioSemanticRenderer.attributed(spans: restored, font: .systemFont(ofSize: 16), color: .black)
        XCTAssertEqual(rendered.string, "uncertainty")
        XCTAssertEqual(rendered.attribute(.underlineStyle, at: 0, effectiveRange: nil) as? Int, NSUnderlineStyle.single.rawValue)
    }
}
