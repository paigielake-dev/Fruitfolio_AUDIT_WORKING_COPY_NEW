import SwiftUI
import Combine
import UIKit

struct Prompt09AskView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var navigation: NavigationCoordinator
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var prompt27AContextStore: Prompt27AContextStore

    @StateObject private var viewModel: Prompt09AskViewModel

    @State private var nearConversationBottom = true
    @State private var conversationViewportHeight: CGFloat = 0
    @State private var suggestionRevealCount = 0
    @State private var showingHelp = false
    @State private var showingEntryPageTurn = true

    // MARK: Prompt 10 Save Integration

    @State private var pendingLibrarySave:
        Prompt10PendingSavedContent?

    @State private var savedAnswerIDs: Set<String> = []
    @State private var savedExcerptText: String?

    @FocusState private var inputFocused: Bool

    init() {
        _viewModel = StateObject(
            wrappedValue: Prompt09AskViewModel()
        )
    }

    private var prompt27AContextPolicy: Prompt27AContextPolicyResult {
        Prompt27AContextPolicyEngine().policy(
            for: prompt27AContextStore.context
        )
    }

    private var discoverySuggestions: [String] {
        let contextual = Prompt27AContextPresentationCopy.askDiscoveryQuestions(
            context: prompt27AContextStore.context,
            policy: prompt27AContextPolicy
        )

        var combined: [String] = []
        for suggestion in contextual + Prompt09AskViewModel.suggestedQuestions {
            guard !combined.contains(suggestion) else { continue }
            combined.append(suggestion)
        }

        // Preserve the existing discovery-card density and animation budget.
        return Array(combined.prefix(5))
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            if !viewModel
                                .isConversationStarted {
                                discoveryCard
                                    .transition(.opacity)
                            }

                            openingArtwork

                            ForEach(
                                viewModel.visibleMessages
                            ) { message in
                                messageView(message)
                                    .id(message.id)
                                if let priorAnswer = viewModel.sessionAnswers[message.id],
                                   priorAnswer.id != viewModel.answer?.id {
                                    archivedAnswerView(priorAnswer)
                                        .id(priorAnswer.id)
                                }
                            }

                            if viewModel.phase ==
                                .searching {
                                searchingView
                                    .id(
                                        "prompt09-searching"
                                    )
                            }

                            if let answer =
                                viewModel.answer {
                                answerView(answer)
                                    .id(answer.id)
                            }

                            Color.clear.frame(height: 1).id("askConversationBottom")

                            if case .failed(
                                let message
                            ) = viewModel.phase {
                                failureView(message)
                            }
                        }
                        .padding(.top, 14)
                        .padding(.bottom, 28)
                        .frame(minHeight: conversationViewportHeight, alignment: .top)
                        .background { AskContinuousJournalPaper() }
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(key: AskConversationBottomKey.self,
                                    value: geometry.frame(in: .named("askConversationViewport")).maxY)
                            }
                        }
                        .frame(maxWidth: 680)
                        .containerRelativeFrame(.horizontal) { length, _ in
                            min(max(1, length - 40), 680)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(
                            .horizontal,
                            20
                        )
                    }
                    .coordinateSpace(name: "askConversationViewport")
                    .background {
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear { conversationViewportHeight = geometry.size.height }
                                .onChange(of: geometry.size.height) { _, value in conversationViewportHeight = value }
                        }
                    }
                    .onPreferenceChange(AskConversationBottomKey.self) { bottom in
                        nearConversationBottom = bottom <= conversationViewportHeight + 80
                    }
                    .onChange(of: viewModel.displayedAnswerText.count) {
                        if viewModel.phase == .answering { audioManager.playTypingTick() }
                        if nearConversationBottom { proxy.scrollTo("askConversationBottom", anchor: .bottom) }
                    }
                    .scrollDismissesKeyboard(
                        .interactively
                    )
                    .onChange(
                        of:
                            viewModel
                                .messages
                                .count
                    ) {
                        if nearConversationBottom, let last =
                            viewModel
                                .messages
                                .last {
                            withAnimation(
                                motionPreferences
                                    .reduceMotionActive
                                    ? nil
                                    : .easeOut(
                                        duration:
                                            0.22
                                    )
                            ) {
                                proxy.scrollTo(
                                    last.id,
                                    anchor: .bottom
                                )
                            }
                        }
                    }
                    .onChange(
                        of:
                            viewModel
                                .answer?
                                .id
                    ) {
                        if nearConversationBottom, let id =
                            viewModel
                                .answer?
                                .id {
                            withAnimation(
                                motionPreferences
                                    .reduceMotionActive
                                    ? nil
                                    : .easeOut(
                                        duration:
                                            0.22
                                    )
                            ) {
                                proxy.scrollTo(
                                    id,
                                    anchor: .top
                                )
                            }
                        }
                    }
                }
            }
            .fruitfolioModalBlur(
                active: pendingLibrarySave != nil,
                reduceMotion: motionPreferences.reduceMotionActive
            )


            // Prompt 09 decides WHAT gets saved.
            // Prompt 10 decides WHERE it goes.
            if let pendingLibrarySave {
                Prompt10AskSaveDestination(
                    store: .shared,
                    pending:
                        pendingLibrarySave,
                    onSaved: {
                        switch
                            pendingLibrarySave
                                .saveType {

                        case .fullAnswer:
                            if let id = pendingLibrarySave.originalAnswerID { savedAnswerIDs.insert(id) }
                            if pendingLibrarySave.originalAnswerID == viewModel.answer.map({ String(describing: $0.id) }) {
                                viewModel.isSaved = true
                            }

                        case .excerpt:
                            savedExcerptText =
                                pendingLibrarySave
                                    .excerptText
                        }

                        self.pendingLibrarySave =
                            nil
                    },
                    onCancel: {
                        self.pendingLibrarySave =
                            nil
                    }
                )
                .zIndex(200)
            }
        }
        .safeAreaInset(
            edge: .bottom,
            spacing: 0
        ) {
            inputBar
                .fruitfolioModalBlur(
                    active: pendingLibrarySave != nil,
                    reduceMotion: motionPreferences.reduceMotionActive
                )
        }
        .overlay {
            if showingEntryPageTurn {
                FruitfolioImage(
                    id: .book_page_turn
                )
                .scaledToFill()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .overlay(
            alignment: .topTrailing
        ) {
            if showingHelp {
                InfoTooltip(
                    message:
                        "ask naturally. Fruitfolio answers only from approved FruitsofLife.xo research and shows the sources it actually used."
                )
                .padding(.top, 74)
                .padding(.trailing, 18)
                .transition(
                    .opacity.combined(
                        with:
                            .scale(
                                scale: 0.98
                            )
                    )
                )
                .zIndex(20)
            }
        }
        .task {
            await runEntryTransition()
        }
        .task {
            await revealSuggestions()
        }
        .onChange(of: viewModel.phase) { _, phase in
            if phase != .answering { audioManager.stop(category: .typingASMR) }
        }
        .onDisappear {
            audioManager.stop(category: .typingASMR)
            inputFocused = false
            viewModel.resetConversation()
            savedAnswerIDs.removeAll()
            savedExcerptText = nil
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 5) {
            ZStack {
                HStack {
                    FruitfolioPressBounce(
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive
                    ) {
                        BackControl {
                            inputFocused =
                                false

                            navigation.back()
                        }
                    }

                    Spacer()

                    FruitfolioPressBounce(
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive
                    ) {
                        FruitfolioIconActionSurface(
                            identificationWord:
                                "help",
                            accessibilityLabel:
                                "Ask help",
                            action: {
                                audioManager.play(
                                    .buttonSoftPop
                                )

                                withAnimation(
                                    .easeOut(
                                        duration:
                                            0.18
                                    )
                                ) {
                                    showingHelp
                                        .toggle()
                                }
                            }
                        ) {
                            FruitfolioImage(
                                id:
                                    .ask_question_mark
                            )
                            .scaledToFit()
                            .frame(
                                width: 27,
                                height: 27
                            )
                            .accessibilityHidden(
                                true
                            )
                        }
                    }
                }

                Text(
                    "ask the encyclopedia"
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 24,
                        relativeTo:
                            .title2
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens
                        .ColorToken
                        .primaryBurgundy
                )
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(
                    .horizontal,
                    58
                )
                .accessibilityAddTraits(
                    .isHeader
                )
            }

            Text(
                "ask what you need, save what matters ♡"
            )
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 13,
                    relativeTo:
                        .subheadline
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
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.97)
        )
        .zIndex(10)
    }

    // MARK: - Discovery

    private var discoveryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                FruitfolioImage(id: .ask_magnifying_glass)
                    .scaledToFit().frame(width: 52, height: 52).accessibilityHidden(true)
                Text(Prompt09AskViewModel.greeting)
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(Array(discoverySuggestions.enumerated()), id: \.offset) { index, suggestion in
                if index < suggestionRevealCount {
                    Button {
                        audioManager.play(.buttonSoftPop)
                        viewModel.useSuggestion(suggestion)
                        inputFocused = true
                    } label: {
                        Text(suggestion)
                            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                            .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.horizontal, 12)
                    }
                    .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                    .transition(.opacity)
                }
            }
        }
        .padding(22)
        .accessibilityElement(children: .contain)
    }

    private var openingArtwork: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: 0) {
                FruitfolioImage(id: .decor_pear).scaledToFit()
                    .frame(width: geometry.size.width / 3, height: geometry.size.height)
                FruitfolioImage(id: .decor_orange_slice).scaledToFit()
                    .rotationEffect(.degrees(29))
                    .frame(width: geometry.size.width / 3, height: geometry.size.height)
                FruitfolioImage(id: .decor_orange_glow).scaledToFit()
                    .frame(width: geometry.size.width / 3, height: geometry.size.height)
            }
        }
        .frame(height: 120)
        .padding(.horizontal, 22)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Messages

    @ViewBuilder
    private func messageView(
        _ message: AskMessage
    ) -> some View {
        if message.role == .user {
            HStack {
                Spacer(minLength: 42)

                Text(message.text)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 15.5,
                            relativeTo:
                                .body
                        )
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                    .padding(
                        .vertical,
                        12
                    )
                    .background(
                        DesignTokens
                            .ColorToken
                            .backgroundCream
                            .opacity(0.92),
                        in:
                            RoundedRectangle(
                                cornerRadius:
                                    18,
                                style:
                                    .continuous
                            )
                    )
                    .overlay {
                        RoundedRectangle(
                            cornerRadius:
                                18,
                            style:
                                .continuous
                        )
                        .stroke(
                            DesignTokens
                                .ColorToken
                                .secondaryBurgundy
                                .opacity(
                                    0.12
                                ),
                            lineWidth:
                                0.8
                        )
                    }
            }

        } else if viewModel
            .isConversationStarted {

            HStack {
                Text(message.text)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 15,
                            relativeTo:
                                .body
                        )
                    )
                    .foregroundStyle(
                        DesignTokens
                            .ColorToken
                            .primaryBurgundy
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                    .padding(
                        .vertical,
                        11
                    )
                    .background(
                        DesignTokens
                            .ColorToken
                            .backgroundCream
                            .opacity(0.76),
                        in:
                            RoundedRectangle(
                                cornerRadius:
                                    18,
                                style:
                                    .continuous
                            )
                    )

                Spacer(minLength: 42)
            }
        }
    }

    // MARK: - Searching

    private var searchingView: some View {
        HStack(spacing: 12) {
            FruitfolioImage(
                id: .ask_magnifying_glass
            )
            .scaledToFit()
            .frame(
                width: 34,
                height: 34
            )
            .offset(
                x:
                    motionPreferences
                        .reduceMotionActive
                        ? 0
                        : 5
            )
            .animation(
                motionPreferences
                    .reduceMotionActive
                    ? nil
                    : .easeInOut(
                        duration: 0.7
                    )
                    .repeatForever(
                        autoreverses:
                            true
                    ),
                value: viewModel.phase
            )
            .accessibilityHidden(true)

            Text(viewModel.searchStatusText)
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 14.5,
                    relativeTo: .body
                )
            )
            .foregroundStyle(
                DesignTokens
                    .ColorToken
                    .secondaryBurgundy
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(
            children: .combine
        )
        .accessibilityLabel(
            "Looking through the FruitsofLife.xo library"
        )
    }

    // MARK: - Answer

    private func archivedAnswerView(_ answer: AskAnswer) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            FruitfolioSemanticText(document: answer.resolvedSemanticDocument,
                baseFont: .custom("Chalkboard SE", size: 16, relativeTo: .body))
                .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if !answer.sources.isEmpty { sourceSection(answer.sources) }
            FruitfolioControlPillButton(label: savedAnswerIDs.contains(String(describing: answer.id)) ? "answer saved ♡" : "save answer ♡") {
                prepareFullAnswerForLibrarySave(answer)
            }
            .disabled(savedAnswerIDs.contains(String(describing: answer.id)))
            Text(Prompt09AskViewModel.educationDisclaimer)
                .font(.footnote)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private func answerView(
        _ answer: AskAnswer
    ) -> some View {
        VStack(spacing: 12) {
            if settings.language != .english {
                Text("this answer is shown in its original English because offline translation is unavailable. your language preference is unchanged.")
                    .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 22)
                    .accessibilityIdentifier("ask.translationUnavailable")
            }
            ZStack {
                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {
                    if answer
                        .isDevelopmentPreview {

                        #if DEBUG
                        Text(
                            "Prompt 09 preview"
                        )
                        .font(
                            .caption
                                .weight(
                                    .semibold
                                )
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .secondaryBurgundy
                        )
                        .accessibilityLabel(
                            "Development preview"
                        )
                        #endif
                    }

                    if viewModel.phase ==
                        .answering {

                        Text(
                            viewModel
                                .displayedAnswerText
                        )
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 16,
                                relativeTo:
                                    .body
                            )
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                        )
                        .lineSpacing(4)
                        .frame(
                            maxWidth:
                                .infinity,
                            alignment:
                                .leading
                        )

                    } else {
                        Prompt09MaroonSelectableAnswerText(
                            text:
                                viewModel
                                    .displayedAnswerText,
                            selectedText:
                                $viewModel
                                    .selectedExcerptText,
                            semanticDocument: viewModel.answer?.resolvedSemanticDocument,
                            selectedRange: $viewModel.selectedExcerptRange
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )

                        if viewModel
                            .selectedExcerptText !=
                            nil {

                            FruitfolioPressBounce(
                                reduceMotion:
                                    motionPreferences
                                        .reduceMotionActive
                            ) {
                                WatercolorSecondaryButton(
                                    label:
                                        savedExcerptText ==
                                        viewModel
                                            .selectedExcerptText
                                        ? "selection saved ♡"
                                        : "save selection ♡",
                                    action: {
                                        prepareExcerptForLibrarySave(
                                            answer
                                        )
                                    }
                                )
                                .disabled(
                                    savedExcerptText ==
                                        viewModel
                                            .selectedExcerptText
                                )
                            }
                        }
                    }

                    if viewModel.phase ==
                        .answering {

                        Button(
                            "show all"
                        ) {
                            audioManager.play(
                                .buttonSoftPop
                            )

                            viewModel
                                .showAll()
                        }
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13,
                                relativeTo:
                                    .callout
                            )
                            .bold()
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                        )
                        .frame(
                            minHeight:
                                DesignTokens
                                    .Layout
                                    .minimumHitTarget
                        )
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion:
                                    motionPreferences
                                        .reduceMotionActive
                            )
                        )
                    }

                    ForEach(
                        viewModel
                            .selectedEducationalAssets,
                        id: \.assetID
                    ) { descriptor in

                        HStack {
                            Spacer(minLength: 0)

                            FruitfolioImage(
                                id:
                                    descriptor
                                        .assetID
                            )
                            .scaledToFit()
                            .containerRelativeFrame(.horizontal) { length, _ in
                                min(max(length * 0.82, 180), 300)
                            }
                            .accessibilityLabel(
                                descriptor
                                    .accessibilityDescription
                            )

                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }

                    if !answer
                        .sources
                        .isEmpty {

                        sourceSection(
                            answer.sources
                        )
                    }

                    if viewModel.phase !=
                        .answering {

                        HStack(
                            spacing: 10
                        ) {
                            FruitfolioPressBounce(
                                reduceMotion:
                                    motionPreferences
                                        .reduceMotionActive
                            ) {
                                BookmarkButton(
                                    isBookmarked:
                                        Binding(
                                            get: {
                                                viewModel
                                                    .isSaved
                                            },
                                            set: {
                                                newValue
                                                in

                                                guard
                                                    newValue,
                                                    !viewModel
                                                        .isSaved
                                                else {
                                                    return
                                                }

                                                prepareFullAnswerForLibrarySave(
                                                    answer
                                                )
                                            }
                                        )
                                )
                                .disabled(
                                    viewModel
                                        .isSaved
                                )
                            }

                            Text(
                                viewModel
                                    .isSaved
                                    ? "saved to my encyclopedia"
                                    : "save to my encyclopedia"
                            )
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 13.5,
                                    relativeTo:
                                        .body
                                )
                            )
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .primaryBurgundy
                            )

                            Spacer()
                        }

                        Text(
                            Prompt09AskViewModel
                                .educationDisclaimer
                        )
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 12.5,
                                relativeTo:
                                    .footnote
                            )
                            .italic()
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .secondaryBurgundy
                        )
                        .frame(
                            maxWidth:
                                .infinity,
                            alignment:
                                .leading
                        )
                    }
                }
                .padding(
                    .horizontal,
                    22
                )
                .padding(
                    .vertical,
                    22
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 28,
                    style: .continuous
                )
            )
        }
    }

    // MARK: - Prompt 10 Save Preparation

    private func prepareFullAnswerForLibrarySave(
        _ answer: AskAnswer
    ) {
        guard viewModel.phase != .answering || viewModel.answer?.id != answer.id else {
            return
        }

        pendingLibrarySave =
            Prompt10PendingSavedContent(
                question:
                    answer.originalQuestion,
                answer:
                    answer.answerText,
                saveType:
                    .fullAnswer,
                originalAnswerID:
                    String(
                        describing:
                            answer.id
                    ),
                originalConversationID:
                    String(describing: viewModel.conversationID),
                sourceIDs:
                    answer.sourceIDs,
                sourceVersions:
                    Dictionary(
                        uniqueKeysWithValues: answer.sources.compactMap { source in
                            guard let version = source.contentVersion else { return nil }
                            return (source.id, version)
                        }
                    ),
                knowledgeBaseVersion:
                    answer.knowledgeBaseVersion,
                generationTimestamp:
                    answer.generationTimestamp,
                semanticDocument: answer.resolvedSemanticDocument
            )
    }

    private func prepareExcerptForLibrarySave(
        _ answer: AskAnswer
    ) {
        guard
            viewModel.phase !=
                .answering,
            let excerpt =
                viewModel
                    .selectedExcerptText,
            !excerpt.isEmpty
        else {
            return
        }

        pendingLibrarySave =
            Prompt10PendingSavedContent(
                question:
                    answer.originalQuestion,
                answer:
                    answer.answerText,
                saveType:
                    .excerpt,
                excerptText:
                    excerpt,
                originalAnswerID:
                    String(
                        describing:
                            answer.id
                    ),
                originalConversationID:
                    String(describing: viewModel.conversationID),
                sourceIDs:
                    answer.sourceIDs,
                sourceVersions:
                    Dictionary(
                        uniqueKeysWithValues: answer.sources.compactMap { source in
                            guard let version = source.contentVersion else { return nil }
                            return (source.id, version)
                        }
                    ),
                knowledgeBaseVersion:
                    answer.knowledgeBaseVersion,
                generationTimestamp:
                    answer.generationTimestamp,
                semanticDocument: viewModel.selectedExcerptRange.flatMap {
                    answer.resolvedSemanticDocument.slice(utf16Range: $0)
                }.flatMap { $0.plainText == excerpt ? $0 : nil }
            )
    }

    // MARK: - Sources

    private func sourceSection(
        _ sources: [AskSourceRecord]
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Rectangle()
                .fill(
                    DesignTokens
                        .ColorToken
                        .secondaryBurgundy
                        .opacity(0.16)
                )
                .frame(height: 1)

            HStack(spacing: 8) {
                FruitfolioImage(
                    id:
                        .ask_source_pages
                )
                .scaledToFit()
                .frame(
                    width: 28,
                    height: 28
                )
                .accessibilityHidden(
                    true
                )

                Text(
                    Prompt09AskViewModel
                        .sourcesHeading
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 15,
                        relativeTo:
                            .headline
                    )
                    .bold()
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.80
                )
                .accessibilityLabel(
                    "sources"
                )
                .foregroundStyle(
                    DesignTokens
                        .ColorToken
                        .primaryBurgundy
                )
                .accessibilityAddTraits(
                    .isHeader
                )
            }

            ForEach(sources) {
                source in

                HStack(
                    alignment: .top,
                    spacing: 8
                ) {
                    FruitfolioImage(
                        id:
                            .ask_source_marker
                    )
                    .scaledToFit()
                    .frame(
                        width: 20,
                        height: 20
                    )
                    .accessibilityHidden(
                        true
                    )

                    VStack(
                        alignment:
                            .leading,
                        spacing: 4
                    ) {
                        Text(
                            source.title
                        )
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13,
                                relativeTo:
                                    .callout
                            )
                            .bold()
                        )
                        .foregroundStyle(
                            DesignTokens
                                .ColorToken
                                .primaryBurgundy
                        )

                        if let publicationData =
                            source
                                .publicationData,
                           !publicationData
                            .isEmpty {

                            Text(
                                publicationData
                            )
                            .font(
                                .caption
                            )
                            .foregroundStyle(
                                DesignTokens
                                    .ColorToken
                                    .secondaryBurgundy
                            )
                        }
                    }
                    .frame(
                        maxWidth:
                            .infinity,
                        alignment:
                            .leading
                    )
                }
            }
        }
    }

    // MARK: - Failure

    private func failureView(
        _ message: String
    ) -> some View {
        VStack(spacing: 10) {
            Text(message)
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 14.5,
                        relativeTo:
                            .body
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

            FruitfolioPressBounce(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            ) {
                WatercolorSecondaryButton(
                    label:
                        "ask something else"
                ) {
                    viewModel
                        .resetConversation()
                }
            }
        }
        .padding(.vertical, 14)
    }

    // MARK: - Input

    private var inputBar: some View {
        HStack(
            alignment: .bottom,
            spacing: 10
        ) {
            TextField(
                "ask Fruitfolio something…",
                text:
                    $viewModel
                        .inputText,
                axis: .vertical
            )
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 15,
                    relativeTo: .body
                )
            )
            .foregroundStyle(
                DesignTokens
                    .ColorToken
                    .primaryBurgundy
            )
            .lineLimit(1...6)
            .focused($inputFocused)
            .submitLabel(.send)
            .onSubmit {
                sendCurrentQuestion()
            }
            .padding(
                .horizontal,
                15
            )
            .padding(
                .vertical,
                12
            )
            .background(
                DesignTokens
                    .ColorToken
                    .backgroundCream,
                in:
                    RoundedRectangle(
                        cornerRadius:
                            20,
                        style:
                            .continuous
                    )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .stroke(
                    DesignTokens
                        .ColorToken
                        .secondaryBurgundy
                        .opacity(0.16),
                    lineWidth: 0.8
                )
            }

            FruitfolioPressBounce(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            ) {
                FruitfolioIconActionSurface(
                    identificationWord:
                        "send",
                    accessibilityLabel:
                        "Send question",
                    isEnabled:
                        viewModel.canSend,
                    action:
                        sendCurrentQuestion
                ) {
                    FruitfolioImage(
                        id: .ask_send
                    )
                    .scaledToFit()
                    .frame(
                        width: 54,
                        height: 54
                    )
                    .opacity(
                        viewModel.canSend
                            ? 1
                            : 0.55
                    )
                    .accessibilityHidden(
                        true
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            DesignTokens
                .ColorToken
                .backgroundCream
                .opacity(0.97)
        )
    }

    // MARK: - Send

    private func sendCurrentQuestion() {
        guard viewModel.canSend else {
            return
        }

        inputFocused = false

        audioManager.play(
            .buttonSoftPop
        )

        Task {
            @MainActor in

            await viewModel
                .submitCurrentQuestion(
                    reduceMotion:
                        motionPreferences
                            .reduceMotionActive
                )
        }
    }

    // MARK: - Entry Transition

    @MainActor
    private func runEntryTransition()
        async {

        guard
            showingEntryPageTurn
        else {
            return
        }

        audioManager.play(
            .pageTurn
        )

        if motionPreferences
            .reduceMotionActive {

            try? await Task.sleep(
                nanoseconds:
                    120_000_000
            )

            showingEntryPageTurn =
                false

            return
        }

        try? await Task.sleep(
            nanoseconds:
                90_000_000
        )

        withAnimation(
            .easeInOut(
                duration: 0.70
            )
        ) {
            showingEntryPageTurn =
                false
        }
    }

    // MARK: - Suggestion Reveal

    @MainActor
    private func revealSuggestions()
        async {

        guard
            suggestionRevealCount ==
                0
        else {
            return
        }

        if motionPreferences
            .reduceMotionActive {

            suggestionRevealCount =
                discoverySuggestions
                    .count

            return
        }

        let totalSuggestions = discoverySuggestions.count
        guard totalSuggestions > 0 else { return }

        for count in 1...totalSuggestions {

            if Task.isCancelled {
                return
            }

            withAnimation(
                .easeOut(
                    duration: 0.24
                )
            ) {
                suggestionRevealCount =
                    count
            }

            try? await Task.sleep(
                nanoseconds:
                    115_000_000
            )
        }
    }
}


