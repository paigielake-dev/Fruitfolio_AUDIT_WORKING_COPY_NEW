import SwiftUI

/// Shared measured artwork/writing-area composition for taped-white dialogs.
/// Content can grow at accessibility sizes without stretching the artwork.
struct FruitfolioTapedWhitePopup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            let metrics = FruitfolioPopupLayout.tapedWhite(available: geometry.size)
            ZStack {
                FruitfolioImage(id: .popup_taped_white)
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
                .offset(y: metrics.paperSize.height * 0.05)
                .accessibilityIdentifier("tapedWhitePopup.scroll")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
    }
}
