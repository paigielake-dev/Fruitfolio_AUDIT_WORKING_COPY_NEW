import Foundation

// MARK: - Ask conversation

enum AskKnowledgeSupport: String, Codable, Sendable {
    case supported
    case partiallySupported
    case genuinelyNovel
}

enum AskMessageRole: String, Codable, Sendable {
    case fruitfolio
    case user
}

struct AskMessage: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let role: AskMessageRole
    let text: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        role: AskMessageRole,
        text: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.createdAt = createdAt
    }
}

struct AskSourceRecord: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let sourceText: String?
    let urlString: String?
    let doi: String?
    let publicationData: String?
    let contentVersion: String?

    init(
        id: String,
        title: String,
        sourceText: String? = nil,
        urlString: String? = nil,
        doi: String? = nil,
        publicationData: String? = nil,
        contentVersion: String? = nil
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.urlString = urlString
        self.doi = doi
        self.publicationData = publicationData
        self.contentVersion = contentVersion
    }
}

struct AskSupportMapEntry: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let concept: String
    let support: AskKnowledgeSupport

    init(id: UUID = UUID(), concept: String, support: AskKnowledgeSupport) {
        self.id = id
        self.concept = concept
        self.support = support
    }
}

struct AskResearchGap: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let normalizedTopic: String
    let originalQuestion: String
    let knownComponents: [String]
    let unknownComponent: String
    let relatedExistingTopics: [String]
    let closestLibraryMatches: [String]
    let retrievalAttempts: [String]
    let detectedAt: Date
}

struct AskAnswer: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let originalQuestion: String
    let answerText: String
    let support: AskKnowledgeSupport
    let supportMap: [AskSupportMapEntry]
    let sourceIDs: [String]
    let sources: [AskSourceRecord]
    let knowledgeBaseVersion: String
    let generationTimestamp: Date
    let conceptTags: Set<String>
    let researchGap: AskResearchGap?
    let isDevelopmentPreview: Bool

    init(
        id: UUID = UUID(),
        originalQuestion: String,
        answerText: String,
        support: AskKnowledgeSupport,
        supportMap: [AskSupportMapEntry] = [],
        sourceIDs: [String] = [],
        sources: [AskSourceRecord] = [],
        knowledgeBaseVersion: String,
        generationTimestamp: Date = Date(),
        conceptTags: Set<String> = [],
        researchGap: AskResearchGap? = nil,
        isDevelopmentPreview: Bool = false
    ) {
        self.id = id
        self.originalQuestion = originalQuestion
        self.answerText = answerText
        self.support = support
        self.supportMap = supportMap
        self.sourceIDs = sourceIDs
        self.sources = sources
        self.knowledgeBaseVersion = knowledgeBaseVersion
        self.generationTimestamp = generationTimestamp
        self.conceptTags = conceptTags
        self.researchGap = researchGap
        self.isDevelopmentPreview = isDevelopmentPreview
    }
}

// MARK: - Saved library data model established by Prompt 09

enum FruitfolioSavedPageType: String, Codable, Sendable {
    case fullAnswer
    case excerpt
}

struct FruitfolioEncyclopedia: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var style: String
    let createdAt: Date
    var updatedAt: Date
}

struct FruitfolioChapter: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let encyclopediaID: UUID
    var name: String
    var order: Int
}

struct FruitfolioSavedPage: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let chapterID: UUID?
    let question: String
    let answer: String
    let saveType: FruitfolioSavedPageType
    let excerptText: String?
    let originalAnswerID: UUID
    let originalConversationID: UUID?
    let sourceIDs: [String]
    let sourceVersions: [String]
    let knowledgeBaseVersion: String
    let generationTimestamp: Date
    let savedAt: Date
    var updatedAt: Date
    var notes: String?
    var order: Int
    let sourceSavedPageID: UUID?
}

struct AskSaveRequest: Hashable, Sendable {
    let answer: AskAnswer
    let conversationID: UUID
    let saveType: FruitfolioSavedPageType
    let excerptText: String?
    let selectedCharacterRange: Range<String.Index>?
}

// MARK: - Provider contracts

protocol AskKnowledgeServing: Sendable {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer
}

protocol AskResearchProgressServing: AskKnowledgeServing {
    func answer(
        question: String,
        conversation: [AskMessage],
        trackerContext: FruitfolioBoundedTrackerContext?,
        progress: ((FruitfolioResearchProgress) -> Void)?
    ) async throws -> AskAnswer
}

protocol AskSaving: Sendable {
    func save(_ request: AskSaveRequest) async throws
}

enum AskEngineError: LocalizedError, Sendable {
    case emptyQuestion
    case knowledgeProviderUnavailable

    var errorDescription: String? {
        switch self {
        case .emptyQuestion:
            return "Please enter a question."
        case .knowledgeProviderUnavailable:
            return "Fruitfolio's approved research library is not connected in this build yet."
        }
    }
}
