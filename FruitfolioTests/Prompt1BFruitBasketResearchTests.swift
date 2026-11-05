import Foundation
import XCTest
@testable import Fruitfolio

final class Prompt1BFruitBasketResearchTests: XCTestCase {
    private func fixture(approved: Bool = true, eligible: Bool = true, includeParagraph: Bool = true) throws -> (URL, Prompt28BundledResearchProvider) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = FruitfolioResearchSource(sourceID: "fixture", title: "Nonclinical test fixture", authors: nil, organization: nil,
            publicationDate: nil, publicationType: nil, canonicalURL: nil, doi: nil, apa7Reference: approved ? "Fixture reference, not a medical source" : nil,
            verificationStatus: approved ? "verified" : "unresolved", retrievalEligibility: approved, sourceVersion: "1", verifiedAt: nil, contentVersion: "fixture")
        var note = FruitfolioResearchNoteChunk(chunkID: "chunk", researchTopicID: "fixture", heading: "fixture vocabulary", subheading: nil,
            text: "blood", sourceIDs: ["fixture"], semanticTags: [], domainTags: [], retrievalEligibility: eligible, sourceParagraphID: "paragraph")
        note.sourceParagraphID = "paragraph"
        var package = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: "fixture", generatedFrom: "test", generationNote: "no medical assertion",
            researchNoteChunks: [note], sources: [source], sourceChunks: [])
        package.sourceParagraphs = includeParagraph ? ["paragraph": "fixture vocabulary: blood body. quantities 2–4 mg; no medical assertion."] : [:]
        let url = directory.appendingPathComponent("package.json")
        try JSONEncoder().encode(package).write(to: url)
        return (directory, Prompt28BundledResearchProvider(packageStore: .init(resourceURL: url)))
    }

    func testActualCorpusQuestionsRestoreCompleteOriginalParagraphAndCitations() async throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        let store = FruitfolioResearchPackageStore(resourceURL: url)
        let package = try await store.load()
        let provider = Prompt28BundledResearchProvider(packageStore: store)
        for difficulty in Prompt28EducationalDifficulty.allCases {
            let question = try await provider.question(topic: "hormones", normalizedTopic: "hormones", difficulty: difficulty, excludingQuestionIDs: [])
            XCTAssertTrue(question.isPlayable)
            let answer = try XCTUnwrap(question.answerOptions.first { $0.id == question.correctAnswerID })
            let restored = question.questionText.replacingOccurrences(of: "which word completes this exact library excerpt?\n\n", with: "")
                .replacingOccurrences(of: "[blank]", with: answer.text)
            XCTAssertEqual(restored, question.sourceExcerpt)
            XCTAssertTrue(package.sourceParagraphs?.values.contains(restored) == true)
            let notes = package.researchNoteChunks.filter { note in
                note.retrievalEligibility != false && note.sourceParagraphID.flatMap { package.sourceParagraphs?[$0] } == restored
            }
            XCTAssertTrue(notes.contains { Set($0.sourceIDs) == Set(question.sourceIDs) })
            for record in try XCTUnwrap(question.sourceRecords) {
                let source = try XCTUnwrap(package.sources.first { $0.sourceID == record.id })
                XCTAssertTrue(source.isApprovedForDisplay)
                XCTAssertEqual(record.title, source.apa7Reference)
                XCTAssertEqual(record.doi, source.doi)
                XCTAssertEqual(record.urlString, source.canonicalURL)
            }
            XCTAssertEqual(question.catchConceptID, "visual-starred-fruit")
            XCTAssertTrue(question.reviewStatus.contains("not_independent_clinical_review"))
        }
    }

    func testEveryAvailableExcerptIsExhaustedBeforeTopicExhaustion() async throws {
        let (directory, provider) = try fixture(); defer { try? FileManager.default.removeItem(at: directory) }
        var excluded: Set<String> = []
        for _ in 0..<2 {
            let question = try await provider.question(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, excludingQuestionIDs: excluded)
            XCTAssertTrue(excluded.insert(question.id).inserted)
            XCTAssertTrue(question.sourceExcerpt?.contains("2–4 mg") == true)
        }
        do { _ = try await provider.question(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, excludingQuestionIDs: excluded); XCTFail("Expected exhausted exact source candidates") }
        catch Prompt28ResearchError.topicExhausted { }
    }

    func testMissingQuarantinedOrUnverifiedMaterialCannotBecomePlayableFacts() async throws {
        for values in [(false, true, true), (true, false, true), (true, true, false)] {
            let (directory, provider) = try fixture(approved: values.0, eligible: values.1, includeParagraph: values.2)
            defer { try? FileManager.default.removeItem(at: directory) }
            do { _ = try await provider.question(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, excludingQuestionIDs: []); XCTFail("No eligible source paragraph") }
            catch Prompt28ResearchError.unsupportedTopic { }
        }
    }

    func testUrgentAndSensitiveTopicsAreNotGamifiedBeforePackageLoading() async throws {
        let provider = Prompt28BundledResearchProvider(packageStore: .init(resourceURL: URL(fileURLWithPath: "/nonexistent/research.json")))
        do { _ = try await provider.question(topic: "I can’t breathe", normalizedTopic: "breathing", difficulty: .easy, excludingQuestionIDs: []); XCTFail("urgent topic must bypass game") }
        catch Prompt28ResearchError.urgentTopic { }
        do { _ = try await provider.question(topic: "pregnancy loss", normalizedTopic: "pregnancy loss", difficulty: .easy, excludingQuestionIDs: []); XCTFail("sensitive topic must bypass game") }
        catch Prompt28ResearchError.sensitiveTopic { }
    }

    func testClozeOnlyReplacesWholeWordAndPreservesOperatorsAndQuantities() throws {
        let text = "antibody, BODY: 2–4 mg, 1:2, x_y; body."
        let candidate = try XCTUnwrap(Prompt28SourceExcerptPractice.candidates(text: text, difficulty: .easy).first)
        XCTAssertEqual(candidate.originalWord, "BODY")
        XCTAssertEqual(candidate.text.replacingOccurrences(of: "[blank]", with: candidate.originalWord), text)
        XCTAssertTrue(candidate.text.hasPrefix("antibody"))
        XCTAssertEqual(Set(candidate.options.map(\.id)).count, 4)
    }

    func testNewQuestionRecordsRoundTripWithoutLosingCitationFields() async throws {
        let (directory, provider) = try fixture(); defer { try? FileManager.default.removeItem(at: directory) }
        let question = try await provider.question(topic: "fixture", normalizedTopic: "fixture", difficulty: .easy, excludingQuestionIDs: [])
        let restored = try JSONDecoder().decode(Prompt28Question.self, from: JSONEncoder().encode(question))
        XCTAssertEqual(restored, question)
        var invalid = question
        invalid.sourceRecords = []
        XCTAssertFalse(invalid.isPlayable)
    }
}
