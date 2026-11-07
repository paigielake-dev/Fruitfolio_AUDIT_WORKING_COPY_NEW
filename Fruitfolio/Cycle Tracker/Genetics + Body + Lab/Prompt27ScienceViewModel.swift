import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
final class Prompt27ScienceViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(
            Prompt27ApprovedScienceContent,
            Prompt27ScienceVisualRoute
        )
        case unavailable
    }

    #if canImport(Combine)
    @Published
    #endif
    private(set) var state: LoadState = .idle
    #if canImport(Combine)
    @Published
    #endif
    private(set) var selectedHotspotID: String?

    let section: Prompt27ContextualScienceSection

    private let provider: any Prompt27ScienceResearchProviding
    private let router: Prompt27ContextRouter
    private var loadTask: Task<Void, Never>?
    private var loadIdentity = UUID()

    init(
        section: Prompt27ContextualScienceSection,
        provider: any Prompt27ScienceResearchProviding,
        router: Prompt27ContextRouter? = nil
    ) {
        self.section = section
        self.provider = provider
        self.router = router ?? Prompt27ContextRouter()
    }

    deinit {
        loadTask?.cancel()
    }

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard case .idle = state else { return loadTask }

        switch router.route(section: section) {
        case .failure:
            state = .unavailable
            return nil

        case let .success(route):
            loadIdentity = UUID()
            let identity = loadIdentity
            state = .loading

            let contentID = section.bodyContentID
            let provider = self.provider

            loadTask = Task { [weak self] in
                do {
                    let content = try await provider.approvedContent(for: contentID)
                    guard !Task.isCancelled, let self, self.loadIdentity == identity else { return }
                    defer { self.loadTask = nil }
                    guard content.contentID == contentID,
                          !content.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                          !content.sourceIDs.isEmpty else {
                        self.state = .unavailable
                        return
                    }
                    self.state = .loaded(content, route)
                } catch {
                    guard !Task.isCancelled, let self, self.loadIdentity == identity else { return }
                    self.state = .unavailable
                    self.loadTask = nil
                }
            }
        }
        return loadTask
    }

    func suspendPresentation() {
        loadIdentity = UUID()
        loadTask?.cancel()
        loadTask = nil
        if case .loading = state { state = .idle }
    }

    func retry() {
        suspendPresentation()
        state = .idle
        loadIfNeeded()
    }

    func selectHotspot(_ id: String?) {
        if let id, !section.hotspotIDs.contains(id) { return }
        selectedHotspotID = id
    }

    var loadedContent: Prompt27ApprovedScienceContent? {
        guard case let .loaded(content, _) = state else {
            return nil
        }
        return content
    }

    var visualRoute: Prompt27ScienceVisualRoute? {
        guard case let .loaded(_, route) = state else {
            return nil
        }
        return route
    }
}
#if canImport(Combine)
extension Prompt27ScienceViewModel: ObservableObject {}
#endif
