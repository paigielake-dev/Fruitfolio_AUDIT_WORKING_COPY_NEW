import Foundation

/// Geometry follows the preserved 398×380 basket canvas, bottom-aligned inside
/// its existing 132pt container. Mouth coordinates are an engineering registration
/// against that supplied art; simulator/device visual acceptance is still required.
nonisolated struct Prompt28CatchGeometry: Sendable {
    let playfield: CGSize
    var basketWidth: CGFloat { min(playfield.width * 0.36, 150) }
    var basketArtSize: CGSize { .init(width: basketWidth * 0.90, height: basketWidth * 0.90 * 380 / 398) }
    var isValid: Bool { playfield.width.isFinite && playfield.height.isFinite && playfield.width > 0 && playfield.height > 0 }
    var fruitSize: CGFloat { min(max(playfield.width * 0.13, 46), 66) }
    var starSize: CGFloat { min(max(playfield.width * 0.10, 34), 52) }

    func artRect(basketX: Double) -> CGRect {
        let size = basketArtSize
        return CGRect(x: playfield.width * basketX - size.width / 2,
                      y: playfield.height * 0.89 + 66 - size.height, width: size.width, height: size.height)
    }
    func mouth(basketX: Double) -> CGRect {
        Self.mouth(in: artRect(basketX: basketX))
    }
    private static func mouth(in art: CGRect) -> CGRect {
        return CGRect(x: art.minX + art.width * 0.18, y: art.minY + art.height * 0.48,
                      width: art.width * 0.60, height: art.height * 0.18)
    }
    func crossedMouth(x: Double, previousY: Double, currentY: Double, basketX: Double, objectSize: CGFloat) -> Bool {
        guard isValid, [x, previousY, currentY, basketX, Double(objectSize)].allSatisfy(\.isFinite), objectSize > 0 else { return false }
        let opening = mouth(basketX: basketX)
        let leadingEdgeCrossing = (opening.minY - objectSize / 2) / playfield.height
        return previousY <= leadingEdgeCrossing && currentY >= leadingEdgeCrossing && currentY > previousY
            && playfield.width * x >= opening.minX && playfield.width * x <= opening.maxX
    }
    func pose(for transit: Prompt28CatchTransit, basketX: Double, reducedMotion: Bool) -> (center: CGPoint, size: CGSize) {
        Self.pose(for: transit, opening: mouth(basketX: basketX),
                  originalSize: transit.kind == .star ? starSize : fruitSize,
                  offsetWidth: playfield.width, reducedMotion: reducedMotion)
    }
    static func localPose(for transit: Prompt28CatchTransit, basketSize: CGSize, reducedMotion: Bool) -> (center: CGPoint, size: CGSize) {
        let width = basketSize.width * 0.90
        let height = width * 380 / 398
        let art = CGRect(x: (basketSize.width - width) / 2, y: basketSize.height - height, width: width, height: height)
        return pose(for: transit, opening: mouth(in: art), originalSize: transit.kind == .star ? 52 : 66,
                    offsetWidth: basketSize.width, reducedMotion: reducedMotion)
    }
    private static func pose(for transit: Prompt28CatchTransit, opening: CGRect, originalSize: CGFloat,
                             offsetWidth: CGFloat, reducedMotion: Bool) -> (center: CGPoint, size: CGSize) {
        let progress = reducedMotion ? 1 : transit.progress
        let width = originalSize * (1 - 0.42 * progress)
        let height = originalSize * (1 - 0.62 * progress)
        let allowableOffset = max(0, opening.width / 2 - originalSize * 0.58 / 2)
        let originalOffset = CGFloat(transit.relativeX) * offsetWidth
        let finalOffset = min(max(originalOffset, -allowableOffset), allowableOffset)
        let offset = originalOffset + (finalOffset - originalOffset) * progress
        let start = opening.minY - originalSize / 2
        // Whole transformed item is below the rim before completion is awarded.
        let end = max(opening.minY + height / 2, opening.minY + opening.height * 0.68)
        return (CGPoint(x: opening.midX + offset, y: start + (end - start) * progress), CGSize(width: width, height: height))
    }
}

nonisolated struct Prompt28CatchTransit: Identifiable, Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case fruit(Prompt28FruitID, Prompt28FruitClassification)
        case star
    }
    static let entryDuration: TimeInterval = 0.24
    static let duration: TimeInterval = 0.36
    let id: UUID
    let kind: Kind
    let relativeX: Double
    private(set) var elapsed: TimeInterval = 0
    var progress: Double { min(max(elapsed / Self.entryDuration, 0), 1) }
    mutating func advance(by delta: TimeInterval) -> Bool {
        guard delta.isFinite, delta > 0, elapsed < Self.duration else { return false }
        elapsed = min(Self.duration, elapsed + delta)
        return elapsed == Self.duration
    }
}

nonisolated struct Prompt28RareStarPlanner: Sendable {
    static let minimumFruitSpacing = 8
    static let probability = 0.05
    private(set) var fruitDropsSinceStar = 0
    mutating func shouldDropStar(randomUnit: Double) -> Bool {
        guard randomUnit.isFinite, (0...1).contains(randomUnit) else { return false }
        if fruitDropsSinceStar >= Self.minimumFruitSpacing && randomUnit < Self.probability {
            fruitDropsSinceStar = 0
            return true
        }
        // This spacing counter is not a cap on earned stars or banked passes.
        fruitDropsSinceStar = min(fruitDropsSinceStar + 1, Self.minimumFruitSpacing)
        return false
    }
}
