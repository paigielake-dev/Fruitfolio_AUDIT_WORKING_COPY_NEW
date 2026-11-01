import SwiftUI

struct Prompt04HubBridgeView: View {
    @EnvironmentObject private var navigation: NavigationCoordinator
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @StateObject
    private var tour =
        Prompt07TourController()

    @State
    private var targetFrames:
        [Prompt07TourTarget: CGRect] = [:]

    @State
    private var invitationScheduled = false

    @State
    private var hubBrandingAnimationCompleted = false

    var body: some View {
        FruitPopupHost {
            ZStack {
                Prompt04StandaloneHubComposition(
                    interactive:
                        !tour.isTourActive,
                    onBrandingAnimationCompleted: {
                        hubBrandingAnimationCompleted =
                            true

                        scheduleInvitationIfNeeded()
                    }
                ) { route in
                    navigation.navigate(
                        to: route
                    )
                }
                .coordinateSpace(
                    name: "Prompt07HubSpace"
                )
                .onPreferenceChange(
                    Prompt07TargetFramePreferenceKey.self
                ) {
                    targetFrames = $0
                }

                if tour.isTourActive {
                    Prompt07TourOverlay(
                        frames: targetFrames,
                        step: tour.currentStep,
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive,
                        onBack: {
                            tour.back()
                        },
                        onNext: {
                            tour.next()
                        },
                        onSkip: {
                            finishTour()
                        },
                        onFinish: {
                            finishTour()
                        }
                    )
                }
            }
        }
        .task {
            if appState.tourWasManuallyReplayed {
                beginManualReplayIfNeeded()
            } else {
                scheduleInvitationIfNeeded()
            }
        }
        .onChange(
            of:
                appState
                    .firstLaunchOnboardingHookReady
        ) { _, isReady in

            guard isReady else {
                return
            }

            scheduleInvitationIfNeeded()
        }
        .onChange(
            of:
                appState
                    .tourWasManuallyReplayed
        ) { _, replay in

            guard replay else {
                return
            }

            beginManualReplayIfNeeded()
        }
    }

    private var shouldOfferFirstLaunchTour: Bool {
        !appState.tutorialCompleted
    }

    private var onboardingHookAllowsInvitation: Bool {
        appState.firstLaunchOnboardingHookReady
    }

    private func scheduleInvitationIfNeeded() {
        guard
            !invitationScheduled,
            hubBrandingAnimationCompleted,
            onboardingHookAllowsInvitation,
            shouldOfferFirstLaunchTour
        else {
            return
        }

        invitationScheduled = true

        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds:
                    600_000_000
            )

            guard
                shouldOfferFirstLaunchTour,
                popupCoordinator
                    .currentPopup == nil
            else {
                return
            }

            popupCoordinator.request(
                .init(
                    character: .blueberry,
                    message:
                        "hello there! ♡ want me to show you around?",
                    primaryAction: .init(
                        label:
                            "show me around",
                        accessibilityLabel:
                            "Show me around"
                    ) {
                        // Resolving the invitation is the one-time onboarding event.
                        // Persist it before the tour begins so an interrupted/relaunched
                        // session never receives the automatic invitation again.
                        appState.completeTutorial()

                        popupCoordinator
                            .dismissCurrent(
                                reason: .action
                            )

                        tour.begin()
                    },
                    secondaryAction: .init(
                        label:
                            "i’ll explore ✿",
                        accessibilityLabel:
                            "I'll explore"
                    ) {
                        appState
                            .completeTutorial()

                        popupCoordinator
                            .dismissCurrent(
                                reason: .action
                            )
                    },
                    positionPreference:
                        .bottom,
                    dismissBehavior:
                        .explicitActionOnly,
                    tone:
                        .educational,
                    priority:
                        .educational,
                    source:
                        "prompt07.firstLaunchTour",
                    deduplicationKey:
                        "prompt07.firstLaunchTourInvitation",
                    analyticsIdentifier:
                        "prompt07.first_launch_tour_invitation"
                )
            )
        }
    }

    private func beginManualReplayIfNeeded() {
        guard appState.tourWasManuallyReplayed else { return }

        popupCoordinator.dismissCurrent(
            reason: .programmatic
        )

        if !tour.isTourActive {
            tour.begin()
        }
    }

    private func finishTour() {
        tour.end()
        appState.completeTutorial()
    }
}

