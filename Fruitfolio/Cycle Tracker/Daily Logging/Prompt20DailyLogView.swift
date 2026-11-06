import SwiftUI
import UIKit

public struct Prompt20DailyLogView: View {
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.locale) private var appLocale
    @Environment(\.scenePhase) private var scenePhase
    private var ownerIsActive: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
    }
    private var canInteract: Bool { ownerIsActive && popupCoordinator.currentPopup == nil }

    @StateObject private var model: Prompt20DailyLogViewModel
    @State private var showCervicalInfo = false
    @State private var showSavedMessage = false
    private enum ConfirmationAction {
        case saveAndClose, discardAndClose
        case removeMedication(Prompt20MedicationEntry)
    }
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var pendingConfirmationAction: ConfirmationAction?
    @State private var viewIsVisible = false
    @State private var popupInstanceID = UUID()
    @State private var confirmationMessage: String?
    @AccessibilityFocusState private var closeFocused: Bool
    @AccessibilityFocusState private var medicationFocused: UUID?
    @State private var returnMedicationFocus: UUID?
    @State private var returnFocusAfterConfirmation = false
    @State private var savedMessageTask: Task<Void, Never>?
    @State private var repositoryTask: Task<Void, Never>?

    private let onSaved: (Prompt20DailyLog?) -> Void
    private let onDirtyStateChange: (Bool) -> Void

    public init(
        ownerID: Prompt20DailyLogOwnerID = .localDevice,
        selectedDate: Date,
        repository: any Prompt20DailyLogRepository = Prompt20CycleDailyLogStore.shared,
        calendar: Calendar = .current,
        preferredTemperatureUnit: Prompt20TemperatureUnit = .fahrenheit,
        initialExpandedSection: Prompt20DailyLogSection? = nil,
        onSaved: @escaping (Prompt20DailyLog?) -> Void = { _ in },
        onDirtyStateChange: @escaping (Bool) -> Void = { _ in }
    ) {
        _model = StateObject(
            wrappedValue: Prompt20DailyLogViewModel(
                ownerID: ownerID,
                selectedDate: selectedDate,
                repository: repository,
                calendar: calendar,
                preferredTemperatureUnit: preferredTemperatureUnit,
                initialExpandedSection: initialExpandedSection
            )
        )
        self.onSaved = onSaved
        self.onDirtyStateChange = onDirtyStateChange
    }

    public var body: some View {
        ZStack {
            Prompt20Palette.paper
                .ignoresSafeArea()

            Group {
                if model.isFutureDate {
                    futureDateView
                } else {
                    journal
                }
            }

        }
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .task { await model.load() }
        .allowsHitTesting(canInteract)
        .accessibilityHidden(popupCoordinator.currentPopup != nil)
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, returnFocusAfterConfirmation,
                  popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            let action = pendingConfirmationAction
            pendingConfirmationAction = nil
            switch action {
            case .saveAndClose:
                repositoryTask = Task { @MainActor in
                    guard !Task.isCancelled, viewIsVisible else { return }
                    let saved = await model.save()
                    guard saved, !Task.isCancelled, viewIsVisible else { return }
                    onSaved(model.existingLog)
                    if !model.hasUnsavedChanges { dismiss() }
                }
            case .discardAndClose: dismiss()
            case .removeMedication(let expected):
                if !model.removeMedication(ifUnchanged: expected) {
                    confirmationMessage = "that entry changed while confirmation was open. your current entry is still here."
                }
            case nil: break
            }
            if let id = returnMedicationFocus, model.draft.medications.contains(where: { $0.id == id }) {
                medicationFocused = id
            } else { closeFocused = true }
            returnMedicationFocus = nil
            returnFocusAfterConfirmation = false
        }
        .onChange(of: model.draft) { _, _ in confirmationMessage = nil }
        .onChange(of: model.hasUnsavedChanges) { _, newValue in
            onDirtyStateChange(newValue)
        }
        .interactiveDismissDisabled(model.hasUnsavedChanges || model.saveState == .saving)
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            pendingConfirmationAction = nil
            returnFocusAfterConfirmation = false
            savedMessageTask?.cancel()
            repositoryTask?.cancel()
        }
        .accessibilityIdentifier("prompt20.dailyLog")
    }

    private var journal: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if model.loadState == .loading {
                    loadingView
                } else if model.loadState == .failed {
                    loadFailureView
                } else {
                    section(.bleeding) { bleedingContent }
                    section(.symptoms) { symptomsContent }
                    section(.temperature) { temperatureContent }
                    section(.cervicalFluid) { cervicalFluidContent }
                    section(.medication) { medicationContent }
                    section(.notes) { notesContent }

                    validationMessages
                    if let confirmationMessage {
                        FruitfolioTranslatedText(source: confirmationMessage, font: Prompt20Type.body,
                            color: Prompt20Palette.burgundy, serious: true)
                    }
                    saveArea
                }
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.top, 24)
            .padding(.bottom, 38)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("dailyLog.scroll")
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                FruitfolioFixedText(source: "daily log", font: Prompt20Type.title, serious: true)
                    .font(Prompt20Type.title)
                    .foregroundStyle(Prompt20Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Text(displayDate)
                    .font(Prompt20Type.date)
                    .foregroundStyle(Prompt20Palette.coral)

                FruitfolioFixedText(source: "notice something today? jot it down here ♡", font: Prompt20Type.body, serious: true)
                    .font(Prompt20Type.body)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.68))
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            CloseControl(action: requestClose)
                .accessibilityFocused($closeFocused)
                .accessibilityIdentifier("dailyLog.close")
                .disabled(model.saveState == .saving)
        }
    }

    private var displayDate: String {
        model.selectedDay.localizedDisplay(locale: appLocale, calendar: model.calendar)
    }

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image("decor_leaves")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                FruitfolioFixedText(source: "opening your day…", font: Prompt20Type.body, serious: true)
                    .font(Prompt20Type.body)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.58))
            }
            .padding(.bottom, 2)

            ForEach(Prompt20DailyLogSection.allCases) { section in
                HStack(spacing: 12) {
                    Image(section.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)

                    Text(section.title)
                        .font(Prompt20Type.sectionTitle)
                        .foregroundStyle(Prompt20Palette.burgundy.opacity(0.52))

                    Spacer(minLength: 8)

                    Image("control_next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .opacity(0.45)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 58)
                .background {
                    Prompt20JournalSectionShape(variant: section.rawValue.count + 40)
                        .fill(Prompt20Palette.paper.opacity(0.01))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("loading daily log")
    }

    private var loadFailureView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image("fruit_peach_soft")
                .resizable()
                .scaledToFit()
                .frame(width: 44)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 7) {
                FruitfolioTranslatedText(source: model.loadFailureMessage ?? "couldn’t open that day just yet. nothing was changed.",
                    font: Prompt20Type.body, color: Prompt20Palette.burgundy.opacity(0.72), serious: true)
                    .fixedSize(horizontal: false, vertical: true)

                FruitfolioControlPillButton(label: "try again") {
                    repositoryTask?.cancel()
                    repositoryTask = Task { @MainActor in await model.retryLoad() }
                }
                .controlSize(.small)
                .accessibilityIdentifier("dailyLog.retryLoad")
            }
        }
        .padding(14)
        .background {
            Prompt20JournalSectionShape(variant: 104)
                .fill(Prompt20Palette.peach.opacity(0.10))
        }
    }

    private func section<Content: View>(
        _ section: Prompt20DailyLogSection,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let expanded = model.expandedSections.contains(section)
        let summary = section.summary(in: model.draft)

        return VStack(spacing: 0) {
            Button {
                audioManager.play(.buttonSoftPop)
                withAnimation(
                    motionPreferences.reduceMotionActive
                        ? .easeOut(duration: 0.08)
                        : .easeOut(duration: 0.21)
                ) {
                    model.toggle(section)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(section.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 34, height: 34)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.title)
                            .font(Prompt20Type.sectionTitle)
                            .foregroundStyle(Prompt20Palette.burgundy)

                        if let summary, !expanded {
                            Text(summary)
                                .font(Prompt20Type.summary)
                                .foregroundStyle(Prompt20Palette.burgundy.opacity(0.58))
                                .lineLimit(2)
                        }
                    }

                    Spacer(minLength: 8)

                    Image("control_next")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 58)
                .contentShape(Rectangle())
            }
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            )
            .accessibilityLabel(section.title)
            .accessibilityValue(expanded ? "expanded" : "collapsed")
            .accessibilityHint("double tap to \(expanded ? "collapse" : "expand")")

            if expanded {
                content()
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .padding(.bottom, 16)
                    .transition(
                        motionPreferences.reduceMotionActive
                            ? .opacity
                            : .opacity.combined(with: .move(edge: .top))
                    )
            }
        }
        .background {
            Prompt20JournalSectionShape(variant: section.hashValue)
                .fill(Prompt20Palette.paper.opacity(0.78))
                .overlay {
                    Prompt20JournalSectionShape(variant: section.hashValue)
                        .stroke(Prompt20Palette.coral.opacity(0.12), lineWidth: 0.8)
                }
        }
    }

    private var bleedingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("period")

            Prompt20AdaptiveChips {
                ForEach(Prompt20PeriodEvent.allCases) { event in
                    choiceChip(
                        event.displayName,
                        selected: model.draft.periodEvent == event
                    ) {
                        model.mutateDraft { draft in
                            draft.periodEvent =
                                draft.periodEvent == event
                                    ? nil
                                    : event
                        }
                    }
                }
            }

            Text("period start + end are separate from bleeding, so spotting or other bleeding won’t automatically become a new cycle.")
                .font(Prompt20Type.micro)
                .foregroundStyle(
                    Prompt20Palette.burgundy.opacity(0.62)
                )
                .fixedSize(horizontal: false, vertical: true)

            prompt("bleeding today?")

            Prompt20AdaptiveChips {
                ForEach(Prompt20BleedingLevel.allCases) { level in
                    choiceChip(
                        level.displayName,
                        selected: model.draft.bleedingLevel == level
                    ) {
                        model.mutateDraft { draft in
                            draft.bleedingLevel = draft.bleedingLevel == level ? nil : level
                        }
                    }
                }
            }

            notePrompt("anything you want to remember?")
            journalTextEditor(
                text: binding(\.bleedingNote),
                placeholder: "add a little note…",
                minHeight: 74
            )
        }
    }

    private var symptomsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            prompt("how are you feeling?")

            ForEach(Prompt20SymptomGroup.allCases) { group in
                let symptoms = Prompt20SymptomID.allCases.filter { $0.group == group }

                VStack(alignment: .leading, spacing: 8) {
                    Text(group.displayName)
                        .font(Prompt20Type.groupLabel)
                        .foregroundStyle(Prompt20Palette.burgundy.opacity(0.58))

                    Prompt20AdaptiveChips {
                        ForEach(symptoms) { symptom in
                            choiceChip(
                                symptom.displayName,
                                selected: model.draft.selectedSymptoms.contains(symptom)
                            ) {
                                model.toggleSymptom(symptom)
                            }
                        }
                    }
                }
            }

            notePrompt("anything else?")
            journalTextEditor(
                text: binding(\.symptomNote),
                placeholder: "add a little detail…",
                minHeight: 74
            )
        }
    }

    private var temperatureContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("temperature today")

            HStack(spacing: 10) {
                TextField(
                    "97.8",
                    text: binding(\.temperatureText)
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .font(Prompt20Type.input)
                .foregroundStyle(Prompt20Palette.burgundy)
                .padding(.horizontal, 13)
                .frame(minHeight: 46)
                .background(inputBackground)
                .accessibilityLabel("temperature")

                Prompt20AdaptiveChips {
                    ForEach(Prompt20TemperatureUnit.allCases) { unit in
                        choiceChip(
                            unit.symbol,
                            selected: model.draft.temperatureUnit == unit
                        ) {
                            model.changeTemperatureUnit(to: unit)
                        }
                    }
                }
                .frame(maxWidth: 142)
            }

            notePrompt("enter the number and unit shown on your thermometer. choosing a unit keeps the number you typed.")

            notePrompt("what kind of reading?")
            Prompt20AdaptiveChips {
                ForEach(Prompt20TemperatureReadingType.allCases) { kind in
                    choiceChip(
                        kind.displayName,
                        selected: model.draft.temperatureReadingType == kind
                    ) {
                        model.mutateDraft { draft in
                            draft.temperatureReadingType =
                                draft.temperatureReadingType == kind ? nil : kind
                        }
                    }
                }
            }

            notePrompt("anything that might have affected it?")
            journalTextEditor(
                text: binding(\.temperatureNote),
                placeholder: "sleep, illness, different wake time…",
                minHeight: 74
            )
        }
    }

    private var cervicalFluidContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                prompt("what did you notice?")

                FruitfolioControlPillButton(label: "info") {
                    showCervicalInfo.toggle()
                }
                .controlSize(.small)
                .accessibilityHint("explains cervical fluid categories")
            }

            if showCervicalInfo {
                HStack(alignment: .top, spacing: 9) {
                    Image("fruit_blueberry_friendly")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38)
                        .accessibilityHidden(true)

                    Text("cervical fluid can vary, and it can be hard to categorize sometimes. one observation does not prove fertility or ovulation.")
                        .font(Prompt20Type.micro)
                        .foregroundStyle(Prompt20Palette.burgundy.opacity(0.72))
                }
                .padding(12)
                .background(
                    Prompt20JournalSectionShape(variant: 95)
                        .fill(Prompt20Palette.dustyBlue.opacity(0.10))
                )
                .transition(.opacity)
            }

            Prompt20AdaptiveChips {
                ForEach(Prompt20CervicalFluidCategory.allCases) { category in
                    choiceChip(
                        category.displayName,
                        selected: model.draft.cervicalFluidCategory == category
                    ) {
                        model.mutateDraft { draft in
                            draft.cervicalFluidCategory =
                                draft.cervicalFluidCategory == category ? nil : category
                        }
                    }
                }
            }

            notePrompt("anything else you noticed?")
            journalTextEditor(
                text: binding(\.cervicalFluidNote),
                placeholder: "add a little note…",
                minHeight: 74
            )
        }
    }

    private var medicationContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("medication or supplements today?")

            if model.draft.medications.isEmpty {
                Text("add an entry only if there’s something you want to remember.")
                    .font(Prompt20Type.micro)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.58))
            }

            ForEach(model.draft.medications) { medication in
                Prompt20MedicationRow(
                    medication: medication,
                    removeFocus: $medicationFocused,
                    validationMessage: medicationValidationMessage(for: medication.id),
                    onChange: { changed in
                        model.updateMedication(id: medication.id) { entry in
                            entry = changed
                        }
                    },
                    onRemove: { requestMedicationRemoval(medication) }
                )
                .transition(
                    motionPreferences.reduceMotionActive
                        ? .opacity
                        : .opacity.combined(with: .move(edge: .top))
                )
            }

            Button {
                audioManager.play(.buttonSoftPop)
                withAnimation(
                    motionPreferences.reduceMotionActive
                        ? .easeOut(duration: 0.08)
                        : .easeOut(duration: 0.20)
                ) {
                    model.addMedication()
                }
            } label: {
                HStack(spacing: 7) {
                    Image("control_plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 21, height: 21)
                        .accessibilityHidden(true)

                    Text("add another")
                        .font(Prompt20Type.button)
                        .foregroundStyle(Prompt20Palette.burgundy)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            )
        }
    }

    private var notesContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            prompt("anything else on your mind?")

            journalTextEditor(
                text: binding(\.generalNote),
                placeholder: "write anything you want to remember about today…",
                minHeight: 150,
                identifier: "dailyLog.notes"
            )
        }
    }

    @ViewBuilder
    private var validationMessages: some View {
        if !model.validationIssues.isEmpty {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(Array(model.validationIssues.enumerated()), id: \.offset) { _, issue in
                    Text(model.validationMessage(for: issue))
                        .font(Prompt20Type.micro)
                        .foregroundStyle(Prompt20Palette.burgundy.opacity(0.72))
                }
            }
            .padding(.horizontal, 4)
            .accessibilityElement(children: .combine)
        }
    }

    private var saveArea: some View {
        VStack(spacing: 9) {
            FruitfolioControlPillButton(
                label: model.saveState == .saving ? "saving…" : model.saveButtonTitle
            ) {
                guard model.canSave else { return }

                saveLog()
            }
            .disabled(!model.canSave)
            .opacity(model.canSave ? 1 : 0.52)

            if showSavedMessage {
                FruitfolioFixedText(source: "saved to your day ♡", font: Prompt20Type.summary, serious: true)
                    .font(Prompt20Type.summary)
                    .foregroundStyle(Prompt20Palette.sage)
                    .transition(.opacity)
            }

            if model.saveState == .failed && model.validationIssues.isEmpty {
                VStack(spacing: 6) {
                    FruitfolioTranslatedText(source: "couldn’t save that just yet. your entry is still here."
                        + (model.saveFailureMessage.map { "\n\n" + $0 } ?? ""),
                        font: Prompt20Type.summary, color: Prompt20Palette.burgundy.opacity(0.68), serious: true)
                        .multilineTextAlignment(.center)

                    FruitfolioControlPillButton(label: "try again") { saveLog() }
                        .controlSize(.small)
                        .accessibilityIdentifier("dailyLog.retrySave")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    private var futureDateView: some View {
        VStack(spacing: 14) {
            Spacer()

            Image("fruit_peach_soft")
                .resizable()
                .scaledToFit()
                .frame(width: 76)
                .accessibilityHidden(true)

            FruitfolioFixedText(source: "daily log", font: Prompt20Type.title, serious: true)
                .font(Prompt20Type.title)
                .foregroundStyle(Prompt20Palette.burgundy)

            Text(displayDate)
                .font(Prompt20Type.date)
                .foregroundStyle(Prompt20Palette.coral)

            Text("this date hasn’t happened yet, so body observations stay closed for now.")
                .font(Prompt20Type.body)
                .foregroundStyle(Prompt20Palette.burgundy.opacity(0.68))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            FruitfolioControlPillButton(label: "close", action: requestClose)
                .controlSize(.small)

            Spacer()
        }
        .padding(24)
    }

    private func requestClose() {
        guard model.saveState != .saving, canInteract else { return }
        guard model.hasUnsavedChanges else { dismiss(); return }
        guard let owner = popupOwner else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        returnMedicationFocus = nil
        returnFocusAfterConfirmation = true
        closeFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: "save, discard or keep editing this day’s changes? saved observations remain unchanged unless you save.",
                primaryAction: .init(label: "keep editing") {
                    guard ownerIsActive else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "save and close") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingConfirmationAction = .saveAndClose
                }, tertiaryAction: .init(label: "discard changes") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingConfirmationAction = .discardAndClose
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "daily-log-draft", deduplicationKey: "daily-log-draft-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private func requestMedicationRemoval(_ entry: Prompt20MedicationEntry) {
        guard canInteract, let owner = popupOwner, model.saveState != .saving else { return }
        if let id = owner.requestID, popupCoordinator.containsRequest(id: id) { return }
        if !entry.hasAnyContent {
            _ = model.removeMedication(ifUnchanged: entry)
            return
        }
        returnMedicationFocus = entry.id
        returnFocusAfterConfirmation = true
        closeFocused = false
        medicationFocused = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .peach,
                message: "remove this medication or supplement entry from the current draft? saved observations change only when you save this day.",
                primaryAction: .init(label: "keep entry") {
                    guard ownerIsActive else { return }
                    _ = owner.consumeAction(for: id)
                }, secondaryAction: .init(label: "remove entry") {
                    guard ownerIsActive, owner.consumeAction(for: id) else { return }
                    pendingConfirmationAction = .removeMedication(entry)
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "daily-log-medication", deduplicationKey: "daily-log-medication-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private func prompt(_ text: String) -> some View {
        FruitfolioFixedText(source: text, font: Prompt20Type.prompt, serious: true)
            .font(Prompt20Type.prompt)
            .foregroundStyle(Prompt20Palette.burgundy.opacity(0.80))
    }

    private func notePrompt(_ text: String) -> some View {
        FruitfolioFixedText(source: text, font: Prompt20Type.micro, serious: true)
            .font(Prompt20Type.micro)
            .foregroundStyle(Prompt20Palette.burgundy.opacity(0.60))
    }

    private func choiceChip(
        _ label: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            audioManager.play(.buttonSoftPop)
            action()
        } label: {
            HStack(spacing: 5) {
                Text(label)
                    .font(Prompt20Type.chip)
                    .foregroundStyle(Prompt20Palette.burgundy)
                    .multilineTextAlignment(.center)

                if selected {
                    Image("control_check")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 11)
            .frame(minHeight: 38)
            .background {
                Prompt20ChipShape(variant: label.hashValue)
                    .fill(
                        selected
                            ? Prompt20Palette.peach.opacity(0.24)
                            : Prompt20Palette.paper.opacity(0.72)
                    )
            }
            .overlay {
                if selected {
                    Prompt20ChipShape(variant: label.hashValue)
                        .stroke(Prompt20Palette.burgundy.opacity(0.30), lineWidth: 0.9)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: motionPreferences.reduceMotionActive
            )
        )
        .accessibilityLabel(label)
        .accessibilityValue(selected ? "selected" : "not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 15, style: .continuous)
            .fill(Prompt20Palette.paper.opacity(0.88))
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Prompt20Palette.burgundy.opacity(0.13), lineWidth: 0.8)
            }
    }

    private func journalTextEditor(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat,
        identifier: String? = nil
    ) -> some View {
        ZStack(alignment: .topLeading) {
            if text.wrappedValue.isEmpty {
                FruitfolioFixedText(source: placeholder, font: Prompt20Type.input, serious: true)
                    .font(Prompt20Type.input)
                    .accessibilityHidden(true)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.34))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 13)
                    .allowsHitTesting(false)
            }

            FruitfolioFixedTextEditor(placeholder, text: text)
                .accessibilityIdentifier(identifier ?? placeholder)
                .font(Prompt20Type.input)
                .foregroundStyle(Prompt20Palette.burgundy)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 7)
                .frame(minHeight: minHeight, maxHeight: max(minHeight, 210))
        }
        .background(inputBackground)
    }

    private func binding(_ keyPath: WritableKeyPath<Prompt20DailyLogDraft, String>) -> Binding<String> {
        Binding(
            get: { model.draft[keyPath: keyPath] },
            set: { value in
                model.mutateDraft { $0[keyPath: keyPath] = value }
            }
        )
    }

    private func medicationValidationMessage(for id: UUID) -> String? {
        guard let index = model.draft.medications.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        guard model.validationIssues.contains(.medicationNameRequired(index: index)) else {
            return nil
        }
        return model.validationMessage(for: .medicationNameRequired(index: index))
    }

    private func saveLog() {
        guard canInteract, model.canSave else { return }
        repositoryTask?.cancel()
        repositoryTask = Task { @MainActor in
            guard !Task.isCancelled, viewIsVisible else { return }
            let success = await model.save()
            guard success, !Task.isCancelled, viewIsVisible else { return }
            onSaved(model.existingLog)
            if !model.hasUnsavedChanges { showSaveFeedback() }
        }
    }

    private func showSaveFeedback() {
        savedMessageTask?.cancel()

        withAnimation(
            motionPreferences.reduceMotionActive
                ? .easeOut(duration: 0.08)
                : .easeOut(duration: 0.18)
        ) {
            showSavedMessage = true
        }

        savedMessageTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.16)) {
                showSavedMessage = false
            }
        }
    }
}

