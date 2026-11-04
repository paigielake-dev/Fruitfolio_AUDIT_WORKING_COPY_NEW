import XCTest
@testable import Fruitfolio

final class ResearchQuotationFidelityTests: XCTestCase {
    func testQuotedURLsDOIsCitationMarkersMeasurementsAndCompoundUnitsStayByteExact() {
        let original = "Research: https://example.org/paper;section?a=b,c=d. DOI 10.1234/Abc.Def;version:Final [source:original]. 2.500  ng/mL; 3.2×10⁻³ pmol.L^-1; 95%; 36.70 °C."
        let result = FruitfolioAnswerPresentationSanitizer.clean(original)
        XCTAssertEqual(Array(result.utf8), Array(original.utf8))
    }

    func testPossibleProseJoinsAreNotRewrittenWithoutReviewedSourceCorrection() {
        let original = "Original.Qualifier;next,term:detail — e\u{301}.\r\nA single result does not establish a diagnosis."
        XCTAssertEqual(Array(FruitfolioAnswerPresentationSanitizer.clean(original).utf8), Array(original.utf8),
                       "A display heuristic must not change the approved passage's punctuation or qualifiers")
    }

    func testOnlyEnclosingLayoutWhitespaceIsTrimmed() {
        let original = "2.500  ng/mL\n\n[source-1]"
        XCTAssertEqual(FruitfolioAnswerPresentationSanitizer.clean(" \n" + original + "\t\n"), original)
    }
}
