import SwiftUI
import UIKit

private enum Prompt28TextRole {
    case screenTitle
    case sectionHeading
    case body
    case secondary
    case metadata
    case button

    var font: Font {
        switch self {
        case .screenTitle:
            return .custom("Chalkboard SE", size: 24, relativeTo: .title2)
        case .sectionHeading:
            return .custom("Chalkboard SE", size: 17, relativeTo: .headline)
        case .body:
            return .custom("Chalkboard SE", size: 15, relativeTo: .body)
        case .secondary:
            return .custom("Chalkboard SE", size: 13, relativeTo: .subheadline)
        case .metadata:
            return .custom("Chalkboard SE", size: 11, relativeTo: .caption)
        case .button:
            return .custom("Chalkboard SE", size: 15, relativeTo: .headline)
        }
    }
}

private extension View {
    func prompt28Text(_ role: Prompt28TextRole) -> some View {
        self.font(role.font)
    }
}

private struct Prompt28InlineArtGlyph: View {
    let assetID: FruitfolioAssetID

    var body: some View {
        FruitfolioImage(id: assetID)
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
    }
}


struct Prompt28FruitBasketView: View {
    let onBack: () -> Void

    @StateObject private var store: Prompt28FruitBasketStore
    @StateObject private var viewModel: Prompt28FruitBasketViewModel

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @ObservedObject private var usernameStore = FruitfolioUsernameStore.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showingSaveDestination = false
    @State private var showTour = false
    @State private var tourStep = 0
    @AccessibilityFocusState private var tourHeadingFocused: Bool
    @State private var leaderboardValidationMessage: String?
    @State private var leaderboardUsernameDraft = ""
    @FocusState private var leaderboardUsernameFocused: Bool
    @State private var selectedLeaderboardCategory: Prompt28LeaderboardCategory = .fruit

    init(
        onBack: @escaping () -> Void,
        researchProvider: (any Prompt28ResearchProviding)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.onBack = onBack
        let store = Prompt28FruitBasketStore(defaults: defaults)
        _store = StateObject(wrappedValue: store)
        _viewModel = StateObject(
            wrappedValue: Prompt28FruitBasketViewModel(
                store: store,
                researchProvider: researchProvider ?? Prompt28CanonicalResearchProvider()
            )
        )
    }