// MARK: - Standalone Hub

struct Prompt04StandaloneHubComposition: View {
    let interactive: Bool

    let onBrandingAnimationCompleted:
        () -> Void

    let navigate:
        (FruitfolioRoute) -> Void

    init(
        interactive: Bool,
        onBrandingAnimationCompleted:
            @escaping () -> Void = {},
        navigate:
            @escaping (FruitfolioRoute) -> Void = { _ in }
    ) {
        self.interactive =
            interactive

        self.onBrandingAnimationCompleted =
            onBrandingAnimationCompleted

        self.navigate =
            navigate
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics =
                Prompt04BookLayout.metrics(
                    for: proxy.size
                )

            ZStack {
                DesignTokens
                    .ColorToken
                    .backgroundCream
                    .ignoresSafeArea()

                FruitfolioImage(
                    id: .ask_answer_paper
                )
                .scaledToFill()
                .frame(
                    width:
                        metrics.viewportWidth,
                    height:
                        metrics.viewportHeight
                )
                .clipped()
                .accessibilityHidden(
                    true
                )

                Prompt04HubPaperControls(
                    metrics: metrics,
                    interactive:
                        interactive,
                    onBrandingAnimationCompleted:
                        onBrandingAnimationCompleted,
                    navigate:
                        navigate
                )
            }
            .frame(
                width:
                    metrics.viewportWidth,
                height:
                    metrics.viewportHeight
            )
            .clipped()
        }
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .ignoresSafeArea()
        )
    }
}

// MARK: - Hub Paper

struct Prompt04HubPaperControls: View {
    let metrics:
        Prompt04BookLayout.Metrics

    let interactive: Bool

    let onBrandingAnimationCompleted:
        () -> Void

    let navigate:
        (FruitfolioRoute) -> Void

    init(
        metrics:
            Prompt04BookLayout.Metrics,
        interactive: Bool,
        onBrandingAnimationCompleted:
            @escaping () -> Void = {},
        navigate:
            @escaping (FruitfolioRoute) -> Void = { _ in }
    ) {
        self.metrics =
            metrics

        self.interactive =
            interactive

        self.onBrandingAnimationCompleted =
            onBrandingAnimationCompleted

        self.navigate =
            navigate
    }

    var body: some View {
        ZStack {
            Prompt05HubDecorations(
                metrics: metrics
            )

            Prompt05HubPaperControls(
                metrics: metrics,
                interactive:
                    interactive,
                onBrandingAnimationCompleted:
                    onBrandingAnimationCompleted,
                navigate:
                    navigate
            )
        }
        .frame(
            width:
                metrics.viewportWidth,
            height:
                metrics.viewportHeight
        )
    }
}

// MARK: - Decorations

