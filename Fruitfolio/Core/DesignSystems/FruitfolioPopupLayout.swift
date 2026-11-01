import SwiftUI

nonisolated struct FruitfolioPopupGeometry {
    let artwork: CGRect
    let writing: CGRect
}

nonisolated enum FruitfolioPopupLayout {
    /// Insets are measured against the actual approved PNG canvas. Notebook
    /// writing stays to the right of its red margin and torn binding holes.
    static func geometry(assetSize: CGSize, normalizedWriting: CGRect,
                         available: CGSize, maximumWidth: CGFloat = 420, edgeClearance: CGFloat = 16) -> FruitfolioPopupGeometry {
        guard assetSize.width > 0, assetSize.height > 0, available.width > 0, available.height > 0 else {
            return .init(artwork: .zero, writing: .zero)
        }
        let width = min(maximumWidth, max(0, available.width - edgeClearance * 2), max(0, available.height - edgeClearance * 2) * assetSize.width / assetSize.height)
        let height = width * assetSize.height / assetSize.width
        let artwork = CGRect(x: (available.width - width) / 2, y: (available.height - height) / 2, width: width, height: height)
        let writing = CGRect(x: artwork.minX + normalizedWriting.minX * width,
                             y: artwork.minY + normalizedWriting.minY * height,
                             width: normalizedWriting.width * width, height: normalizedWriting.height * height)
        return .init(artwork: artwork, writing: writing)
    }
}

/// One content-fit renderer for approved popup artwork. The caller supplies
/// artwork and its calibrated writing region, never feature-specific offsets.
struct FruitfolioPopupArtworkSurface<Content: View>: View {
    let assetName: String
    let normalizedWriting: CGRect
    let maximumWidth: CGFloat
    var mirrorsArtwork = false
    var edgeClearance: CGFloat = 16
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let measured = FruitfolioArtworkGeometryStore.geometry(named: assetName)
            let size = CGSize(width: measured?.width ?? 1, height: measured?.height ?? 1)
            let layout = FruitfolioPopupLayout.geometry(assetSize: size, normalizedWriting: normalizedWriting,
                                                       available: proxy.size, maximumWidth: maximumWidth, edgeClearance: edgeClearance)
            ZStack(alignment: .topLeading) {
                Image(assetName).resizable().scaledToFit()
                    .scaleEffect(x: mirrorsArtwork ? -1 : 1, y: 1)
                    .frame(width: layout.artwork.width, height: layout.artwork.height)
                    .position(x: layout.artwork.midX, y: layout.artwork.midY)
                    .accessibilityHidden(true).allowsHitTesting(false)
                ScrollView(.vertical) {
                    content()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: layout.writing.height, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(width: layout.writing.width, height: layout.writing.height)
                .position(x: layout.writing.midX, y: layout.writing.midY)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}
