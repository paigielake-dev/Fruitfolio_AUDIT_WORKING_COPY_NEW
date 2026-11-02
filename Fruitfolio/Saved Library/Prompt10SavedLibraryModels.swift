import Foundation

// PROMPT 10 — My Encyclopedias / Saved Library
// Preserves Prompt 09 provenance fields while keeping Prompt 10 feature types
// namespaced so they do not collide with any existing domain models.

enum Prompt10SavedPageType: String, Codable, CaseIterable, Sendable {
    case fullAnswer
    case excerpt
}

enum Prompt10BookStyle: String, Codable, CaseIterable, Sendable {
    case sage
    case yellow
    case pink
    case coral
    case lavender

    var assetName: String {
        switch self {
        case .sage:
            return "library_book_sage"
        case .yellow:
            return "library_book_yellow"
        case .pink:
            return "library_book_pink"
        case .coral:
            return "library_book_coral"
        case .lavender:
            return "library_book_lavender"
        }
    }

    var displayName: String {
        rawValue
    }
}

struct Prompt10SavedPage: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var chapterID: UUID

    var question: String
    var answer: String
    var saveType: Prompt10SavedPageType
    var excerptText: String?

    var originalAnswerID: String?
    var originalConversationID: String?

    var sourceIDs: [String]
    var sourceVersions: [String: String]
    var sourceSnapshots: [AskSourceRecord]?
    var knowledgeBaseVersion: String?
    var generationTimestamp: Date?

    var savedAt: Date
    var updatedAt: Date

    var notes: String
    var order: Int
    var sourceSavedPageID: UUID?
    var importedImageIDs: [String]?
    var semanticDocument: FruitfolioSemanticDocument?
    var isUserAuthored: Bool?

    init(
        id: UUID = UUID(),
        chapterID: UUID,
        question: String,
        answer: String,
        saveType: Prompt10SavedPageType,
        excerptText: String? = nil,
        originalAnswerID: String? = nil,
        originalConversationID: String? = nil,
        sourceIDs: [String] = [],
        sourceVersions: [String: String] = [:],
        sourceSnapshots: [AskSourceRecord]? = nil,
        knowledgeBaseVersion: String? = nil,
        generationTimestamp: Date? = nil,
        savedAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String = "",
        order: Int = 0,
        sourceSavedPageID: UUID? = nil,
        importedImageIDs: [String]? = nil,
        semanticDocument: FruitfolioSemanticDocument? = nil,
        isUserAuthored: Bool? = nil
    ) {
        self.id = id
        self.chapterID = chapterID
        self.question = question
        self.answer = answer
        self.saveType = saveType
        self.excerptText = excerptText
        self.originalAnswerID = originalAnswerID
        self.originalConversationID = originalConversationID
        self.sourceIDs = sourceIDs
        self.sourceVersions = sourceVersions
        self.sourceSnapshots = sourceSnapshots
        self.knowledgeBaseVersion = knowledgeBaseVersion
        self.generationTimestamp = generationTimestamp
        self.savedAt = savedAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.order = order
        self.sourceSavedPageID = sourceSavedPageID
        self.importedImageIDs = importedImageIDs
        self.semanticDocument = semanticDocument
        self.isUserAuthored = isUserAuthored
    }

    var resolvedSemanticDocument: FruitfolioSemanticDocument {
        guard let semanticDocument, semanticDocument.plainText == displayBody else {
            return .init(spans: [.init(text: displayBody)])
        }
        return semanticDocument
    }

    var displayBody: String {
        switch saveType {
        case .fullAnswer:
            return answer
        case .excerpt:
            return excerptText ?? ""
        }
    }
}

struct Prompt10Chapter: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let encyclopediaID: UUID
    var name: String
    var order: Int
    var pages: [Prompt10SavedPage]

    init(
        id: UUID = UUID(),
        encyclopediaID: UUID,
        name: String,
        order: Int,
        pages: [Prompt10SavedPage] = []
    ) {
        self.id = id
        self.encyclopediaID = encyclopediaID
        self.name = name
        self.order = order
        self.pages = pages
    }
}

