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

/// Controlled runtime contract only, never official MADLAD quality evidence.
private actor Prompt1BQueryTranslationRuntime: FruitfolioLocalTranslationRuntime {
    let result: String?
    private(set) var targetTags: [String] = []
    init(result: String? = nil) { self.result = result }
    func translate(_ text: String, targetTag: String) async throws -> String {
        targetTags.append(targetTag)
        guard let result else { throw FruitfolioTranslationError.resourcesMissing }
        return result
    }
    func releaseResources() async {}
}

@MainActor
final class Prompt1BResearchEngineIntegrationTests: XCTestCase {
    private func store() throws -> FruitfolioResearchPackageStore {
        let explicit = ProcessInfo.processInfo.environment["FRUITFOLIO_TEST_RESEARCH_PATH"].map { URL(fileURLWithPath: $0) }
        let url = try XCTUnwrap(explicit ?? Bundle.main.url(forResource: "FruitfolioResearchPackage", withExtension: "json"))
        return FruitfolioResearchPackageStore(resourceURL: url)
    }
    func testLocalizedQuestionRetrievesActualEnglishEvidenceWithoutChangingOriginalQuestion() async throws {
        let question = "comment la progestérone affecte-t-elle la température ?"
        let english = "how does progesterone affect temperature?"
        let runtime = Prompt1BQueryTranslationRuntime(result: english)
        let service = FruitfolioTranslationService(runtime: runtime)
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(),
            languageModel: Prompt1BUnavailableSynthesis(), translationService: service)
        let localized = try await engine.answer(question: question, conversation: [], trackerContext: nil,
            userContext: nil, inputLanguage: .french, translationInferenceAllowed: true, progress: nil)
        let baseline = try await engine.answer(question: english, conversation: [])
        XCTAssertEqual(Data(localized.originalQuestion.utf8), Data(question.utf8))
        XCTAssertEqual(localized.sourceIDs, baseline.sourceIDs)
        XCTAssertEqual(localized.answerText, baseline.answerText)
        XCTAssertFalse(localized.sourceIDs.isEmpty)
        XCTAssertEqual(localized.answerPath, .retrievalFallback)
        let tags = await runtime.targetTags
        XCTAssertEqual(tags, ["en"])
        let flights = await service.debugInFlightStatistics()
        XCTAssertEqual(flights.requests, 0)
        XCTAssertEqual(flights.waiters, 0)
        XCTAssertEqual(flights.unshared, 0)
    }

    func testEnglishQuestionDoesNotRequireTranslationEvenWhenInferenceIsPaused() async throws {
        let runtime = Prompt1BQueryTranslationRuntime()
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(),
            languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
        let answer = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [],
            trackerContext: nil, userContext: nil, inputLanguage: .english, translationInferenceAllowed: false, progress: nil)
        XCTAssertFalse(answer.sourceIDs.isEmpty)
        let tags = await runtime.targetTags
        XCTAssertTrue(tags.isEmpty)
    }

    private func oversizedSelectedContext() throws -> FruitfolioAskUserContext {
        var record = FruitfolioHormoneMeasurement()
        record.result = "12.50"; record.unit = "pg/mL"
        record.notes = String(repeating: "x", count: 7_000)
        return try XCTUnwrap(FruitfolioAskUserContext.captureSelected(measurementIDs: [record.id],
            personalCategories: [], measurements: [record], context: .unspecified))
    }

    func testOversizedOptionalContextCannotPreemptOriginalOrTranslatedUrgentGuidance() async throws {
        let context = try oversizedSelectedContext()
        XCTAssertThrowsError(try context.promptJSON())
        for (question, language) in [("severe bleeding", FruitfolioLanguage.english),
                                     ("saignements abondants", .french)] {
            let runtime = Prompt1BQueryTranslationRuntime(result: "heavy bleeding")
            let missing = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"))
            let engine = FruitfolioResearchIntelligenceEngine(packageStore: missing,
                languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
            let answer = try await engine.answer(question: question, conversation: [], trackerContext: nil,
                userContext: context, inputLanguage: language, translationInferenceAllowed: true, progress: nil)
            XCTAssertEqual(answer.answerPath, .localSafety)
            XCTAssertEqual(answer.originalQuestion, question)
            XCTAssertTrue(answer.sourceIDs.isEmpty)
            XCTAssertFalse(answer.answerText.contains("untrusted"))
            XCTAssertNil(engine.lastDiagnostics)
        }
    }

    func testNonurgentOversizedContextStillFailsBeforeMissingResearchCanLoad() async throws {
        let context = try oversizedSelectedContext()
        let missing = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: missing, languageModel: Prompt1BUnavailableSynthesis())
        do {
            _ = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [],
                trackerContext: nil, userContext: context, inputLanguage: .english,
                translationInferenceAllowed: true, progress: nil)
            XCTFail("Optional attachment limits remain enforced for normal research")
        } catch { XCTAssertTrue(error is FruitfolioAskUserContext.Failure) }
        XCTAssertNil(engine.lastDiagnostics)
    }

    func testOriginalUrgentQuestionBypassesTranslationAndMissingResearchResources() async throws {
        let runtime = Prompt1BQueryTranslationRuntime()
        let missing = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: missing,
            languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
        let answer = try await engine.answer(question: "severe bleeding", conversation: [], trackerContext: nil,
            userContext: nil, inputLanguage: .french, translationInferenceAllowed: false, progress: nil)
        XCTAssertEqual(answer.answerPath, .localSafety)
        let tags = await runtime.targetTags
        XCTAssertTrue(tags.isEmpty)
    }

    func testTranslatedUrgentQuestionRechecksSafetyBeforeResearchOrGeneration() async throws {
        let runtime = Prompt1BQueryTranslationRuntime(result: "heavy bleeding")
        let missing = FruitfolioResearchPackageStore(resourceURL: URL(fileURLWithPath: "/unavailable/research.json"))
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: missing,
            languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
        let original = "saignements abondants"
        let answer = try await engine.answer(question: original, conversation: [], trackerContext: nil,
            userContext: nil, inputLanguage: .french, translationInferenceAllowed: true, progress: nil)
        XCTAssertEqual(answer.answerPath, .localSafety)
        XCTAssertEqual(answer.originalQuestion, original)
        XCTAssertNil(engine.lastDiagnostics)
    }

    func testUnavailableQuestionTranslationDoesNotClaimTheResearchHasNoAnswer() async throws {
        for allowed in [false, true] {
            let runtime = Prompt1BQueryTranslationRuntime()
            let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(),
                languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
            do {
                _ = try await engine.answer(question: "question française", conversation: [], trackerContext: nil,
                    userContext: nil, inputLanguage: .french, translationInferenceAllowed: allowed, progress: nil)
                XCTFail("Missing/paused translation must not masquerade as an unsupported research answer")
            } catch {
                XCTAssertEqual(error as? FruitfolioTranslationError, allowed ? .resourcesMissing : .pausedForMemoryPressure)
            }
            XCTAssertNil(engine.lastDiagnostics)
        }
    }

    func testChangedScientificQuantityInQuestionTranslationIsRejectedBeforeResearch() async throws {
        let runtime = Prompt1BQueryTranslationRuntime(result: "progesterone 99 pg/mL")
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(),
            languageModel: Prompt1BUnavailableSynthesis(), translationService: .init(runtime: runtime))
        do {
            _ = try await engine.answer(question: "progestérone 12.50 pg/mL", conversation: [], trackerContext: nil,
                userContext: nil, inputLanguage: .french, translationInferenceAllowed: true, progress: nil)
            XCTFail("Changed laboratory result must not become a retrieval question")
        } catch { XCTAssertEqual(error as? FruitfolioTranslationError, .protectedContentChanged) }
        XCTAssertNil(engine.lastDiagnostics)
    }

    func testClearingSessionDiagnosticsReleasesQuestionClaimsWhileStaticResearchRemainsUsable() async throws {
        let engine = FruitfolioResearchIntelligenceEngine(packageStore: try store(), languageModel: Prompt1BUnavailableSynthesis())
        let first = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        XCTAssertNotNil(engine.lastDiagnostics)
        engine.clearSessionDiagnostics()
        XCTAssertNil(engine.lastDiagnostics)
        let second = try await engine.answer(question: "how does progesterone affect temperature?", conversation: [])
        XCTAssertEqual(first.sourceIDs, second.sourceIDs)
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

extension Prompt1BResearchEngineIntegrationTests {
    func testActualResearchEngineUsesExplicitCueInBothValidatedAndRetrievalFallbackPaths() async throws {
        let question = "I'm worried about how progesterone affects temperature"
        let packageStore = try store()
        let generatedEngine = FruitfolioResearchIntelligenceEngine(packageStore: packageStore,
            languageModel: Prompt1BSingleEvidenceSynthesis())
        let fallbackEngine = FruitfolioResearchIntelligenceEngine(packageStore: packageStore,
            languageModel: Prompt1BUnavailableSynthesis())
        for (engine, expectedPath) in [(generatedEngine, FruitfolioAnswerPath.generated),
                                      (fallbackEngine, FruitfolioAnswerPath.retrievalFallback)] {
            let answer = try await engine.answer(question: question, conversation: [])
            XCTAssertEqual(answer.originalQuestion, question)
            XCTAssertEqual(answer.answerPath, expectedPath, "scoped=\(FruitfolioConversationalPresentation.researchQuestion(question)); diagnostics=\(String(describing: engine.lastDiagnostics))")
            XCTAssertTrue(answer.answerText.hasPrefix("we can take this one step at a time."))
            XCTAssertFalse(answer.sourceIDs.isEmpty)
            XCTAssertEqual(Set(answer.sources.map(\.id)), Set(answer.sourceIDs))
            XCTAssertFalse(answer.answerText.contains("you are worried"))
            XCTAssertFalse(answer.answerText.contains("you will be fine"))
        }
    }
}
