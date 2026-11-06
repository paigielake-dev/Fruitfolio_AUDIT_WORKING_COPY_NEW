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
    case urgentTopic
    case practiceUnavailable
    case unsupportedTopic
    case topicExhausted
    case invalidQuestion
    case sourceValidationFailed

    var errorDescription: String? {
        switch self {
        case .urgentTopic:
            return Prompt34LocalSafetyRouter.urgentResponseText()
        case .practiceUnavailable:
            return "there are eligible library excerpts for this topic, but this practice mode could not build a fair question at this vocabulary level. try another difficulty or explore the excerpts in Ask."
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

/// Explicit unavailable adapter for isolated integrations without a research package.
/// Production uses the bundled exact-excerpt provider below; no preview facts are used.
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

/// Offline exact-excerpt practice. It does not ask a model to invent medical
/// distractors or treat a fruit classification as a nutritional/clinical fact.
actor Prompt28BundledResearchProvider: Prompt28ResearchProviding {
    static let shared = Prompt28BundledResearchProvider()
    private let packageStore: FruitfolioResearchPackageStore
    init(packageStore: FruitfolioResearchPackageStore = .shared) { self.packageStore = packageStore }

    func question(topic: String, normalizedTopic: String, difficulty: Prompt28EducationalDifficulty,
                  excludingQuestionIDs: Set<String>) async throws -> Prompt28Question {
        try Task.checkCancellation()
        let safety = Prompt34LocalSafetyRouter.classify(topic)
        if safety.level == .urgent { throw Prompt28ResearchError.urgentTopic }
        guard !FruitfolioQueryNormalizer.tokens(normalizedTopic).isEmpty else { throw Prompt28ResearchError.unsupportedTopic }
        let retriever = try await packageStore.retriever()
        let package = retriever.package
        let records = package.sources.filter(\.isApprovedForDisplay)
        guard Set(records.map(\.sourceID)).count == records.count else { throw Prompt28ResearchError.sourceValidationFailed }
        let approved = Dictionary(uniqueKeysWithValues: records.map { ($0.sourceID, $0) })
        let ranked = retriever.searchNotes(question: normalizedTopic, limit: package.researchNoteChunks.count)
        let notes = retriever.contextualizedNotes(ranked)
        var seenParagraphs: Set<String> = []
        var hadValidQuestion = false
        var hadEligibleExcerpt = false
        for note in notes {
            try Task.checkCancellation()
            guard seenParagraphs.insert(note.text).inserted,
                  !note.sourceIDs.isEmpty, note.sourceIDs.allSatisfy({ approved[$0] != nil }),
                  FruitfolioEvidenceCopyPolicy.validatedPresentation(note.text, original: note.text) != nil
            else { continue }
            hadEligibleExcerpt = true
            let serious = safety.requiresSeriousTone || Prompt34LocalSafetyRouter.classify(note.text).requiresSeriousTone
            let sources = note.sourceIDs.compactMap { approved[$0] }.map {
                AskSourceRecord(id: $0.sourceID, title: $0.apa7Reference ?? $0.title, sourceText: $0.apa7Reference,
                    urlString: $0.canonicalURL, doi: $0.doi, publicationData: $0.publicationDate, contentVersion: $0.contentVersion)
            }
            for cloze in Prompt28SourceExcerptPractice.candidates(text: note.text, difficulty: difficulty) {
                let id = "source-excerpt:\(package.contentVersion):\(note.sourceParagraphID ?? note.chunkID):\(cloze.location):\(difficulty.rawValue)"
                hadValidQuestion = true
                guard !excludingQuestionIDs.contains(id) else { continue }
                let question = Prompt28Question(id: id, topicQuery: topic, normalizedTopic: normalizedTopic,
                    category: Prompt28ExcerptQuestionPresentation.category, educationalDifficulty: difficulty,
                    questionText: Prompt28ExcerptQuestionPresentation.prefix + cloze.text,
                    answerOptions: cloze.options, correctAnswerID: cloze.correctID,
                    explanation: FruitfolioSemanticMarkup.markdown([.init(text: "the omitted word is “\(cloze.originalWord)”.\n\noriginal library excerpt:\n\n" + note.text)]),
                    sourceIDs: sources.map(\.id), sourceTitles: sources.map(\.title),
                    catchConceptID: "visual-starred-fruit", catchRule: "catch starred fruit; let fruit without a star pass. standalone stars bank one star pass each. this is a visual game rule, not a medical or nutrition claim about the fruit.",
                    goodFruitIDs: [.strawberry, .blueberry, .orange, .apple, .pear],
                    badFruitIDs: [.grape, .peach, .watermelon, .plum, .lemon],
                    contentVersion: package.contentVersion, reviewStatus: "exact_founder_attributed_excerpt_not_independent_clinical_review",
                    createdAt: Date(), sourceRecords: sources, sourceExcerpt: note.text, seriousFeedback: serious)
                guard question.isPlayable else { throw Prompt28ResearchError.invalidQuestion }
                return question
            }
        }
        if hadValidQuestion { throw Prompt28ResearchError.topicExhausted }
        throw hadEligibleExcerpt ? Prompt28ResearchError.practiceUnavailable : Prompt28ResearchError.unsupportedTopic
    }
}

nonisolated enum Prompt28SourceExcerptPractice {
    struct Candidate: Sendable {
        let text: String
        let originalWord: String
        let location: Int
        let options: [Prompt28AnswerOption]
        let correctID: String
    }
    // Vocabulary bands describe excerpt practice, not validated clinical question depth.
    static func vocabulary(_ difficulty: Prompt28EducationalDifficulty) -> [String] {
        switch difficulty {
        case .easy: return ["blood", "body", "cycle", "egg", "food", "milk", "sleep", "water", "ovary", "uterus", "cells", "fruit", "iron", "fiber", "skin", "bone", "brain", "sperm"]
        case .medium: return ["hormone", "hormones", "estrogen", "insulin", "protein", "glucose", "follicle", "vitamin", "calcium", "placenta", "embryo", "oocyte", "cervix", "thyroid", "period", "ovaries", "fertility", "nutrition", "pregnancy", "surrogacy"]
        case .hard: return ["progesterone", "estradiol", "endometrium", "hypothalamus", "luteinizing", "testosterone", "prolactin", "gonadotropin", "implantation", "fertilization", "mitochondria", "endocrine", "metabolism", "chromosome", "chromosomes"]
        }
    }
    static func candidates(text: String, difficulty: Prompt28EducationalDifficulty) -> [Candidate] {
        let words = vocabulary(difficulty)
        let source = text as NSString
        return words.enumerated().compactMap { index, word in
            guard let regex = try? NSRegularExpression(pattern: "(?<![\\p{L}\\p{N}])" + NSRegularExpression.escapedPattern(for: word) + "(?![\\p{L}\\p{N}])", options: .caseInsensitive),
                  let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: source.length)) else { return nil }
            let original = source.substring(with: match.range)
            let correctID = "word-" + word
            let others = (1...3).map { words[(index + $0) % words.count] }
            var options = ([word] + others).map { value in
                Prompt28AnswerOption(id: "word-" + value, text: value == word ? original : (original.first?.isUppercase == true ? value.capitalized : value))
            }
            let rotation = (match.range.location + index) % options.count
            options = Array(options[rotation...]) + Array(options[..<rotation])
            return Candidate(text: source.replacingCharacters(in: match.range, with: "[blank]"), originalWord: original,
                             location: match.range.location, options: options, correctID: correctID)
        }
    }
}
