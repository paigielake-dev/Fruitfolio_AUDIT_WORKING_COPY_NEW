import SwiftUI

struct Prompt30ContactView: View {
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var motion: MotionPreferences
    @State private var failedDestination: URL?

    private let instagramURL = URL(string: "https://www.instagram.com/fruitsoflife.xo")!
    private let tiktokURL = URL(string: "https://www.tiktok.com/@fruitsoflife.xo?lang=en")!
    private let emailURL = URL(string: "mailto:fruitsoflifexo@gmail.com")!
    private let carrdURL = URL(string: "https://fruitsoflifexo.carrd.co")!

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    FruitfolioProtectedHeader {
                        Prompt12RouteHeader(
                            title: "contact",
                            subtitle: "questions, feedback, or just a little hello ♡",
                            assetName: nil,
                            onBack: onBack
                        )
                    } decoration: { protected, space in
                        ZStack(alignment: .topTrailing) {

                        HStack(spacing: -7) {
                            FruitfolioImage(id: .cycledecor_green_flecks)
                                .frame(width: 52, height: 52)

                            FruitfolioImage(id: .fruitbasket_plum)
                                .frame(width: 46, height: 46)


                        }
                        .padding(.top, 2)
                        .padding(.trailing, 2)
                        .fruitfolioAvoidProtectedContent(protected, in: space)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)

                        FruitfolioImage(id: .decor_sparkles_2)
                            .frame(width: 52, height: 52)
                            .fruitfolioAvoidProtectedContent(protected, in: space, assetName: "decor_sparkles_2")
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(x: 72, y: -14)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                        }
                    }

                    VStack(spacing: 4) {
                        FruitfolioControlPillButton(label: "Instagram  •  @fruitsoflife.xo", localizationKey: "Instagram  •  @fruitsoflife.xo") { openContact(instagramURL) }
                        FruitfolioControlPillButton(label: "TikTok  •  @fruitsoflife.xo", localizationKey: "TikTok  •  @fruitsoflife.xo") { openContact(tiktokURL) }
                        FruitfolioControlPillButton(label: "email  •  fruitsoflifexo@gmail.com", localizationKey: "email  •  fruitsoflifexo@gmail.com") { openContact(emailURL) }
                        FruitfolioControlPillButton(label: "FruitsofLife.xo Carrd", localizationKey: "FruitsofLife.xo Carrd") { openContact(carrdURL) }
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
            .fruitfolioModalBlur(active: failedDestination != nil, reduceMotion: motion.reduceMotionActive)

            if let destination = failedDestination {
                Prompt12ConfirmationPopup(assetName: "popup_warning", title: "that link couldn’t open",
                    message: "please try again when a compatible app or connection is available. destination: \(destination.absoluteString)",
                    primaryLabel: "close", secondaryLabel: nil, destructiveLabel: nil,
                    primaryAction: { failedDestination = nil }, secondaryAction: nil, destructiveAction: nil)
                    .accessibilityIdentifier("contact.linkFailure")
            }
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func openContact(_ destination: URL) {
        openURL(destination) { accepted in
            if !accepted { failedDestination = destination }
        }
    }
}
