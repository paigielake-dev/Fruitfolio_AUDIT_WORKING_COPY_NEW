import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Prompt 03 deliberately renders restrained, responsive placeholders only.
/// Final Intro/Hub/feature production interfaces belong to later prompts.
struct Prompt03SkeletonView: View {
    @StateObject private var appState: AppState
    @StateObject private var navigation: NavigationCoordinator
    @StateObject private var settings: SettingsStore
    @StateObject private var audioManager: AudioManager
    @StateObject private var motionPreferences: MotionPreferences
    @StateObject private var popupCoordinator: PopupCoordinator
    @StateObject private var introLaunchStore: IntroLaunchStore
    @StateObject private var prompt27AContextStore: Prompt27AContextStore

    @Environment(\.accessibilityReduceMotion)
    private var systemReduceMotion

    init(defaults: UserDefaults = .standard) {
        let settingsStore = SettingsStore(defaults: defaults)
        let popup = PopupCoordinator()
        let initialRoot: FruitfolioRoute = .intro

        _settings = StateObject(
            wrappedValue: settingsStore
        )

        _appState = StateObject(
            wrappedValue: AppState(
                hasEnteredMainApp: false
            )
        )

        _popupCoordinator = StateObject(
            wrappedValue: popup
        )

        _navigation = StateObject(
            wrappedValue: NavigationCoordinator(
                root: initialRoot,
                popupCoordinator: popup
            )
        )

        _audioManager = StateObject(
            wrappedValue: AudioManager(
                settings: settingsStore
            )
        )

        _motionPreferences = StateObject(
            wrappedValue: MotionPreferences()
        )

        _introLaunchStore = StateObject(
            wrappedValue: IntroLaunchStore(
                defaults: defaults
            )
        )

        _prompt27AContextStore = StateObject(
            wrappedValue: Prompt27AContextStore(
                defaults: defaults
            )
        )
    }

