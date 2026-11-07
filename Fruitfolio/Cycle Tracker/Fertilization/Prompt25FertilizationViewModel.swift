import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt25FertilizationViewModel: ObservableObject {
    @Published private(set) var stageID: Prompt25FertilizationStageID
    @Published private(set) var content: Prompt25EducationalContent = .unavailable
    @Published private(set) var contentState: ContentState = .idle
    @Published var isExpanded = false
    @Published var showsRelatedTopics = false
    @Published private(set) var isTransitioning = false

    enum ContentState: Equatable {
        case idle
        case loading
        case loaded
        case unavailable
    }

    private let contentProvider: any Prompt25FertilizationContentProviding
    private var loadGeneration = 0
    private var transitionTask: Task<Void, Never>?
    private var transitionID = UUID()
    private var transitionCompletion: (@MainActor () -> Void)?

    init(
        initialStage: Prompt25FertilizationStageID,
        contentProvider: any Prompt25FertilizationContentProviding
    ) {
        self.stageID = initialStage
        self.contentProvider = contentProvider
    }

    var stage: Prompt25FertilizationStage {
        Prompt25FertilizationSequence.stage(for: stageID)
    }

    var stageIndex: Int {
        Prompt25FertilizationSequence.index(of: stageID)
    }

    var canGoPrevious: Bool {
        Prompt25FertilizationSequence.previous(from: stageID) != nil
    }

    var canGoNext: Bool {
        Prompt25FertilizationSequence.next(from: stageID) != nil
    }

    func loadContent() async {
        guard !Task.isCancelled else { return }
        loadGeneration += 1
        let generation = loadGeneration
        let requestedStage = stage
        contentState = .loading
        guard !Task.isCancelled, generation == loadGeneration,
              requestedStage.id == stageID else { return }

        let loaded = await contentProvider.content(for: requestedStage)

        guard !Task.isCancelled, generation == loadGeneration,
              requestedStage.id == stageID else { return }

        content = loaded
        contentState = loaded.isApproved ? .loaded : .unavailable
    }

    func setStage(
        _ newStage: Prompt25FertilizationStageID,
        animated: Bool,
        reduceMotion: Bool,
        completion: @escaping @MainActor () -> Void = {}
    ) {
        guard !isTransitioning, newStage != stageID else { return }

        // Invalidate before publishing the stage; an old provider may finish
        // before SwiftUI starts the replacement stage task.
        loadGeneration += 1
        transitionTask?.cancel()
        transitionID = UUID()
        let expectedTransition = transitionID
        transitionCompletion = completion
        isTransitioning = true
        isExpanded = false
        showsRelatedTopics = false
        content = .unavailable
        contentState = .idle

        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.36)) {
                stageID = newStage
            }

            transitionTask = Task { @MainActor [weak self] in
                do { try await Task.sleep(for: .milliseconds(380)) }
                catch { return }
                guard !Task.isCancelled else { return }
                self?.finishTransition(expected: expectedTransition)
            }
        } else {
            stageID = newStage
            finishTransition(expected: expectedTransition)
        }
    }

    private func finishTransition(expected: UUID) {
        guard transitionID == expected, isTransitioning else { return }
        transitionTask = nil
        let completion = transitionCompletion
        transitionCompletion = nil
        isTransitioning = false
        completion?()
    }

    func settleTransitionForReducedMotion() {
        transitionTask?.cancel()
        finishTransition(expected: transitionID)
    }

    /// Keep the selected logical stage while dropping hidden/stale publications
    /// and deferred caller actions. The visible owner can reload on return.
    func suspendPresentation() {
        loadGeneration += 1
        transitionID = UUID()
        transitionTask?.cancel()
        transitionTask = nil
        transitionCompletion = nil
        isTransitioning = false
        if contentState == .loading { contentState = .idle }
    }

    deinit { transitionTask?.cancel() }

    func previous(
        reduceMotion: Bool,
        completion: @escaping @MainActor () -> Void = {}
    ) {
        guard let previous =
            Prompt25FertilizationSequence.previous(from: stageID)
        else {
            return
        }

        setStage(
            previous,
            animated: true,
            reduceMotion: reduceMotion,
            completion: completion
        )
    }

    func next(
        reduceMotion: Bool,
        completion: @escaping @MainActor () -> Void = {}
    ) {
        guard let next =
            Prompt25FertilizationSequence.next(from: stageID)
        else {
            return
        }

        setStage(
            next,
            animated: true,
            reduceMotion: reduceMotion,
            completion: completion
        )
    }
}
