import Foundation

@MainActor
extension Prompt10SavedLibraryStore {
    var prompt11Guides: [Prompt10Encyclopedia] {
        Prompt10SharedLibraryCatalog.books(encyclopedias)
    }

    func prompt11AllSavedMaterial() -> [Prompt10SavedPage] {
        Prompt10SharedLibraryCatalog.material(encyclopedias)
    }

    func prompt11SourcePage(sourceKey: UUID) -> Prompt10SavedPage? {
        Prompt10SharedLibraryCatalog.originalPage(sourceKey: sourceKey, in: encyclopedias)
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

        let existingSourceKeys = Prompt10SharedLibraryCatalog.containedSourceKeys(in: guide)

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

        if let existing = guide.chapters.flatMap(\.pages).first(where: {
            Prompt10SharedLibraryCatalog.sourceKey($0) == sourceKey
        }) {
            return existing
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
            knowledgeBaseVersion: sourcePage.knowledgeBaseVersion,
            generationTimestamp: sourcePage.generationTimestamp,
            notes: sourcePage.userMaterial == nil ? "" : sourcePage.notes,
            sourceSavedPageID: sourceKey,
            importedImageIDs: sourcePage.importedImageIDs,
            excerptSemanticSpans: sourcePage.excerptSemanticSpans,
            excerptSelectionLocation: sourcePage.excerptSelectionLocation,
            excerptSelectionLength: sourcePage.excerptSelectionLength,
            excerptLanguage: sourcePage.excerptLanguage,
            sourceRecords: sourcePage.sourceRecords,
            educationalAssetIDs: sourcePage.educationalAssetIDs,
            userMaterial: sourcePage.userMaterial
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