private struct Prompt20MedicationRow: View {
    let medication: Prompt20MedicationEntry
    let removeFocus: AccessibilityFocusState<UUID?>.Binding
    let validationMessage: String?
    let onChange: (Prompt20MedicationEntry) -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("entry")
                    .font(Prompt20Type.groupLabel)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.56))

                Spacer()

                FruitfolioControlPillButton(label: "remove", action: onRemove)
                    .controlSize(.small)
                    .accessibilityFocused(removeFocus, equals: medication.id)
                    .accessibilityIdentifier("dailyLog.removeMedication." + medication.id.uuidString)
                    .accessibilityLabel("remove \(medication.name.isEmpty ? "medication entry" : medication.name)")
            }

            Prompt20LabeledField(
                label: "name",
                placeholder: "name",
                text: fieldBinding(\.name)
            )

            HStack(spacing: 10) {
                Prompt20LabeledField(
                    label: "dose optional",
                    placeholder: "dose",
                    text: fieldBinding(\.dose)
                )

                Prompt20LabeledField(
                    label: "time optional",
                    placeholder: "time",
                    text: fieldBinding(\.time)
                )
            }

            Prompt20LabeledField(
                label: "note optional",
                placeholder: "note",
                text: fieldBinding(\.note)
            )

            if let validationMessage {
                Text(validationMessage)
                    .font(Prompt20Type.micro)
                    .foregroundStyle(Prompt20Palette.burgundy.opacity(0.70))
            }


        }
        .padding(12)
        .background {
            Prompt20JournalSectionShape(variant: medication.id.hashValue)
                .fill(Prompt20Palette.sage.opacity(0.08))
        }
    }

    private func fieldBinding(_ keyPath: WritableKeyPath<Prompt20MedicationEntry, String>) -> Binding<String> {
        Binding(
            get: { medication[keyPath: keyPath] },
            set: { value in
                var changed = medication
                changed[keyPath: keyPath] = value
                onChange(changed)
            }
        )
    }
}

