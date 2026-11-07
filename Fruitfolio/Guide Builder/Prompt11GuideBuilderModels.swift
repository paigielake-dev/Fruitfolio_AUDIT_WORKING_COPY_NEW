import Foundation

enum Prompt11SavedMaterialFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case fullAnswers
    case excerpts

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:
            return "all"
        case .fullAnswers:
            return "full answers"
        case .excerpts:
            return "excerpts"
        }
    }

    func includes(_ page: Prompt10SavedPage) -> Bool {
        switch self {
        case .all:
            return true
        case .fullAnswers:
            return page.saveType == .fullAnswer
        case .excerpts:
            return page.saveType == .excerpt
        }
    }
}

enum Prompt11Overlay: Equatable {
    case createGuide
    case renameGuide(UUID, String)
    case editDescription(UUID, String)
    case changeCover(UUID, Prompt10BookStyle)
    case deleteGuide(UUID)
    case addSection(UUID)
    case renameSection(UUID, UUID, String)
    case addNote(UUID, UUID, UUID, String)
    case addSavedPages(UUID)
    case movePage(UUID, UUID, UUID)
    case removePage(UUID, UUID, UUID)
    case viewOriginal(UUID)
}

struct Prompt11SavedMaterialCandidate: Identifiable, Equatable {
    let page: Prompt10SavedPage
    let sourceKey: UUID
    let isAlreadyInGuide: Bool

    var id: UUID { sourceKey }
}

struct Prompt11TableOfContentsEntry: Identifiable, Equatable {
    let id: UUID
    let sectionName: String
    let firstPageNumber: Int
    let pageCount: Int
}

struct Prompt11GuideSearchMatch: Identifiable, Equatable {
    let page: Prompt10SavedPage
    let section: String

    var id: UUID { page.id }
}

/// Display-only numeric copy. Persisted guide structure and authored text are
/// never rewritten when the selected language changes.
nonisolated struct Prompt11GuideCountCopy: Equatable, Sendable {
    let pageCountLiteral: String
    let sectionCountLiteral: String
    let pagesSource: String
    let savedPagesSource: String
    let progressSource: String
    var progressLiterals: [String] { [sectionCountLiteral, pageCountLiteral] }

    init(sections: Int, pages: Int, language: FruitfolioLanguage) {
        let locale = Locale(identifier: language.localeIdentifier)
        pageCountLiteral = pages.formatted(.number.locale(locale))
        sectionCountLiteral = sections.formatted(.number.locale(locale))
        pagesSource = "\(pageCountLiteral) \(pages == 1 ? "page" : "pages")"
        savedPagesSource = "\(pageCountLiteral) \(pages == 1 ? "saved page" : "saved pages")"
        progressSource = "\(sectionCountLiteral) \(sections == 1 ? "section" : "sections") · \(pagesSource)"
    }
}

nonisolated struct Prompt11GuideTileCopy: Equatable, Sendable {
    let counts: Prompt11GuideCountCopy
    let accessibilitySource: String
    let accessibilityProtectedLiterals: [String]

    init(name: String, sections: Int, pages: Int, language: FruitfolioLanguage) {
        counts = .init(sections: sections, pages: pages, language: language)
        let literalName = FruitfolioSemanticMarkup.markdown([.init(text: name)])
        accessibilitySource = "\(literalName). \(counts.savedPagesSource)."
        accessibilityProtectedLiterals = [literalName, counts.pageCountLiteral].filter { !$0.isEmpty }
    }
}

nonisolated struct Prompt11GuideContentsCopy: Equatable, Sendable {
    let ordinalLiteral: String
    let pageLiteral: String
    let accessibilitySource: String
    let protectedLiterals: [String]

    init(ordinal: Int, sectionName: String, firstPage: Int, language: FruitfolioLanguage) {
        let style: IntegerFormatStyle<Int> = .number.locale(Locale(identifier: language.localeIdentifier)).grouping(.never)
        ordinalLiteral = ordinal.formatted(style.precision(.integerLength(2...)))
        pageLiteral = firstPage.formatted(style)
        let literalName = FruitfolioSemanticMarkup.markdown([.init(text: sectionName)])
        accessibilitySource = "section \(ordinalLiteral), \(literalName), page \(pageLiteral)"
        protectedLiterals = [ordinalLiteral, literalName, pageLiteral].filter { !$0.isEmpty }
    }
}

