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
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var contextStore: Prompt27AContextStore

    private let onExit: () -> Void

    init(
        store: Prompt14CycleOnboardingStore = .shared,
        onExit: @escaping () -> Void
    ) {
        _model = StateObject(wrappedValue: Prompt14CycleOnboardingViewModel(store: store))
        self.onExit = onExit
    }

    var body: some View {
        ZStack {
            Prompt14Palette.paper.ignoresSafeArea()

            if model.isLoading {
                ProgressView()
                    .tint(Prompt14Palette.burgundy)
                    .accessibilityLabel("Loading cycle setup")
            } else if trackerReady || model.draft.isCompleted {
                Prompt15CycleTrackerView(onBack: onExit)
                    .transition(.opacity)
            } else {
                onboardingContent
            }
        }
        .task {
            await model.load()
            model.mergeSharedContextIfNeeded(contextStore.context)
            contextStore.syncFromCycleOnboarding(model.draft)
        }
        .onChange(of: model.draft) { _, newDraft in
            contextStore.syncFromCycleOnboarding(newDraft)
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
                    Prompt14SeedProgress(step: model.draft.step)
                        .padding(.top, 4)

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
                if !model.goBack() { onExit() }
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

            WatercolorPrimaryButton(label: "get started") {
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

                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.latestPeriodState == .unanswered)
                    .opacity(model.draft.latestPeriodState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.currentPeriodState == .unanswered)
                    .opacity(model.draft.currentPeriodState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.periodEndState == .unanswered)
                    .opacity(model.draft.periodEndState == .unanswered ? 0.5 : 1)
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

                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.previousHistoryState == .unanswered)
                    .opacity(model.draft.previousHistoryState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.regularityState == .unanswered)
                    .opacity(model.draft.regularityState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.cycleContextState == .unanswered)
                    .opacity(model.draft.cycleContextState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.recentContextState == .unanswered)
                    .opacity(model.draft.recentContextState == .unanswered ? 0.5 : 1)
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
                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.trackingPreferencesState == .unanswered)
                    .opacity(model.draft.trackingPreferencesState == .unanswered ? 0.5 : 1)
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

                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(model.draft.fertilityPreference == nil)
                    .opacity(model.draft.fertilityPreference == nil ? 0.5 : 1)
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
                                set: { model.setBBTTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(Prompt14Palette.burgundy)

                        Button("skip") { model.setBBTTime(nil) }
                            .font(Prompt14Type.interface)
                            .foregroundStyle(Prompt14Palette.burgundy)
                            .frame(minHeight: 44)
                    }
                    .padding(.top, 4)

                    Prompt14BBTInfo()
                }

                WatercolorPrimaryButton(label: "continue") { model.advance() }
                    .disabled(!bbtCanContinue)
                    .opacity(bbtCanContinue ? 1 : 0.5)
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var bbtCanContinue: Bool {
        guard let choice = model.draft.bbtTrackingChoice else { return false }
        if choice == .notRightNow || choice == .skipped { return true }
        return model.draft.bbtUnit != nil
    }

    private var cervicalFluidSetup: some View {
        Prompt14QuestionCard(title: "you can optionally log cervical-fluid observations too ✿") {
            VStack(spacing: 16) {
                Image("symptom_cervical_fluid")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 78, height: 78)
                    .accessibilityHidden(true)

                Text("Fruitfolio records what you observe so you can look back at how it changes over time.")
                    .font(Prompt14Type.body)
                    .foregroundStyle(Prompt14Palette.burgundy)
                    .multilineTextAlignment(.center)

                WatercolorPrimaryButton(label: "got it ♡") {
                    model.acknowledgeCervicalFluid()
                }
                Prompt14SkipButton { model.skipCurrentStep() }
            }
        }
    }

    private var completion: some View {
        VStack(spacing: 18) {
            Prompt14SproutCompletionArt()

            Prompt14PeachMessage(
                text: "all set! Fruitfolio will start with what you know and adjust as you log more. ♡"
            )

            WatercolorPrimaryButton(label: "open my cycle tracker") {
                Task {
                    if await model.finish() {
                        withAnimation(motionPreferences.reduceMotionActive ? .easeOut(duration: 0.08) : .easeInOut(duration: 0.24)) {
                            trackerReady = true
                        }
                    }
                }
            }
            .frame(maxWidth: 320)
        }
        .padding(.top, 22)
    }
}

