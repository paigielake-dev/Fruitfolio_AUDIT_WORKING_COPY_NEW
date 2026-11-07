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
