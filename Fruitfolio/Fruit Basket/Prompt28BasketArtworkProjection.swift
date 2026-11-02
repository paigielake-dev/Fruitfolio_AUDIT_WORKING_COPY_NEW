import Foundation

/// A bounded drawing projection of actual records, never an allowed fruit pool.
/// Pending artwork is always retained so its real settling acknowledgement can
/// register the catch. Extra already-collected stars are represented by a count.
struct Prompt28BasketArtworkProjection {
    let visibleCatches: [Prompt28SettledCatch]
    let additionalCollectedStars: Int
    let registeredStars: Int

    init(catches: [Prompt28SettledCatch], maximumVisibleCollectedStars: Int = 8) {
        let stars = catches.filter { $0.isStar && $0.collected }
        let visibleStarIDs = Set(stars.suffix(max(0, maximumVisibleCollectedStars)).map(\.id))
        visibleCatches = catches.filter { !$0.isStar || !$0.collected || visibleStarIDs.contains($0.id) }
        registeredStars = stars.count
        additionalCollectedStars = stars.count - visibleStarIDs.count
    }
}