nonisolated struct Prompt11GuidePaginationCopy: Equatable, Sendable {
    let currentLiteral: String
    let totalLiteral: String
    let displaySource: String
    let accessibilitySource: String
    var protectedLiterals: [String] { [currentLiteral, totalLiteral] }
    init(current: Int, total: Int, language: FruitfolioLanguage) {
        let style: IntegerFormatStyle<Int> = .number.grouping(.never).locale(Locale(identifier: language.localeIdentifier))
        currentLiteral = current.formatted(style)
        totalLiteral = total.formatted(style)
        displaySource = "\(currentLiteral) / \(totalLiteral)"
        accessibilitySource = "page \(currentLiteral) of \(totalLiteral)"
    }
}

nonisolated struct Prompt11GuideInteractionContext: Equatable, Sendable {
    var epoch: UUID
    var languageID: String
    var selectedGuideID: UUID?
    var isVisible: Bool
    var isActive: Bool
    var allowsInteraction: Bool
}

/// Captures displayed placement, not independent authored content. A delayed
/// reorder may never act on a different visit, guide or newly ordered list.
nonisolated struct Prompt11GuideReorderOwner: Equatable, Sendable {
    enum Scope: Equatable, Sendable { case sections, pages(UUID) }
    let guideID: UUID
    let scope: Scope
    let epoch: UUID
    let languageID: String
    let renderedIDs: [UUID]

    init?(guide: Prompt10Encyclopedia, scope: Scope, epoch: UUID, languageID: String) {
        guard let identifiers = Self.identifiers(in: guide, scope: scope) else { return nil }
        guideID = guide.id
        self.scope = scope
        self.epoch = epoch
        self.languageID = languageID
        renderedIDs = identifiers
    }

    /// Capture one page-list snapshot at the section boundary, then share its
    /// immutable array with every row instead of sorting/copying it per page.
    init?(guideID: UUID, chapter: Prompt10Chapter, epoch: UUID, languageID: String) {
        let ids = chapter.pages.sorted { $0.order < $1.order }.map(\.id)
        guard chapter.encyclopediaID == guideID, Set(ids).count == ids.count else { return nil }
        self.guideID = guideID
        scope = .pages(chapter.id)
        self.epoch = epoch
        self.languageID = languageID
        renderedIDs = ids
    }

    func accepts(in records: [Prompt10Encyclopedia], context: Prompt11GuideInteractionContext) -> Bool {
        guard context.isVisible, context.isActive, context.allowsInteraction,
              context.selectedGuideID == guideID, context.epoch == epoch, context.languageID == languageID else { return false }
        let matches = records.filter { $0.id == guideID }
        guard matches.count == 1, let guide = matches.first else { return false }
        return Self.identifiers(in: guide, scope: scope) == renderedIDs
    }

    private static func identifiers(in guide: Prompt10Encyclopedia, scope: Scope) -> [UUID]? {
        let ids: [UUID]
        switch scope {
        case .sections:
            guard guide.chapters.allSatisfy({ $0.encyclopediaID == guide.id }) else { return nil }
            ids = guide.chapters.sorted { $0.order < $1.order }.map(\.id)
        case .pages(let chapterID):
            let chapters = guide.chapters.filter { $0.id == chapterID }
            guard chapters.count == 1, let chapter = chapters.first, chapter.encyclopediaID == guide.id else { return nil }
            ids = chapter.pages.sorted { $0.order < $1.order }.map(\.id)
        }
        guard Set(ids).count == ids.count else { return nil }
        return ids
    }
}
