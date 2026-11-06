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
    let paintedFrame: CGRect
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
            return .init(frame: .zero, paintedFrame: .zero, isVisible: false)
        }

        let safe = CGRect(
            x: container.minX + max(safeInsets.leading, 16),
            y: container.minY + max(safeInsets.top, 16),
            width: max(0, container.width - max(safeInsets.leading, 16) - max(safeInsets.trailing, 16)),
            height: max(0, container.height - max(safeInsets.top, 16) - max(safeInsets.bottom, 16))
        )
        guard safe.width > 0, safe.height > 0 else { return .init(frame: .zero, paintedFrame: .zero, isVisible: false) }

        let intrinsicBounds = CGRect(origin: .zero, size: intrinsicSize)
        let alpha = (visibleAlphaBounds ?? intrinsicBounds).intersection(intrinsicBounds)
        guard !alpha.isNull, !alpha.isEmpty,
              [alpha.minX, alpha.minY, alpha.width, alpha.height].allSatisfy({ $0.isFinite }) else {
            return .init(frame: .zero, paintedFrame: .zero, isVisible: false)
        }
        let aspect = intrinsicSize.width / intrinsicSize.height
        let minimumWidth = safe.width * roleFraction.lowerBound
        let preferredWidth = safe.width * roleFraction.upperBound
        // Only resize within the approved role, at the original anchor. Never
        // move art to an unrelated corner or shrink it indefinitely to fit.
        let heightConstrainedWidth = min(preferredWidth, safe.height * aspect)
        guard heightConstrainedWidth >= minimumWidth else {
            return .init(frame: .zero, paintedFrame: .zero, isVisible: false)
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
                return .init(frame: frame, paintedFrame: painted, isVisible: true)
            }
        }
        return .init(frame: .zero, paintedFrame: .zero, isVisible: false)
    }
}

/// Explicit approved compositions; no generated or silently substituted art.
enum FruitfolioHeaderArtworkPalette: CaseIterable {
    case contact, settings, faq

    var items: [Item] {
        switch self {
        case .contact:
            return [
                Item(id: .fruitbasket_plum, pixels: CGSize(width: 364, height: 361), paintedBounds: CGRect(x: 22, y: 3, width: 266, height: 341), role: 0.45...0.62, anchor: .bottomTrailing),
                Item(id: .cycledecor_green_flecks, pixels: CGSize(width: 289, height: 342), paintedBounds: CGRect(x: 33, y: 69, width: 224, height: 228), role: 0.20...0.40, anchor: .topLeading),
                Item(id: .decor_sparkles_2, pixels: CGSize(width: 1323, height: 1189), paintedBounds: CGRect(x: 224, y: 258, width: 872, height: 700), role: 0.18...0.28, anchor: .topTrailing)
            ]
        case .settings:
            return [
                Item(id: .cycledecor_flower, pixels: CGSize(width: 258, height: 304), paintedBounds: CGRect(x: 40, y: 72, width: 178, height: 175), role: 0.42...0.55, anchor: .bottomTrailing),
                Item(id: .cycledecor_lavender_droplets, pixels: CGSize(width: 295, height: 402), paintedBounds: CGRect(x: 27, y: 42, width: 262, height: 328), role: 0.20...0.36, anchor: .topLeading),
                Item(id: .decor_sparkles_2, pixels: CGSize(width: 1323, height: 1189), paintedBounds: CGRect(x: 224, y: 258, width: 872, height: 700), role: 0.18...0.28, anchor: .topTrailing)
            ]
        case .faq:
            // The supplied registry has no canonical tulip or decor_fluffy_cloud.
            // Keep the approved sparkles; never replace the missing tulip with
            // an unrelated flower, fruit cluster, or rain cloud.
            return [Item(id: .decor_sparkles_1, pixels: CGSize(width: 1323, height: 1189), paintedBounds: CGRect(x: 224, y: 258, width: 872, height: 700), role: 0.35...0.55, anchor: .topTrailing)]
        }
    }

    struct Placement {
        let id: FruitfolioAssetID
        let frame: CGRect
        let paintedFrame: CGRect
    }

    func placements(in size: CGSize) -> [Placement] {
        var protected: [FruitfolioProtectedRegion] = []
        var result: [Placement] = []
        for item in items {
            let placement = FruitfolioDecorativeArtLayout.placement(
                intrinsicSize: item.pixels, visibleAlphaBounds: item.paintedBounds,
                roleFraction: item.role, anchor: item.anchor,
                container: CGRect(origin: .zero, size: size), safeInsets: .init(),
                protectedRegions: protected, minimumGap: 6)
            if placement.isVisible {
                result.append(.init(id: item.id, frame: placement.frame, paintedFrame: placement.paintedFrame))
                protected.append(.init(rect: placement.paintedFrame))
            }
        }
        return result
    }

    struct Item {
        let id: FruitfolioAssetID
        let pixels: CGSize
        // Bounding box at alpha >12/255, measured from the unchanged PNG.
        let paintedBounds: CGRect
        let role: ClosedRange<CGFloat>
        let anchor: FruitfolioDecorativeAnchor
    }
}
