import SwiftUI

/// Selection alone never invokes Ask. Done attaches only the selected IDs to
/// the next unsent question; the request snapshot is resolved again at Send.
struct FruitfolioAskContextPicker: View {
    @ObservedObject var measurements: FruitfolioHormoneMeasurementStore
    @ObservedObject var contextStore: Prompt27AContextStore
    let onAttach: (Set<UUID>, Set<FruitfolioPersonalHealthCategory>) -> Void
    let onCancel: () -> Void
    @State private var measurementIDs: Set<UUID>
    @State private var categories: Set<FruitfolioPersonalHealthCategory>
    @State private var errorMessage: String?

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
                Text("context for my next question").font(.headline).accessibilityAddTraits(.isHeader)
                Text("nothing is shared by default. choose local records, attach them, then press Send. this is user-provided context, not verified research or a diagnosis. it is used for one question only and is not added to the question text or sources.")
                Text("My Measurements").font(.headline)
                if measurements.storageUnreadable { Text("measurements are unavailable; their original data has been preserved.") }
                else if measurements.records.isEmpty { Text("no measurements recorded.") }
                ForEach(measurements.history()) { record in
                    Toggle(isOn: measurementBinding(record.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(verbatim: record.hormoneName).bold()
                            Text(verbatim: record.result + " " + record.unit)
                            Text(record.testDate, style: .date)
                        }
                    }
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
                Text("Personal Health Context").font(.headline)
                if contextStore.didRecoverCorruptStoredContext { Text("personal context is unavailable; its original data has been preserved.") }
                ForEach(FruitfolioPersonalHealthCategory.allCases.filter {
                    contextStore.context.personalHealthEntries[$0.rawValue]?.status == .provided
                }) { category in
                    Toggle(isOn: categoryBinding(category)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(category.title)).bold()
                            if let entry = contextStore.context.personalHealthEntries[category.rawValue] {
                                Text(verbatim: entry.text ?? "").lineLimit(3)
                                Text(LocalizedStringKey(entry.provenance.label)).font(.caption)
                            }
                        }
                    }
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(Color.red) }
                WatercolorPrimaryButton(label: "attach selected context") { attach() }
                WatercolorSecondaryButton(label: "cancel") { onCancel() }
            }
            .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
        }
    }
    private func measurementBinding(_ id: UUID) -> Binding<Bool> {
        Binding(get: { measurementIDs.contains(id) }, set: { selected in
            if selected { measurementIDs.insert(id) } else { measurementIDs.remove(id) }
        })
    }
    private func categoryBinding(_ category: FruitfolioPersonalHealthCategory) -> Binding<Bool> {
        Binding(get: { categories.contains(category) }, set: { selected in
            if selected { categories.insert(category) } else { categories.remove(category) }
        })
    }
    private func attach() {
        let validIDs = measurementIDs.intersection(Set(measurements.records.map(\.id)))
        let validCategories = categories.filter { contextStore.context.personalHealthEntries[$0.rawValue]?.status == .provided }
        do {
            _ = try FruitfolioAskUserContext.selected(measurementIDs: validIDs, personalCategories: validCategories,
                measurements: measurements.records, context: contextStore.context)
            onAttach(validIDs, validCategories)
        } catch { errorMessage = error.localizedDescription }
    }
}

#if DEBUG
struct FruitfolioAskContextRegressionHarness: View {
    @StateObject private var measurements: FruitfolioHormoneMeasurementStore
    @StateObject private var model: Prompt09AskViewModel
    private let suite: String
    init() {
        let suite = "fruitfolio.askContextQA." + UUID().uuidString
        self.suite = suite
        let store = FruitfolioHormoneMeasurementStore(defaults: UserDefaults(suiteName: suite) ?? .standard, key: suite)
        var fixture = FruitfolioHormoneMeasurement()
        fixture.hormone = .progesterone; fixture.result = "12.50"; fixture.unit = "ng/mL"
        fixture.notes = "QA explicitly selected fixture context"
        try? store.save(fixture, locale: Locale(identifier: "en_US"))
        _measurements = StateObject(wrappedValue: store)
        _model = StateObject(wrappedValue: Prompt09AskViewModel.paperRegressionFixture())
    }
    var body: some View {
        Prompt09AskView(viewModel: model, measurements: measurements)
            .onDisappear {
                UserDefaults.standard.removeObject(forKey: suite)
                UserDefaults.standard.removePersistentDomain(forName: suite)
            }
    }
}
#endif
