import SwiftUI
import UIKit

/// Selection alone never invokes Ask. Done attaches only the selected IDs to
/// the next unsent question; the request snapshot is resolved again at Send.
struct FruitfolioAskContextPicker: View {
    @ObservedObject var measurements: FruitfolioHormoneMeasurementStore
    @ObservedObject var contextStore: Prompt27AContextStore
    let onAttach: (Set<UUID>, Set<FruitfolioPersonalHealthCategory>) -> Void
    let onCancel: () -> Void
    @State private var measurementIDs: Set<UUID>
    @State private var categories: Set<FruitfolioPersonalHealthCategory>
    @State private var errorMessage: FruitfolioAskContextNotice?
    @State private var viewIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    private var canInteract: Bool {
        viewIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil
    }

    init(measurements: FruitfolioHormoneMeasurementStore, contextStore: Prompt27AContextStore,
        selectedMeasurements: Set<UUID>, selectedCategories: Set<FruitfolioPersonalHealthCategory>,
        onAttach: @escaping (Set<UUID>, Set<FruitfolioPersonalHealthCategory>) -> Void, onCancel: @escaping () -> Void) {
        self.measurements = measurements; self.contextStore = contextStore
        self.onAttach = onAttach; self.onCancel = onCancel
        _measurementIDs = State(initialValue: selectedMeasurements)
        _categories = State(initialValue: selectedCategories)
    }
    var body: some View {
        FruitfolioTapedWhitePopup {
            VStack(alignment: .leading, spacing: 14) {
                FruitfolioFixedText(source: "context for my next question", serious: true).font(.headline).accessibilityAddTraits(.isHeader)
                FruitfolioTranslatedText(source: "nothing is shared by default. choose local records, attach them, then press Send. this is user-provided context, not verified research or a diagnosis. it is used for one question only and is not added to the question text or sources.", serious: true)
                FruitfolioFixedText(source: "My Measurements", serious: true).font(.headline)
                if measurements.storageUnreadable { FruitfolioFixedText(source: "measurements are unavailable; their original data has been preserved.", serious: true) }
                else if measurements.records.isEmpty { FruitfolioFixedText(source: "no measurements recorded.", serious: true) }
                ForEach(measurements.history()) { record in
                    Toggle(isOn: measurementBinding(record.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Group {
                                if record.hormone == .other { Text(verbatim: record.otherHormoneName) }
                                else { FruitfolioFixedText(source: record.hormone.label, protectedLiterals: record.hormone.protectedAbbreviations, serious: true) }
                            }.fontWeight(.bold)
                            Text(verbatim: record.result + " " + record.unit)
                            if let date = record.dateForDisplay() { Text(date, style: .date) }
                            else if let day = record.reportedTestDay?.description { Text(verbatim: day) }
                            else { FruitfolioFixedText(source: "date unavailable", serious: true) }
                        }
                    }
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
                FruitfolioFixedText(source: "Personal Health Context", serious: true).font(.headline)
                if contextStore.didRecoverCorruptStoredContext { FruitfolioFixedText(source: "personal context is unavailable; its original data has been preserved.", serious: true) }
                ForEach(FruitfolioPersonalHealthCategory.allCases.filter {
                    contextStore.context.personalHealthEntries[$0.rawValue]?.status == .provided
                }) { category in
                    Toggle(isOn: categoryBinding(category)) {
                        VStack(alignment: .leading, spacing: 4) {
                            FruitfolioFixedText(source: category.title, serious: true).fontWeight(.bold)
                            if let entry = contextStore.context.personalHealthEntries[category.rawValue] {
                                Text(verbatim: entry.text ?? "").lineLimit(3)
                                FruitfolioFixedText(source: entry.provenance.label, font: .caption, serious: true)
                            }
                        }
                    }
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
                if let errorMessage {
                    if let source = errorMessage.fixedSource {
                        FruitfolioFixedText(source: source, color: .red, serious: true)
                    } else {
                        Text(verbatim: errorMessage.text).foregroundStyle(.red)
                    }
                }
                WatercolorPrimaryButton(label: "attach selected context") { attach() }
                WatercolorSecondaryButton(label: "cancel") { guard canInteract else { return }; onCancel() }
            }
            .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
        }
        .onAppear { viewIsVisible = true }
        .onDisappear { viewIsVisible = false }
    }
    private func measurementBinding(_ id: UUID) -> Binding<Bool> {
        Binding(get: { measurementIDs.contains(id) }, set: { selected in
            guard canInteract else { return }
            if selected { measurementIDs.insert(id) } else { measurementIDs.remove(id) }
        })
    }
    private func categoryBinding(_ category: FruitfolioPersonalHealthCategory) -> Binding<Bool> {
        Binding(get: { categories.contains(category) }, set: { selected in
            guard canInteract else { return }
            if selected { categories.insert(category) } else { categories.remove(category) }
        })
    }
    private func attach() {
        guard canInteract else { return }
        let validIDs = measurementIDs.intersection(Set(measurements.records.map(\.id)))
        let validCategories = categories.filter { contextStore.context.personalHealthEntries[$0.rawValue]?.status == .provided }
        do {
            _ = try FruitfolioAskUserContext.selected(measurementIDs: validIDs, personalCategories: validCategories,
                measurements: measurements.records, context: contextStore.context)
            onAttach(validIDs, validCategories)
        } catch { errorMessage = .init(error: error) }
    }
}

#if DEBUG
struct FruitfolioAskContextRegressionHarness: View {
    @EnvironmentObject private var preferences: FruitfolioRegressionPreferenceSuite
    var body: some View {
        FruitfolioAskContextRegressionContent(defaults: preferences.defaults)
    }
}

private struct FruitfolioAskContextRegressionContent: View {
    @EnvironmentObject private var settings: SettingsStore
    @StateObject private var fixture: FruitfolioAskContextRegressionFixture
    @StateObject private var model: Prompt09AskViewModel
    init(defaults: UserDefaults?) {
        _fixture = StateObject(wrappedValue: FruitfolioAskContextRegressionFixture(defaults: defaults))
        _model = StateObject(wrappedValue: Prompt09AskViewModel.paperRegressionFixture(
            illustrationOption: ProcessInfo.processInfo.arguments.contains("-fruitfolioAskIllustrationQA")))
    }
    var body: some View {
        Group {
            if let measurements = fixture.measurements {
                Prompt09AskView(viewModel: model, measurements: measurements)
            } else {
                Text(verbatim: fixture.failureMessage ?? "Ask regression environment unavailable.")
            }
        }
        .onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard args.contains("-fruitfolioAskControlsQA") else { return }
            settings.language = args.contains("-fruitfolioAskControlsQAArabic") ? .arabic : .french
            settings.translationPausedForMemoryPressure = true
            settings.reduceAnimationOverride = args.contains("-fruitfolioAskControlsQAReduceMotion")
        }
    }
}
#endif
