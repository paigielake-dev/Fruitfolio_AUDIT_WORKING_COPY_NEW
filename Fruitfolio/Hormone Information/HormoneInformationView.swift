import SwiftUI

struct HormoneInformationView: View {
    @ObservedObject var store: HormoneMeasurementStore
    let onBack: () -> Void
    @State private var showLibrary = false
    @State private var filter: RecordedHormone?
    @State private var newestFirst = true
    @State private var editing: HormoneMeasurement?
    @State private var pendingDeletion: HormoneMeasurement?
    @State private var error: String?

    private var records: [HormoneMeasurement] {
        store.measurements.filter { filter == nil || $0.hormone == filter }
            .sorted { newestFirst ? $0.testDate > $1.testDate : $0.testDate < $1.testDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            BackControl(action: onBack)
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("hormone information ♡").font(.title2).bold().accessibilityAddTraits(.isHeader)
                    Image("hormone_estrogen").resizable().scaledToFit().frame(maxWidth: 120).accessibilityHidden(true)
                    Text("your measurements stay on this device. they are not sent to Ask or used to change cycle predictions.")
                    if let loadError = store.loadError { Text(loadError).accessibilityLabel(loadError) }
                    if store.measurements.isEmpty && store.loadError == nil {
                        Text("have hormone results you’d like to keep track of? add them whenever you’re ready.")
                    }
                    FruitfolioControlPillButton(label: "add measurement") { editing = HormoneMeasurement() }
                        .disabled(store.loadError != nil)
                    FruitfolioControlPillButton(label: "hormone library") { showLibrary = true }
                    Picker("filter by hormone", selection: $filter) {
                        Text("all hormones").tag(Optional<RecordedHormone>.none)
                        ForEach(RecordedHormone.allCases) { hormone in
                            Text(LocalizedStringKey(hormone.title)).tag(Optional(hormone))
                        }
                    }
                    Toggle("newest results first", isOn: $newestFirst)
                    ForEach(records) { record in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(record.displayName).bold()
                            Text(record.result + " " + record.unit).textSelection(.enabled)
                            Text(record.testDate, style: .date)
                            if !record.sampleType.isEmpty { Text(record.sampleType) }
                            if !record.cycleDay.isEmpty { Text("cycle day: \(record.cycleDay)") }
                            if !record.laboratoryReferenceRange.isEmpty {
                                Text("laboratory-provided reference range: \(record.laboratoryReferenceRange)")
                            }
                            if !record.notes.isEmpty { Text(record.notes).textSelection(.enabled) }
                            FruitfolioControlPillButton(label: "open / edit measurement") { editing = record }
                            FruitfolioControlPillButton(label: "delete measurement") { pendingDeletion = record }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("hormone.measurement.\(record.id.uuidString)")
                        Divider()
                    }
                    Text("these are results you recorded, not a diagnosis. timing, sample type, methods, units, and clinical context matter. Fruitfolio does not classify results or recommend treatment.")
                    Text("hormone rhythm remains a separate educational illustration. these records do not represent a measured curve or confirm ovulation or fertility.")
                }
                .frame(maxWidth: 620, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .padding(20)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .sheet(isPresented: $showLibrary) { HormoneResearchLibraryView() }
        .sheet(item: $editing) { record in
            HormoneMeasurementEditor(store: store, measurement: record)
        }
        .alert("delete this measurement?", isPresented: Binding(
            get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("cancel", role: .cancel) { pendingDeletion = nil }
            Button("delete", role: .destructive) {
                guard let record = pendingDeletion else { return }
                do { try store.delete(id: record.id) } catch { self.error = error.localizedDescription }
                pendingDeletion = nil
            }
        } message: { Text("only this recorded result will be removed. cycle logs and predictions are unchanged.") }
        .alert("measurement could not be changed", isPresented: Binding(
            get: { error != nil }, set: { if !$0 { error = nil } }
        )) { Button("ok") { error = nil } } message: { Text(error ?? "") }
    }
}

private struct HormoneMeasurementEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: HormoneMeasurementStore
    @State private var draft: HormoneMeasurement
    private let original: HormoneMeasurement
    @FocusState private var fieldFocused: Bool
    @State private var showDiscard = false
    @State private var error: String?

    init(store: HormoneMeasurementStore, measurement: HormoneMeasurement) {
        self.store = store
        self.original = measurement
        _draft = State(initialValue: measurement)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("record a measurement").font(.title2).bold()
                Picker("hormone", selection: $draft.hormone) {
                    ForEach(RecordedHormone.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
                }
                if draft.hormone == .other { field("other hormone name", text: $draft.otherHormoneName) }
                field("numerical result", text: $draft.result).keyboardType(.decimalPad)
                field("unit (exactly as reported)", text: $draft.unit)
                DatePicker("test date", selection: $draft.testDate, displayedComponents: .date)
                    .onChange(of: draft.testDate) { _, _ in draft.testDateWasProvided = true }
                if draft.testDateWasProvided != true {
                    FruitfolioControlPillButton(label: "confirm test date") { draft.testDateWasProvided = true }
                    Text("the displayed date is not saved until you choose or confirm it.")
                }
                field("sample type (optional)", text: $draft.sampleType)
                field("cycle day (optional)", text: $draft.cycleDay).keyboardType(.numberPad)
                field("laboratory-provided reference range (optional)", text: $draft.laboratoryReferenceRange)
                field("notes (optional)", text: $draft.notes, multiline: true)
                Text("enter a decimal separator only for decimals; do not enter thousands separators. units are saved exactly as entered and are never converted.")
                if let validation = draft.validationError { Text(LocalizedStringKey(validation)).font(.footnote) }
                if let error { Text(error).accessibilityLabel(error) }
                FruitfolioControlPillButton(label: "save measurement") {
                    do { try store.save(draft); dismiss() } catch { self.error = error.localizedDescription }
                }.disabled(draft.validationError != nil)
                FruitfolioControlPillButton(label: "cancel") {
                    if draft != original { showDiscard = true } else { dismiss() }
                }
            }
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            if fieldFocused {
                HStack {
                    Spacer()
                    Button("done") { fieldFocused = false }
                        .accessibilityIdentifier("hormone.keyboardDone")
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }
        }
        .interactiveDismissDisabled(draft != original)
        .confirmationDialog("discard unsaved measurement?", isPresented: $showDiscard, titleVisibility: .visible) {
            Button("discard", role: .destructive) { dismiss() }
            Button("keep editing", role: .cancel) { }
        }
    }

    private func field(_ label: String, text: Binding<String>, multiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(LocalizedStringKey(label))
            TextField(LocalizedStringKey(label), text: text, axis: multiline ? .vertical : .horizontal)
                .textFieldStyle(.roundedBorder)
                .focused($fieldFocused)
                .submitLabel(.done)
                .onSubmit { fieldFocused = false }
                .accessibilityLabel(LocalizedStringKey(label))
                .autocorrectionDisabled()
        }
    }
}

