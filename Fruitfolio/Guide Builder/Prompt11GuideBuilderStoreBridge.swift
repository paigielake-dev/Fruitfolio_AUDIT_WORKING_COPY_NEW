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

        return try prompt11AddSavedMaterials([sourcePage], to: encyclopediaID, chapterID: chapterID)[0]
    }

    /// Returns only newly added references, deduplicating the whole guide and batch.
    @discardableResult
    func prompt11AddSavedMaterials(
        _ sourcePages: [Prompt10SavedPage],
        to encyclopediaID: UUID,
        chapterID: UUID
    ) throws -> [Prompt10SavedPage] {
        guard let guide = encyclopedia(id: encyclopediaID) else {
            throw Prompt10LibraryError.encyclopediaNotFound
        }
        guard guide.chapters.contains(where: { $0.id == chapterID }) else {
            throw Prompt10LibraryError.chapterNotFound
        }
        var seen = Prompt10SharedLibraryCatalog.containedSourceKeys(in: guide)
        let references = sourcePages.compactMap { sourcePage -> Prompt10SavedPage? in
            let key = Prompt10SharedLibraryCatalog.sourceKey(sourcePage)
            guard seen.insert(key).inserted else { return nil }
            return prompt11ReferencePage(sourcePage, chapterID: chapterID)
        }
        return try savePages(references, to: encyclopediaID, chapterID: chapterID)
    }

    /// Resolve selection against the current shared catalog, independently of
    /// the picker's visible search/filter. Never silently save a surviving subset.
    @discardableResult
    func prompt11AddSavedMaterialSelection(
        sourceKeys: Set<UUID>, to encyclopediaID: UUID, chapterID: UUID
    ) throws -> [Prompt10SavedPage] {
        let pages = prompt11AllSavedMaterial().filter {
            sourceKeys.contains(Prompt10SharedLibraryCatalog.sourceKey($0))
        }
        guard Set(pages.map(Prompt10SharedLibraryCatalog.sourceKey)) == sourceKeys else {
            throw Prompt10LibraryError.contentChanged
        }
        return try prompt11AddSavedMaterials(pages, to: encyclopediaID, chapterID: chapterID)
    }

    private func prompt11ReferencePage(_ sourcePage: Prompt10SavedPage, chapterID: UUID) -> Prompt10SavedPage {
        let sourceKey = Prompt10SharedLibraryCatalog.sourceKey(sourcePage)
        return Prompt10SavedPage(
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
            userMaterial: sourcePage.userMaterial,
            evidenceSupport: sourcePage.evidenceSupport
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

#if DEBUG
/// Real private-fixture pages make the production eight-page search gate
/// reachable. Never repopulates a target that already contains saved content.
@MainActor
enum Prompt11GuideSearchRegressionFixture {
    static func seed(in store: Prompt10SavedLibraryStore, guideID: UUID) throws {
        guard let guide = store.encyclopedia(id: guideID) else { throw Prompt10LibraryError.encyclopediaNotFound }
        guard guide.savedPageCount == 0 else { throw Prompt10LibraryError.contentChanged }
        guard let chapter = guide.chapters.sorted(by: { $0.order < $1.order }).first else {
            throw Prompt10LibraryError.chapterNotFound
        }
        let pages = (1...8).map { index in
            Prompt10SavedPage(chapterID: chapter.id, question: "QA searchable page \(index)",
                answer: "Nonclinical private search fixture \(index).", saveType: .fullAnswer)
        }
        _ = try store.savePages(pages, to: guideID, chapterID: chapter.id)
    }
}
#endif
