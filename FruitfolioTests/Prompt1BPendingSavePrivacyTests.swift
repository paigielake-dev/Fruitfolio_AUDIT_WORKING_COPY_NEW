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
            let page = try store.savePage(pending.makeSavedPage(chapterID: chapter.id),
                to: book.id, chapterID: chapter.id)
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

@MainActor
final class Prompt1BSavedAnswerSupportTests: XCTestCase {
    private func answer(_ support: AskKnowledgeSupport = .partiallySupported,
                        preview: Bool = false, path: FruitfolioAnswerPath? = .retrievalFallback) -> AskAnswer {
        AskAnswer(originalQuestion: "explicit question", answerText: "selected words plus private unsaved concept",
            support: support, supportMap: [.init(concept: "private unsaved concept", support: .genuinelyNovel)],
            knowledgeBaseVersion: "fixture", isDevelopmentPreview: preview, answerPath: path)
    }
    private func authority() throws -> (Prompt10SavedLibraryStore, UserDefaults, String) {
        let name = "fruitfolio.tests.savedSupport." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        return (Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture"), defaults, name)
    }

    func testFullSupportSurvivesCanonicalSaveNotesReloadAndGuideReference() async throws {
        let (store, defaults, suite) = try authority()
        defer { defaults.removePersistentDomain(forName: suite) }
        let response = answer()
        let support = Prompt09SavedAnswerSupport(answer: response)
        let pending = Prompt10PendingSavedContent(question: response.originalQuestion, answer: response.answerText,
            saveType: .fullAnswer, evidenceSupport: support)
        let book = try store.createEncyclopedia(name: "support fixture", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let page = try store.savePage(.init(chapterID: chapter.id, question: pending.question,
            answer: pending.answer, saveType: pending.saveType, evidenceSupport: pending.evidenceSupport),
            to: book.id, chapterID: chapter.id)
        try store.updatePageNotes(encyclopediaID: book.id, chapterID: chapter.id, pageID: page.id,
            notes: "authored notes", expectedNotes: "")
        let guide = try store.createEncyclopedia(name: "support guide", style: .sage)
        let guideChapter = try XCTUnwrap(guide.chapters.first)
        let references = try store.prompt11AddSavedMaterials([page], to: guide.id, chapterID: guideChapter.id)
        XCTAssertEqual(references.first?.evidenceSupport, support)
        XCTAssertEqual(references.first?.sourceSavedPageID, page.id)
        let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        let original = try XCTUnwrap(reloaded.encyclopedia(id: book.id)?.chapters.first?.pages.first)
        XCTAssertEqual(original.evidenceSupport, support)
        XCTAssertEqual(original.evidenceSupport?.concepts, response.supportMap)
        XCTAssertEqual(original.evidenceSupport?.classification, .partiallySupported)
        XCTAssertEqual(original.evidenceSupport?.answerPath, .retrievalFallback)
        XCTAssertEqual(original.notes, "authored notes")
        XCTAssertEqual(original.answer, response.answerText)
        XCTAssertEqual(reloaded.encyclopedia(id: guide.id)?.chapters.first?.pages.first?.evidenceSupport, support)
    }

    func testExcerptAndImageOnlyMetadataOmitUnsavedConceptsThroughCanonicalReload() async throws {
        let (store, defaults, suite) = try authority()
        defer { defaults.removePersistentDomain(forName: suite) }
        let response = answer()
        let full = Prompt09SavedAnswerSupport(answer: response)
        let book = try store.createEncyclopedia(name: "selection support", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        for selection in ["selected words", ""] {
            let art: [FruitfolioAssetID]? = selection.isEmpty ? [.ovarian_cycle_follicle_development_stages] : nil
            let pending = Prompt10PendingSavedContent(question: response.originalQuestion, answer: response.answerText,
                saveType: .excerpt, excerptText: selection, educationalAssetIDs: art, evidenceSupport: full)
            XCTAssertNil(pending.evidenceSupport?.concepts)
            XCTAssertEqual(pending.evidenceSupport?.scope, .excerpt)
            let page = try store.savePage(.init(chapterID: chapter.id, question: pending.question,
                answer: pending.answer, saveType: .excerpt, excerptText: selection,
                educationalAssetIDs: art, evidenceSupport: full), to: book.id, chapterID: chapter.id)
            let reloaded = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            let saved = try XCTUnwrap(reloaded.encyclopedia(id: book.id)?.chapters.first?.pages.first { $0.id == page.id })
            let metadata = try XCTUnwrap(saved.evidenceSupport)
            XCTAssertNil(metadata.concepts)
            XCTAssertEqual(metadata.scope, .excerpt)
            XCTAssertEqual(metadata.classification, .partiallySupported)
            XCTAssertEqual(saved.answer, selection)
            XCTAssertNotNil(metadata.notice)
            let encoded = String(decoding: try JSONEncoder().encode(saved), as: UTF8.self)
            XCTAssertFalse(encoded.contains("private unsaved concept"))
        }
    }

    func testMissingLegacySupportStaysUnknownAndFutureMetadataIsNeverRewritten() async throws {
        let (store, defaults, suite) = try authority()
        defer { defaults.removePersistentDomain(forName: suite) }
        let book = try store.createEncyclopedia(name: "legacy support", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let page = try store.savePage(.init(chapterID: chapter.id, question: "legacy", answer: "original",
            saveType: .fullAnswer), to: book.id, chapterID: chapter.id)
        XCTAssertNil(page.evidenceSupport)
        let bytes = try XCTUnwrap(defaults.data(forKey: "fixture"))
        let legacy = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        XCTAssertNil(legacy.encyclopedia(id: book.id)?.chapters.first?.pages.first?.evidenceSupport)
        XCTAssertEqual(defaults.data(forKey: "fixture"), bytes)
        let metadata = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(Prompt09SavedAnswerSupport(answer: answer()))) as? [String: Any])
        var future = metadata; future["futureField"] = NSNull()
        var unknown = metadata; unknown["classification"] = "future-support"
        let values: [Any] = [future, unknown, NSNull()]
        for value in values {
            var root = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [[String: Any]])
            var chapters = try XCTUnwrap(root[0]["chapters"] as? [[String: Any]])
            var pages = try XCTUnwrap(chapters[0]["pages"] as? [[String: Any]])
            pages[0]["evidenceSupport"] = value
            chapters[0]["pages"] = pages; root[0]["chapters"] = chapters
            let original = try JSONSerialization.data(withJSONObject: root, options: .sortedKeys)
            defaults.set(original, forKey: "fixture")
            let protected = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
            XCTAssertNotNil(protected.storageProtectionReason)
            XCTAssertThrowsError(try protected.createEncyclopedia(name: "valid blocked fixture", style: .sage))
            XCTAssertEqual(defaults.data(forKey: "fixture"), original)
        }
    }

    func testPreviewSafetyAndUnavailableQualifiersStayDistinctFromResearchSupport() async {
        for response in [answer(.supported, preview: true), answer(.supported, path: .localSafety),
                         answer(.supported, path: .unavailableContent), answer(.supported, path: .unsupported)] {
            let snapshot = Prompt09SavedAnswerSupport(answer: response)
            XCTAssertEqual(snapshot.classification, response.support)
            XCTAssertEqual(snapshot.answerPath, response.answerPath)
            XCTAssertEqual(snapshot.isDevelopmentPreview, response.isDevelopmentPreview)
            XCTAssertNotNil(snapshot.notice)
        }
        XCTAssertNil(Prompt09SavedAnswerSupport(answer: answer(.supported, path: .generated)).notice)
        XCTAssertNotNil(Prompt09SavedAnswerSupport(answer: answer(.genuinelyNovel)).notice)
    }
}
