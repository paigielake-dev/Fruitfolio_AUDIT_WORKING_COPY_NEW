#if canImport(SwiftUI)
import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt27ScienceViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(
            Prompt27ApprovedScienceContent,
            Prompt27ScienceVisualRoute
        )
        case unavailable
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var selectedHotspotID: String?

    let section: Prompt27ContextualScienceSection

    private let provider: any Prompt27ScienceResearchProviding
    private let router: Prompt27ContextRouter
    private var loadTask: Task<Void, Never>?

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

    func loadIfNeeded() {
        guard case .idle = state else { return }

        switch router.route(section: section) {
        case .failure:
            state = .unavailable
            return

        case let .success(route):
            state = .loading

            let contentID = section.bodyContentID
            let provider = self.provider

            loadTask = Task { [weak self] in
                do {
                    let content = try await provider.approvedContent(for: contentID)
                    guard !Task.isCancelled else { return }

                    guard !content.sourceIDs.isEmpty else {
                        self?.state = .unavailable
                        return
                    }

                    self?.state = .loaded(content, route)
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.state = .unavailable
                }
            }
        }
    }

    func retry() {
        loadTask?.cancel()
        state = .idle
        loadIfNeeded()
    }

    func selectHotspot(_ id: String?) {
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
#endif
