#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import UIKit

@MainActor
struct Prompt27AMyContextView: View {
    @StateObject private var viewModel: Prompt27AContextViewModel
    @ObservedObject private var observedStore: Prompt27AContextStore
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var pendingClearRevision: UUID?
    @State private var returnClearFocus = false
    @State private var failureNoticeFocus: UUID?
    @State private var popupInstanceID = UUID()
    @AccessibilityFocusState private var clearFocused: Bool
    @State private var showHormoneInformation = false
    @State private var showPersonalHealthContext = false

    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    init(
        store: Prompt27AContextStore,
        onBack: @escaping () -> Void = {}
    ) {
        _observedStore = ObservedObject(wrappedValue: store)
        _viewModel = StateObject(
            wrappedValue: Prompt27AContextViewModel(store: store)
        )
        self.onBack = onBack
    }

    private var ownerIsActive: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
    }
    private var canInteractWithContext: Bool {
        ownerIsActive && popupCoordinator.currentPopup == nil && !showHormoneInformation && !showPersonalHealthContext
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackControl {
                        guard canInteractWithContext else { return }
                        onBack()
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        FruitfolioContextStorageNotice(store: viewModel.store, messageFocusRequest: failureNoticeFocus, interactionAllowed: canInteractWithContext)
                        WatercolorPrimaryButton(label: "optional personal health context") { guard canInteractWithContext else { return }; showPersonalHealthContext = true }
                        WatercolorPrimaryButton(label: "Hormone Information") {
                            guard canInteractWithContext else { return }
                            showHormoneInformation = true
                        }
                        .accessibilityIdentifier("myContext.hormoneInformation")

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "what are you tracking for?",
                                values: Prompt27ATrackingGoal.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.trackingGoal.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setTrackingGoal
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "sexual activity",
                                values: Prompt27ASexualActivityContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.sexualActivityContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setSexualActivityContext
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "reproductive stage",
                                values: Prompt27AReproductiveStage.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.reproductiveStage.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setReproductiveStage
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "surrogacy",
                                values: Prompt27ASurrogacyContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.surrogacyContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setSurrogacyContext
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "lactation",
                                values: Prompt27ALactationContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.lactationContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setLactationContext
                            )
                        }

                        Prompt27AContextCard {
                            multiChoiceHealthSection
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "infertility context",
                                values: Prompt27AInfertilityContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.infertilityContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setInfertilityContext
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "fertility treatment",
                                values: Prompt27AFertilityTreatmentContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.fertilityTreatmentContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setFertilityTreatmentContext
                            )
                        }

                        Prompt27AContextCard {
                            singleChoiceSection(
                                title: "contraception",
                                values: Prompt27AContraceptionContext.allCases.filter { $0 != .unspecified },
                                selected: viewModel.store.context.contraceptionContext.value,
                                label: { $0.displayName },
                                onSelect: viewModel.store.setContraceptionContext
                            )
                        }

                        FruitfolioControlPillButton(
                            label: "clear my context"
                        ) {
                            requestClearContext()
                        }
                        .frame(maxWidth: 280, alignment: .leading)
                        .accessibilityIdentifier("myContext.clear")
                        .accessibilityFocused($clearFocused)
                        .accessibilityHint(
                            "Clears context selections without deleting cycle history, Daily Log entries, symptoms, temperatures, notes, or Trends."
                        )

                        FruitfolioFixedText(source: "all of this is optional. clearing or changing context never rewrites what you previously logged.", font: Prompt27AType.small, serious: true)
                            .font(Prompt27AType.small)
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: 620, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 42)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            pendingClearRevision = nil
            returnClearFocus = false
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            if let revision = pendingClearRevision {
                pendingClearRevision = nil
                if !viewModel.store.clearContext(expectedRevision: revision) {
                    returnClearFocus = false
                    failureNoticeFocus = UUID()
                }
            }
            if returnClearFocus { returnClearFocus = false; clearFocused = true }
        }
        .sheet(isPresented: $showPersonalHealthContext) {
            FruitfolioPresentedPopupHost {
                FruitfolioPersonalHealthContextView(store: viewModel.store, onBack: { showPersonalHealthContext = false })
            }
        }
        .sheet(isPresented: $showHormoneInformation) {
            FruitfolioPresentedPopupHost {
                FruitfolioHormoneInformationView(onBack: { showHormoneInformation = false })
            }
        }
        .accessibilityIdentifier("prompt27a.myContext")
    }

    private func requestClearContext() {
        guard canInteractWithContext, let owner = popupOwner else { return }
        let revision = viewModel.store.savedRecordRevision
        returnClearFocus = true
        clearFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "clear all My Context selections and personal health notes from this device? this cannot be undone. cycle history and Daily Log entries will be kept.",
                primaryAction: .init(label: "keep my context") {
                    guard ownerIsActive else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "clear my context") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingClearRevision = revision
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "my-context-clear", deduplicationKey: "my-context-clear-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 3) {
                FruitfolioFixedText(source: "my context", font: Prompt27AType.title, serious: true)
                    .font(Prompt27AType.title)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: -9) {
                    FruitfolioImage(id: .decor_seed)
                        .frame(width: 36, height: 36)

                    FruitfolioImage(id: .decor_sparkles_2)
                        .frame(width: 58, height: 58)
                }
                .offset(y: -2)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

                Spacer(minLength: 0)
            }

            FruitfolioFixedText(source: "tell Fruitfolio anything you’d like it to keep in mind ♡", font: Prompt27AType.body, serious: true)
                .font(Prompt27AType.body)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .fixedSize(horizontal: false, vertical: true)

            FruitfolioFixedText(source: "this is context you choose to report — not something Fruitfolio guesses from your cycle, symptoms, age, or activity.", font: Prompt27AType.small, serious: true)
                .font(Prompt27AType.small)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy.opacity(0.84)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    private var multiChoiceHealthSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("cycle / health context")

            FruitfolioFixedText(source: "choose any that apply — these can overlap", font: Prompt27AType.small, serious: true)
                .font(Prompt27AType.small)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )

            ForEach(
                Prompt27ACycleHealthContext.allCases,
                id: \.self
            ) { value in
                let selected = viewModel.store.context.cycleHealthContexts.contains(value)

                selectionButton(
                    title: value.displayName,
                    selected: selected
                ) {
                    viewModel.store.setCycleHealthContext(
                        value,
                        selected: !selected
                    )
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func singleChoiceSection<Value: Hashable>(
        title: String,
        values: [Value],
        selected: Value,
        label: @escaping (Value) -> String,
        onSelect: @escaping (Value) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title)

            ForEach(values, id: \.self) { value in
                selectionButton(
                    title: label(value),
                    selected: value == selected
                ) {
                    onSelect(value)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {
        FruitfolioFixedText(source: title, font: Prompt27AType.sectionTitle, serious: true)
            .font(Prompt27AType.sectionTitle)
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    private func selectionButton(
        title: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            guard canInteractWithContext else { return }
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            Prompt27ASelectionRow(
                title: title,
                isSelected: selected
            )
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: motionPreferences.reduceMotionActive
            )
        )
        .disabled(viewModel.store.storageProtectionReason != nil)
        // Preserve the translated child label and use the system's localized
        // selection trait instead of overriding it with English-only text.
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct Prompt27AContextCard<Content: View>: View {
    let content: Content

    init(
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                DesignTokens.ColorToken.backgroundCream.opacity(0.78),
                in: RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 22,
                    style: .continuous
                )
                .stroke(
                    DesignTokens.ColorToken.primaryBurgundy.opacity(0.09),
                    lineWidth: 0.8
                )
            }
    }
}

private struct Prompt27ASelectionRow: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(
                isSelected
                    ? "control_radio_selected"
                    : "control_radio_unselected"
            )
            .resizable()
            .scaledToFit()
            .frame(width: 25, height: 25)
            .accessibilityHidden(true)

            FruitfolioFixedText(source: title, font: Prompt27AType.body, serious: true)
                .font(Prompt27AType.body)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .frame(
            maxWidth: .infinity,
            minHeight: DesignTokens.Layout.minimumHitTarget,
            alignment: .leading
        )
    }
}