    var body: some View {
        FruitPopupHost {
            NavigationStack(
                path: $navigation.path
            ) {
                initialContent
                .navigationDestination(
                    for: FruitfolioRoute.self
                ) { route in
                    routeView(route)
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar(
                .hidden,
                for: .navigationBar
            )
            .tint(
                DesignTokens.ColorToken
                    .primaryBurgundy
            )
            .background(
                DesignTokens.ColorToken
                    .backgroundCream
                    .ignoresSafeArea()
            )
            .onAppear {
                syncMotionPreferences()
                navigation.onNavigationTransition = {
                    audioManager.play(.pageTurn)
                }
            }
            .onChange(
                of: systemReduceMotion
            ) {
                syncMotionPreferences()
            }
            .onChange(
                of: settings.reduceAnimationOverride
            ) {
                syncMotionPreferences()
            }
            #if canImport(UIKit)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                settings.translationPausedForMemoryPressure = true
                Task {
                    async let translation: Void = FruitfolioTranslationService.shared.releaseResources()
                    async let research: Void = LlamaFruitfolioLanguageModel.shared.releaseResources()
                    _ = await (translation, research)
                }
            }
            #endif
        }
        .environmentObject(appState)
        .environmentObject(navigation)
        .environmentObject(settings)
        .environmentObject(audioManager)
        .environmentObject(motionPreferences)
        .environmentObject(popupCoordinator)
        .environmentObject(introLaunchStore)
        .environmentObject(prompt27AContextStore)
        .environment(\.locale, Locale(identifier: settings.language.localeIdentifier))
        .environment(\.layoutDirection, settings.language.isRightToLeft ? .rightToLeft : .leftToRight)
    }

    @ViewBuilder
    private var initialContent: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-fruitfolioCitationQA") {
            FruitfolioCitationRegressionHarness()
                .environment(\.openURL, OpenURLAction { _ in .discarded })
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQA") {
            Prompt28GameRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioContactQA") {
            Prompt30ContactView(onBack: {})
                .environment(\.openURL, OpenURLAction { _ in .discarded })
                .onAppear {
                    settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioContactReduceMotion")
                }
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioWheelQA") {
            Prompt18WheelRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioPersonalHealthQA") {
            FruitfolioPersonalHealthRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioHormoneLibraryQA") {
            FruitfolioHormoneLibraryView(onBack: {})
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioBookQA") {
            Prompt1BBookRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioAskPaperQA") {
            FruitfolioAskContextRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioTourQA") {
            Prompt1BTourRegressionHarness()
        } else if ProcessInfo.processInfo.arguments.contains("-fruitfolioModalQA") {
            Prompt1BModalRegressionHarness()
        } else { routeView(navigation.root) }
        #else
        routeView(navigation.root)
        #endif
    }

    @ViewBuilder
    private func routeView(
        _ route: FruitfolioRoute
    ) -> some View {
        switch route {
        case .intro:
            Prompt04IntroView()

        case .hub:
            Prompt04HubBridgeView()

        case .ask:
            Prompt09AskView()

        case .library:
            Prompt10SavedLibraryView(
                store: .shared,
                onBack: navigation.back
            )

        case .guideBuilder:
            Prompt11GuideBuilderView(
                store: .shared,
                onBack: navigation.back,
                onGoToAsk: {
                    navigation.navigate(to: .ask)
                }
            )

        case .cycle:
            Prompt14CycleEntryView(
                store: .shared,
                onBack: navigation.back
            )

        case .fruitBasket:
            Prompt28FruitBasketView(
                onBack: navigation.back
            )

        case .faq:
            Prompt29FAQView(
                onBack: navigation.back
            )

        case .contact:
            Prompt30ContactView(
                onBack: navigation.back
            )

        case .settings:
            Prompt12SettingsView(
                store: .shared,
                onBack: navigation.back,
                onShowAccount: {
                    navigation.navigate(to: .account)
                },
                onShowPrivacy: {
                    navigation.navigate(to: .privacy)
                }
            )

        case .account:
            Prompt12AccountView(
                store: .shared,
                onBack: navigation.back,
                onShowPrivacy: {
                    navigation.navigate(to: .privacy)
                }
            )

        case .privacy:
            Prompt12PrivacyView(
                store: .shared,
                onBack: navigation.back
            )

        case .purchase:
            Prompt12OwnershipView(
                store: .shared,
                onBack: navigation.back
            )
        }
    }

    private func syncMotionPreferences() {
        motionPreferences.update(
            systemReduceMotion:
                systemReduceMotion,
            appOverride:
                settings
                    .reduceAnimationOverride
        )
    }
}


// MARK: - Destination Placeholder

private struct Prompt03DestinationPlaceholder: View {
    let route: FruitfolioRoute

    @EnvironmentObject
    private var navigation:
        NavigationCoordinator

    var body: some View {
        Prompt03ScrollablePage {
            Prompt03BackControl(
                action: navigation.back
            )

            Text(route.title)
                .font(
                    .title2.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
                .accessibilityAddTraits(
                    .isHeader
                )

            #if DEBUG
            Prompt03DebugLabel(
                "Route.\(route.debugName) • Prompt 03 placeholder"
            )
            #endif

            if route == .account {
                Prompt03TextButton(
                    "Privacy"
                ) {
                    navigation.navigate(
                        to: .privacy
                    )
                }
            }

            #if DEBUG
            if route == .purchase {
                Text(
                    "Architecture QA only — paid App Store installs already have access."
                )
                .font(.footnote)
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .secondaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
            }
            #endif

            Text(
                "Routing verified. Production content belongs to its dedicated prompt."
            )
            .font(.body)
            .foregroundStyle(
                DesignTokens.ColorToken
                    .secondaryBurgundy
            )
            .multilineTextAlignment(
                .center
            )
        }
    }
}


// MARK: - Settings

private struct Prompt03SettingsPlaceholder: View {
    @EnvironmentObject
    private var navigation:
        NavigationCoordinator

    @EnvironmentObject
    private var settings:
        SettingsStore