struct Prompt10Encyclopedia: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var ownerID: String?
    var name: String
    var subtitle: String?
    var guideBuilderEnabled: Bool?
    var style: Prompt10BookStyle
    let createdAt: Date
    var updatedAt: Date
    var chapters: [Prompt10Chapter]

    init(
        id: UUID = UUID(),
        ownerID: String? = nil,
        name: String,
        subtitle: String? = nil,
        guideBuilderEnabled: Bool? = nil,
        style: Prompt10BookStyle,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        chapters: [Prompt10Chapter] = []
    ) {
        self.id = id
        self.ownerID = ownerID
        self.name = name
        self.subtitle = subtitle
        self.guideBuilderEnabled = guideBuilderEnabled
        self.style = style
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.chapters = chapters
    }

    var chapterCount: Int {
        chapters.count
    }

    var savedPageCount: Int {
        chapters.reduce(0) { $0 + $1.pages.count }
    }
}

enum Prompt10LibrarySort: String, Codable, CaseIterable, Identifiable, Sendable {
    case recentlyUpdated
    case alphabetical
    case newest
    case oldest

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentlyUpdated:
            return "recently updated"
        case .alphabetical:
            return "alphabetical"
        case .newest:
            return "newest"
        case .oldest:
            return "oldest"
        }
    }
}

enum Prompt10LibraryError: LocalizedError, Equatable {
    case blankTitle
    case encyclopediaLimitReached
    case encyclopediaNotFound
    case chapterNotFound
    case pageNotFound
    case persistenceFailure
    case titleTooLong
    case descriptionTooLong
    case inappropriateMetadata

    var errorDescription: String? {
        switch self {
        case .titleTooLong:
            return "keep your encyclopedia title to 60 characters or fewer. your writing has not been changed."
        case .descriptionTooLong:
            return "keep your little description to 240 characters or fewer. your writing has not been changed."
        case .inappropriateMetadata:
            return "please choose a title or description without profanity, crude wording, or violent threats. sexual-health and anatomical terms are welcome."
        case .blankTitle:
            return "give your little encyclopedia a name first."
        case .encyclopediaLimitReached:
            return "your little library is completely full."
        case .encyclopediaNotFound:
            return "that encyclopedia could not be found."
        case .chapterNotFound:
            return "that chapter could not be found."
        case .pageNotFound:
            return "that saved page could not be found."
        case .persistenceFailure:
            return "that change didn’t settle properly."
        }
    }
}


/// Metadata only: never run moderation over saved evidence, source citations,
/// questions, health records, or the user's independently authored page body.
/// Existing records are not rewritten/truncated during loading or migration.
nonisolated enum Prompt10MetadataPolicy {
    static let maximumTitleCharacters = 60
    static let maximumDescriptionCharacters = 240

    static func validateTitle(_ text: String) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw Prompt10LibraryError.blankTitle }
        guard trimmed.count <= maximumTitleCharacters else { throw Prompt10LibraryError.titleTooLong }
        try validateWording(trimmed)
    }

    static func validateDescription(_ text: String) throws {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count <= maximumDescriptionCharacters else {
            throw Prompt10LibraryError.descriptionTooLong
        }
        try validateWording(text)
    }

    private static func validateWording(_ text: String) throws {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                                  locale: Locale(identifier: "en_US_POSIX"))
        let words = folded.components(separatedBy: CharacterSet.letters.inverted).filter { !$0.isEmpty }
        let profanity: Set<String> = ["fuck", "fucking", "fucked", "motherfucker", "shit", "shitty", "bullshit",
            "bitch", "cunt", "dick", "cock", "pussy", "asshole", "whore", "slut"]
        if !profanity.isDisjoint(with: words) { throw Prompt10LibraryError.inappropriateMetadata }
        // Whole-word boundaries keep legitimate anatomy/sexual-health language
        // and words such as assessment/intersex from substring false positives.
        // This local guardrail is not a claim of comprehensive multilingual moderation.
        let violentThreat = #"^\s*(?:(?:how|ways)\s+to\s+)?(?:kill|murder|torture)\s+(?:you|them|people|someone|everyone)\b"#
        if folded.range(of: violentThreat, options: .regularExpression) != nil {
            throw Prompt10LibraryError.inappropriateMetadata
        }
    }
}
