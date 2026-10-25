import Foundation

protocol Prompt27ScienceResearchProviding: Sendable {
    func approvedContent(
        for contentID: String
    ) async throws -> Prompt27ApprovedScienceContent
}

struct Prompt27UnavailableScienceResearchProvider: Prompt27ScienceResearchProviding {
    init() {}

    func approvedContent(
        for contentID: String
    ) async throws -> Prompt27ApprovedScienceContent {
        throw Prompt27ScienceLoadFailure.researchUnavailable
    }
}

struct Prompt27ClosureScienceResearchProvider: Prompt27ScienceResearchProviding {
    typealias Loader = @Sendable (String) async throws -> Prompt27ApprovedScienceContent

    private let loader: Loader

    init(loader: @escaping Loader) {
        self.loader = loader
    }

    func approvedContent(
        for contentID: String
    ) async throws -> Prompt27ApprovedScienceContent {
        let content = try await loader(contentID)

        guard content.contentID == contentID else {
            throw Prompt27ScienceLoadFailure.invalidApprovedContent
        }

        guard !content.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Prompt27ScienceLoadFailure.invalidApprovedContent
        }

        guard !content.sourceIDs.isEmpty else {
            throw Prompt27ScienceLoadFailure.invalidApprovedContent
        }

        return content
    }
}

struct Prompt27ScienceActions: Sendable {
    let showSources: @Sendable ([String]) -> Void
    let saveEducationalContent: @Sendable (Prompt27ApprovedScienceContent) -> Void
    let openRelatedTopic: @Sendable (String) -> Void
    let openHotspotContent: @Sendable (String) -> Void

    init(
        showSources: @escaping @Sendable ([String]) -> Void = { _ in },
        saveEducationalContent: @escaping @Sendable (Prompt27ApprovedScienceContent) -> Void = { _ in },
        openRelatedTopic: @escaping @Sendable (String) -> Void = { _ in },
        openHotspotContent: @escaping @Sendable (String) -> Void = { _ in }
    ) {
        self.showSources = showSources
        self.saveEducationalContent = saveEducationalContent
        self.openRelatedTopic = openRelatedTopic
        self.openHotspotContent = openHotspotContent
    }
}
