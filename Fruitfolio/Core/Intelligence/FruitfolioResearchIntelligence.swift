import Foundation
#if canImport(llama)
import llama
#endif

// MARK: - Prompt 56 canonical local research architecture

// MARK: - Package loading

actor FruitfolioResearchPackageStore {
    nonisolated static let shared =
        FruitfolioResearchPackageStore()

    private var cached:
        FruitfolioResearchPackage?

    private let resourceURL: URL?

    init(resourceURL: URL? = nil) { self.resourceURL = resourceURL }

    private var cachedRetriever: FruitfolioLocalResearchRetriever?
    private var indexedLocale: String?

    func retriever() throws -> FruitfolioLocalResearchRetriever {
        let locale = Locale.current.identifier
        if let cachedRetriever, indexedLocale == locale { return cachedRetriever }
        try Task.checkCancellation()
        let indexed = FruitfolioLocalResearchRetriever(package: try load())
        cachedRetriever = indexed
        indexedLocale = locale
        try Task.checkCancellation()
        return indexed
    }

    func searchNotes(question: String) throws -> [FruitfolioRankedNote] {
        try Task.checkCancellation()
        let result = try retriever().searchNotes(question: question)
        try Task.checkCancellation()
        return result
    }

    func searchSources(question: String, approvedSourceIDs: Set<String>) throws -> [FruitfolioRankedSourceChunk] {
        try Task.checkCancellation()
        let result = try retriever().searchSources(question: question, approvedSourceIDs: approvedSourceIDs)
        try Task.checkCancellation()
        return result
    }

    func load() throws
        -> FruitfolioResearchPackage
    {
        if let cached {
            return cached
        }

        guard
            let url = resourceURL ?? Bundle.main.url(
                forResource:
                    "FruitfolioResearchPackage",
                withExtension: "json"
            )
        else {
            throw FruitfolioResearchIntelligenceError
                .researchPackageMissing
        }

        let data = try Data(
            contentsOf: url,
            options: [.mappedIfSafe]
        )

        let decoded =
            try JSONDecoder().decode(
                FruitfolioResearchPackage.self,
                from: data
            )

        cached = decoded

        return decoded
    }
}

// MARK: - Language-model abstraction

nonisolated enum FruitfolioLanguageModelAvailability:
    Equatable,
    Sendable
{
    case available
    case runtimeNotSupported
    case modelResourceMissing
    case packageNotLinked
}

protocol FruitfolioLanguageModel:
    Sendable
{
    func availability() async
        -> FruitfolioLanguageModelAvailability

    func generateDraft(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) async throws -> FruitfolioGeneratedDraft
}

nonisolated enum FruitfolioLanguageModelError:
    LocalizedError,
    Sendable
{
    case unavailable(
        FruitfolioLanguageModelAvailability
    )

    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return
                "Fruitfolio's local language model is unavailable on this device."

        case .emptyResponse:
            return
                "Fruitfolio's local model returned an empty response."
        }
    }
}

#if canImport(llama)
private enum FruitfolioLlamaError: Error {
    case couldNotLoadModel
    case couldNotCreateContext
    case couldNotCreateSampler
    case outputLimitReached
    case promptTooLong
    case decodeFailed
    case invalidOutput
}

nonisolated private func fruitfolioLlamaBatchClear(
    _ batch: inout llama_batch
) {
    batch.n_tokens = 0
}

nonisolated private func fruitfolioLlamaBatchAdd(
    _ batch: inout llama_batch,
    token: llama_token,
    position: llama_pos,
    logits: Bool
) throws {
    let index = Int(batch.n_tokens)
    guard let sequenceIDs = batch.seq_id[index] else {
        throw FruitfolioLlamaError.decodeFailed
    }
    batch.token[index] = token
    batch.pos[index] = position
    batch.n_seq_id[index] = 1
    sequenceIDs[0] = 0
    batch.logits[index] = logits ? 1 : 0
    batch.n_tokens += 1
}