// MARK: - Bounce Wrapper for Existing Custom Controls

private struct FruitfolioPressBounce<
    Content: View
>: View {
    let reduceMotion: Bool

    @ViewBuilder
    let content: () -> Content

    @GestureState
    private var isPressed = false

    var body: some View {
        content()
            .scaleEffect(
                reduceMotion
                    ? 1.0
                    : (
                        isPressed
                            ? 0.88
                            : 1.0
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
                isPressed
                    ? -0.04
                    : 0
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.08
                    )
                    : .spring(
                        response:
                            0.20,
                        dampingFraction:
                            0.38,
                        blendDuration:
                            0
                    ),
                value: isPressed
            )
            .simultaneousGesture(
                DragGesture(
                    minimumDistance: 0
                )
                .updating(
                    $isPressed
                ) {
                    _,
                    state,
                    _ in

                    state = true
                }
            )
    }
}

// MARK: - Prompt 09 Maroon Selection Surface

/// Fruitfolio-owned selectable answer text.
/// The selection controls use the exact founder-approved maroon #800000,
/// so selection never falls back to the previous pink accent.
struct Prompt09MaroonSelectableAnswerText: UIViewRepresentable {
    let text: String
    @Binding var selectedText: String?
    var semanticDocument: FruitfolioSemanticDocument? = nil
    @Binding var selectedRange: NSRange?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(text: String, selectedText: Binding<String?>, semanticDocument: FruitfolioSemanticDocument? = nil, selectedRange: Binding<NSRange?> = .constant(nil)) {
        self.text = text
        self._selectedText = selectedText
        self.semanticDocument = semanticDocument
        self._selectedRange = selectedRange
    }