private struct Prompt05HubDecorations:
    View {

    let metrics:
        Prompt04BookLayout.Metrics

    private var glowWidth:
        CGFloat {

        min(
            max(
                metrics.viewportWidth
                    * 0.315,
                112
            ),
            138
        )
    }

    private var pearWidth:
        CGFloat {

        min(
            max(
                metrics.viewportWidth
                    * 0.305,
                108
            ),
            136
        )
    }

    private var orangeSliceWidth:
        CGFloat {

        min(
            max(
                pearWidth * 1.18,
                128
            ),
            158
        )
    }

    private var sparkleWidth:
        CGFloat {

        min(
            max(
                metrics.viewportWidth
                    * 0.255,
                92
            ),
            116
        )
    }

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    FruitfolioImage(
                        id:
                            .decor_sparkle_cluster
                    )
                    .scaledToFit()
                    .frame(
                        width:
                            sparkleWidth
                    )
                    .accessibilityHidden(
                        true
                    )

                    Spacer(
                        minLength: 0
                    )
                }

                Spacer(
                    minLength: 0
                )
            }
            .padding(
                .top,
                18
            )
            .padding(
                .leading,
                4
            )

            VStack {
                HStack {
                    Spacer(
                        minLength: 0
                    )

                    FruitfolioImage(
                        id:
                            .decor_orange_glow
                    )
                    .scaledToFit()
                    .frame(
                        width:
                            glowWidth
                    )
                    .accessibilityHidden(
                        true
                    )
                }

                Spacer(
                    minLength: 0
                )
            }
            .padding(
                .top,
                -8
            )
            .padding(
                .trailing,
                -24
            )

            VStack {
                Spacer(
                    minLength: 0
                )

                HStack {
                    FruitfolioImage(
                        id:
                            .decor_pear
                    )
                    .scaledToFit()
                    .frame(
                        width:
                            pearWidth
                    )
                    .accessibilityHidden(
                        true
                    )

                    Spacer(
                        minLength: 0
                    )
                }
            }
            .padding(
                .leading,
                -14
            )
            .padding(
                .bottom,
                metrics.hubBottomPadding
                    + metrics.utilityIconSize
                    + 18
            )

            VStack {
                Spacer(
                    minLength: 0
                )

                HStack {
                    Spacer(
                        minLength: 0
                    )

                    Image(
                        "decor_orange_slice"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width:
                            orangeSliceWidth
                    )
                    .offset(
                        x: 8,
                        y: 0
                    )
                    .accessibilityHidden(
                        true
                    )
                }
            }
            .padding(
                .trailing,
                -4
            )
            .padding(
                .bottom,
                metrics.hubBottomPadding
                    + metrics.utilityIconSize
                    + 34
            )
        }
        .frame(
            width:
                metrics.viewportWidth,
            height:
                metrics.viewportHeight
        )
        .allowsHitTesting(
            false
        )
        .accessibilityHidden(
            true
        )
    }
}

// MARK: - Button Spec

private struct Prompt05HubButtonSpec:
    Identifiable {

    let route:
        FruitfolioRoute

    let buttonAsset:
        FruitfolioAssetID

    let symbolAsset:
        FruitfolioAssetID

    let displayLabel:
        String

    var id:
        FruitfolioRoute {

        route
    }

    var tourTarget:
        Prompt07TourTarget? {

        switch route {

        case .ask:
            return .ask

        case .library:
            return .library

        case .guideBuilder:
            return .guideBuilder

        case .cycle:
            return .cycle

        case .fruitBasket:
            return .fruitBasket

        case .faq:
            return .faq

        default:
            return nil
        }
    }
}

// MARK: - Hub Controls

