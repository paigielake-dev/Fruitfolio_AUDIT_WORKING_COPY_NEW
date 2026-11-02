import Foundation

@MainActor
extension Prompt10SavedLibraryStore {
    var prompt11Guides: [Prompt10Encyclopedia] {
        encyclopedias
            .filter { $0.guideBuilderEnabled == true }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func prompt11AllSavedMaterial() -> [Prompt10SavedPage] {
        var seen = Set<UUID>()
        var results: [Prompt10SavedPage] = []

        let pages = encyclopedias
            .filter { $0.guideBuilderEnabled != true }
            .flatMap(\.chapters)
            .flatMap(\.pages)
            .sorted { $0.savedAt > $1.savedAt }

        for page in pages {
            let sourceKey = page.sourceSavedPageID ?? page.id

            if seen.insert(sourceKey).inserted {
                results.append(page)
            }
        }

        return results
    }

    func prompt11SourcePage(sourceKey: UUID) -> Prompt10SavedPage? {
        prompt11AllSavedMaterial().first {
            ($0.sourceSavedPageID ?? $0.id) == sourceKey
        }
    }

    func prompt11SavedMaterialCandidates(
        for encyclopediaID: UUID,
        filter: Prompt11SavedMaterialFilter,
        searchText: String
    ) -> [Prompt11SavedMaterialCandidate] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let guide = encyclopedia(id: encyclopediaID) else {
            return []
        }

        let existingSourceKeys = Set(
            guide.chapters
                .flatMap(\.pages)
                .compactMap(\.sourceSavedPageID)
        )

        return prompt11AllSavedMaterial()
            .filter { filter.includes($0) }
            .filter { page in
                guard !cleanSearch.isEmpty else {
                    return true
                }

                return page.question.localizedCaseInsensitiveContains(cleanSearch) ||
                    page.displayBody.localizedCaseInsensitiveContains(cleanSearch)
            }
            .map { page in
                let sourceKey = page.sourceSavedPageID ?? page.id

                return Prompt11SavedMaterialCandidate(
                    page: page,
                    sourceKey: sourceKey,
                    isAlreadyInGuide: existingSourceKeys.contains(sourceKey)
                )
            }
    }

    @discardableResult
    func prompt11AddSavedMaterial(
        _ sourcePage: Prompt10SavedPage,
        to encyclopediaID: UUID,
        chapterID: UUID
    ) throws -> Prompt10SavedPage {
        guard let guide = encyclopedia(id: encyclopediaID) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }

        let sourceKey = sourcePage.sourceSavedPageID ?? sourcePage.id

        let alreadyExists = guide.chapters
            .flatMap(\.pages)
            .contains { $0.sourceSavedPageID == sourceKey }

        if alreadyExists {
            return sourcePage
        }

        let referencePage = Prompt10SavedPage(
            chapterID: chapterID,
            question: sourcePage.question,
            answer: sourcePage.answer,
            saveType: sourcePage.saveType,
            excerptText: sourcePage.excerptText,
            originalAnswerID: sourcePage.originalAnswerID,
            originalConversationID: sourcePage.originalConversationID,
            sourceIDs: sourcePage.sourceIDs,
            sourceVersions: sourcePage.sourceVersions,
            sourceSnapshots: sourcePage.sourceSnapshots,
            knowledgeBaseVersion: sourcePage.knowledgeBaseVersion,
            generationTimestamp: sourcePage.generationTimestamp,
            notes: "",
            sourceSavedPageID: sourceKey,
            importedImageIDs: sourcePage.importedImageIDs,
            semanticDocument: sourcePage.semanticDocument,
            isUserAuthored: sourcePage.isUserAuthored
        )

        return try savePage(
            referencePage,
            to: encyclopediaID,
            chapterID: chapterID
        )
    }

    func prompt11TableOfContents(
        for encyclopediaID: UUID
    ) -> [Prompt11TableOfContentsEntry] {
        guard let guide = encyclopedia(id: encyclopediaID) else {
            return []
        }

        var currentPage = 1

        return guide.chapters
            .sorted { $0.order < $1.order }
            .map { chapter in
                let entry = Prompt11TableOfContentsEntry(
                    id: chapter.id,
                    sectionName: chapter.name,
                    firstPageNumber: currentPage,
                    pageCount: chapter.pages.count
                )

                currentPage += max(chapter.pages.count, 1)
                return entry
            }
    }
}
