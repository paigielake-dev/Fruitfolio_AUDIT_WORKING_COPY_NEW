import Foundation
import SwiftUI
import Combine

@MainActor
final class Prompt10SavedLibraryStore: ObservableObject {
    static let shared = Prompt10SavedLibraryStore()

    static let maximumEncyclopedias = 100

    @Published private(set) var encyclopedias: [Prompt10Encyclopedia] = []

    private let defaults: UserDefaults
    private let persistenceKey: String

    init(
        defaults: UserDefaults = .standard,
        persistenceKey: String = "fruitfolio.prompt10.savedLibrary.v2"
    ) {
        self.defaults = defaults
        self.persistenceKey = persistenceKey
        load()
    }

    var count: Int {
        encyclopedias.count
    }

    var canCreateEncyclopedia: Bool {
        count < Self.maximumEncyclopedias
    }

    @discardableResult
    func createEncyclopedia(
        name rawName: String,
        style: Prompt10BookStyle,
        ownerID: String? = nil
    ) throws -> Prompt10Encyclopedia {
        guard encyclopedias.count < Self.maximumEncyclopedias else {
            throw Prompt10LibraryError.encyclopediaLimitReached
        }

        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            throw Prompt10LibraryError.blankTitle
        }

        let id = UUID()
        let defaultChapter = Prompt10Chapter(
            encyclopediaID: id,
            name: "saved pages",
            order: 0
        )

        let encyclopedia = Prompt10Encyclopedia(
            id: id,
            ownerID: ownerID,
            name: cleanName,
            style: style,
            chapters: [defaultChapter]
        )

