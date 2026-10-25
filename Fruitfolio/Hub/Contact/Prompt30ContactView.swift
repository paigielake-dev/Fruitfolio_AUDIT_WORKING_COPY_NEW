import SwiftUI

struct Prompt30ContactView: View {
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL

    private let instagramURL = URL(string: "https://www.instagram.com/fruitsoflife.xo")!
    private let tiktokURL = URL(string: "https://www.tiktok.com/@fruitsoflife.xo?lang=en")!
    private let emailURL = URL(string: "mailto:fruitsoflifexo@gmail.com")!
    private let carrdURL = URL(string: "https://fruitsoflifexo.carrd.co")!

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .topTrailing) {
                        Prompt12RouteHeader(
                            title: "contact",
                            subtitle: "questions, feedback, or just a little hello ♡",
                            assetName: nil,
                            onBack: onBack
                        )

                        HStack(spacing: -7) {
                            FruitfolioImage(id: .fruitbasket_watermelon)
                                .frame(width: 52, height: 52)

                            FruitfolioImage(id: .fruitbasket_grape)
                                .frame(width: 46, height: 46)

                            FruitfolioImage(id: .fruitbasket_star)
                                .frame(width: 22, height: 22)
                                .offset(y: -13)
                        }
                        .padding(.top, 2)
                        .padding(.trailing, 2)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)

                        FruitfolioImage(id: .decor_sparkles_2)
                            .frame(width: 92, height: 92)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(x: 72, y: -14)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }

                    VStack(spacing: 4) {
                        FruitfolioControlPillButton(label: "Instagram  •  @fruitsoflife.xo") { openURL(instagramURL) }
                        FruitfolioControlPillButton(label: "TikTok  •  @fruitsoflife.xo") { openURL(tiktokURL) }
                        FruitfolioControlPillButton(label: "email  •  fruitsoflifexo@gmail.com") { openURL(emailURL) }
                        FruitfolioControlPillButton(label: "FruitsofLife.xo Carrd") { openURL(carrdURL) }
                    }

                    Text("Fruitfolio is educational. For personal medical questions, diagnosis, treatment, or urgent concerns, contact an appropriate healthcare professional or emergency service.")
                        .font(.custom("Chalkboard SE", size: 12, relativeTo: .footnote))
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
                .frame(maxWidth: DesignTokens.Layout.compactReadingMaxWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
    }
}
