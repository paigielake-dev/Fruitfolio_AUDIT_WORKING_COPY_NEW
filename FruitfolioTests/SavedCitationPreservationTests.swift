import XCTest
@testable import Fruitfolio

@MainActor
final class SavedCitationPreservationTests: XCTestCase {
    private func source(version: String = "v1", approved: Bool = true) -> FruitfolioResearchSource {
        .init(sourceID: "fixture-source", title: "Synthetic metadata fixture", authors: "Fixture, A.", organization: nil,
              publicationDate: "2020", publicationType: "test fixture", canonicalURL: "https://example.org/fixture",
              doi: nil, apa7Reference: "Fixture, A. (2020). Synthetic reference, \(version).", verificationStatus: approved ? "verified" : "unresolved",
              retrievalEligibility: approved, sourceVersion: version, verifiedAt: nil, contentVersion: version)
    }
    private func package(version: String = "v1", approved: Bool = true) -> FruitfolioResearchPackage {
        .init(schemaVersion: 1, contentVersion: "library-v1", generatedFrom: "synthetic fixture", generationNote: "Not medical evidence",
              researchNoteChunks: [], sources: [source(version: version, approved: approved)], sourceChunks: [])
    }
    private func page(snapshots: [AskSourceRecord]? = nil) -> Prompt10SavedPage {
        .init(chapterID: UUID(), question: "fixture", answer: "original saved words", saveType: .fullAnswer,
              sourceIDs: ["fixture-source"], sourceVersions: ["fixture-source": "v1"], sourceSnapshots: snapshots,
              knowledgeBaseVersion: "library-v1")
    }
    private var snapshot: AskSourceRecord {
        .init(id: "fixture-source", title: "Fixture", sourceText: "Fixture, A. (2020). Exact original reference.",
              urlString: "https://example.org/fixture", contentVersion: "v1")
    }
    func testSavedReferenceSurvivesRestartEncodingAndCannotBeReplacedByANewLibraryVersion() throws {
        let original = page(snapshots: [snapshot])
        let restored = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONEncoder().encode(original))
        let display = Prompt10SavedCitationResolver.resolve(restored, package: package(version: "v2"))
        XCTAssertEqual(display.map(\.reference), [snapshot.sourceText])
        XCTAssertTrue(display[0].isSnapshot)
        XCTAssertEqual(restored.answer, original.answer)
        XCTAssertEqual(restored.sourceIDs, original.sourceIDs)
        XCTAssertEqual(restored.sourceVersions, original.sourceVersions)
    }
    func testUnrelatedExtraReferenceCannotAcquireAttributionOnASavedPage() {
        let unrelated = AskSourceRecord(id: "unrelated", title: "Not cited", sourceText: "Unrelated reference", contentVersion: "v1")
        let display = Prompt10SavedCitationResolver.resolve(page(snapshots: [snapshot, unrelated]))
        XCTAssertEqual(display.count, 1); XCTAssertEqual(display[0].id, "fixture-source")
        XCTAssertEqual(display[0].reference, snapshot.sourceText)
    }
    func testDuplicateMissingBlankAndWrongVersionSnapshotFailClosedWithoutRetrofittingAnotherSource() {
        let wrong = AskSourceRecord(id: "fixture-source", title: "Wrong version", sourceText: "Changed reference", contentVersion: "v2")
        let blank = AskSourceRecord(id: "fixture-source", title: "Title alone is not an APA citation", contentVersion: "v1")
        for snapshots in [[], [snapshot, snapshot], [wrong], [blank]] {
            XCTAssertNil(Prompt10SavedCitationResolver.resolve(page(snapshots: snapshots), package: package()).first?.reference)
        }
    }
    func testLegacyMetadataResolvesOnlyAnExactlyMatchingApprovedLibrarySource() throws {
        let legacy = page()
        let good = Prompt10SavedCitationResolver.resolve(legacy, package: package())
        XCTAssertEqual(good[0].reference, source().apa7Reference)
        XCTAssertFalse(good[0].isSnapshot)
        XCTAssertNil(Prompt10SavedCitationResolver.resolve(legacy, package: package(version: "v2"))[0].reference)
        XCTAssertNil(Prompt10SavedCitationResolver.resolve(legacy, package: package(approved: false))[0].reference)
        var unknownVersion = legacy; unknownVersion.sourceVersions = [:]
        XCTAssertNil(Prompt10SavedCitationResolver.resolve(unknownVersion, package: package())[0].reference)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(legacy)) as? [String: Any])
        object.removeValue(forKey: "sourceSnapshots")
        let decoded = try JSONDecoder().decode(Prompt10SavedPage.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.sourceSnapshots)
        XCTAssertEqual(decoded.sourceIDs, legacy.sourceIDs)
    }
    func testGuideCopyAndStoreReopenPreserveTheSameReferenceSnapshot() throws {
        let suite = "Fruitfolio.SavedCitations.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite)); defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "citation-fixture")
        let book = try store.createEncyclopedia(name: "original", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        var original = page(snapshots: [snapshot]); original.chapterID = chapter.id
        let saved = try store.savePage(original, to: book.id, chapterID: chapter.id)
        let guide = try store.createGuideEncyclopedia(name: "guide", subtitle: "", style: .pink)
        let section = try store.createChapter(in: guide.id, name: "section")
        _ = try store.prompt11AddSavedMaterial(saved, to: guide.id, chapterID: section.id)
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "citation-fixture")
        let copy = try XCTUnwrap(reopened.encyclopedia(id: guide.id)?.chapters.flatMap(\.pages).first)
        XCTAssertEqual(copy.sourceSnapshots, [snapshot]); XCTAssertEqual(copy.sourceIDs, original.sourceIDs)
        XCTAssertEqual(copy.sourceVersions, original.sourceVersions)
        XCTAssertEqual(Prompt10SavedCitationResolver.resolve(copy)[0].reference, snapshot.sourceText)
    }
    func testSavedReferenceDoesNotOpenLocalOrCustomSchemeURLs() {
        let unsafe = AskSourceRecord(id: "fixture-source", title: "fixture", sourceText: "Exact reference", urlString: "file:///private/fixture", contentVersion: "v1")
        let resolved = Prompt10SavedCitationResolver.resolve(page(snapshots: [unsafe]))
        XCTAssertEqual(resolved[0].reference, "Exact reference")
        XCTAssertNil(resolved[0].urlString)
    }
}
