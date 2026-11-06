import SwiftUI

struct Prompt30ContactView: View {
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @AccessibilityFocusState private var focusedLink: Prompt30ContactDestination?
    @AccessibilityFocusState private var errorHeadingFocused: Bool
    @State private var linkState = Prompt30ContactLinkState()

    var body: some View {
        ZStack {
            ZStack {
                DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            ForEach(Prompt30ContactDestination.allCases) { destination in
                                FruitfolioControlPillButton(label: destination.label) { openContact(destination) }
                                    .accessibilityIdentifier("contact.link.\(destination.rawValue)")
                                    .accessibilityFocused($focusedLink, equals: destination)
                            }
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
            .fruitfolioModalBlur(active: linkState.failedDestination != nil, reduceMotion: motionPreferences.reduceMotionActive)
            if let destination = linkState.failedDestination {
                linkFailure(destination)
                    .zIndex(DesignTokens.ZLayer.systemModal)
            }
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { linkState.appear() }
        .onDisappear { linkState.disappear() }
    }

    private func linkFailure(_ destination: Prompt30ContactDestination) -> some View {
        ZStack {
            Color.black.opacity(FruitfolioModalBlurSpec.dimOpacity).ignoresSafeArea()
                .accessibilityHidden(true)
            FruitfolioTapedWhitePopup {
                VStack(spacing: 12) {
                    Text(settings.localized("this link could not be opened on this device"))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($errorHeadingFocused)
                    Text(destination.label)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(settings.localized("you can copy the destination and open it in another app."))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(destination.url.absoluteString)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("close") { dismissFailure(destination) }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                        .accessibilityIdentifier("contact.linkFailure.close")
                }
                .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("contact.linkFailure")
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { dismissFailure(destination) }
            .onAppear { errorHeadingFocused = true }
        }
    }

    private func dismissFailure(_ destination: Prompt30ContactDestination) {
        audioManager.play(.buttonSoftPop)
        linkState.dismiss()
        focusedLink = destination
    }

    private func openContact(_ destination: Prompt30ContactDestination) {
        audioManager.play(.buttonSoftPop)
        guard let request = linkState.begin(destination) else { return }
        openURL(destination.url) { accepted in
            linkState.complete(request, accepted: accepted)
        }
    }
}
