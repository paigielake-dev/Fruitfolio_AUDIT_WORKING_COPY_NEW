import Foundation

struct FruitfolioArtInsets {
    var top: CGFloat = 0
    var leading: CGFloat = 0
    var bottom: CGFloat = 0
    var trailing: CGFloat = 0
}

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
        safeInsets: FruitfolioArtInsets,
        protectedRegions: [FruitfolioProtectedRegion],
        minimumGap: CGFloat = 12
    ) -> FruitfolioDecorativePlacement {
        let values = [intrinsicSize.width, intrinsicSize.height, container.minX, container.minY,
                      container.width, container.height, roleFraction.lowerBound, roleFraction.upperBound,
                      safeInsets.leading, safeInsets.trailing, safeInsets.top, safeInsets.bottom, minimumGap]
        guard values.allSatisfy({ $0.isFinite }),
              intrinsicSize.width > 0, intrinsicSize.height > 0,
              container.width > 0, container.height > 0,
              roleFraction.lowerBound > 0, roleFraction.upperBound <= 1 else {
            return .init(frame: .zero, isVisible: false)
        }

        let safe = CGRect(
            x: container.minX + max(safeInsets.leading, 16),
            y: container.minY + max(safeInsets.top, 16),
            width: max(0, container.width - max(safeInsets.leading, 16) - max(safeInsets.trailing, 16)),
            height: max(0, container.height - max(safeInsets.top, 16) - max(safeInsets.bottom, 16))
        )
        guard safe.width > 0, safe.height > 0 else { return .init(frame: .zero, isVisible: false) }

        let intrinsicBounds = CGRect(origin: .zero, size: intrinsicSize)
        let alpha = (visibleAlphaBounds ?? intrinsicBounds).intersection(intrinsicBounds)
        guard !alpha.isNull, !alpha.isEmpty,
              [alpha.minX, alpha.minY, alpha.width, alpha.height].allSatisfy({ $0.isFinite }) else {
            return .init(frame: .zero, isVisible: false)
        }
        let aspect = intrinsicSize.width / intrinsicSize.height
        let minimumWidth = safe.width * roleFraction.lowerBound
        let preferredWidth = safe.width * roleFraction.upperBound
        // Only resize within the approved role, at the original anchor. Never
        // move art to an unrelated corner or shrink it indefinitely to fit.
        let heightConstrainedWidth = min(preferredWidth, safe.height * aspect)
        guard heightConstrainedWidth >= minimumWidth else {
            return .init(frame: .zero, isVisible: false)
        }
        let widths = [heightConstrainedWidth, (heightConstrainedWidth + minimumWidth) / 2, minimumWidth]
        for width in widths {
            let height = width / aspect
            let origin: CGPoint
            switch anchor {
            case .topLeading: origin = .init(x: safe.minX, y: safe.minY)
            case .topTrailing: origin = .init(x: safe.maxX - width, y: safe.minY)
            case .bottomLeading: origin = .init(x: safe.minX, y: safe.maxY - height)
            case .bottomTrailing: origin = .init(x: safe.maxX - width, y: safe.maxY - height)
            case .bottomCenter: origin = .init(x: safe.midX - width / 2, y: safe.maxY - height)
            case .center: origin = .init(x: safe.midX - width / 2, y: safe.midY - height / 2)
            }
            let frame = CGRect(origin: origin, size: CGSize(width: width, height: height))
            let scale = width / intrinsicSize.width
            let painted = CGRect(x: frame.minX + alpha.minX * scale,
                                 y: frame.minY + alpha.minY * scale,
                                 width: alpha.width * scale, height: alpha.height * scale)
            let collision = painted.insetBy(dx: -max(0, minimumGap), dy: -max(0, minimumGap))
            if safe.contains(painted), !protectedRegions.contains(where: { $0.rect.intersects(collision) }) {
                return .init(frame: frame, isVisible: true)
            }
        }
        return .init(frame: .zero, isVisible: false)
    }
}