private struct Prompt14ReadyState: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                BackControl(action: onBack)
                Spacer()
            }

            Spacer(minLength: 32)

            Image("decor_sprout")
                .resizable()
                .scaledToFit()
                .frame(width: 86, height: 86)
                .accessibilityHidden(true)

            Text("your cycle picture is ready ♡")
                .font(Prompt14Type.title)
                .foregroundStyle(Prompt14Palette.burgundy)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Prompt14PeachMessage(
                text: "start wherever you are! :-) your little cycle picture will fill in as you log."
            )

            Text("your setup is saved locally. the tracker can build from what you actually supplied without filling in missing pieces.")
                .font(Prompt14Type.body)
                .foregroundStyle(Prompt14Palette.burgundy.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 18)

            Spacer()
        }
        .frame(maxWidth: 560)
        .padding(.horizontal, 22)
        .padding(.top, 8)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
    }
}

private struct Prompt14QuestionCard<Content: View>: View {
    let title: String
    var helper: String? = nil
    var eyebrow: String? = nil
    @ViewBuilder let content: Content

    init(
        title: String,
        helper: String? = nil,
        eyebrow: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.helper = helper
        self.eyebrow = eyebrow
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 16) {
            if let eyebrow {
                Text(eyebrow)
                    .font(Prompt14Type.helper)
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(0.72))
            }

            Text(title)
                .font(Prompt14Type.question)
                .foregroundStyle(Prompt14Palette.burgundy)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            if let helper {
                Text(helper)
                    .font(Prompt14Type.helper)
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(0.76))
                    .multilineTextAlignment(.center)
            }

            content
        }
        .padding(.top, 4)
    }
}

private struct Prompt14SelectionButton: View {
    let label: String
    let selected: Bool
    var compact: Bool = false
    let action: () -> Void

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            HStack(spacing: 9) {
                Text(label)
                    .font(Prompt14Type.interface)
                    .foregroundStyle(Prompt14Palette.burgundy)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if selected {
                    Image("control_check")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 10 : 12)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? Prompt14Palette.peachWash : Prompt14Palette.creamWash)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Prompt14Palette.burgundy.opacity(selected ? 0.72 : 0.24), lineWidth: selected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
        .accessibilityLabel(label)
        .accessibilityValue(selected ? "selected" : "not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private struct Prompt14SkipButton: View {
    let action: () -> Void

    var body: some View {
        Button("skip") { action() }
            .font(Prompt14Type.interface)
            .foregroundStyle(Prompt14Palette.burgundy.opacity(0.82))
            .frame(minWidth: 88, minHeight: 44)
            .accessibilityHint("Leaves this answer unknown")
    }
}

private struct Prompt14PeachMessage: View {
    let text: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image("fruit_peach_soft")
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 68)
                .accessibilityLabel("Peach")

            Text(text)
                .font(Prompt14Type.body)
                .foregroundStyle(Prompt14Palette.burgundy)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Prompt14Palette.creamWash.opacity(0.92))
                )
        }
        .frame(maxWidth: 420)
        .accessibilityElement(children: .combine)
    }
}

private struct Prompt14SeedProgress: View {
    let step: Prompt14OnboardingStep

    private var progress: Double {
        let ordered: [Prompt14OnboardingStep] = [
            .intro, .latestPeriod, .currentPeriod, .periodEnd, .previousHistory,
            .subjectiveRegularity, .cycleAffectingContext, .recentContext,
            .trackingPreferences, .fertilityEstimates, .bbtSetup,
            .cervicalFluidSetup, .complete
        ]
        guard let index = ordered.firstIndex(of: step) else { return 0 }
        return Double(index) / Double(max(ordered.count - 1, 1))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("decor_seed")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .opacity(step == .complete ? 0 : 1)
                .scaleEffect(0.9 + progress * 0.12)

            if progress > 0.44 && step != .complete {
                Capsule()
                    .fill(Prompt14Palette.sage.opacity(0.55))
                    .frame(width: 3, height: 7 + (progress * 8))
                    .offset(y: -22)
                    .accessibilityHidden(true)
            }

            if step == .complete {
                Image("decor_sprout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 46, height: 46)
            }
        }
        .frame(height: 50)
        .accessibilityHidden(true)
    }
}

