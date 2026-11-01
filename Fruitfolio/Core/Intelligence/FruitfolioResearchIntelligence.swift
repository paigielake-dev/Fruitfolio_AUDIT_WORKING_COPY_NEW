import Foundation
#if canImport(llama)
import llama
#endif

// MARK: - Prompt 56 canonical local research architecture

nonisolated enum FruitfolioSourceVerificationStatus:
    String,
    Codable,
    Sendable
{
    case founderCorpusAPA7
    case verified
    case unresolved
    case conflicted
}

nonisolated struct FruitfolioResearchNoteChunk:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let chunkID: String
    let researchTopicID: String
    let heading: String
    let subheading: String?
    let text: String
    let sourceIDs: [String]
    let semanticTags: [String]
    let domainTags: [String]

    var id: String {
        chunkID
    }
}

nonisolated struct FruitfolioResearchSource:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let sourceID: String
    let title: String
    let authors: String?
    let organization: String?
    let publicationDate: String?
    let publicationType: String?
    let canonicalURL: String?
    let doi: String?
    let apa7Reference: String?
    let verificationStatus: String
    let retrievalEligibility: Bool
    let sourceVersion: String
    let verifiedAt: String?
    let contentVersion: String

    var id: String {
        sourceID
    }

    var isApprovedForDisplay: Bool {
        retrievalEligibility
            && (
                verificationStatus
                    == FruitfolioSourceVerificationStatus
                        .founderCorpusAPA7
                        .rawValue
                || verificationStatus
                    == FruitfolioSourceVerificationStatus
                        .verified
                        .rawValue
            )
            && !(
                apa7Reference?
                    .trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )
                    .isEmpty
                ?? true
            )
    }
}

nonisolated struct FruitfolioSourceChunk:
    Codable,
    Hashable,
    Identifiable,
    Sendable
{
    let sourceChunkID: String
    let sourceID: String
    let section: String?
    let text: String
    let locationMetadata: String?
    let claimCategories: [String]

    var id: String {
        sourceChunkID
    }
}

nonisolated struct FruitfolioResearchPackage:
    Codable,
    Sendable
{
    let schemaVersion: Int
    let contentVersion: String
    let generatedFrom: String
    let generationNote: String
    let researchNoteChunks: [FruitfolioResearchNoteChunk]
    let sources: [FruitfolioResearchSource]
    let sourceChunks: [FruitfolioSourceChunk]
}

nonisolated struct FruitfolioClaimNeed:
    Hashable,
    Codable,
    Sendable
{
    let id: String
    let text: String
}

nonisolated struct FruitfolioRankedNote:
    Hashable,
    Sendable
{
    let chunk: FruitfolioResearchNoteChunk
    let score: Double
}

nonisolated struct FruitfolioRankedSourceChunk:
    Hashable,
    Sendable
{
    let chunk: FruitfolioSourceChunk
    let score: Double
}

nonisolated struct FruitfolioEvidenceCoverage:
    Hashable,
    Sendable
{
    let requestedClaims: [FruitfolioClaimNeed]
    let supportedClaims: [FruitfolioClaimNeed]
    let partiallySupportedClaims: [FruitfolioClaimNeed]
    let unsupportedClaims: [FruitfolioClaimNeed]

    var isSufficient: Bool {
        unsupportedClaims.isEmpty
            && partiallySupportedClaims.isEmpty
    }

    var hasAnySupport: Bool {
        !supportedClaims.isEmpty
            || !partiallySupportedClaims.isEmpty
    }
}

nonisolated struct FruitfolioClaimEvidence:
    Hashable,
    Sendable
{
    let claim: FruitfolioClaimNeed
    let noteChunkIDs: [String]
    let sourceChunkIDs: [String]
}

nonisolated struct FruitfolioEvidencePacket:
    Sendable
{
    let normalizedQuestion: String
    let researchNoteChunks: [FruitfolioResearchNoteChunk]
    let sourceChunks: [FruitfolioSourceChunk]
    let claimEvidenceMap: [FruitfolioClaimEvidence]
    let sourceRecords: [FruitfolioResearchSource]
    let safetyClassification: Prompt34SafetyClassification
    let permittedContext: FruitfolioBoundedTrackerContext?
    let contentVersion: String
}

