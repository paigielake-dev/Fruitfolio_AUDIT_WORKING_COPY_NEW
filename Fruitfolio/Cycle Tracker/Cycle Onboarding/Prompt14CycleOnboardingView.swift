import SwiftUI

struct Prompt14CycleEntryView: View {
    let store: Prompt14CycleOnboardingStore
    let onBack: () -> Void

    init(
        store: Prompt14CycleOnboardingStore = .shared,
        onBack: @escaping () -> Void
    ) {
        self.store = store
        self.onBack = onBack
    }

    var body: some View {
        Prompt14CycleOnboardingView(store: store, onExit: onBack)
    }
}

struct Prompt14CycleOnboardingView: View {
    @StateObject private var model: Prompt14CycleOnboardingViewModel
    @State private var trackerReady = false
    @State private var showPersonalHealth = false
    @State private var showLeaveAfterSaveFailure = false
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var contextStore: Prompt27AContextStore

    private let onExit: () -> Void
    private let editingStep: Prompt14OnboardingStep?

    init(
        store: Prompt14CycleOnboardingStore = .shared,
        editingStep: Prompt14OnboardingStep? = nil,
        onExit: @escaping () -> Void
    ) {
        _model = StateObject(wrappedValue: Prompt14CycleOnboardingViewModel(store: store))
        self.onExit = onExit
        self.editingStep = editingStep
    }

    var body: some View {
        ZStack {
            Prompt14Palette.paper.ignoresSafeArea()

            if model.isLoading {
                ProgressView()
                    .tint(Prompt14Palette.burgundy)
                    .accessibilityLabel("Loading cycle setup")
            } else if editingStep == nil && (trackerReady || model.draft.isCompleted) {
                Prompt15CycleTrackerView(onBack: onExit)
                    .transition(.opacity)
            } else {
                onboardingContent
            }
        }
        .fullScreenCover(isPresented: $showPersonalHealth) {
            Prompt27APersonalHealthView(store: contextStore) { showPersonalHealth = false }
        }
        .fruitfolioModalBlur(active: showLeaveAfterSaveFailure, reduceMotion: motionPreferences.reduceMotionActive)
        .overlay {
            if showLeaveAfterSaveFailure {
                Prompt12ConfirmationPopup(assetName: "popup_warning", title: "leave without saving these changes?",
                    message: "Fruitfolio couldn’t save the latest changes. previously saved information remains available.",
                    primaryLabel: "keep editing", secondaryLabel: nil, destructiveLabel: "leave without saving",
                    primaryAction: { showLeaveAfterSaveFailure = false }, secondaryAction: nil, destructiveAction: onExit)
            }
        }
        .accessibilityIdentifier("cycle-tracker-entry")
        .task {
            // Shared health context reflects confirmed local persistence, not
            // an optimistic draft whose write might subsequently fail.
            model.onPersistedDraftChange = { [contextStore] saved, previous in
                contextStore.syncFromCycleOnboarding(saved, previous: previous)
            }
            await model.load()
            model.mergeSharedContextIfNeeded(contextStore.context)
            if let editingStep { model.beginEditing(editingStep) }
        }
        .onChange(of: model.draft) { oldDraft, newDraft in
            if let editingStep, oldDraft.step == editingStep, newDraft.step != editingStep {
                Task {
                    await model.waitForPendingSaves()
                    if model.errorMessage == nil { onExit() }
                }
            }
        }
        .animation(
            motionPreferences.reduceMotionActive ? .easeOut(duration: 0.08) : .easeInOut(duration: 0.24),
            value: model.draft.step
        )
    }

