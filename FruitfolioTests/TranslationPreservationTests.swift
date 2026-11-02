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

    func testProtectedQuantitiesPreserveSignsRangesPercentTemperaturePowersAndCompoundUnits() throws {
        let source = "Recorded: -2.50–-1.00 ng/mL; 12.5%; 37.0 °C; 4.20e-3 mol/L; 1.2 ×10⁻³ kg·m⁻²; ١٢٫٥٪; ≤5 mL/min/1.73m²; 3 observations on 2026-11-02."
        let spans = ["-2.50–-1.00 ng/mL", "12.5%", "37.0 °C", "4.20e-3 mol/L", "1.2 ×10⁻³ kg·m⁻²", "١٢٫٥٪", "≤5 mL/min/1.73m²", "3", "2026-11-02"]
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: [])
        XCTAssertEqual(plan.originalSpans, spans)
        XCTAssertEqual(try plan.restoring(in: plan.modelInput), source)
        XCTAssertEqual(plan.markers.count, spans.count)
        XCTAssertFalse(plan.modelInput.contains("ng/mL"))
        XCTAssertFalse(plan.modelInput.contains("١٢٫٥"))
        for marker in plan.markers {
            XCTAssertThrowsError(try plan.restoring(in: plan.modelInput.replacingOccurrences(of: marker, with: "")))
        }
    }

    func testBareNumbersUnicodeSignsAndUnitBoundariesArePreservedWithoutInventingUnits() throws {
        let source = "3 months, −4 observations, ２．５ ｎｇ／ｍＬ, 10⁻³, 10^-3, and 5 ± 0.2 mg/dL."
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: ["ｎｇ／ｍＬ"])
        XCTAssertEqual(plan.originalSpans, ["3", "−4", "２．５ ｎｇ／ｍＬ", "10⁻³", "10^-3", "5 ± 0.2 mg/dL"])
        XCTAssertTrue(plan.modelInput.contains("months"), "The unit m must not consume the start of months")
        XCTAssertEqual(try plan.restoring(in: plan.modelInput), source)
    }

    func testDecimalLocaleExceptionCannotIgnoreExponentOrUnicodeChanges() throws {
        for pair in [("2.5e-3", "2,5e3"), ("1.2 ×10⁻³", "1,2 ×10³"), ("2.5", "２,５"), ("10^-3", "10^3")] {
            XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(
                source: pair.0, translated: pair.1, target: "fr"))
        }
    }

    func testObservedChineseMarkerEdgeSpacingRestoresOnlyExactIdentifiersInExactOrder() throws {
        let plan = try FruitfolioProtectedMeasurements(source: "TSH is 2.50 ng/mL and 5 mIU/L", immutableTerms: ["TSH", "ng/mL", "mIU/L"])
        XCTAssertEqual(plan.originalSpans, ["TSH", "2.50 ng/mL", "5 mIU/L"])
        XCTAssertEqual(try plan.restoring(in: "[ FFQ0 ]: [FFQ1 ] / ［ＦＦＱ２　］"), "TSH: 2.50 ng/mL / 5 mIU/L")
        for unsafe in ["[FFQ0] [FFQ01] [FFQ2]", "[FFQ0] [FFQ2] [FFQ1]", "[FFQ0] [FFQ1] [FFQ2] [FFQ2]",
                       "[FFQ0] [FFQ1A] [FFQ2]", "[FFQ0] [FFQ1\n] [FFQ2]", "[FFQ0] [FFQ1]"] {
            XCTAssertThrowsError(try plan.restoring(in: unsafe))
        }
    }

    func testFractionsFullWidthUnitsAndComparisonOperatorsStayOpaqueWithoutConversion() throws {
        let source = "Record >=2.50 ng/mL, ≤5 mg/dL, ½ mg, 1 ½ mL, 1/2 mg, and ＋２．５ ｎｇ／ｍＬ."
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: [])
        XCTAssertEqual(plan.originalSpans, [">=2.50 ng/mL", "≤5 mg/dL", "½ mg", "1 ½ mL", "1/2 mg", "＋２．５ ｎｇ／ｍＬ"])
        XCTAssertEqual(try plan.restoring(in: plan.modelInput), source)
        XCTAssertEqual(FruitfolioTranslationPreservation.numbers("½ 1 ½ 1/2 ＋２．５"), ["½", "1 ½", "1/2", "＋２．５"])
    }

    func testPureTerminalMeasurementListsStayOutsideGenerationWhileStrictValidationStillApplies() throws {
        let source = "These are recorded values, not medical advice: -2.50 ng/mL; 12.5%; 37.0 °C."
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: [])
        let detached = try XCTUnwrap(plan.terminalLiteralList())
        XCTAssertEqual(detached.modelInput, "These are recorded values, not medical advice")
        XCTAssertEqual(detached.sourceSuffix, ": [FFQ0]; [FFQ1]; [FFQ2].")
        // Exact actual prior Japanese output dropped every quantity. The list
        // now never enters the decoder, and is copied verbatim outside it.
        let rawJapanese = "これらは記録値であり，医療的アドバイスではない。"
        let restored = try plan.restoring(in: detached.combining(with: rawJapanese))
        XCTAssertTrue(restored.hasSuffix(": -2.50 ng/mL; 12.5%; 37.0 °C."))
        XCTAssertEqual(FruitfolioTranslationPreservation.numbers(restored), FruitfolioTranslationPreservation.numbers(source))
        let addedNumber = try plan.restoring(in: detached.combining(with: "There are 9 values."))
        XCTAssertThrowsError(try FruitfolioTranslationPreservation.preserveNumbers(source: source, translated: addedNumber, target: "en"))
        XCTAssertThrowsError(try plan.restoring(in: detached.combining(with: "[FFQ0] added.")))
        XCTAssertNil(try FruitfolioProtectedMeasurements(source: "Values: 2 ng/mL; and 5 mIU/L.", immutableTerms: []).terminalLiteralList(),
            "A mixed prose clause must not be bypassed as a pure quantitative list")
        XCTAssertNil(try FruitfolioProtectedMeasurements(source: "The result is 2.5 ng/mL.", immutableTerms: []).terminalLiteralList())
    }

    func testLanguageReadinessNeverConfusesModelPresenceWithApprovedMedicalDisplay() {
        XCTAssertNil(FruitfolioLocalization.untranslatedContentNotice(for: .english))
        for language in FruitfolioLanguage.allCases where language != .english {
            XCTAssertNotNil(FruitfolioLocalization.untranslatedContentNotice(for: language))
            XCTAssertNotEqual(FruitfolioLocalization.displayReadiness(for: language), .originalEnglish)
        }
        for language in [FruitfolioLanguage.tokPisin, .tahitian, .cookIslandsMaori, .niuean, .kiribati] {
            XCTAssertEqual(FruitfolioLocalization.displayReadiness(for: language), .unsupportedOfficialTarget)
        }
        XCTAssertEqual(FruitfolioLocalization.displayReadiness(for: .chineseSimplified), .requiresVerification)
        XCTAssertEqual(FruitfolioLocalization.displayReadiness(for: .chineseTraditional), .requiresVerification)
    }

    func testKnownHindiOvaryForOvulationSubstitutionIsRejectedAndOriginalConceptIsProtected() throws {
        let source = "This estimate does not confirm ovulation."
        let terms = FruitfolioMedicalConceptPreservation.originalTerms(source: source, target: "hi")
        XCTAssertEqual(terms, ["ovulation"])
        let plan = try FruitfolioProtectedMeasurements(source: source, immutableTerms: terms)
        XCTAssertFalse(plan.modelInput.contains("ovulation"), "The decoder cannot choose a different biological noun")
        XCTAssertEqual(try plan.restoring(in: "इस अनुमान में [FFQ0] की पुष्टि नहीं होती है।"),
            "इस अनुमान में ovulation की पुष्टि नहीं होती है।")
        XCTAssertThrowsError(try FruitfolioMedicalConceptPreservation.rejectKnownConceptSubstitutions(source: source,
            translated: "इस अनुमान में अंडाशय की पुष्टि नहीं होती है।", target: "hi"))
        XCTAssertNoThrow(try FruitfolioMedicalConceptPreservation.rejectKnownConceptSubstitutions(
            source: "Ovulation involves an ovary.", translated: "Ovulation: अंडाशय", target: "hi"),
            "A literal ovary actually present in the source must not be prohibited by a blanket word ban")
        XCTAssertTrue(FruitfolioMedicalConceptPreservation.originalTerms(source: "An ovarian result.", target: "hi").isEmpty)
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
