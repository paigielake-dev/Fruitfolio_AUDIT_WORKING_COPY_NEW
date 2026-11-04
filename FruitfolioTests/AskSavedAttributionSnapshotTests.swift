import XCTest
@testable import Fruitfolio

final class AskSavedAttributionSnapshotTests: XCTestCase {
    private func answer(ids: [String], sources: [AskSourceRecord]) -> AskAnswer {
        AskAnswer(originalQuestion: "synthetic attribution fixture", answerText: "Do not change 2.500 ng/mL or [s1].",
                  support: .supported, sourceIDs: ids, sources: sources, knowledgeBaseVersion: "original-package-v1")
    }

    func testOriginalUsedSourceOrderVersionsAndCitationBytesRemainPinnedAfterSerialization() throws {
        let first = AskSourceRecord(id: "s1", title: "Original title — α", sourceText: "Original APA reference.\nExact punctuation.",
                                    urlString: "https://example.invalid/original", doi: "10.fixture/original",
                                    publicationData: "Original publication details", contentVersion: "v1:original")
        let second = AskSourceRecord(id: "s2", title: "Second original source", sourceText: "Second original citation.", contentVersion: "v2:original")
        let unused = AskSourceRecord(id: "not-used", title: "Unrelated result", contentVersion: "unused-version")
        let original = answer(ids: ["s2", "s1"], sources: [first, unused, second])
        let reopened = try JSONDecoder().decode(AskAnswer.self, from: JSONEncoder().encode(original))
        let snapshot = try AskSavedAttributionSnapshot(answer: reopened)
        XCTAssertEqual(snapshot.sourceIDs, ["s2", "s1"])
        XCTAssertEqual(snapshot.sources, [second, first])
        XCTAssertEqual(snapshot.sourceVersions, ["s1": "v1:original", "s2": "v2:original"])
        XCTAssertNil(snapshot.sourceVersions["not-used"])
        XCTAssertEqual(reopened.answerText, original.answerText)
        XCTAssertEqual(snapshot.sources.last?.sourceText?.data(using: .utf8), first.sourceText?.data(using: .utf8))
    }

    func testDuplicateUsedIdentifiersOrSnapshotsFailInsteadOfCrashingOrSelectingAVersion() {
        let original = AskSourceRecord(id: "s1", title: "Original", contentVersion: "v1")
        let changed = AskSourceRecord(id: "s1", title: "Changed", contentVersion: "v2")
        for response in [answer(ids: ["s1", "s1"], sources: [original]),
                         answer(ids: ["s1"], sources: [original, original]),
                         answer(ids: ["s1"], sources: [original, changed])] {
            XCTAssertThrowsError(try AskSavedAttributionSnapshot(answer: response)) {
                XCTAssertEqual($0 as? AskSavedAttributionSnapshot.SnapshotError, .duplicateSourceID)
            }
        }
    }

    func testMissingUsedSnapshotCannotSilentlyAdoptAnotherSource() {
        let unrelated = AskSourceRecord(id: "s2", title: "Different source", contentVersion: "v1")
        XCTAssertThrowsError(try AskSavedAttributionSnapshot(answer: answer(ids: ["s1"], sources: [unrelated]))) {
            XCTAssertEqual($0 as? AskSavedAttributionSnapshot.SnapshotError, .missingSourceSnapshot)
        }
    }

    func testMissingOrBlankOriginalVersionCannotBecomeAnUnversionedSavedCitation() {
        let versions: [String?] = [nil, "", " \n"]
        for version in versions {
            let source = AskSourceRecord(id: "s1", title: "Original", contentVersion: version)
            XCTAssertThrowsError(try AskSavedAttributionSnapshot(answer: answer(ids: ["s1"], sources: [source]))) {
                XCTAssertEqual($0 as? AskSavedAttributionSnapshot.SnapshotError, .missingSourceVersion)
            }
        }
    }

    func testBlankIdentifiersFailAndSourceFreeResponsesDoNotInventAttribution() throws {
        XCTAssertThrowsError(try AskSavedAttributionSnapshot(answer: answer(ids: [" "], sources: []))) {
            XCTAssertEqual($0 as? AskSavedAttributionSnapshot.SnapshotError, .invalidSourceID)
        }
        let empty = try AskSavedAttributionSnapshot(answer: answer(ids: [], sources: []))
        XCTAssertTrue(empty.sourceIDs.isEmpty)
        XCTAssertTrue(empty.sourceVersions.isEmpty)
        XCTAssertTrue(empty.sources.isEmpty)
    }
}
