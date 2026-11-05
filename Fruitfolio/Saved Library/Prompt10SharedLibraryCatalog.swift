import Foundation

/// Feature projections of the same records. Legacy guideBuilderEnabled is
/// retained for backwards compatibility, never used to hide a shared book.
nonisolated enum Prompt10SharedLibraryCatalog {
    static func books(_ records: [Prompt10Encyclopedia]) -> [Prompt10Encyclopedia] {
        records.sorted {
            $0.updatedAt == $1.updatedAt ? $0.id.uuidString < $1.id.uuidString : $0.updatedAt > $1.updatedAt
        }
    }

    static func sourceKey(_ page: Prompt10SavedPage) -> UUID { page.sourceSavedPageID ?? page.id }

    static func material(_ records: [Prompt10Encyclopedia]) -> [Prompt10SavedPage] {
        let pages = records.flatMap(\.chapters).flatMap(\.pages)
        var bySource: [UUID: Prompt10SavedPage] = [:]
        for page in pages {
            let key = sourceKey(page)
            if let previous = bySource[key] {
                // The original remains authoritative while it exists. A later
                // guide snapshot must not silently become "view original".
                if previous.sourceSavedPageID == nil { continue }
                if page.sourceSavedPageID != nil, previous.savedAt >= page.savedAt { continue }
            }
            bySource[key] = page
        }
        return bySource.values.sorted {
            $0.savedAt == $1.savedAt ? $0.id.uuidString < $1.id.uuidString : $0.savedAt > $1.savedAt
        }
    }

    static func originalPage(sourceKey: UUID, in records: [Prompt10Encyclopedia]) -> Prompt10SavedPage? {
        records.flatMap(\.chapters).flatMap(\.pages).first {
            $0.id == sourceKey && $0.sourceSavedPageID == nil
        }
    }

    static func containedSourceKeys(in book: Prompt10Encyclopedia) -> Set<UUID> {
        Set(book.chapters.flatMap(\.pages).map(sourceKey))
    }
}
