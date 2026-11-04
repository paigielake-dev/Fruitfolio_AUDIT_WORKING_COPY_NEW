import SwiftUI

struct FruitfolioProtectedTextAnchors: PreferenceKey {
    static let defaultValue: [Anchor<CGRect>] = []
    static func reduce(value: inout [Anchor<CGRect>], nextValue: () -> [Anchor<CGRect>]) { value += nextValue() }
}

extension View {
    func fruitfolioProtectFromDecoration() -> some View {
        anchorPreference(key: FruitfolioProtectedTextAnchors.self, value: .bounds) { [$0] }
    }
}

struct FruitfolioProtectedHeader<Header: View, Decoration: View>: View {
    @ViewBuilder let header: () -> Header
    @ViewBuilder let decoration: ([CGRect], UUID) -> Decoration
    @State private var space = UUID()

    var body: some View {
        header()
            .overlayPreferenceValue(FruitfolioProtectedTextAnchors.self) { anchors in
                GeometryReader { geometry in
                    decoration(anchors.map { geometry[$0] }, space)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topTrailing)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
            .coordinateSpace(name: space)
    }
}

private struct FruitfolioDecorationFrameKey: PreferenceKey {
    static let defaultValue = CGRect.zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

private struct FruitfolioDecorationGuard: ViewModifier {
    let protected: [CGRect]
    let space: UUID
    let assetName: String?
    @State private var frame = CGRect.zero

    func body(content: Content) -> some View {
        let measured = assetName.flatMap { FruitfolioArtworkGeometryStore.geometry(named: $0) }
        let alpha = measured?.paintedBounds(in: frame.size) ?? CGRect(origin: .zero, size: frame.size)
        let footprint = alpha.offsetBy(dx: frame.minX, dy: frame.minY)
        content
            .background { GeometryReader { geometry in
                Color.clear.preference(key: FruitfolioDecorationFrameKey.self, value: geometry.frame(in: .named(space)))
            } }
            .onPreferenceChange(FruitfolioDecorationFrameKey.self) { frame = $0 }
            .opacity(!frame.isEmpty && FruitfolioDecorativeArtLayout.isCollisionFree(
                paintedFrame: footprint, protectedRegions: protected.map { .init(rect: $0) }, minimumGap: 4) ? 1 : 0)
            .allowsHitTesting(false).accessibilityHidden(true)
    }
}

extension View {
    func fruitfolioAvoidProtectedContent(_ rects: [CGRect], in space: UUID, assetName: String? = nil) -> some View {
        modifier(FruitfolioDecorationGuard(protected: rects, space: space, assetName: assetName))
    }
}
