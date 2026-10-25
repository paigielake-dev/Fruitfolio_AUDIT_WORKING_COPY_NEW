import SwiftUI

struct FruitfolioProtectedRegion: Hashable {
    let rect: CGRect
}

enum FruitfolioDecorativeAnchor: Hashable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing, bottomCenter, center
}

struct FruitfolioDecorativePlacement {
    let frame: CGRect
    let isVisible: Bool
}

/// Shared geometry authority for decorative art. Screen-level art selection,
/// side, rotation and semantic relationship remain founder-owned at call sites.
enum FruitfolioDecorativeArtLayout {
    static func placement(
        intrinsicSize: CGSize,
        visibleAlphaBounds: CGRect? = nil,
        roleFraction: ClosedRange<CGFloat>,
        anchor: FruitfolioDecorativeAnchor,
        container: CGRect,
        safeInsets: EdgeInsets,
        protectedRegions: [FruitfolioProtectedRegion],
        minimumGap: CGFloat = 12
    ) -> FruitfolioDecorativePlacement {
        guard intrinsicSize.width > 0, intrinsicSize.height > 0,
              container.width > 0, container.height > 0 else {
            return .init(frame: .zero, isVisible: false)
        }

        let safe = CGRect(
            x: container.minX + max(safeInsets.leading, 16),
            y: container.minY + max(safeInsets.top, 16),
            width: max(0, container.width - max(safeInsets.leading, 16) - max(safeInsets.trailing, 16)),
            height: max(0, container.height - max(safeInsets.top, 16) - max(safeInsets.bottom, 16))
        )
        guard safe.width > 0, safe.height > 0 else { return .init(frame: .zero, isVisible: false) }

        let aspect = intrinsicSize.width / intrinsicSize.height
        let preferred = safe.width * roleFraction.upperBound
        let minimum = safe.width * roleFraction.lowerBound
        let targetWidth = min(safe.width, max(minimum, preferred))
        let targetHeight = targetWidth / aspect
        guard targetHeight <= safe.height else { return .init(frame: .zero, isVisible: false) }

        func origin(for anchor: FruitfolioDecorativeAnchor) -> CGPoint {
            switch anchor {
            case .topLeading: return .init(x: safe.minX, y: safe.minY)
            case .topTrailing: return .init(x: safe.maxX - targetWidth, y: safe.minY)
            case .bottomLeading: return .init(x: safe.minX, y: safe.maxY - targetHeight)
            case .bottomTrailing: return .init(x: safe.maxX - targetWidth, y: safe.maxY - targetHeight)
            case .bottomCenter: return .init(x: safe.midX - targetWidth / 2, y: safe.maxY - targetHeight)
            case .center: return .init(x: safe.midX - targetWidth / 2, y: safe.midY - targetHeight / 2)
            }
        }

        let candidate = CGRect(origin: origin(for: anchor), size: .init(width: targetWidth, height: targetHeight))
        let alpha = visibleAlphaBounds ?? CGRect(origin: .zero, size: intrinsicSize)
        let sx = targetWidth / intrinsicSize.width
        let sy = targetHeight / intrinsicSize.height
        let visibleFrame = CGRect(
            x: candidate.minX + alpha.minX * sx,
            y: candidate.minY + alpha.minY * sy,
            width: alpha.width * sx,
            height: alpha.height * sy
        )
        let collisionFrame = visibleFrame.insetBy(dx: -minimumGap, dy: -minimumGap)
        let collides = protectedRegions.contains { $0.rect.intersects(collisionFrame) }
        return .init(frame: candidate, isVisible: !collides && safe.contains(visibleFrame))
    }
}
