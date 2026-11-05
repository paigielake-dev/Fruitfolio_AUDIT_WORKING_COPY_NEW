import SwiftUI

/// Explicit approved compositions; no generated or silently substituted art.
enum FruitfolioHeaderArtworkPalette {
    case contact, settings, faq

    var items: [Item] {
        switch self {
        case .contact:
            return [
                Item(id: .fruitbasket_plum, pixels: CGSize(width: 364, height: 361), role: 0.45...0.62, anchor: .bottomTrailing),
                Item(id: .cycledecor_green_flecks, pixels: CGSize(width: 289, height: 342), role: 0.20...0.40, anchor: .topLeading),
                Item(id: .decor_sparkles_2, pixels: CGSize(width: 1323, height: 1189), role: 0.18...0.28, anchor: .topTrailing)
            ]
        case .settings:
            return [
                Item(id: .cycledecor_flower, pixels: CGSize(width: 258, height: 304), role: 0.42...0.55, anchor: .bottomTrailing),
                Item(id: .cycledecor_lavender_droplets, pixels: CGSize(width: 295, height: 402), role: 0.20...0.36, anchor: .topLeading),
                Item(id: .decor_sparkles_2, pixels: CGSize(width: 1323, height: 1189), role: 0.18...0.28, anchor: .topTrailing)
            ]
        case .faq:
            // The supplied registry has no canonical tulip or decor_fluffy_cloud.
            // Keep the approved sparkles; never replace the missing tulip with
            // an unrelated flower, fruit cluster, or rain cloud.
            return [Item(id: .decor_sparkles_1, pixels: CGSize(width: 1323, height: 1189), role: 0.35...0.55, anchor: .topTrailing)]
        }
    }

    struct Item {
        let id: FruitfolioAssetID
        let pixels: CGSize
        let role: ClosedRange<CGFloat>
        let anchor: FruitfolioDecorativeAnchor
    }
}

/// Reserved artwork column keeps header text and controls protected at every
/// Dynamic Type size. This header lives outside scrolling content.
struct FruitfolioDecoratedRouteHeader<Header: View>: View {
    let palette: FruitfolioHeaderArtworkPalette
    @ViewBuilder let header: () -> Header

    var body: some View {
        FruitfolioHeaderColumns {
            header()
            GeometryReader { geometry in
                let placements = placements(in: geometry.size)
                ZStack {
                    ForEach(Array(placements.enumerated()), id: \.offset) { _, item in
                        FruitfolioImage(id: item.0)
                            .scaledToFit()
                            .frame(width: item.1.width, height: item.1.height)
                            .position(x: item.1.midX, y: item.1.midY)
                    }
                }
            }
            .frame(height: 128)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private func placements(in size: CGSize) -> [(FruitfolioAssetID, CGRect)] {
        var protected: [FruitfolioProtectedRegion] = []
        var result: [(FruitfolioAssetID, CGRect)] = []
        for item in palette.items {
            let placement = FruitfolioDecorativeArtLayout.placement(
                intrinsicSize: item.pixels, roleFraction: item.role, anchor: item.anchor,
                container: CGRect(origin: .zero, size: size), safeInsets: .init(),
                protectedRegions: protected, minimumGap: 6)
            if placement.isVisible {
                result.append((item.id, placement.frame))
                protected.append(.init(rect: placement.frame))
            }
        }
        return result
    }
}

private struct FruitfolioHeaderColumns: Layout {
    private func widths(_ proposal: ProposedViewSize) -> (CGFloat, CGFloat) {
        let width = max(0, proposal.width ?? 353)
        return (width, min(136, width * 0.32))
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let (width, art) = widths(proposal)
        let text = subviews[0].sizeThatFits(ProposedViewSize(width: width - art, height: nil))
        return CGSize(width: width, height: max(128, text.height))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let (_, art) = widths(ProposedViewSize(width: bounds.width, height: bounds.height))
        subviews[0].place(at: bounds.origin, anchor: .topLeading,
                          proposal: ProposedViewSize(width: bounds.width - art, height: bounds.height))
        subviews[1].place(at: CGPoint(x: bounds.maxX - art, y: bounds.minY), anchor: .topLeading,
                          proposal: ProposedViewSize(width: art, height: 128))
    }
}
