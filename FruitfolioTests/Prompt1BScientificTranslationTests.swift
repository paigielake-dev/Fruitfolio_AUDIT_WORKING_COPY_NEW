import XCTest
@testable import Fruitfolio

final class Prompt1BScientificTranslationTests: XCTestCase {
    func testRoundTripProtectsNumbersUnitsCitationsURLsAndFormatting() throws {
        let source = "**estradiol** 12.5 pg/mL [source-7] (Author, 2020). https://example.org/12"
        let envelope = try FruitfolioScientificTranslationEnvelope(source, protectedLiterals: ["source-7"])
        XCTAssertFalse(envelope.prepared.contains("12.5 pg/mL"))
        XCTAssertEqual(try envelope.restore(envelope.prepared), source)
    }
    func testClinicalSignsComparisonsAndExtendedUnitsCannotBeAlteredOutsidePlaceholders() throws {
        let source = "FSH ≤ −2.5 ng/dL; change -0.2 °C; 1.2×10^-3 µIU/mL; ratio 1:2; 2.5±0.3 pg/mL; HbA1c=5.2 %."
        let envelope = try FruitfolioScientificTranslationEnvelope(source)
        for literal in ["≤", "−", "-0.2", "ng/dL", "µIU/mL", "±", "HbA1c"] {
            XCTAssertFalse(envelope.prepared.contains(literal), "Unprotected scientific token: \(literal)")
        }
        let tampered = envelope.prepared.replacingOccurrences(of: "−", with: "")
            .replacingOccurrences(of: "≤", with: "").replacingOccurrences(of: "ng/dL", with: "mg/dL")
        XCTAssertEqual(try envelope.restore(tampered), source)
    }
    func testEscapedComparatorsGroupingAndScientificPowersRemainExact() throws {
        let sources = ["E2 < -2.5 ng/dL", "1 000 IU/L", "1.2 * 10^-3 mIU/mL", "10^−3 mol/L", "2 mg–3 mg", "−.5 ng/dL"]
        for source in sources {
            let canonical = FruitfolioSemanticMarkup.markdown([.init(text: source)])
            let envelope = try FruitfolioScientificTranslationEnvelope(canonical)
            XCTAssertEqual(try envelope.restore(envelope.prepared), canonical)
            XCTAssertFalse(envelope.prepared.contains("ng/dL"))
            XCTAssertFalse(envelope.prepared.contains("^−3"))
        }
    }
    func testIntroducedUnitsOrReferencesRejectOutputEvenWithoutNewDigits() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("recorded value 20")
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " mg"))
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " [invented-source]"))
        XCTAssertThrowsError(try envelope.restore(envelope.prepared + " https://invented.example/paper"))
    }
    func testOrdinaryTranslatedContractionsAreNotMisreadAsBareUnits() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("my context")
        XCTAssertEqual(try envelope.restore("min kontekst"), "min kontekst")
        XCTAssertEqual(try envelope.restore("m’a aidé"), "m’a aidé")
    }

    func testMissingProtectedTokensRejectsOutput() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("level 12 pg/mL [source-1]")
        XCTAssertThrowsError(try envelope.restore("translated prose with no protected tokens"))
    }
    func testIntroducedNumericalClaimIsRejected() throws {
        let envelope = try FruitfolioScientificTranslationEnvelope("source prose with no numeric claim")
        XCTAssertThrowsError(try envelope.restore("source prose now claims 99 percent"))
    }
}

private actor Prompt1BIdentityTranslationFixture: FruitfolioLocalTranslationRuntime {
    private var tags: [String] = []
    func translate(_ text: String, targetTag: String) async throws -> String {
        tags.append(targetTag)
        return text
    }
    func requestedTags() -> [String] { tags }
}

final class Prompt1BTranslationPipelineTests: XCTestCase {
    func testNonEnglishSavedContentCanRequestEnglishTranslation() async throws {
        let fixture = Prompt1BIdentityTranslationFixture()
        let service = FruitfolioTranslationService(runtime: fixture)
        _ = try await service.translate("texto original", language: .english, sourceLanguage: "es")
        let tags = await fixture.requestedTags()
        XCTAssertEqual(tags, ["en"])
    }

    func testParagraphAndStructuredReferencePreservationWithFixtureRuntime() async throws {
        let service = FruitfolioTranslationService(runtime: Prompt1BIdentityTranslationFixture())
        let original = "value 3.2 ng/mL [A]\n\nuncertainty remains."
        let result = try await service.translate(original, language: .spanish, protectedLiterals: ["A"])
        XCTAssertEqual(result, original)
        // This checks the protection pipeline, not actual model inference or translation quality.
    }
}