/// The local model never gets to hand arbitrary prose directly to the UI.
/// It must return a small evidence-linked draft that deterministic code can
/// validate before rendering. This keeps the model downstream of Research.
nonisolated struct FruitfolioGeneratedClaim:
    Codable,
    Hashable,
    Sendable
{
    let text: String
    let evidenceIDs: [String]
}

nonisolated struct FruitfolioGeneratedDraft:
    Codable,
    Hashable,
    Sendable
{
    let bridge: String?
    let claims: [FruitfolioGeneratedClaim]
    let limitation: String?
}

nonisolated enum FruitfolioResearchProgress:
    Sendable
{
    case lookingThroughLibrary
    case searchingApprovedSources
    case synthesizing
    case validating
}

nonisolated struct FruitfolioRetrievalDiagnostics:
    Sendable
{
    let noteCount: Int
    let sourceChunkCount: Int
    let didExpandSources: Bool
    let coverage: FruitfolioEvidenceCoverage
}

nonisolated struct FruitfolioBoundedTrackerContext:
    Codable,
    Hashable,
    Sendable
{
    let predictionConfidence: String?
    let reasonCode: String?
    let trackingGoal: String?
    let reproductiveStage: String?
    let cycleHealthContext: String?

    static let none = FruitfolioBoundedTrackerContext(
        predictionConfidence: nil,
        reasonCode: nil,
        trackingGoal: nil,
        reproductiveStage: nil,
        cycleHealthContext: nil
    )
}


