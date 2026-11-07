import SwiftUI
import UIKit

struct Prompt12SettingsView: View {
    @ObservedObject var store: Prompt12AccountPrivacyStore

    let onBack: () -> Void
    let onShowAccount: () -> Void
    let onShowPrivacy: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var prompt27AContextStore: Prompt27AContextStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var navigation: NavigationCoordinator

    @State private var showDataManagement = false
    @State private var showAbout = false
    @State private var showMyContext = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popups: PopupCoordinator
    @State private var rootIsVisible = false
    @State private var settingsActionEpoch = UUID()
    @State private var aboutPresentationID = UUID()
    @State private var announcedAboutID: UUID?
    @State private var aboutReturnTask: Task<Void, Never>?
    @State private var needsAboutReturnFocus = false
    @AccessibilityFocusState private var aboutHeadingFocused: Bool
    @AccessibilityFocusState private var aboutControlFocused: Bool

    private var canUseSettings: Bool {
        rootIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active &&
            popups.currentPopup == nil && !showMyContext
    }

    private var canEditSettings: Bool {
        canUseSettings && !showAbout && !showDataManagement
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Prompt12SavedRecordNotice(store: store)
                    languageSection
                    experienceSection
                    accessibilitySection
                    accountPrivacySection
                    fruitfolioSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 42)
            }
            .scrollIndicators(.hidden)
            .disabled(!canEditSettings)

            .safeAreaInset(edge: .top, spacing: 0) {
                FruitfolioDecoratedRouteHeader(palette: .settings) {
                    Prompt12RouteHeader(title: "settings", subtitle: "small controls for how Fruitfolio feels",
                                        assetName: "hub_settings", onBack: {
                                            guard canEditSettings else { return }
                                            onBack()
                                        })
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }
            .fruitfolioModalBlur(
                active:
                    showDataManagement ||
                    showAbout,
                reduceMotion: motionPreferences.reduceMotionActive
            )

            if showDataManagement ||
                showAbout {
                FruitfolioModalBackdrop()
                    .zIndex(90)
            }

            if showDataManagement {
                Prompt12DataManagementView(
                    store: store,
                    mode: .popup,
                    onBack: {
                        showDataManagement = false
                    },
                    onShowMyContext: {
                        showDataManagement = false
                        showMyContext = true
                    }
                )
                .zIndex(100)
            }

            if showAbout {
                let presentationID = aboutPresentationID
                FruitfolioTapedPaperPopup {
                    VStack(
                        alignment: .center,
                        spacing: 14
                    ) {
                        Image("fruitfolio_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 58,
                                height: 58
                            )
                            .accessibilityHidden(true)

                        FruitfolioFixedText(source: "about Fruitfolio", protectedLiterals: ["Fruitfolio"], font: .custom("Chalkboard SE", size: 16).bold(), color: DesignTokens.ColorToken.primaryBurgundy)
                            .multilineTextAlignment(
                                .center
                            )
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($aboutHeadingFocused)
                            .accessibilityIdentifier("settings.about.heading")
                            .lineLimit(nil)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        FruitfolioTranslatedText(
                            source: "Fruitfolio is a tiny watercolor encyclopedia world by FruitsofLife.xo. full about copy belongs to the dedicated About experience.",
                            protectedLiterals: ["Fruitfolio", "FruitsofLife.xo"],
                            font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body),
                            color: DesignTokens.ColorToken.secondaryBurgundy)
                        .accessibilityIdentifier("settings.about.body")
                        .multilineTextAlignment(
                            .center
                        )
                        .lineLimit(nil)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .frame(
                            maxWidth: 255,
                            alignment: .center
                        )

                        FruitfolioControlPillButton(
                            label: "got it ♡"
                        ) {
                            dismissAbout(expectedID: presentationID)
                        }
                        .accessibilityIdentifier("settings.about.close")
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                }
                .frame(maxWidth: 350)
                .accessibilityElement(children: .contain)
                .accessibilityAddTraits(.isModal)
                .accessibilityIdentifier("settings.about.popup")
                .accessibilityAction(.escape) { dismissAbout(expectedID: presentationID) }
                .task(id: "\(presentationID)-\(scenePhase == .active)-\(popups.currentPopup?.id.uuidString ?? "none")") {
                    await Task.yield()
                    guard !Task.isCancelled, canUseSettings, showAbout,
                          aboutPresentationID == presentationID else { return }
                    aboutHeadingFocused = true
                    if announcedAboutID != presentationID {
                        announcedAboutID = presentationID
                        audioManager.play(.popupOpen)
                    }
                }
                .zIndex(100)
            }

        }
        .onAppear { rootIsVisible = true }
        .onDisappear {
            rootIsVisible = false
            settingsActionEpoch = UUID()
            aboutReturnTask?.cancel(); aboutReturnTask = nil
            needsAboutReturnFocus = false
            aboutPresentationID = UUID()
            announcedAboutID = nil
            aboutHeadingFocused = false
            aboutControlFocused = false
            showAbout = false
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { settingsActionEpoch = UUID(); suspendAboutFocus() }
            else { restoreAboutControlFocus() }
        }
        .onChange(of: popups.currentPopup?.id) { _, id in
            if id != nil { settingsActionEpoch = UUID(); suspendAboutFocus() }
            else { restoreAboutControlFocus() }
        }
        .onChange(of: showDataManagement) { _, visible in
            if visible { settingsActionEpoch = UUID(); needsAboutReturnFocus = false; suspendAboutFocus() }
        }
        .onChange(of: showMyContext) { _, visible in
            if visible { settingsActionEpoch = UUID(); needsAboutReturnFocus = false; suspendAboutFocus() }
        }
        .fullScreenCover(isPresented: $showMyContext) {
            FruitfolioPresentedPopupHost {
                Prompt27AMyContextView(
                    store: prompt27AContextStore,
                    onBack: {
                        showMyContext = false
                    }
                )
                .environmentObject(audioManager)
                .environmentObject(motionPreferences)
            }
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
    }

    private var experienceSection: some View {
        Prompt12PaperCard {
            sectionTitle(
                "experience"
            )

            WatercolorToggle(label: "mute all audio", isOn: audioEnableBinding(\.globallyMuted, resumeWhen: false))
            WatercolorToggle(
                label: "sound effects",
                isOn: audioEnableBinding(\.soundEffectsEnabled, category: .soundEffects)
            )

            WatercolorToggle(
                label: "music",
                isOn: audioEnableBinding(\.musicEnabled, category: .music)
            )

            WatercolorToggle(
                label: "rain ambience",
                isOn: audioEnableBinding(\.rainEnabled, category: .rainAmbience)
            )

            WatercolorToggle(
                label: "typing ASMR",
                isOn: audioEnableBinding(\.typingASMREnabled, category: .typingASMR)
            )

            Prompt12VolumeRow(title: "music", value: admittedBinding(\.musicVolume))
            Prompt12VolumeRow(title: "rain sounds", value: admittedBinding(\.rainVolume))
            Prompt12VolumeRow(title: "sound effects", value: admittedBinding(\.soundEffectsVolume))
            Prompt12VolumeRow(title: "typing asmr", value: admittedBinding(\.typingVolume))
        }
    }

    private func audioEnableBinding(_ key: ReferenceWritableKeyPath<SettingsStore, Bool>,
                                    resumeWhen: Bool = true, category: FruitfolioAudioCategory? = nil) -> Binding<Bool> {
        Binding(get: { settings[keyPath: key] }, set: { enabled in
            guard canEditSettings else { return }
            settings[keyPath: key] = enabled
            if enabled == resumeWhen { audioManager.resumeAfterUserRequest(category: category) }
        })
    }

    private func admittedBinding<Value>(_ key: ReferenceWritableKeyPath<SettingsStore, Value>) -> Binding<Value> {
        Binding(get: { settings[keyPath: key] }, set: { value in
            guard canEditSettings else { return }
            settings[keyPath: key] = value
        })
    }

    private var languageSection: some View {
        Prompt12PaperCard {
            sectionTitle("language / भाषा / زبان")

            let expectedEpoch = settingsActionEpoch
            Menu {
                ForEach(FruitfolioLanguage.allCases) { language in
                    Button {
                        guard canEditSettings, expectedEpoch == settingsActionEpoch else { return }
                        settings.language = language
                        audioManager.play(.buttonSoftPop)
                    } label: {
                        if settings.language == language {
                            Label(language.nativeDisplayName, systemImage: "checkmark")
                        } else {
                            Text(language.nativeDisplayName)
                        }
                    }
                    .accessibilityIdentifier("settings.language.option." + language.rawValue)
                }
            } label: {
                HStack(spacing: 10) {
                    Text(settings.language.nativeDisplayName)
                        .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier("settings.language")
            .accessibilityLabel("Language / भाषा / زبان")
            .accessibilityValue(settings.language.nativeDisplayName)

            if let message = settings.languagePersistenceMessage {
                Prompt12InfoText(message)
                    .accessibilityIdentifier("settings.language.persistence")
            }
            if settings.languagePreferenceNeedsReview {
                Prompt12InfoText("the saved language is not recognized by this version. English is shown for now; the original preference is preserved until you choose a language.")
                    .accessibilityIdentifier("settings.language.recovery")
            }
            Prompt12InfoText("choose the language Fruitfolio uses throughout the app. language names stay recognizable so you can always change this setting again.")
            Prompt12InfoText("some translations may be unavailable. when that happens, the original text stays visible.")
        }
    }

    private var accessibilitySection: some View {
        Prompt12PaperCard {
            sectionTitle(
                "accessibility"
            )

            WatercolorToggle(
                label: "reduced motion",
                isOn:
                    admittedBinding(\.reduceAnimationOverride)
            )

            Prompt12InfoText(
                "when reduced motion is on, Fruitfolio keeps the same information and softens movement."
            )
        }
    }

    private var accountPrivacySection: some View {
        Prompt12PaperCard {
            sectionTitle(
                "account/privacy"
            )

            Prompt12NavigationRow(
                title: "account",
                detail:
                    store.isSignedIn
                    ? store.accountDisplayName
                    : "sign in or view ownership",
                assetName:
                    "hub_account",
                action: {
                    guard canEditSettings else { return }
                    onShowAccount()
                }
            )
            .modifier(
                Prompt12CuteRowPressModifier(
                    reduceMotion:
                        motionPreferences
                            .reduceMotionActive
                )
            )

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "privacy",
                detail:
                    "how Fruitfolio handles your information",
                assetName:
                    "popup_info",
                action: {
                    guard canEditSettings else { return }
                    onShowPrivacy()
                }
            )
            .modifier(
                Prompt12CuteRowPressModifier(
                    reduceMotion:
                        motionPreferences
                            .reduceMotionActive
                )
            )

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "my context",
                detail:
                    prompt27AContextStore.context.isCompletelyUnspecified
                    ? "optional reproductive + body context"
                    : "review or change what Fruitfolio keeps in mind",
                assetName:
                    "symptom_notes",
                action: {
                    guard canEditSettings else { return }
                    showMyContext = true
                }
            )
            .modifier(
                Prompt12CuteRowPressModifier(
                    reduceMotion:
                        motionPreferences
                            .reduceMotionActive
                )
            )

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "data",
                detail:
                    "export or manage supported data",
                assetName:
                    "ask_source_pages",
                action: {
                    guard canEditSettings else { return }
                    showDataManagement = true
                }
            )
        }
    }

    private var fruitfolioSection: some View {
        Prompt12PaperCard {
            sectionTitle(
                "Fruitfolio"
            )

            Prompt12NavigationRow(
                title: "replay tour",
                detail:
                    "review the existing Fruitfolio tour",
                assetName:
                    "fruit_blueberry_friendly",
                action: {
                    guard canEditSettings else { return }
                    appState.beginManualTourReplay()
                    navigation.returnToHub()
                }
            )

            Divider()
                .opacity(0.18)

            Prompt12NavigationRow(
                title: "about",
                detail:
                    "Fruitfolio by FruitsofLife.xo",
                assetName:
                    "fruitfolio_logo",
                action: openAbout
            )
            .accessibilityIdentifier("settings.about.open")
            .accessibilityFocused($aboutControlFocused)
        }
    }

    private func openAbout() {
        guard canUseSettings, !showAbout, !showDataManagement else { return }
        aboutReturnTask?.cancel(); aboutReturnTask = nil
        needsAboutReturnFocus = false
        aboutControlFocused = false
        aboutPresentationID = UUID()
        settingsActionEpoch = UUID()
        showAbout = true
    }

    private func dismissAbout(expectedID: UUID) {
        guard canUseSettings, showAbout, !showDataManagement,
              aboutPresentationID == expectedID else { return }
        showAbout = false
        aboutHeadingFocused = false
        audioManager.play(.popupClose)
        needsAboutReturnFocus = true
        restoreAboutControlFocus()
    }

    private func suspendAboutFocus() {
        aboutReturnTask?.cancel(); aboutReturnTask = nil
        aboutHeadingFocused = false
        aboutControlFocused = false
    }

    private func restoreAboutControlFocus() {
        guard canUseSettings, needsAboutReturnFocus, !showAbout, !showDataManagement else { return }
        aboutReturnTask?.cancel()
        let expectedID = aboutPresentationID
        aboutReturnTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled, canUseSettings, needsAboutReturnFocus,
                  !showAbout, !showDataManagement, aboutPresentationID == expectedID else { return }
            aboutControlFocused = true
            needsAboutReturnFocus = false
            aboutReturnTask = nil
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        FruitfolioFixedText(source: text,
            protectedLiterals: ["Fruitfolio", "FruitsofLife.xo", "भाषा", "زبان"],
            font: .custom("Chalkboard SE", size: 15, relativeTo: .headline).bold(),
            color: DesignTokens.ColorToken.primaryBurgundy)
            .accessibilityAddTraits(.isHeader)
    }

}


// MARK: - Cute Settings Row Press

/// Override the row's inherited style without a second gesture/transform.
private struct Prompt12CuteRowPressModifier: ViewModifier {
    let reduceMotion: Bool
    func body(content: Content) -> some View {
        content.buttonStyle(CutePopButtonStyle(reduceMotion: reduceMotion))
    }
}
