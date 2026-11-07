import SwiftUI
import PhotosUI

struct Prompt10UserMaterialEditor: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    let encyclopediaID: UUID
    let existing: Prompt10SavedPage?
    let onSaved: (Prompt10SavedPage) -> Void
    let onCancel: () -> Void
    @State private var draft: Prompt10UserMaterialDraft
    @State private var chapterID: UUID?
    @State private var errorMessage: String?
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @State private var pendingAction: PendingAction?
    @State private var returnCancelFocus = false
    @State private var popupInstanceID = UUID()
    @AccessibilityFocusState private var cancelFocused: Bool
    @AccessibilityFocusState private var errorFocused: Bool
    @State private var errorFocusRequest = UUID()
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case title, body, source, notes }
    private enum PendingAction { case save, discard }
    @State private var initialDraft: Prompt10UserMaterialDraft
    @State private var initialChapterID: UUID?
    @State private var editingPageID: UUID?
    @State private var editingBaseline: Prompt10UserMaterialEditingBaseline?

    init(store: Prompt10SavedLibraryStore, encyclopediaID: UUID, existing: Prompt10SavedPage? = nil,
         onSaved: @escaping (Prompt10SavedPage) -> Void, onCancel: @escaping () -> Void) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.existing = existing
        self.onSaved = onSaved
        self.onCancel = onCancel
        let initial = existing.map(Prompt10UserMaterialDraft.init(page:)) ?? .init()
        let chapter = existing?.chapterID ?? store.encyclopedia(id: encyclopediaID)?.chapters.sorted { $0.order < $1.order }.first?.id
        _initialDraft = State(initialValue: initial)
        _initialChapterID = State(initialValue: chapter)
        _editingPageID = State(initialValue: existing?.id)
        _editingBaseline = State(initialValue: existing.map(Prompt10UserMaterialEditingBaseline.init(page:)))
        _draft = State(initialValue: initial)
        _chapterID = State(initialValue: chapter)
    }
    private var changed: Bool { draft != initialDraft || chapterID != initialChapterID }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(alignment: .leading, spacing: 12) {
                Prompt10LibraryStorageNotice(store: store)
                Text(editingPageID == nil ? "add my own page" : "edit my page")
                    .font(.headline).accessibilityAddTraits(.isHeader)
                Text("your own material stays separate from Fruitfolio’s approved research. a source address here is user supplied, not verified.")
                    .font(.caption)
                TextField("page title", text: $draft.title)
                    .focused($focusedField, equals: .title)
                    .accessibilityIdentifier("userPage.editor.title")
                    .textFieldStyle(.roundedBorder)
                    .bookLabelGuidance(text: draft.title, maximum: Prompt10BookLabelPolicy.maximumTitleLength)
                Picker("chapter", selection: $chapterID) {
                    Text("choose a chapter").tag(Optional<UUID>.none)
                    ForEach(store.encyclopedia(id: encyclopediaID)?.chapters.sorted { $0.order < $1.order } ?? []) { chapter in
                        Text(chapter.name).tag(Optional(chapter.id))
                    }
                }
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                Text("my text").font(.headline)
                TextEditor(text: $draft.body)
                    .frame(minHeight: 150)
                    .accessibilityLabel("my page text")
                    .accessibilityIdentifier("userPage.editor.body")
                    .focused($focusedField, equals: .body)
                TextField("optional source address", text: $draft.sourceURL)
                    .focused($focusedField, equals: .source)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .keyboardType(.URL).textFieldStyle(.roundedBorder)
                Text("my notes").font(.headline)
                TextEditor(text: $draft.notes)
                    .frame(minHeight: 90).accessibilityLabel("my page notes")
                    .focused($focusedField, equals: .notes)
                if let errorMessage {
                    FruitfolioTranslatedContent(source: errorMessage) { display, _ in
                        FruitfolioSemanticText(markdown: display,
                            baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                            .accessibilityFocused($errorFocused)
                    }
                    .task(id: errorFocusRequest) {
                        await Task.yield()
                        guard !Task.isCancelled, viewIsVisible else { return }
                        errorFocused = true
                    }
                }
                WatercolorPrimaryButton(label: "save my page") { save() }
                    .disabled(chapterID == nil || store.storageProtectionReason != nil)
                    .accessibilityIdentifier("userPage.editor.save")
                WatercolorSecondaryButton(label: "cancel") {
                    if changed { requestClose() } else { onCancel() }
                }
                .accessibilityIdentifier("userPage.editor.cancel")
                .accessibilityFocused($cancelFocused)
            }
            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
        }
        .interactiveDismissDisabled(changed)
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
        }
        .onDisappear {
            viewIsVisible = false
            popupOwner?.cancel()
            pendingAction = nil
            returnCancelFocus = false
        }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            let action = pendingAction
            pendingAction = nil
            switch action {
            case .save: save()
            case .discard: onCancel()
            case nil: break
            }
            if returnCancelFocus { returnCancelFocus = false; cancelFocused = true }
        }
    }

    private func requestClose() {
        guard viewIsVisible, let owner = popupOwner else { return }
        returnCancelFocus = true
        cancelFocused = false
        focusedField = nil
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "save, discard or keep editing your page changes?",
                primaryAction: .init(label: "keep editing") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "save changes") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingAction = .save
                },
                tertiaryAction: .init(label: "discard changes") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingAction = .discard
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "user-page-draft", deduplicationKey: "user-page-draft-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private func save() {
        guard let chapterID else {
            errorMessage = "choose a chapter before saving your page."
            errorFocusRequest = UUID()
            return
        }
        do {
            let saved = try store.saveUserMaterial(draft, to: encyclopediaID, chapterID: chapterID, existingPageID: editingPageID, expectedBaseline: editingBaseline)
            onSaved(saved)
        } catch { errorMessage = error.localizedDescription; errorFocusRequest = UUID() }
    }
}

/// Each image owns its picker selection, so choosing a replacement cannot race
/// another image's tap or inherit a stale target from a cancelled picker.
struct Prompt10ReplaceImagePicker: View {
    let imageID: String
    let onPicked: (PhotosPickerItem, String) -> Void
    @State private var item: PhotosPickerItem?
    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            FruitfolioFixedText(source: "replace image")
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
        }
        .onChange(of: item) { _, selected in
            guard let selected else { return }
            onPicked(selected, imageID)
            item = nil
        }
    }
}
