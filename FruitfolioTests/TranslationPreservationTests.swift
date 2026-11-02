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

    func testProtectedMeasurementsKeepOriginalPrecisionUnitsAndSpacingOutsideGeneration() throws {
        let source = "The result is 2.500 ng/mL and 4e-3 mIU/L."
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: ["ng/mL", "mIU/L"])
        XCTAssertEqual(plan.modelInput, "The result is [FFQ0] and [FFQ1].")
        XCTAssertEqual(try plan.restoring(in: "Le résultat est [FFQ0] et [FFQ1]."),
                       "Le résultat est 2.500 ng/mL et 4e-3 mIU/L.")
        XCTAssertEqual(try plan.restoring(in: "結果は［ＦＦＱ０］と［ＦＦＱ１］です。"),
                       "結果は2.500 ng/mLと4e-3 mIU/Lです。")
    }

    func testProtectedMeasurementsRejectMissingDuplicatedAddedOrReorderedSlots() throws {
        let plan = try FruitfolioProtectedMeasurements(source: "2.5 ng/mL and 5 mIU/L", immutableTerms: ["ng/mL", "mIU/L"])
        for invalid in ["[FFQ0]", "[FFQ0] [FFQ0] [FFQ1]", "[FFQ1] [FFQ0]", "[FFQ0] [FFQ1] [FFQ2]", "2.5 grams/cm3"] {
            XCTAssertThrowsError(try plan.restoring(in: invalid))
        }
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
            source: "The result is 2.5 ng/mL.", translated: "इसका घनत्व 2.5 ग्राम/सेमी3 है।", target: "hi"),
            "The actual unsafe Hindi density output must remain rejected, never normalized into acceptance")
    }

    func testProtectedMeasurementMarkersCannotCollideWithOriginalSourceAndScientificNotationStaysExact() throws {
        let plan = try FruitfolioProtectedMeasurements(source: "The [FFQ0] label and 2.50 ng/mL", immutableTerms: ["ng/mL", "ng/mL"])
        XCTAssertEqual(plan.markers, ["[FFQX0]"])
        XCTAssertEqual(try plan.restoring(in: "The [FFQ0] label and [FFQX0]"), "The [FFQ0] label and 2.50 ng/mL")
        XCTAssertEqual(FruitfolioTranslationPreservation.numbers("2.50e-3 and -4E+5"), ["2.50e-3", "-4E+5"])
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
            source: "2.5e-3", translated: "2.5e3", target: "es"))
        XCTAssertEqual(FruitfolioProtectedMeasurements.canonicalASCIIWidth("２．５ｎｇ／ｍＬと漢字"), "2.5ng/mLと漢字")
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
