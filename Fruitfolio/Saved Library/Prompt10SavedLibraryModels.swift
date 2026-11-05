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
    var educationalAssetIDs: [FruitfolioAssetID]?
    var sourceRecords: [AskSourceRecord]?
    var sourceVersions: [String: String]
    var knowledgeBaseVersion: String?
    var generationTimestamp: Date?

    var savedAt: Date
    var updatedAt: Date

    var notes: String
    var order: Int
    var sourceSavedPageID: UUID?
    var importedImageIDs: [String]?
    var excerptSemanticSpans: [FruitfolioSemanticSpan]?
    var excerptSelectionLocation: Int?
    var excerptSelectionLength: Int?
    var excerptLanguage: String?

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
        knowledgeBaseVersion: String? = nil,
        generationTimestamp: Date? = nil,
        savedAt: Date = Date(),
        updatedAt: Date = Date(),
        notes: String = "",
        order: Int = 0,
        sourceSavedPageID: UUID? = nil,
        importedImageIDs: [String]? = nil,
        excerptSemanticSpans: [FruitfolioSemanticSpan]? = nil,
        excerptSelectionLocation: Int? = nil,
        excerptSelectionLength: Int? = nil,
        excerptLanguage: String? = nil,
        sourceRecords: [AskSourceRecord]? = nil,
        educationalAssetIDs: [FruitfolioAssetID]? = nil
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
        self.educationalAssetIDs = educationalAssetIDs
        self.sourceRecords = sourceRecords
        self.sourceVersions = sourceVersions
        self.knowledgeBaseVersion = knowledgeBaseVersion
        self.generationTimestamp = generationTimestamp
        self.savedAt = savedAt
        self.updatedAt = updatedAt
        self.notes = notes
        self.order = order
        self.sourceSavedPageID = sourceSavedPageID
        self.importedImageIDs = importedImageIDs
        self.excerptSemanticSpans = excerptSemanticSpans
        self.excerptSelectionLocation = excerptSelectionLocation
        self.excerptSelectionLength = excerptSelectionLength
        self.excerptLanguage = excerptLanguage
    }

    func isDuplicateSave(of candidate: Prompt10SavedPage) -> Bool {
        guard let origin = originalAnswerID, origin == candidate.originalAnswerID,
              saveType == candidate.saveType else { return false }
        guard (educationalAssetIDs ?? []) == (candidate.educationalAssetIDs ?? []) else { return false }
        if saveType == .fullAnswer { return true }
        if excerptText == "", candidate.excerptText == "", !(educationalAssetIDs ?? []).isEmpty { return true }
        // Legacy records without an occurrence range cannot prove that a new
        // selection is the same occurrence; do not guess from equal words.
        guard let location = excerptSelectionLocation, let length = excerptSelectionLength,
              let otherLocation = candidate.excerptSelectionLocation,
              let otherLength = candidate.excerptSelectionLength else { return false }
        return location == otherLocation && length == otherLength &&
            (excerptLanguage ?? "en") == (candidate.excerptLanguage ?? "en") && excerptText == candidate.excerptText
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

    var errorDescription: String? {
        switch self {
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

/// Draft ownership prevents unrelated media redraws from replacing unsaved notes.
struct Prompt10NoteDraft: Equatable {
    private(set) var pageID: UUID?
    private(set) var baseline = ""
    var text = ""
    var hasChanges: Bool { text != baseline }

    mutating func load(pageID: UUID, notes: String) {
        guard self.pageID != pageID else { return }
        self.pageID = pageID
        baseline = notes
        text = notes
    }

    mutating func didSave() { baseline = text }
    mutating func discard() { text = baseline }
}

/// Media IDs may be shared by independent saved-page snapshots in guides.
enum Prompt10MediaReferences {
    static func contains(_ imageID: String, in encyclopedias: [Prompt10Encyclopedia]) -> Bool {
        encyclopedias.contains { book in
            book.chapters.contains { chapter in
                chapter.pages.contains { ($0.importedImageIDs ?? []).contains(imageID) }
            }
        }
    }
}
