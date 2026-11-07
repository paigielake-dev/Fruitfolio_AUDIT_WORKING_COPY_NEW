import Foundation
#if canImport(Combine)
import Combine
#endif

@MainActor
final class Prompt26PregnancyEducationViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded(Prompt26ApprovedContent)
        case unavailable
    }

    #if canImport(Combine)
    @Published
    #endif
    private(set) var state: LoadState = .idle
    #if canImport(Combine)
    @Published
    #endif
    private(set) var selectedReferencePeriodID: String?

    let topic: Prompt26PregnancyEducationTopic

    private let provider: any Prompt26PregnancyResearchProviding
    private var loadTask: Task<Void, Never>?
    private var loadIdentity = UUID()

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

    @discardableResult
    func loadIfNeeded() -> Task<Void, Never>? {
        guard case .idle = state else { return loadTask }
        loadIdentity = UUID()
        let identity = loadIdentity
        state = .loading
        let contentID = topic.shortContentID
        let provider = self.provider

        loadTask = Task { [weak self] in
            do {
                let content = try await provider.approvedContent(for: contentID)
                guard !Task.isCancelled, let self, self.loadIdentity == identity else { return }
                self.state = content.contentID == contentID ? .loaded(content) : .unavailable
                self.loadTask = nil
            } catch {
                guard !Task.isCancelled, let self, self.loadIdentity == identity else { return }
                self.state = .unavailable
                self.loadTask = nil
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

    func selectReferencePeriod(_ id: String?) {
        selectedReferencePeriodID = id
    }

    var loadedContent: Prompt26ApprovedContent? {
        guard case let .loaded(content) = state else { return nil }
        return content
    }
}
#if canImport(Combine)
extension Prompt26PregnancyEducationViewModel: ObservableObject {}
#endif