nonisolated enum FruitfolioAnswerPresentationSanitizer {
    /// Research-note compilation occasionally removes a space after punctuation.
    /// Repair only obvious prose joins; do not rewrite scientific content, URLs,
    /// abbreviations such as e.g., or numeric notation.
    static func clean(_ raw: String) -> String {
        var value = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let patterns: [(String, String)] = [
            (#"(?<=[A-Za-z]{3})\.(?=[A-Za-z])"#, ". "),
            (#",(?=[A-Za-z])"#, ", "),
            (#";(?=[A-Za-z])"#, "; "),
            (#":(?=[A-Za-z])"#, ": ")
        ]

        for (pattern, replacement) in patterns {
            value = value.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }

        value = value.replacingOccurrences(
            of: #"[ \t]{2,}"#,
            with: " ",
            options: .regularExpression
        )

        return value
    }
}

// MARK: - Deterministic local retrieval

nonisolated enum FruitfolioQueryNormalizer {
    private static let synonymMap: [String: String] = [
        "period": "menstruation",
        "periods": "menstruation",
        "discharge": "cervical fluid",
        "mucus": "cervical fluid",
        "temp": "temperature",
        "temps": "temperature",
        "preggo": "pregnancy",
        "pcos": "polycystic ovary syndrome pcos",
        "endo": "endometriosis",
        "ttc": "trying to conceive ttc"
    ]

    static func normalize(
        _ question: String
    ) -> String {
        var value = question.folding(
            options: [
                .caseInsensitive,
                .diacriticInsensitive
            ],
            locale: .current
        )
        .lowercased()

        value = value.replacingOccurrences(
            of: "’",
            with: "'"
        )

        for (from, to) in synonymMap {
            value = value.replacingOccurrences(
                of: "\\b\(from)\\b",
                with: to,
                options: .regularExpression
            )
        }

        return value
            .replacingOccurrences(
                of: "[^a-z0-9' ]",
                with: " ",
                options: .regularExpression
            )
            .replacingOccurrences(
                of: "\\s+",
                with: " ",
                options: .regularExpression
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    static func tokens(
        _ text: String
    ) -> Set<String> {
        let stop: Set<String> = [
            "a",
            "an",
            "and",
            "are",
            "as",
            "at",
            "be",
            "because",
            "can",
            "do",
            "does",
            "for",
            "from",
            "how",
            "i",
            "in",
            "is",
            "it",
            "me",
            "my",
            "of",
            "on",
            "or",
            "the",
            "this",
            "to",
            "what",
            "when",
            "why",
            "with",
            "you"
        ]

        return Set(
            normalize(text)
                .split(separator: " ")
                .map(String.init)
                .filter {
                    $0.count > 2
                        && !stop.contains($0)
                }
        )
    }
}

nonisolated enum FruitfolioQuestionDecomposer {
    static func claims(
        from normalizedQuestion: String
    ) -> [FruitfolioClaimNeed] {
        let pieces = normalizedQuestion
            .replacingOccurrences(
                of: "?",
                with: " and "
            )
            .components(
                separatedBy: " and "
            )
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        var seen = Set<String>()

        let unique = pieces.filter {
            seen.insert($0).inserted
        }

        return unique.enumerated().map {
            index,
            text in

            FruitfolioClaimNeed(
                id: "claim_\(index)",
                text: text
            )
        }
    }
}

nonisolated struct FruitfolioLocalResearchRetriever:
    Sendable
{
    let package: FruitfolioResearchPackage
    private let indexedNotes: [(chunk: FruitfolioResearchNoteChunk, heading: Set<String>, body: Set<String>)]
    private let indexedSources: [(chunk: FruitfolioSourceChunk, body: Set<String>)]

    init(package: FruitfolioResearchPackage) {
        self.package = package
        indexedNotes = package.researchNoteChunks.map { chunk in
            (chunk, FruitfolioQueryNormalizer.tokens(chunk.heading),
             chunk.semanticTags.isEmpty ? FruitfolioQueryNormalizer.tokens(chunk.text) : Set(chunk.semanticTags))
        }
        let eligible = Set(package.sources.filter(\.isApprovedForDisplay).map(\.sourceID))
        indexedSources = package.sourceChunks.filter { eligible.contains($0.sourceID) }.map {
            ($0, FruitfolioQueryNormalizer.tokens($0.text))
        }
    }

    func searchNotes(
        question: String,
        limit: Int = 8
    ) -> [FruitfolioRankedNote] {
        let queryTokens =
            FruitfolioQueryNormalizer.tokens(
                question
            )

        guard !queryTokens.isEmpty else {
            return []
        }

        let normalizedQuestion = FruitfolioQueryNormalizer.normalize(question)
        return indexedNotes
            .compactMap {
                entry in
                let chunk = entry.chunk
                guard !Task.isCancelled else { return nil }

                let headingTokens = entry.heading
                let bodyTokens = entry.body

                let headingHits = Double(
                    queryTokens
                        .intersection(
                            headingTokens
                        )
                        .count
                )

                let bodyHits = Double(
                    queryTokens
                        .intersection(
                            bodyTokens
                        )
                        .count
                )

                let exactBonus =
                    chunk.text
                        .lowercased()
                        .contains(
                            normalizedQuestion
                        )
                    ? 3.0
                    : 0.0

                let score =
                    (headingHits * 3.0)
                    + bodyHits
                    + exactBonus

                guard score > 0 else {
                    return nil
                }

                return FruitfolioRankedNote(
                    chunk: chunk,
                    score: score
                )
            }
            .sorted {
                lhs,
                rhs in

                if lhs.score == rhs.score {
                    return lhs.chunk.chunkID
                        < rhs.chunk.chunkID
                }

                return lhs.score > rhs.score
            }
            .prefix(limit)
            .map {
                $0
            }
    }

    func searchSources(
        question: String,
        approvedSourceIDs: Set<String>,
        limit: Int = 6
    ) -> [FruitfolioRankedSourceChunk] {
        guard !package.sourceChunks.isEmpty else {
            return []
        }

        let queryTokens =
            FruitfolioQueryNormalizer.tokens(
                question
            )

        return indexedSources
            .compactMap {
                entry in
                let chunk = entry.chunk
                guard !Task.isCancelled else { return nil }

                guard approvedSourceIDs.isEmpty || approvedSourceIDs.contains(chunk.sourceID)
                else {
                    return nil
                }

                let bodyTokens = entry.body

                let score = Double(
                    queryTokens
                        .intersection(
                            bodyTokens
                        )
                        .count
                )

                guard score > 0 else {
                    return nil
                }

                return FruitfolioRankedSourceChunk(
                    chunk: chunk,
                    score: score
                )
            }
            .sorted {
                $0.score > $1.score
            }
            .prefix(limit)
            .map {
                $0
            }
    }

    func coverage(
        claims: [FruitfolioClaimNeed],
        notes: [FruitfolioRankedNote],
        sourceChunks: [FruitfolioRankedSourceChunk] = []
    ) -> FruitfolioEvidenceCoverage {
        var supported: [FruitfolioClaimNeed] = []
        var partial: [FruitfolioClaimNeed] = []
        var unsupported: [FruitfolioClaimNeed] = []

        let evidenceTexts =
            notes.map {
                $0.chunk.text
            }
            + sourceChunks.map {
                $0.chunk.text
            }

        let evidenceTokens = Set(
            evidenceTexts.flatMap {
                FruitfolioQueryNormalizer.tokens(
                    $0
                )
            }
        )

        for claim in claims {
            let needed =
                FruitfolioQueryNormalizer.tokens(
                    claim.text
                )

            guard !needed.isEmpty else {
                unsupported.append(claim)
                continue
            }

            let matchingCount =
                needed
                    .intersection(
                        evidenceTokens
                    )
                    .count

            let ratio =
                Double(matchingCount)
                / Double(
                    max(
                        needed.count,
                        1
                    )
                )

            if ratio >= 0.72 {
                supported.append(claim)

            } else if ratio >= 0.34 {
                partial.append(claim)

            } else {
                unsupported.append(claim)
            }
        }

        return FruitfolioEvidenceCoverage(
            requestedClaims: claims,
            supportedClaims: supported,
            partiallySupportedClaims: partial,
            unsupportedClaims: unsupported
        )
    }
}

// MARK: - Package loading

actor FruitfolioResearchPackageStore {
    nonisolated static let shared =
        FruitfolioResearchPackageStore()

    private var cached:
        FruitfolioResearchPackage?
    private var cachedRetriever: FruitfolioLocalResearchRetriever?

    func retriever() throws -> FruitfolioLocalResearchRetriever {
        if let cachedRetriever { return cachedRetriever }
        let value = FruitfolioLocalResearchRetriever(package: try load())
        cachedRetriever = value
        return value
    }

    func load() throws
        -> FruitfolioResearchPackage
    {
        if let cached {
            return cached
        }

        guard
            let url = Bundle.main.url(
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

nonisolated protocol FruitfolioLanguageModel:
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

    private let contextSize: UInt32 = 4096
    private let maximumGeneratedTokens: Int32 = 768

    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var backendInitialized = false

    deinit {
        if let sampler {
            llama_sampler_free(sampler)
        }

        if let context {
            llama_free(context)
        }

        if let model {
            llama_model_free(model)
        }

        if backendInitialized {
            llama_backend_free()
        }
    }

    func availability() async
        -> FruitfolioLanguageModelAvailability
    {
        guard Bundle.main.url(
            forResource: resourceName,
            withExtension: resourceExtension
        ) != nil else {
            return .modelResourceMissing
        }

        return .available
    }

    func generateDraft(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) async throws -> FruitfolioGeneratedDraft {
        let currentAvailability =
            await availability()

        guard currentAvailability == .available else {
            throw FruitfolioLanguageModelError
                .unavailable(currentAvailability)
        }

        try Task.checkCancellation()
        try loadIfNeeded()

        guard
            let context,
            let vocab,
            let sampler
        else {
            throw FruitfolioLlamaError
                .couldNotCreateContext
        }

        llama_memory_clear(
            llama_get_memory(context),
            true
        )
        defer { llama_memory_clear(llama_get_memory(context), true) }
        llama_sampler_reset(sampler)

        let evidencePrompt =
            FruitfolioEvidencePromptBuilder.prompt(
                question: question,
                evidence: evidence
            )

        let prompt = qwenPrompt(evidencePrompt)
        let promptTokens = try tokenize(prompt, vocab: vocab)

        let contextCapacity = Int(llama_n_ctx(context))
        guard
            promptTokens.count + Int(maximumGeneratedTokens)
                < contextCapacity
        else {
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
        var pendingUTF8: [CChar] = []

        for _ in 0..<maximumGeneratedTokens {
            try Task.checkCancellation()
            let token = llama_sampler_sample(
                sampler,
                context,
                batch.n_tokens - 1
            )

            if llama_vocab_is_eog(vocab, token) {
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

        if !pendingUTF8.isEmpty {
            generated += String(
                decoding: pendingUTF8.map { UInt8(bitPattern: $0) },
                as: UTF8.self
            )
        }

        let cleaned = extractJSONObject(from: generated)

        guard
            !cleaned.isEmpty,
            let data = cleaned.data(using: .utf8),
            let draft = try? JSONDecoder().decode(
                FruitfolioGeneratedDraft.self,
                from: data
            )
        else {
            throw FruitfolioLlamaError.invalidOutput
        }

        return draft
    }

    private func loadIfNeeded() throws {
        if
            model != nil,
            context != nil,
            vocab != nil,
            sampler != nil
        {
            return
        }

        guard
            let modelURL = Bundle.main.url(
                forResource: resourceName,
                withExtension: resourceExtension
            )
        else {
            throw FruitfolioLanguageModelError
                .unavailable(.modelResourceMissing)
        }

        if !backendInitialized {
            llama_backend_init()
            backendInitialized = true
        }

        var modelParameters = llama_model_default_params()

        #if targetEnvironment(simulator)
        modelParameters.n_gpu_layers = 0
        #else
        modelParameters.n_gpu_layers = 99
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

        let samplerParameters = llama_sampler_chain_default_params()

        guard
            let loadedSampler = llama_sampler_chain_init(
                samplerParameters
            )
        else {
            llama_free(loadedContext)
            llama_model_free(loadedModel)
            throw FruitfolioLlamaError.couldNotCreateContext
        }

        llama_sampler_chain_add(
            loadedSampler,
            llama_sampler_init_temp(0.20)
        )
        llama_sampler_chain_add(
            loadedSampler,
            llama_sampler_init_dist(42)
        )

        model = loadedModel
        context = loadedContext
        vocab = loadedVocab
        sampler = loadedSampler
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

nonisolated enum FruitfolioEvidencePromptBuilder {
    static func prompt(
        question: String,
        evidence: FruitfolioEvidencePacket
    ) -> String {
        let noteText =
            evidence
                .researchNoteChunks
                .prefix(6)
                .map {
                    """
                    [NOTE \($0.chunkID)]
                    \($0.text)
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        let sourceText =
            evidence
                .sourceChunks
                .prefix(4)
                .map {
                    """
                    [SOURCE \($0.sourceChunkID)]
                    \($0.text)
                    """
                }
                .joined(
                    separator: "\n\n"
                )

        let claimMapText = evidence.claimEvidenceMap
            .map { item in
                let ids = item.noteChunkIDs + item.sourceChunkIDs
                return "[CLAIM \(item.claim.id)] \(item.claim.text)\nPERMITTED EVIDENCE IDS: \(ids.joined(separator: ", "))"
            }
            .joined(separator: "\n\n")

        let trackerContext: String
        if let context = evidence.permittedContext {
            trackerContext = """
            predictionConfidence=\(context.predictionConfidence ?? "unknown")
            reasonCode=\(context.reasonCode ?? "unknown")
            trackingGoal=\(context.trackingGoal ?? "unknown")
            reproductiveStage=\(context.reproductiveStage ?? "unknown")
            cycleHealthContext=\(context.cycleHealthContext ?? "unknown")
            """
        } else {
            trackerContext = "[none supplied]"
        }

        let outputLanguage = FruitfolioLanguagePreferences.current.nativeDisplayName

        return """
        You are Fruitfolio's local synthesis layer. Write all user-facing bridge, claim, and limitation text in \(outputLanguage), while preserving the exact scientific meaning of the approved evidence and leaving evidence IDs unchanged. Use ONLY the supplied approved evidence for substantive health or scientific claims. Do not supplement from pretrained knowledge. Do not invent facts, user biology, diagnoses, citations, authors, dates, URLs, or study details. If evidence supports only part of the question, answer only that part and state the limitation. Keep recorded, calculated, estimated, predicted, educational, and user-reported information distinct. Symptoms are semantically underlined by the renderer; do not replace that rule with italics. Serious health content must be calm and non-playful.

        Return ONLY valid JSON matching this exact shape:
        {"bridge":"optional short human bridge or null","claims":[{"text":"one evidence-bounded claim","evidenceIDs":["NOTE_OR_SOURCE_ID"]}],"limitation":"optional honest limitation or null"}

        Every substantive claim MUST include one or more evidenceIDs copied exactly from the permitted evidence IDs below. Never create an evidence ID. If a requested part is unsupported, omit that claim and put the limitation in limitation. Do not include a Sources section; Fruitfolio renders verified sources deterministically.

        USER QUESTION:
        \(question)

        SAFETY CLASSIFICATION:
        \(evidence.safetyClassification.level.rawValue)

        PERMITTED BOUNDED TRACKER CONTEXT:
        \(trackerContext)

        CLAIM / EVIDENCE BOUNDARY:
        \(claimMapText)

        APPROVED RESEARCH NOTES:
        \(noteText)

        APPROVED SOURCE EXCERPTS:
        \(sourceText.isEmpty ? "[none supplied]" : sourceText)

        Each claim must quote one complete supplied evidence chunk verbatim,
        preserving every qualifier, numerical value and negation. Do not paraphrase
        or add medical facts. Use null for bridge and limitation. The app applies
        Canonical Voice after validation. Return the JSON fields only.
        """
    }
}

// MARK: - Deterministic generated-claim validation

nonisolated enum FruitfolioGeneratedDraftValidator {
    static func validatedText(
        draft: FruitfolioGeneratedDraft,
        evidence: FruitfolioEvidencePacket
    ) -> String? {
        let noteByID = Dictionary(
            uniqueKeysWithValues: evidence.researchNoteChunks.map { ($0.chunkID, $0.text) }
        )
        let sourceByID = Dictionary(
            uniqueKeysWithValues: evidence.sourceChunks.map { ($0.sourceChunkID, $0.text) }
        )

        let allowedByClaim = Dictionary(
            uniqueKeysWithValues: evidence.claimEvidenceMap.map {
                ($0.claim.id, Set($0.noteChunkIDs + $0.sourceChunkIDs))
            }
        )

        let supportedClaimTokens: [(Set<String>, Set<String>)] = evidence.claimEvidenceMap.map {
            (FruitfolioQueryNormalizer.tokens($0.claim.text), allowedByClaim[$0.claim.id] ?? [])
        }

        let surviving = draft.claims.compactMap { generated -> String? in
            let generatedTokens = FruitfolioQueryNormalizer.tokens(generated.text)
            guard !generatedTokens.isEmpty else { return nil }

            let cited = Set(generated.evidenceIDs)
            guard !cited.isEmpty else { return nil }

            let allIDsExist = cited.allSatisfy { noteByID[$0] != nil || sourceByID[$0] != nil }
            guard allIDsExist else { return nil }

            // A generated claim must correspond to a requested claim need and may
            // cite only evidence that retrieval already mapped to that need.
            let boundaryMatch = supportedClaimTokens.contains { needTokens, allowedIDs in
                !generatedTokens.intersection(needTokens).isEmpty
                    && cited.isSubset(of: allowedIDs)
            }
            guard boundaryMatch else { return nil }

            // Token overlap is not proof of medical entailment. Until a validated
            // entailment layer exists, accept only complete, verbatim evidence
            // chunks so qualifiers and negations cannot be silently dropped.
            let candidates = cited.compactMap { noteByID[$0] ?? sourceByID[$0] }
            guard let original = candidates.first(where: {
                canonicalWhitespace($0) == canonicalWhitespace(generated.text)
            }) else { return nil }
            return original.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard !surviving.isEmpty else { return nil }
        return surviving.map { "☆ \($0)" }.joined(separator: "\n\n")
    }

    private static func canonicalWhitespace(_ text: String) -> String {
        text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

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
                "i don’t have this one in the library yet."
        }
    }
}

@MainActor
final class FruitfolioResearchIntelligenceEngine:
    AskKnowledgeServing,
    AskResearchProgressServing
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
            ((FruitfolioResearchProgress) -> Void)?
    ) async throws -> AskAnswer {
        let trimmed =
            question.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmed.isEmpty else {
            throw FruitfolioResearchIntelligenceError
                .emptyQuestion
        }

        let safety =
            Prompt34LocalSafetyRouter.classify(
                trimmed
            )

        let normalized =
            FruitfolioQueryNormalizer.normalize(
                trimmed
            )

        let claims =
            FruitfolioQuestionDecomposer.claims(
                from: normalized
            )

        let package =
            try await packageStore.load()

        progress?(.lookingThroughLibrary)

        let retriever = try await packageStore.retriever()

        let noteSearch = Task.detached(priority: .userInitiated) {
            retriever.searchNotes(question: normalized)
        }
        let rankedNotes = await withTaskCancellationHandler {
            await noteSearch.value
        } onCancel: {
            noteSearch.cancel()
        }
        try Task.checkCancellation()

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

            let sourceSearch = Task.detached(priority: .userInitiated) {
                let matching = retriever.searchSources(question: normalized, approvedSourceIDs: sourceIDs)
                return matching.isEmpty
                    ? retriever.searchSources(question: normalized, approvedSourceIDs: [])
                    : matching
            }
            rankedSources = await withTaskCancellationHandler {
                await sourceSearch.value
            } onCancel: {
                sourceSearch.cancel()
            }
            try Task.checkCancellation()

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
            deduplicateNotes(
                rankedNotes.map {
                    $0.chunk
                }
            )

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
                    package.contentVersion
            )

        let answerText: String

        do {
            progress?(.synthesizing)

            let draft =
                try await languageModel.generateDraft(
                    question: trimmed,
                    evidence: packet
                )

            progress?(.validating)

            answerText =
                FruitfolioGeneratedDraftValidator.validatedText(
                    draft: draft,
                    evidence: packet
                )
                ?? retrievalOnlyAnswer(
                    question: trimmed,
                    coverage: coverage,
                    notes: packet.researchNoteChunks,
                    safety: safety
                )

        } catch {
            answerText =
                retrievalOnlyAnswer(
                    question: trimmed,
                    coverage: coverage,
                    notes:
                        packet.researchNoteChunks,
                    safety: safety
                )
        }

        let sources =
            approvedSources.map {
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
                false
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
                "i don’t have this one in the library yet.",
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
                false
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
        let excerpts =
            notes
                .prefix(3)
                .map {
                    chunk -> String in

                    let clean =
                        FruitfolioAnswerPresentationSanitizer.clean(
                            chunk.text
                        )

                    let offset =
                        min(
                            clean.count,
                            680
                        )

                    let limit =
                        clean.index(
                            clean.startIndex,
                            offsetBy: offset
                        )

                    let clipped =
                        String(
                            clean[..<limit]
                        )

                    let suffix =
                        clean.count > 680
                        ? "…"
                        : ""

                    return
                        "• \(clipped)\(suffix)"
                }

        var parts: [String] = []

        if safety.level != .normal {
            parts.append(
                "this deserves a quieter, more careful answer. if you may be in immediate danger or have severe symptoms, seek urgent medical care rather than relying on an educational app."
            )
        }

        let excerptText =
            excerpts.joined(
                separator: "\n\n"
            )

        if !excerptText.isEmpty {
            parts.append(
                excerptText
            )
        }

        if
            !coverage.unsupportedClaims.isEmpty
            || !coverage
                .partiallySupportedClaims
                .isEmpty
        {
            parts.append(
                "the local library does not fully support every part of that question yet, so Fruitfolio is leaving the unsupported part unanswered rather than filling it from model memory."
            )
        }

        return parts
            .filter {
                !$0.isEmpty
            }
            .joined(
                separator: "\n\n"
            )
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
