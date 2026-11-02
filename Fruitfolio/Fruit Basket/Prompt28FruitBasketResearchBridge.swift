import Foundation

/// Prompt 28 consumes approved, already-retrieved educational records through this
/// narrow contract. It never falls back to web search or model memory.
protocol Prompt28ResearchProviding: Sendable {
    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question
}

enum Prompt28ResearchError: LocalizedError, Equatable, Sendable {
    case providerUnavailable
    case unsupportedTopic
    case topicExhausted
    case invalidQuestion
    case sourceValidationFailed

    var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "the approved FruitsofLife.xo research library is not connected to Fruit Basket in this build yet."
        case .unsupportedTopic:
            return "i don’t have enough approved research on that one in the FruitsofLife.xo library yet :,)"
        case .topicExhausted:
            return "you picked through this little patch for now. wanna try another topic?"
        case .invalidQuestion:
            return "that question could not be validated for a fair Fruit Basket round."
        case .sourceValidationFailed:
            return "the source trail for that question could not be verified."
        }
    }
}

/// Safe production default for the current Prompt 01–27A source tree.
/// Prompt 09 explicitly identifies its provider as a development layout preview,
/// so Prompt 28 refuses to turn that preview into medical/scientific game content.
struct Prompt28UnavailableResearchProvider: Prompt28ResearchProviding {
    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question {
        throw Prompt28ResearchError.providerUnavailable
    }
}