    private var onboardingContent: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 22) {
                    if editingStep == nil {
                        Prompt14SeedProgress(step: model.draft.step).padding(.top, 4)
                    } else {
                        Text("edit your cycle setup").font(Prompt14Type.title)
                        Text("changes are saved as you make them. your other answers and daily logs stay in place.")
                            .font(Prompt14Type.helper).multilineTextAlignment(.center)
                    }

                    stepContent
                        .id(model.draft.step)
                        .transition(
                            motionPreferences.reduceMotionActive
                            ? .opacity
                            : .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .trailing)),
                                removal: .opacity.combined(with: .move(edge: .leading))
                            )
                        )

                    FruitfolioControlPillButton(label: "personal health context (optional)", localizationKey: "personal health context (optional)") { showPersonalHealth = true }
                        .accessibilityIdentifier("onboarding.openPersonalHealth")

                    if let error = model.errorMessage {
                        Text(error)
                            .font(Prompt14Type.helper)
                            .foregroundStyle(Prompt14Palette.burgundy)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                            .accessibilityLabel(error)
                    }
                }
                .frame(maxWidth: 560)
                .padding(.horizontal, 22)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var topBar: some View {
        HStack {
            BackControl {
                if editingStep != nil {
                    Task {
                        await model.waitForPendingSaves()
                        if model.errorMessage == nil { onExit() } else { showLeaveAfterSaveFailure = true }
                    }
                } else if !model.goBack() { onExit() }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .frame(minHeight: 54)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch model.draft.step {
        case .intro: intro
        case .latestPeriod: latestPeriod
        case .currentPeriod: currentPeriod
        case .periodEnd: periodEnd
        case .previousHistory: previousHistory
        case .subjectiveRegularity: subjectiveRegularity
        case .cycleAffectingContext: cycleAffectingContext
        case .recentContext: recentContext
        case .trackingPreferences: trackingPreferences
        case .fertilityEstimates: fertilityEstimates
        case .bbtSetup: bbtSetup
        case .cervicalFluidSetup: cervicalFluidSetup
        case .complete: completion
        }
    }

    private var intro: some View {
        VStack(spacing: 18) {
            Text("your cycle, little by little")
                .font(Prompt14Type.title)
                .foregroundStyle(Prompt14Palette.burgundy)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text("you can skip anything you don’t know.")
                .font(Prompt14Type.body)
                .foregroundStyle(Prompt14Palette.burgundy)
                .multilineTextAlignment(.center)

            Prompt14PeachMessage(
                text: "log what you know and we’ll build your little cycle picture ♡"
            )
            .padding(.top, 4)

            WatercolorPrimaryButton(label: "get started", localizationKey: "get started") {
                model.getStarted()
            }
            .frame(maxWidth: 300)
            .padding(.top, 10)
        }
        .padding(.top, 20)
    }

    private var latestPeriod: some View {
        Prompt14QuestionCard(
            title: "when did your latest period begin?",
            helper: "the first day of full menstrual bleeding"
        ) {
            VStack(spacing: 14) {
                Prompt14SpottingInfo()
                Prompt14Calendar(
                    displayedMonth: $model.displayedMonth,
                    selected: model.draft.latestPeriodStart,
                    minimum: nil,
                    maximum: try? Prompt13LocalDate(Date(), calendar: .autoupdatingCurrent),
                    isDateEnabled: { !$0.isFutureRelativeToToday },
                    onSelect: { model.selectLatestPeriod($0) }
                )

                Prompt14SelectionButton(
                    label: "i’m not sure",
                    selected: model.draft.latestPeriodState == .unknown
                ) {
                    model.latestPeriodUnknown()
                }

                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.latestPeriodState == .unanswered)
                    .opacity(model.draft.latestPeriodState == .unanswered ? 0.82 : 1)
            }
        }
    }

    private var currentPeriod: some View {
        Prompt14QuestionCard(title: "is your period still happening?") {
            VStack(spacing: 12) {
                ForEach(Prompt14TriState.allCases, id: \.rawValue) { value in
                    Prompt14SelectionButton(
                        label: value == .yes ? "yes" : value == .no ? "no" : "not sure",
                        selected: model.draft.currentPeriodAnswer == value
                    ) { model.selectCurrentPeriod(value) }
                }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.currentPeriodState == .unanswered)
                    .opacity(model.draft.currentPeriodState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var periodEnd: some View {
        Prompt14QuestionCard(title: "when did it end?") {
            VStack(spacing: 14) {
                Prompt14Calendar(
                    displayedMonth: $model.displayedMonth,
                    selected: model.draft.periodEnd,
                    minimum: model.draft.latestPeriodStart,
                    maximum: try? Prompt13LocalDate(Date(), calendar: .autoupdatingCurrent),
                    isDateEnabled: { local in
                        guard !local.isFutureRelativeToToday else { return false }
                        guard let start = model.draft.latestPeriodStart else { return true }
                        return local >= start
                    },
                    onSelect: { model.selectPeriodEnd($0) }
                )
                Prompt14SelectionButton(
                    label: "i’m not sure",
                    selected: model.draft.periodEndState == .unknown
                ) { model.periodEndUnknown() }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.periodEndState == .unanswered)
                    .opacity(model.draft.periodEndState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var previousHistory: some View {
        Prompt14QuestionCard(title: "do you know when the period before that began?") {
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Prompt14SelectionButton(
                        label: "yes",
                        selected: model.draft.previousHistoryState == .supplied
                    ) { model.setHistoryKnown(true) }
                    Prompt14SelectionButton(
                        label: "no",
                        selected: model.draft.previousHistoryState == .none
                    ) { model.setHistoryKnown(false) }
                }

                if model.draft.previousHistoryState == .supplied {
                    VStack(spacing: 10) {
                        ForEach(model.draft.historicalPeriodStarts, id: \.self) { date in
                            Prompt14HistoryRow(
                                date: date,
                                onEdit: { model.editHistoricalPeriod(date) },
                                onRemove: { model.removeHistoricalPeriod(date) }
                            )
                        }

                        if model.historyPickerVisible {
                            Prompt14Calendar(
                                displayedMonth: $model.displayedMonth,
                                selected: model.historyEditingDate,
                                minimum: nil,
                                maximum: model.draft.latestPeriodStart,
                                isDateEnabled: { model.isValidHistoricalStart($0) },
                                onSelect: { model.addHistoricalPeriod($0) }
                            )
                        }

                        Button("＋ add another past period") {
                            model.historyEditingDate = nil
                            model.historyPickerVisible = true
                        }
                        .font(Prompt14Type.interface)
                        .foregroundStyle(Prompt14Palette.burgundy)
                        .frame(minHeight: 44)
                        .accessibilityLabel("Add another past period")
                    }
                }

                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.previousHistoryState == .unanswered)
                    .opacity(model.draft.previousHistoryState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var subjectiveRegularity: some View {
        Prompt14QuestionCard(title: "how predictable do your cycles usually feel?") {
            VStack(spacing: 11) {
                ForEach(Prompt14SubjectiveRegularity.allCases) { value in
                    Prompt14SelectionButton(
                        label: value.label,
                        selected: model.draft.subjectiveRegularity == value
                    ) { model.chooseRegularity(value) }
                }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.regularityState == .unanswered)
                    .opacity(model.draft.regularityState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var cycleAffectingContext: some View {
        Prompt14QuestionCard(
            title: "are you currently using anything that may affect your cycle?",
            eyebrow: "optional"
        ) {
            VStack(spacing: 11) {
                ForEach(Prompt14CycleAffectingContext.allCases) { value in
                    Prompt14SelectionButton(
                        label: value.label,
                        selected: model.draft.cycleAffectingContexts.contains(value)
                    ) { model.toggleCycleContext(value) }
                }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.cycleContextState == .unanswered)
                    .opacity(model.draft.cycleContextState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var recentContext: some View {
        Prompt14QuestionCard(
            title: "is there anything that may make your recent cycles different?",
            eyebrow: "optional"
        ) {
            VStack(spacing: 11) {
                ForEach(Prompt14RecentContext.allCases) { value in
                    Prompt14SelectionButton(
                        label: value.label,
                        selected: model.draft.recentContexts.contains(value)
                    ) { model.toggleRecentContext(value) }
                }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.recentContextState == .unanswered)
                    .opacity(model.draft.recentContextState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var trackingPreferences: some View {
        Prompt14QuestionCard(
            title: "what would you like Fruitfolio to help you keep track of?",
            helper: "choose as many as you’d like! ♡"
        ) {
            VStack(spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 11) {
                    ForEach(Prompt14TrackingPreference.allCases) { value in
                        Prompt14SelectionButton(
                            label: value.label,
                            selected: model.draft.trackingPreferences.contains(value),
                            compact: true
                        ) { model.toggleTrackingPreference(value) }
                    }
                }
                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.trackingPreferencesState == .unanswered)
                    .opacity(model.draft.trackingPreferencesState == .unanswered ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var fertilityEstimates: some View {
        Prompt14QuestionCard(title: "would you like to see estimated fertile and ovulation windows?") {
            VStack(spacing: 12) {
                Prompt14SelectionButton(
                    label: "yes, show estimates",
                    selected: model.draft.fertilityPreference == .showEstimates
                ) { model.chooseFertilityPreference(.showEstimates) }
                Prompt14SelectionButton(
                    label: "not right now",
                    selected: model.draft.fertilityPreference == .notRightNow
                ) { model.chooseFertilityPreference(.notRightNow) }

                Text("these are estimates based on logged information and aren’t contraception or confirmation of ovulation.")
                    .font(Prompt14Type.helper)
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(0.82))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 2)

                WatercolorPrimaryButton(label: "continue", localizationKey: "continue") { model.advance() }
                    .disabled(model.draft.fertilityPreference == nil)
                    .opacity(model.draft.fertilityPreference == nil ? 0.82 : 1)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var bbtSetup: some View {
        Prompt14QuestionCard(title: "do you track basal body temperature?") {
            VStack(spacing: 12) {
                Image("cycle_bbt_thermometer")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 74, height: 74)
                    .accessibilityHidden(true)

                Prompt14SelectionButton(
                    label: "yes",
                    selected: model.draft.bbtTrackingChoice == .yes
                ) { model.chooseBBTTracking(.yes) }
                Prompt14SelectionButton(
                    label: "i’d like to start",
                    selected: model.draft.bbtTrackingChoice == .wouldLikeToStart
                ) { model.chooseBBTTracking(.wouldLikeToStart) }
                Prompt14SelectionButton(
                    label: "not right now",
                    selected: model.draft.bbtTrackingChoice == .notRightNow
                ) { model.chooseBBTTracking(.notRightNow) }

                if model.draft.bbtTrackingChoice == .yes || model.draft.bbtTrackingChoice == .wouldLikeToStart {
                    Text("which temperature unit do you use?")
                        .font(Prompt14Type.body)
                        .foregroundStyle(Prompt14Palette.burgundy)
                        .padding(.top, 6)

                    HStack(spacing: 12) {
                        ForEach(Prompt14TemperatureUnitPreference.allCases, id: \.rawValue) { unit in
                            Prompt14SelectionButton(
                                label: unit.symbol,
                                selected: model.draft.bbtUnit == unit
                            ) { model.chooseBBTUnit(unit) }
                        }
                    }

                    VStack(spacing: 5) {
                        Text("about what time do you usually measure?")
                            .font(Prompt14Type.body)
                            .foregroundStyle(Prompt14Palette.burgundy)
                        Text("optional")
                            .font(Prompt14Type.helper)
                            .foregroundStyle(Prompt14Palette.burgundy.opacity(0.7))

                        DatePicker(
                            "usual BBT measurement time",
                            selection: Binding(
                                get: { model.selectedBBTTime },
         …20935 tokens truncated…lied."
    },
    {
      "requirementID": "SUP-20261102-04-010",
      "requirement": "Existing user data.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:166",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-011",
      "requirement": "Research notes.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:174",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-012",
      "requirement": "Scientific claims.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:175",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-013",
      "requirement": "Supporting sources.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:176",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-014",
      "requirement": "Citation metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:177",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-015",
      "requirement": "Topic classifications.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:178",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-016",
      "requirement": "Approved educational explanations.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:179",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-017",
      "requirement": "Content revisions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:180",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-018",
      "requirement": "Fruit spawning.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:184",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-019",
      "requirement": "Fruit classification.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:185",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-020",
      "requirement": "Catch detection.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:186",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-021",
      "requirement": "Scoring.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:187",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-022",
      "requirement": "Difficulty mechanics.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:188",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-023",
      "requirement": "Obstacles.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:189",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-024",
      "requirement": "Star passes.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:190",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-025",
      "requirement": "Round completion.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:191",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-026",
      "requirement": "Game-state transitions.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:192",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-027",
      "requirement": "Stable research ID.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:200",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-028",
      "requirement": "Content version.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:201",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-029",
      "requirement": "Topic classification.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:202",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-030",
      "requirement": "Approved scientific content.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:203",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-031",
      "requirement": "Supporting source identifiers.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:204",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-032",
      "requirement": "Citation metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:205",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-033",
      "requirement": "Source publication details.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:206",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-034",
      "requirement": "Revision metadata.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:207",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-035",
      "requirement": "Validation status.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:208",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-20261102-04-036",
      "requirement": "Retirement or supersession status where appropriate.",
      "origin": "New explicit founder addition; supplements original478 without renumbering",
      "sourceReference": "Specification/Founder_Additional_Requirements_2026-11-02.txt:209",
      "acceptanceStatus": "PARTIAL",
      "implementationLocations": [
        "Tools/manage_research_snapshot.py",
        "Delivery/RESEARCH_UPDATE_WORKFLOW.md",
        "Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift"
      ],
      "testsPerformed": [
        "Six offline Python tooling tests; original unchanged5477-note package structural validation."
      ],
      "supportingEvidence": [
        "Fruitfolio_Verification_Evidence/ResearchUpdates/local-tooling-tests.log"
      ],
      "actualResult": "Local build-time publication/archive/rollback tooling implemented and tested; exact requirement-specific iOS update, saved-fact, research-quality and retrieval acceptance remains unverified. No runtime distribution or clinical approval implied."
    },
    {
      "requirementID": "SUP-EDUCATION-STRUCTURE-001",
      "requirement": "Pregnancy and contextual science educational payloads must remain associated with the requested topic and usable source identifiers; malformed or cross-topic payloads must fail closed.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyResearchBridge.swift",
        "Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationViewModel.swift",
        "Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ResearchBridge.swift",
        "Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ScienceViewModel.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/EducationalContentBoundaryTests.swift"
      ],
      "actualResult": "Five XCTest cases added, not executed. Closures and view models reject mismatched content, blank titles/bodies/source identifiers, duplicate source identifiers and invalid section associations. Structural preflight does not verify source approval or scientific accuracy. Default unavailable providers and unconnected action callbacks remain a separate PARTIAL production-integration gap; no clinical content was invented."
    },
    {
      "requirementID": "SUP-CYCLE-SETUP-WRITE-001",
      "requirement": "Cycle setup answers must not report failed writes as saved, expose uncommitted snapshots, or lose later edits through actor reentrancy.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift",
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingViewModel.swift",
        "Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/CycleSetupPersistenceSafetyTests.swift"
      ],
      "actualResult": "Added serialized, cancellation-aware access and rollback of the in-memory draft on failed writes. Five tests exercise write failure, blocked persistence/concurrent edits/snapshots, cancellation, and actual shared-context synchronization only after a successful save. Failed optimistic answers cannot alter shared health context; dismissing an error cannot allow completion of an older draft. Not executed in Xcode. Cross-file reconciliation with Prompt13 remains non-atomic if one persistence layer fails after the other has saved; this change does not claim a two-file transaction."
    },
    {
      "requirementID": "SUP-EXPORT-LIFECYCLE-001",
      "requirement": "Export preparation must not open a destination after navigation away, publish a cancelled/stale document, or mix later MainActor health/game edits into an already captured snapshot.",
      "acceptanceStatus": "IMPLEMENTED \u2014 VERIFICATION PENDING",
      "relevantSourceFiles": [
        "Fruitfolio/Privacy Settings/FruitfolioExportPreparation.swift",
        "Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift",
        "Fruitfolio/Privacy Settings/FruitfolioPersonalDataExport.swift"
      ],
      "supportingEvidence": [
        "FruitfolioTests/ExportPreparationLifecycleTests.swift",
        "FruitfolioTests/ExportSnapshotConsistencyTests.swift"
      ],
      "actualResult": "Added cancellable request-owned preparation; Back/real disappearance cancels preparation, while native Files presentation remains intact. Late cancelled results cannot replace the active document. MainActor domain values are copied before awaiting cycle/setup snapshots. Four new tests cover cancellation, replacement, error and a deliberately blocked cycle-file read with later health/game edits. Not executed on Mac. Existing saved-file byte verification and Cancel/no-success behavior are unchanged.",
      "limitations": "This freezes MainActor data at request time; separately actor-owned cycle/setup snapshots are still individually read and are not a cross-file database transaction."
    }
  ],
  "additional20261102": {
    "source": "Specification/Founder_Additional_Requirements_2026-11-02.txt",
    "uniqueChecklistItemsAdded": 72,
    "countsByWorkstream": {
      "1": 10,
      "2": 18,
      "3": 8,
      "4": 36
    },
    "pendingNarrativeRequirementsAlsoBinding": true
  }
}