private struct Prompt20LabeledField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    init(label: String, placeholder: String, text: Binding<String>) {
        self.label = label
        self.placeholder = placeholder
        _text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Prompt20Type.micro)
                .foregroundStyle(Prompt20Palette.burgundy.opacity(0.52))

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(Prompt20Type.input)
                .foregroundStyle(Prompt20Palette.burgundy)
                .padding(.horizontal, 11)
                .frame(minHeight: 42)
                .background {
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Prompt20Palette.paper.opacity(0.86))
                        .overlay {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Prompt20Palette.burgundy.opacity(0.10), lineWidth: 0.7)
                        }
                }
        }
    }
}

private struct Prompt20AdaptiveChips<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 88), spacing: 8)],
            alignment: .leading,
            spacing: 8
        ) {
            content
        }
    }
}

private struct Prompt20JournalSectionShape: Shape {
    let variant: Int

    func path(in rect: CGRect) -> Path {
        let wobble = CGFloat(abs(variant) % 5) * 0.004
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 8, y: rect.minY + 5))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 7, y: rect.minY + 7),
            control1: CGPoint(x: rect.width * (0.32 + wobble), y: rect.minY),
            control2: CGPoint(x: rect.width * 0.75, y: rect.minY + 3)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - 5, y: rect.maxY - 7),
            control1: CGPoint(x: rect.maxX, y: rect.height * 0.34),
            control2: CGPoint(x: rect.maxX - 1, y: rect.height * 0.76)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 7, y: rect.maxY - 5),
            control1: CGPoint(x: rect.width * 0.72, y: rect.maxY),
            control2: CGPoint(x: rect.width * 0.26, y: rect.maxY - 1)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + 8, y: rect.minY + 5),
            control1: CGPoint(x: rect.minX, y: rect.height * 0.72),
            control2: CGPoint(x: rect.minX + 2, y: rect.height * 0.26)
        )
        path.closeSubpath()
        return path
    }
}

