import SwiftUI

struct Prompt12PrivacyView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Prompt12RouteHeader(
                            title: "privacy",
                            subtitle: "clear boundaries for personal things",
                            assetName: "fruit_peach_soft",
                            onBack: onBack
                        )

                        FruitfolioImage(id: .decor_sparkles_2)
                            .frame(width: 88, height: 88)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(x: 74, y: -12)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    Prompt12PaperCard {
                        title("what Fruitfolio stores")
                        Prompt12InfoText(
                            "Fruitfolio may store saved encyclopedias, guide organization, preferences, account state, and cycle data when those features are used."
                        )
                    }

                    Prompt12PaperCard {
                        title("account ≠ health profile")
                        Prompt12InfoText(
                            "your account identifies access and supported sync. it should not become one giant record containing every question, symptom, cycle log, and guide just because that is convenient."
                        )
                    }

                    Prompt12PaperCard {
                        title("Ask boundaries")
                        Prompt12InfoText(
                            "Ask uses the approved FruitsofLife.xo knowledge architecture. private questions and saved items must remain separate from marketing analytics."
                        )
                    }

                    Prompt12PaperCard {
                        title("cycle data")
                        Prompt12InfoText(
                            "cycle information is personal. recorded observations, calculated values, estimates, and exports keep their provenance and scope separate."
                        )
                    }

                    Prompt12PaperCard {
                        title("lock-screen privacy")

                        WatercolorToggle(
                            label: "private notification wording",
                            isOn: $store.usePrivacyModeOnLockScreen
                        )

                        Prompt12InfoText(
                            "notification copy should avoid exposing reproductive-health details by default."
                        )
                    }

                    Text(
                        "final legal privacy copy should be reviewed before release. this screen is product architecture, not legal advice."
                    )
                    .font(.custom("Chalkboard SE", size: 10.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func title(
        _ text: String
    ) -> some View {
        Text(text)
            .font(.custom("Chalkboard SE", size: 15))
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
    }
}