private struct Prompt14SproutCompletionArt: View {
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @State private var revealed = false

    var body: some View {
        ZStack {
            Image("decor_seed")
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)
                .opacity(revealed ? 0 : 1)

            Image("decor_sprout")
                .resizable()
                .scaledToFit()
                .frame(width: 92, height: 92)
                .opacity(revealed ? 1 : 0)
                .scaleEffect(revealed ? 1 : 0.74)

            if revealed {
                Text("✦")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(0.7))
                    .offset(x: 45, y: -38)
                    .accessibilityHidden(true)
            }
        }
        .frame(height: 104)
        .accessibilityLabel("Watercolor seed growing into a sprout")
        .onAppear {
            if motionPreferences.reduceMotionActive {
                withAnimation(.easeOut(duration: 0.18)) { revealed = true }
            } else {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.78)) { revealed = true }
            }
        }
    }
}

private struct Prompt14SpottingInfo: View {
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                expanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .accessibilityHidden(true)
                    Text("spotting info")
                }
                .font(Prompt14Type.helper)
                .foregroundStyle(Prompt14Palette.burgundy)
                .frame(minHeight: 44)
            }
            .accessibilityLabel("Spotting information")

            if expanded {
                Text("spotting is lighter bleeding that can happen outside your full menstrual flow. for cycle tracking, choose the first day your full menstrual bleeding began — not light spotting.")
                    .font(Prompt14Type.helper)
                    .foregroundStyle(Prompt14Palette.burgundy)
                    .multilineTextAlignment(.center)
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Prompt14Palette.creamWash)
                    )
                    .transition(.opacity)
            }
        }
    }
}

private struct Prompt14BBTInfo: View {
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 6) {
            Button("BBT info") { expanded.toggle() }
                .font(Prompt14Type.helper)
                .foregroundStyle(Prompt14Palette.burgundy)
                .frame(minHeight: 44)
                .accessibilityLabel("Basal body temperature information")
            if expanded {
                Text("BBT is usually measured after your longest stretch of sleep and before getting up or becoming active.")
                    .font(Prompt14Type.helper)
                    .foregroundStyle(Prompt14Palette.burgundy)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Prompt14Palette.creamWash))
            }
        }
    }
}

private struct Prompt14HistoryRow: View {
    let date: Prompt13LocalDate
    let onEdit: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(Prompt14DateFormatting.long(date))
                .font(Prompt14Type.interface)
                .foregroundStyle(Prompt14Palette.burgundy)
            Spacer()
            Button("edit", action: onEdit)
                .font(Prompt14Type.helper)
                .foregroundStyle(Prompt14Palette.burgundy)
                .frame(minWidth: 44, minHeight: 44)
            Button("remove", action: onRemove)
                .font(Prompt14Type.helper)
                .foregroundStyle(Prompt14Palette.burgundy)
                .frame(minWidth: 56, minHeight: 44)
        }
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Prompt14Palette.creamWash.opacity(0.75))
        )
    }
}

struct Prompt14Calendar: View {
    @Binding var displayedMonth: Date
    let selected: Prompt13LocalDate?
    let minimum: Prompt13LocalDate?
    let maximum: Prompt13LocalDate?
    let isDateEnabled: (Prompt13LocalDate) -> Bool
    let onSelect: (Date) -> Void

