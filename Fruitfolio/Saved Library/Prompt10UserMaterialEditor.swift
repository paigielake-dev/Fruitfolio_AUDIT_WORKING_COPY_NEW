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
    @State private var confirmDiscard = false
    private let initialDraft: Prompt10UserMaterialDraft
    private let initialChapterID: UUID?

    init(store: Prompt10SavedLibraryStore, encyclopediaID: UUID, existing: Prompt10SavedPage? = nil,
         onSaved: @escaping (Prompt10SavedPage) -> Void, onCancel: @escaping () -> Void) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.existing = existing
        self.onSaved = onSaved
        self.onCancel = onCancel
        let initial = existing.map(Prompt10UserMaterialDraft.init(page:)) ?? .init()
        let chapter = existing?.chapterID ?? store.encyclopedia(id: encyclopediaID)?.chapters.sorted { $0.order < $1.order }.first?.id
        initialDraft = initial
        initialChapterID = chapter
        _draft = State(initialValue: initial)
        _chapterID = State(initialValue: chapter)
    }
    private var changed: Bool { draft != initialDraft || chapterID != initialChapterID }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(alignment: .leading, spacing: 12) {
                Text(existing == nil ? "add my own page" : "edit my page")
                    .font(.headline).accessibilityAddTraits(.isHeader)
                Text("your own material stays separate from Fruitfolio’s approved research. a source address here is user supplied, not verified.")
                    .font(.caption)
                TextField("page title", text: $draft.title)
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
                TextField("optional source address", text: $draft.sourceURL)
                    .textInputAutocapitalization(.never).autocorrectionDisabled()
                    .keyboardType(.URL).textFieldStyle(.roundedBorder)
                Text("my notes").font(.headline)
                TextEditor(text: $draft.notes)
                    .frame(minHeight: 90).accessibilityLabel("my page notes")
                if let errorMessage { Text(errorMessage).foregroundStyle(Color.red).accessibilityAddTraits(.isStaticText) }
                WatercolorPrimaryButton(label: "save my page") { save() }
                    .disabled(chapterID == nil)
                WatercolorSecondaryButton(label: "cancel") {
                    if changed { confirmDiscard = true } else { onCancel() }
                }
            }
            .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
        }
        .interactiveDismissDisabled(changed)
        .confirmationDialog("save or discard your page changes?", isPresented: $confirmDiscard, titleVisibility: .visible) {
            Button("save changes") { save() }
            Button("discard changes", role: .destructive) { onCancel() }
            Button("keep editing", role: .cancel) {}
        }
    }

    private func save() {
        guard let chapterID else { return }
        do {
            let saved = try store.saveUserMaterial(draft, to: encyclopediaID, chapterID: chapterID, existingPageID: existing?.id)
            onSaved(saved)
        } catch { errorMessage = error.localizedDescription }
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
            Text("replace image").frame(minHeight: DesignTokens.Layout.minimumHitTarget)
        }
        .onChange(of: item) { _, selected in
            guard let selected else { return }
            onPicked(selected, imageID)
            item = nil
        }
    }
}
