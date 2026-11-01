import Foundation

struct Prompt10SavedCitation: Identifiable, Equatable {
    let id: String
    let reference: String?
    let urlString: String?
    let isSnapshot: Bool
}

/// Citation metadata never supplies a new claim or silently substitutes the
/// current version of a source for the version attached to a saved answer.
enum Prompt10SavedCitationResolver {
    static func resolve(_ page: Prompt10SavedPage, package: FruitfolioResearchPackage? = nil) -> [Prompt10SavedCitation] {
        let snapshots = page.sourceSnapshots.map { Dictionary(grouping: $0, by: \.id) }
        let sources = package.map { Dictionary(grouping: $0.sources, by: \.sourceID) }
        return page.sourceIDs.map { id in
            let unavailable = Prompt10SavedCitation(id: id, reference: nil, urlString: nil, isSnapshot: snapshots != nil)
            if let snapshots {
                guard let matches = snapshots[id], matches.count == 1,
                      let source = matches.first,
                      let reference = source.sourceText,
                      !reference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return unavailable }
                if let expected = page.sourceVersions[id], expected != source.contentVersion { return unavailable }
                return .init(id: id, reference: reference, urlString: safeURL(source.urlString), isSnapshot: true)
            }
            // Legacy pages have no reference snapshots. Recover only the exact
            // approved content version, never a similar title or new revision.
            guard let package, page.knowledgeBaseVersion == package.contentVersion,
                  let matches = sources?[id], matches.count == 1, let source = matches.first,
                  source.isApprovedForDisplay, let expected = page.sourceVersions[id],
                  expected == source.contentVersion, let reference = source.apa7Reference else { return unavailable }
            return .init(id: id, reference: reference, urlString: safeURL(source.canonicalURL), isSnapshot: false)
        }
    }

    private static func safeURL(_ raw: String?) -> String? {
        guard let raw, let url = URL(string: raw), ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return raw
    }
}
