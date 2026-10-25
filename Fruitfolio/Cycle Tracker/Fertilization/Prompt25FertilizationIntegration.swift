import SwiftUI

/// Thin integration wrapper for the existing Encyclopedia architecture.
///
/// The wrapper deliberately uses closures instead of creating a second
/// navigation/source/save/Ask system. Wire each closure to the already-established
/// Fruitfolio destination in the app target.

nonisolated enum Prompt25ContextualEducationSurface {
    static func shouldSurface(
        policy: Prompt27AContextPolicyResult
    ) -> Bool {
        policy[.fertilizationEducation].effect == .surface
    }
}

@MainActor
struct Prompt25FertilizationModule: View {
    let initialStage: Prompt25FertilizationStageID
    let contentProvider: any Prompt25FertilizationContentProviding
    let onBack: () -> Void
    let onSources: (Prompt25FertilizationStage) -> Void
    let onAsk: (Prompt25FertilizationStage) -> Void
    let onSave: (Prompt25FertilizationStage) -> Void
    let onRelatedTopic: (Prompt25RelatedTopic) -> Void
    let onPageSound: () -> Void

    init(
        initialStage: Prompt25FertilizationStageID = .oocyte,
        contentProvider: any Prompt25FertilizationContentProviding =
            Prompt25UnavailableContentProvider(),
        onBack: @escaping () -> Void = {},
        onSources: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onAsk: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onSave: @escaping (Prompt25FertilizationStage) -> Void = { _ in },
        onRelatedTopic: @escaping (Prompt25RelatedTopic) -> Void = { _ in },
        onPageSound: @escaping () -> Void = {}
    ) {
        self.initialStage = initialStage
        self.contentProvider = contentProvider
        self.onBack = onBack
        self.onSources = onSources
        self.onAsk = onAsk
        self.onSave = onSave
        self.onRelatedTopic = onRelatedTopic
        self.onPageSound = onPageSound
    }

    var body: some View {
        Prompt25FertilizationView(
            initialStage: initialStage,
            contentProvider: contentProvider,
            onBack: onBack,
            onSources: onSources,
            onAsk: onAsk,
            onSave: onSave,
            onRelatedTopic: onRelatedTopic,
            onPageSound: onPageSound
        )
    }
}
