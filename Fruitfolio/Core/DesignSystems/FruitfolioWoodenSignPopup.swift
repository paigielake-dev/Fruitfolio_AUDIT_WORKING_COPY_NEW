import SwiftUI

/// Same shared measured-artwork rule as the existing paper families. The original
/// rope, screws and watercolor proportions stay intact; live content scrolls.
struct FruitfolioWoodenSignPopup<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        GeometryReader { geometry in
            let metrics = FruitfolioPopupLayout.woodenSign(available: geometry.size)
            ZStack {
                FruitfolioImage(id: .popup_wooden_sign)
                    .scaledToFit()
                    .frame(width: metrics.paperSize.width, height: metrics.paperSize.height)
                    .accessibilityHidden(true)
                ScrollView(.vertical) {
                    content()
                        .frame(maxWidth: .infinity, minHeight: max(0, metrics.writingSize.height - 8))
                        .padding(.vertical, 4)
                }
                .scrollBounceBehavior(.basedOnSize)
                .frame(width: metrics.writingSize.width, height: metrics.writingSize.height)
                .offset(y: metrics.paperSize.height * (FruitfolioPopupLayout.woodenSignWritingRect.midY - 0.5))
                .accessibilityIdentifier("woodenSignPopup.scroll")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}
