import Foundation

/// Scientific plates preserve the entire source canvas. This policy never crops,
/// stretches, decorates, or relocates an anatomical detail independently.
nonisolated enum FruitfolioScientificArtSizing {
    static func fit(intrinsic: CGSize, availableWidth: CGFloat?, availableHeight: CGFloat?,
                    maximumWidth: CGFloat, maximumHeight: CGFloat) -> CGSize {
        guard [intrinsic.width, intrinsic.height, maximumWidth, maximumHeight].allSatisfy({ $0.isFinite && $0 > 0 }) else { return .zero }
        func limit(_ proposed: CGFloat?, maximum: CGFloat) -> CGFloat {
            guard let proposed else { return maximum }
            if proposed == .infinity { return maximum }
            guard proposed.isFinite else { return 0 }
            return min(max(proposed, 0), maximum)
        }
        let width = limit(availableWidth, maximum: maximumWidth)
        let height = limit(availableHeight, maximum: maximumHeight)
        let scale = min(width / intrinsic.width, height / intrinsic.height)
        guard scale.isFinite && scale > 0 else { return .zero }
        return CGSize(width: intrinsic.width * scale, height: intrinsic.height * scale)
    }
}
