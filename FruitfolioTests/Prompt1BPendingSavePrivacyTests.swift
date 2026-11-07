import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BPendingSavePrivacyTests: XCTestCase {
    func testExcerptPayloadDoesNotRetainTheUnsavedRemainderOfAnAnswer() {
        let pending = Prompt10PendingSavedContent(question: "question", answer: "selected words plus private unsaved remainder",
            saveType: .excerpt, excerptText: "selected words", originalAnswerID: "answer-1",
            sourceIDs: ["source-1"], sourceRecords: [.init(id: "source-1", title: "Original source")])
        XCTAssertEqual(pending.answer, "selected words")
        XCTAssertFalse(pending.answer.contains("private unsaved remainder"))
        XCTAssertEqual(pending.originalAnswerID, "answer-1")
        XCTAssertEqual(pending.sourceRecords?.first?.title, "Original source")
    }
    func testImageOnlyAndTextWithImageRetainExactlyTheChosenContent() {
        let art: FruitfolioAssetID = .ovarian_cycle_follicle_development_stages
        let imageOnly = Prompt10PendingSavedContent(question: "question", answer: "private unsaved text", saveType: .excerpt,
            excerptText: "", sourceIDs: ["source-1"], educationalAssetIDs: [art])
        XCTAssertEqual(imageOnly.answer, "")
        XCTAssertEqual(imageOnly.educationalAssetIDs, [art])
        let combination = Prompt10PendingSavedContent(question: "question", answer: "whole unsaved answer", saveType: .excerpt,
            excerptText: "chosen passage", educationalAssetIDs: [art])
        XCTAssertEqual(combination.answer, "chosen passage")
        XCTAssertEqual(combination.educationalAssetIDs, [art])
    }

    func testOnlyExplicitFullAnswerSaveRetainsFullAnswer() {
        let pending = Prompt10PendingSavedContent(question: "question", answer: "full selected answer", saveType: .fullAnswer)
        XCTAssertEqual(pending.answer, "full selected answer")
        let invalid = Prompt10PendingSavedContent(question: "question", answer: "unsaved answer", saveType: .excerpt)
        XCTAssertEqual(invalid.answer, "")
    }
}

@MainActor
final class Prompt1BAskSourceVersionSaveTests: XCTestCase {
    func testConsistentDuplicateVersionsPreserveFullAndExcerptAttributionInActualCanonicalStore() async throws {
        let suite = "fruitfolio.tests.askSourceVersions." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let book = try store.createEncyclopedia(name: "source metadata fixture", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let source = AskSourceRecord(id: "fixture-source", title: "Synthetic source attribution",
            doi: "10.1234/fixture", publicationData: "Fixture Author (2020). Not medical evidence.", contentVersion: "v1")
        let legacy = AskSourceRecord(id: "legacy-source", title: "Legacy unversioned fixture")
        let sources = [source, source, legacy, legacy]
        let versions = try XCTUnwrap(Prompt09SaveSourceVersions.validated(sources))
        XCTAssertEqual(versions, ["fixture-source": "v1"])
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        let originalRecords = try encoder.encode(sources)
        let original = "Fixture value 12.500 pg/mL [fixture-source]. Original remainder."
        let excerpt = "12.500 pg/mL [fixture-source]"
        for type in [Prompt10SavedPageType.fullAnswer, .excerpt] {
            let pending = Prompt10PendingSavedContent(question: "original question", answer: original,
                saveType: type, excerptText: type == .excerpt ? excerpt : nil,
                originalAnswerID: "fixture-answer", originalConversationID: "fixture-conversation",
                sourceIDs: ["fixture-source", "legacy-source"], sourceVersions: versions,
                knowledgeBaseVersion: "fixture-kb", generationTimestamp: Date(timeIntervalSince1970: 99),
                sourceRecords: sources)
            let page = try store.savePage(.init(chapterID: chapter.id, question: pending.question,
                answer: pending.answer, saveType: pending.saveType, excerptText: pending.excerptText,
                originalAnswerID: pending.originalAnswerID, originalConversationID: pending.originalConversationID,
                sourceIDs: pending.sourceIDs, sourceVersions: pending.sourceVersions,
                knowledgeBaseVersion: pending.knowledgeBaseVersion, generationTimestamp: pending.generationTimestamp,
                sourceRecords: pending.sourceRecords), to: book.id, chapterID: chapter.id)
            let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            let saved = try XCTUnwrap(reloaded.encyclopedia(id: book.id)?.chapters.first?.pages.first { $0.id == page.id })
            XCTAssertEqual(saved.answer, type == .excerpt ? excerpt : original)
            XCTAssertEqual(saved.sourceVersions, ["fixture-source": "v1"])
            XCTAssertEqual(saved.sourceIDs, ["fixture-source", "legacy-source"])
            XCTAssertEqual(saved.originalAnswerID, "fixture-answer")
            XCTAssertEqual(saved.originalConversationID, "fixture-conversation")
            XCTAssertEqual(saved.generationTimestamp, Date(timeIntervalSince1970: 99))
            XCTAssertEqual(try encoder.encode(try XCTUnwrap(saved.sourceRecords)), originalRecords)
        }
    }

    func testConflictingBlankAndUnicodeCollidingMetadataIsRejectedWithoutNormalizingRecords() async throws {
        func source(_ id: String = "source", _ version: String?) -> AskSourceRecord {
            .init(id: id, title: "fixture", contentVersion: version)
        }
        let cases = [
            [source("source", "v1"), source("source", "v2")],
            [source("source", nil), source("source", "v1")],
            [source(" \n", "v1")], [source("source", " \n")],
            [source("café", "v1"), source("cafe\u{301}", "v1")],
            [source("source", "café"), source("source", "cafe\u{301}")]
        ]
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        for records in cases {
            let before = try encoder.encode(records)
            XCTAssertNil(Prompt09SaveSourceVersions.validated(records))
            XCTAssertEqual(try encoder.encode(records), before)
        }
    }

    func testLegacyAndEmptySourcesNeverAcquireInventedVersions() async {
        let legacy = AskSourceRecord(id: "legacy", title: "unversioned original")
        XCTAssertEqual(Prompt09SaveSourceVersions.validated([legacy, legacy]), [String: String]())
        XCTAssertEqual(Prompt09SaveSourceVersions.validated([]), [String: String]())
        XCTAssertNil(legacy.contentVersion)
    }
}
