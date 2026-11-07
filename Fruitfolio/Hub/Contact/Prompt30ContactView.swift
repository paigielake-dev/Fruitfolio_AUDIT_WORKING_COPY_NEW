import SwiftUI
import UIKit

struct Prompt30ContactView: View {
    let onBack: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popups: PopupCoordinator

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @AccessibilityFocusState private var focusedLink: Prompt30ContactDestination?
    @AccessibilityFocusState private var errorHeadingFocused: Bool
    @State private var linkState = Prompt30ContactLinkState()
    @State private var announcedFailureID: UUID?
    private var canUseContact: Bool {
        scenePhase == .active && UIApplication.shared.applicationState == .active && popups.currentPopup == nil
    }

    var body: some View {
        ZStack {
            ZStack {
                DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            ForEach(Prompt30ContactDestination.allCases) { destination in
                                FruitfolioControlPillButton(label: destination.label,
                                    protectedLiterals: destination.protectedLabelLiterals) { openContact(destination) }
                                    .accessibilityIdentifier("contact.link.\(destination.rawValue)")
                                    .accessibilityFocused($focusedLink, equals: destination)
                            }
                        }

                        FruitfolioTranslatedText(source: "Fruitfolio is educational. For personal medical questions, diagnosis, treatment, or urgent concerns, contact an appropriate healthcare professional or emergency service.",
                            protectedLiterals: ["Fruitfolio"], font: .custom("Chalkboard SE", size: 12, relativeTo: .footnote), serious: true)
                            .accessibilityIdentifier("contact.educationNotice")
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
            if let destination = linkState.failedDestination, let failureID = linkState.failureID {
                linkFailure(destination, failureID: failureID)
                    .zIndex(DesignTokens.ZLayer.systemModal)
            }
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            if linkState.failedDestination == nil && ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                FruitfolioInteractionSoundDiagnostics()
            }
            #endif
        }
        .onAppear { linkState.appear(isActive: canUseContact) }
        .onChange(of: scenePhase) { _, _ in synchronizeAvailability() }
        .onChange(of: popups.currentPopup?.id) { _, _ in synchronizeAvailability() }
        .onChange(of: linkState.failureID) { _, _ in synchronizeAvailability() }
        .onDisappear {
            linkState.disappear()
            announcedFailureID = nil
            errorHeadingFocused = false
            focusedLink = nil
        }
    }

    private func linkFailure(_ destination: Prompt30ContactDestination, failureID: UUID) -> some View {
        ZStack {
            FruitfolioModalBackdrop()
                .accessibilityHidden(true)
            FruitfolioTapedWhitePopup {
                VStack(spacing: 12) {
                    FruitfolioFixedText(source: "this link could not be opened on this device",
                        font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($errorHeadingFocused)
                    FruitfolioFixedText(source: destination.label, protectedLiterals: destination.protectedLabelLiterals,
                        font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                        .fixedSize(horizontal: false, vertical: true)
                    FruitfolioFixedText(source: "you can copy the destination and open it in another app.",
                        font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(verbatim: destination.url.absoluteString)
                        .accessibilityIdentifier("contact.linkFailure.destinationURL")
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                    FruitfolioControlPillButton(label: "close") { dismissFailure(destination, failureID: failureID) }
                        .accessibilityIdentifier("contact.linkFailure.close")
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                        FruitfolioInteractionSoundDiagnostics()
                    }
                    #endif
                }
                .multilineTextAlignment(.center)
            }
            .accessibilityIdentifier("contact.linkFailure")
            .accessibilityAddTraits(.isModal)
            .accessibilityAction(.escape) { dismissFailure(destination, failureID: failureID) }
            .onAppear { synchronizeAvailability() }
        }
    }

    private func dismissFailure(_ destination: Prompt30ContactDestination, failureID: UUID) {
        guard canUseContact, linkState.dismiss(expectedFailureID: failureID) else { return }
        audioManager.play(.popupClose)
        errorHeadingFocused = false
        focusedLink = destination
    }

    private func synchronizeAvailability() {
        linkState.setActive(canUseContact)
        guard canUseContact else {
            errorHeadingFocused = false
            focusedLink = nil
            return
        }
        guard let failureID = linkState.failureID else { return }
        errorHeadingFocused = true
        if announcedFailureID != failureID {
            announcedFailureID = failureID
            audioManager.play(.popupOpen)
        }
    }

    private func openContact(_ destination: Prompt30ContactDestination) {
        guard canUseContact, let request = linkState.begin(destination) else { return }
        openURL(destination.url) { accepted in
            linkState.complete(request, accepted: accepted)
        }
    }
}
