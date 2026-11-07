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


@MainActor
struct Prompt28FruitBasketView: View {
    let onBack: () -> Void
    private let libraryStore: Prompt10SavedLibraryStore

    @StateObject private var store: Prompt28FruitBasketStore
    @StateObject private var viewModel: Prompt28FruitBasketViewModel

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var usernameLabel = FruitfolioControlTranslationState()
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var usernameExitSession: FruitfolioUsernameExitSession?
    @State private var rootIsVisible = false
    @State private var returnExitFocus = false
    private enum UsernameFocus: Hashable { case back, input, error }
    @AccessibilityFocusState private var usernameFocus: UsernameFocus?
    @AccessibilityFocusState private var tourHeadingFocused: Bool
    @AccessibilityFocusState private var stormHeadingFocused: Bool
    @AccessibilityFocusState private var pauseHeadingFocused: Bool
    @State private var gameplayHeaderContentHeight: CGFloat = 100
    @State private var pauseMenuVisible = false
    @State private var lastCheeredRoundID: UUID?
    @State private var levelResetSession: Prompt28LevelResetSession?
    @State private var returnLevelResetFocus = false
    @AccessibilityFocusState private var levelResetControlFocused: Bool
    @AccessibilityFocusState private var progressRecoveryHeadingFocused: Bool
    private enum GameplayFocus: Hashable { case pause, classificationProgress }
    @AccessibilityFocusState private var gameplayFocus: GameplayFocus?
    @FocusState private var usernameKeyboardFocused: Bool
    private var usernameLabelKey: FruitfolioControlTranslationState.Key {
        .init(source: "public username", language: settings.language)
    }
    @ObservedObject private var usernameStore: FruitfolioUsernameStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var questionOperationTask: Task<Void, Never>?
    @State private var showingSaveDestination = false
    @State private var pendingSaveContent: Prompt10PendingSavedContent?
    private struct QuestionSaveReturnContext {
        let questionID: String
        let roundID: UUID
    }
    @State private var questionSaveReturnContext: QuestionSaveReturnContext?
    @AccessibilityFocusState private var questionSaveFocused: Bool
    private var canInteractWithGame: Bool {
        rootIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active &&
            !store.isReadOnly && popupCoordinator.currentPopup == nil && !showTour && !showStormNote && !showingSaveDestination && pendingSaveContent == nil
    }
    @State private var showTour = false
    @State private var showStormNote = false
    @State private var lastStormNoteKey: String?
    @State private var tourStep = 0
    @State private var leaderboardValidationMessage: String?
    @State private var leaderboardUsernameDraft = ""
    @State private var usernameNonIdentifying = false
    @State private var usernameBaseline: FruitfolioUsernamePersistence.Snapshot?
    @State private var usernameEditorHasLoaded = false
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
        #if DEBUG
        .preference(key: Prompt28GameOverlayVisibilityKey.self, value: showTour || showStormNote || pauseMenuVisible)
        #endif
        .onAppear {
            rootIsVisible = true
            if usernameExitSession == nil { usernameExitSession = .init(coordinator: popupCoordinator) }
            if levelResetSession == nil { levelResetSession = .init(coordinator: popupCoordinator) }
            Prompt28AssetUsageRegistrar.markProductionRoutes()
            Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_background)
            audioManager.fadeIn(.fruitBasketMusicbox, duration: 0.35)
            if !store.isReadOnly && !store.tourState.hasCompletedTour && !showTour {
                showTour = true
                tourStep = 0
            }
        }
        .onDisappear {
            questionSaveFocused = false
            rootIsVisible = false
            setPauseMenuVisible(false)
            returnExitFocus = false
            usernameExitSession?.cancel()
            levelResetSession?.cancel()
            returnLevelResetFocus = false
            questionOperationTask?.cancel()
            viewModel.leaveScreen()
            audioManager.fadeOut(category: .music, duration: 0.25)
            audioManager.fadeOut(category: .rainAmbience, duration: 0.20)
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            guard rootIsVisible else { return }
            if let choice = levelResetSession?.takeCompletedChoice() {
                switch choice {
                case .reset(let expected):
                    returnLevelResetFocus = false
                    if !store.isReadOnly, expected.matches(currentLevelResetContext) { viewModel.resetGameLevel() }
                case .cancel: restoreLevelResetFocus()
                }
            } else if returnLevelResetFocus, levelResetSession?.requestID == nil,
                      popupCoordinator.currentPopup == nil {
                restoreLevelResetFocus()
            }
            guard let session = usernameExitSession else { return }
            if let choice = session.takeCompletedChoice() {
                returnExitFocus = false
                completeUsernameExit(choice)
            } else if returnExitFocus, session.requestID == nil, popupCoordinator.currentPopup == nil {
                returnExitFocus = false
                usernameFocus = .back
            }
        }
        .onChange(of: store.isReadOnly) { _, blocked in
            if blocked {
                levelResetSession?.cancel()
                returnLevelResetFocus = false
                levelResetControlFocused = false
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
        .onChange(of: showStormNote) { _, visible in
            audioManager.play(visible ? .popupOpen : .popupClose)
            if !visible { stormHeadingFocused = false }
        }
        .onChange(of: showTour) { _, visible in
            audioManager.play(visible ? .popupOpen : .popupClose)
            if !visible { tourHeadingFocused = false }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                questionSaveFocused = false
                tourHeadingFocused = false
                stormHeadingFocused = false
                pauseHeadingFocused = false
                progressRecoveryHeadingFocused = false
                viewModel.sceneBecameInactive()
            } else if store.isReadOnly { focusProgressRecoveryHeading() }
            else if showStormNote { stormHeadingFocused = true }
            else if showTour { tourHeadingFocused = true }
            else if pauseMenuVisible { pauseHeadingFocused = true }
        }
        .sheet(isPresented: $showingSaveDestination, onDismiss: questionSaveDidDismiss) {
            if let pending = pendingSaveContent {
                FruitfolioPresentedPopupHost {
                    Prompt10AskSaveDestination(
                        store: libraryStore,
                        pending: pending,
                        onSaved: { showingSaveDestination = false },
                        onCancel: { showingSaveDestination = false }
                    )
                }
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
                GeometryReader { viewport in
                    ScrollView {
                        home.frame(minHeight: viewport.size.height)
                    }
                    .accessibilityIdentifier("fruitBasket.home.scroll")
                }

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

            }
        }
    }

    private var topBar: some View {
        HStack {
            BackControl { requestLeavingGame() }
                .accessibilityFocused($usernameFocus, equals: .back)
                .accessibilityIdentifier("fruitBasket.back")

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
                .accessibilityIdentifier("fruitBasket.home")
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
                    FruitfolioTranslatedContent(source: "game progress is protected") { display, _ in
                        FruitfolioSemanticText(markdown: display, baseFont: Prompt28TextRole.sectionHeading.font, serious: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($progressRecoveryHeadingFocused)
                            .accessibilityIdentifier("fruitBasket.progressRecovery.heading")
                    }
                    FruitfolioTranslatedText(source: store.persistenceMessage ?? "the original local game data is retained while progress changes are paused.",
                        font: Prompt28TextRole.body.font, serious: true)
                        .accessibilityIdentifier("fruitBasket.progressRecovery.message")
                    FruitfolioControlPillButton(label: "reload local progress", action: reloadProtectedGameProgress)
                        .accessibilityIdentifier("fruitBasket.progressRecovery.reload")
                }
            }
            .padding(.horizontal, 20)
        }
        .task { focusProgressRecoveryHeading() }
        .accessibilityIdentifier("fruitBasket.progressRecovery")
    }

    private func focusProgressRecoveryHeading() {
        progressRecoveryHeadingFocused = false
        Task { @MainActor in
            await Task.yield()
            guard rootIsVisible, store.isReadOnly, scenePhase == .active,
                  popupCoordinator.currentPopup == nil else { return }
            progressRecoveryHeadingFocused = true
        }
    }

    private func reloadProtectedGameProgress() {
        guard rootIsVisible, store.isReadOnly else { return }
        store.reload()
        if !store.isReadOnly {
            progressRecoveryHeadingFocused = false
            viewModel.changeTopic()
            viewModel.difficulty = store.preferredDifficulty
            tourStep = 0
            showTour = !store.tourState.hasCompletedTour
        } else {
            focusProgressRecoveryHeading()
        }
    }

    private var stormNote: some View {
        let serious = viewModel.currentQuestion?.usesSeriousFeedback == true
        return ZStack {
            DesignTokens.ColorToken.backgroundCream.opacity(0.72).ignoresSafeArea()
            FruitfolioLargeControlCardPopup {
                VStack(spacing: 10) {
                    HStack {
                        if !serious {
                            FruitfolioImage(id: .fruit_strawberry_silly).frame(width: 44, height: 44)
                                .accessibilityLabel("Strawberry")
                        }
                        Spacer()
                        CloseControl(action: dismissStormNote)
                            .accessibilityIdentifier("fruitBasket.storm.close")
                    }
                    FruitfolioTranslatedContent(source: serious ? "a rain obstacle is active." : "uh oh! a little storm is passing. o__o", protectedLiterals: ["o__o"]) { display, _ in
                        FruitfolioSemanticText(markdown: display, baseFont: Prompt28TextRole.sectionHeading.font, serious: serious)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($stormHeadingFocused)
                            .accessibilityIdentifier("fruitBasket.storm.heading")
                    }
                    FruitfolioTranslatedText(source: "puddles gently resist your basket while it moves through the water.",
                        font: Prompt28TextRole.secondary.font, serious: serious)
                    FruitfolioControlPillButton(label: "got it") { dismissStormNote() }
                        .accessibilityIdentifier("fruitBasket.storm.acknowledge")
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQA") {
                        if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQAEscape") {
                            FruitfolioControlPillButton(label: "QA accessibility escape", action: dismissStormNote)
                                .controlSize(.small).accessibilityIdentifier("gameQA.stormEscape")
                        }
                        if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                            FruitfolioInteractionSoundDiagnostics()
                        }
                    }
                    #endif
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("fruitBasket.stormNote")
        .accessibilityAction(.escape) { dismissStormNote() }
        .task {
            await Task.yield()
            guard showStormNote, !Task.isCancelled else { return }
            stormHeadingFocused = true
        }
    }

    private func dismissStormNote() {
        guard showStormNote else { return }
        showStormNote = false
        stormHeadingFocused = false
        if viewModel.screen == .paused { viewModel.resume() }
        Task { @MainActor in
            await Task.yield()
            guard rootIsVisible, !showStormNote, scenePhase == .active,
                  viewModel.screen == .catchActive else { return }
            gameplayFocus = store.controlMode == .classification ? .classificationProgress : .pause
        }
    }

    private func requestQuestionSave(expectedQuestionID: String?, expectedInteractionID: UUID) {
        guard canInteractWithGame, expectedInteractionID == viewModel.questionInteractionID, let expectedQuestionID,
              viewModel.screen == .basketReveal, viewModel.currentQuestion?.id == expectedQuestionID,
              let result = viewModel.roundResult, result.succeeded,
              result.roundID == viewModel.roundLedger.roundID,
              let pending = viewModel.savePendingContent() else { return }
        questionSaveFocused = false
        questionSaveReturnContext = .init(questionID: expectedQuestionID, roundID: result.roundID)
        pendingSaveContent = pending
        showingSaveDestination = true
    }

    private func questionSaveDidDismiss() {
        let context = questionSaveReturnContext
        pendingSaveContent = nil
        questionSaveReturnContext = nil
        Task { @MainActor in
            await Task.yield()
            guard let context, canInteractWithGame, viewModel.screen == .basketReveal,
                  viewModel.currentQuestion?.id == context.questionID,
                  viewModel.roundResult?.roundID == context.roundID else { return }
            questionSaveFocused = true
        }
    }

    private func performQuestionOperation(_ operation: @MainActor @escaping () async -> Void) {
        guard canInteractWithGame else { return }
        let screen = viewModel.screen
        let topic = viewModel.rawTopic
        let difficulty = viewModel.difficulty
        let interactionID = viewModel.questionInteractionID
        questionOperationTask?.cancel()
        questionOperationTask = Task { @MainActor in
            guard !Task.isCancelled, canInteractWithGame, viewModel.screen == screen,
                  viewModel.rawTopic == topic, viewModel.difficulty == difficulty,
                  viewModel.questionInteractionID == interactionID else { return }
            await operation()
        }
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

            FruitfolioFixedText(source: "fruit basket", font: .custom("Chalkboard SE", size: 34, relativeTo: .largeTitle))
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
                .accessibilityIdentifier("fruitBasket.home.heading")

            FruitfolioImage(id: .fruit_strawberry_silly)
                .frame(width: 92, height: 92)
                .accessibilityLabel("Strawberry")

            FruitfolioFixedText(source: "ready to collect some fruit\nand learn a little? ♡", protectedLiterals: ["♡"], font: .custom("Chalkboard SE", size: 17, relativeTo: .headline))
                .accessibilityIdentifier("fruitBasket.home.invitation")
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
                .accessibilityIdentifier("fruitBasket.home.play")

                Prompt28WatercolorButton(
                    title: "how it works",
                    accent: .mint
                ) {
                    viewModel.screen = .howItWorks
                }
                .accessibilityIdentifier("fruitBasket.home.rules")

                Prompt28WatercolorButton(
                    title: "leaderboard",
                    accent: .lavender
                ) {
                    viewModel.screen = .leaderboard
                }
                .accessibilityIdentifier("fruitBasket.openLeaderboard")
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

                FruitfolioTranslatedContent(source: "how it works!") { display, _ in
                    FruitfolioSemanticText(markdown: display, baseFont: Prompt28TextRole.screenTitle.font)
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("fruitBasket.rules.heading")
                }
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

                FruitfolioTranslatedText(
                    source: "catching gets a little trickier as your game level grows, but you can start the game level over whenever you want. ☆",
                    font: Prompt28TextRole.secondary.font,
                    color: DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                .accessibilityIdentifier("fruitBasket.rules.levelNote")
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
                    .accessibilityIdentifier("fruitBasket.rules.replayTour")

                    Prompt28WatercolorButton(
                        title: "got it!",
                        accent: .paleYellow
                    ) {
                        viewModel.screen = .home
                    }
                    .accessibilityIdentifier("fruitBasket.rules.returnHome")
                }
                .frame(maxWidth: 292)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .accessibilityIdentifier("fruitBasket.rules.scroll")
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
                        FruitfolioFixedText(source: "what do you want to learn about? ♡", protectedLiterals: ["♡"], font: Prompt28TextRole.screenTitle.font)
                            .prompt28Text(.screenTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )

                        FruitfolioFixedTextField("type literally anything…", text: Binding(
                            get: { viewModel.rawTopic },
                            set: { guard canInteractWithGame else { return }; viewModel.editTopic($0) }
                        ), axis: .vertical)
                        .accessibilityIdentifier("fruitBasket.topicInput")
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

                        FruitfolioFixedText(source: "or pick something!", font: Prompt28TextRole.secondary.font)
                            .prompt28Text(.secondary)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                        Prompt28ChipWrap(
                            titles: Prompt28LearningTopic.allCases.map(\.displayName),
                            onSelect: { guard canInteractWithGame else { return }; viewModel.chooseSuggestedTopic($0) }
                        )
                        .frame(maxWidth: 286)

                        FruitfolioFixedText(source: "how deep should we go?", font: Prompt28TextRole.sectionHeading.font)
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
                                    guard canInteractWithGame else { return }
                                    viewModel.updateDifficulty(option)
                                }
                                .accessibilityIdentifier("fruitBasket.difficulty." + option.rawValue)
                            }
                        }
                        .frame(maxWidth: 286)

                        if let progress = viewModel.progress {
                            let level = Prompt28GameStatisticFormatting.integer(progress.currentGameLevel, language: settings.language)
                            VStack(spacing: 4) {
                                FruitfolioFixedText(source: "game level  ·  \(level)", protectedLiterals: [level], font: Prompt28TextRole.body.font)
                                    .accessibilityIdentifier("fruitBasket.setup.gameLevel")
                                if progress.totalRoundsCompleted > 0 {
                                    FruitfolioFixedText(source: "welcome back ♡ you made it to game level \(level) here.",
                                        protectedLiterals: [level, "♡"], font: Prompt28TextRole.secondary.font)
                                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: 280)
                        } else if !viewModel.normalizedTopic.isEmpty {
                            let level = Prompt28GameStatisticFormatting.integer(1, language: settings.language)
                            FruitfolioFixedText(source: "starting at game level \(level)", protectedLiterals: [level], font: Prompt28TextRole.secondary.font)
                                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                                .accessibilityIdentifier("fruitBasket.setup.startingLevel")
                        }

                        controlModePicker

                        if let message = viewModel.message {
                            HStack(alignment: .center, spacing: 8) {
                                if !viewModel.setupMessageRequiresSeriousTone {
                                    FruitfolioImage(id: .fruit_strawberry_silly)
                                        .frame(width: 48, height: 48)
                                        .allowsHitTesting(false)
                                        .accessibilityHidden(true)
                                        #if DEBUG
                                        .preference(key: Prompt28SetupFeedbackArtVisibilityKey.self, value: true)
                                        #endif
                                }
                                FruitfolioTranslatedText(source: message,
                                    protectedLiterals: ["Fruitfolio", "FruitsofLife.xo", "Fruit Basket"],
                                    font: Prompt28TextRole.body.font, serious: viewModel.setupMessageRequiresSeriousTone)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: 280)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("fruitBasket.setup.message")
                        }

                        switch viewModel.screen {
                        case .loading:
                            ProgressView {
                                FruitfolioFixedText(source: "looking through the little library…", font: Prompt28TextRole.body.font)
                            }
                            .tint(DesignTokens.ColorToken.primaryBurgundy)

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
        let expectedScreen = viewModel.screen
        let interactionID = viewModel.questionInteractionID
        return VStack(
            alignment: .center,
            spacing: 7
        ) {
            FruitfolioFixedText(source: "controls", font: Prompt28TextRole.secondary.font)
                .accessibilityAddTraits(.isHeader)
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
                        guard canInteractWithGame else { return }
                        viewModel.setControlMode(mode, expectedScreen: expectedScreen, expectedInteractionID: interactionID)
                    }
                    .accessibilityIdentifier("fruitBasket.controlMode." + mode.rawValue)
                }
            }

            FruitfolioFixedText(source: "classification keeps the same rules + points without reflex dragging.",
                font: Prompt28TextRole.metadata.font)
            .prompt28Text(.metadata)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(maxWidth: 280)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fruitBasket.controlModePicker")
    }

    @ViewBuilder
    private var questionFlow: some View {
        let interactionID = viewModel.questionInteractionID
        return ScrollView {
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

                        if let excerpt = Prompt28ExcerptQuestionPresentation(question: question) {
                            FruitfolioTranslatedText(source: Prompt28ExcerptQuestionPresentation.instructionSource,
                                font: Prompt28TextRole.body.font, serious: true)
                                .accessibilityIdentifier("fruitBasket.question.instruction")
                            FruitfolioSemanticText(spans: [.init(text: excerpt.literalExcerpt)],
                                baseFont: Prompt28TextRole.body.font,
                                color: DesignTokens.ColorToken.primaryBurgundy)
                                .fixedSize(horizontal: false, vertical: true)
                                .accessibilityIdentifier("fruitBasket.question.literalExcerpt")
                            FruitfolioTranslatedText(source: Prompt28ExcerptQuestionPresentation.noticeSource,
                                font: Prompt28TextRole.metadata.font, serious: true)
                                .accessibilityIdentifier("fruitBasket.question.sourceLanguageNotice")
                        } else {
                            // Unknown/legacy templates remain complete and unchanged.
                            Text(verbatim: question.questionText)
                                .prompt28Text(question.category == Prompt28ExcerptQuestionPresentation.category ? .body : .screenTitle)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        ForEach(
                            question.answerOptions
                        ) { answer in
                            Button {
                                guard canInteractWithGame else { return }
                                audioManager.play(.buttonSoftPop)
                                viewModel.answer(answer.id, expectedQuestionID: question.id, expectedInteractionID: interactionID)
                            } label: {
                                HStack(alignment: .top) {
                                    Text(verbatim: answer.text)
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
                            .accessibilityIdentifier("fruitBasket.question.answer." + answer.id)
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
                                    FruitfolioTranslatedText(
                                        source: Prompt28FeedbackCopy.incorrect(serious: question.usesSeriousFeedback),
                                        font: Prompt28TextRole.body.font, serious: question.usesSeriousFeedback)
                                        .accessibilityIdentifier("fruitBasket.question.incorrectFeedback")

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
                                guard canInteractWithGame else { return }
                                viewModel.retryQuestion(expectedQuestionID: question.id, expectedInteractionID: interactionID)
                            }
                            .accessibilityIdentifier("fruitBasket.question.review")

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

                                FruitfolioTranslatedText(
                                    source: Prompt28FeedbackCopy.correct(serious: question.usesSeriousFeedback),
                                    font: Prompt28TextRole.body.font, serious: question.usesSeriousFeedback)
                                    .accessibilityIdentifier("fruitBasket.question.correctFeedback")
                            }

                            Prompt28WatercolorButton(
                                title: "catch",
                                accent: .paleYellow
                            ) {
                                guard canInteractWithGame else { return }
                                viewModel.presentCatchIntro(expectedQuestionID: question.id, expectedInteractionID: interactionID)
                            }
                            .accessibilityIdentifier("fruitBasket.question.correctContinue")

                        } else if viewModel.screen == .catchIntro {
                            FruitfolioTranslatedText(source: question.catchRule,
                                protectedLiterals: question.sourceIDs, font: Prompt28TextRole.body.font,
                                serious: true, sourceRecords: question.sourceRecords ?? [])
                                .accessibilityIdentifier("fruitBasket.question.catchRule")

                            FruitfolioTranslatedText(source: "starred = catch it · no star = let it pass",
                                font: Prompt28TextRole.secondary.font, serious: true)
                                .accessibilityIdentifier("fruitBasket.question.catchLegend")
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                            Prompt28WatercolorButton(
                                title: question.usesSeriousFeedback ? "ready" : "ready ♡",
                                accent: .paleYellow
                            ) {
                                guard canInteractWithGame else { return }
                                viewModel.beginCatch(expectedQuestionID: question.id, expectedInteractionID: interactionID)
                            }
                            .accessibilityIdentifier("fruitBasket.question.continue")
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer(minLength: 12)
        }
        }
        .accessibilityIdentifier("fruitBasket.question.scroll")
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

    private var gameplayHeader: some View {
        let language = settings.language
        func number(_ value: Int) -> String {
            Prompt28GameStatisticFormatting.integer(value, language: language)
        }
        return VStack(spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                FruitfolioControlPillButton(label: "pause") { viewModel.pause() }
                    .controlSize(.small).frame(maxWidth: 160)
                    .accessibilityIdentifier("fruitBasket.gameplay.pause")
                    .accessibilityFocused($gameplayFocus, equals: .pause)
                Prompt28StatisticRow(label: "score", value: number(viewModel.score), font: Prompt28TextRole.metadata.font)
                    .accessibilityIdentifier("fruitBasket.gameplay.score")
            }
            HStack(alignment: .top, spacing: 12) {
                Prompt28StatisticRow(label: "round", value: number(viewModel.currentRound), font: Prompt28TextRole.metadata.font)
                    .accessibilityIdentifier("fruitBasket.gameplay.round")
                Prompt28StatisticRow(label: "game level", value: number(viewModel.gameLevel), font: Prompt28TextRole.metadata.font)
            }
            HStack(alignment: .top, spacing: 12) {
                Prompt28StatisticRow(label: "basket",
                    value: Prompt28GameStatisticFormatting.fraction(viewModel.basketCount,
                        target: viewModel.engine.rules.goodFruitTarget, language: language), font: Prompt28TextRole.metadata.font)
                Prompt28StatisticRow(label: "star passes", value: number(viewModel.session?.availableStarPasses ?? 0),
                    font: Prompt28TextRole.metadata.font)
            }
            if viewModel.activeObstacles.contains(.puddle), store.controlMode == .catchMode {
                // Reserve the same height on dry ground: changing the measured header
                // during contact would move the playfield and its painted puddle.
                FruitfolioFixedText(source: "puddles gently resist your basket while it moves through the water.",
                    font: Prompt28TextRole.metadata.font)
                    .opacity(viewModel.basketIsInPuddle ? 1 : 0)
                    .accessibilityHidden(!viewModel.basketIsInPuddle)
                    .accessibilityIdentifier("fruitBasket.gameplay.puddleResistance")
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .frame(maxWidth: 620).frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var gameplay: some View {
        GeometryReader { outer in
            let available = CGSize(width: outer.size.width,
                height: max(0, outer.size.height - outer.safeAreaInsets.bottom))
            let viewport = Prompt28GameplayViewport(available: available, headerContentHeight: gameplayHeaderContentHeight)
            if viewport.canPresentPlayfield {
                ZStack {
                    VStack(spacing: 0) {
                        ScrollView(.vertical) {
                            gameplayHeader.background {
                                GeometryReader { header in
                                    Color.clear.preference(key: Prompt28GameplayHeaderHeightKey.self, value: header.size.height)
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .frame(height: viewport.headerHeight)
                        .accessibilityIdentifier("fruitBasket.gameplayHeader.scroll")
                        GeometryReader { field in
                            let width = min(field.size.width, 620)
                            let xOffset = (field.size.width - width) / 2
                            ZStack(alignment: .topLeading) {
                                gameplayDecor(width: width, height: field.size.height, xOffset: xOffset)
                                if viewModel.screen != .paused {
                                    if store.controlMode == .classification {
                                        classificationGameplay(width: width, height: field.size.height, xOffset: xOffset)
                                    } else {
                                        catchGameplay(width: width, height: field.size.height, xOffset: xOffset)
                                    }
                                }
                            }
                            .frame(width: field.size.width, height: field.size.height)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("fruitBasket.playfield")
                        }
                    }
                    .fruitfolioModalBlur(active: viewModel.screen == .paused && !showStormNote,
                        reduceMotion: motionPreferences.reduceMotionActive)
                    .allowsHitTesting(viewModel.screen != .paused)
                    .accessibilityHidden(viewModel.screen == .paused)
                    if viewModel.screen == .paused && !showStormNote {
                        ScrollView {
                            pausePanel.frame(maxWidth: .infinity, minHeight: max(0, available.height - 32))
                        }
                        .frame(width: min(max(0, available.width - 40), 380), height: max(0, available.height - 32))
                        .accessibilityElement(children: .contain)
                        .accessibilityAddTraits(.isModal)
                        .accessibilityIdentifier("fruitBasket.pause.scroll")
                        .accessibilityAction(.escape) { resumeGameFromPause() }
                        .task {
                            guard rootIsVisible, viewModel.screen == .paused, !showStormNote else { return }
                            setPauseMenuVisible(true)
                            await Task.yield()
                            guard !Task.isCancelled, rootIsVisible, pauseMenuVisible, scenePhase == .active,
                                  viewModel.screen == .paused, !showStormNote else { return }
                            pauseHeadingFocused = true
                        }
                        .onDisappear { setPauseMenuVisible(false) }
                    }
                }
                .frame(width: available.width, height: available.height)
                .onPreferenceChange(Prompt28GameplayHeaderHeightKey.self) { height in
                    if height.isFinite, height > 0, abs(height - gameplayHeaderContentHeight) > 0.5 {
                        gameplayHeaderContentHeight = height
                    }
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        FruitfolioTranslatedText(source: "the play area needs more room. rotate your device or use a larger window.",
                            font: Prompt28TextRole.body.font, serious: true)
                        FruitfolioControlPillButton(label: "change topic") { viewModel.changeTopic() }
                        FruitfolioControlPillButton(label: "exit fruit basket", action: onBack)
                    }.padding(20)
                }
                .accessibilityIdentifier("fruitBasket.playfield.unavailable")
                .task { if viewModel.screen == .catchActive { viewModel.pause() } }
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

    /// The rendered menu owns its cues; a storm-induced pause has no menu owner.
    private func setPauseMenuVisible(_ visible: Bool) {
        guard pauseMenuVisible != visible else { return }
        pauseMenuVisible = visible
        audioManager.play(visible ? .popupOpen : .popupClose)
        if !visible { pauseHeadingFocused = false }
    }

    private func resumeGameFromPause() {
        guard viewModel.screen == .paused, !showStormNote else { return }
        pauseHeadingFocused = false
        viewModel.resume()
        Task { @MainActor in
            await Task.yield()
            guard rootIsVisible, viewModel.screen == .catchActive, !showStormNote else { return }
            gameplayFocus = .pause
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
                .accessibilityIdentifier("fruitBasket.round.fruit." + fruit.fruitID.rawValue)
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
                    .modifier(FruitfolioFixedAccessibilityLabel(source: Prompt28RulesCopy.standaloneStar))
                    .accessibilityIdentifier("fruitBasket.round.star")
            }

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                fruitIDs: viewModel.collectedFruit,
                transits: viewModel.catchTransits,
                playfield: geometry.playfield,
                basketX: viewModel.basketX,
                groundStateSource: viewModel.basketIsInPuddle ? "in a puddle; movement meets gentle resistance" : "on dry ground"
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
        let interactionID = viewModel.questionInteractionID
        ScrollView {
        VStack(spacing: 14) {
            VStack(spacing: 8) {
                Prompt28StatisticRow(label: "basket", value: Prompt28GameStatisticFormatting.fraction(
                    viewModel.basketCount, target: viewModel.engine.rules.goodFruitTarget, language: settings.language),
                    font: Prompt28TextRole.secondary.font)
                    .accessibilityIdentifier("fruitBasket.classification.basket")
                    .accessibilityFocused($gameplayFocus, equals: .classificationProgress)
                Prompt28StatisticRow(label: "star passes", value: Prompt28GameStatisticFormatting.integer(
                    viewModel.session?.availableStarPasses ?? 0, language: settings.language),
                    font: Prompt28TextRole.secondary.font)
                    .accessibilityIdentifier("fruitBasket.classification.passes")
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("fruitBasket.classification.progress")

            if let fruit =
                viewModel.classificationFruit {

                Prompt28MovingFruit(fruit: fruit, reduceMotion: true,
                    accessibilitySource: Prompt28RulesCopy.fruitAccessibilitySource(fruit, classificationPrompt: true))
                    .frame(width: 100, height: 100)
                    .accessibilityIdentifier("fruitBasket.classification.fruit")
                    .onAppear { Prompt28AssetUsageRegistrar.markRendered(fruit.fruitID.assetID) }

                FruitfolioTranslatedText(source: "does this belong in the basket?",
                    font: Prompt28TextRole.sectionHeading.font,
                    serious: viewModel.currentQuestion?.usesSeriousFeedback == true)
                    .accessibilityIdentifier("fruitBasket.classification.question")

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        classificationYesButton(fruitID: fruit.id, interactionID: interactionID)
                        classificationNoButton(fruitID: fruit.id, interactionID: interactionID)
                    }

                    VStack(spacing: 8) {
                        classificationYesButton(fruitID: fruit.id, interactionID: interactionID)
                        classificationNoButton(fruitID: fruit.id, interactionID: interactionID)
                    }
                }
                .frame(maxWidth: 292)
            } else if viewModel.classificationStarAvailable {
                FruitfolioImage(id: .fruitbasket_star).frame(width: 52, height: 52)
                    .accessibilityHidden(true)
                FruitfolioTranslatedText(source: Prompt28RulesCopy.standaloneStar,
                    font: Prompt28TextRole.body.font, serious: viewModel.currentQuestion?.usesSeriousFeedback == true)
                    .multilineTextAlignment(.center)
                Prompt28WatercolorButton(title: "catch star", accent: .paleYellow) {
                    guard canInteractWithGame else { return }
                    viewModel.classificationStarDecision(accept: true, expectedInteractionID: interactionID)
                }
                .accessibilityIdentifier("fruitBasket.classification.catchStar")
                Prompt28WatercolorButton(title: "let star pass", accent: .mint) {
                    guard canInteractWithGame else { return }
                    viewModel.classificationStarDecision(accept: false, expectedInteractionID: interactionID)
                }
            } else if !viewModel.catchTransits.isEmpty {
                FruitfolioTranslatedText(source: "settling in the basket…", font: Prompt28TextRole.body.font, serious: true)
            }

            Spacer()

            Prompt28BasketProgressView(
                count: viewModel.basketCount,
                fruitIDs: viewModel.collectedFruit,
                transits: viewModel.catchTransits
            )
            .accessibilityIdentifier("fruitBasket.classification.basketArt")
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

    private func classificationYesButton(fruitID: UUID, interactionID: UUID) -> some View {
        Prompt28WatercolorButton(
            title: viewModel.currentQuestion?.usesSeriousFeedback == true ? "catch fruit" : "yes ♡",
            accent: .mint
        ) {
            guard canInteractWithGame else { return }
            viewModel.classificationDecision(accept: true, expectedFruitID: fruitID, expectedInteractionID: interactionID)
        }
        .accessibilityIdentifier("fruitBasket.classification.catchFruit")
    }

    private func classificationNoButton(fruitID: UUID, interactionID: UUID) -> some View {
        Prompt28WatercolorButton(
            title: viewModel.currentQuestion?.usesSeriousFeedback == true ? "let fruit pass" : "nope!",
            accent: .peach
        ) {
            guard canInteractWithGame else { return }
            viewModel.classificationDecision(accept: false, expectedFruitID: fruitID, expectedInteractionID: interactionID)
        }
        .accessibilityIdentifier("fruitBasket.classification.passFruit")
    }

    private var pausePanel: some View {
        Prompt28PaperPanel {
            VStack(spacing: 10) {
                FruitfolioTranslatedContent(source: viewModel.currentQuestion?.usesSeriousFeedback == true ? "game menu" : "little game menu") { display, _ in
                    FruitfolioSemanticText(markdown: display, baseFont: Prompt28TextRole.sectionHeading.font, serious: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($pauseHeadingFocused)
                        .accessibilityIdentifier("fruitBasket.pause.heading")
                }

                Prompt28WatercolorButton(
                    title: "resume",
                    accent: .paleYellow
                ) {
                    resumeGameFromPause()
                }
                .accessibilityIdentifier("fruitBasket.pause.resume")

                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQA") {
                    Prompt28GameProgressReadback(model: viewModel, store: store)
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQAEscape") {
                        FruitfolioControlPillButton(label: "QA accessibility escape", action: resumeGameFromPause)
                            .controlSize(.small).accessibilityIdentifier("gameQA.pauseEscape")
                    }
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                        FruitfolioInteractionSoundDiagnostics()
                    }
                }
                #endif

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
                    requestLevelReset()
                }
                .accessibilityIdentifier("fruitBasket.pause.resetLevel")
                .accessibilityFocused($levelResetControlFocused)

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
        let failedQuestionID = viewModel.currentQuestion?.id
        let failedRoundID = viewModel.roundResult?.roundID
        let interactionID = viewModel.questionInteractionID
        return ScrollView {
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
                    FruitfolioTranslatedText(
                        source: Prompt28FeedbackCopy.unsuccessful(serious: viewModel.currentQuestion?.usesSeriousFeedback == true),
                        font: Prompt28TextRole.sectionHeading.font,
                        serious: viewModel.currentQuestion?.usesSeriousFeedback == true)
                    .accessibilityIdentifier("fruitBasket.failure.feedback")
                    .multilineTextAlignment(.center)

                    if let question =
                        viewModel.currentQuestion {

                        FruitfolioTranslatedText(source: "for this round, we were collecting fruits that fit:",
                            font: Prompt28TextRole.body.font, serious: true)
                        FruitfolioTranslatedText(source: question.catchRule, protectedLiterals: question.sourceIDs,
                            font: Prompt28TextRole.body.font, serious: true,
                            sourceRecords: question.sourceRecords ?? [])
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))
                        .multilineTextAlignment(.center)
                    }

                    FruitfolioTranslatedText(
                        source: viewModel.currentQuestion?.usesSeriousFeedback == true ? "no points were deducted." : "your score didn’t lose any points ♡",
                        font: Prompt28TextRole.secondary.font,
                        serious: viewModel.currentQuestion?.usesSeriousFeedback == true)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.72))

                    Prompt28WatercolorButton(
                        title: viewModel.currentQuestion?.usesSeriousFeedback == true ? "try this round again" : "try this round again ♡",
                        accent: .paleYellow
                    ) {
                        guard canInteractWithGame, let failedQuestionID, let failedRoundID else { return }
                        viewModel.retryRound(expectedQuestionID: failedQuestionID, expectedRoundID: failedRoundID, expectedInteractionID: interactionID)
                    }
                    .accessibilityIdentifier("fruitBasket.failure.retry")

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
        .accessibilityIdentifier("fruitBasket.failure.scroll")
    }

    private func roundStatistics(_ result: Prompt28RoundResult) -> some View {
        let language = settings.language
        func number(_ value: Int, signed: Bool = false) -> String {
            Prompt28GameStatisticFormatting.integer(value, language: language, signed: signed)
        }
        return VStack(alignment: .leading, spacing: 8) {
            FruitfolioTranslatedText(source: result.succeeded ? "completed catch round" : "catch attempt ended",
                font: Prompt28TextRole.sectionHeading.font, serious: true)
                .accessibilityAddTraits(.isHeader)
            Prompt28StatisticRow(label: "fruit caught",
                value: Prompt28GameStatisticFormatting.fraction(result.caughtFruit.count, target: result.targetFruit, language: language))
                .accessibilityIdentifier("fruitBasket.result.fruitCount")
            Prompt28StatisticRow(label: "passes carried in", value: number(result.starPassesAtStart))
            Prompt28StatisticRow(label: "stars caught this round", value: number(result.starsCollected))
            Prompt28StatisticRow(label: "star passes used", value: number(result.starPassesSpent))
            Prompt28StatisticRow(label: "star passes available", value: number(result.starPassesRemaining))
            Prompt28StatisticRow(label: "round points", value: number(result.scoreChange, signed: true))
            Prompt28StatisticRow(label: "session score", value: number(result.cumulativeScore))
            if result.goodFruitPassed > 0 {
                Prompt28StatisticRow(label: "good fruit passed", value: number(result.goodFruitPassed))
                FruitfolioTranslatedText(source: "missed good fruit has no penalty.",
                    font: Prompt28TextRole.body.font, serious: true)
            }
            if result.starPassesSpent > 0 {
                FruitfolioTranslatedText(source: "each protected bad-fruit catch used exactly one star pass, so play continued.",
                    font: Prompt28TextRole.body.font, serious: true)
            }
            if let fruit = result.endingBadFruit {
                FruitfolioTranslatedText(
                    source: "\(fruit.displayName) was caught with no star passes available; that catch attempt ended.",
                    font: Prompt28TextRole.body.font, serious: true,
                    semanticSpans: [.init(text: fruit.displayName, emphasis: .anchorBold),
                        .init(text: " was caught with no star passes available; that catch attempt ended.")])
            }
            if result.nextGameLevel > result.gameLevelPlayed {
                Prompt28StatisticRow(label: "next catching level", value: number(result.nextGameLevel))
            }
        }
        .prompt28Text(.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("fruitBasket.roundStatistics")
    }

    private var basketReveal: some View {
        let sourceQuestionID = viewModel.currentQuestion?.id
        let completedRoundID = viewModel.roundResult?.roundID
        let interactionID = viewModel.questionInteractionID
        let serious = viewModel.currentQuestion?.usesSeriousFeedback == true
        let celebrateBest = viewModel.didSetPersonalBestThisRound && !serious
        let basketLabel = viewModel.roundResult == nil ? "Round result unavailable."
            : (viewModel.didSetPersonalBestThisRound ? "completed basket. personal best." : "completed basket.")
        let basketValue = viewModel.roundResult.map {
            Prompt28GameStatisticFormatting.fraction($0.caughtFruit.count, target: $0.targetFruit, language: settings.language)
        } ?? ""
        return ScrollView {
            VStack(spacing: 14) {
                topBar

                ZStack {
                    if celebrateBest {
                        Prompt28WatercolorConfettiBurst(
                            reduceMotion: motionPreferences.reduceMotionActive
                        )
                        .frame(width: 270, height: 190)
                        .accessibilityHidden(true)
                        #if DEBUG
                        .preference(key: Prompt28CelebrationArtVisibilityKey.self, value: true)
                        #endif

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
                    if celebrateBest {
                        FruitfolioImage(id: .fruitbasket_crown)
                            .frame(width: 50, height: 46)
                            .padding(.top, 2)
                            .accessibilityHidden(true)
                            .onAppear {
                                Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_crown)
                            }
                    }
                }
                .accessibilityElement(children: .ignore)
                .modifier(FruitfolioFixedAccessibilityLabel(source: basketLabel))
                .accessibilityValue(Text(basketValue))
                .accessibilityIdentifier("fruitBasket.result.basketSummary")

                Prompt28PaperPanel {
                    VStack(
                        alignment: .leading,
                        spacing: 11
                    ) {
                        FruitfolioTranslatedContent(source: serious ? "round complete" : "your basket reveal! ♡") { display, _ in
                            FruitfolioSemanticText(markdown: display, baseFont: Prompt28TextRole.screenTitle.font, serious: serious)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityIdentifier("fruitBasket.result.heading")
                        }

                        if let result = viewModel.roundResult { roundStatistics(result) }

                        if let question =
                            viewModel.currentQuestion {

                            FruitfolioTranslatedText(source: "library explanation", font: Prompt28TextRole.secondary.font,
                                color: DesignTokens.ColorToken.primaryBurgundy.opacity(0.72), serious: true)

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
                            requestQuestionSave(expectedQuestionID: sourceQuestionID, expectedInteractionID: interactionID)
                        }
                        .accessibilityIdentifier("fruitBasket.result.saveQuestion")
                        .accessibilityFocused($questionSaveFocused)

                        Prompt28WatercolorButton(
                            title: "keep playing",
                            accent: .paleYellow
                        ) {
                            guard canInteractWithGame, let completedRoundID else { return }
                            performQuestionOperation {
                                await viewModel.continueAfterReveal(expectedRoundID: completedRoundID, expectedInteractionID: interactionID)
                            }
                        }

                        Prompt28WatercolorButton(
                            title: "change topic",
                            accent: .mint
                        ) {
                            guard canInteractWithGame else { return }
                            viewModel.changeTopic()
                        }

                        Prompt28WatercolorButton(
                            title: "change difficulty",
                            accent: .lavender
                        ) {
                            guard canInteractWithGame else { return }
                            viewModel.screen = .learningSetup
                        }

                        Prompt28WatercolorButton(
                            title: "start catching easy again",
                            accent: .peach
                        ) {
                            requestLevelReset()
                        }
                        .accessibilityIdentifier("fruitBasket.result.resetLevel")
                        .accessibilityFocused($levelResetControlFocused)
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .onAppear {
            guard !serious, let roundID = viewModel.roundResult?.roundID,
                  lastCheeredRoundID != roundID else { return }
            lastCheeredRoundID = roundID
            audioManager.play(.gentleCheer)
        }
    }

    private var leaderboard: some View {
        let input = usernameLabel.presentation(for: usernameLabelKey)
        return ScrollView {
            VStack(spacing: 14) {
                topBar
                if store.hasLegacyCaptureTotals {
                    FruitfolioFixedText(source: "totals saved before this update may omit fruit from failed or unfinished attempts. existing totals are retained; new captures are counted as they happen.", font: .footnote)
                        .fixedSize(horizontal: false, vertical: true)
                }


                VStack(spacing: 8) {
                    FruitfolioTranslatedText(source: "top 3 players",
                        font: .custom("Chalkboard SE", size: 20, relativeTo: .title2))
                        .fontWeight(.bold)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("fruitBasket.leaderboard.heading")

                    VStack(spacing: 6) {
                        ForEach(Prompt28LeaderboardCategory.allCases, id: \.self) { category in
                            Prompt28LeaderboardCategoryButton(category: category,
                                isSelected: selectedLeaderboardCategory == category) {
                                selectedLeaderboardCategory = category
                            }
                        }
                    }
                    .frame(maxWidth: 245)

                    VStack(spacing: 6) {
                        Prompt28LeaderboardRow(rank: 1, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                        Prompt28LeaderboardRow(rank: 2, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                        Prompt28LeaderboardRow(rank: 3, username: "—", scoreText: "—", unit: selectedLeaderboardCategory.accessibilityUnit)
                    }
                    .frame(maxWidth: 245)

                    Prompt28LeaderboardLocalTotal(category: selectedLeaderboardCategory,
                        total: selectedLeaderboardCategory.localTotal(store.leaderboardTotals))

                    FruitfolioTranslatedText(source: "worldwide rankings unavailable until secure registration is configured ♡",
                        font: .custom("Chalkboard SE", size: 11, relativeTo: .caption))
                        .accessibilityIdentifier("fruitBasket.leaderboard.serviceStatus")
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 220)
                }
                .foregroundStyle(DesignTokens.ColorToken.backgroundCream)
                .padding(.horizontal, 56)
                .padding(.vertical, 60)
                .frame(maxWidth: 340, minHeight: 220)
                .background {
                    // Preserve the original frame corners while the writing
                    // region grows with Dynamic Type instead of overflowing.
                    FruitfolioAssetLoader.image(.fruitbasket_chalkboard)
                        .resizable(capInsets: EdgeInsets(top: 64, leading: 64, bottom: 64, trailing: 64),
                                   resizingMode: .stretch)
                        .accessibilityHidden(true)
                        .onAppear { Prompt28AssetUsageRegistrar.markRendered(.fruitbasket_chalkboard) }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("fruitBasket.leaderboard.board")

                Prompt28PaperPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        FruitfolioTranslatedText(source: "what counts",
                            font: Prompt28TextRole.sectionHeading.font)
                            .accessibilityAddTraits(.isHeader)
                        FruitfolioTranslatedText(source: Prompt28RulesCopy.totals,
                            font: Prompt28TextRole.secondary.font)
                            .fixedSize(horizontal: false, vertical: true)
                        FruitfolioTranslatedText(source: Prompt28RulesCopy.results,
                            font: Prompt28TextRole.secondary.font)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .prompt28Text(.secondary)
                }
                .accessibilityIdentifier("fruitBasket.leaderboard.rules")

                Prompt28PaperPanel {
                    VStack(spacing: 10) {
                        FruitfolioTranslatedText(source: "fruit basket leaderboard",
                            font: .custom("Chalkboard SE", size: 17, relativeTo: .headline))
                            .multilineTextAlignment(.center)

                        TextField("", text: $leaderboardUsernameDraft,
                            prompt: Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: input.text)))
                        .task(id: FruitfolioControlTranslationState.TaskKey(key: usernameLabelKey,
                            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
                            await usernameLabel.resolve(usernameLabelKey, inferenceAllowed: !settings.translationPausedForMemoryPressure)
                        }
                        .accessibilityIdentifier("fruitBasket.publicUsername")
                        .accessibilityFocused($usernameFocus, equals: .input)
                        .focused($usernameKeyboardFocused)
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
                        .accessibilityHint(Text([
                            settings.localized("Three to sixteen characters. Letters, numbers, periods, and underscores only. Public usernames cannot be explicit."),
                            input.status.accessibilityDetail(original: usernameLabelKey.source, localized: { settings.localized($0) })
                        ].filter { !$0.isEmpty }.joined(separator: ". ")))
                        if let status = input.status.captionKey {
                            Text(LocalizedStringKey(status)).prompt28Text(.metadata).accessibilityHidden(true)
                        }

                        WatercolorToggle(label: "this is not my real or legal name and contains no identifying details",
                            isOn: $usernameNonIdentifying)
                            .accessibilityIdentifier("fruitBasket.usernameConfirmation")
                        if let issue = usernameStore.persistenceMessage {
                            FruitfolioTranslatedText(source: issue,
                                font: .custom("Chalkboard SE", size: 13, relativeTo: .body), serious: true)
                            WatercolorSecondaryButton(label: "reload saved username") { usernameStore.reloadSavedUsername() }
                                .controlSize(.small)
                                .accessibilityIdentifier("fruitBasket.reloadUsername")
                        }
                        WatercolorSecondaryButton(label: "save username") {
                            leaderboardValidationMessage = usernameStore.setUsername(leaderboardUsernameDraft,
                                confirmedNonIdentifying: usernameNonIdentifying, expecting: usernameBaseline)
                            if leaderboardValidationMessage == nil {
                                leaderboardUsernameDraft = usernameStore.username
                                usernameBaseline = usernameStore.snapshot
                                leaderboardValidationMessage = "saved on this device only."
                            } else { usernameNonIdentifying = false }
                        }
                        .controlSize(.small)
                        .disabled(!usernameStore.canPersistUsername || usernameBaseline == nil)
                        .accessibilityIdentifier("fruitBasket.saveUsername")
                        #if DEBUG
                        if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQA") {
                            Text("saved username: \(usernameStore.debugStoredUsername.username)")
                                .accessibilityIdentifier("fruitBasket.qa.savedUsername")
                        }
                        #endif

                        HStack {
                            Text("3–\(Prompt28LeaderboardUsernamePolicy.maximumLength) characters")
                            Spacer()
                            Text("\(leaderboardUsernameDraft.count)/\(Prompt28LeaderboardUsernamePolicy.maximumLength)")
                                .monospacedDigit()
                        }
                        .prompt28Text(.metadata)
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.68))

                        if let leaderboardValidationMessage {
                            FruitfolioTranslatedText(source: leaderboardValidationMessage,
                                font: .custom("Chalkboard SE", size: 13, relativeTo: .subheadline), serious: true)
                                .accessibilityFocused($usernameFocus, equals: .error)
                                .accessibilityIdentifier("fruitBasket.usernameMessage")
                                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy.opacity(0.78))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        WatercolorToggle(
                            label: "appear on the leaderboard",
                            isOn: leaderboardOptInBinding
                        )
                        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))

                        if usernameStore.confirmedNonIdentifying, Prompt28LeaderboardUsernamePolicy.isValid(usernameStore.username) {
                            HStack(spacing: 6) {
                                Text("public name")
                                    .prompt28Text(.metadata)
                                Spacer(minLength: 8)
                                Text(verbatim: usernameStore.username)
                                    .prompt28Text(.body)
                                    .fontWeight(.semibold)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
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
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("fruitBasket.leaderboard.scroll")
        .onChange(of: usernameNonIdentifying) { _, confirmed in
            if confirmed { usernameBaseline = usernameStore.snapshot }
        }
        .onChange(of: leaderboardUsernameDraft) { _, newValue in
            usernameNonIdentifying = newValue == usernameStore.username && usernameStore.confirmedNonIdentifying
        }
        .onChange(of: usernameStore.username) { oldValue, newValue in
            if leaderboardUsernameDraft == oldValue || leaderboardUsernameDraft == newValue {
                leaderboardUsernameDraft = newValue
                usernameNonIdentifying = usernameStore.confirmedNonIdentifying
                usernameBaseline = usernameStore.snapshot
            } else {
                usernameNonIdentifying = false
                leaderboardValidationMessage = "the saved username changed in Account. your unsaved draft is still here; confirm it again before saving."
            }
        }
        .onAppear {
            let current = usernameStore.snapshot
            if !usernameEditorHasLoaded || usernameBaseline.map({ leaderboardUsernameDraft == $0.username }) == true {
                usernameEditorHasLoaded = true
                leaderboardUsernameDraft = current.username
                usernameNonIdentifying = current.confirmedNonIdentifying
                usernameBaseline = current
                leaderboardValidationMessage = current.username.isEmpty ? nil :
                    Prompt28LeaderboardUsernamePolicy.validationMessage(for: current.username)
            } else if usernameBaseline != current {
                usernameNonIdentifying = false
                leaderboardValidationMessage = "the saved username changed in Account. your unsaved draft is still here; confirm it again before saving."
            }
        }
    }

    private func requestLeavingGame() {
        guard rootIsVisible else { return }
        guard usernameEditorHasLoaded, let baseline = usernameBaseline,
              leaderboardUsernameDraft != baseline.username else { onBack(); return }
        guard let session = usernameExitSession else { return }
        usernameKeyboardFocused = false
        usernameFocus = nil
        returnExitFocus = true
        session.present(intent: .init(raw: leaderboardUsernameDraft,
            confirmedNonIdentifying: usernameNonIdentifying, expected: baseline),
            canSave: usernameStore.canPersistUsername)
    }

    private func completeUsernameExit(_ choice: FruitfolioUsernameExitSession.Choice) {
        guard rootIsVisible else { return }
        switch choice {
        case .keepEditing:
            viewModel.screen = .leaderboard
            focusUsername(.input)
        case .review:
            usernameStore.reloadSavedUsername()
            usernameNonIdentifying = false
            leaderboardValidationMessage = usernameStore.persistenceMessage ??
                "review the current saved username before confirming your edit again."
            viewModel.screen = .leaderboard
            focusUsername(.error)
        case .discard:
            leaderboardUsernameDraft = usernameStore.username
            usernameNonIdentifying = usernameStore.confirmedNonIdentifying
            usernameBaseline = usernameStore.snapshot
            leaderboardValidationMessage = nil
            onBack()
        case .save(let intent):
            if let error = intent.commit(to: usernameStore) {
                leaderboardValidationMessage = error
                usernameNonIdentifying = false
                viewModel.screen = .leaderboard
                focusUsername(.error)
            } else {
                leaderboardUsernameDraft = usernameStore.username
                usernameNonIdentifying = usernameStore.confirmedNonIdentifying
                usernameBaseline = usernameStore.snapshot
                leaderboardValidationMessage = "saved on this device only."
                onBack()
            }
        }
    }

    private func focusUsername(_ target: UsernameFocus) {
        Task { @MainActor in
            await Task.yield()
            guard rootIsVisible, popupCoordinator.currentPopup == nil, viewModel.screen == .leaderboard else { return }
            usernameFocus = target
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

    private var currentLevelResetContext: Prompt28LevelResetContext {
        .init(normalizedTopic: viewModel.normalizedTopic, sessionID: viewModel.session?.id, origin: viewModel.screen)
    }

    private func requestLevelReset() {
        guard canInteractWithGame, currentLevelResetContext.isEligible else { return }
        levelResetControlFocused = false
        levelResetSession?.present(context: currentLevelResetContext)
        returnLevelResetFocus = levelResetSession?.requestID != nil
    }

    private func restoreLevelResetFocus() {
        returnLevelResetFocus = false
        Task { @MainActor in
            await Task.yield()
            guard rootIsVisible, !store.isReadOnly, popupCoordinator.currentPopup == nil,
                  currentLevelResetContext.isEligible else { return }
            levelResetControlFocused = true
        }
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

                    Prompt28StatisticRow(label: "tutorial step",
                        value: Prompt28GameStatisticFormatting.fraction(tourStep + 1,
                            target: Prompt28TourCatalog.pages.count, language: settings.language),
                        font: Prompt28TextRole.metadata.font)
                        .accessibilityIdentifier("fruitBasket.tour.step")

                    FruitfolioTranslatedContent(source: tourPage.title) { display, _ in
                        FruitfolioSemanticText(markdown: display,
                            baseFont: .custom("Chalkboard SE", size: 16, relativeTo: .headline))
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityFocused($tourHeadingFocused)
                            .accessibilityIdentifier("fruitBasket.tour.title")
                    }

                    FruitfolioTranslatedText(source: tourPage.body,
                        font: .custom("Chalkboard SE", size: 13, relativeTo: .body),
                        color: DesignTokens.ColorToken.primaryBurgundy.opacity(0.84))
                        .accessibilityIdentifier("fruitBasket.tour.body")
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )

                    if tourPage.showsFruitDemo {
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
                            tourStep == Prompt28TourCatalog.pages.count - 1
                            ? "let’s play!"
                            : "next ♡",
                        accent: .paleYellow
                    ) {
                        guard showTour else { return }
                        if tourStep >= Prompt28TourCatalog.pages.count - 1 {
                            store.completeTour()
                            showTour = false
                            viewModel.openSetup()

                        } else {
                            tourStep += 1
                        }
                    }
                    .frame(maxWidth: 242)
                    .accessibilityIdentifier("fruitBasket.tour.next")

                    if tourStep == 0 {
                        FruitfolioControlPillButton(label: "skip tour", action: skipGameTour)
                        .controlSize(.small)
                        .accessibilityIdentifier("fruitBasket.tour.skip")
                    }
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQA") {
                        Text("tour completed: \(store.tourState.hasCompletedTour)")
                            .font(.caption2).accessibilityIdentifier("gameQA.tourCompleted")
                        if ProcessInfo.processInfo.arguments.contains("-fruitfolioGameQAEscape") {
                            FruitfolioControlPillButton(label: "QA accessibility escape", action: skipGameTour)
                                .controlSize(.small).accessibilityIdentifier("gameQA.tourEscape")
                        }
                        if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                            FruitfolioInteractionSoundDiagnostics()
                        }
                    }
                    #endif
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("fruitBasket.tour")
        .accessibilityAction(.escape) { skipGameTour() }
        .task(id: tourStep) {
            tourHeadingFocused = false
            await Task.yield()
            guard showTour, !Task.isCancelled else { return }
            tourHeadingFocused = true
        }
    }

    private func skipGameTour() {
        guard showTour else { return }
        viewModel.screen = .howItWorks
        store.skipTourAfterRules()
        showTour = false
    }

    private var tourPage: Prompt28TourPage { Prompt28TourCatalog.pages[tourStep] }
}

/// Header content is measured independently of its bounded scroll viewport.
nonisolated private struct Prompt28GameplayHeaderHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct Prompt28MovingFruit: View {
    let fruit: Prompt28FallingFruit
    let reduceMotion: Bool
    var accessibilitySource: String? = nil

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
        .modifier(FruitfolioFixedAccessibilityLabel(source: accessibilitySource
            ?? Prompt28RulesCopy.fruitAccessibilitySource(fruit)))
    }
}

@MainActor
private struct Prompt28BasketProgressView: View {
    let count: Int
    let fruitIDs: [Prompt28FruitID]
    var transits: [Prompt28CatchTransit] = []
    var playfield: CGSize = .zero
    var basketX: Double = 0.5
    var groundStateSource: String? = nil
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var labelTranslation = FruitfolioControlTranslationState()
    @StateObject private var groundTranslation = FruitfolioControlTranslationState()
    private var labelKey: FruitfolioControlTranslationState.Key {
        .init(source: "basket", language: settings.language)
    }
    private var groundKey: FruitfolioControlTranslationState.Key {
        .init(source: groundStateSource ?? "", language: settings.language)
    }

    var body: some View {
        let label = labelTranslation.presentation(for: labelKey)
        let ground = groundTranslation.presentation(for: groundKey)
        let fraction = Prompt28GameStatisticFormatting.fraction(count,
            target: Prompt28RoundRules.canonical.goodFruitTarget, language: settings.language)
        let value = groundStateSource == nil ? fraction
            : fraction + "; " + FruitfolioSemanticDocument.plainText(from: ground.text)
        let hint = [
            label.status.accessibilityDetail(original: "basket", localized: { settings.localized($0) }),
            groundStateSource.map { ground.status.accessibilityDetail(original: $0, localized: { settings.localized($0) }) } ?? ""
        ].reduce(into: [String]()) { details, detail in
            if !detail.isEmpty, !details.contains(detail) { details.append(detail) }
        }.joined(separator: ". ")
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

                Text(verbatim: fraction)
                    .font(.custom("Chalkboard SE", size: 13, relativeTo: .caption).bold())
                    .monospacedDigit()
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(DesignTokens.ColorToken.backgroundCream.opacity(0.90), in: Capsule())
                    .offset(y: -2)
            }
            .frame(width: width, height: height)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: label.text)))
        .accessibilityValue(Text(value))
        .accessibilityHint(Text(hint))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: labelKey,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await labelTranslation.resolve(labelKey, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
        .task(id: FruitfolioControlTranslationState.TaskKey(key: groundKey,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            guard groundStateSource != nil else { return }
            await groundTranslation.resolve(groundKey, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
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

/// Uses the shared noninteractive control translation state inside one button.
/// The chalkboard keeps its original ink rather than gaining pill artwork.
@MainActor
private struct Prompt28LeaderboardCategoryButton: View {
    let category: Prompt28LeaderboardCategory
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @StateObject private var translation = FruitfolioControlTranslationState()
    private var key: FruitfolioControlTranslationState.Key {
        .init(source: category.rawValue, language: settings.language)
    }

    var body: some View {
        let display = translation.presentation(for: key)
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            VStack(spacing: 4) {
                FruitfolioSemanticText(markdown: display.text,
                    baseFont: .custom("Chalkboard SE", size: 12, relativeTo: .caption),
                    color: isSelected ? Color.white : DesignTokens.ColorToken.backgroundCream.opacity(0.72))
                if let status = display.status.captionKey {
                    Text(LocalizedStringKey(status)).font(.caption)
                }
            }
            .fontWeight(isSelected ? .bold : .regular)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .padding(8)
            .frame(minWidth: DesignTokens.Layout.minimumHitTarget, maxWidth: .infinity,
                   minHeight: DesignTokens.Layout.minimumHitTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("fruitBasket.leaderboard.category." + category.accessibilityUnit)
        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: display.text)))
        .accessibilityHint(Text(display.status.accessibilityDetail(
            original: FruitfolioSemanticDocument.plainText(from: category.rawValue),
            localized: { settings.localized($0) })))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}

/// The immutable value is formatted before presentation and never sent to
/// inference. A noninteractive control label keeps the row's AX value explicit.
@MainActor
private struct Prompt28StatisticRow: View {
    let label: String
    let value: String
    var font: Font = Prompt28TextRole.body.font
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()
    private var key: FruitfolioControlTranslationState.Key {
        .init(source: label, language: settings.language)
    }
    var body: some View {
        let display = translation.presentation(for: key)
        LabeledContent {
            Text(verbatim: value).monospacedDigit()
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                FruitfolioSemanticText(markdown: display.text, baseFont: font, serious: true)
                if let status = display.status.captionKey {
                    Text(LocalizedStringKey(status)).font(.caption)
                }
            }
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        }
        .font(font)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(FruitfolioSemanticDocument.plainText(from: display.text)))
        .accessibilityValue(Text(value))
        .accessibilityHint(Text(display.status.accessibilityDetail(
            original: label, localized: { settings.localized($0) })))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}

/// Translate fixed category copy only. The stored integer never enters inference.
@MainActor
private struct Prompt28LeaderboardLocalTotal: View {
    let category: Prompt28LeaderboardCategory
    let total: Int
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var translation = FruitfolioControlTranslationState()
    private var key: FruitfolioControlTranslationState.Key {
        .init(source: "your on-device \(category.accessibilityUnit):", language: settings.language)
    }

    var body: some View {
        let display = translation.presentation(for: key)
        let number = total.formatted(.number.locale(Locale(identifier: settings.language.localeIdentifier)))
        VStack(spacing: 4) {
            FruitfolioSemanticText(markdown: display.text,
                baseFont: Prompt28TextRole.metadata.font,
                color: DesignTokens.ColorToken.backgroundCream)
            Text(verbatim: number).monospacedDigit()
            if let status = display.status.captionKey {
                Text(LocalizedStringKey(status)).font(.caption)
            }
        }
        .font(Prompt28TextRole.metadata.font)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("fruitBasket.leaderboard.localTotal")
        .accessibilityLabel(Text("\(FruitfolioSemanticDocument.plainText(from: display.text)) \(number)"))
        .accessibilityHint(Text(display.status.accessibilityDetail(
            original: key.source, localized: { settings.localized($0) })))
        .task(id: FruitfolioControlTranslationState.TaskKey(key: key,
            inferenceAllowed: !settings.translationPausedForMemoryPressure)) {
            await translation.resolve(key, inferenceAllowed: !settings.translationPausedForMemoryPressure)
        }
    }
}

private struct Prompt28LeaderboardRow: View {
    let rank: Int
    let username: String
    let scoreText: String
    let unit: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(rank).")
                .frame(minWidth: 24, alignment: .trailing)
                .fixedSize(horizontal: true, vertical: false)

            Text(username)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

            Text(scoreText)
                .monospacedDigit()
                .lineLimit(nil)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minWidth: 44, alignment: .trailing)
        }
        .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("fruitBasket.leaderboard.rank.\(rank)")
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
                    FruitfolioTranslatedContent(source: title) { display, _ in
                        FruitfolioSemanticText(markdown: display,
                            baseFont: .custom("Chalkboard SE", size: 15, relativeTo: .headline))
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("fruitBasket.rules.title." + title)
                    }
                    .frame(maxWidth: .infinity)
                    .fixedSize(horizontal: false, vertical: true)

                    if let artID {
                        Prompt28InlineArtGlyph(assetID: artID)
                            .frame(minWidth: 18, minHeight: 18)
                    }
                }
                .multilineTextAlignment(.center)

                FruitfolioTranslatedText(source: ruleBody,
                    font: .custom("Chalkboard SE", size: 13, relativeTo: .body),
                    color: DesignTokens.ColorToken.primaryBurgundy.opacity(0.78))
                    .accessibilityIdentifier("fruitBasket.rules.body." + title)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .frame(maxWidth: 292)
        .accessibilityIdentifier("fruitBasket.rules.card." + title)
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

@MainActor
private struct Prompt28MiniControlPill: View {
    let title: String
    let isSelected: Bool
    var width: CGFloat = 88
    let action: () -> Void

    var body: some View {
        FruitfolioControlPillButton(label: title, isSelected: isSelected, action: action)
            .controlSize(.small)
            .frame(maxWidth: width)
    }
}

@MainActor
private struct Prompt28ChipWrap: View {
    let titles: [String]
    let onSelect: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6),
                            GridItem(.flexible(), spacing: 6)], spacing: 6) {
            ForEach(titles, id: \.self) { title in
                FruitfolioControlPillButton(label: title, artworkOpacity: 0.72) {
                    // Presentation may be translated; research receives the source topic.
                    onSelect(title)
                }
                .controlSize(.small)
                .accessibilityIdentifier("fruitBasket.suggestedTopic." + title)
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