private struct Prompt05HubPaperControls:
    View {

    let metrics:
        Prompt04BookLayout.Metrics

    let interactive:
        Bool

    let onBrandingAnimationCompleted:
        () -> Void

    let navigate:
        (FruitfolioRoute) -> Void

    @EnvironmentObject
    private var appState:
        AppState

    @EnvironmentObject
    private var audioManager:
        AudioManager

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    @State
    private var navigationLocked =
        false

    @State
    private var titleWritingProgress:
        CGFloat = 0

    @State
    private var bylineVisible =
        false

    @State
    private var hubTitleAnimationStarted =
        false

    private let primarySpecs:
        [Prompt05HubButtonSpec] = [

        .init(
            route: .ask,
            buttonAsset:
                .button_mint,
            symbolAsset:
                .ask_magnifying_glass,
            displayLabel:
                "ask the encyclopedia"
        ),

        .init(
            route: .library,
            buttonAsset:
                .button_sage,
            symbolAsset:
                .hub_bookshelf,
            displayLabel:
                "my encyclopedias"
        ),

        .init(
            route: .guideBuilder,
            buttonAsset:
                .button_peach,
            symbolAsset:
                .guide_folder_add,
            displayLabel:
                "build your own guide"
        ),

        .init(
            route: .cycle,
            buttonAsset:
                .button_coral,
            symbolAsset:
                .hub_calendar,
            displayLabel:
                "cycle tracker"
        ),

        .init(
            route: .fruitBasket,
            buttonAsset:
                .button_yellow,
            symbolAsset:
                .hub_basket,
            displayLabel:
                "fruit basket"
        ),

        .init(
            route: .faq,
            buttonAsset:
                .button_lavender,
            symbolAsset:
                .hub_question,
            displayLabel:
                "FAQ"
        )
    ]

    var body: some View {
        VStack(
            spacing: 0
        ) {

            // MARK: Branding

            VStack(
                spacing: 3
            ) {
                Text(
                    "Fruitfolio"
                )
                .font(
                    .custom(
                        "Snell Roundhand",
                        size:
                            dynamicTypeSize
                                .isAccessibilitySize
                            ? 58
                            : 68
                    )
                )
                .foregroundStyle(
                    DesignTokens
                        .ColorToken
                        .primaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
                .minimumScaleFactor(
                    0.78
                )
                .lineLimit(1)
                .frame(
                    width:
                        metrics
                            .hubContentWidth,
                    alignment:
                        .center
                )
                .mask {
                    GeometryReader {
                        geometry in

                        HStack(
                            spacing: 0
                        ) {
                            Rectangle()
                                .frame(
                                    width:
                                        max(
                                            0,
                                            geometry
                                                .size
                                                .width
                                            * titleWritingProgress
                                        )
                                )

                            Spacer(
                                minLength: 0
                            )
                        }
                    }
                }
                .accessibilityAddTraits(
                    .isHeader
                )

                Text(
                    "By FruitsofLife.xo"
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size:
                            dynamicTypeSize
                                .isAccessibilitySize
                            ? 18
                            : 20
                    )
                )
                .fontWeight(
                    .bold
                )
                .foregroundStyle(
                    DesignTokens
                        .ColorToken
                        .secondaryBurgundy
                )
                .multilineTextAlignment(
                    .center
                )
                .minimumScaleFactor(
                    0.80
                )
                .lineLimit(1)
                .frame(
                    width:
                        metrics
                            .hubContentWidth,
                    alignment:
                        .center
                )
                .opacity(
                    bylineVisible
                    ? 1
                    : 0
                )
                .scaleEffect(
                    bylineVisible
                    ? 1
                    : 0.92
                )
                .offset(
                    y:
                        bylineVisible
                        ? 0
                        : 3
                )
            }
            .frame(
                width:
                    metrics
                        .hubContentWidth,
                alignment:
                    .center
            )

            Spacer(
                minLength:
                    dynamicTypeSize
                        .isAccessibilitySize
                    ? 8
                    : 12
            )

            // MARK: Main Buttons

            LazyVGrid(
                columns: [
                    GridItem(
                        .fixed(
                            metrics
                                .hubGridColumnWidth
                        ),
                        spacing:
                            metrics
                                .hubGridGap
                    ),

                    GridItem(
                        .fixed(
                            metrics
                                .hubGridColumnWidth
                        ),
                        spacing:
                            metrics
                                .hubGridGap
                    )
                ],
                alignment: .center,
                spacing:
                    dynamicTypeSize
                        .isAccessibilitySize
                    ? 10
                    : 12
            ) {
                ForEach(
                    primarySpecs
                ) { spec in

                    Prompt05PrimaryHubButton(
                        spec: spec,
                        width:
                            metrics
                                .hubGridColumnWidth,
                        height:
                            metrics
                                .hubButtonHeight,
                        interactive:
                            interactive
                            && !navigationLocked,
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive,
                        action: {
                            activate(
                                spec.route
                            )
                        }
                    )
                    .modifier(
                        Prompt07OptionalTargetModifier(
                            target:
                                spec.tourTarget
                        )
                    )
                }
            }

            Spacer(
                minLength:
                    dynamicTypeSize
                        .isAccessibilitySize
                    ? 8
                    : 10
            )

            // MARK: Utilities

            Prompt05HubUtilityRow(
                metrics: metrics,
                interactive:
                    interactive
                    && !navigationLocked,
                accountLabel:
                    appState
                        .hubAccountLabel,
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive,
                activate:
                    activate
            )
        }
        .padding(
            .horizontal,
            metrics
                .hubHorizontalPadding
        )
        .padding(
            .top,
            metrics
                .hubTopPadding
        )
        .padding(
            .bottom,
            metrics
                .hubBottomPadding
        )
        .frame(
            width:
                metrics.viewportWidth,
            height:
                metrics.viewportHeight
        )
        .accessibilityElement(
            children: .contain
        )
        .task {
            guard interactive else {
                return
            }

            await beginHubTitleAnimationAfterSettling()
        }
        .onChange(
            of: interactive
        ) { _, isReady in

            guard isReady else {
                return
            }

            Task { @MainActor in
                await beginHubTitleAnimationAfterSettling()
            }
        }
    }

    // MARK: - Branding Animation

    @MainActor
    private func beginHubTitleAnimationAfterSettling()
        async {

        guard
            interactive,
            !hubTitleAnimationStarted
        else {
            return
        }

        hubTitleAnimationStarted =
            true

        try? await Task.sleep(
            nanoseconds:
                150_000_000
        )

        guard interactive else {
            hubTitleAnimationStarted =
                false

            return
        }

        if motionPreferences
            .reduceMotionActive {

            titleWritingProgress =
                1

            bylineVisible =
                true

            onBrandingAnimationCompleted()

            return
        }

        titleWritingProgress =
            0

        bylineVisible =
            false

        withAnimation(
            .easeInOut(
                duration: 1.35
            )
        ) {
            titleWritingProgress =
                1
        }

        try? await Task.sleep(
            nanoseconds:
                1_200_000_000
        )

        guard interactive else {
            return
        }

        withAnimation(
            .spring(
                response: 0.34,
                dampingFraction: 0.76
            )
        ) {
            bylineVisible =
                true
        }

        try? await Task.sleep(
            nanoseconds:
                400_000_000
        )

        guard interactive else {
            return
        }

        onBrandingAnimationCompleted()
    }

    // MARK: - Navigation

    private func activate(
        _ route: FruitfolioRoute
    ) {
        guard
            interactive,
            !navigationLocked
        else {
            return
        }

        navigationLocked =
            true

        audioManager.play(
            .buttonSoftPop
        )

        navigate(route)

        Task { @MainActor in
            try? await Task.sleep(
                nanoseconds:
                    450_000_000
            )

            navigationLocked =
                false
        }
    }
}