/// Adapter point for the later canonical Research Library/RAG implementation.
/// A real provider supplies a fully validated Prompt28Question only after retrieval,
/// source validation, catch-concept validation, and available-art validation.
struct Prompt28ResearchLibraryBridge: Prompt28ResearchProviding {
    typealias Resolver = @Sendable (
        _ topic: String,
        _ normalizedTopic: String,
        _ difficulty: Prompt28EducationalDifficulty,
        _ excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question

    private let resolver: Resolver

    init(resolver: @escaping Resolver) {
        self.resolver = resolver
    }

    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question {
        let candidate = try await resolver(topic, normalizedTopic, difficulty, excludingQuestionIDs)
        guard candidate.isPlayable else { throw Prompt28ResearchError.invalidQuestion }
        guard !candidate.sourceIDs.isEmpty else { throw Prompt28ResearchError.sourceValidationFailed }
        return candidate
    }
}

/// Research-first, deterministic reading-comprehension fallback. Distractors are
/// individual words, never invented medical statements. The complete original
/// passage is the explanation; its qualifiers and source versions are immutable.
actor Prompt28CanonicalResearchProvider: Prompt28ResearchProviding {
    private let packages: FruitfolioResearchPackageStore

    init(packages: FruitfolioResearchPackageStore = .shared) { self.packages = packages }

    func question(topic: String, normalizedTopic: String,
                  difficulty: Prompt28EducationalDifficulty,
                  excludingQuestionIDs: Set<String>) async throws -> Prompt28Question {
        let package = try await packages.load()
        let retriever = try await packages.retriever()
        let query = FruitfolioQueryNormalizer.normalize(topic)
        guard !FruitfolioQueryNormalizer.tokens(query).isEmpty else {
            throw Prompt28ResearchError.unsupportedTopic
        }
        let approved = Dictionary(uniqueKeysWithValues: package.sources.filter(\.isApprovedForDisplay).map { ($0.sourceID, $0) })
        let notes = retriever.searchNotes(question: query, limit: package.researchNoteChunks.count)
        var encounteredPlayable = false
        for ranked in notes {
            try Task.checkCancellation()
            let note = ranked.chunk
            guard !note.sourceIDs.isEmpty, Set(note.sourceIDs).count == note.sourceIDs.count,
                  note.sourceIDs.allSatisfy({ approved[$0] != nil }) else { continue }
            let sources = note.sourceIDs.compactMap { approved[$0] }
            if let candidate = makeQuestion(id: note.chunkID, text: note.text, topic: topic,
                normalizedTopic: normalizedTopic, difficulty: difficulty, package: package,
                sources: sources, note: note, source: nil) {
                encounteredPlayable = true
                if !excludingQuestionIDs.contains(candidate.id) { return candidate }
            }
        }
        // Only actual, approved, locally available source material can expand
        // retrieval. A bibliography label is never treated as source content.
        let associated = Set(notes.flatMap { $0.chunk.sourceIDs }).intersection(Set(approved.keys))
        let sourceCandidates = retriever.searchSources(question: query, approvedSourceIDs: associated,
                                                       limit: package.sourceChunks.count)
        for ranked in sourceCandidates {
            try Task.checkCancellation()
            let chunk = ranked.chunk
            guard let source = approved[chunk.sourceID] else { continue }
            if let candidate = makeQuestion(id: chunk.sourceChunkID, text: chunk.text, topic: topic,
                normalizedTopic: normalizedTopic, difficulty: difficulty, package: package,
                sources: [source], note: nil, source: chunk) {
                encounteredPlayable = true
                if !excludingQuestionIDs.contains(candidate.id) { return candidate }
            }
        }
        throw encounteredPlayable ? Prompt28ResearchError.topicExhausted : Prompt28ResearchError.unsupportedTopic
    }

    private func makeQuestion(id: String, text: String, topic: String, normalizedTopic: String,
                              difficulty: Prompt28EducationalDifficulty, package: FruitfolioResearchPackage,
                              sources: [FruitfolioResearchSource], note: FruitfolioResearchNoteChunk?,
                              source: FruitfolioSourceChunk?) -> Prompt28Question? {
        guard text.count >= 40, text.count <= 1800,
              Prompt34LocalSafetyRouter.classify(text).level != .urgent,
              !["♡", ":-)", ":,)", "^_", "☆", "<3"].contains(where: text.contains) else { return nil }
        let claim = FruitfolioClaimNeed(id: "fruitbasket:\(id)", text: topic)
        let packet = FruitfolioEvidencePacket(normalizedQuestion: topic,
            researchNoteChunks: note.map { [$0] } ?? [], sourceChunks: source.map { [$0] } ?? [],
            claimEvidenceMap: [.init(claim: claim, noteChunkIDs: note.map { [$0.chunkID] } ?? [],
                                    sourceChunkIDs: source.map { [$0.sourceChunkID] } ?? [])],
            sourceRecords: sources, safetyClassification: Prompt34LocalSafetyRouter.classify(text),
            permittedContext: nil, contentVersion: package.contentVersion)
        let draft = FruitfolioGeneratedDraft(bridge: nil, claims: [.init(text: text, evidenceIDs: [id])], limitation: nil)
        guard let validated = FruitfolioGeneratedDraftValidator.validatedDraft(draft: draft, evidence: packet),
              validated.evidenceIDs == [id] else { return nil }
        let regex = try! NSRegularExpression(pattern: "\\b[A-Za-z]{4,}\\b")
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))
        let excluded: Set<String> = ["that", "this", "these", "those", "with", "from", "into", "have", "been", "were", "will", "would", "could", "should", "does", "only", "never", "without", "their", "there", "some", "more", "less", "than", "when", "what", "which", "your", "they", "also", "about", "other"]
        var seen: Set<String> = []
        let words = matches.compactMap { match -> (String, NSRange)? in
            guard let range = Range(match.range, in: text) else { return nil }
            let word = String(text[range]); let key = word.lowercased()
            guard !excluded.contains(key), seen.insert(key).inserted else { return nil }
            return (word, match.range)
        }
        let queryWords = FruitfolioQueryNormalizer.tokens(topic)
        guard let chosen = words.first(where: { queryWords.contains($0.0.lowercased()) }),
              let chosenRange = Range(chosen.1, in: text) else { return nil }
        let count = difficulty == .easy ? 2 : (difficulty == .medium ? 3 : 4)
        let alternatives = words.filter { $0.0.lowercased() != chosen.0.lowercased() }.prefix(count - 1)
        guard alternatives.count == count - 1 else { return nil }
        var options = [Prompt28AnswerOption(id: "original", text: chosen.0)]
        options += alternatives.enumerated().map { .init(id: "word-\($0.offset)", text: $0.element.0) }
        // Stable rotation avoids teaching that the first button is always right.
        let offset = id.utf8.reduce(0) { ($0 + Int($1)) % options.count }
        options = Array(options[offset...]) + Array(options[..<offset])
        let passage = text.replacingCharacters(in: chosenRange, with: "_____" )
        var question = Prompt28Question(id: "grounded:\(package.contentVersion):\(id):\(difficulty.rawValue)",
            topicQuery: topic, normalizedTopic: normalizedTopic, category: normalizedTopic,
            educationalDifficulty: difficulty,
            questionText: "which word fills the blank in this research-library passage?\n\n\(passage)",
            answerOptions: options, correctAnswerID: "original", explanation: text,
            sourceIDs: sources.map(\.sourceID), sourceTitles: sources.compactMap(\.apa7Reference),
            catchConceptID: "starred-fruit", catchRule: "catch 10 starred fruits. no star? let it pass.",
            goodFruitIDs: Array(Prompt28FruitID.allCases.prefix(5)),
            badFruitIDs: Array(Prompt28FruitID.allCases.suffix(5)), contentVersion: package.contentVersion,
            reviewStatus: "verbatim-evidence-validated-reading-comprehension", createdAt: Date())
        question.evidenceSnapshot = .init(evidenceID: id, originalPassage: text,
            packageVersion: package.contentVersion, sources: sources)
        return question.isPlayable ? question : nil
    }
}
