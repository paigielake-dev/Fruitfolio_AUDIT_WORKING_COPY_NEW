import SwiftUI

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
    private let libraryStore: Prompt10SavedLibraryStore

    @StateObject private var store: Prompt28FruitBasketStore
    @StateObject private var viewModel: Prompt28FruitBasketViewModel

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @ObservedObject private var usernameStore: FruitfolioUsernameStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var questionOperationTask: Task<Void, Never>?
    @State private var showingSaveDestination = false
    @State private var showTour = false
    @State private var showStormNote = false
    @State private var lastStormNoteKey: String?
    @State private var tourStep = 0
    @State private var leaderboardValidationMessage: String?
    @State private var leaderboardUsernameDraft = ""
    @State private var usernameNonIdentifying = false
    @State private var selectedLeaderboardCategory: Prompt28LeaderboardCategory = .fruit

    init(
        onBack: @escaping () -> Void,
        researchProvider: (any Prompt28ResearchProviding)? = nil,
        defaults: UserDefaults = .standard,
        usernameStore: FruitfolioUsernameStore? = nil,
        libraryStore: Prompt10SavedLibraryStore? = nil
    ) {
        self.onBack = onBack
        self.libraryStore = libraryStore ?? .shared
        _usernameStore = ObservedObject(wrappedValue: usernameStore ?? .shared)
        let store = Prompt28FruitBasketStore(defaults: defaults)
        _store = StateObject(wrappedValue: store)
        _viewModel = StateObject(
            wrappedValue: Prompt28FruitBasketViewModel(
                store: store,
                researchProvider: researchProvider ?? Prompt28BundledResearchProvider.shared
            )
        )
    }

    #if DEBUG
    /// The regression route uses the actual controller and isolated stores.
    init(onBack: @escaping () -> Void, regressionModel: Prompt28FruitBasketViewModel,
         usernameStore: FruitfolioUsernameStore, libraryStore: Prompt10SavedLibraryStore) {
        self.onBack = onBack
        self.libraryStore = libraryStore
        _store = StateObject(wrappedValue: regressionModel.store)
        _viewModel = StateObject(wrappedValue: regressionModel)
        _usernameStore = ObservedObject(wrappedValue: usernameStore)
    }
    #endif

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
            .fruitfolioModalBlur(active: showTour || showStormNote, reduceMotion: motionPreferences.reduceMotionActive)

            if showTour {
                tourOverlay
                    .zIndex(100)
            }
            if showStormNote {
                stormNote.zIndex(110)
            }
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Prompt28AssetUsageRegistrar.markProductionRoutes()
            Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_background)
            audioManager.fadeIn(.fruitBasketMusicbox, duration: 0.35)
            if !store.isReadOnly && !store.tourState.hasCompletedTour {
                showTour = true
                tourStep = 0
            }
        }
        .onDisappear {
            questionOperationTask?.cancel()
            viewModel.leaveScreen()
            audioManager.fadeOut(category: .music, duration: 0.25)
            audioManager.fadeOut(category: .rainAmbience, duration: 0.20)
        }
        .onChange(of: store.isReadOnly) { _, blocked in
            if blocked {
                questionOperationTask?.cancel()
                viewModel.leaveScreen()
                showStormNote = false
                showTour = false
            }
        }
        .onChange(of: viewModel.screen) { _, screen in
            guard screen == .catchActive, viewModel.weather == .softRain,
                  let session = viewModel.session else { return }
            let key = session.id.uuidString + ":" + String(session.currentRound)
            guard key != lastStormNoteKey else { return }
            lastStormNoteKey = key
            showStormNote = true
            viewModel.pause()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.sceneBecameInactive()
            }
        }
        .sheet(isPresented: $showingSaveDestination) {
            if let pending = viewModel.savePendingContent() {
                Prompt10AskSaveDestination(
                    store: libraryStore,
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
                    reduceMotion: motionPreferences.reduceMotionActive || viewModel.isPaused,
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
                        if viewModel.activeObstacles.contains(.wind) {
                            Prompt28WindGust(reduceMotion: motionPreferences.reduceMotionActive || viewModel.isPaused,
                                direction: viewModel.windDirection)
                        }
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
                    if viewModel.activeObstacles.contains(.wind) {
                        Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_wind)
                        audioManager.play(.fruitBasketWind)
                    }
                }
            }
        } else {
            Color.clear.allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isReadOnly {
            progressRecovery
        } else {
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

    private var progressRecovery: some View {
        ScrollView {
            VStack(spacing: 18) {
                topBar
                FruitfolioLargeCard {
                    Text("game progress is protected").prompt28Text(.sectionHeading)
                        .accessibilityAddTraits(.isHeader)
                    Text(store.persistenceMessage ?? "the original local game data is retained while progress changes are paused.")
                        .prompt28Text(.body)
                    FruitfolioControlPillButton(label: "reload local progress") {
                        store.reload()
                        if !store.isReadOnly {
                            viewModel.changeTopic()
                            viewModel.difficulty = store.preferredDifficulty
                            tourStep = 0
                            showTour = !store.tourState.hasCompletedTour
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .accessibilityIdentifier("fruitBasket.progressRecovery")
    }

    private var stormNote: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.opacity(0.72).ignoresSafeArea()
            FruitfolioLargeControlCardPopup {
                VStack(spacing: 10) {
                    HStack {
                        FruitfolioImage(id: .fruit_strawberry_silly).frame(width: 44, height: 44)
                            .accessibilityLabel("Strawberry")
                        Spacer()
                        CloseControl(action: dismissStormNote)
                    }
                    FruitfolioTranslatedText(source: "uh oh! a little storm is passing. o__o", protectedLiterals: ["o__o"],
                        font: Prompt28TextRole.sectionHeading.font)
                    FruitfolioTranslatedText(source: "puddles gently resist your basket while it moves through the water.",
                        font: Prompt28TextRole.secondary.font)
                    FruitfolioControlPillButton(label: "got it") { dismissStormNote() }
                }
            }
        }
        .accessibilityIdentifier("fruitBasket.stormNote")
        .accessibilityAction(.escape) { dismissStormNote() }
    }

    private func dismissStormNote() {
        showStormNote = false
        if viewModel.screen == .paused { viewModel.resume() }
    }

    private func performQuestionOperation(_ operation: @MainActor @escaping () async -> Void) {
        questionOperationTask?.cancel()
        questionOperationTask = Task { @MainActor in await operation() }
    }

    private func questionSources(_ question: Prompt28Question) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let records = question.sourceRecords, !records.isEmpty {
                FruitfolioSourceCitationList(sources: records)
            } else {
                ForEach(Array(question.sourceTitles.enumerated()), id: \.offset) { _, title in
                    Text(verbatim: title).textSelection(.enabled)
                }
            }
            if question.category == "source-excerpt practice" {
                Text("exact-excerpt practice; vocabulary difficulty is separate from catching level. source citations reflect the founder library attribution, not independent clinical review.")
                    .font(.footnote)
            }
        }
    }

    private var home: some View {
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
    }

    private var howItWorks: some View {
        ScrollView {
            VStack(spacing: 14) {
                topBar

                Text("how it works!")
                    .prompt28Text(.screenTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)

                VStack(spacing: 10) {
                    Prompt28CompactRuleCard(
                        title: "1. pick what you want to learn",
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
                        body: Prompt28RulesCopy.catches
                    )

                    Prompt28CompactRuleCard(
                        title: "4. fill your basket",
                        artID: .fruitbasket_strawberry,
                        body: Prompt28RulesCopy.protection
                    )
                }
                .frame(maxWidth: 330)

                Text(
                    "catching gets a little trickier as your game level grows, but you can start the game level over whenever you want. ☆"
                )
                .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
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
                        Text("what do you want to learn about? ♡")
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

                        Text("or pick something!")
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

                        HStack(spacing: 6) {
                            ForEach(
                                Prompt28EducationalDifficulty.allCases
                            ) { option in
                                Prompt28MiniControlPill(
                                    title: option.displayName,
                                    isSelected: viewModel.difficulty == option
                                ) {
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

                                FruitfolioSemanticText(markdown: message, baseFont: Prompt28TextRole.body.font)
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
                                    performQuestionOperation {
                                        await viewModel.continueReturningTopic(
                                            resetLevel: false
                                        )
                                    }
                                }

                                Prompt28WatercolorButton(
                                    title: "start catching easy again",
                                    accent: .mint
                                ) {
                                    performQuestionOperation {
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
                                performQuestionOperation {
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

                        Text(verbatim: question.questionText)
                            .prompt28Text(question.category == "source-excerpt practice" ? .body : .screenTitle)
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
                                if !question.usesSeriousFeedback {
                                FruitfolioImage(
                                    id: .fruit_peach_soft
                                )
                                .frame(
                                    width: 64,
                                    height: 64
                                )
                                .accessibilityLabel("Peach")
                                }

                                VStack(
                                    alignment: .leading,
                                    spacing: 5
                                ) {
                                    Text(
                                        Prompt28FeedbackCopy.incorrect(serious: question.usesSeriousFeedback)
                                    )
                                    .prompt28Text(.body)

                                    FruitfolioTranslatedText(source: question.explanation, protectedLiterals: question.sourceIDs, font: Prompt28TextRole.body.font, serious: true, sourceRecords: question.sourceRecords ?? [])
                                        .prompt28Text(.body)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                                    questionSources(question)
                                    .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                                }
                            }

                            Prompt28WatercolorButton(
                                title: question.usesSeriousFeedback ? "review question" : "got it ♡",
                                accent: .mint
                            ) {
                                viewModel.selectedAnswerID = nil
                                viewModel.screen = .question
                            }

                        } else if viewModel.screen == .correctFeedback {
                            HStack(spacing: 10) {
                                if !question.usesSeriousFeedback {
                                FruitfolioImage(
                                    id: .fruit_strawberry_silly
                                )
                                .frame(
                                    width: 62,
                                    height: 62
                                )
                                .accessibilityLabel("Strawberry")
                                }

                                Text(Prompt28FeedbackCopy.correct(serious: question.usesSeriousFeedback))
                                    .prompt28Text(.body)
                            }

                            Prompt28WatercolorButton(
                                title: "catch",
                                accent: .paleYellow
                            ) {
                                if !question.usesSeriousFeedback { audioManager.play(.starChime) }
                                viewModel.screen = .catchIntro
                            }

                        } else if viewModel.screen == .catchIntro {
                            Text(question.catchRule)
                                .prompt28Text(.body)

                            Text(
                                "starred = catch it · no star = let it pass"
                            )
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            Prompt28WatercolorButton(
                                title: question.usesSeriousFeedback ? "ready" : "ready ♡",
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
            let fieldHeight = max(0, proxy.size.height - proxy.safeAreaInsets.bottom)

            ZStack(alignment: .topLeading) {
                gameplayDecor(
                    width: width,
                    height: fieldHeight,
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

                    Text("\(viewModel.basketCount) / 10 · star passes: \(viewModel.session?.availableStarPasses ?? 0)")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 16
                            )
                        )
                        .fontWeight(.bold)
                }
                .frame(width: width)
                .offset(
                    x: xOffset,
                    y: 8
                )
                .zIndex(20)

                if viewModel.screen == .paused {
                    pausePanel
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
                        height: fieldHeight,
                        xOffset: xOffset
                    )

                } else {
                    catchGameplay(
                        width: width,
                        height: fieldHeight,
                        xOffset: xOffset
                    )
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: viewModel.basketCount) { oldValue, newValue in
            if newValue > oldValue { audioManager.play(.fruitCatch) }
        }
        .onChange(of: viewModel.vineContactSequence) { oldValue, newValue in
            if newValue > oldValue { audioManager.play(.vineRustle) }
        }
        .onChange(of: viewModel.session?.availableStarPasses ?? 0) { oldValue, newValue in
            if newValue > oldValue { audioManager.play(.starChime) }
        }
    }

    @ViewBuilder
    private func gameplayDecor(width: CGFloat, height: CGFloat, xOffset: CGFloat) -> some View {
        if let library = Prompt28ObstacleMaskLibrary.bundled {
            let geometry = Prompt28ObstacleGeometry(playfield: CGSize(width: width, height: height), level: viewModel.gameLevel, library: library)
            if viewModel.activeObstacles.contains(.vines), let frame = geometry.frame("vines") {
                FruitfolioImage(id: .fruitbasket_vines)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: xOffset + frame.midX, y: frame.midY)
                    .opacity(viewModel.gameLevel == 2 ? 0.46 : 0.66)
                    .zIndex(12).accessibilityHidden(true).allowsHitTesting(false)
                    .onAppear { Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_vines) }
            }
            if viewModel.activeObstacles.contains(.branch), let frame = geometry.frame("branch") {
                FruitfolioImage(id: .fruitbasket_branch)
                    .frame(width: frame.width, height: frame.height)
                    .scaleEffect(x: -1, y: 1)
                    .position(x: xOffset + frame.midX, y: frame.midY)
                    .opacity(0.78)
                    .zIndex(12).accessibilityHidden(true).allowsHitTesting(false)
                    .onAppear { Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_branch) }
            }
            if viewModel.activeObstacles.contains(.puddle), let frame = geometry.frame("puddle") {
                Prompt28PuddleArtwork(active: !viewModel.isPaused, reduceMotion: motionPreferences.reduceMotionActive)
                    .frame(width: frame.width, height: frame.height)
                    .position(x: xOffset + frame.midX, y: frame.midY)
                    .opacity(0.62).zIndex(2).accessibilityHidden(true).allowsHitTesting(false)
                    .onAppear { Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_puddle) }
            }
        }
    }

    private func catchGameplay(
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat
    ) -> some View {
        let geometry = Prompt28CatchGeometry(playfield: CGSize(width: width, height: height))
        return ZStack(alignment: .topLeading) {
            ForEach(
                viewModel.activeFruit
            ) { fruit in
                Prompt28MovingFruit(
                    fruit: fruit,
                    reduceMotion:
                        motionPreferences.reduceMotionActive
                )
                .frame(width: geometry.fruitSize, height: geometry.fruitSize)
                .position(
                    x: xOffset + width * fruit.x,
                    y: height * fruit.y
                )
                .zIndex(10)
                .accessibilityIdentifier("fruitBasket.classification.item")
                .onAppear {
                    Prompt28AssetUsageRegistrar.markRendered(
                        fruit.fruitID.assetID
                    )
                }
            }

            ForEach(viewModel.activeStars) { star in
                FruitfolioImage(id: .fruitbasket_star)
                    .frame(width: geometry.starSize, height: geometry.starSize)
                    .scaleEffect(x: star.isInVines && !motionPreferences.reduceMotionActive ? 0.94 : 1,
                                 y: star.isInVines && !motionPreferences.reduceMotionActive ? 1.04 : 1)
                    .rotationEffect(.degrees(motionPreferences.reduceMotionActive ? 0 : star.rotationDegrees + (star.isInVines ? sin(star.vineContactTime * 13) * 4 : 0)))
                    .position(x: xOffset + width * star.x, y: height * star.y)
                    .zIndex(11)
                    .accessibilityLabel("star pass")
            }

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                fruitIDs: viewModel.collectedFruit,
                transits: viewModel.catchTransits,
                playfield: geometry.playfield,
                basketX: viewModel.basketX
            )
            .frame(width: geometry.basketWidth, height: 132)
            .position(
                x: xOffset + width * viewModel.basketX,
                y: geometry.basketCenterY
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
            )
            .zIndex(30)
            .accessibilityIdentifier("fruitBasket.round.basket")
            .accessibilityLabel("Basket, \(viewModel.basketCount) of \(viewModel.engine.rules.goodFruitTarget)")
            .accessibilityValue(viewModel.basketIsInPuddle ? "in a puddle; movement meets gentle resistance" : "on dry ground")
        }
        .onAppear { viewModel.updatePlayfield(size: geometry.playfield) }
        .onChange(of: geometry.playfield) { _, size in viewModel.updatePlayfield(size: size) }
        .coordinateSpace(name: "prompt28Playfield")
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func classificationGameplay(
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat
    ) -> some View {
        ScrollView {
        VStack(spacing: 14) {
            Spacer()
                .frame(height: 92)
            Text("basket \(viewModel.basketCount) of \(viewModel.engine.rules.goodFruitTarget); star passes \(viewModel.session?.availableStarPasses ?? 0)")
                .prompt28Text(.secondary)
                .accessibilityIdentifier("fruitBasket.classification.progress")

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
                    "\(fruit.fruitID.displayName). \(fruit.classification == .good ? "attached star marker" : "no attached star marker"). Does this belong in the basket?"
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
            } else if viewModel.classificationStarAvailable {
                FruitfolioImage(id: .fruitbasket_star).frame(width: 52, height: 52)
                    .accessibilityHidden(true)
                Text("a standalone star — catch it to bank one star pass. it does not fill the fruit basket.")
                    .prompt28Text(.body).multilineTextAlignment(.center)
                Prompt28WatercolorButton(title: "catch star", accent: .paleYellow) {
                    viewModel.classificationStarDecision(accept: true)
                }
                .accessibilityIdentifier("fruitBasket.classification.catchStar")
                Prompt28WatercolorButton(title: "let star pass", accent: .mint) {
                    viewModel.classificationStarDecision(accept: false)
                }
            } else if !viewModel.catchTransits.isEmpty {
                Text("settling in the basket…").prompt28Text(.body)
            }

            Spacer()

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                fruitIDs: viewModel.collectedFruit,
                transits: viewModel.catchTransits
            )
            .frame(
                width: 150,
                height: 132
            )

            Spacer()
                .frame(height: 20)
        }
        .frame(width: width)
        .frame(minHeight: height)
        }
        .frame(width: width, height: height)
        .offset(x: xOffset)
        .accessibilityIdentifier("fruitBasket.classification.scroll")
    }

    private var classificationYesButton: some View {
        Prompt28WatercolorButton(
            title: "yes ♡",
            accent: .mint
        ) {
            viewModel.classificationDecision(accept: true)
        }
        .accessibilityIdentifier("fruitBasket.classification.catchFruit")
    }

    private var classificationNoButton: some View {
        Prompt28WatercolorButton(
            title: "nope!",
            accent: .peach
        ) {
            viewModel.classificationDecision(accept: false)
        }
        .accessibilityIdentifier("fruitBasket.classification.passFruit")
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
        ScrollView {
        VStack(spacing: 14) {
            topBar

            if let result = viewModel.roundResult { roundStatistics(result).padding(.horizontal, 20) }

            Spacer()

            Prompt28PaperPanel {
                VStack(spacing: 12) {
                    if viewModel.currentQuestion?.usesSeriousFeedback != true {
                    FruitfolioImage(
                        id: .fruit_peach_soft
                    )
                    .frame(
                        width: 88,
                        height: 88
                    )
                    .accessibilityLabel("Peach")

                    }
                    Text(
                        Prompt28FeedbackCopy.unsuccessful(serious: viewModel.currentQuestion?.usesSeriousFeedback == true)
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
                        viewModel.currentQuestion?.usesSeriousFeedback == true ? "no points were deducted." : "your score didn’t lose any points ♡"
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
                        performQuestionOperation {
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
    }

    private func roundStatistics(_ result: Prompt28RoundResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(result.succeeded ? "completed catch round" : "catch attempt ended")
                .prompt28Text(.sectionHeading).accessibilityAddTraits(.isHeader)
            LabeledContent("fruit caught", value: "\(result.caughtFruit.count) / \(result.targetFruit)")
                .accessibilityIdentifier("fruitBasket.result.fruitCount")
            LabeledContent("passes carried in", value: String(result.starPassesAtStart))
            LabeledContent("stars caught this round", value: String(result.starsCollected))
            LabeledContent("star passes used", value: String(result.starPassesSpent))
            LabeledContent("star passes available", value: String(result.starPassesRemaining))
            LabeledContent("round points", value: (result.scoreChange >= 0 ? "+" : "") + String(result.scoreChange))
            LabeledContent("session score", value: String(result.cumulativeScore))
            if result.goodFruitPassed > 0 {
                Text("\(result.goodFruitPassed) good fruit passed; missed good fruit has no penalty.")
            }
            if result.starPassesSpent > 0 {
                Text("each protected bad-fruit catch used exactly one star pass, so play continued.")
            }
            if let fruit = result.endingBadFruit {
                Text("\(fruit.displayName) was caught with no star passes available; that catch attempt ended.")
            }
            if result.nextGameLevel > result.gameLevelPlayed {
                Text("next catching level: \(result.nextGameLevel)")
            }
        }
        .prompt28Text(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fruitBasket.roundStatistics")
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
                        count: viewModel.roundResult?.caughtFruit.count ?? 0,
                        fruitIDs: viewModel.roundResult?.caughtFruit ?? []
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
                    viewModel.roundResult.map { "Basket. \($0.caughtFruit.count) of \($0.targetFruit). Round complete." + (viewModel.didSetPersonalBestThisRound ? " Personal best." : "") }
                        ?? "Round result unavailable."
                )

                Prompt28PaperPanel {
                    VStack(
                        alignment: .leading,
                        spacing: 11
                    ) {
                        Text(viewModel.currentQuestion?.usesSeriousFeedback == true ? "round complete" : "your basket reveal! ♡")
                        .prompt28Text(.screenTitle)

                        if let result = viewModel.roundResult { roundStatistics(result) }

                        if let question =
                            viewModel.currentQuestion {

                            Text(
                                "library explanation"
                            )
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            FruitfolioTranslatedText(source: question.explanation, protectedLiterals: question.sourceIDs, font: Prompt28TextRole.body.font, serious: true, sourceRecords: question.sourceRecords ?? [])
                                .prompt28Text(.body)

                            questionSources(question)
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
                            performQuestionOperation {
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
                if store.hasLegacyCaptureTotals {
                    Text("totals saved before this update may omit fruit from failed or unfinished attempts. existing totals are retained; new captures are counted as they happen.")
                        .font(.footnote).fixedSize(horizontal: false, vertical: true)
                }


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
                                .buttonStyle(.plain)
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
                    VStack(alignment: .leading, spacing: 10) {
                        Text("what counts")
                            .prompt28Text(.sectionHeading)
                            .accessibilityAddTraits(.isHeader)
                        Text(Prompt28RulesCopy.totals)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(Prompt28RulesCopy.results)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .prompt28Text(.secondary)
                }
                .accessibilityIdentifier("fruitBasket.leaderboard.rules")

                Prompt28PaperPanel {
                    VStack(spacing: 10) {
                        Text("fruit basket leaderboard")
                            .prompt28Text(.sectionHeading)
                            .multilineTextAlignment(.center)

                        TextField(
                            "public username",
                            text: $leaderboardUsernameDraft
                        )
                        .accessibilityIdentifier("fruitBasket.publicUsername")
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
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

                        Toggle("this is not my real or legal name and contains no identifying details", isOn: $usernameNonIdentifying)
                            .prompt28Text(.metadata)
                        Button("save username") {
                            leaderboardValidationMessage = usernameStore.setUsername(leaderboardUsernameDraft,
                                confirmedNonIdentifying: usernameNonIdentifying)
                            if leaderboardValidationMessage == nil { leaderboardValidationMessage = "saved on this device only." }
                        }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)

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
        .onChange(of: leaderboardUsernameDraft) { _, newValue in
            usernameNonIdentifying = newValue == usernameStore.username && usernameStore.confirmedNonIdentifying
        }
        .onChange(of: usernameStore.username) { oldValue, newValue in
            if leaderboardUsernameDraft == oldValue || leaderboardUsernameDraft == newValue {
                leaderboardUsernameDraft = newValue
                usernameNonIdentifying = usernameStore.confirmedNonIdentifying
            } else {
                usernameNonIdentifying = false
                leaderboardValidationMessage = "the saved username changed in Account. your unsaved draft is still here; confirm it again before saving."
            }
        }
        .onAppear {
            leaderboardUsernameDraft = usernameStore.username
            usernameNonIdentifying = usernameStore.confirmedNonIdentifying
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

                if let message = FruitfolioPseudonymPolicy.validationMessage(for: usernameStore.username,
                    confirmedNonIdentifying: usernameStore.confirmedNonIdentifying) {
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
        ZStack {
            DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.72)
                .ignoresSafeArea()

            FruitfolioTapedWhitePopup {
                VStack(spacing: 8) {
                    FruitfolioImage(
                        id: .fruit_strawberry_silly
                    )
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .accessibilityLabel("Strawberry")

                    Text("\(tourStep + 1) of 10")
                        .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                    Text(tourTitle)
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

                    Text(tourBody)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13,
                                relativeTo: .body
                            )
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                                .opacity(0.84)
                        )
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

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
                        Button("skip tour") {
                            viewModel.screen = .howItWorks
                            store.skipTourAfterRules()
                            showTour = false
                        }
                        .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        .frame(minHeight: 44)
                    }
                }
            }
        }
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
            "the tenth good fruit lands first, the basket reaches 10 / 10, then the result shows what you actually caught. the sourced library explanation stays separate from the catch rule.",
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
                        .degrees(reduceMotion ? 0 : fruit.rotationDegrees + (fruit.isInVines ? sin(fruit.vineContactTime * 13) * 4 : 0))
                    )
                    .scaleEffect(x: fruit.isInVines && !reduceMotion ? 0.94 : 1, y: fruit.isInVines && !reduceMotion ? 1.04 : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                if fruit.classification == .good {
                    FruitfolioImage(id: .fruitbasket_star)
                        .frame(width: starSize, height: starSize)
                        .accessibilityHidden(true)
                        .accessibilityIdentifier("fruitBasket.goodFruitMarker")
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

private struct Prompt28BasketProgressView: View {
    let count: Int
    let fruitIDs: [Prompt28FruitID]
    var transits: [Prompt28CatchTransit] = []
    var playfield: CGSize = .zero
    var basketX: Double = 0.5
    @EnvironmentObject private var motionPreferences: MotionPreferences

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 1)
            let height = max(proxy.size.height, 1)
            let artWidth = width * 0.90
            let artHeight = artWidth * 380 / 398
            let artLeft = (width - artWidth) / 2
            let artTop = height - artHeight
            let fruitSize = min(max(width * 0.16, 18), 28)
            let geometry = Prompt28CatchGeometry(playfield: playfield)
            ZStack(alignment: .bottom) {
                // Original source canvas behind the actual collected objects.
                FruitfolioImage(id: .fruitbasket_basket)
                    .frame(width: artWidth, height: artHeight)

                ZStack {
                    ForEach(0..<min(max(count, 0), fruitIDs.count), id: \.self) { index in
                        let row = index / 5
                        let column = index % 5
                        FruitfolioImage(id: fruitIDs[index].assetID)
                            .frame(width: fruitSize, height: fruitSize)
                            .scaleEffect(x: 1, y: 0.62)
                            .position(x: artLeft + artWidth * (0.27 + CGFloat(column) * 0.105),
                                      y: artTop + artHeight * (row == 0 ? 0.57 : 0.51))
                            .accessibilityHidden(true)
                    }
                    ForEach(transits) { transit in
                        let pose = geometry.isValid
                            ? geometry.pose(for: transit, basketX: basketX, reducedMotion: motionPreferences.reduceMotionActive)
                            : Prompt28CatchGeometry.localPose(for: transit, basketSize: CGSize(width: width, height: height), reducedMotion: motionPreferences.reduceMotionActive)
                        let center = geometry.isValid
                            ? CGPoint(x: pose.center.x - playfield.width * basketX + width / 2, y: pose.center.y - geometry.basketCenterY + height / 2)
                            : pose.center
                        let asset: FruitfolioAssetID = {
                            switch transit.kind {
                            case .star: return .fruitbasket_star
                            case .fruit(let fruit, _): return fruit.assetID
                            }
                        }()
                        FruitfolioImage(id: asset).frame(width: pose.size.width, height: pose.size.height)
                            .position(center).accessibilityHidden(true)
                    }
                }
                .frame(width: width, height: height)
                .allowsHitTesting(false)

                // Reuse the untouched lower front rim/body to occlude the settled
                // objects. The full original source remains visible behind them.
                FruitfolioImage(id: .fruitbasket_basket)
                    .frame(width: artWidth, height: artHeight)
                    .mask {
                        GeometryReader { image in
                            Rectangle().frame(width: image.size.width, height: image.size.height * 0.38)
                                .position(x: image.size.width / 2, y: image.size.height * 0.81)
                        }
                    }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                Text("\(count) / 10")
                    .font(.custom("Chalkboard SE", size: 13, relativeTo: .caption).bold())
                    .monospacedDigit()
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(DesignTokens.ColorToken.backgroundCream.opacity(0.90), in: Capsule())
                    .offset(y: -2)
            }
            .frame(width: width, height: height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Basket \(count) of 10")
    }
}

private enum Prompt28LeaderboardCategory: String, CaseIterable {
    case fruit = "🍓 fruit collected"
    case stars = "⭐ stars earned"
    case baskets = "🧺 basket reveals"
    case level = "🎮 highest level"

    var localTotal: (Prompt28LeaderboardTotals) -> Int {
        switch self {
        case .fruit: return { $0.fruitCollected }
        case .stars: return { $0.starsEarned }
        case .baskets: return { $0.basketReveals }
        case .level: return { $0.highestLevel }
        }
    }

    var accessibilityUnit: String {
        switch self {
        case .fruit: return "fruit collected"
        case .stars: return "stars earned"
        case .baskets: return "basket reveals"
        case .level: return "highest level"
        }
    }
}

private struct Prompt28LeaderboardRow: View {
    let rank: Int
    let username: String
    let scoreText: String
    let unit: String

    var body: some View {
        HStack(spacing: 8) {
            Text("\(rank).")
                .frame(width: 24, alignment: .trailing)

            Text(username)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(scoreText)
                .monospacedDigit()
                .lineLimit(1)
                .frame(minWidth: 44, alignment: .trailing)
        }
        .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            scoreText == "—"
            ? "\(rank) place, awaiting player"
            : "\(rank) place. \(username). \(scoreText) \(unit)."
        )
    }
}

private struct Prompt28TourFruit: View {
    let fruit: Prompt28FruitID
    let classification: Prompt28FruitClassification

    var body: some View {
        Prompt28MovingFruit(
            fruit: Prompt28FallingFruit(
                fruitID: fruit,
                classification: classification,
                x: 0.5,
                y: 0.5,
                fallSpeed: 0,
                horizontalDrift: 0,
                rotationDegrees: 0
            ),
            reduceMotion: true
        )
        .frame(
            width: 80,
            height: 80
        )
    }
}

private struct Prompt28PaperPanel<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .frame(maxWidth: 330)
            .background {
                Prompt28CodedLargeCardBackground(cornerRadius: 30)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(
                children: .contain
            )
    }
}

private struct Prompt28CompactPopupCard<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 22)
            .padding(.vertical, 20)
            .frame(maxWidth: 292)
            .background {
                Prompt28CodedLargeCardBackground(cornerRadius: 28)
            }
            .accessibilityElement(
                children: .contain
            )
    }
}

private struct Prompt28CodedLargeCardBackground: View {
    let cornerRadius: CGFloat

    private let paperCream = Color(
        red: 0.992,
        green: 0.968,
        blue: 0.918
    )

    private let borderBurgundy = Color(
        red: 0.48,
        green: 0.035,
        blue: 0.045
    )

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(paperCream)

            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.28),
                        Color.clear,
                        Color(
                            red: 0.90,
                            green: 0.79,
                            blue: 0.63
                        )
                        .opacity(0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.softLight)

            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .stroke(
                borderBurgundy.opacity(0.88),
                lineWidth: 2.7
            )

            RoundedRectangle(
                cornerRadius: max(cornerRadius - 0.8, 0),
                style: .continuous
            )
            .stroke(
                borderBurgundy.opacity(0.34),
                lineWidth: 1.15
            )
            .offset(x: 0.75, y: 0.35)

            RoundedRectangle(
                cornerRadius: cornerRadius + 0.8,
                style: .continuous
            )
            .stroke(
                borderBurgundy.opacity(0.22),
                lineWidth: 0.9
            )
            .offset(x: -0.65, y: -0.45)
        }
        .shadow(
            color: borderBurgundy.opacity(0.05),
            radius: 1.5,
            x: 0,
            y: 1
        )
        .accessibilityHidden(true)
    }
}

private struct Prompt28CompactRuleCard: View {
    let title: String
    let artID: FruitfolioAssetID?
    let ruleBody: String

    init(
        title: String,
        artID: FruitfolioAssetID? = nil,
        body: String
    ) {
        self.title = title
        self.artID = artID
        self.ruleBody = body
    }

    var body: some View {
        Prompt28CompactPopupCard {
            VStack(spacing: 5) {
                HStack(spacing: 5) {
                    Text(title)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 15,
                                relativeTo: .headline
                            )
                        )
                        .fontWeight(.semibold)

                    if let artID {
                        Prompt28InlineArtGlyph(assetID: artID)
                            .frame(minWidth: 18, minHeight: 18)
                    }
                }
                .multilineTextAlignment(.center)

                Text(ruleBody)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 13,
                            relativeTo: .body
                        )
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                            .opacity(0.78)
                    )
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .frame(maxWidth: 292)
    }
}

private enum Prompt28Accent {
    case paleYellow
    case mint
    case lavender
    case sage
    case peach
}

private struct Prompt28WatercolorButton: View {
    let title: String
    let accent: Prompt28Accent
    let action: () -> Void

    var body: some View {
        FruitfolioControlPillButton(
            label: title,
            action: action
        )
        .frame(maxWidth: 292)
    }
}

private struct Prompt28MiniControlPill: View {
    let title: String
    let isSelected: Bool
    var width: CGFloat = 88
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @EnvironmentObject
    private var audioManager: AudioManager

    var body: some View {
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            ZStack {
                Image("control_pill_outline")
                    .resizable()
                    .scaledToFit()
                    .opacity(
                        isSelected
                        ? 1
                        : 0.56
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 12,
                            relativeTo: .subheadline
                        )
                    )
                    .fontWeight(
                        isSelected
                        ? .bold
                        : .semibold
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
                    .padding(.horizontal, 8)
            }
            .frame(
                width: width,
                height: 52
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
        .accessibilityAddTraits(
            isSelected
            ? .isSelected
            : []
        )
    }
}

private struct Prompt28ChipWrap: View {
    let titles: [String]
    let onSelect: (String) -> Void

    @EnvironmentObject
    private var motionPreferences: MotionPreferences

    @EnvironmentObject
    private var audioManager: AudioManager

    var body: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(),
                    spacing: 6
                ),
                GridItem(
                    .flexible(),
                    spacing: 6
                )
            ],
            spacing: 6
        ) {
            ForEach(
                titles,
                id: \.self
            ) { title in
                Button {
                    audioManager.play(.buttonSoftPop)
                    onSelect(title)
                } label: {
                    ZStack {
                        Image("control_pill_outline")
                            .resizable()
                            .scaledToFit()
                            .opacity(0.72)
                            .accessibilityHidden(true)

                        Text(title)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 11,
                                    relativeTo: .caption
                                )
                            )
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                            .padding(.horizontal, 10)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 48
                    )
                }
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion:
                            motionPreferences.reduceMotionActive
                    )
                )
            }
        }
    }
}








