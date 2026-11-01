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

                Text(title)
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.custom("Chalkboard SE", size: 11.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
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
                    Button(destructiveLabel) {
                        audioManager.play(.buttonSoftPop)
                        destructiveAction()
                    }
                    .font(.custom("Chalkboard SE", size: 11.5))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                    .buttonStyle(CutePopButtonStyle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 30)
            .padding(.bottom, 28)
        }
        .frame(maxWidth: 350)
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}
