import XCTest
@testable import Fruitfolio

@MainActor
final class TranslationPreservationTests: XCTestCase {
    func testTranslationLayoutRetainsParagraphsListsIndentationAndExactLineEndings() {
        let original = "# heading\r\n\r\n  1. First sentence.  Next sentence [source-1].\n\t- A second item.\n\nlast line  "
        let segments = FruitfolioTranslationLayout.segments(original)
        XCTAssertEqual(segments.map(\.original).joined(), original)
        let sentences = segments.compactMap { segment -> String? in
            if case .sentence(let sentence) = segment { return sentence }; return nil
        }
        XCTAssertTrue(sentences.contains("heading"))
        XCTAssertTrue(sentences.contains("First sentence."))
        XCTAssertFalse(sentences.contains(where: { $0.hasPrefix("1.") || $0.hasPrefix("# ") || $0.hasPrefix("- ") }))
        XCTAssertEqual(FruitfolioTranslationLayout.segments(" \n\r\n").map(\.original).joined(), " \n\r\n")
    }

    func testUnknownAndNonterminalCitationCannotBeReattributedByMovingIt() async throws {
        let translator = FruitfolioMADLADDocumentTranslator()
        for (source, identifiers) in [("A result [unapproved].", ["approved"]), ("A result [approved] and another claim.", ["approved"])] {
            do {
                _ = try await translator.candidate(source: source, sourceIdentifiers: identifiers,
                    target: "es", immutableTerms: [], directory: FileManager.default.temporaryDirectory)
                XCTFail("Invalid attribution must fail before inference")
            } catch FruitfolioTranslationPreservationError.invalidSourceCitation { }
        }
    }

    func testEquivalentDecimalMarkRestoresTheExactOriginalSpellingWithoutWeakeningTheFinalInvariant() throws {
        let source = "The result is 2.50 ng/mL."
        let result = try FruitfolioTranslationPreservation.preserveNumbers(source: source,
            translated: "Le résultat est de 2,5 ng/mL.", target: "fr")
        XCTAssertEqual(result, "Le résultat est de 2.50 ng/mL.")
        XCTAssertEqual(FruitfolioTranslationPreservation.numbers(result), FruitfolioTranslationPreservation.numbers(source))
    }
    func testChangedAddedDroppedReorderedAndSignChangedNumbersAreRejected() {
        for proposed in ["The result is 1.5 ng/mL.", "The result is 2.5 and 1 ng/mL.", "The result is normal.", "The result is -2.5 ng/mL."] {
            XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
                source: "The result is 2.5 ng/mL.", translated: proposed, target: "fr"))
        }
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
            source: "Between 2.5 and 5.0 ng/mL.", translated: "Entre 5,0 et 2,5 ng/mL.", target: "fr"))
    }
    func testAmbiguousSourceCommaAndUnapprovedLocaleAreNeverReinterpreted() {
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
            source: "2,500 ng/mL", translated: "2.500 ng/mL", target: "de"))
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
            source: "2.5 ng/mL", translated: "2,5 ng/mL", target: "es"))
    }
    func testUnitAndExplicitMedicalLiteralChangesOrDuplicationAreRejected() throws {
        try FruitfolioTranslationPreservation.preserveLiterals(["TSH", "ng/mL"], source: "TSH 2.5 ng/mL", translated: "TSH: 2.5 ng/mL")
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveLiterals(["TSH"], source: "a result", translated: "TSH result"))
        for changed in ["TSH: 2.5 ng/ml", "TSH: 2.5 ng/mL ng/mL", "2.5 ng/mL"] {
            XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveLiterals(["TSH", "ng/mL"], source: "TSH 2.5 ng/mL", translated: changed))
        }
    }
}
