import SwiftUI

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

            .safeAreaInset(edge: .top, spacing: 0) {
                FruitfolioDecoratedRouteHeader(palette: .settings) {
                    Prompt12RouteHeader(title: "settings", subtitle: "small controls for how Fruitfolio feels",
                                        assetName: "hub_settings", onBack: onBack)
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
                DesignTokens.ColorToken.backgroundCream
                    .opacity(FruitfolioModalBlurSpec.dimOpacity)
                    .ignoresSafeArea()
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

                        Text("about Fruitfolio")
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 16
                                )
                            )
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                            )
                            .multilineTextAlignment(
                                .center
                            )
                            .lineLimit(nil)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        Text(
                            "Fruitfolio is a tiny watercolor encyclopedia world by FruitsofLife.xo. full about copy belongs to the dedicated About experience."
                        )
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 11.5
                            )
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .secondaryBurgundy
                        )
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
                            audioManager.play(
                                .popupClose
                            )
                            showAbout = false
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .center
                    )
                }
                .frame(maxWidth: 350)
                .onAppear {
                    audioManager.play(
                        .popupOpen
                    )
                }
                .zIndex(100)
            }

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

            WatercolorToggle(label: "mute all audio", isOn: $settings.globallyMuted)
            WatercolorToggle(
                label: "sound effects",
                isOn:
                    $settings
                        .soundEffectsEnabled
            )

            WatercolorToggle(
                label: "music",
                isOn:
                    $settings
                        .musicEnabled
            )

            WatercolorToggle(
                label: "rain ambience",
                isOn:
                    $settings
                        .rainEnabled
            )

            WatercolorToggle(
                label: "typing ASMR",
                isOn:
                    $settings
                        .typingASMREnabled
            )

            Prompt12VolumeRow(title: "music", value: $settings.musicVolume)
            Prompt12VolumeRow(title: "rain sounds", value: $settings.rainVolume)
            Prompt12VolumeRow(title: "sound effects", value: $settings.soundEffectsVolume)
            Prompt12VolumeRow(title: "typing asmr", value: $settings.typingVolume)
        }
    }

    private var languageSection: some View {
        Prompt12PaperCard {
            sectionTitle("language / भाषा / زبان")

            Menu {
                ForEach(FruitfolioLanguage.allCases) { language in
                    Button {
                        audioManager.play(.buttonSoftPop)
                        settings.language = language
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
                    $settings
                        .reduceAnimationOverride
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
                action: {
                    showAbout = true
                }
            )
        }
    }

    private func sectionTitle(
        _ text: String
    ) -> some View {
        Text(text)
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 15
                )
            )
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens
                    .ColorToken
                    .primaryBurgundy
            )
    }
}


// MARK: - Cute Settings Row Press

private struct Prompt12CuteRowPressModifier: ViewModifier {
    let reduceMotion: Bool

    @GestureState
    private var isPressed = false

    func body(
        content: Content
    ) -> some View {
        content
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        isPressed
                        ? 0.88
                        : 1
                    )
            )
            .offset(
                y:
                    reduceMotion
                    ? 0
                    : (
                        isPressed
                        ? 5
                        : 0
                    )
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (
                            isPressed
                            ? -1.2
                            : 0
                        )
                )
            )
            .brightness(
                reduceMotion
                    ? 0
                    : (
                        isPressed
                        ? -0.04
                        : 0
                    )
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.08
                    )
                    : .spring(
                        response: 0.20,
                        dampingFraction: 0.38,
                        blendDuration: 0
                    ),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(
                    minimumDistance: 0
                )
                .updating(
                    $isPressed
                ) { _, state, _ in
                    state = true
                }
            )
    }
}