private struct Prompt28WindGust: View {
    let reduceMotion: Bool
    let direction: Double
    @State private var drift = false

    var body: some View {
        GeometryReader { proxy in
            FruitfolioImage(id: .fruitbasket_wind)
                .frame(width: min(proxy.size.width * 0.48, 178))
                .scaleEffect(x: direction < 0 ? -1 : 1, y: 1)
                .position(
                    x: proxy.size.width * (direction < 0 ? 0.72 : 0.28),
                    y: max(118, proxy.size.height * 0.18)
                )
                .offset(x: reduceMotion ? 0 : (drift ? CGFloat(direction * 10) : CGFloat(direction * -8)))
                .opacity(reduceMotion ? 0.56 : (drift ? 0.66 : 0.48))
                .animation(
                    reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                    value: drift
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { drift = !reduceMotion }
        .onChange(of: reduceMotion) { _, reduced in
            if reduced {
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) { drift = false }
            } else { drift = true }
        }
        .onDisappear {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { drift = false }
        }
        .accessibilityHidden(true)
    }
}

private struct Prompt28WatercolorConfettiBurst: View {
    let reduceMotion: Bool
    @State private var burst = false

    private let pieces: [(Double, Double, Double, Double)] = [
        (-88,-58,-18,0.0), (-62,-82,24,0.03), (-35,-66,-32,0.06),
        (-12,-92,18,0.09), (18,-78,-22,0.12), (44,-90,30,0.15),
        (70,-62,-16,0.18), (92,-42,26,0.21), (-76,-26,34,0.24),
        (-46,-40,-26,0.27), (42,-36,20,0.30), (78,-18,-30,0.33)
    ]

