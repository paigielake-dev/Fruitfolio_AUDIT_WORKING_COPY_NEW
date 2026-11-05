import SwiftUI

struct Prompt30ContactView: View {
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL

    @State private var unavailableLink = false

    private let instagramURL = URL(string: "https://www.instagram.com/fruitsoflife.xo")!
    private let tiktokURL = URL(string: "https://www.tiktok.com/@fruitsoflife.xo?lang=en")!
    private let emailURL = URL(string: "mailto:fruitsoflifexo@gmail.com")!
    private let carrdURL = URL(string: "https://fruitsoflifexo.carrd.co")!

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        FruitfolioControlPillButton(label: "Instagram  •  @fruitsoflife.xo") { openContact(instagramURL) }
                        FruitfolioControlPillButton(label: "TikTok  •  @fruitsoflife.xo") { openContact(tiktokURL) }
                        FruitfolioControlPillButton(label: "email  •  fruitsoflifexo@gmail.com") { openContact(emailURL) }
                        FruitfolioControlPillButton(label: "FruitsofLife.xo Carrd") { openContact(carrdURL) }
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
            .safeAreaInset(edge: .top, spacing: 0) {
                FruitfolioDecoratedRouteHeader(palette: .contact) {
                    Prompt12RouteHeader(title: "contact", subtitle: "questions, feedback, or just a little hello ♡",
                                        assetName: nil, onBack: onBack)
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }


        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
        .alert("this link could not be opened on this device", isPresented: $unavailableLink) {
            Button("OK", role: .cancel) {}
        }
    }

    private func openContact(_ url: URL) {
        openURL(url) { accepted in
            if !accepted { unavailableLink = true }
        }
    }
}
