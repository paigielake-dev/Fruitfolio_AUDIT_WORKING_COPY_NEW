import Foundation

/// One production request factory shared by Tracker and its disposable UI scene.
/// It displays existing engine/UI copy; it does not calculate a new prediction.
@MainActor
enum Prompt16PredictionPopupRequest {
    static func make(info: Prompt16PredictionLearningInfo, id: UUID, scope: UUID,
                     onClose: @escaping @MainActor () -> Void) -> FruitPopupRequest {
        FruitPopupRequest(id: id, character: .peach,
            message: "**" + info.title + "**\n\n" + info.body + "\n\n" + info.progress,
            primaryAction: .init(label: "got it ♡", handler: onClose),
            dismissBehavior: .explicitActionOnly, tone: .informational, priority: .educational,
            source: "cycle-prediction-info", deduplicationKey: "cycle-prediction-info-" + scope.uuidString,
            surface: .woodenSign)
    }
}
