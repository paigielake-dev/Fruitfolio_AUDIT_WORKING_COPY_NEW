import SwiftUI
import UniformTypeIdentifiers

struct FruitfolioHormoneInformationView: View {
    let onBack: () -> Void
    @Environment(\.locale) private var appLocale
    @ObservedObject private var store: FruitfolioHormoneMeasurementStore
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @State private var returnDeletionFocus: DeletionFocus?
    @AccessibilityFocusState private var deletionFocus: DeletionFocus?
    private enum DeletionFocus: Hashable { case delete(UUID), eraseAll, add, reload }
    @State private var popupInstanceID = UUID()

    init(onBack: @escaping () -> Void, store: FruitfolioHormoneMeasurementStore = .shared) {
        self.onBack = onBack
        self.store = store
    }
    @State private var showingLibrary = false
    @State private var filter: FruitfolioMeasuredHormone?
    @State private var editing: FruitfolioHormoneMeasurement?
    @State private var editingIntent: FruitfolioMeasurementSaveIntent?
    @State private var errorMessage: String?
    @State private var showExport = false
    @State private var measurementSavedThisVisit = false
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
                if let reason = store.storageProtectionReason {
                    FruitfolioTranslatedText(source: reason.localizedDescription,
                        font: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                    WatercolorSecondaryButton(label: "reload saved measurements") {
                        measurementSavedThisVisit = false
                        store.reloadSavedMeasurements()
                    }
                        .accessibilityIdentifier("measurements.reloadSavedRecord")
                    .accessibilityFocused($deletionFocus, equals: .reload)
                } else if store.records.isEmpty {
                    Text("have hormone results you’d like to keep track of? add them whenever you’re ready.")
                }
                WatercolorPrimaryButton(label: "Add Measurement") {
                    let record = FruitfolioHormoneMeasurement()
                    editingIntent = .create(record.id)
                    editing = record
                }
                .disabled(store.storageProtectionReason != nil)
                .accessibilityIdentifier("measurements.add")
                .accessibilityFocused($deletionFocus, equals: .add)
                Picker(selection: $filter) {
                    FruitfolioFixedText(source: "all hormones", serious: true).tag(Optional<FruitfolioMeasuredHormone>.none)
                    ForEach(FruitfolioMeasuredHormone.allCases) { hormone in
                        FruitfolioFixedText(source: hormone.label, protectedLiterals: hormone.protectedAbbreviations, serious: true).tag(Optional(hormone))
                    }
                } label: { FruitfolioFixedText(source: "filter by hormone", serious: true) }
                .accessibilityIdentifier("measurements.hormoneFilter")
                ForEach(store.history(hormone: filter)) { measurement in
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            if measurement.hormone == .other {
                                Text(verbatim: measurement.otherHormoneName)
                            } else {
                                FruitfolioFixedText(source: measurement.hormone.label,
                                    protectedLiterals: measurement.hormone.protectedAbbreviations, serious: true)
                            }
                        }.fontWeight(.bold)
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
                        WatercolorSecondaryButton(label: "edit measurement") {
                            editingIntent = .edit(measurement)
                            editing = measurement
                        }
                            .accessibilityIdentifier("measurements.edit." + measurement.id.uuidString)
                            .disabled(store.storageProtectionReason != nil)
                        WatercolorSecondaryButton(label: "delete measurement") { requestDeletion(.one(measurement.id)) }
                            .disabled(store.storageProtectionReason != nil)
                            .accessibilityIdentifier("measurements.delete." + measurement.id.uuidString)
                            .accessibilityFocused($deletionFocus, equals: .delete(measurement.id))
                    }
                    .padding(16)
                    .background(DesignTokens.ColorToken.softWhite, in: RoundedRectangle(cornerRadius: 16))
                }
                Text("Hormone Rhythm shows typical educational patterns. My Measurements contains only values you record. These records do not adjust cycle predictions or confirm ovulation, fertility, or a diagnosis.")
                if measurementSavedThisVisit && !store.records.isEmpty {
                    FruitfolioTranslatedText(source: FruitfolioHormoneAdjustmentPolicy.insufficientMessage,
                        font: .custom("Chalkboard SE", size: 13, relativeTo: .footnote), serious: true)
                }
                WatercolorSecondaryButton(label: "export my measurements") {
                    do {
                        exportDocument = FruitfolioHormoneExportDocument(data: try store.exportJSON())
                        showExport = true
                    } catch { errorMessage = error.localizedDescription }
                }
                .disabled(store.storageProtectionReason != nil || store.records.isEmpty)
                WatercolorSecondaryButton(label: "delete all measurements") { requestDeletion(.all) }
                .disabled(store.records.isEmpty && !store.storageUnreadable)
                .accessibilityIdentifier("measurements.eraseAll")
                .accessibilityFocused($deletionFocus, equals: .eraseAll)
                if let errorMessage {
                    FruitfolioTranslatedText(source: errorMessage,
                        font: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                }
            }
            .padding(20)
            .frame(maxWidth: 620, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .font(.custom("Chalkboard SE", size: 15, relativeTo: .body))
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .sheet(isPresented: $showingLibrary) {
            FruitfolioPresentedPopupHost {
                FruitfolioHormoneLibraryView(onBack: { showingLibrary = false })
            }
        }
        .sheet(item: $editing, onDismiss: { if editing == nil { editingIntent = nil } }) { record in
            FruitfolioPresentedPopupHost {
                FruitfolioHormoneMeasurementEditor(original: record, intent: editingIntent ?? .edit(record),
                    onCancel: { editing = nil; editingIntent = nil }) { updated, intent in
                    try store.save(updated, locale: appLocale, intent: intent)
                    measurementSavedThisVisit = true
                    editing = nil
                    editingIntent = nil
                }
            }
        }
        .fileExporter(isPresented: $showExport, document: exportDocument, contentType: .json,
                      defaultFilename: "Fruitfolio-My-Measurements") { result in
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
        }
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            returnDeletionFocus = nil
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil,
                  popupCoordinator.currentPopup == nil, let requestedFocus = returnDeletionFocus else { return }
            returnDeletionFocus = nil
            if store.storageProtectionReason != nil { deletionFocus = .reload }
            else if case .delete(let id) = requestedFocus, !store.records.contains(where: { $0.id == id }) { deletionFocus = .add }
            else { deletionFocus = requestedFocus }
        }
    }

    private func requestDeletion(_ scope: FruitfolioMeasurementDeletionIntent.Scope) {
        guard viewIsVisible, let owner = popupOwner else { return }
        let intent = FruitfolioMeasurementDeletionIntent(scope: scope, savedRevision: store.savedRecordRevision)
        let all = scope == .all
        switch scope {
        case .one(let id): returnDeletionFocus = .delete(id)
        case .all: returnDeletionFocus = .eraseAll
        }
        deletionFocus = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: all ? "delete all saved hormone measurements from this device? this cannot be undone. other saved Fruitfolio data will be kept."
                    : "delete this saved hormone measurement from this device? this cannot be undone.",
                primaryAction: .init(label: "keep measurements") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: all ? "delete all measurements" : "delete measurement") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    do {
                        try intent.perform(in: store)
                        measurementSavedThisVisit = false
                        returnDeletionFocus = .add
                    } catch {
                        errorMessage = error.localizedDescription
                        returnDeletionFocus = store.storageProtectionReason == nil ? .add : .reload
                    }
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "measurement-deletion", deduplicationKey: "measurement-deletion-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

}