    var body: some View {
        ZStack {
            ForEach(Array(pieces.enumerated()), id: \.offset) { index, piece in
                RoundedRectangle(cornerRadius: index.isMultiple(of: 2) ? 3 : 5)
                    .fill(confettiColor(index).opacity(0.72))
                    .frame(width: index.isMultiple(of: 3) ? 7 : 5, height: index.isMultiple(of: 2) ? 11 : 7)
                    .rotationEffect(.degrees(burst && !reduceMotion ? piece.2 : 0))
                    .offset(
                        x: burst && !reduceMotion ? piece.0 : 0,
                        y: burst && !reduceMotion ? piece.1 : 0
                    )
                    .opacity(burst ? (reduceMotion ? 0.48 : 0.0) : 0.72)
                    .animation(
                        .easeOut(duration: reduceMotion ? 0.35 : 0.9).delay(piece.3),
                        value: burst
                    )
            }
        }
        .onAppear { burst = true }
        .allowsHitTesting(false)
    }

    private func confettiColor(_ index: Int) -> Color {
        switch index % 5 {
        case 0: return DesignTokens.ColorToken.coral
        case 1: return DesignTokens.ColorToken.sage
        case 2: return DesignTokens.ColorToken.paleYellow
        case 3: return DesignTokens.ColorToken.lavender
        default: return DesignTokens.ColorToken.mint
        }
    }
}

private struct Prompt28PuddleArtwork: View {
    let active: Bool
    let reduceMotion: Bool
    @State private var ripple = false
    var body: some View {
        FruitfolioImage(id: .fruitbasket_puddle)
            .scaleEffect(x: active && !reduceMotion && ripple ? 1.012 : 1,
                         y: active && !reduceMotion && ripple ? 0.993 : 1)
            .offset(x: active && !reduceMotion && ripple ? 1.2 : 0)
            .animation(active && !reduceMotion ? .easeInOut(duration: 2.8).repeatForever(autoreverses: true) : nil, value: ripple)
            .onAppear { synchronize() }
            .onChange(of: active) { _, _ in synchronize() }
            .onChange(of: reduceMotion) { _, _ in synchronize() }
            .onDisappear {
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) { ripple = false }
            }
    }
    private func synchronize() {
        if active && !reduceMotion { ripple = true }
        else {
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) { ripple = false }
        }
    }
}
