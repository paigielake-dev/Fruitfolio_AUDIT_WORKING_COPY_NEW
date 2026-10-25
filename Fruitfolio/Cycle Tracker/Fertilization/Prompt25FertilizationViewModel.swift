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
        loadGeneration += 1
        let generation = loadGeneration
        contentState = .loading

        let loaded = await contentProvider.content(for: stage)

        guard generation == loadGeneration else { return }

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

        isTransitioning = true
        isExpanded = false
        showsRelatedTopics = false
        content = .unavailable
        contentState = .idle

        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.36)) {
                stageID = newStage
            }

            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(380))
                isTransitioning = false
                completion()
            }
        } else {
            stageID = newStage
            isTransitioning = false
            completion()
        }
    }

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
