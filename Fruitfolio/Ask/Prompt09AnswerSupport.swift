import Foundation

enum AskKnowledgeSupport: String, Codable, Sendable {
    case supported
    case partiallySupported
    case genuinelyNovel
}

struct AskSourceRecord: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let sourceText: String?
    let urlString: String?
    let doi: String?
    let publicationData: String?
    let contentVersion: String?

    init(
        id: String,
        title: String,
        sourceText: String? = nil,
        urlString: String? = nil,
        doi: String? = nil,
        publicationData: String? = nil,
        contentVersion: String? = nil
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.urlString = urlString
        self.doi = doi
        self.publicationData = publicationData
        self.contentVersion = contentVersion
    }
}

/// Version dictionaries cannot represent contradictory versions or distinct
/// UTF-8 identifiers that Swift String equality would normalize into one key.
enum Prompt09SaveSourceVersions {
    static let rejectionMessage = "this answer has inconsistent source metadata and cannot be saved. the original answer is preserved."
    private struct Seen {
        let idBytes: Data
        let versionBytes: Data?
    }
    static func validated(_ sources: [AskSourceRecord]) -> [String: String]? {
        var seen: [String: Seen] = [:]
        var versions: [String: String] = [:]
        for source in sources {
            guard !source.id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            if let version = source.contentVersion,
               version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return nil }
            let idBytes = Data(source.id.utf8)
            let versionBytes = source.contentVersion.map { Data($0.utf8) }
            if let previous = seen[source.id] {
                guard previous.idBytes == idBytes, previous.versionBytes == versionBytes else { return nil }
            } else {
                seen[source.id] = Seen(idBytes: idBytes, versionBytes: versionBytes)
                if let version = source.contentVersion { versions[source.id] = version }
            }
        }
        return versions
    }
}

/// Open only a supplied HTTPS citation or an exact DOI resolver destination.
/// A title, search phrase or model-generated address never becomes a link.
enum Prompt09CitationDestination {
    static func url(sourceURL: String?, doi: String?) -> URL? {
        if let sourceURL, let components = URLComponents(string: sourceURL.trimmingCharacters(in: .whitespacesAndNewlines)),
           components.scheme?.lowercased() == "https", let host = components.host, !host.isEmpty,
           components.user == nil, components.password == nil, let url = components.url {
            return url
        }
        guard var identifier = doi?.trimmingCharacters(in: .whitespacesAndNewlines), !identifier.isEmpty else { return nil }
        if let components = URLComponents(string: identifier),
           let host = components.host?.lowercased(), ["doi.org", "dx.doi.org"].contains(host),
           ["https", "http"].contains(components.scheme?.lowercased() ?? ""),
           components.user == nil, components.password == nil, components.query == nil, components.fragment == nil {
            identifier = String(components.path.dropFirst())
        } else if identifier.lowercased().hasPrefix("doi:") {
            identifier = String(identifier.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard identifier.range(of: #"^10\.\d{4,9}/\S+$"#, options: .regularExpression) != nil else { return nil }
        var destination = URLComponents()
        destination.scheme = "https"
        destination.host = "doi.org"
        destination.path = "/" + identifier
        return destination.url
    }
}

/// In-memory verification metadata, never an implicit transcript store.
enum FruitfolioAnswerPath: String, Codable, Sendable {
    case generated, retrievalFallback, localSafety, unsupported, unavailableContent
}