// MARK: - Optional Tour Target

private struct Prompt07OptionalTargetModifier:
    ViewModifier {

    let target:
        Prompt07TourTarget?

    func body(
        content: Content
    ) -> some View {

        if let target {
            content
                .prompt07TourTarget(
                    target
                )

        } else {
            content
        }
    }
}

// MARK: - Primary Hub Button

private struct Prompt05PrimaryHubButton:
    View {

    let spec:
        Prompt05HubButtonSpec

    let width:
        CGFloat

    let height:
        CGFloat

    let interactive:
        Bool

    let reduceMotion:
        Bool

    let action:
        () -> Void

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Button {
            activateImmediately()

        } label: {
            ZStack {
                FruitfolioImage(
                    id:
                        spec.buttonAsset
                )
                .scaledToFit()
                .frame(
                    width: width,
                    height:
                        max(
                            height,
                            44
                        )
                )
                .accessibilityHidden(
                    true
                )

                HStack(
                    spacing: 6
                ) {
                    FruitfolioImage(
                        id:
                            spec.symbolAsset
                    )
                    .scaledToFit()
                    .frame(
                        width:
                            min(
                                34,
                                max(
                                    24,
                                    height
                                        * 0.40
                                )
                            ),
                        height:
                            min(
                                34,
                                max(
                                    24,
                                    height
                                        * 0.40
                                )
                            )
                    )
                    .accessibilityHidden(
                        true
                    )

                    Text(
                        spec.displayLabel
                    )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size:
                                dynamicTypeSize
                                    .isAccessibilitySize
                                ? 13.5
                                : 12.5
                        )
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .multilineTextAlignment(
                        .leading
                    )
                    .lineLimit(
                        dynamicTypeSize
                            .isAccessibilitySize
                        ? 3
                        : 2
                    )
                    .minimumScaleFactor(
                        0.82
                    )
                    .frame(
                        maxWidth:
                            .infinity,
                        alignment:
                            .leading
                    )
                }
                .padding(
                    .leading,
                    11
                )
                .padding(
                    .trailing,
                    10
                )
            }
            .frame(
                width: width
            )
            .frame(
                minHeight:
                    max(
                        height,
                        DesignTokens
                            .Layout
                            .minimumHitTarget
                    )
            )
            .contentShape(
                Rectangle()
            )
            .accessibilityHidden(true)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    reduceMotion
            )
        )
        .disabled(
            !interactive
        )
        .accessibilityHidden(
            !interactive
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            accessibilityLabel
        )
        .accessibilityIdentifier("hub.action." + accessibilityLabel)
        .accessibilityAddTraits(
            .isButton
        )
    }

    // MARK: - Immediate Navigation

    @MainActor
    private func activateImmediately() {
        guard interactive else { return }
        action()
    }

    private var accessibilityLabel:
        String {

        switch spec.route {

        case .ask:
            return
                "Ask the Encyclopedia"

        case .library:
            return
                "My Encyclopedias"

        case .guideBuilder:
            return
                "Build Your Own Guide"

        case .cycle:
            return
                "Cycle Tracker"

        case .fruitBasket:
            return
                "Fruit Basket"

        case .faq:
            return
                "FAQ"

        default:
            return
                spec.displayLabel
        }
    }
}

