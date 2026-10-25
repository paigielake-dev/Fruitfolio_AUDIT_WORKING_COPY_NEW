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
