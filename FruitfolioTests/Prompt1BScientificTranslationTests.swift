import XCTest
@testable import Fruitfolio

final class Prompt1BScientificTranslationTests: XCTestCase {
    func testRoundTripProtectsNumbersUnitsCitationsURLsAndFormatting() throws {
        let source = "**estradiol** 12.5 pg/mL [source-7] (Author, 2020). https://example.org/12"
        let envelope = try FruitfolioScientificTranslationEnvelope(source, protectedLiterals: ["source-7"])
        XCTAssertFalse(envelope.prepared.contains("12.5 pg/mL"))
        XCTAssertEqual(try envelope.restore(envelope.prepared), source)
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