// MARK: - Utility Row

private struct Prompt05HubUtilityRow:
    View {

    let metrics:
        Prompt04BookLayout.Metrics

    let interactive:
        Bool

    let accountLabel:
        String

    let reduceMotion:
        Bool

    let activate:
        (FruitfolioRoute) -> Void

    var body: some View {
        ViewThatFits(
            in: .horizontal
        ) {
            HStack(
                spacing: 0
            ) {
                utility(
                    route:
                        .contact,
                    asset:
                        .hub_envelope,
                    label:
                        "contact"
                )

                utility(
                    route:
                        .settings,
                    asset:
                        .hub_settings,
                    label:
                        "settings"
                )

                utility(
                    route:
                        .account,
                    asset:
                        .hub_account,
                    label:
                        accountLabel
                )
            }
            .frame(
                width:
                    metrics
                        .hubContentWidth
            )

            VStack(
                spacing: 4
            ) {
                HStack(
                    spacing: 0
                ) {
                    utility(
                        route:
                            .contact,
                        asset:
                            .hub_envelope,
                        label:
                            "contact"
                    )

                    utility(
                        route:
                            .settings,
                        asset:
                            .hub_settings,
                        label:
                            "settings"
                    )
                }

                utility(
                    route:
                        .account,
                    asset:
                        .hub_account,
                    label:
                        accountLabel
                )
            }
            .frame(
                width:
                    metrics
                        .hubContentWidth
            )
        }
        .accessibilityElement(
            children: .contain
        )
    }

    private func utility(
        route:
            FruitfolioRoute,
        asset:
            FruitfolioAssetID,
        label:
            String
    ) -> some View {

        Prompt05HubUtilityButton(
            route:
                route,
            asset:
                asset,
            label:
                label,
            width:
                metrics
                    .utilityItemWidth,
            iconSize:
                metrics
                    .utilityIconSize,
            interactive:
                interactive,
            reduceMotion:
                reduceMotion,
            activate:
                activate
        )
    }
}

// MARK: - Hub Utility Button

private struct Prompt05HubUtilityButton:
    View {

    let route:
        FruitfolioRoute

    let asset:
        FruitfolioAssetID

    let label:
        String

    let width:
        CGFloat

    let iconSize:
        CGFloat

    let interactive:
        Bool

    let reduceMotion:
        Bool

    let activate:
        (FruitfolioRoute) -> Void

    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    var body: some View {
        Button {
            activateImmediately()

        } label: {
            VStack(
                spacing: 3
            ) {
                FruitfolioImage(
                    id: asset
                )
                .scaledToFit()
                .frame(
                    width:
                        iconSize,
                    height:
                        iconSize
                )
                .accessibilityHidden(
                    true
                )

                Text(label)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 11,
                            relativeTo: .caption
                        )
                    )
                    .fontWeight(
                        .bold
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(
                width:
                    width
            )
            .frame(
                minHeight:
                    DesignTokens
                        .Layout
                        .minimumHitTarget
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    reduceMotion
            )
        )
        .disabled(
            !interactive
        )
        .accessibilityHidden(
            !interactive
        )
        .accessibilityAddTraits(
            .isButton
        )
    }

    @MainActor
    private func activateImmediately() {
        guard interactive else { return }
        activate(route)
    }

}

