#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI

@MainActor
struct Prompt27AMyContextView: View {
    @StateObject private var viewModel: Prompt27AContextViewModel
    @ObservedObject private var observedStore: Prompt27AContextStore
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
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

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    BackControl {
                        onBack()
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        FruitfolioContextStorageNotice(store: viewModel.store, messageFocusRequest: failureNoticeFocus)
                        WatercolorPrimaryButton(label: "optional personal health context") { showPersonalHealthContext = true }
                        WatercolorPrimaryButton(label: "Hormone Information") {
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
        guard viewIsVisible, let owner = popupOwner else { return }
        let revision = viewModel.store.savedRecordRevision
        returnClearFocus = true
        clearFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "clear all My Context selections and personal health notes from this device? this cannot be undone. cycle history and Daily Log entries will be kept.",
                primaryAction: .init(label: "keep my context") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "clear my context") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
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
#endif