private struct FruitfolioHormoneMeasurementEditor: View {
    @State private var original: FruitfolioHormoneMeasurement
    @State private var saveIntent: FruitfolioMeasurementSaveIntent
    @Environment(\.locale) private var appLocale
    let onCancel: () -> Void
    let onSave: (FruitfolioHormoneMeasurement, FruitfolioMeasurementSaveIntent) throws -> Void
    @State private var draft: FruitfolioHormoneMeasurement
    @State private var cycleDayText: String
    @State private var errorMessage: String?
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @State private var discardAfterDismissal = false
    @State private var returnCancelFocus = false
    @AccessibilityFocusState private var cancelFocused: Bool
    @AccessibilityFocusState private var errorFocused: Bool
    @State private var popupInstanceID = UUID()
    @FocusState private var editorFocus: EditorField?
    private enum EditorField: Hashable { case otherName, result, unit, sample, cycleDay, reference, notes }

    init(original: FruitfolioHormoneMeasurement, intent: FruitfolioMeasurementSaveIntent,
         onCancel: @escaping () -> Void,
         onSave: @escaping (FruitfolioHormoneMeasurement, FruitfolioMeasurementSaveIntent) throws -> Void) {
        var initial = original
        if case .create = intent { try? initial.setReportedTestDate(original.testDate, calendar: .autoupdatingCurrent) }
        _original = State(initialValue: initial)
        _saveIntent = State(initialValue: intent)
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
                Picker(selection: $draft.hormone) {
                    ForEach(FruitfolioMeasuredHormone.allCases) { hormone in
                        FruitfolioFixedText(source: hormone.label, protectedLiterals: hormone.protectedAbbreviations, serious: true).tag(hormone)
                    }
                } label: { FruitfolioFixedText(source: "hormone", serious: true) }
                .accessibilityIdentifier("measurements.editor.hormone")
                if draft.hormone == .other {
                    FruitfolioFixedTextField("other hormone name", text: $draft.otherHormoneName).focused($editorFocus, equals: .otherName)
                        .accessibilityIdentifier("measurements.editor.otherName")
                }
                FruitfolioFixedTextField("numerical result", text: $draft.result).keyboardType(.decimalPad)
                    .accessibilityIdentifier("measurements.editor.result")
                    .focused($editorFocus, equals: .result)
                    .onChange(of: draft.result) { _, _ in
                        if original.result.isEmpty && draft.resultLocaleIdentifier == nil {
                            draft.resultLocaleIdentifier = appLocale.identifier
                        }
                    }
                Picker(selection: $draft.resultLocaleIdentifier) {
                    FruitfolioFixedText(source: "not recorded — preserve original", serious: true).tag(Optional<String>.none)
                    FruitfolioFixedText(source: "point (1.5)", protectedLiterals: ["1.5"], serious: true).tag(Optional("en_US"))
                    FruitfolioFixedText(source: "comma (1,5)", protectedLiterals: ["1,5"], serious: true).tag(Optional("fr_FR"))
                    FruitfolioFixedText(source: "Arabic decimal separator (١٫٥)", protectedLiterals: ["١٫٥"], serious: true).tag(Optional("ar_EG"))
                    if let identifier = draft.resultLocaleIdentifier,
                       !["en_US", "fr_FR", "ar_EG"].contains(identifier) {
                        Group {
                            if let separator = FruitfolioHormoneReportFormat.decimalSeparator(for: identifier) {
                                HStack {
                                    FruitfolioFixedText(source: "recorded format", serious: true)
                                    Text(verbatim: separator)
                                }
                            } else {
                                FruitfolioFixedText(source: "format not recognized — preserve original", serious: true)
                            }
                        }.tag(Optional(identifier))
                    }
                } label: { FruitfolioFixedText(source: "decimal separator on the report", serious: true) }
                .accessibilityIdentifier("measurements.editor.resultFormat")
                FruitfolioFixedTextField("unit, exactly as reported", text: $draft.unit).focused($editorFocus, equals: .unit)
                    .accessibilityIdentifier("measurements.editor.unit")
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
                FruitfolioFixedTextField("sample type (optional)", text: $draft.sampleType).focused($editorFocus, equals: .sample)
                FruitfolioFixedTextField("cycle day (optional)", text: $cycleDayText).keyboardType(.numberPad)
                    .accessibilityIdentifier("measurements.editor.cycleDay")
                    .focused($editorFocus, equals: .cycleDay)
                FruitfolioFixedTextField("laboratory reference range (optional)", text: $draft.laboratoryReferenceRange).focused($editorFocus, equals: .reference)
                FruitfolioFixedTextField("notes (optional)", text: $draft.notes, axis: .vertical)
                    .accessibilityIdentifier("measurements.editor.notes")
                    .focused($editorFocus, equals: .notes)
                if let errorMessage {
                    FruitfolioTranslatedContent(source: errorMessage) { display, _ in
                        FruitfolioSemanticText(markdown: display,
                            baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                            .accessibilityFocused($errorFocused)
                    }
                    .accessibilityIdentifier("measurements.editor.error")
                    .task(id: errorMessage) {
                        errorFocused = false
                        await Task.yield()
                        guard !Task.isCancelled, viewIsVisible, self.errorMessage == errorMessage,
                              popupCoordinator.currentPopup == nil else { return }
                        errorFocused = true
                    }
                }
                WatercolorPrimaryButton(label: "save measurement") {
                    do {
                        draft.cycleDay = try FruitfolioHormoneMeasurement.parseCycleDay(cycleDayText)
                        try onSave(draft, saveIntent)
                    } catch { errorMessage = error.localizedDescription }
                }
                .accessibilityIdentifier("measurements.editor.save")
                WatercolorSecondaryButton(label: "cancel") {
                    if hasChanges { requestDiscard() } else { onCancel() }
                }
                .accessibilityIdentifier("measurements.editor.cancel")
                .accessibilityFocused($cancelFocused)
            }
            .padding(20)
            .textFieldStyle(.roundedBorder)
        }
        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
        .background(DesignTokens.ColorToken.backgroundCream.ignoresSafeArea())
        .accessibilityIdentifier("measurements.editor.scroll")
        .interactiveDismissDisabled(hasChanges)
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            discardAfterDismissal = false
            returnCancelFocus = false
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            if discardAfterDismissal {
                discardAfterDismissal = false
                onCancel()
            } else if returnCancelFocus {
                returnCancelFocus = false
                cancelFocused = true
            }
        }
    }

    private func requestDiscard() {
        guard viewIsVisible, let owner = popupOwner else { return }
        returnCancelFocus = true
        editorFocus = nil
        cancelFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "discard unsaved measurement changes? the saved measurement will be kept unchanged.",
                primaryAction: .init(label: "keep editing") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "discard changes") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    // Finish the actual shared dismissal before closing its native sheet.
                    discardAfterDismissal = true
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "measurement-editor-discard", deduplicationKey: "measurement-discard-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
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
