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

    func validate(now: Date = Date()) -> Bool {
        let hosts = Set(snapshots.compactMap { $0.sourceURL.host?.lowercased() })
        guard hosts.contains("lifebridgesurrogacy.com"), hosts.contains("fruitsoflifexo.carrd.co"),
              Set(snapshots.map(\.id)).count == snapshots.count else { return false }
        guard snapshots.allSatisfy({ snapshot in
            snapshot.sourceURL.scheme == "https" &&
            ["lifebridgesurrogacy.com", "fruitsoflifexo.carrd.co"].contains(snapshot.sourceURL.host?.lowercased() ?? "") &&
            !snapshot.title.isEmpty && !snapshot.version.isEmpty && !snapshot.approvedText.isEmpty &&
            snapshot.retrievedAt <= snapshot.reviewedAt && snapshot.reviewedAt <= now
        }) else { return false }
        if let application = officialApplicationURL {
            guard application.scheme == "https", application.host?.lowercased() == "lifebridgesurrogacy.com" else { return false }
        }
        return true
    }
}

enum FruitfolioLifeBridgeInformation {
    static let awaitingStatus = "awaiting_verified_lifebridge_content"
    static let missingContent = "details not available in the approved library yet"
    static let officialURL = URL(string: "https://lifebridgesurrogacy.com/")
    static let founderURL = URL(string: "https://fruitsoflifexo.carrd.co/")

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
