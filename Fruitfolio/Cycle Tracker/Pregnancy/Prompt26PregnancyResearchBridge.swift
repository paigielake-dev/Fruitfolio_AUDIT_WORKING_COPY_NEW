import Foundation

protocol Prompt26PregnancyResearchProviding: Sendable {
    func approvedContent(for contentID: String) async throws -> Prompt26ApprovedContent
}

enum Prompt26ResearchBridgeError: Error, Equatable, Sendable {
    case contentUnavailable(String)
    case invalidApprovedContent
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
        let content = try await loader(contentID)
        guard content.hasValidStructure(for: contentID) else {
            throw Prompt26ResearchBridgeError.invalidApprovedContent
        }
        return content
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

// Structural preflight is not scientific/source verification. A production
// provider must still supply content approved by the strict research pipeline.
extension Prompt26ApprovedContent {
    func hasValidStructure(for requestedID: String) -> Bool {
        func nonblank(_ value: String) -> Bool {
            !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        let sources = Set(sourceIDs)
        guard contentID == requestedID, nonblank(requestedID), nonblank(title), nonblank(summary),
              !sources.isEmpty, sources.count == sourceIDs.count,
              sourceIDs.allSatisfy(nonblank), Set(sections.map(\.id)).count == sections.count else { return false }
        return sections.allSatisfy { section in
            nonblank(section.id) && nonblank(section.heading) && nonblank(section.body)
                && !section.sourceIDs.isEmpty
                && Set(section.sourceIDs).count == section.sourceIDs.count
                && Set(section.sourceIDs).isSubset(of: sources)
        }
    }
}
