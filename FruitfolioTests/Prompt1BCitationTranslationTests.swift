import Foundation
import XCTest
@testable import Fruitfolio

private actor Prompt1BCitationTranslationFixture: FruitfolioLocalTranslationRuntime {
    func releaseResources() {}
    func translate(_ text: String, targetTag: String) async throws -> String {
        text.replacingOccurrences(of: "Original", with: "Fixture-translated")
    }
}

final class Prompt1BCitationTranslationTests: XCTestCase {
    func testFullOriginalAPAAndBareDOIRemainExactWhileOrdinaryProseCanChange() async throws {
        let citation = "Original, A. (2020). Original research. Example Journal."
        let record = AskSourceRecord(id: "A", title: "Original research", sourceText: citation,
            urlString: "https://example.test/Original", doi: "10.1000/Original", contentVersion: "v7")
        let source = "Original prose 12 pg/mL [A].\n\n" + citation + " DOI 10.1000/Original"
        let literals = FruitfolioCitationProtection.literals(ids: ["A"], records: [record])
        let service = FruitfolioTranslationService(runtime: Prompt1BCitationTranslationFixture())
        let display = try await service.translate(source, language: .spanish, protectedLiterals: literals)
        XCTAssertTrue(display.hasPrefix("Fixture-translated prose 12 pg/mL [A]."))
        XCTAssertTrue(display.contains(citation))
        XCTAssertTrue(display.hasSuffix("DOI 10.1000/Original"))
        XCTAssertEqual(record.sourceText, citation)
        XCTAssertEqual(record.contentVersion, "v7")
        // Fixture verifies the protection pipeline, not real clinical translation.
    }
    func testEscapedCitationVariantDeduplicatesWithoutFreezingOrdinarySourceTitleWords() throws {
        let citation = "Original_*author (2020)."
        let record = AskSourceRecord(id: "A", title: "ordinary biological concept", sourceText: citation,
            urlString: "https://example.test/record", doi: "10.1000/record")
        let literals = FruitfolioCitationProtection.literals(ids: ["A", "A", ""], records: [record, record])
        XCTAssertEqual(literals.count, Set(literals).count)
        XCTAssertFalse(literals.contains(""))
        XCTAssertFalse(literals.contains(record.title))
        let escaped = FruitfolioSemanticMarkup.markdown([.init(text: citation)])
        XCTAssertTrue(literals.contains(citation))
        XCTAssertTrue(literals.contains(escaped))
        let envelope = try FruitfolioScientificTranslationEnvelope(escaped, protectedLiterals: literals)
        XCTAssertFalse(envelope.prepared.contains("Original"))
        XCTAssertEqual(try envelope.restore(envelope.prepared), escaped)
    }
    func testLegacyIDsWithoutSourceRecordsRemainProtectedAndDoNotInventAttributions() {
        XCTAssertEqual(FruitfolioCitationProtection.literals(ids: ["legacy", "legacy"], records: []), ["legacy"])
    }
}