actor LlamaFruitfolioLanguageModel:
    FruitfolioLanguageModel
{
    nonisolated static let shared =
        LlamaFruitfolioLanguageModel()

    private let resourceName =
        "FruitfolioAI"

    private let resourceExtension =
        "gguf"

    private let modelURLOverride: URL?
    init(modelURL: URL? = nil) { self.modelURLOverride = modelURL }
    private var resolvedModelURL: URL? {
        modelURLOverride ?? Bundle.main.url(forResource: resourceName, withExtension: resourceExtension)
    }

    private let contextSize: UInt32 = 4096
    private let maximumGeneratedTokens: Int32 = 256

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    private var backendInitialized = false

    deinit {
        if let context {
            llama_free(context)
        }

        if let model {
            llama_model_free(model)
        }

        // Backends are process-owned; another model actor may still be using them.
    }

    func availability() async
        -> FruitfolioLanguageModelAvailability
    {
        guard let modelURL = resolvedModelURL, FruitfolioGGUFResource.isReadableModel(at: modelURL) else {
            return .modelResourceMissing
        }

        return .available
    }

    func generateDraft(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) async throws -> FruitfolioGeneratedDraft {
        try Task.checkCancellation()
        if let userContext = evidence.userProvidedContext { _ = try userContext.promptJSON() }
        let currentAvailability = await availability()
        try Task.checkCancellation()

        guard currentAvailability == .available else {
            throw FruitfolioLanguageModelError
                .unavailable(currentAvailability)
        }

        try loadIfNeeded()
        try Task.checkCancellation()

        guard
            let context,
            let vocab
        else {
            throw FruitfolioLlamaError
                .couldNotCreateContext
        }

        llama_memory_clear(llama_get_memory(context), true)
        defer { llama_memory_clear(llama_get_memory(context), true) }
        let contextCapacity = Int(llama_n_ctx(context))
        guard let selection = try FruitfolioEvidenceBudget.fit(
            evidence: evidence, maximumPromptTokens: contextCapacity - Int(maximumGeneratedTokens) - 1,
            maximumOutputTokens: Int(maximumGeneratedTokens),
            promptTokenCount: { packet in
                try tokenize(qwenPrompt(FruitfolioEvidencePromptBuilder.selectionPrompt(question: question, evidence: packet)), vocab: vocab).count
            }, outputTokenCount: { json in try tokenize(json, vocab: vocab).count }) else {
            throw FruitfolioLlamaError.promptTooLong
        }
        let sampler = try makeSampler(vocab: vocab, evidence: selection.evidence, maximumClaims: selection.maximumClaims)
        defer { llama_sampler_free(sampler) }
        let prompt = qwenPrompt(FruitfolioEvidencePromptBuilder.selectionPrompt(question: question, evidence: selection.evidence, maximumClaims: selection.maximumClaims))
        let promptTokens = try tokenize(prompt, vocab: vocab)
        guard promptTokens.count + Int(maximumGeneratedTokens) < contextCapacity else {
            throw FruitfolioLlamaError.promptTooLong
        }

        var batch = llama_batch_init(
            Int32(max(contextCapacity, 512)),
            0,
            1
        )
        defer { llama_batch_free(batch) }

        fruitfolioLlamaBatchClear(&batch)

        for (index, token) in promptTokens.enumerated() {
            try fruitfolioLlamaBatchAdd(
                &batch,
                token: token,
                position: Int32(index),
                logits: index == promptTokens.count - 1
            )
        }

        guard llama_decode(context, batch) == 0 else {
            throw FruitfolioLlamaError.decodeFailed
        }

        var currentPosition = Int32(promptTokens.count)
        var generated = ""
        var reachedEnd = false
        var pendingUTF8: [CChar] = []

        for _ in 0..<maximumGeneratedTokens {
            try Task.checkCancellation()
            let token = llama_sampler_sample(
                sampler,
                context,
                batch.n_tokens - 1
            )

            if llama_vocab_is_eog(vocab, token) {
                reachedEnd = true
                break
            }

            pendingUTF8.append(
                contentsOf: tokenPiece(token, vocab: vocab)
            )

            if let valid = String(
                validatingUTF8: pendingUTF8 + [0]
            ) {
                generated += valid
                pendingUTF8.removeAll(keepingCapacity: true)
            }

            fruitfolioLlamaBatchClear(&batch)
            try fruitfolioLlamaBatchAdd(
                &batch,
                token: token,
                position: currentPosition,
                logits: true
            )

            currentPosition += 1

            guard llama_decode(context, batch) == 0 else {
                throw FruitfolioLlamaError.decodeFailed
            }
        }

        guard reachedEnd else { throw FruitfolioLlamaError.outputLimitReached }
        guard pendingUTF8.isEmpty else { throw FruitfolioLlamaError.invalidOutput }

        let cleaned = extractJSONObject(from: generated)

        guard !cleaned.isEmpty, let data = cleaned.data(using: .utf8) else {
            throw FruitfolioLlamaError.invalidOutput
        }
        let draft = try FruitfolioEvidenceSelectionDecoder.draft(from: data, evidence: selection.evidence,
                                                               maximumClaims: selection.maximumClaims)

        return draft
    }

    private func loadIfNeeded() throws {
        if
            model != nil,
            context != nil,
            vocab != nil
        {
            return
        }

        guard
            let modelURL = resolvedModelURL
        else {
            throw FruitfolioLanguageModelError
                .unavailable(.modelResourceMissing)
        }

        if !backendInitialized {
            FruitfolioLlamaBackend.initialize()
            backendInitialized = true
        }

        var modelParameters = llama_model_default_params()

        #if os(iOS) && !targetEnvironment(simulator)
        modelParameters.n_gpu_layers = 99
        #else
        modelParameters.n_gpu_layers = 0
        #endif

        guard
            let loadedModel = llama_model_load_from_file(
                modelURL.path,
                modelParameters
            )
        else {
            throw FruitfolioLlamaError.couldNotLoadModel
        }

        let processorCount = ProcessInfo.processInfo.processorCount
        let threadCount = max(1, min(6, processorCount - 2))

        var contextParameters = llama_context_default_params()
        contextParameters.n_ctx = contextSize
        contextParameters.n_batch = contextSize
        contextParameters.n_threads = Int32(threadCount)
        contextParameters.n_threads_batch = Int32(threadCount)

        guard
            let loadedContext = llama_init_from_model(
                loadedModel,
                contextParameters
            )
        else {
            llama_model_free(loadedModel)
            throw FruitfolioLlamaError.couldNotCreateContext
        }

        guard
            let loadedVocab = llama_model_get_vocab(loadedModel)
        else {
            llama_free(loadedContext)
            llama_model_free(loadedModel)
            throw FruitfolioLlamaError.couldNotCreateContext
        }

        model = loadedModel
        context = loadedContext
        vocab = loadedVocab
    }

    private func makeSampler(vocab: OpaquePointer, evidence: FruitfolioEvidencePacket, maximumClaims: Int) throws -> UnsafeMutablePointer<llama_sampler> {
        let grammar = try FruitfolioEvidenceDecodingGrammar.make(evidence: evidence, maximumClaims: maximumClaims)
        guard let chain = llama_sampler_chain_init(llama_sampler_chain_default_params()) else {
            throw FruitfolioLlamaError.couldNotCreateSampler
        }
        guard let grammarSampler = llama_sampler_init_grammar(vocab, grammar, "root") else {
            llama_sampler_free(chain)
            throw FruitfolioLlamaError.couldNotCreateSampler
        }
        llama_sampler_chain_add(chain, grammarSampler)
        llama_sampler_chain_add(chain, llama_sampler_init_temp(0.20))
        llama_sampler_chain_add(chain, llama_sampler_init_dist(42))
        return chain
    }

    private func qwenPrompt(
        _ evidencePrompt: String
    ) -> String {
        """
        <|im_start|>system
        You are the local Fruitfolio synthesis engine. Follow the supplied instructions exactly. Output only the requested JSON object and nothing before or after it.<|im_end|>
        <|im_start|>user
        \(evidencePrompt)<|im_end|>
        <|im_start|>assistant
        """
    }

    private func tokenize(
        _ text: String,
        vocab: OpaquePointer
    ) throws -> [llama_token] {
        let utf8Count = text.utf8.count

        let required = llama_tokenize(
            vocab,
            text,
            Int32(utf8Count),
            nil,
            0,
            true,
            true
        )

        guard required < 0 else {
            return []
        }

        let capacity = Int(-required)
        let buffer = UnsafeMutablePointer<llama_token>
            .allocate(capacity: capacity)
        defer { buffer.deallocate() }

        let count = llama_tokenize(
            vocab,
            text,
            Int32(utf8Count),
            buffer,
            Int32(capacity),
            true,
            true
        )

        guard count > 0 else {
            throw FruitfolioLlamaError.invalidOutput
        }

        return Array(
            UnsafeBufferPointer(
                start: buffer,
                count: Int(count)
            )
        )
    }

    private func tokenPiece(
        _ token: llama_token,
        vocab: OpaquePointer
    ) -> [CChar] {
        let initialCapacity = 16
        let firstBuffer = UnsafeMutablePointer<CChar>
            .allocate(capacity: initialCapacity)
        firstBuffer.initialize(
            repeating: 0,
            count: initialCapacity
        )
        defer { firstBuffer.deallocate() }

        let firstCount = llama_token_to_piece(
            vocab,
            token,
            firstBuffer,
            Int32(initialCapacity),
            0,
            false
        )

        if firstCount >= 0 {
            return Array(
                UnsafeBufferPointer(
                    start: firstBuffer,
                    count: Int(firstCount)
                )
            )
        }

        let required = Int(-firstCount)
        let secondBuffer = UnsafeMutablePointer<CChar>
            .allocate(capacity: required)
        secondBuffer.initialize(
            repeating: 0,
            count: required
        )
        defer { secondBuffer.deallocate() }

        let secondCount = llama_token_to_piece(
            vocab,
            token,
            secondBuffer,
            Int32(required),
            0,
            false
        )

        guard secondCount > 0 else {
            return []
        }

        return Array(
            UnsafeBufferPointer(
                start: secondBuffer,
                count: Int(secondCount)
            )
        )
    }

    private func extractJSONObject(
        from raw: String
    ) -> String {
        var text = raw.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if text.hasPrefix("```json") {
            text.removeFirst(7)
        } else if text.hasPrefix("```") {
            text.removeFirst(3)
        }

        if text.hasSuffix("```") {
            text.removeLast(3)
        }

        text = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            let first = text.firstIndex(of: "{"),
            let last = text.lastIndex(of: "}")
        else {
            return ""
        }

        return String(text[first...last])
    }
}

