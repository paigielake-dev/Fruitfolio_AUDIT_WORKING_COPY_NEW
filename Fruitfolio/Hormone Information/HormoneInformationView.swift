import SwiftUI
import UniformTypeIdentifiers

struct FruitfolioHormoneInformationView: View {
    let onBack: () -> Void
    @ObservedObject private var store = FruitfolioHormoneMeasurementStore.shared
    @State private var showingLibrary = false
    @State private var filter: FruitfolioMeasuredHormone?
    @State private var editing: FruitfolioHormoneMeasurement?
    @State private var deleting: FruitfolioHormoneMeasurement?
    @State private var errorMessage: String?
    @State private var showExport = false
    @State private var confirmErase = false
    @State private var exportDocument = FruitfolioHormoneExportDocument(data: Data())

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BackControl(action: onBack)
                HStack {
                    Text("hormone information ♡").font(.title2).bold()
                        .accessibilityAddTraits(.isHeader)
                    FruitfolioImage(id: .hormone_estrogen)
                        .scaledToFit().frame(width: 56, height: 56)
                        .accessibilityHidden(true)
                }
                WatercolorSecondaryButton(label: "explore the hormone library") { showingLibrary = true }
                Text("my measurements").font(.headline)
                if store.storageUnreadable {
                    Text(FruitfolioHormoneMeasurementError.unreadableStorage.localizedDescription)
                } else if store.records.isEmpty {
                    Text("have hormone results you’d like to keep track of? add them whenever you’re ready.")
                }
                WatercolorPrimaryButton(label: "Add Measurement") {
                    editing = FruitfolioHormoneMeasurement()
                }
                .disabled(store.storageUnreadable)
                Picker("filter by hormone", selection: $filter) {
                    Text("all hormones").tag(Optional<FruitfolioMeasuredHormone>.none)
                    ForEach(FruitfolioMeasuredHormone.allCases) { hormone in
                        Text(LocalizedStringKey(hormone.label)).tag(Optional(hormone))
                    }
                }
                ForEach(store.history(hormone: filter)) { measurement in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verbatim: measurement.hormoneName).bold()
                        Text(verbatim: "\(measurement.result) \(measurement.unit)")
                        if let date = measurement.dateForDisplay() { Text(date, style: .date) }
                        else { Text(verbatim: measurement.reportedTestDay?.description ?? "date unavailable") }
                        if measurement.reportedTestDay == nil {
                            Text("date shown in your current time zone; you can confirm or correct it when editing.").font(.caption)
                        }
                        if !measurement.sampleType.isEmpty { Text(verbatim: measurement.sampleType) }
                        if let day = measurement.cycleDay { Text("cycle day \(day)") }
                        if !measurement.laboratoryReferenceRange.isEmpty {
                            Text("laboratory reference range")
                            Text(verbatim: measurement.laboratoryReferenceRange)
                        }
                        if !measurement.notes.isEmpty { Text(verbatim: measurement.notes) }
                        WatercolorSecondaryButton(label: "edit measurement") { editing = measurement }
                        WatercolorSecondaryButton(label: "delete measurement") { deleting = measurement }
                    }
                    .padding(16)
                    .background(DesignTokens.ColorToken.softWhite, in: RoundedRectangle(cornerRadius: 16))
                }
                Text("Hormone Rhythm shows typical educational patterns. My Measurements contains only values you record. These records do not adjust cycle predictions or confirm ovulation, fertility, or a diagnosis.")
                Text("your measurement has been saved, but there isn’t enough information to adjust this illustration reliably. you can still explore the typical hormone rhythm and view your actual result in my measurements.")
                    .font(.footnote)
                    .accessibilityHidden(store.records.isEmpty)
                    .opacity(store.records.isEmpty ? 0 : 1)
                WatercolorSecondaryButton(label: "export my measurements") {
                    do {
                        exportDocument = FruitfolioHormoneExportDocument(data: try store.exportJSON())
                        showExport = true
                    } catch { errorMessage = error.localizedDescription }
                }
                .disabled(store.storageUnreadable || store.records.isEmpty)
                WatercolorSecondaryButton(label: "delete all measurements") { confirmErase = true }
                .disabled(store.records.isEmpty && !store.storageUnreadable)
                if let errorMessage { Text(errorMessage) }
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .sheet(isPresented: $showingLibrary) {
            FruitfolioHormoneLibraryView(onBack: { showingLibrary = false })
        }
        .sheet(item: $editing) { record in
            FruitfolioHormoneMeasurementEditor(original: record, captureInitialTestDay: !store.records.contains(where: { $0.id == record.id }), onCancel: { editing = nil }) { updated in
                try store.save(updated)
                editing = nil
            }
        }
        .fileExporter(isPresented: $showExport, document: exportDocument, contentType: .json,
                      defaultFilename: "Fruitfolio-My-Measurements") { result in
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
        }
        .confirmationDialog(confirmErase ? "delete all hormone measurements from this device?" : "delete this measurement?",
                            isPresented: Binding(get: { confirmErase || deleting != nil },
                                                 set: { if !$0 { confirmErase = false; deleting = nil } })) {
            if confirmErase {
                Button("delete all measurements", role: .destructive) {
                    store.eraseAllMeasurements()
                    confirmErase = false
                }
            } else {
                Button("delete measurement", role: .destructive) {
                    guard let record = deleting else { return }
                    do { try store.delete(id: record.id) } catch { errorMessage = error.localizedDescription }
                    deleting = nil
                }
            }
            Button("cancel", role: .cancel) { confirmErase = false; deleting = nil }
        }
        .accessibilityIdentifier("hormoneInformation.history")
    }
}

