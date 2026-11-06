import Foundation
import XCTest
@testable import Fruitfolio

private actor Prompt1BDisplayOnlyTranslationFixture: FruitfolioLocalTranslationRuntime {
    func releaseResources() {}
    func translate(_ text: String, targetTag: String) async throws -> String {
        text.replacingOccurrences(of: "original prose", with: "fixture translated prose")
    }
}

final class Prompt1BSavedTranslationBoundaryTests: XCTestCase {
    private func page(type: Prompt10SavedPageType = .fullAnswer) -> Prompt10SavedPage {
        Prompt10SavedPage(chapterID: UUID(), question: "original question", answer: "original prose 12 pg/mL [A]",
            saveType: type, excerptText: "original prose 12 pg/mL [A]", originalAnswerID: "answer-1",
            sourceIDs: ["A"], sourceVersions: ["A": "paper-v7"], knowledgeBaseVersion: "package-v2",
            generationTimestamp: Date(timeIntervalSince1970: 1_700_000_000), notes: "my note: −2.5 µIU/mL",
            excerptSemanticSpans: [.init(text: "original prose 12 pg/mL [A]", emphasis: .anchorBold)], excerptLanguage: "fr",
            sourceRecords: [.init(id: "A", title: "Original APA fixture", urlString: "https://example.test/source", contentVersion: "paper-v7")])
    }
    func testFullAnswersIgnoreStaleExcerptMetadataButExcerptsKeepRecordedLanguageAndSpans() {
        let full = page()
        XCTAssertTrue(full.allowsAutomaticDisplayTranslation)
        XCTAssertEqual(full.displaySourceLanguage, "en")
        XCTAssertNil(full.displaySemanticSpans)
        let excerpt = page(type: .excerpt)
        XCTAssertEqual(excerpt.displaySourceLanguage, "fr")
        XCTAssertEqual(excerpt.displaySemanticSpans, excerpt.excerptSemanticSpans)
        XCTAssertEqual(excerpt.displayBody, excerpt.excerptText)
    }
    func testUserMaterialAndUnattributedPagesRemainOriginalEvenWithConflictingLegacyOrigin() {
        var authored = page()
        authored.userMaterial = .init(sourceURL: nil, addedAt: Date(), editedAt: Date())
        XCTAssertFalse(authored.allowsAutomaticDisplayTranslation)
        XCTAssertEqual(authored.displayBody, authored.answer)
        var unattributed = page()
        unattributed.originalAnswerID = nil
        XCTAssertFalse(unattributed.allowsAutomaticDisplayTranslation)
    }
    func testMismatchedSemanticMetadataCannotReplaceTheActualSavedExcerpt() {
        var saved = page(type: .excerpt)
        saved.excerptSemanticSpans = [.init(text: "unrelated stale text")]
        XCTAssertNil(saved.displaySemanticSpans)
        XCTAssertEqual(saved.displayBody, "original prose 12 pg/mL [A]")
        saved.userMaterial = .init(sourceURL: nil, addedAt: Date(), editedAt: Date())
        saved.excerptSemanticSpans = [.init(text: saved.displayBody)]
        XCTAssertNil(saved.displaySemanticSpans)
    }
    func testDisplayTranslationAndLanguageChangesCannotRewriteActualSavedDocumentOrMetadata() async throws {
        let suite = "Fruitfolio.saved-translation." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        var saved = page()
        let bookID = UUID(), chapterID = saved.chapterID
        let book = Prompt10Encyclopedia(id: bookID, name: "user title", style: .sage,
            chapters: [.init(id: chapterID, encyclopediaID: bookID, name: "user chapter", order: 0, pages: [saved])])
        var persistence = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library")
        try persistence.commit([book])
        let originalBytes = try XCTUnwrap(defaults.data(forKey: "library"))
        let service = FruitfolioTranslationService(runtime: Prompt1BDisplayOnlyTranslationFixture())
        for language in [FruitfolioLanguage.spanish, .arabic, .quechua, .english] {
            FruitfolioLanguagePreferences.save(language, to: defaults)
            let display = try await service.translate(saved.displayBody, language: language, protectedLiterals: saved.sourceIDs,
                                                      sourceLanguage: saved.displaySourceLanguage)
            XCTAssertEqual(display, language == .english ? saved.answer : "fixture translated prose 12 pg/mL [A]")
            XCTAssertEqual(defaults.data(forKey: "library"), originalBytes)
            let restored = Prompt10SavedLibraryPersistence(defaults: defaults, key: "library").committed
            XCTAssertEqual(restored, [book])
            XCTAssertEqual(restored[0].chapters[0].pages[0].sourceRecords, saved.sourceRecords)
            XCTAssertEqual(restored[0].chapters[0].pages[0].notes, "my note: −2.5 µIU/mL")
        }
        // Explicit user note edits remain separate from original evidence and display text.
        saved.notes = "my updated original-language note"
        XCTAssertEqual(saved.answer, book.chapters[0].pages[0].answer)
        XCTAssertEqual(defaults.data(forKey: "library"), originalBytes)
        // Fixture checks persistence/display boundaries, not actual MT quality.
    }
}