private enum Prompt27AType {
    static let title = Font.custom(
        "Chalkboard SE",
        size: 26,
        relativeTo: .title2
    ).weight(.bold)

    static let sectionTitle = Font.custom(
        "Chalkboard SE",
        size: 16,
        relativeTo: .headline
    ).weight(.semibold)

    static let body = Font.custom(
        "Chalkboard SE",
        size: 14.5,
        relativeTo: .body
    )

    static let small = Font.custom(
        "Chalkboard SE",
        size: 12.5,
        relativeTo: .subheadline
    )
}

/// Source-cited interpretation remains local to the currently requested view.
struct Prompt27AContextResearchPanel: View {
    let report: Prompt27AContextResearchReport?
    let isLoading: Bool
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FruitfolioFixedText(source: "why you’re seeing this", font: .headline, serious: true)
                .accessibilityAddTraits(.isHeader)
            FruitfolioFixedText(source: "this uses your supplied context and recorded history on this device. research does not change your prediction calculations.", serious: true)
            if isLoading {
                ProgressView { FruitfolioFixedText(source: "looking through the approved Research Library…", serious: true) }
            }
            if let report {
                section("what you reported")
                ForEach(Prompt27AContextResearchPlan.topics(for: report.context)) { topic in
                    VStack(alignment: .leading, spacing: 3) {
                        FruitfolioFixedText(source: topic.reportedTitle, font: .subheadline.bold(), serious: true)
                        FruitfolioFixedText(source: topic.reportedValue, serious: true)
                        if let category = topic.personalCategory,
                           let text = report.context.personalHealthEntries[category.rawValue]?.text {
                            DisclosureGroup {
                                Text(verbatim: text).textSelection(.enabled)
                            } label: { FruitfolioFixedText(source: "review the entry used here", serious: true) }
                        }
                    }
                }
                section("what your logs show")
                if let starts = report.observedFacts.enteredPeriodStartCount {
                    fact("period-start dates you supplied", starts)
                    if !report.observedFacts.recentCompletedCycleLengths.isEmpty {
                        let lengths = report.observedFacts.recentCompletedCycleLengths.map { $0.formatted(.number.grouping(.never).locale(locale)) }
                        FruitfolioFixedText(source: "recent cycle lengths calculated from those starts: \(lengths.joined(separator: ", ")) days",
                            protectedLiterals: lengths, serious: true)
                    }
                } else {
                    FruitfolioFixedText(source: "period-start history could not be read for this explanation. no dates have been filled in.", serious: true)
                }
                if let logs = report.observedFacts.recordedLogCount { fact("saved daily logs", logs) }
                if let bbt = report.observedFacts.recordedBasalTemperatureCount { fact("logs with a recorded basal temperature", bbt) }
                if let fluid = report.observedFacts.recordedCervicalFluidCount { fact("logs with recorded cervical fluid", fluid) }
                FruitfolioFixedText(source: "these describe entries you supplied, not confirmed ovulation, pregnancy, fertility or hormone levels.", serious: true)
                section("what approved research supports")
                FruitfolioFixedText(source: "these are general research excerpts, not proof that a reported condition caused your recorded pattern. not every detail applies to your situation.", serious: true)
                ForEach(report.items) { item in
                    VStack(alignment: .leading, spacing: 10) {
                        FruitfolioFixedText(source: item.topic.reportedTitle, font: .subheadline.bold(), serious: true)
                        if let answer = item.answer {
                            FruitfolioTranslatedText(source: answer.answerText, protectedLiterals: answer.sourceIDs, serious: true)
                            FruitfolioSourceCitationList(sources: answer.sources)
                        } else {
                            FruitfolioFixedText(source: unavailableCopy(item.unavailable), serious: true)
                        }
                    }
                }
                section("what remains unknown")
                FruitfolioFixedText(source: "context and logs alone do not establish a diagnosis, genotype, ovulation event, pregnancy, fertility status, hormone level or a causal relationship. no effect of an unspecified medication is assumed. unsupported details stay unknown; a skipped or removed field is not a negative medical finding.", serious: true)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityIdentifier("cycleTracker.contextResearch")
    }
    private func section(_ title: String) -> some View {
        FruitfolioFixedText(source: title, font: .subheadline.bold(), serious: true).accessibilityAddTraits(.isHeader)
    }
    private func fact(_ label: String, _ value: Int) -> some View {
        let number = value.formatted(.number.grouping(.never).locale(locale))
        return FruitfolioFixedText(source: "\(label): \(number)", protectedLiterals: [number], serious: true)
    }
    private func unavailableCopy(_ reason: Prompt27AContextResearchItem.Unavailable?) -> String {
        switch reason {
        case .contextTooLarge: return "this entry is too large for this local research request and was not sent to the model. you can shorten it in My Context; its original text is still saved."
        case .noBiologicalInference: return "this choice is kept as you reported it. it does not establish a biological state or justify a new prediction calculation."
        case .narrativeNeedsValidatedModel: return "a source-grounded explanation of this entry is not ready. a general category match is not treated as proof about the details you reported."
        case .missingResearch: return "the approved library did not return cited support for this item. no biological effect is inferred from missing support."
        case .requestFailed, nil: return "approved research could not be read for this item. no explanation has been improvised, and your records are unchanged."
        }
    }
}
#endif
