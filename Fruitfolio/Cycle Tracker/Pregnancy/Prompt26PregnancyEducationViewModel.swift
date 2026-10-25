#if canImport(SwiftUI)
import Foundation
import SwiftUI
import Combine

@MainActor
final class Prompt26PregnancyEducationViewModel: ObservableObject {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(Prompt26ApprovedContent)
        case unavailable
    }

    @Published private(set) var state: LoadState = .idle
    @Published private(set) var selectedReferencePeriodID: String?

    let topic: Prompt26PregnancyEducationTopic

    private let provider: any Prompt26PregnancyResearchProviding
    private var loadTask: Task<Void, Never>?

    init(
        topic: Prompt26PregnancyEducationTopic,
        provider: any Prompt26PregnancyResearchProviding
    ) {
        self.topic = topic
        self.provider = provider
    }

    deinit {
        loadTask?.cancel()
    }

    func loadIfNeeded() {
        guard case .idle = state else { return }
        state = .loading
        let contentID = topic.shortContentID
        let provider = self.provider

        loadTask = Task { [weak self] in
            do {
                let content = try await provider.approvedContent(for: contentID)
                guard !Task.isCancelled else { return }
                self?.state = .loaded(content)
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .unavailable
            }
        }
    }

    func retry() {
        loadTask?.cancel()
        state = .idle
        loadIfNeeded()
    }

    func selectReferencePeriod(_ id: String?) {
        selectedReferencePeriodID = id
    }

    var loadedContent: Prompt26ApprovedContent? {
        guard case let .loaded(content) = state else { return nil }
        return content
    }
}
#endif