    private static let maroon = UIColor(
        red: 128.0 / 255.0,
        green: 0.0,
        blue: 0.0,
        alpha: 1.0
    )

    private static let selectionHighlight = UIColor(
        red: 244.0 / 255.0,
        green: 199.0 / 255.0,
        blue: 199.0 / 255.0,
        alpha: 1.0
    )

    func makeCoordinator() -> Coordinator {
        Coordinator(selectedText: $selectedText, selectedRange: $selectedRange)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.adjustsFontForContentSizeCategory = true
        textView.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )
        textView.tintColor = Self.selectionHighlight
        textView.accessibilityLabel = "Fruitfolio answer"

        applyTextStyle(to: textView)

        return textView
    }

    func updateUIView(
        _ textView: UITextView,
        context: Context
    ) {
        textView.tintColor = Self.selectionHighlight

        _ = dynamicTypeSize
        let styled = attributedContent(traits: textView.traitCollection)
        if !textView.attributedText.isEqual(to: styled) {
            let selection = textView.selectedRange
            textView.attributedText = styled
            textView.accessibilityLabel = styled.string
            if NSMaxRange(selection) <= styled.length { textView.selectedRange = selection }
        }
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width else {
            return nil
        }

        let fittingSize = uiView.sizeThatFits(
            CGSize(
                width: width,
                height: .greatestFiniteMagnitude
            )
        )

        return CGSize(
            width: width,
            height: ceil(fittingSize.height)
        )
    }

    private func applyTextStyle(
        to textView: UITextView
    ) {
        textView.attributedText = attributedContent(traits: textView.traitCollection)
        textView.accessibilityLabel = text
    }

    private func attributedContent(traits: UITraitCollection) -> NSAttributedString {
        let document: FruitfolioSemanticDocument
        if let semanticDocument, semanticDocument.plainText.hasPrefix(text) {
            document = semanticDocument.prefix(characters: text.count)
        } else {
            document = .init(spans: [.init(text: text)])
        }
        return FruitfolioSemanticAttributedRenderer.render(document, traits: traits)
    }

    static func styledAnswer(_ text: String) -> NSAttributedString {
        FruitfolioSemanticAttributedRenderer.render(.init(spans: [.init(text: text)]))
    }

    static func styledAnswer(_ document: FruitfolioSemanticDocument) -> NSAttributedString {
        FruitfolioSemanticAttributedRenderer.render(document)
    }

    final class Coordinator:
        NSObject,
        UITextViewDelegate
    {
        @Binding private var selectedText: String?
        @Binding private var selectedRange: NSRange?

        init(
            selectedText: Binding<String?>, selectedRange: Binding<NSRange?>
        ) {
            _selectedText = selectedText
            _selectedRange = selectedRange
        }

        func textViewDidChangeSelection(
            _ textView: UITextView
        ) {
            let range = textView.selectedRange

            let currentText = textView.text ?? ""

            guard
                range.location != NSNotFound,
                range.length > 0,
                let swiftRange = Range(
                    range,
                    in: currentText
                )
            else {
                if selectedText != nil { selectedText = nil }
                selectedRange = nil
                return
            }

            selectedRange = range
            let selection = String(
                currentText[swiftRange]
            )

            if selectedText != selection {
                selectedText = selection
            }
        }
    }
}




















private struct AskConversationBottomKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct AskContinuousJournalPaper: View {
    var body: some View {
        GeometryReader { geometry in
            Image("ask_answer_paper")
                .resizable(capInsets: EdgeInsets(top: 140, leading: 80, bottom: 140, trailing: 80), resizingMode: .stretch)
                .frame(width: geometry.size.width, height: geometry.size.height + 200, alignment: .top)
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
