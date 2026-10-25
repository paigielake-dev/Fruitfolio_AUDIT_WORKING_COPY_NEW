import SwiftUI

struct Prompt12OwnershipView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Prompt12RouteHeader(
                        title: "Fruitfolio ownership",
                        subtitle: "one little encyclopedia. yours to keep ♡",
                        assetName: "app_cover",
                        onBack: onBack
                    )

                    Prompt12PaperCard {
                        Text(store.ownershipState.displayTitle)
                            .font(.custom("Chalkboard SE", size: 17))
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )

                        Prompt12InfoText(store.ownershipState.displayDetail)

                        Prompt12StatusPill(
                            text: "$9.99 one-time purchase",
                            assetName: "control_check"
                        )
                    }

                    Prompt12PaperCard {
                        Text("no second paywall")
                            .font(.custom("Chalkboard SE", size: 15))
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )

                        Prompt12InfoText(
                            "after the app is legitimately obtained through the storefront, Fruitfolio should open into the experience—not a subscription screen."
                        )
                    }

                    Prompt12PaperCard {
                        Text("restore ≠ sign in")
                            .font(.custom("Chalkboard SE", size: 15))
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )

                        Prompt12InfoText(
                            "storefront ownership restoration and Fruitfolio data restoration are separate ideas. signing in may restore supported data; it is not another purchase."
                        )

                        WatercolorSecondaryButton(label: "check ownership") {
                            audioManager.play(.buttonSoftPop)
                            store.beginQuietOwnershipValidation()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