#else
actor LlamaFruitfolioLanguageModel: FruitfolioLanguageModel {
    nonisolated static let shared = LlamaFruitfolioLanguageModel()
    init() {}

    func availability() async -> FruitfolioLanguageModelAvailability {
        .packageNotLinked
    }

    func generateDraft(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) async throws -> FruitfolioGeneratedDraft {
        throw FruitfolioLanguageModelError.unavailable(.packageNotLinked)
    }
}
#endif

// MARK: - Research intelligence engine

nonisolated enum FruitfolioResearchIntelligenceError:
    LocalizedError,
    Sendable
{
    case emptyQuestion
    case researchPackageMissing
    case unsupported

    var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            return
                "Please enter a question."

        case .researchPackageMissing:
            return
                "Fruitfolio's local research package is unavailable."

        case .unsupported:
            return
                FruitfolioCanonicalAnswerVoice.unsupportedMessage
        }
    }
}

@MainActor
final class FruitfolioResearchIntelligenceEngine:
    AskContextualResearchServing
{
    static let shared =
        FruitfolioResearchIntelligenceEngine()

    private let packageStore:
        FruitfolioResearchPackageStore

    private let languageModel:
        any FruitfolioLanguageModel

    private(set) var lastDiagnostics:
        FruitfolioRetrievalDiagnostics?

    init(
        packageStore:
            FruitfolioResearchPackageStore?
            = nil,
        languageModel:
            (any FruitfolioLanguageModel)?
            = nil
    ) {
        self.packageStore =
            packageStore
            ?? FruitfolioResearchPackageStore.shared

        self.languageModel =
            languageModel
            ?? LlamaFruitfolioLanguageModel.shared
    }

    func answer(
        question: String,
        conversation: [AskMessage]
    ) async throws -> AskAnswer {
        try await answer(
            question: question,
            conversation: conversation,
            trackerContext: nil,
            progress: nil
        )
    }

    func answer(
        question: String,
        conversation: [AskMessage],
        trackerContext:
            FruitfolioBoundedTrackerContext?
    ) async throws -> AskAnswer {
        try await answer(
            question: question,
            conversation: conversation,
            trackerContext: trackerContext,
            progress: nil
        )
    }

    func answer(
        question: String,
        conversation: [AskMessage],
        trackerContext:
            FruitfolioBoundedTrackerContext?,
        progress:
            (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?
    ) async throws -> AskAnswer {
        try await answer(question: question, conversation: conversation, trackerContext: trackerContext,
                         userContext: nil, progress: progress)
    }

    func answer(question: String, conversation: [AskMessage], trackerContext: FruitfolioBoundedTrackerContext?,
        userContext: FruitfolioAskUserContext?, progress: (@MainActor @Sendable (FruitfolioResearchProgress) -> Void)?) async throws -> AskAnswer {
        if let userContext { _ = try userContext.promptJSON() }
        let trimmed =
            question.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            throw FruitfolioResearchIntelligenceError
                .emptyQuestion
        }

        let classified = Prompt34LocalSafetyRouter.classify(trimmed)
        let safety = userContext != nil && classified.level == .normal
            ? Prompt34SafetyClassification(level: .sensitive, matchedPatterns: ["explicit_user_provided_context"])
            : classified

        if safety.requiresUrgentGuidance {
            // A missing package/model must not delay the existing local urgent
            // guidance. No diagnosis or invented source attribution is added.
            return AskAnswer(originalQuestion: trimmed,
                answerText: Prompt34LocalSafetyRouter.urgentResponseText(), support: .partiallySupported,
                knowledgeBaseVersion: "local-safety-guidance-v1", answerPath: .localSafety)
        }

        if safety.level == .normal,
           FruitfolioLifeBridgeInformation.isOrganizationQuestion(trimmed),
           FruitfolioLifeBridgeInformation.load() == nil {
            return AskAnswer(
                originalQuestion: trimmed,
                answerText: "details not available in the approved library yet. open LifeBridge information for the founder-specified official websites. current organization-specific claims require reviewed snapshots from both LifeBridge and FruitsofLife.xo.",
                support: .genuinelyNovel, knowledgeBaseVersion: FruitfolioLifeBridgeInformation.awaitingStatus, answerPath: .unavailableContent)
        }

        let normalized =
            FruitfolioQueryNormalizer.normalize(
                trimmed + " " + (userContext?.topicHints.joined(separator: " ") ?? "")
            )

        let claims =
            FruitfolioQuestionDecomposer.claims(
                from: normalized
            )

        progress?(.lookingThroughLibrary)
        // Only static approved-library indexes are cached; no question or
        // conversation is retained. Tokenization and ranking run on the actor,
        // leaving the main actor available for typing, scrolling and controls.
        let retriever = try await packageStore.retriever()
        let package = retriever.package
        let rankedNotes = try await packageStore.searchNotes(question: normalized)

        var coverage =
            retriever.coverage(
                claims: claims,
                notes: rankedNotes
            )

        var rankedSources:
            [FruitfolioRankedSourceChunk]
            = []

        var expanded = false

        if !coverage.isSufficient {
            expanded = true
            progress?(.searchingApprovedSources)

            let sourceIDs = Set(
                rankedNotes.flatMap {
                    $0.chunk.sourceIDs
                }
            )

            rankedSources =
                try await packageStore.searchSources(
                    question: normalized,
                    approvedSourceIDs:
                        sourceIDs
                )

            coverage =
                retriever.coverage(
                    claims: claims,
                    notes: rankedNotes,
                    sourceChunks:
                        rankedSources
                )
        }

        lastDiagnostics =
            FruitfolioRetrievalDiagnostics(
                noteCount:
                    rankedNotes.count,
                sourceChunkCount:
                    rankedSources.count,
                didExpandSources:
                    expanded,
                coverage:
                    coverage
            )

        guard
            coverage.hasAnySupport,
            !rankedNotes.isEmpty
        else {
            return unsupportedAnswer(
                question: trimmed,
                packageVersion:
                    package.contentVersion
            )
        }

        let noteChunks =
            deduplicateNotes(retriever.contextualizedNotes(rankedNotes))

        let sourceChunks =
            deduplicateSources(
                rankedSources.map {
                    $0.chunk
                }
            )

        let sourceIDSet = Set(
            noteChunks.flatMap {
                $0.sourceIDs
            }
            + sourceChunks.map {
                $0.sourceID
            }
        )

        let approvedSources =
            package.sources.filter {
                sourceIDSet.contains(
                    $0.sourceID
                )
                && $0.isApprovedForDisplay
            }

        let claimMap =
            claims.map {
                claim in

                let noteIDs =
                    noteChunks
                        .filter {
                            overlaps(
                                claim.text,
                                $0.text
                            )
                        }
                        .map {
                            $0.chunkID
                        }

                let sourceIDs =
                    sourceChunks
                        .filter {
                            overlaps(
                                claim.text,
                                $0.text
                            )
                        }
                        .map {
                            $0.sourceChunkID
                        }

                return FruitfolioClaimEvidence(
                    claim: claim,
                    noteChunkIDs: noteIDs,
                    sourceChunkIDs:
                        sourceIDs
                )
            }

        let packet =
            FruitfolioEvidencePacket(
                normalizedQuestion:
                    normalized,
                researchNoteChunks:
                    Array(
                        noteChunks.prefix(8)
                    ),
                sourceChunks:
                    Array(
                        sourceChunks.prefix(6)
                    ),
                claimEvidenceMap:
                    claimMap,
                sourceRecords:
                    approvedSources,
                safetyClassification:
                    safety,
                permittedContext:
                    trackerContext,
                contentVersion:
                    package.contentVersion,
                userProvidedContext: userContext
            )

        let answerText: String
        let answerPath: FruitfolioAnswerPath
        let usedEvidenceIDs: Set<String>

        do {
            progress?(.synthesizing)

            let draft =
                try await languageModel.generateDraft(
                    question: trimmed,
                    evidence: packet
                )

            progress?(.validating)

            if let validated = FruitfolioGeneratedDraftValidator.validatedAnswer(draft: draft, evidence: packet) {
                answerText = validated.text
                usedEvidenceIDs = validated.usedEvidenceIDs
                answerPath = .generated
            } else {
                answerText = retrievalOnlyAnswer(question: trimmed, coverage: coverage,
                    notes: packet.researchNoteChunks, safety: safety)
                answerPath = .retrievalFallback
                usedEvidenceIDs = Set(packet.researchNoteChunks.prefix(3).map(\.chunkID))
            }

        } catch {
            if Task.isCancelled || error is CancellationError { throw CancellationError() }
            answerPath = .retrievalFallback
            usedEvidenceIDs = Set(packet.researchNoteChunks.prefix(3).map(\.chunkID))
            answerText =
                retrievalOnlyAnswer(
                    question: trimmed,
                    coverage: coverage,
                    notes:
                        packet.researchNoteChunks,
                    safety: safety
                )
        }

        let displayedSourceIDs = Set(packet.researchNoteChunks.filter { usedEvidenceIDs.contains($0.chunkID) }.flatMap(\.sourceIDs)
            + packet.sourceChunks.filter { usedEvidenceIDs.contains($0.sourceChunkID) }.map(\.sourceID))
        let sources =
            approvedSources.filter { displayedSourceIDs.contains($0.sourceID) }.map {
                source in

                AskSourceRecord(
                    id: source.sourceID,
                    title:
                        source.apa7Reference
                        ?? source.title,
                    sourceText:
                        source.apa7Reference,
                    urlString:
                        source.canonicalURL,
                    doi:
                        source.doi,
                    publicationData:
                        source.publicationDate,
                    contentVersion:
                        source.contentVersion
                )
            }

        let support:
            AskKnowledgeSupport =
                coverage.isSufficient
                ? .supported
                : .partiallySupported

        let supportMap =
            coverage.requestedClaims.map {
                claim in

                let state:
                    AskKnowledgeSupport

                if coverage.supportedClaims
                    .contains(claim)
                {
                    state = .supported

                } else if coverage
                    .partiallySupportedClaims
                    .contains(claim)
                {
                    state =
                        .partiallySupported

                } else {
                    state =
                        .genuinelyNovel
                }

                return AskSupportMapEntry(
                    concept: claim.text,
                    support: state
                )
            }

        let conceptTags = Set(
            noteChunks
                .prefix(4)
                .flatMap {
                    FruitfolioQueryNormalizer
                        .tokens(
                            $0.heading
                        )
                }
        )

        let researchGap:
            AskResearchGap?

        if coverage.unsupportedClaims.isEmpty {
            researchGap = nil
        } else {
            researchGap = makeGap(
                question: trimmed,
                coverage: coverage,
                notes: noteChunks
            )
        }

        return AskAnswer(
            originalQuestion:
                trimmed,
            answerText:
                answerText,
            support:
                support,
            supportMap:
                supportMap,
            sourceIDs:
                sources.map {
                    $0.id
                },
            sources:
                sources,
            knowledgeBaseVersion:
                package.contentVersion,
            conceptTags:
                conceptTags,
            researchGap:
                researchGap,
            isDevelopmentPreview:
                false,
            answerPath: answerPath
        )
    }

    private func unsupportedAnswer(
        question: String,
        packageVersion: String
    ) -> AskAnswer {
        AskAnswer(
            originalQuestion:
                question,
            answerText:
                FruitfolioCanonicalAnswerVoice.unsupportedMessage,
            support:
                .genuinelyNovel,
            supportMap:
                [],
            sourceIDs:
                [],
            sources:
                [],
            knowledgeBaseVersion:
                packageVersion,
            conceptTags:
                [],
            researchGap:
                nil,
            isDevelopmentPreview:
                false,
            answerPath: .unsupported
        )
    }

    private func retrievalOnlyAnswer(
        question: String,
        coverage:
            FruitfolioEvidenceCoverage,
        notes:
            [FruitfolioResearchNoteChunk],
        safety:
            Prompt34SafetyClassification
    ) -> String {
        // Context has already been restored from the original paragraph table.
        // Do not clip at a character limit and accidentally remove a qualifier.
        let excerpts = notes.prefix(3).map { FruitfolioSemanticMarkup.markdown([.init(text: $0.text)]) }.filter { !$0.isEmpty }
        return FruitfolioCanonicalAnswerVoice.compose(excerpts: excerpts,
            hasUnansweredParts: !coverage.unsupportedClaims.isEmpty || !coverage.partiallySupportedClaims.isEmpty,
            safety: safety)
    }

    private func deduplicateNotes(
        _ input:
            [FruitfolioResearchNoteChunk]
    ) -> [FruitfolioResearchNoteChunk] {
        var seen =
            Set<String>()

        return input.filter {
            seen.insert(
                $0.chunkID
            )
            .inserted
        }
    }

    private func deduplicateSources(
        _ input:
            [FruitfolioSourceChunk]
    ) -> [FruitfolioSourceChunk] {
        var seen =
            Set<String>()

        return input.filter {
            seen.insert(
                $0.sourceChunkID
            )
            .inserted
        }
    }

    private func overlaps(
        _ lhs: String,
        _ rhs: String
    ) -> Bool {
        let leftTokens =
            FruitfolioQueryNormalizer.tokens(
                lhs
            )

        let rightTokens =
            FruitfolioQueryNormalizer.tokens(
                rhs
            )

        return !leftTokens
            .intersection(
                rightTokens
            )
            .isEmpty
    }

    private func makeGap(
        question: String,
        coverage:
            FruitfolioEvidenceCoverage,
        notes:
            [FruitfolioResearchNoteChunk]
    ) -> AskResearchGap {
        AskResearchGap(
            id:
                "gap_\(abs(question.hashValue))",
            normalizedTopic:
                FruitfolioQueryNormalizer
                    .normalize(
                        question
                    ),
            originalQuestion:
                question,
            knownComponents:
                coverage
                    .supportedClaims
                    .map {
                        $0.text
                    },
            unknownComponent:
                coverage
                    .unsupportedClaims
                    .map {
                        $0.text
                    }
                    .joined(
                        separator: "; "
                    ),
            relatedExistingTopics:
                Array(
                    notes
                        .prefix(3)
                        .map {
                            $0.heading
                        }
                ),
            closestLibraryMatches:
                Array(
                    notes
                        .prefix(3)
                        .map {
                            $0.heading
                        }
                ),
            retrievalAttempts: [
                "founder-curated research notes",
                "approved local source library"
            ],
            detectedAt:
                Date()
        )
    }
}

// MARK: - Architecture audit

nonisolated enum Prompt56ArchitectureAudit {
    static let prohibitedExternalAIProviders = [
        "openai",
        "anthropic",
        "gemini",
        "pinecone"
    ]

    static let productionNetworkAIClients:
        [String]
        = []

    static var hasZeroMeteredAIClients:
        Bool
    {
        productionNetworkAIClients
            .isEmpty
    }
}
