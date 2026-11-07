import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BEducationResearchTests: XCTestCase {
    private func store() throws -> FruitfolioResearchPackageStore {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        return FruitfolioResearchPackageStore(resourceURL: try XCTUnwrap(explicit ??
            Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json")))
    }

    func testRegistryUsesTheExistingModuleCatalogsAndRejectsUnsupportedContentBeforeLoading() async throws {
        let requests = FruitfolioEducationResearch.requests
        XCTAssertEqual(Set(requests.map(\.id)).count, requests.count)
        XCTAssertEqual(requests.count, Prompt25FertilizationSequence.stages.count +
            Prompt26PregnancyEducationCatalog.topics.count + Prompt27ScientificAssetCatalog.canonicalAssets.count)
        for stage in Prompt25FertilizationSequence.stages {
            XCTAssertTrue(requests.contains { $0.id == stage.shortContentID && $0.title == stage.title })
        }
        let research = FruitfolioEducationResearch(packageStore: .init(resourceURL:
            URL(fileURLWithPath: "/unavailable/research.json")))
        do {
            _ = try await research.article(for: "unreviewed.arbitrary.content")
            XCTFail("Unknown content must not fetch or improvise a chapter")
        } catch { XCTAssertEqual(error as? FruitfolioEducationResearchError, .unknownContent) }
        for period in Prompt26PregnancyEducationCatalog.fetalReferencePeriods {
            do {
                _ = try await research.article(for: period.contentID)
                XCTFail("An unreviewed reference-period mapping must not become generic or personalized fetal content")
            } catch { XCTAssertEqual(error as? FruitfolioEducationResearchError, .unavailable) }
        }
    }

    func testStageScopeDoesNotMisrepresentEightOrTwelveCellSourcesAsTwoCellEducation() throws {
        let stage = Prompt25FertilizationSequence.stage(for: .twoCell)
        let request = try XCTUnwrap(FruitfolioEducationResearch.requests.first { $0.id == stage.shortContentID })
        let matcher = try NSRegularExpression(pattern: request.requiredPattern, options: .caseInsensitive)
        for (text, expected) in [("two-cell nonclinical scope fixture", true), ("2 cell fixture", true),
                                 ("8-cell fixture", false), ("12-cell fixture", false), ("24-cell fixture", false)] {
            XCTAssertEqual(matcher.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil, expected)
        }
    }

    func testScientificScopeRejectsIncidentalSocialAndDiseaseNameMatchesAndAcceptsRealAliases() throws {
        func matches(_ concept: Prompt27ScienceConcept, _ text: String) throws -> Bool {
            let asset = try XCTUnwrap(Prompt27ScientificAssetCatalog.canonicalAssets.first { $0.concept == concept })
            let request = try XCTUnwrap(FruitfolioEducationResearch.requests.first {
                $0.id == FruitfolioEducationResearch.scienceID(for: asset)
            })
            let regex = try NSRegularExpression(pattern: request.requiredPattern, options: .caseInsensitive)
            return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
        }
        XCTAssertFalse(try matches(.culture, "beauty has a history, culture, and legacy."))
        XCTAssertTrue(try matches(.culture, "nonclinical agar plate scope fixture"))
        XCTAssertFalse(try matches(.cell, "sickle cell trait reproductive planning fixture"))
        XCTAssertFalse(try matches(.protein, "dairy foods provide protein and calcium"))
        XCTAssertFalse(try matches(.receptor, "hormone receptor-positive cancer may delay pregnancy"))
        XCTAssertFalse(try matches(.stomach, "symptoms involve the heart, brain, stomach, and muscles"))
        XCTAssertTrue(try matches(.rna, "ribonucleic acid scope fixture"))
        XCTAssertTrue(try matches(.mitochondrion, "mitochondria scope fixture"))
        XCTAssertTrue(try matches(.testTube, "test-tubes scope fixture"))
    }

    func testActualCorpusPreservesCompleteParagraphsTheirOwnCitationsAndRecordsMissingTopicsHonestly() async throws {
        let store = try store()
        let package = try await store.load()
        let notes = Dictionary(uniqueKeysWithValues: package.researchNoteChunks.map { ($0.chunkID, $0) })
        let sources = Dictionary(uniqueKeysWithValues: package.sources.map { ($0.sourceID, $0) })
        let research = FruitfolioEducationResearch(packageStore: store)
        var selected: [String: String] = [:]
        var missing: [String] = []
        for request in FruitfolioEducationResearch.requests {
            do {
                let article = try await research.article(for: request.id)
                let note = try XCTUnwrap(notes[article.noteID])
                XCTAssertNotEqual(note.retrievalEligibility, false)
                let original = note.sourceParagraphID.flatMap { package.sourceParagraphs?[$0] } ?? note.text
                XCTAssertEqual(Data(article.originalText.utf8), Data(original.utf8))
                XCTAssertEqual(article.contentID, request.id)
                XCTAssertEqual(article.title, request.title)
                XCTAssertEqual(article.knowledgeBaseVersion, package.contentVersion)
                XCTAssertEqual(Set(article.sources.map(\.id)), Set(note.sourceIDs))
                XCTAssertNotNil(Prompt09SaveSourceVersions.validated(article.sources))
                for record in article.sources {
                    let source = try XCTUnwrap(sources[record.id])
                    XCTAssertTrue(source.isApprovedForDisplay)
                    XCTAssertEqual(record.title, source.apa7Reference ?? source.title)
                    XCTAssertEqual(record.urlString, source.canonicalURL)
                    XCTAssertEqual(record.doi, source.doi)
                    XCTAssertEqual(record.publicationData, source.publicationDate)
                    XCTAssertEqual(record.contentVersion, source.contentVersion)
                }
                selected[request.id] = article.noteID
            } catch FruitfolioEducationResearchError.unavailable { missing.append(request.id) }
        }
        XCTAssertFalse(selected.isEmpty, "Exercise real corpus consumption, not only unavailable fallbacks")
        let coverage: [String: Any] = ["selected_original_note_ids": selected, "missing_content_ids": missing.sorted(),
            "limit": "Topic-match/source-integrity coverage only; not complete chapter, clinical or Apple verification."]
        let data = try JSONSerialization.data(withJSONObject: coverage, options: [.sortedKeys])
        print("Education actual-corpus coverage " + String(decoding: data, as: UTF8.self))
    }

    @MainActor
    func testAllThreeRealProtocolAdaptersConsumeTheSameGroundedArticleAndSourceReaderRejectsForeignIDs() async throws {
        let research = FruitfolioEducationResearch(packageStore: try store())
        let stage = Prompt25FertilizationSequence.stage(for: .oocyte)
        let original = try await research.article(for: stage.shortContentID)
        let fertilization = await FruitfolioFertilizationResearchAdapter(research: research).content(for: stage)
        XCTAssertTrue(fertilization.isApproved)
        XCTAssertEqual(fertilization.shortText, original.modulePresentation)
        XCTAssertEqual(fertilization.sourceCount, original.sources.count)
        let pregnancyID = Prompt26PregnancyEducationCatalog.topic(.testing).shortContentID
        let pregnancyArticle = try await research.article(for: pregnancyID)
        let pregnancy = try await FruitfolioPregnancyResearchAdapter(research: research).approvedContent(for: pregnancyID)
        XCTAssertEqual(pregnancy.summary, pregnancyArticle.modulePresentation)
        XCTAssertEqual(pregnancy.sourceIDs, pregnancyArticle.sources.map(\.id))
        let dna = try XCTUnwrap(Prompt27ScientificAssetCatalog().asset(for: .geneticsDNA))
        let scienceID = FruitfolioEducationResearch.scienceID(for: dna)
        let scienceArticle = try await research.article(for: scienceID)
        let science = try await FruitfolioScienceResearchAdapter(research: research).approvedContent(for: scienceID)
        XCTAssertEqual(science.body, scienceArticle.modulePresentation)
        XCTAssertEqual(science.sourceIDs, scienceArticle.sources.map(\.id))
        let records = try await research.sourceRecords(ids: original.sources.map(\.id))
        XCTAssertEqual(records, original.sources)
        let pending = try original.prepareSave()
        let saved = pending.makeSavedPage(chapterID: UUID())
        XCTAssertEqual(saved.answer, original.presentation)
        XCTAssertEqual(saved.sourceIDs, original.sources.map(\.id))
        XCTAssertEqual(saved.sourceRecords, original.sources)
        XCTAssertEqual(saved.sourceVersions, Prompt09SaveSourceVersions.validated(original.sources))
        XCTAssertEqual(saved.knowledgeBaseVersion, original.knowledgeBaseVersion)
        XCTAssertTrue(saved.originalAnswerID?.contains(original.noteID) == true)
        XCTAssertNil(saved.originalConversationID)
        XCTAssertEqual(scienceArticle.title, "DNA")
        let suite = "EducationSavedOriginal." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "education-fixture")
        let book = try library.createEncyclopedia(name: "fixture", style: .sage)
        let chapter = try XCTUnwrap(book.chapters.first)
        let stored = try library.savePage(pending.makeSavedPage(chapterID: chapter.id),
            to: book.id, chapterID: chapter.id)
        let reopened = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "education-fixture")
        let reloaded = try XCTUnwrap(reopened.encyclopedia(id: book.id)?.chapters.first?.pages.first)
        XCTAssertEqual(reloaded, stored)
        XCTAssertEqual(reloaded.answer, original.presentation)
        XCTAssertEqual(reloaded.sourceRecords, original.sources)
        XCTAssertEqual(reloaded.sourceVersions, pending.sourceVersions)
        XCTAssertEqual(reloaded.originalAnswerID, pending.originalAnswerID)
        do {
            _ = try await research.sourceRecords(ids: ["nonexistent-source"])
            XCTFail("Foreign IDs must not obtain invented attribution")
        } catch { XCTAssertEqual(error as? FruitfolioEducationResearchError, .invalidSourceMetadata) }
    }
}
