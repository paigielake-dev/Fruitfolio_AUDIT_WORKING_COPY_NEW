import XCTest
@testable import Fruitfolio

private actor Prompt1BUnavailableSynthesis: FruitfolioLanguageModel {
    func availability() async -> FruitfolioLanguageModelAvailability { .packageNotLinked }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}

private actor Prompt1BSingleEvidenceSynthesis: FruitfolioLanguageModel {
    private(set) var expectedSourceIDs: Set<String> = []
    func availability() async -> FruitfolioLanguageModelAvailability { .available }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        let permitted = Set(evidence.claimEvidenceMap.flatMap(\.noteChunkIDs))
        let note = try XCTUnwrap(evidence.researchNoteChunks.first { permitted.contains($0.chunkID) })
        expectedSourceIDs = Set(note.sourceIDs)
        return .init(bridge: nil, claims: [.init(text: note.text, evidenceIDs: [note.chunkID])], limitation: nil)
    }
}

private actor Prompt1BClaimMapCapture: FruitfolioLanguageModel {
    private(set) var captured: FruitfolioEvidencePacket?
    func availability() async -> FruitfolioLanguageModelAvailability { .packageNotLinked }
    func generateDraft(question: String, evidence: FruitfolioEvidencePacket) async throws -> FruitfolioGeneratedDraft {
        captured = evidence
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}

@MainActor
final class Prompt1BResearchEngineIntegrationTests: XCTestCase {
    private func store() throws -> FruitfolioResearchPackageStore {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        return FruitfolioResearchPackageStore(resourceURL: url)
    }
    func testMultiClaimOptimizationPreservesActualCorpusEvidenceLinksAndCitations() async throws {
        let capture = Prompt1BClaimMapCapture()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: capture)
        let answer = try await engine.answer(
            question: "how does progesterone affect temperature and how does estradiol support follicles?", conversation: [])
        let captured = await capture.captured
        let packet = try XCTUnwrap(captured)
        XCTAssertGreaterThan(packet.claimEvidenceMap.count, 1)
        for mapping in packet.claimEvidenceMap {
            let claim = FruitfolioQueryNormalizer.tokens(mapping.claim.text)
            let expectedNotes = packet.researchNoteChunks.filter {
                !claim.intersection(FruitfolioQueryNormalizer.tokens($0.text)).isEmpty
            }.map(\.chunkID)
            let expectedSources = packet.sourceChunks.filter {
                !claim.intersection(FruitfolioQueryNormalizer.tokens($0.text)).isEmpty
            }.map(\.sourceChunkID)
            XCTAssertEqual(mapping.noteChunkIDs, expectedNotes)
            XCTAssertEqual(mapping.sourceChunkIDs, expectedSources)
        }
        XCTAssertFalse(answer.sourceIDs.isEmpty)
        XCTAssertEqual(answer.answerPath, .retrievalFallback)
        XCTAssertEqual(Set(answer.sourceIDs), Set(answer.sources.map(\.id)))
    }

    func testActualFallbackAndGameExplanationUseReviewedSourceRolesWithOriginalCitations() async throws {
        let complete = try await store().load()
        let review = try XCTUnwrap(FruitfolioReviewedSemanticContexts.passages.first { $0.noteID == "note_ca00d1045d9609459ec60f03" })
        let note = try XCTUnwrap(complete.researchNoteChunks.first { $0.chunkID == review.noteID })
        let sources = complete.sources.filter { note.sourceIDs.contains($0.sourceID) }
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var subset = FruitfolioResearchPackage(schemaVersion: 1, contentVersion: complete.contentVersion,
            generatedFrom: "Actual corpus subset for formatting regression", generationNote: "Original facts and citations unchanged; not new clinical evidence",
            researchNoteChunks: [note], sources: sources, sourceChunks: [])
        if let id = note.sourceParagraphID { subset.sourceParagraphs = [id: review.originalText] }
        let url = directory.appendingPathComponent("research.json")
        try JSONEncoder().encode(subset).write(to: url)
        let packageStore = FruitfolioResearchPackageStore(resourceURL: url)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: packageStore, languageModel: Prompt1BUnavailableSynthesis())
        let answer = try await engine.answer(question: "apple slices", conversation: [])
        XCTAssertEqual(answer.answerPath, .retrievalFallback)
        XCTAssertTrue(answer.answerText.contains("**apple slices**"))
        XCTAssertTrue(answer.answerText.contains("**peanut butter**"))
        XCTAssertEqual(Set(answer.sourceIDs), Set(note.sourceIDs))
        let generated = try await FruitfolioResearchIntelligenceEngine(packageStore: packageStore,
            languageModel: Prompt1BSingleEvidenceSynthesis()).answer(question: "apple slices", conversation: [])
        XCTAssertEqual(generated.answerPath, .generated)
        XCTAssertTrue(generated.answerText.contains("**apple slices**"))
        XCTAssertTrue(generated.answerText.contains("**peanut butter**"))
        XCTAssertEqual(Set(generated.sourceIDs), Set(note.sourceIDs))
        let game = try await Prompt28BundledResearchProvider(packageStore: packageStore).question(
            topic: "apple slices", normalizedTopic: "apple slices", difficulty: .easy, excludingQuestionIDs: [])
        XCTAssertEqual(game.sourceExcerpt, review.originalText)
        XCTAssertTrue(game.explanation.contains("**apple slices**"))
        XCTAssertTrue(game.explanation.contains("**peanut butter**"))
        XCTAssertEqual(Set((game.sourceRecords ?? []).map(\.id)), Set(note.sourceIDs))
    }

    func testActualResearchEngineProvidesCitedFallbackWhenLocalGenerationIsUnavailable() async throws {
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: Prompt1BUnavailableSynthesis())
        let answer = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        XCTAssertFalse(answer.answerText.isEmpty)
        XCTAssertTrue(answer.answerText.contains("let’s start"))
        XCTAssertTrue(answer.answerText.contains("☆"))
        XCTAssertFalse(answer.sourceIDs.isEmpty)
        XCTAssertEqual(answer.sourceIDs, answer.sources.map(\.id))
        XCTAssertTrue(answer.sources.allSatisfy { !$0.title.isEmpty })
        XCTAssertFalse(answer.isDevelopmentPreview)
        XCTAssertEqual(answer.answerPath, .retrievalFallback)
        XCTAssertGreaterThan(engine.lastDiagnostics?.noteCount ?? 0, 0)
    }
    func testSourcesContainOnlyEvidenceActuallyPresented() async throws {
        let model = Prompt1BSingleEvidenceSynthesis()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: model)
        let answer = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        let expected = await model.expectedSourceIDs
        XCTAssertEqual(answer.answerPath, .generated)
        XCTAssertFalse(expected.isEmpty)
        XCTAssertEqual(Set(answer.sourceIDs), expected)
    }
    func testUrgentGuidanceDoesNotDependOnPackageOrModelAvailability() async throws {
        let missing = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/missing/research.json"))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: missing, languageModel: Prompt1BUnavailableSynthesis())
        let answer = try await engine.answer(question: "I cannot breathe", conversation: [])
        XCTAssertTrue(answer.answerText.contains("seek emergency medical care now"))
        XCTAssertEqual(answer.knowledgeBaseVersion, "local-safety-guidance-v1")
        XCTAssertEqual(answer.answerPath, .localSafety)
        XCTAssertTrue(answer.sources.isEmpty)
    }
    func testUnsupportedQuestionIsReportedAfterTheActualLibrarySearch() async throws {
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: Prompt1BUnavailableSynthesis())
        let answer = try await engine.answer(question: "zxqvplmkgtrn", conversation: [])
        XCTAssertEqual(answer.support, .genuinelyNovel)
        XCTAssertEqual(answer.answerPath, .unsupported)
        XCTAssertEqual(answer.answerText, FruitfolioCanonicalAnswerVoice.unsupportedMessage)
        XCTAssertNotNil(engine.lastDiagnostics)
        XCTAssertTrue(answer.sources.isEmpty)
    }
    #if canImport(llama)
    func testNativeModelAnswersFromActualCorpusWithinWholeParagraphBudgets() async throws {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_MODEL_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioAI", withExtension: "gguf"))
        let model = LlamaFruitfolioLanguageModel(modelURL: url)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: model)
        let answer = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        XCTAssertEqual(answer.answerPath, .generated, "A fallback must not count as successful integrated native inference")
        XCTAssertFalse(answer.sourceIDs.isEmpty)
        XCTAssertTrue(answer.answerText.contains("☆"))
        XCTAssertFalse(answer.isDevelopmentPreview)
        await model.releaseResources()
        await model.releaseResources()
        let reloaded = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        XCTAssertEqual(reloaded.answerPath, .generated, "A released native model must reload and genuinely generate")
        XCTAssertEqual(reloaded.sourceIDs, answer.sourceIDs)
        XCTAssertEqual(reloaded.answerText, answer.answerText)
        await model.releaseResources()
    }
    #endif

}