    private let calendar = Calendar.autoupdatingCurrent
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    init(
        displayedMonth: Binding<Date>,
        selected: Prompt13LocalDate?,
        minimum: Prompt13LocalDate?,
        maximum: Prompt13LocalDate?,
        isDateEnabled: @escaping (Prompt13LocalDate) -> Bool,
        onSelect: @escaping (Date) -> Void
    ) {
        _displayedMonth = displayedMonth
        self.selected = selected
        self.minimum = minimum
        self.maximum = maximum
        self.isDateEnabled = isDateEnabled
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button { changeMonth(-1) } label: {
                    Image("control_previous")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Previous month")

                Spacer()

                Text(monthTitle)
                    .font(Prompt14Type.interface)
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(0.82))

                Spacer()

                Button { changeMonth(1) } label: {
                    Image("control_next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Next month")
                .disabled(!canMoveForward)
                .opacity(canMoveForward ? 1 : 0.34)
            }

            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(Prompt14Type.calendarWeekday)
                        .foregroundStyle(Prompt14Palette.burgundy.opacity(0.62))
                        .frame(maxWidth: .infinity)
                }

                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, value in
                    if let value {
                        Prompt14CalendarDay(
                            value: value,
                            selected: selected == value.local,
                            enabled: isEnabled(value.local)
                        ) {
                            onSelect(value.date)
                        }
                    } else {
                        Color.clear.frame(height: 42)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Prompt14Palette.calendarPaper)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Prompt14Palette.burgundy.opacity(0.13), lineWidth: 1)
                )
        )
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth).lowercased()
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = max(0, calendar.firstWeekday - 1)
        return (Array(symbols[first...]) + Array(symbols[..<first])).map { $0.lowercased() }
    }

    fileprivate struct CellValue {
        let date: Date
        let local: Prompt13LocalDate
        let day: Int
    }

    private var monthCells: [CellValue?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth) else { return [] }
        let first = monthInterval.start
        let weekday = calendar.component(.weekday, from: first)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        var cells: [CellValue?] = Array(repeating: nil, count: offset)
        for day in dayRange {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: first),
                  let local = try? Prompt13LocalDate(date, calendar: calendar) else { continue }
            cells.append(CellValue(date: date, local: local, day: day))
        }
        return cells
    }

    private func isEnabled(_ local: Prompt13LocalDate) -> Bool {
        if let minimum, local < minimum { return false }
        if let maximum, local > maximum { return false }
        return isDateEnabled(local)
    }

    private var canMoveForward: Bool {
        guard let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) else { return false }
        let currentMonth = calendar.dateComponents([.year, .month], from: Date())
        let nextMonth = calendar.dateComponents([.year, .month], from: next)
        guard let cy = currentMonth.year, let cm = currentMonth.month,
              let ny = nextMonth.year, let nm = nextMonth.month else { return true }
        return (ny, nm) <= (cy, cm)
    }

    private func changeMonth(_ delta: Int) {
        if let value = calendar.date(byAdding: .month, value: delta, to: displayedMonth) {
            displayedMonth = value
        }
    }
}

private struct Prompt14CalendarDay: View {
    let value: Prompt14Calendar.CellValue
    let selected: Bool
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if selected {
                    Image("cycle_day_circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .accessibilityHidden(true)
                }
                Text("\(value.day)")
                    .font(Prompt14Type.calendarDay)
                    .foregroundStyle(Prompt14Palette.burgundy.opacity(enabled ? 1 : 0.32))
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(Prompt14DateFormatting.long(value.local))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

private enum Prompt14DateFormatting {
    static func long(_ date: Prompt13LocalDate) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = date.year
        components.month = date.month
        components.day = date.day
        components.hour = 12
        guard let value = calendar.date(from: components) else { return date.description }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .long
        return formatter.string(from: value).lowercased()
    }
}

private extension Prompt13LocalDate {
    var isFutureRelativeToToday: Bool {
        guard let today = try? Prompt13LocalDate(Date(), calendar: .autoupdatingCurrent) else { return false }
        return self > today
    }
}

private enum Prompt14Palette {
    static let burgundy = DesignTokens.ColorToken.primaryBurgundy
    static let paper = Color(red: 0.986, green: 0.956, blue: 0.887)
    static let calendarPaper = Color(red: 0.995, green: 0.975, blue: 0.925)
    static let creamWash = Color(red: 0.995, green: 0.968, blue: 0.900)
    static let peachWash = Color(red: 0.965, green: 0.793, blue: 0.718).opacity(0.52)
    static let sage = Color(red: 0.51, green: 0.60, blue: 0.43)
}

private enum Prompt14Type {
    static let title = Font.custom("Chalkboard SE", size: 30, relativeTo: .largeTitle).weight(.semibold)
    static let question = Font.custom("Chalkboard SE", size: 22, relativeTo: .title2).weight(.semibold)
    static let body = Font.custom("Chalkboard SE", size: 16, relativeTo: .body)
    static let helper = Font.custom("Chalkboard SE", size: 13, relativeTo: .footnote)
    static let interface = Font.custom("Chalkboard SE", size: 15, relativeTo: .body).weight(.medium)
    static let calendarDay = Font.custom("Chalkboard SE", size: 14, relativeTo: .body)
    static let calendarWeekday = Font.custom("Chalkboard SE", size: 11, relativeTo: .caption)
}