    var body: some View {
        ZStack {
            ZStack {
            GeometryReader { proxy in
                Image("fruitbasket_background")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height,
                        alignment: .center
                    )
                    .offset(x: -proxy.size.width * 0.28)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()

            meadowWash

            sceneDecorationLayer

            weatherLayer

            content
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)

            }
            .accessibilityElement(children: showTour || viewModel.showingStormNotice ? .ignore : .contain)
            .fruitfolioModalBlur(active: showTour || viewModel.showingStormNotice,
                                reduceMotion: motionPreferences.reduceMotionActive)

            if showTour && !viewModel.showingStormNotice {
                tourOverlay
                    .zIndex(100)
            }
            if viewModel.showingStormNotice {
                Prompt28StormNoticeView(onContinue: { viewModel.dismissStormNotice() })
                    .zIndex(200)
            }
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            let audioOwner = viewModel.obstacleAudioOwnerID
            audioManager.claimBasketObstacleAudioOwner(audioOwner)
            viewModel.installGameplayCleanup { [weak manager = audioManager] in
                manager?.stopBasketObstacleAudio(owner: audioOwner)
            }
            Prompt28AssetUsageRegistrar.markProductionRoutes()
            Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_background)
            audioManager.fadeIn(.fruitBasketMusicbox, duration: 0.35)
            if let error = store.loadError {
                viewModel.message = error
                viewModel.screen = .error
            } else if !store.tourState.hasCompletedTour {
                showTour = true
                tourStep = 0
            }
        }
        .onDisappear {
            viewModel.viewWillDisappear()
            audioManager.stopBasketObstacleAudio(owner: viewModel.obstacleAudioOwnerID)
            audioManager.fadeOut(category: .music, duration: 0.25)
            audioManager.fadeOut(category: .rainAmbience, duration: 0.20)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.sceneBecameInactive()
                audioManager.stopBasketObstacleAudio(owner: viewModel.obstacleAudioOwnerID)
            }
        }
        .sheet(isPresented: $showingSaveDestination) {
            if let pending = viewModel.savePendingContent() {
                Prompt10AskSaveDestination(
                    store: .shared,
                    pending: pending,
                    onSaved: {
                        showingSaveDestination = false
                    },
                    onCancel: {
                        showingSaveDestination = false
                    }
                )
            }
        }
    }

    private var meadowWash: some View {
        LinearGradient(
            colors: [
                DesignTokens.ColorToken.backgroundCream.opacity(0.10),
                DesignTokens.ColorToken.paleYellow.opacity(0.08),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var sceneDecorationLayer: some View {
        GeometryReader { proxy in
            ZStack {
                FruitfolioImage(id: .fruitbasket_cloud)
                    .frame(width: 138)
                    .opacity(viewModel.screen == .catchActive ? 0.34 : 0.56)
                    .position(x: 78, y: 82)
                    .accessibilityHidden(true)
                    .onAppear {
                        Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_cloud)
                    }

                FruitfolioImage(id: .decor_grass)
                    .frame(width: 150)
                    .position(
                        x: 70,
                        y: max(proxy.size.height - 58, 0)
                    )
                    .accessibilityHidden(true)
                    .onAppear {
                        Prompt28AssetUsageRegistrar.markRendered(.decor_grass)
                    }
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var weatherLayer: some View {
        if viewModel.screen == .catchActive || viewModel.screen == .paused {
            switch viewModel.weather {
            case .clear:
                Color.clear
                    .allowsHitTesting(false)
                    .onAppear {
                        audioManager.fadeOut(category: .rainAmbience, duration: 0.20)
                    }

            case .breezy:
                Prompt28WindGust(
                    reduceMotion: motionPreferences.reduceMotionActive,
                    direction: viewModel.windDirection
                )
                .onAppear {
                    audioManager.fadeOut(category: .rainAmbience, duration: 0.20)
                    Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_wind)
                    audioManager.play(.fruitBasketWind)
                }

            case .softRain:
                GeometryReader { proxy in
                    ZStack(alignment: .top) {
                        FruitfolioImage(id: .fruitbasket_rain, contentMode: .fill)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .opacity(0.23)
                            .clipped()

                        FruitfolioImage(id: .fruitbasket_rain_cloud)
                            .frame(width: min(proxy.size.width * 0.58, 220))
                            .padding(.top, max(58, proxy.safeAreaInsets.top + 28))
                            .opacity(0.78)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .onAppear {
                    Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_rain)
                    Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_rain_cloud)
                    audioManager.play(.fruitBasketRainObstacle)
                }
            }
        } else {
            Color.clear.allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.screen {
        case .home:
            home

        case .howItWorks:
            howItWorks

        case .learningSetup,
             .topicProgressChoice,
             .loading,
             .topicUnsupported,
             .topicExhausted,
             .error:
            learningFlow

        case .question,
             .correctFeedback,
             .incorrectFeedback,
             .catchIntro:
            questionFlow

        case .catchActive,
             .paused:
            gameplay

        case .catchUnsuccessful:
            unsuccessful

        case .basketReveal:
            basketReveal

        case .leaderboard:
            leaderboard

        case .resetConfirmation:
            resetConfirmation
        }
    }

    private var topBar: some View {
        HStack {
            BackControl {
                onBack()
            }

            Spacer()

            if viewModel.screen != .home {
                Button("fruit basket") {
                    audioManager.play(.buttonSoftPop)
                    viewModel.screen = .home
                }
                .prompt28Text(.secondary)
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion: motionPreferences.reduceMotionActive
                    )
                )
                .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var home: some View {
        GeometryReader { proxy in
        ScrollView {
        VStack(spacing: 10) {
            topBar

            Spacer(minLength: 8)

            Text("fruit basket")
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 34,
                        relativeTo: .largeTitle
                    )
                )
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            FruitfolioImage(id: .fruit_strawberry_silly)
                .frame(width: 92, height: 92)
                .accessibilityLabel("Strawberry")

            Text("ready to collect some fruit\nand learn a little? ♡")
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 17,
                        relativeTo: .headline
                    )
                )
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            FruitfolioImage(id: .fruitbasket_basket)
                .frame(
                    width: 124,
                    height: 112
                )
                .accessibilityHidden(true)
                .onAppear {
                    Prompt28AssetUsageRegistrar.markRendered(
                        .fruitbasket_basket
                    )
                }

            VStack(spacing: 4) {
                Prompt28WatercolorButton(
                    title: "play",
                    accent: .paleYellow
                ) {
                    viewModel.openSetup()
                }

                Prompt28WatercolorButton(
                    title: "how it works",
                    accent: .mint
                ) {
                    viewModel.screen = .howItWorks
                }

                Prompt28WatercolorButton(
                    title: "leaderboard",
                    accent: .lavender
                ) {
                    viewModel.screen = .leaderboard
                }
            }
            .frame(maxWidth: 292)

            Spacer(minLength: 18)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .frame(minHeight: proxy.size.height)
        }
        }
    }

    private var howItWorks: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar

                Text("how it works ♡")
                    .prompt28Text(.screenTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                VStack(spacing: 10) {
                    Prompt28CompactRuleCard(
                        title: "1. pick what you wanna learn",
                        body: "type a topic + choose how deep you wanna go."
                    )

                    Prompt28CompactRuleCard(
                        title: "2. answer",
                        artID: .popup_speech_bubble,
                        body: "pick what you think is right."
                    )

                    Prompt28CompactRuleCard(
                        title: "3. catch",
                        artID: .fruitbasket_basket,
                        body: "catch the GOOD fruit that fits the rule. standalone stars are bonus passes and do not fill the basket."
                    )

                    Prompt28CompactRuleCard(
                        title: "4. fill your basket",
                        artID: .fruitbasket_strawberry,
                        body: "a BAD fruit ends the round unless you have a star pass — then exactly one pass is used and you keep going."
                    )
                }
                .frame(maxWidth: 330)

                FruitfolioNativeActionLabel(
                    text: "catching gets a little trickier as your game level grows, but you can start the game level over whenever you want. ☆", localizationKey: "catching gets a little trickier as your game level grows, but you can start the game level over whenever you want. ☆",
                    fontName: "ChalkboardSE-Regular", pointSize: 13, textStyle: .subheadline)
                .multilineTextAlignment(.center)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .frame(maxWidth: 300)

                VStack(spacing: 4) {
                    Prompt28WatercolorButton(
                        title: "show me the tour again",
                        accent: .lavender
                    ) {
                        store.resetTourForReplay()
                        tourStep = 0
                        showTour = true
                    }

                    Prompt28WatercolorButton(
                        title: "got it!",
                        accent: .paleYellow
                    ) {
                        viewModel.screen = .home
                    }
                }
                .frame(maxWidth: 292)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    @ViewBuilder
    private var learningFlow: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar

                Prompt28PaperPanel {
                    VStack(
                        alignment: .center,
                        spacing: 14
                    ) {
                        Text("what do you wanna learn about? ♡")
                            .prompt28Text(.screenTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        TextField(
                            "type literally anything…",
                            text: $viewModel.rawTopic,
                            axis: .vertical
                        )
                        .textInputAutocapitalization(.never)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 15,
                                relativeTo: .body
                            )
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 278)
                        .background(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .fill(
                                DesignTokens
                                    .ColorToken
                                    .backgroundCream
                                    .opacity(0.94)
                            )
                        )
                        .overlay(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                            .stroke(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                                    .opacity(0.16),
                                lineWidth: 1
                            )
                        )

                        Text("or pick something ✿")
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                        Prompt28ChipWrap(
                            titles: Prompt28LearningTopic.allCases.map(\.displayName),
                            onSelect: viewModel.chooseSuggestedTopic
                        )
                        .frame(maxWidth: 286)

                        Text("how deep should we go?")
                            .prompt28Text(.sectionHeading)
                            .multilineTextAlignment(.center)

                        let difficultyLayout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(spacing: 6)) : AnyLayout(HStackLayout(spacing: 6))
                        difficultyLayout {
                            ForEach(Prompt28EducationalDifficulty.allCases) { option in
                                Prompt28MiniControlPill(title: option.displayName,
                                    isSelected: viewModel.difficulty == option) {
                                    viewModel.updateDifficulty(option)
                                }
                            }
                        }
                        .frame(maxWidth: 286)

                        if let progress = viewModel.progress {
                            VStack(spacing: 4) {
                                Text(
                                    "game level  ·  \(progress.currentGameLevel)"
                                )
                                .prompt28Text(.body)

                                if progress.totalRoundsCompleted > 0 {
                                    Text(
                                        "welcome back ♡ you made it to game level \(progress.currentGameLevel) here."
                                    )
                                    .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                                    .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: 280)

                        } else if !viewModel.normalizedTopic.isEmpty {
                            Text("starting at game level 1")
                                .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        }

                        controlModePicker

                        if let message = viewModel.message {
                            HStack(
                                alignment: .center,
                                spacing: 8
                            ) {
                                FruitfolioImage(
                                    id: .fruit_strawberry_silly
                                )
                                .frame(
                                    width: 48,
                                    height: 48
                                )
                                .accessibilityLabel("Strawberry")

                                Text(message)
                                    .prompt28Text(.body)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }
                            .frame(maxWidth: 280)
                        }

                        switch viewModel.screen {
                        case .loading:
                            ProgressView(
                                "looking through the little library…"
                            )
                            .tint(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                            )

                        case .topicProgressChoice:
                            VStack(spacing: 4) {
                                Prompt28WatercolorButton(
                                    title: "keep my level",
                                    accent: .paleYellow
                                ) {
                                    Task {
                                        await viewModel.continueReturningTopic(
                                            resetLevel: false
                                        )
                                    }
                                }

                                Prompt28WatercolorButton(
                                    title: "start catching easy again",
                                    accent: .mint
                                ) {
                                    Task {
                                        await viewModel.continueReturningTopic(
                                            resetLevel: true
                                        )
                                    }
                                }
                            }

                        case .topicUnsupported,
                             .topicExhausted,
                             .error:
                            Prompt28WatercolorButton(
                                title: "try another topic",
                                accent: .mint
                            ) {
                                viewModel.changeTopic()
                            }

                        default:
                            Prompt28WatercolorButton(
                                title: "let’s play!",
                                accent: .paleYellow
                            ) {
                                Task {
                                    await viewModel.startTopic()
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    private var controlModePicker: some View {
        VStack(
            alignment: .center,
            spacing: 7
        ) {
            Text("controls")
                .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

            HStack(spacing: 8) {
                ForEach(
                    Prompt28ControlMode.allCases
                ) { mode in
                    Prompt28MiniControlPill(
                        title: mode.displayName,
                        isSelected: store.controlMode == mode,
                        width: 136
                    ) {
                        viewModel.setControlMode(mode)
                    }
                }
            }

            Text(
                "classification keeps the same rules + points without reflex dragging."
            )
            .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(maxWidth: 280)
        }
    }

    @ViewBuilder
    private var questionFlow: some View {
        GeometryReader { proxy in
        ScrollView {
        VStack(spacing: 14) {
            topBar

            Spacer(minLength: 4)

            if let question = viewModel.currentQuestion {
                Prompt28PaperPanel {
                    VStack(
                        alignment: .leading,
                        spacing: 13
                    ) {
                        HStack {
                            Text(question.topicQuery)
                                .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            Spacer()

                            Text(
                                question.educationalDifficulty.displayName
                            )
                            .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        }

                        Text(question.questionText)
                            .accessibilityIdentifier("fruitBasket.researchQuestion")
                            .prompt28Text(.screenTitle)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        ForEach(
                            question.answerOptions
                        ) { answer in
                            Button {
                                audioManager.play(.buttonSoftPop)
                                viewModel.answer(answer.id)
                            } label: {
                                HStack(alignment: .top) {
                                    Text(answer.text)
                                        .multilineTextAlignment(.leading)
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )

                                    Spacer(minLength: 10)
                                }
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: 52,
                                    alignment: .leading
                                )
                                .padding(.horizontal, 13)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: 17,
                                        style: .continuous
                                    )
                                    .fill(
                                        answerFill(
                                            answerID: answer.id,
                                            question: question
                                        )
                                    )
                                )
                            }
                            .accessibilityIdentifier("fruitBasket.answer.\(question.answerOptions.firstIndex(of: answer) ?? 0)")
                            .prompt28Text(.body)
                            .buttonStyle(
                                CutePopButtonStyle(
                                    reduceMotion:
                                        motionPreferences.reduceMotionActive
                                )
                            )
                            .disabled(
                                viewModel.selectedAnswerID != nil
                            )
                        }

                        if viewModel.screen == .incorrectFeedback {
                            HStack(
                                alignment: .top,
                                spacing: 10
                            ) {
                                FruitfolioImage(
                                    id: .fruit_peach_soft
                                )
                                .frame(
                                    width: 64,
                                    height: 64
                                )
                                .accessibilityLabel("Peach")

                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
                                    Text(
                                        "not quite :,) here’s the little reason why."
                                    )
                                    .prompt28Text(.body)

                                    Text(question.explanation)
                                        .prompt28Text(.body)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                                    Text(
                                        "sources · \(question.sourceIDs.count)"
                                    )
                                    .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                                }
                            }

                            Prompt28WatercolorButton(
                                title: "got it ♡",
                                accent: .mint
                            ) {
                                viewModel.selectedAnswerID = nil
                                viewModel.screen = .question
                            }

                        } else if viewModel.screen == .correctFeedback {
                            HStack(spacing: 10) {
                                FruitfolioImage(
                                    id: .fruit_strawberry_silly
                                )
                                .frame(
                                    width: 62,
                                    height: 62
                                )
                                .accessibilityLabel("Strawberry")

                                Text("YAYYY! catch your fruit! ♡")
                                    .prompt28Text(.body)
                            }

                            Prompt28WatercolorButton(
                                title: "catch",
                                accent: .paleYellow
                            ) {
                                audioManager.play(.starChime)
                                viewModel.screen = .catchIntro
                            }

                        } else if viewModel.screen == .catchIntro {
                            Text(question.catchRule)
                                .prompt28Text(.body)

                            Text(
                                "starred fruit = catch it · unstarred fruit = let it pass. standalone stars bank one star pass each. a bad-fruit catch uses one pass; with none, the round ends."
                            )
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            Prompt28WatercolorButton(
                                title: "ready ♡",
                                accent: .paleYellow
                            ) {
                                viewModel.beginCatch()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 12)
        }
        .frame(minHeight: proxy.size.height)
        }
        }
    }

    private func answerFill(
        answerID: String,
        question: Prompt28Question
    ) -> Color {
        guard let selected = viewModel.selectedAnswerID else {
            return DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.86)
        }

        if answerID == question.correctAnswerID {
            return DesignTokens
                .ColorToken
                .mint
                .opacity(0.72)
        }

        if answerID == selected {
            return DesignTokens
                .ColorToken
                .peach
                .opacity(0.72)
        }

        return DesignTokens
            .ColorToken
            .backgroundCream
            .opacity(0.62)
    }

    private var gameplay: some View {
        GeometryReader { proxy in
            let width = min(
                proxy.size.width,
                620
            )

            let xOffset =
                (proxy.size.width - width) / 2

            ZStack(alignment: .topLeading) {
                gameplayDecor(
                    width: width,
                    height: proxy.size.height,
                    xOffset: xOffset
                )

                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Button("pause") {
                            audioManager.play(.buttonSoftPop)
                            viewModel.pause()
                        }
                        .prompt28Text(.button)
                        .frame(width: 58, alignment: .leading)
                        .frame(minHeight: 44)

                        Spacer(minLength: 4)

                        Text(
                            "round \(viewModel.currentRound)  ·  game level \(viewModel.gameLevel)"
                        )
                        .prompt28Text(.metadata)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                        .frame(maxWidth: .infinity)

                        Spacer(minLength: 4)

                        Text("\(viewModel.score)")
                            .prompt28Text(.metadata)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .frame(width: 58, alignment: .trailing)
                    }
                    .padding(.horizontal, 20)

                    Text("\(viewModel.basketCount) / 10")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 16
                            )
                        )
                        .fontWeight(.bold)
                    Text("star passes: \(viewModel.session?.availableStarPasses ?? 0)")
                        .font(.custom("Chalkboard SE", size: 13, relativeTo: .subheadline))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("fruitBasket.availableStarPasses")
                        .accessibilityValue((viewModel.session?.availableStarPasses ?? 0) > 0
                            ? "one pass will be used if you catch a bad fruit; the round will continue"
                            : "with no star pass, a bad-fruit catch ends this round")
                }
                .frame(width: width)
                .offset(
                    x: xOffset,
                    y: 8
                )
                .zIndex(20)
                .fruitfolioModalBlur(active: viewModel.screen == .paused,
                    reduceMotion: motionPreferences.reduceMotionActive)

                if viewModel.screen == .paused {
                    ScrollView(.vertical) {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            pausePanel
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: max(44, proxy.size.height - 32))
                    }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(maxHeight: max(44, proxy.size.height - 32))
                        .accessibilityIdentifier("fruitBasket.pauseMenu")
                        .accessibilityAddTraits(.isModal)
                        .frame(
                            width: min(
                                width - 40,
                                380
                            )
                        )
                        .position(
                            x: proxy.size.width / 2,
                            y: proxy.size.height / 2
                        )
                        .zIndex(80)

                } else if store.controlMode == .classification {
                    classificationGameplay(
                        width: width,
                        height: proxy.size.height,
                        xOffset: xOffset
                    )

                } else {
                    catchGameplay(
                        width: width,
                        height: proxy.size.height,
                        xOffset: xOffset
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: viewModel.basketCount) { oldValue, newValue in
            if newValue > oldValue {
                audioManager.play(.fruitCatch)
            }
        }
        .onChange(of: viewModel.basketX) { _, _ in
            audioManager.setBasketPuddleInteraction(overlapping: viewModel.puddleContactActive, moving: viewModel.puddleMovementActive, owner: viewModel.obstacleAudioOwnerID)
        }
        .onChange(of: viewModel.puddleContactActive) { _, contact in
            audioManager.setBasketPuddleInteraction(overlapping: contact, moving: viewModel.puddleMovementActive, owner: viewModel.obstacleAudioOwnerID)
        }
        .onChange(of: viewModel.puddleMovementActive) { _, moving in
            audioManager.setBasketPuddleInteraction(overlapping: viewModel.puddleContactActive, moving: moving, owner: viewModel.obstacleAudioOwnerID)
        }
        .onChange(of: viewModel.branchContactCount) { oldValue, newValue in
            for _ in 0..<max(0, newValue - oldValue) { audioManager.playBasketBranchImpact(owner: viewModel.obstacleAudioOwnerID) }
        }
        .onChange(of: viewModel.vineContactCount) { oldValue, newValue in
            if newValue > oldValue { audioManager.play(.vineRustle) }
        }
        .onChange(of: viewModel.session?.availableStarPasses ?? 0) { oldValue, newValue in
            if newValue > oldValue { audioManager.play(.starChime) }
            else if newValue < oldValue { audioManager.play(.notificationSoftSparkle) }
            if UIAccessibility.isVoiceOverRunning {
                let change = newValue > oldValue ? "star pass banked" : "one star pass used"
                UIAccessibility.post(notification: .announcement, argument: "\(change). star passes: \(newValue).")
            }
        }
    }

    @ViewBuilder
    private func gameplayDecor(
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat
    ) -> some View {
        if viewModel.activeObstacles.contains(.vines) {
            FruitfolioImage(
                id: .fruitbasket_vines,
                contentMode: .fit
            )
            .frame(width: width * (viewModel.gameLevel == 2 ? 0.20 : 0.30))
            .position(
                x: xOffset + width * (viewModel.gameLevel == 2 ? 0.07 : 0.11),
                y: height * 0.54
            )
            .opacity(viewModel.gameLevel == 2 ? 0.46 : 0.66)
            .zIndex(12)
            .accessibilityHidden(true)
            .onAppear {
                Prompt28AssetUsageRegistrar.markRendered(
                    .fruitbasket_vines
                )
            }
        }

        if viewModel.activeObstacles.contains(.branch) {
            let branchGeometry = Prompt28BranchContactGeometry(fieldWidth: width, fieldHeight: height)
            FruitfolioImage(
                id: .fruitbasket_branch
            )
            .frame(width: branchGeometry.artworkWidth)
            .scaleEffect(x: -1, y: 1)
            .position(
                x: xOffset + branchGeometry.artworkCenterX,
                y: height * 0.40
            )
            .opacity(0.78)
            .zIndex(12)
            .accessibilityHidden(true)
            .onAppear {
                Prompt28AssetUsageRegistrar.markRendered(
                    .fruitbasket_branch
                )
            }
        }

        if viewModel.activeObstacles.contains(.puddle) {
            Prompt28PuddleArtwork(reduceMotion: motionPreferences.reduceMotionActive)
            .frame(width: min(width * 0.34, 190))
            .position(
                x: xOffset + width * 0.50,
                y: height * 0.905
            )
            .opacity(0.62)
            .zIndex(2)
            .accessibilityHidden(true)
            .onAppear {
                Prompt28AssetUsageRegistrar.markRendered(
                    .fruitbasket_puddle
                )
            }
        }
    }

    private func catchGameplay(
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat
    ) -> some View {
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: width, fieldHeight: height)
        return ZStack(alignment: .topLeading) {
            // Original handle/back rim behind moving items; original front rim
            // above them. Complementary masks preserve every artwork pixel.
            Prompt28BasketProgressView(count: viewModel.basketCount,
                settledCatches: viewModel.settledCatches, layer: .back)
                .frame(width: geometry.containerWidth, height: Prompt28BasketCatchGeometry.containerHeight)
                .rotationEffect(.degrees(motionPreferences.reduceMotionActive || !viewModel.basketIsMeetingPuddleResistance ? 0 : -3))
                .animation(motionPreferences.reduceMotionActive ? nil : .easeOut(duration: 0.12), value: viewModel.basketX)
                .position(x: xOffset + width * viewModel.basketX, y: height * Prompt28BasketCatchGeometry.centerYFraction)
                .zIndex(5).accessibilityHidden(true)
            ForEach(
                viewModel.activeFruit
            ) { fruit in
                Prompt28MovingFruit(
                    fruit: fruit,
                    reduceMotion:
                        motionPreferences.reduceMotionActive
                )
                .frame(
                    width: min(
                        max(
                            width * 0.13,
                            46
                        ),
                        66
                    ),
                    height: min(
                        max(
                            width * 0.13,
                            46
                        ),
                        66
                    )
                )
                .modifier(Prompt28VineResistanceVisual(
                    active: viewModel.isMeetingVines(x: fruit.x, y: fruit.y, classification: fruit.classification),
                    reduceMotion: motionPreferences.reduceMotionActive, phase: fruit.y))
                .position(
                    x: xOffset + width * fruit.x,
                    y: height * fruit.y
                )
                .zIndex(10)
                .onAppear {
                    Prompt28AssetUsageRegistrar.markRendered(
                        fruit.fruitID.assetID
                    )
                }
            }

            ForEach(viewModel.activeStars) { star in
                FruitfolioImage(id: .fruitbasket_star)
                    .frame(width: min(max(width * 0.10, 34), 52), height: min(max(width * 0.10, 34), 52))
                    .rotationEffect(.degrees(motionPreferences.reduceMotionActive ? 0 : star.rotationDegrees))
                    .modifier(Prompt28VineResistanceVisual(
                        active: viewModel.isMeetingVines(x: star.x, y: star.y),
                        reduceMotion: motionPreferences.reduceMotionActive, phase: star.y))
                    .position(x: xOffset + width * star.x, y: height * star.y)
                    .zIndex(11)
                    .accessibilityLabel("star pass")
            }

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                settledCatches: viewModel.settledCatches,
                layer: .front,
                onPresentation: { [weak model = viewModel] id, event in model?.handleCatchPresentation(id: id, event: event) }
            )
            .frame(
                width: min(
                    width * 0.36,
                    150
                ),
                height: 132
            )
            .rotationEffect(.degrees(motionPreferences.reduceMotionActive || !viewModel.basketIsMeetingPuddleResistance ? 0 : -3))
            .animation(motionPreferences.reduceMotionActive ? nil : .easeOut(duration: 0.12), value: viewModel.basketX)
            .position(
                x: xOffset + width * viewModel.basketX,
                y: height * Prompt28BasketCatchGeometry.centerYFraction
            )
            .gesture(
                DragGesture(
                    minimumDistance: 0,
                    coordinateSpace: .named("prompt28Playfield")
                )
                .onChanged { value in
                    let normalized = Double(
                        (value.location.x - xOffset)
                        / width
                    )

                    viewModel.moveBasket(
                        to: normalized
                    )
                }
                .onEnded { _ in viewModel.basketMovementEnded() }
            )
            .zIndex(30)
            .accessibilityLabel(
                "Basket, \(viewModel.basketCount) of 10"
            )
            .accessibilityValue("position \(Int((viewModel.basketX * 100).rounded())) percent; " + (viewModel.basketIsMeetingPuddleResistance ? "moving through a puddle with resistance" : "normal movement"))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: viewModel.moveBasket(to: viewModel.basketX + 0.08)
                case .decrement: viewModel.moveBasket(to: viewModel.basketX - 0.08)
                @unknown default: break
                }
                viewModel.basketMovementEnded()
            }
        }
        .coordinateSpace(name: "prompt28Playfield")
        .contentShape(Rectangle())
        .onAppear { viewModel.updateGameplayFieldSize(width: width, height: height) }
        .onChange(of: CGSize(width: width, height: height)) { _, size in
            viewModel.updateGameplayFieldSize(width: size.width, height: size.height)
        }
    }

    @ViewBuilder
    private func classificationGameplay(
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat
    ) -> some View {
        VStack(spacing: 14) {
            Spacer()
                .frame(height: 92)

            if let fruit =
                viewModel.classificationFruit {

                Prompt28MovingFruit(
                    fruit: fruit,
                    reduceMotion: true
                )
                .frame(
                    width: 100,
                    height: 100
                )
                .accessibilityLabel(
                    "\(fruit.fruitID.displayName). Does this belong in the basket?"
                )
                .onAppear {
                    Prompt28AssetUsageRegistrar.markRendered(
                        fruit.fruitID.assetID
                    )
                }

                Text(
                    "does this belong in the basket?"
                )
                .prompt28Text(.sectionHeading)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        classificationYesButton
                        classificationNoButton
                    }

                    VStack(spacing: 8) {
                        classificationYesButton
                        classificationNoButton
                    }
                }
                .frame(maxWidth: 292)
            }

            Spacer()

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                settledCatches: viewModel.settledCatches
            )
            .frame(
                width: 150,
                height: 132
            )

            Spacer()
                .frame(height: 20)
        }
        .frame(
            width: width,
            height: height
        )
        .offset(x: xOffset)
    }

    private var classificationYesButton: some View {
        Prompt28WatercolorButton(
            title: "yes ♡",
            accent: .mint
        ) {
            viewModel.classificationDecision(accept: true)
        }
    }

    private var classificationNoButton: some View {
        Prompt28WatercolorButton(
            title: "nope!",
            accent: .peach
        ) {
            viewModel.classificationDecision(accept: false)
        }
    }

    private var pausePanel: some View {
        Prompt28PaperPanel {
            VStack(spacing: 10) {
                Text("little game menu")
                    .prompt28Text(.sectionHeading)

                Prompt28WatercolorButton(
                    title: "resume",
                    accent: .paleYellow
                ) {
                    viewModel.resume()
                }
                .accessibilityValue("score \(viewModel.score), caught \(viewModel.basketCount) of 10, star passes \(viewModel.availableStarPasses), round \(viewModel.currentRound)")

                Prompt28WatercolorButton(
                    title: "change topic",
                    accent: .mint
                ) {
                    viewModel.changeTopic()
                }

                Prompt28WatercolorButton(
                    title: "change question difficulty",
                    accent: .lavender
                ) {
                    viewModel.screen = .learningSetup
                }

                Prompt28WatercolorButton(
                    title: "start catching easy again",
                    accent: .peach
                ) {
                    viewModel.screen = .resetConfirmation
                }

                Prompt28WatercolorButton(
                    title: "exit fruit basket",
                    accent: .sage
                ) {
                    onBack()
                }
            }
        }
    }

    private var unsuccessful: some View {
        VStack(spacing: 14) {
            topBar

            Spacer()

            Prompt28PaperPanel {
                VStack(spacing: 12) {
                    FruitfolioImage(
                        id: .fruit_peach_soft
                    )
                    .frame(
                        width: 88,
                        height: 88
                    )
                    .accessibilityLabel("Peach")

                    Text(
                        "oopsie :,) that one didn’t belong in this basket."
                    )
                    .prompt28Text(.sectionHeading)
                    .multilineTextAlignment(.center)

                    if let question =
                        viewModel.currentQuestion {

                        Text(
                            "for this round, we were collecting fruits that fit: \(question.catchRule)"
                        )
                        .prompt28Text(.body)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        .multilineTextAlignment(.center)
                    }

                    Text(
                        "your score didn’t lose any points ♡"
                    )
                    .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                    Prompt28WatercolorButton(
                        title: "try this round again ♡",
                        accent: .paleYellow
                    ) {
                        viewModel.retryRound()
                    }

                    Prompt28WatercolorButton(
                        title: "next question",
                        accent: .mint
                    ) {
                        Task {
                            await viewModel.loadQuestion()
                        }
                    }

                    Prompt28WatercolorButton(
                        title: "change topic",
                        accent: .lavender
                    ) {
                        viewModel.changeTopic()
                    }
                }
            }
            .frame(maxWidth: 400)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private var basketReveal: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar

                ZStack {
                    if viewModel.didSetPersonalBestThisRound {
                        Prompt28WatercolorConfettiBurst(
                            reduceMotion: motionPreferences.reduceMotionActive
                        )
                        .frame(width: 270, height: 190)
                        .accessibilityHidden(true)

                        FruitfolioImage(id: .fruitbasket_star_balloons)
                            .frame(width: 150, height: 170)
                            .offset(y: -8)
                            .accessibilityHidden(true)
                            .onAppear {
                                Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_star_balloons)
                            }

                        FruitfolioImage(id: .fruitbasket_confetti)
                            .frame(width: 250, height: 180)
                            .opacity(motionPreferences.reduceMotionActive ? 0.42 : 0.66)
                            .accessibilityHidden(true)
                            .onAppear {
                                Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_confetti)
                            }
                    }

                    Prompt28BasketProgressView(
                        count: 10,
                        settledCatches: viewModel.settledCatches.filter(\.collected)
                    )
                    .frame(width: 210, height: 180)
                    .accessibilityHidden(true)
                }
                .frame(maxWidth: 300)
                .frame(height: 210)
                .overlay(alignment: .top) {
                    if viewModel.didSetPersonalBestThisRound {
                        FruitfolioImage(id: .fruitbasket_crown)
                            .frame(width: 50, height: 46)
                            .padding(.top, 2)
                            .accessibilityLabel("Personal best crown")
                            .onAppear {
                                Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_crown)
                            }
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    viewModel.didSetPersonalBestThisRound
                    ? "Basket full. 10 of 10. Round complete. Personal best."
                    : "Basket full. 10 of 10. Round complete."
                )

                Prompt28PaperPanel {
                    VStack(
                        alignment: .leading,
                        spacing: 11
                    ) {
                        Text(
                            "your basket reveal!"
                        )
                        .prompt28Text(.screenTitle)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("good fruit collected: \(viewModel.roundCollection.goodFruit.count)")
                            Text("unstarred fruit caught: \(viewModel.roundCollection.badFruit.count)")
                            Text("standalone stars collected: \(viewModel.roundCollection.standaloneStarsCaught)")
                            Text("star passes used: \(viewModel.roundCollection.starPassesConsumed)")
                            Text("star passes available: \(viewModel.availableStarPasses)")
                            Text("score this round: \(viewModel.score - viewModel.roundCollection.startingScore)")
                        }
                        .prompt28Text(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("fruitBasket.actualRoundResults")

                        if let question =
                            viewModel.currentQuestion {

                            Text(
                                "here’s the research behind your question."
                            )
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            if !viewModel.revealFacts.isEmpty {
                                ForEach(Array(viewModel.revealFacts.enumerated()), id: \.element.id) { index, fact in
                                    VStack(alignment: .leading, spacing: 5) {
                                        if viewModel.revealFacts.count > 1 {
                                            Text("\(index + 1) of \(viewModel.revealFacts.count)")
                                                .prompt28Text(.metadata)
                                        }
                                        FruitfolioSemanticText(document: .init(spans: [.init(text: fact.text)]),
                                            baseFont: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .accessibilityElement(children: .contain)
                                    .accessibilityIdentifier("fruitBasket.fact." + fact.id)
                                }
                            } else {
                                Text(question.explanation).prompt28Text(.body)
                                Text("the original evidence snapshot for these notes could not be verified.")
                                    .prompt28Text(.secondary)
                            }
                            ForEach(question.sourceTitles, id: \.self) { reference in
                                Text(reference).prompt28Text(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(
                                "sources · \(question.sourceIDs.count)"
                            )
                            .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        }

                        Prompt28WatercolorButton(
                            title: "save to my encyclopedia",
                            accent: .sage
                        ) {
                            showingSaveDestination = true
                        }

                        Prompt28WatercolorButton(
                            title: "keep playing",
                            accent: .paleYellow
                        ) {
                            Task {
                                await viewModel.continueAfterReveal()
                            }
                        }

                        Prompt28WatercolorButton(
                            title: "change topic",
                            accent: .mint
                        ) {
                            viewModel.changeTopic()
                        }

                        Prompt28WatercolorButton(
                            title: "change difficulty",
                            accent: .lavender
                        ) {
                            viewModel.screen = .learningSetup
                        }

                        Prompt28WatercolorButton(
                            title: "start catching easy again",
                            accent: .peach
                        ) {
                            viewModel.screen =
                                .resetConfirmation
                        }
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            audioManager.play(.gentleCheer)
        }
    }

    private var leaderboard: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar

                ZStack {
                    FruitfolioImage(id: .fruitbasket_chalkboard)
                        .frame(maxWidth: 340)
                        .accessibilityHidden(true)
                        .onAppear {
                            Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_chalkboard)
                        }

                    VStack(spacing: 8) {
                        Text("top 3 players")
                            .font(.custom("Chalkboard SE", size: 20, relativeTo: .title2))
                            .fontWeight(.bold)

                        VStack(spacing: 6) {
                            ForEach(Prompt28LeaderboardCategory.allCases, id: \.self) { category in
                                Button {
                                    selectedLeaderboardCategory = category
                                } label: {
                                    Text(category.rawValue)
                                        .font(.custom("Chalkboard SE", size: 12, relativeTo: .caption))
                                        .fontWeight(selectedLeaderboardCategory == category ? .bold : .regular)
                                        .foregroundStyle(
                                            selectedLeaderboardCategory == category
                                            ? Color.white
                                            : DesignTokens.ColorToken.backgroundCream.opacity(0.72)
                                        )
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.75)
                                }
                                .buttonStyle(CutePopButtonStyle())
                                .accessibilityAddTraits(
                                    selectedLeaderboardCategory == category ? .isSelected : []
                                )
                            }
                        }
                        .frame(maxWidth: 245)

                        VStack(spacing: 6) {
                            Prompt28LeaderboardRow(rank: 1, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                            Prompt28LeaderboardRow(rank: 2, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                            Prompt28LeaderboardRow(rank: 3, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                        }
                        .frame(maxWidth: 245)

                        Text("your on-device total: \(selectedLeaderboardCategory.localTotal(store.leaderboardTotals))")
                            .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("your on-device \(selectedLeaderboardCategory.accessibilityUnit): \(selectedLeaderboardCategory.localTotal(store.leaderboardTotals))")

                        Text("worldwide rankings unavailable until secure registration is configured ♡")
                            .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 220)
                    }
                    .foregroundStyle(DesignTokens.ColorToken.backgroundCream)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 30)
                }
                .frame(maxWidth: 340)
                .accessibilityElement(children: .contain)

                Prompt28PaperPanel {
                    VStack(spacing: 10) {
                        Text("fruit basket leaderboard")
                            .prompt28Text(.sectionHeading)
                            .multilineTextAlignment(.center)

                        TextField(
                            "public username",
                            text: Binding(
                                get: { leaderboardUsernameDraft },
                                set: { raw in
                                    // Preserve the actual draft, including invalid input,
                                    // so validation can explain it without silently changing
                                    // the identity the user intended to enter.
                                    leaderboardUsernameDraft = raw
                                    if let error = Prompt28LeaderboardUsernamePolicy.validationMessage(for: raw) {
                                        leaderboardValidationMessage = error
                                    } else {
                                        leaderboardValidationMessage = usernameStore.setUsername(raw)
                                    }
                                    if store.appearOnLeaderboard, !Prompt28LeaderboardUsernamePolicy.isValid(raw) {
                                        store.appearOnLeaderboard = false
                                    }
                                    store.persistPreferences()
                                }
                            )
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($leaderboardUsernameFocused)
                        .submitLabel(.done)
                        .onSubmit { leaderboardUsernameFocused = false }
                        .accessibilityIdentifier("fruitBasket.publicUsername")
                        .prompt28Text(.body)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 46)
                        .background(
                            DesignTokens.ColorToken.backgroundCream.opacity(0.82),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(DesignTokens.ColorToken.primaryBurgundy.opacity(0.18), lineWidth: 1)
                        }
                        .accessibilityHint(
                            "Three to sixteen characters. Letters, numbers, periods, and underscores only. Public usernames cannot be explicit."
                        )

                        HStack {
                            Text("3–\(Prompt28LeaderboardUsernamePolicy.maximumLength) characters")
                            Spacer()
                            Text("\(leaderboardUsernameDraft.count)/\(Prompt28LeaderboardUsernamePolicy.maximumLength)")
                                .monospacedDigit()
                        }
                        .prompt28Text(.metadata)
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.68))

                        if let leaderboardValidationMessage {
                            Text(leaderboardValidationMessage)
                                .prompt28Text(.secondary)
                                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        WatercolorToggle(
                            label: "appear on the leaderboard",
                            isOn: leaderboardOptInBinding
                        )
                        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))

                        if Prompt28LeaderboardUsernamePolicy.isValid(usernameStore.username) {
                            HStack(spacing: 6) {
                                Text("public name")
                                    .prompt28Text(.metadata)
                                Spacer(minLength: 8)
                                Text(usernameStore.username)
                                    .prompt28Text(.body)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.80)
                            }
                            .frame(maxWidth: .infinity)
                        }

                        Text(
                            "topics, difficulty, wrong answers, accuracy, bad-fruit catches, accessibility mode, health data, and saved content are never leaderboard fields."
                        )
                        .prompt28Text(.metadata)
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .onChange(of: usernameStore.username) { _, newValue in
            // The authority publishes valid intermediate edits. Reflecting a
            // delayed echo while focused can reinsert the last valid prefix
            // after the user deletes below the minimum length.
            if !leaderboardUsernameFocused, leaderboardUsernameDraft != newValue {
                leaderboardUsernameDraft = newValue
            }
        }
        .onAppear {
            leaderboardUsernameDraft = usernameStore.username
            leaderboardValidationMessage = usernameStore.username.isEmpty
                ? nil
                : Prompt28LeaderboardUsernamePolicy.validationMessage(for: usernameStore.username)
        }
    }

    private var leaderboardOptInBinding: Binding<Bool> {
        Binding(
            get: { store.appearOnLeaderboard },
            set: { wantsToAppear in
                if !wantsToAppear {
                    store.appearOnLeaderboard = false
                    leaderboardValidationMessage = nil
                    store.persistPreferences()
                    return
                }

                if let message = usernameStore.setUsername(leaderboardUsernameDraft) {
                    store.appearOnLeaderboard = false
                    leaderboardValidationMessage = message
                } else {
                    // A local username is not a globally reserved username.
                    // Do not publish or claim opt-in before server verification.
                    store.appearOnLeaderboard = false
                    leaderboardValidationMessage = "worldwide registration isn't available yet ♡ your name is saved on this device only."
                }
                store.persistPreferences()
            }
        )
    }

    private var resetConfirmation: some View {
        VStack(spacing: 14) {
            topBar

            Spacer()

            Prompt28PaperPanel {
                VStack(spacing: 11) {
                    Text(
                        "start this topic’s game level over?"
                    )
                    .prompt28Text(.sectionHeading)
                    .multilineTextAlignment(.center)

                    Text(
                        "the catching will go back to the gentlest level. your learning topic, question difficulty, saved encyclopedia entries, and scores won’t disappear."
                    )
                    .prompt28Text(.body)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                    .multilineTextAlignment(.center)

                    Prompt28WatercolorButton(
                        title: "yes, reset level",
                        accent: .paleYellow
                    ) {
                        viewModel.resetGameLevel()
                    }

                    Prompt28WatercolorButton(
                        title: "never mind",
                        accent: .mint
                    ) {
                        viewModel.screen = .paused
                    }
                }
            }
            .frame(maxWidth: 400)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func rule(
        _ title: String,
        _ body: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            Text(title)
                .prompt28Text(.sectionHeading)

            Text(body)
                .prompt28Text(.body)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
        }
    }

    private var tourOverlay: some View {
        GeometryReader { viewport in
        ZStack {
            Prompt28CompactPopupCard(maximumHeight: dynamicTypeSize.isAccessibilitySize
                ? max(44, viewport.size.height - viewport.safeAreaInsets.top - viewport.safeAreaInsets.bottom - 32) : nil) {
                VStack(spacing: 8) {
                    FruitfolioImage(
                        id: .fruit_strawberry_silly
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .accessibilityLabel("Strawberry")

                    FruitfolioNativeActionLabel(text: "\(tourStep + 1) of 10",
                        fontName: "ChalkboardSE-Regular", pointSize: 11, textStyle: .caption)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(tourTitle)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($tourHeadingFocused)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 16,
                                relativeTo: .headline
                            )
                        )
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    FruitfolioNativeActionLabel(text: tourBody,
                        fontName: "ChalkboardSE-Regular", pointSize: 13, textStyle: .body,
                        lineSpacing: 2)
                        .fixedSize(horizontal: false, vertical: true)

                    if tourStep == 4 {
                        HStack(spacing: 16) {
                            Prompt28TourFruit(
                                fruit: .apple,
                                classification: .good
                            )

                            Prompt28TourFruit(
                                fruit: .lemon,
                                classification: .bad
                            )
                        }
                    }

                    Prompt28WatercolorButton(
                        title:
                            tourStep == 9
                            ? "let’s play!"
                            : "next ♡",
                        accent: .paleYellow
                    ) {
                        if tourStep >= 9 {
                            store.completeTour()
                            showTour = false
                            viewModel.openSetup()

                        } else {
                            tourStep += 1
                        }
                    }
                    .frame(maxWidth: 242)

                    if tourStep == 0 {
                        Button {
                            skipTourToRules()
                        } label: {
                            HStack(spacing: 0) {
                                Spacer(minLength: 0)
                                FruitfolioNativeActionLabel(text: "skip tour", localizationKey: "skip tour", fontName: "ChalkboardSE-Regular",
                                    pointSize: 13, textStyle: .subheadline)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .accessibilityElement(children: .contain)
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(Text("skip tour"))
                        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                    }
                }
            }
            .frame(maxWidth: 292)
            .padding(.horizontal, 20)
        }
        .frame(width: viewport.size.width, height: viewport.size.height)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .onAppear {
            audioManager.play(.popupOpen)
            tourHeadingFocused = true
        }
        .onDisappear { audioManager.play(.popupClose) }
        .accessibilityAction(.escape) { skipTourToRules() }
        .onChange(of: tourStep) { _, _ in
            tourHeadingFocused = false
            Task { @MainActor in
                await Task.yield()
                tourHeadingFocused = true
            }
        }
    }

    private func skipTourToRules() {
        audioManager.play(.buttonSoftPop)
        viewModel.screen = .howItWorks
        store.skipTourAfterRules()
        showTour = false
    }

    private var tourTitle: String {
        [
            "welcome to the Fruit Basket!",
            "pick what you wanna learn",
            "your game level",
            "answer the question",
            "the catch rule",
            "practice a good catch",
            "missing is okay",
            "let bad fruit pass",
            "fill to 10",
            "one last reminder"
        ][tourStep]
    }

    private var tourBody: String {
        [
            "you pick something you wanna learn about, answer a little question, and then fill your basket with the fruits that belong. ♡",
            "type any topic the approved library supports, then choose easy, medium, or hard. that only changes how deep the questions go.",
            "game level only changes the catching. you can start a topic’s game level over whenever you want without changing the science.",
            "pick the answer you think is right. a wrong answer shows the correct answer + sourced explanation, with no point loss.",
            "catch the fruit that belongs in your basket. standalone stars are rare bonus drops: each one banks one star pass.",
            "a good catch adds +1 to your basket and +10 points. ten good fruits fills it.",
            "miss a good fruit? nothing gets taken away. another one will come along.",
            "bad fruit can fall away safely. if you catch one with a star pass banked, exactly one pass is used and the round keeps going. with zero passes, the round ends.",
            "the tenth good fruit lands first, the basket reaches 10 / 10, then the soft Basket Reveal explains what you collected.",
            "catch 10 good fruits. standalone stars bank protection for bad-fruit catches. question difficulty and game level stay separate. ♡"
        ][tourStep]
    }
}

private struct Prompt28MovingFruit: View {
    let fruit: Prompt28FallingFruit
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let starSize = min(max(side * 0.36, 18), 26)

            ZStack(alignment: .topTrailing) {
                FruitfolioImage(id: fruit.fruitID.assetID)
                    .frame(width: side * 0.88, height: side * 0.88)
                    .rotationEffect(
                        .degrees(reduceMotion ? 0 : fruit.rotationDegrees)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                if fruit.classification == .good {
                    FruitfolioImage(id: .fruitbasket_star)
                        .frame(width: starSize, height: starSize)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(fruit.fruitID.displayName), \(fruit.classification == .good ? "belongs in basket" : "does not belong in basket")"
        )
    }
}

private enum Prompt28Basket…9755 tokens truncated…ection.startingScore)"
        let revealBody = "basket reveal\n\n\(question.explanation)\n\n\(references)\n\n\(outcome)"
        return Prompt10PendingSavedContent(
            question: "basket reveal",
            answer: revealBody,
            saveType: .fullAnswer,
            originalAnswerID: "fruitbasket:\(question.id)",
            sourceIDs: question.sourceIDs,
            sourceVersions: Dictionary(uniqueKeysWithValues: (question.evidenceSnapshot?.sources ?? []).map { ($0.sourceID, $0.contentVersion) }),
            sourceSnapshots: question.evidenceSnapshot?.sources.map { source in
                AskSourceRecord(id: source.sourceID, title: source.apa7Reference ?? source.title,
                    sourceText: source.apa7Reference, urlString: source.canonicalURL, doi: source.doi,
                    publicationData: source.publicationDate, contentVersion: source.contentVersion)
            },
            knowledgeBaseVersion: question.contentVersion,
            generationTimestamp: question.createdAt
        )
    }

    private func startGameplayLoop() {
        gameplayTask?.cancel()
        gameplayTask = Task { [weak self] in
            var previous = Date()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 33_000_000)
                // Hold the model only during this synchronous frame. Keeping
                // a strong self before the loop retains it across every sleep
                // and prevents deinit's cancellation if a host drops the view
                // without delivering its ordinary disappearance callback.
                guard !Task.isCancelled, let self else { break }
                let now = Date()
                let delta = min(max(now.timeIntervalSince(previous), 0.001), 0.08)
                previous = now
                self.tick(delta: delta, now: now)
            }
        }
    }

    func updateGameplayFieldSize(width: Double, height: Double) {
        guard width.isFinite, height.isFinite, width > 0, height > 0 else { return }
        gameplayFieldSize = CGSize(width: width, height: height)
    }

    func isMeetingVines(x: Double, y: Double, classification: Prompt28FruitClassification = .good) -> Bool {
        guard classification == .good, activeObstacles.contains(.vines) else { return false }
        return Prompt28VineContactGeometry(fieldWidth: gameplayFieldSize.width,
                                          fieldHeight: gameplayFieldSize.height,
                                          level: gameLevel).contains(x: x, y: y)
    }

    // Internal frame entry point is also exercised by deterministic physics tests.
    func tick(delta: TimeInterval, now: Date) {
        guard screen == .catchActive, !isPaused, !roundResultLocked, delta.isFinite, delta >= 0 else { return }
        catchClock += delta
        var remaining: [Prompt28FallingFruit] = []
        var currentVineContacts: Set<UUID> = []

        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        for var fruit in activeFruit {
            let previousY = fruit.y
            let meetingVines = isMeetingVines(x: fruit.x, y: fruit.y, classification: fruit.classification)
            if meetingVines { currentVineContacts.insert(fruit.id) }
            let vineMultiplier = meetingVines ? 0.56 : 1.0
            if activeObstacles.contains(.branch), branchDeflections[fruit.id] == nil {
                let geometry = Prompt28BranchContactGeometry(fieldWidth: gameplayFieldSize.width,
                                                              fieldHeight: gameplayFieldSize.height)
                let radius = min(max(gameplayFieldSize.width * 0.13, 46), 66) * 0.44
                if geometry.contains(x: fruit.x, y: fruit.y + fruit.fallSpeed * delta, radius: radius) {
                    branchContactCount += 1
                    branchDeflections[fruit.id] = Prompt28BranchDeflection(horizontalVelocity: -max(abs(fruit.horizontalDrift), 0.08))
                }
            }
            let bounce = branchDeflections[fruit.id]
            fruit.y += fruit.fallSpeed * vineMultiplier * (bounce?.verticalMultiplier ?? 1) * delta
            var horizontalVelocity = bounce?.horizontalVelocity ?? fruit.horizontalDrift
            if var bounce {
                bounce.elapsed += delta
                branchDeflections[fruit.id] = bounce
            }
            if activeObstacles.contains(.wind) {
                horizontalVelocity += windDirection * (weather == .softRain ? 0.030 : 0.021)
            }

            fruit.x = min(max(fruit.x + horizontalVelocity * delta, laneBounds.lowerBound), laneBounds.upperBound)

            if engine.collision(fruitX: fruit.x, fruitY: fruit.y, basketX: basketX,
                                fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height,
                                itemDiameter: Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: gameplayFieldSize.width),
                                previousY: previousY) {
                beginLanding(id: fruit.id, kind: .fruit(fruit.fruitID, fruit.classification),
                             previousY: previousY, currentY: fruit.y,
                             diameter: Prompt28BasketCatchGeometry.fruitDiameter(fieldWidth: gameplayFieldSize.width), delta: delta)
                continue
            }

            if fruit.y > 1.06 {
                if fruit.classification == .good { handleGoodMiss() }
                else { handleBadMiss() }
                continue
            }

            remaining.append(fruit)
        }

        activeFruit = roundResultLocked ? [] : remaining
        let remainingIDs = Set(activeFruit.map(\.id))
        branchDeflections = branchDeflections.filter { remainingIDs.contains($0.key) }
        guard !roundResultLocked else { return }

        var remainingStars: [Prompt28FallingStar] = []
        for var star in activeStars {
            let previousY = star.y
            let meetingVines = isMeetingVines(x: star.x, y: star.y)
            if meetingVines { currentVineContacts.insert(star.id) }
            let vineMultiplier = meetingVines ? 0.56 : 1.0
            star.y += star.fallSpeed * vineMultiplier * delta
            star.x = min(max(star.x + star.horizontalDrift * delta, laneBounds.lowerBound), laneBounds.upperBound)
            if engine.collision(fruitX: star.x, fruitY: star.y, basketX: basketX,
                                fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height,
                                itemDiameter: Prompt28BasketCatchGeometry.starDiameter(fieldWidth: gameplayFieldSize.width),
                                previousY: previousY) {
                beginLanding(id: star.id, kind: .star, previousY: previousY, currentY: star.y,
                             diameter: Prompt28BasketCatchGeometry.starDiameter(fieldWidth: gameplayFieldSize.width), delta: delta)
                continue
            }
            if star.y <= 1.06 { remainingStars.append(star) }
        }
        activeStars = remainingStars
        collectReadyLandings()
        guard !roundResultLocked else { return }
        if !currentVineContacts.subtracting(previousVineContacts).isEmpty { vineContactCount += 1 }
        previousVineContacts = currentVineContacts

        let interval = random(in: levelConfig.spawnIntervalRange)
        if activeFruit.count < levelConfig.maxConcurrentItems,
           now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnFruit()
            lastSpawnAt = now
        }
    }

    private func spawnFruit() {
        guard let question = currentQuestion else { return }
        if Double.random(in: 0...1) < 0.06 {
            let duration = random(in: levelConfig.fallDurationRange)
            let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
            activeStars.append(Prompt28FallingStar(
                x: Double.random(in: max(0.12, laneBounds.lowerBound)...min(0.88, laneBounds.upperBound)),
                fallSpeed: 1.18 / max(duration, 0.5),
                horizontalDrift: random(in: levelConfig.driftRange),
                rotationDegrees: Double.random(in: -6...6)
            ))
            return
        }
        let classification = spawnPlanner.nextClassification(
            goodProbability: levelConfig.goodProbability,
            randomUnit: Double.random(in: 0...1)
        )
        let pool = classification == .good ? question.goodFruitIDs : question.badFruitIDs
        guard let fruitID = pool.randomElement() else { return }
        let duration = random(in: levelConfig.fallDurationRange)
        let speed = 1.18 / max(duration, 0.5)
        let drift = random(in: levelConfig.driftRange)
        let laneBounds = engine.fruitLaneBounds(level: gameLevel, round: currentRound)
        let x = Double.random(in: max(0.12, laneBounds.lowerBound)...min(0.88, laneBounds.upperBound))
        let rotation = Double.random(in: -6...6)
        activeFruit.append(
            Prompt28FallingFruit(
                fruitID: fruitID,
                classification: classification,
                x: x,
                fallSpeed: speed,
                horizontalDrift: drift,
                rotationDegrees: rotation
            )
        )
    }

    private func spawnClassificationFruit() {
        guard let question = currentQuestion else { return }
        let classification = spawnPlanner.nextClassification(
            goodProbability: levelConfig.goodProbability,
            randomUnit: Double.random(in: 0...1)
        )
        let pool = classification == .good ? question.goodFruitIDs : question.badFruitIDs
        guard let fruitID = pool.randomElement() else { return }
        classificationFruit = Prompt28FallingFruit(
            fruitID: fruitID,
            classification: classification,
            x: 0.5,
            y: 0.38,
            fallSpeed: 0,
            horizontalDrift: 0,
            rotationDegrees: 0
        )
    }

    private func beginLanding(id: UUID, kind: LandingKind, previousY: Double, currentY: Double,
                              diameter: Double, delta: TimeInterval) {
        guard !pendingLandings.contains(where: { $0.id == id }) else { return }
        let geometry = Prompt28BasketCatchGeometry(fieldWidth: gameplayFieldSize.width, fieldHeight: gameplayFieldSize.height)
        let threshold = (geometry.mouthY + diameter / 2) / gameplayFieldSize.height
        let fraction = currentY > previousY ? min(max((threshold - previousY) / (currentY - previousY), 0), 1) : 0
        let asset: FruitfolioAssetID
        let isStar: Bool
        switch kind {
        case .fruit(let fruit, _): asset = fruit.assetID; isStar = false
        case .star: asset = .fruitbasket_star; isStar = true
        }
        settledCatches.append(.init(id: id, assetID: asset, isStar: isStar))
        pendingLandings.append(.init(id: id, kind: kind,
            readyAt: catchClock - delta + fraction * delta + Prompt28BasketCatchGeometry.settlingDuration,
            order: landingOrder))
        landingOrder += 1
    }

    /// A real presentation completion, not a timer-only guess. Repeated/stale
    /// callbacks cannot collect twice. Paused games retain the acknowledgement
    /// but never advance scoring until active play resumes.
    func handleCatchPresentation(id: UUID, event: Prompt28CatchPresentationEvent) {
        guard let index = pendingLandings.firstIndex(where: { $0.id == id }) else { return }
        switch event {
        case .appeared(let token):
            pendingLandings[index].presentationID = token
            pendingLandings[index].artworkSettled = false
        case .settled(let token):
            guard pendingLandings[index].presentationID == token else { return }
            pendingLandings[index].artworkSettled = true
        case .disappeared(let token):
            guard pendingLandings[index].presentationID == token else { return }
            pendingLandings[index].presentationID = nil
            pendingLandings[index].artworkSettled = false
        }
        collectReadyLandings()
    }

    private func collectReadyLandings() {
        guard screen == .catchActive, !isPaused, !roundResultLocked else { return }
        let ready = pendingLandings.filter { $0.presentationID != nil && $0.artworkSettled && $0.readyAt <= catchClock }
            .sorted { $0.readyAt == $1.readyAt ? $0.order < $1.order : $0.readyAt < $1.readyAt }
        let readyIDs = Set(ready.map(\.id))
        pendingLandings.removeAll { readyIDs.contains($0.id) }
        var collectedIDs: Set<UUID> = []
        for landing in ready {
            guard !roundResultLocked else { break }
            collectedIDs.insert(landing.id)
            if let index = settledCatches.firstIndex(where: { $0.id == landing.id }) {
                settledCatches[index].collected = true
            }
            switch landing.kind {
            case .fruit(let fruit, .good): handleGoodCatch(fruit, existingArtworkID: landing.id)
            case .fruit(let fruit, .bad): handleBadCatch(fruit, existingArtworkID: landing.id)
            case .star: handleStarCatch(existingArtworkID: landing.id)
            }
        }
        if roundResultLocked {
            let uncollected = readyIDs.subtracting(collectedIDs).union(pendingLandings.map(\.id))
            settledCatches.removeAll { uncollected.contains($0.id) }
            pendingLandings.removeAll()
        }
    }

    private func handleGoodCatch(_ fruit: Prompt28FruitID, existingArtworkID: UUID? = nil) {
        guard !roundResultLocked, var session else { return }
        if existingArtworkID == nil {
            settledCatches.append(.init(id: UUID(), assetID: fruit.assetID, isStar: false, collected: true))
        }
        let outcome = engine.registerGoodCatch(session: &session)
        roundCollection.goodFruit.append(fruit)
        self.session = session
        if outcome == .success {
            roundResultLocked = true
            stopGameplay()
            roundCompletionTask?.cancel()
            roundCompletionTask = Task { [weak self] in
                try? await Task.sleep(nanoseconds: 650_000_000)
                guard !Task.isCancelled, let self else { return }
                self.finishSuccessfulRound()
            }
        }
    }

    private func handleGoodMiss() {
        guard !roundResultLocked, var session else { return }
        _ = engine.registerGoodMiss(session: &session)
        self.session = session
    }

    private func handleBadMiss() {
        guard !roundResultLocked, var session else { return }
        _ = engine.registerBadMiss(session: &session)
        self.session = session
    }

    private func handleStarCatch(existingArtworkID: UUID? = nil) {
        guard !roundResultLocked, var session else { return }
        if existingArtworkID == nil {
            settledCatches.append(.init(id: UUID(), assetID: .fruitbasket_star, isStar: true, collected: true))
        }
        _ = engine.registerStarCatch(session: &session)
        roundCollection.standaloneStarsCaught += 1
        self.session = session

        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalStarsEarned += 1
        store.updateProgress(progress)
    }

    private func handleBadCatch(_ fruit: Prompt28FruitID, existingArtworkID: UUID? = nil) {
        guard !roundResultLocked, var session else { return }
        if existingArtworkID == nil {
            settledCatches.append(.init(id: UUID(), assetID: fruit.assetID, isStar: false, collected: true))
        }
        let outcome = engine.registerBadCatch(fruit, session: &session)
        roundCollection.badFruit.append(fruit)
        if case .badFruitBlockedByStar = outcome { roundCollection.starPassesConsumed += 1 }
        self.session = session
        lastBadFruit = fruit
        if case .badFruitBlockedByStar = outcome { return }
        roundResultLocked = true
        stopGameplay()
        activeFruit.removeAll(); activeStars.removeAll(); classificationFruit = nil
        roundCompletionTask?.cancel()
        roundCompletionTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 280_000_000)
            guard !Task.isCancelled, let self else { return }
            self.finishUnsuccessfulRound()
        }
    }

    private func finishSuccessfulRound() {
        guard var session else { return }
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalRoundsCompleted += 1
        progress.totalSuccessfulRounds += 1
        progress.totalFruitCaught += Prompt28FruitBasketEngine.goodFruitTarget
        let newLevel = engine.levelAfterSuccessfulRounds(progress.totalSuccessfulRounds)
        progress.currentGameLevel = max(progress.currentGameLevel, newLevel)
        progress.highestGameLevelReached = max(progress.highestGameLevelReached, progress.currentGameLevel)
        didSetPersonalBestThisRound = session.score > progress.bestScore
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        recordCompletedRound(successful: true)
        screen = .basketReveal
    }

    private func finishUnsuccessfulRound() {
        guard var session else { return }
        var progress = store.ensureProgress(for: session.normalizedTopicID)
        progress.totalRoundsCompleted += 1
        progress.bestScore = max(progress.bestScore, session.score)
        progress.bestStreak = max(progress.bestStreak, session.currentStreak)
        store.updateProgress(progress)
        session.currentGameLevel = progress.currentGameLevel
        self.session = session
        recordCompletedRound(successful: false)
        screen = .catchUnsuccessful
    }

    private func recordCompletedRound(successful: Bool) {
        guard let session, let question = currentQuestion else { return }
        store.recordCompletedRound(.init(id: attemptID, sessionID: session.id,
            round: session.currentRound, completedAt: Date(), successful: successful,
            question: question, collection: roundCollection, finalScore: session.score,
            remainingStarPasses: session.availableStarPasses,
            personalBest: successful && didSetPersonalBestThisRound,
            educationalFacts: question.verifiedEducationalFacts))
    }

    private func stopGameplay() {
        gameplayCleanup?()
        puddleMovementActive = false
        puddleContactActive = false
        gameplayTask?.cancel(); gameplayTask = nil
        roundCompletionTask?.cancel(); roundCompletionTask = nil
    }

    private func random(in range: ClosedRange<Double>) -> Double {
        Double.random(in: range)
    }
}