private struct FruitfolioHormoneMeasurementEditor: View {
    let original: FruitfolioHormoneMeasurement
    let onCancel: () -> Void
    let onSave: (FruitfolioHormoneMeasurement) throws -> Void
    @State private var draft: FruitfolioHormoneMeasurement
    @State private var cycleDayText: String
    @State private var errorMessage: String?
    @State private var confirmDiscard = false

    init(original: FruitfolioHormoneMeasurement, captureInitialTestDay: Bool = false, onCancel: @escaping () -> Void,
         onSave: @escaping (FruitfolioHormoneMeasurement) throws -> Void) {
        var initial = original
        if captureInitialTestDay { try? initial.setReportedTestDate(original.testDate, calendar: .autoupdatingCurrent) }
        self.original = initial
        self.onCancel = onCancel
        self.onSave = onSave
        _draft = State(initialValue: initial)
        _cycleDayText = State(initialValue: original.cycleDay.map(String.init) ?? "")
    }
    private var hasChanges: Bool { draft != original || cycleDayText != (original.cycleDay.map(String.init) ?? "") }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("measurement").font(.title2).bold()
                Picker("hormone", selection: $draft.hormone) {
                    ForEach(FruitfolioMeasuredHormone.allCases) { Text(LocalizedStringKey($0.label)).tag($0) }
                }
                if draft.hormone == .other { TextField("other hormone name", text: $draft.otherHormoneName) }
                TextField("numerical result", text: $draft.result).keyboardType(.decimalPad)
                    .onChange(of: draft.result) { _, _ in draft.resultLocaleIdentifier = Locale.current.identifier }
                TextField("unit, exactly as reported", text: $draft.unit)
                if let shownDate = draft.dateForDisplay() {
                    DatePicker("test date", selection: Binding(
                        get: { draft.dateForDisplay() ?? shownDate },
                        set: { value in
                            do { try draft.setReportedTestDate(value, calendar: .autoupdatingCurrent) }
                            catch { errorMessage = error.localizedDescription }
                        }), displayedComponents: .date)
                } else {
                    Text(verbatim: draft.reportedTestDay?.description ?? "date unavailable")
                    Text("the stored day has been kept. your current time zone cannot represent it; no replacement date was assumed.")
                        .font(.caption)
                }
                Text("record the date as reported. the time of day is not collected.").font(.caption)
                if draft.reportedTestDay == nil {
                    Button("confirm this displayed test date") {
                        do { try draft.setReportedTestDate(draft.testDate, calendar: .autoupdatingCurrent) }
                        catch { errorMessage = error.localizedDescription }
                    }
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
                TextField("sample type (optional)", text: $draft.sampleType)
                TextField("cycle day (optional)", text: $cycleDayText).keyboardType(.numberPad)
                TextField("laboratory reference range (optional)", text: $draft.laboratoryReferenceRange)
                TextField("notes (optional)", text: $draft.notes, axis: .vertical)
                if let errorMessage { Text(errorMessage) }
                WatercolorPrimaryButton(label: "save measurement") {
                    do {
                        let day = cycleDayText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !day.isEmpty && (Int(day) == nil || Int(day)! <= 0) {
                            throw FruitfolioHormoneMeasurementError.invalidRequiredFields
                        }
                        draft.cycleDay = day.isEmpty ? nil : Int(day)
                        try onSave(draft)
                    } catch { errorMessage = error.localizedDescription }
                }
                WatercolorSecondaryButton(label: "cancel") {
                    if hasChanges { confirmDiscard = true } else { onCancel() }
                }
            }
            .padding(20)
            .textFieldStyle(.roundedBorder)
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .interactiveDismissDisabled(hasChanges)
        .confirmationDialog("discard unsaved measurement changes?", isPresented: $confirmDiscard) {
            Button("discard changes", role: .destructive, action: onCancel)
            Button("keep editing", role: .cancel) {}
        }
    }
}

private struct FruitfolioHormoneExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let content = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        data = content
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