private struct Prompt20ChipShape: Shape {
    let variant: Int

    func path(in rect: CGRect) -> Path {
        let inset = CGFloat(abs(variant) % 3) * 0.4
        return RoundedRectangle(cornerRadius: 15 + inset, style: .continuous)
            .path(in: rect.insetBy(dx: inset, dy: inset))
    }
}

private enum Prompt20Palette {
    static let burgundy = Color(red: 128.0 / 255.0, green: 0, blue: 0)
    static let paper = DesignTokens.ColorToken.backgroundCream
    static let coral = Color(red: 0.89, green: 0.43, blue: 0.46)
    static let peach = Color(red: 0.93, green: 0.70, blue: 0.59)
    static let sage = Color(red: 0.51, green: 0.64, blue: 0.48)
    static let dustyBlue = Color(red: 0.49, green: 0.66, blue: 0.70)
}

private enum Prompt20Type {
    static let title = Font.custom("Chalkboard SE", size: 27, relativeTo: .title2).weight(.bold)
    static let date = Font.custom("Chalkboard SE", size: 15, relativeTo: .headline).weight(.semibold)
    static let body = Font.custom("Chalkboard SE", size: 14, relativeTo: .body)
    static let sectionTitle = Font.custom("Chalkboard SE", size: 16, relativeTo: .headline).weight(.semibold)
    static let summary = Font.custom("Chalkboard SE", size: 11.5, relativeTo: .caption)
    static let prompt = Font.custom("Chalkboard SE", size: 14, relativeTo: .body).weight(.semibold)
    static let groupLabel = Font.custom("Chalkboard SE", size: 11, relativeTo: .caption).weight(.semibold)
    static let chip = Font.custom("Chalkboard SE", size: 12, relativeTo: .caption)
    static let input = Font.custom("Chalkboard SE", size: 13.5, relativeTo: .body)
    static let micro = Font.custom("Chalkboard SE", size: 10.5, relativeTo: .caption)
    static let button = Font.custom("Chalkboard SE", size: 13, relativeTo: .body).weight(.semibold)
}
