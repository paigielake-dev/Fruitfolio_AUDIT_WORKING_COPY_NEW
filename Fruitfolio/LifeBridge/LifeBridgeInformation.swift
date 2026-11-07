import Foundation

struct FruitfolioLifeBridgeSnapshot: Codable, Equatable, Sendable {
    let id: String
    let title: String
    let sourceURL: URL
    let retrievedAt: Date
    let reviewedAt: Date
    let version: String
    let approvedText: String
}

struct FruitfolioLifeBridgeContent: Codable, Equatable, Sendable {
    let snapshots: [FruitfolioLifeBridgeSnapshot]
    let officialApplicationURL: URL?
    let relationshipDisclosure: String?

    private static func isOfficialURL(_ url: URL, hosts: Set<String>) -> Bool {
        url.scheme?.lowercased() == "https" && hosts.contains(url.host?.lowercased() ?? "") &&
            url.user == nil && url.password == nil && (url.port == nil || url.port == 443)
    }
    private static func hasVisibleContent(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func validate(now: Date = Date()) -> Bool {
        guard now.timeIntervalSinceReferenceDate.isFinite else { return false }
        let hosts = Set(snapshots.compactMap { $0.sourceURL.host?.lowercased() })
        guard hosts.contains("lifebridgesurrogacy.com"), hosts.contains("fruitsoflifexo.carrd.co"),
              Set(snapshots.map(\.id)).count == snapshots.count else { return false }
        guard snapshots.allSatisfy({ snapshot in
            Self.isOfficialURL(snapshot.sourceURL, hosts: ["lifebridgesurrogacy.com", "fruitsoflifexo.carrd.co"]) &&
            [snapshot.id, snapshot.title, snapshot.version, snapshot.approvedText].allSatisfy(Self.hasVisibleContent) &&
            snapshot.retrievedAt.timeIntervalSinceReferenceDate.isFinite && snapshot.reviewedAt.timeIntervalSinceReferenceDate.isFinite &&
            snapshot.retrievedAt <= snapshot.reviewedAt && snapshot.reviewedAt <= now
        }) else { return false }
        if let application = officialApplicationURL {
            guard Self.isOfficialURL(application, hosts: ["lifebridgesurrogacy.com"]) else { return false }
        }
        return true
    }
}

enum FruitfolioLifeBridgeInformation {
    static let awaitingStatus = "awaiting_verified_lifebridge_content"
    static let missingContent = "details not available in the approved library yet"
    static let officialURL = URL(string: "https://lifebridgesurrogacy.com/")
    static let founderURL = URL(string: "https://fruitsoflifexo.carrd.co/")
    static let founderInstagramURL = URL(string: "https://www.instagram.com/fruitsoflife.xo/")

    static func isOrganizationQuestion(_ question: String) -> Bool {
        let text = question.lowercased()
        return text.contains("lifebridge") || text.contains("life bridge")
    }
    static func isDiscoverable(for question: String) -> Bool {
        isOrganizationQuestion(question) || question.localizedCaseInsensitiveContains("surrogacy")
    }
    static func load(bundle: Bundle = .main) -> FruitfolioLifeBridgeContent? {
        guard let url = bundle.url(forResource: "LifeBridgeApprovedContent", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let content = try? decoder.decode(FruitfolioLifeBridgeContent.self, from: data), content.validate() else { return nil }
        return content
    }
}
