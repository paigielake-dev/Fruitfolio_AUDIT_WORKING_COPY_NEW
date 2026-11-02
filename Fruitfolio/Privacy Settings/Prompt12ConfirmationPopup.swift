import SwiftUI

struct Prompt12ConfirmationPopup: View {
    let assetName: String?
    let title: String
    let message: String
    let primaryLabel: String
    let secondaryLabel: String?
    let destructiveLabel: String?
    let primaryAction: () -> Void
    let secondaryAction: (() -> Void)?
    let destructiveAction: (() -> Void)?

    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                if let assetName {
                    Image(assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 58, height: 58)
                        .accessibilityHidden(true)
                }

                FruitfolioNativeActionLabel(text: title,
                    pointSize: 16, textStyle: .headline,
                    lineBreakMode: dynamicTypeSize.isAccessibilitySize ? .byCharWrapping : .byWordWrapping)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityFocused($titleFocused)

                FruitfolioNativeActionLabel(text: message,
                    fontName: "ChalkboardSE-Regular", pointSize: 11.5, textStyle: .body,
                    lineBreakMode: .byWordWrapping)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 275)

                WatercolorPrimaryButton(label: primaryLabel) {
                    primaryAction()
                }

                if let secondaryLabel,
                   let secondaryAction {
                    WatercolorSecondaryButton(label: secondaryLabel) {
                        audioManager.play(.popupClose)
                        secondaryAction()
                    }
                }

                if let destructiveLabel,
                   let destructiveAction {
                    FruitfolioControlPillButton(label: destructiveLabel, playsSound: false) {
                        audioManager.play(.buttonSoftPop)
                        destructiveAction()
                    }
                }
            }
            .padding(.horizontal, dynamicTypeSize.isAccessibilitySize ? 0 : 18)
            .padding(.top, 30)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : 350)
        .accessibilityAction(.escape) { (secondaryAction ?? primaryAction)() }
        .task { await Task.yield(); guard !Task.isCancelled else { return }; titleFocused = true }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}