/// Queries approved research only. No recorded measurement enters this request.
private struct HormoneResearchLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected: RecordedHormone = .estradiol
    @State private var answer: AskAnswer?
    @State private var error: String?
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FruitfolioControlPillButton(label: "back") { dismiss() }
                Text("hormone library").font(.title2).bold()
                Picker("hormone", selection: $selected) {
                    ForEach(RecordedHormone.allCases.filter { $0 != .other }) {
                        Text(LocalizedStringKey($0.title)).tag($0)
                    }
                }
                Text("these explanations use the approved research library. your recorded results are not included.")
                if loading { ProgressView("looking through the library…") }
                if let answer {
                    Text(answer.answerText).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    ForEach(answer.sources) { source in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.title).bold()
                            if let publication = source.publicationData { Text(publication) }
                            if let text = source.sourceText { Text(text) }
                        }.textSelection(.enabled)
                    }
                }
                if let error { Text(error) }
                Text("an isolated result does not establish a diagnosis. discuss personal interpretation with a qualified clinician.")
            }
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(20)
        }
        .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .task(id: selected) {
            let requested = selected
            answer = nil
            error = nil
            loading = true
            do {
                let response = try await FruitfolioResearchIntelligenceEngine.shared.answer(
                    question: "explain \(requested.title): biological functions, reproductive physiology, factors affecting measurements, timing and testing methods, limitations of an isolated result, and when professional guidance is appropriate. use only approved research; say when evidence is missing.",
                    conversation: []
                )
                try Task.checkCancellation()
                guard selected == requested else { return }
                answer = response
                loading = false
            } catch {
                guard !Task.isCancelled, selected == requested else { return }
                self.error = error.localizedDescription
                loading = false
            }
        }
    }
}
