import SwiftUI

/// The preserved large control/contact-card artwork, with a bounded writing
/// aperture. Large text scrolls without stretching the source painted border.
struct FruitfolioLargeControlCardPopup<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        GeometryReader { geometry in
            let metrics = FruitfolioPopupLayout.largeControlCard(available: geometry.size)
            ZStack {
                FruitfolioImage(id: .control_large_card)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}
