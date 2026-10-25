import Foundation

protocol Prompt26PregnancyResearchProviding: Sendable {
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent
}

enum Prompt26ResearchBridgeError: Error, Equatable, Sendable {
    case contentUnavailable(String)
}

struct Prompt26UnavailableResearchProvider: Prompt26PregnancyResearchProviding {
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent {
        throw Prompt26ResearchBridgeError.contentUnavailable(contentID)
    }
}

struct Prompt26ClosureResearchProvider: Prompt26PregnancyResearchProviding {
    private let loader: @Sendable (String) async throws -> Prompt26ApprovedContent

    init(loader: @escaping @Sendable (String) async throws -> Prompt26ApprovedContent) {
        self.loader = loader
    }

    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent {
        try await loader(contentID)
    }
}

struct Prompt26PregnancyEducationActions: Sendable {
    var openSources: @Sendable ([String]) -> Void
    var saveEducationEntry: @Sendable (Prompt26SavedEducationEntry) -> Void
    var openFertilizationEducation: @Sendable () -> Void

    init(
        openSources: @escaping @Sendable ([String]) -> Void = { _ in },
        saveEducationEntry: @escaping @Sendable (Prompt26SavedEducationEntry) -> Void = { _ in },
        openFertilizationEducation: @escaping @Sendable () -> Void = {}
    ) {
        self.openSources = openSources
        self.saveEducationEntry = saveEducationEntry
        self.openFertilizationEducation = openFertilizationEducation
    }
}
