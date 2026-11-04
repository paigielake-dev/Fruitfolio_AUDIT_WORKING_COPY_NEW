import XCTest
import UIKit
@testable import Fruitfolio

@MainActor
final class SemanticRenderSessionTests: XCTestCase {
    func testEveryProgressiveUnicodePrefixMatchesUncachedRolesWithoutRebuildingTheWholeAnswer() {
        let document = FruitfolioSemanticDocument(spans: [
            .init(text: "e", emphasis: .anchorBold),
            .init(text: "\u{301} 👩\u{200D}🔬 ", emphasis: .spokenItalic),
            .init(text: "2.500 ng/mL [source-1]", emphasis: .anchorBold),
            .init(text: " does not confirm ovulation.")
        ])
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        let session = FruitfolioSemanticRenderSession()
        for n in 0...document.plainText.count {
            let visible = String(document.plainText.prefix(n))
            let actual = session.prefix(visible, document: document, traits: traits)
            let expected = FruitfolioSemanticAttributedRenderer.render(document.prefix(characters: n), traits: traits)
            XCTAssertEqual(Array(actual.string.utf8), Array(visible.utf8))
            XCTAssertTrue(actual.isEqual(to: expected), "Cached prefix must retain every semantic role at position \(n)")
        }
        XCTAssertEqual(session.renderCount, 1, "A growing answer must not rebuild every font/role for every character")
    }

    func testChangingSizeOrAnswerInvalidatesTheSessionAndResetPreventsReuseAcrossVisits() throws {
        let document = FruitfolioSemanticDocument(spans: [.init(text: "2.500 ng/mL", emphasis: .anchorBold)])
        let normal = UITraitCollection(preferredContentSizeCategory: .large)
        let largest = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        let session = FruitfolioSemanticRenderSession()
        let initial = session.prefix(document.plainText, document: document, traits: normal)
        let enlarged = session.prefix(document.plainText, document: document, traits: largest)
        let a = try XCTUnwrap(initial.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        let b = try XCTUnwrap(enlarged.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        XCTAssertGreaterThan(b.pointSize, a.pointSize)
        XCTAssertEqual(session.renderCount, 2)
        let changed = FruitfolioSemanticDocument(spans: [.init(text: "3.1250 pmol/L [different-source]")])
        XCTAssertEqual(session.prefix(changed.plainText, document: changed, traits: largest).string, changed.plainText)
        XCTAssertEqual(session.renderCount, 3)
        session.reset()
        _ = session.prefix(document.plainText, document: document, traits: normal)
        XCTAssertEqual(session.renderCount, 4)
    }

    func testMismatchedWordingOrPartialGraphemeCannotBorrowMedicalEmphasisOrReplaceVisibleBytes() {
        let document = FruitfolioSemanticDocument(spans: [.init(text: "e\u{301} has not been confirmed", emphasis: .anchorBold)])
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        let session = FruitfolioSemanticRenderSession()
        for text in ["e", "é", "confirmed", "ovary", "[another-source]"] {
            let actual = session.prefix(text, document: document, traits: traits)
            XCTAssertEqual(Array(actual.string.utf8), Array(text.utf8))
            XCTAssertEqual(actual.attribute(.fruitfolioSemanticRole, at: 0, effectiveRange: nil) as? String,
                           FruitfolioSemanticEmphasis.plain.rawValue)
        }
    }

    func testReconstructedSpanIdentityDoesNotRepeatRenderingButAChangedMeaningRoleDoes() {
        let session = FruitfolioSemanticRenderSession()
        let traits = UITraitCollection(preferredContentSizeCategory: .large)
        for _ in 0..<10 {
            let reconstructed = FruitfolioSemanticDocument(spans: [.init(text: "original unit: ng/mL", emphasis: .anchorBold)])
            _ = session.prefix(reconstructed.plainText, document: reconstructed, traits: traits)
        }
        XCTAssertEqual(session.renderCount, 1)
        let changed = FruitfolioSemanticDocument(spans: [.init(text: "original unit: ng/mL", emphasis: .plain)])
        let actual = session.prefix(changed.plainText, document: changed, traits: traits)
        XCTAssertEqual(session.renderCount, 2)
        XCTAssertEqual(actual.attribute(.fruitfolioSemanticRole, at: 0, effectiveRange: nil) as? String,
                       FruitfolioSemanticEmphasis.plain.rawValue)
    }
}