    var body: some View {
        Prompt03ScrollablePage {
            Prompt03BackControl(
                action: navigation.back
            )

            Text("Settings")
                .font(
                    .title2.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .accessibilityAddTraits(
                    .isHeader
                )

            VStack(
                spacing:
                    DesignTokens.Spacing.sm
            ) {
                Prompt03ToggleRow(
                    "Music",
                    isOn:
                        $settings.musicEnabled
                )

                Prompt03ToggleRow(
                    "Rain ambience",
                    isOn:
                        $settings.rainEnabled
                )

                Prompt03ToggleRow(
                    "Sound effects",
                    isOn:
                        $settings.soundEffectsEnabled
                )

                Prompt03ToggleRow(
                    "Typing ASMR",
                    isOn:
                        $settings.typingASMREnabled
                )

                Prompt03ToggleRow(
                    "Reduce animation override",
                    isOn:
                        $settings.reduceAnimationOverride
                )
            }
        }
    }
}


// MARK: - Scrollable Page

private struct Prompt03ScrollablePage<
    Content: View
>: View {
    @ViewBuilder
    let content: Content

    init(
        @ViewBuilder
        content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(
                spacing:
                    DesignTokens.Spacing.lg
            ) {
                content
            }
            .frame(
                maxWidth:
                    DesignTokens.Layout
                        .compactReadingMaxWidth
            )
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
            .padding(
                .horizontal,
                DesignTokens.Spacing.xl
            )
            .padding(
                .vertical,
                DesignTokens.Spacing.xxl
            )
        }
        .scrollBounceBehavior(
            .basedOnSize
        )
        .background(
            DesignTokens.ColorToken
                .backgroundCream
                .ignoresSafeArea()
        )
    }
}


// MARK: - Text Button

private struct Prompt03TextButton: View {
    let title: String
    let action: () -> Void

    init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(
            action: action
        ) {
            Text(title)
                .font(
                    .body.weight(
                        .semibold
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken
                        .primaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
                .frame(
                    maxWidth: .infinity
                )
                .frame(
                    minHeight:
                        DesignTokens.Layout
                            .minimumHitTarget
                )
                .padding(
                    .horizontal,
                    DesignTokens.Spacing.md
                )
                .padding(
                    .vertical,
                    DesignTokens.Spacing.xs
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 18
                    )
                    .fill(
                        DesignTokens.ColorToken
                            .softWhite
                            .opacity(0.82)
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 18
                        )
                        .stroke(
                            DesignTokens
                                .ColorToken
                                .secondaryBurgundy
                                .opacity(0.22),
                            lineWidth: 1
                        )
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}


// MARK: - Back Control

private struct Prompt03BackControl: View {
    let action: () -> Void

    var body: some View {
        Button(
            action: action
        ) {
            HStack(
                spacing:
                    DesignTokens.Spacing.xs
            ) {
                FruitfolioImage(
                    id: .control_previous,
                    accessibilityLabelOverride:
                        "Back"
                )
                .frame(
                    width: 26,
                    height: 26
                )

                Text("Back")
                    .font(
                        .body.weight(
                            .semibold
                        )
                    )
            }
            .foregroundStyle(
                DesignTokens.ColorToken
                    .primaryBurgundy
            )
            .frame(
                minWidth:
                    DesignTokens.Layout
                        .minimumHitTarget,
                minHeight:
                    DesignTokens.Layout
                        .minimumHitTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .accessibilityLabel("Back")
    }
}


// MARK: - Settings Toggle Row

private struct Prompt03ToggleRow: View {
    let title: String

    @Binding
    var isOn: Bool

    init(
        _ title: String,
        isOn: Binding<Bool>
    ) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        WatercolorToggle(
            label: title,
            isOn: $isOn
        )
        .frame(
            maxWidth: .infinity,
            minHeight:
                DesignTokens.Layout
                    .minimumHitTarget
        )
    }
}


// MARK: - Debug Label

#if DEBUG
private struct Prompt03DebugLabel: View {
    let text: String

    init(
        _ text: String
    ) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(
                DesignTokens.ColorToken
                    .secondaryBurgundy
            )
            .multilineTextAlignment(
                .center
            )
    }
}
#endif