        encyclopedias.append(encyclopedia)
        try persist()
        return encyclopedia
    }

    func renameEncyclopedia(
        id: UUID,
        to rawName: String
    ) throws {
        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            throw Prompt10LibraryError.blankTitle
        }

        guard let index = encyclopedias.firstIndex(where: { $0.id == id }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        encyclopedias[index].name = cleanName
        encyclopedias[index].updatedAt = Date()
        try persist()
    }

    func deleteEncyclopedia(id: UUID) throws {
        guard let index = encyclopedias.firstIndex(where: { $0.id == id }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        encyclopedias.remove(at: index)
        try persist()
    }

    @discardableResult
    func createChapter(
        in encyclopediaID: UUID,
        name rawName: String
    ) throws -> Prompt10Chapter {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            throw Prompt10LibraryError.blankTitle
        }

        let chapter = Prompt10Chapter(
            encyclopediaID: encyclopediaID,
            name: cleanName,
            order: encyclopedias[encyclopediaIndex].chapters.count
        )

        encyclopedias[encyclopediaIndex].chapters.append(chapter)
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
        return chapter
    }

    func renameChapter(
        encyclopediaID: UUID,
        chapterID: UUID,
        to rawName: String
    ) throws {
        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            throw Prompt10LibraryError.blankTitle
        }

        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        encyclopedias[encyclopediaIndex].chapters[chapterIndex].name = cleanName
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
    }

    func deleteChapter(
        encyclopediaID: UUID,
        chapterID: UUID
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        encyclopedias[encyclopediaIndex].chapters.remove(at: chapterIndex)
        normalizeChapterOrder(encyclopediaIndex: encyclopediaIndex)
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
    }

    @discardableResult
    func savePage(
        _ page: Prompt10SavedPage,
        to encyclopediaID: UUID,
        chapterID: UUID
    ) throws -> Prompt10SavedPage {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        var savedPage = page
        savedPage.chapterID = chapterID
        savedPage.order = encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages.count
        savedPage.savedAt = Date()
        savedPage.updatedAt = Date()

        encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages.append(savedPage)
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
        return savedPage
    }

    func deletePage(
        encyclopediaID: UUID,
        chapterID: UUID,
        pageID: UUID
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        guard let pageIndex = encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages
            .firstIndex(where: { $0.id == pageID }) else {
            throw Prompt10LibraryError.pageNotFound
        }

        encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages.remove(at: pageIndex)
        normalizePageOrder(
            encyclopediaIndex: encyclopediaIndex,
            chapterIndex: chapterIndex
        )
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
    }

    func movePage(
        encyclopediaID: UUID,
        pageID: UUID,
        fromChapterID: UUID,
        toChapterID: UUID
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let fromIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == fromChapterID }),
              let toIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == toChapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        guard let pageIndex = encyclopedias[encyclopediaIndex]
            .chapters[fromIndex]
            .pages
            .firstIndex(where: { $0.id == pageID }) else {
            throw Prompt10LibraryError.pageNotFound
        }

        var page = encyclopedias[encyclopediaIndex].chapters[fromIndex].pages.remove(at: pageIndex)
        page.chapterID = toChapterID
        page.order = encyclopedias[encyclopediaIndex].chapters[toIndex].pages.count
        page.updatedAt = Date()

        encyclopedias[encyclopediaIndex].chapters[toIndex].pages.append(page)

        normalizePageOrder(
            encyclopediaIndex: encyclopediaIndex,
            chapterIndex: fromIndex
        )
        normalizePageOrder(
            encyclopediaIndex: encyclopediaIndex,
            chapterIndex: toIndex
        )

        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
    }

    func encyclopedia(id: UUID) -> Prompt10Encyclopedia? {
        encyclopedias.first(where: { $0.id == id })
    }

    func sorted(
        by sort: Prompt10LibrarySort,
        searchText: String = ""
    ) -> [Prompt10Encyclopedia] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered: [Prompt10Encyclopedia]

        if cleanSearch.isEmpty {
            filtered = encyclopedias
        } else {
            filtered = encyclopedias.filter {
                $0.name.localizedCaseInsensitiveContains(cleanSearch)
            }
        }

        switch sort {
        case .recentlyUpdated:
            return filtered.sorted { $0.updatedAt > $1.updatedAt }

        case .alphabetical:
            return filtered.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }

        case .newest:
            return filtered.sorted { $0.createdAt > $1.createdAt }

        case .oldest:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        }
    }

    // MARK: - Prompt 11 / Guide Builder

    @discardableResult
    func createGuideEncyclopedia(
        name rawName: String,
        subtitle rawSubtitle: String,
        style: Prompt10BookStyle,
        ownerID: String? = nil
    ) throws -> Prompt10Encyclopedia {
        guard encyclopedias.count < Self.maximumEncyclopedias else {
            throw Prompt10LibraryError.encyclopediaLimitReached
        }

        let cleanName = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanSubtitle = rawSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanName.isEmpty else {
            throw Prompt10LibraryError.blankTitle
        }

        let guide = Prompt10Encyclopedia(
            ownerID: ownerID,
            name: cleanName,
            subtitle: cleanSubtitle.isEmpty ? nil : cleanSubtitle,
            guideBuilderEnabled: true,
            style: style,
            chapters: []
        )

        encyclopedias.append(guide)
        try persist()

        return guide
    }

    func updateEncyclopediaDescription(
        id: UUID,
        description rawDescription: String
    ) throws {
        guard let index = encyclopedias.firstIndex(where: { $0.id == id }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        let cleaned = rawDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        encyclopedias[index].subtitle =
            cleaned.isEmpty ? nil : cleaned

        encyclopedias[index].updatedAt = Date()

        try persist()
    }

    func changeEncyclopediaStyle(
        id: UUID,
        to style: Prompt10BookStyle
    ) throws {
        guard let index = encyclopedias.firstIndex(where: { $0.id == id }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        encyclopedias[index].style = style
        encyclopedias[index].updatedAt = Date()

        try persist()
    }

    func updatePageNotes(
        encyclopediaID: UUID,
        chapterID: UUID,
        pageID: UUID,
        notes rawNotes: String
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: {
            $0.id == encyclopediaID
        }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex]
            .chapters
            .firstIndex(where: {
                $0.id == chapterID
            }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        guard let pageIndex = encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages
            .firstIndex(where: {
                $0.id == pageID
            }) else {
            throw Prompt10LibraryError.pageNotFound
        }

        encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages[pageIndex]
            .notes =
                rawNotes.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages[pageIndex]
            .updatedAt = Date()

        encyclopedias[encyclopediaIndex]
            .updatedAt = Date()

        try persist()
    }

    func setImportedImageIDs(
        encyclopediaID: UUID,
        chapterID: UUID,
        pageID: UUID,
        imageIDs: [String]
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: { $0.id == encyclopediaID }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }
        guard let chapterIndex = encyclopedias[encyclopediaIndex].chapters.firstIndex(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }
        guard let pageIndex = encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages.firstIndex(where: { $0.id == pageID }) else {
            throw Prompt10LibraryError.pageNotFound
        }
        encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages[pageIndex].importedImageIDs = imageIDs
        encyclopedias[encyclopediaIndex].chapters[chapterIndex].pages[pageIndex].updatedAt = Date()
        encyclopedias[encyclopediaIndex].updatedAt = Date()
        try persist()
    }

    func moveChapter(
        encyclopediaID: UUID,
        chapterID: UUID,
        offset: Int
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: {
            $0.id == encyclopediaID
        }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let currentIndex = encyclopedias[encyclopediaIndex]
            .chapters
            .firstIndex(where: {
                $0.id == chapterID
            }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        let destinationIndex =
            currentIndex + offset

        guard encyclopedias[encyclopediaIndex]
            .chapters
            .indices
            .contains(destinationIndex)
        else {
            return
        }

        encyclopedias[encyclopediaIndex]
            .chapters
            .swapAt(
                currentIndex,
                destinationIndex
            )

        normalizeChapterOrder(
            encyclopediaIndex:
                encyclopediaIndex
        )

        encyclopedias[encyclopediaIndex]
            .updatedAt = Date()

        try persist()
    }

    func movePageWithinChapter(
        encyclopediaID: UUID,
        chapterID: UUID,
        pageID: UUID,
        offset: Int
    ) throws {
        guard let encyclopediaIndex = encyclopedias.firstIndex(where: {
            $0.id == encyclopediaID
        }) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        guard let chapterIndex = encyclopedias[encyclopediaIndex]
            .chapters
            .firstIndex(where: {
                $0.id == chapterID
            }) else {
            throw Prompt10LibraryError.chapterNotFound
        }

        guard let currentIndex = encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages
            .firstIndex(where: {
                $0.id == pageID
            }) else {
            throw Prompt10LibraryError.pageNotFound
        }

        let destinationIndex =
            currentIndex + offset

        guard encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages
            .indices
            .contains(destinationIndex)
        else {
            return
        }

        encyclopedias[encyclopediaIndex]
            .chapters[chapterIndex]
            .pages
            .swapAt(
                currentIndex,
                destinationIndex
            )

        normalizePageOrder(
            encyclopediaIndex:
                encyclopediaIndex,
            chapterIndex:
                chapterIndex
        )

        encyclopedias[encyclopediaIndex]
            .updatedAt = Date()

        try persist()
    }

    func removeAllForTesting() throws {
        encyclopedias = []
        try persist()
    }

    private func load() {
        guard let data =
                defaults.data(
                    forKey: persistenceKey
                )
        else {
            encyclopedias = []
            return
        }

        do {
            encyclopedias =
                try JSONDecoder().decode(
                    [Prompt10Encyclopedia].self,
                    from: data
                )
        } catch {
            encyclopedias = []
        }
    }

    private func persist() throws {
        do {
            let data =
                try JSONEncoder().encode(
                    encyclopedias
                )

            defaults.set(
                data,
                forKey: persistenceKey
            )
        } catch {
            throw Prompt10LibraryError
                .persistenceFailure
        }
    }

    private func normalizeChapterOrder(
        encyclopediaIndex: Int
    ) {
        for index in
            encyclopedias[encyclopediaIndex]
                .chapters
                .indices {

            encyclopedias[encyclopediaIndex]
                .chapters[index]
                .order = index
        }
    }

    private func normalizePageOrder(
        encyclopediaIndex: Int,
        chapterIndex: Int
    ) {
        for index in
            encyclopedias[encyclopediaIndex]
                .chapters[chapterIndex]
                .pages
                .indices {

            encyclopedias[encyclopediaIndex]
                .chapters[chapterIndex]
                .pages[index]
                .order = index
        }
    }
}
