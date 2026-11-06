import SwiftUI

/// Reserved artwork column keeps header text and controls protected at every
/// Dynamic Type size. This header lives outside scrolling content.
struct FruitfolioDecoratedRouteHeader<Header: View>: View {
    let palette: FruitfolioHeaderArtworkPalette
    @ViewBuilder let header: () -> Header

    var body: some View {
        FruitfolioHeaderColumns {
            header()
            GeometryReader { geometry in
                let placements = palette.placements(in: geometry.size)
                ZStack {
                    ForEach(Array(placements.enumerated()), id: \.offset) { _, item in
                        FruitfolioImage(id: item.id)
                            .scaledToFit()
                            .frame(width: item.frame.width, height: item.frame.height)
                            .position(x: item.frame.midX, y: item.frame.midY)
                    }
                }
            }
            .frame(height: 128)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
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
