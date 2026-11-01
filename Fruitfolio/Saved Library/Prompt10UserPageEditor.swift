import SwiftUI
import PhotosUI
import UIKit

struct Prompt10UserPageEditor: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    let encyclopediaID: UUID
    let chapterID: UUID
    let page: Prompt10SavedPage?
    let onSaved: (Prompt10SavedPage) -> Void
    let onCancel: () -> Void

    private let initialDocument: FruitfolioSemanticDocument
    @EnvironmentObject private var motion: MotionPreferences
    @ScaledMetric(relativeTo: .body) private var formatControlWidth: CGFloat = 82
    @State private var title: String
    @State private var document: FruitfolioSemanticDocument
    @State private var imageIDs: [String]
    @State private var importedDuringEdit: Set<String> = []
    @State private var selection = NSRange(location: 0, length: 0)
    @State private var photo: PhotosPickerItem?
    @State private var showUnsaved = false
    @State private var error: String?
    @State private var saved = false
    @State private var photoTask: Task<Void, Never>?

    init(store: Prompt10SavedLibraryStore, encyclopediaID: UUID, chapterID: UUID,
         page: Prompt10SavedPage? = nil, onSaved: @escaping (Prompt10SavedPage) -> Void,
         onCancel: @escaping () -> Void) {
        self.store = store; self.encyclopediaID = encyclopediaID; self.chapterID = chapterID
        self.page = page; self.onSaved = onSaved; self.onCancel = onCancel
        let initial = page?.resolvedSemanticDocument ?? .init(spans: [])
        self.initialDocument = initial
        _title = State(initialValue: page?.question ?? "")
        _document = State(initialValue: initial)
        _imageIDs = State(initialValue: page?.importedImageIDs ?? [])
    }

    private var dirty: Bool {
        title != (page?.question ?? "") || document.plainText != (page?.displayBody ?? "")
        || document.spans.map(\.text) != initialDocument.spans.map(\.text)
        || document.spans.map(\.emphasis) != initialDocument.spans.map(\.emphasis)
        || imageIDs != (page?.importedImageIDs ?? [])
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    BackControl { if dirty || photoTask != nil { showUnsaved = true } else { cancel() } }
                    Text(page == nil ? "my own page" : "edit my page")
                        .font(.custom("Chalkboard SE", size: 22, relativeTo: .title2)).bold()
                    TextField("page title", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .accessibilityIdentifier("userPage.title")
                    Text("my writing").font(.custom("Chalkboard SE", size: 15, relativeTo: .headline))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: min(formatControlWidth, 320)), spacing: 10)], spacing: 10) {
                        formatButton("bold", .anchorBold)
                        formatButton("italic", .spokenItalic)
                        formatButton("underline", .symptomOrPracticalUnderline)
                        formatButton("plain", .plain)
                    }
                    Prompt10SemanticTextEditor(document: $document, selection: $selection)
                        .frame(minHeight: 240)
                        .padding(10)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
                    ForEach(imageIDs, id: \.self) { id in
                        if let data = Prompt10LocalMediaStore.shared.data(for: id), let image = UIImage(data: data) {
                            Image(uiImage: image).resizable().scaledToFit()
                                .accessibilityLabel("my imported image")
                            Button("remove image") { imageIDs.removeAll { $0 == id } }
                                .frame(minHeight: 44)
                        }
                    }
                    PhotosPicker(selection: $photo, matching: .images) {
                        Text("add image").frame(minHeight: 44)
                    }
                    .disabled(photoTask != nil)
                    if let error { Text(error).accessibilityIdentifier("userPage.error") }
                    FruitfolioControlPillButton(label: "save changes", action: save)
                        .disabled(photoTask != nil)
                    WatercolorSecondaryButton(label: "discard changes") {
                        if dirty || photoTask != nil { showUnsaved = true } else { cancel() }
                    }
                }
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                .padding(20).padding(.bottom, 60).frame(maxWidth: 580).frame(maxWidth: .infinity)
            }
            .fruitfolioModalBlur(active: showUnsaved, reduceMotion: motion.reduceMotionActive)
            if showUnsaved {
                Prompt12ConfirmationPopup(assetName: "popup_warning", title: "unsaved changes",
                    message: "would you like to save your changes?", primaryLabel: "save changes",
                    secondaryLabel: "keep editing", destructiveLabel: "discard changes",
                    primaryAction: save, secondaryAction: { showUnsaved = false },
                    destructiveAction: cancel)
            }
        }
        .interactiveDismissDisabled(dirty)
        .onChange(of: photo) { _, value in
            guard let value else { return }
            photoTask?.cancel()
            photoTask = Task { await importPhoto(value); photoTask = nil }
        }
    }

    private func cancel() {
        photoTask?.cancel()
        for id in importedDuringEdit { try? Prompt10LocalMediaStore.shared.delete(id) }
        onCancel()
    }

    private func formatButton(_ label: String, _ emphasis: FruitfolioSemanticEmphasis) -> some View {
        Button(label) {
            if let updated = document.toggling(emphasis, utf16Range: selection) { document = updated }
        }
        .frame(minHeight: 44)
        .disabled(selection.length == 0)
        .accessibilityHint("Formats the selected text")
    }

    private func save() {
        guard photoTask == nil else { error = "please wait for your image to finish importing."; showUnsaved = false; return }
        do {
            let result = try store.saveUserPage(pageID: page?.id, encyclopediaID: encyclopediaID,
                chapterID: chapterID, title: title, document: document, imageIDs: imageIDs)
            saved = true
            for id in importedDuringEdit where !imageIDs.contains(id) { try? Prompt10LocalMediaStore.shared.delete(id) }
            onSaved(result)
        } catch { self.error = error.localizedDescription; showUnsaved = false }
    }

    private func importPhoto(_ item: PhotosPickerItem) async {
        defer { photo = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self), UIImage(data: data) != nil else {
                error = "that image could not be imported."; return
            }
            try Task.checkCancellation()
            let id = try Prompt10LocalMediaStore.shared.stageImageData(data)
            importedDuringEdit.insert(id); imageIDs.append(id)
        } catch { self.error = "that image could not be saved." }
    }
}

struct Prompt10SemanticTextEditor: UIViewRepresentable {
    @Binding var document: FruitfolioSemanticDocument
    @Binding var selection: NSRange

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        context.coordinator.textView = view
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        toolbar.tintColor = UIColor(red: 128.0 / 255, green: 0, blue: 0, alpha: 1)
        toolbar.items = [UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "done", style: .done, target: context.coordinator, action: #selector(Coordinator.finishEditing))]
        view.inputAccessoryView = toolbar
        view.backgroundColor = .clear
        view.adjustsFontForContentSizeCategory = true
        view.accessibilityLabel = "page content"
        view.accessibilityIdentifier = "userPage.content"
        view.attributedText = FruitfolioSemanticAttributedRenderer.render(document, traits: view.traitCollection)
        context.coordinator.lastAppliedDocument = document
        context.coordinator.lastContentSizeCategory = view.traitCollection.preferredContentSizeCategory
        view.typingAttributes = FruitfolioSemanticAttributedRenderer.render(
            .init(spans: [.init(text: " ")]), traits: view.traitCollection).attributes(at: 0, effectiveRange: nil)
        return view
    }
    func updateUIView(_ view: UITextView, context: Context) {
        context.coordinator.parent = self
        // UIKit already contains edits emitted by its delegate. Reapplying the
        // attributed string for each SwiftUI echo can move the insertion point
        // between keystrokes and interleave the user's text.
        guard context.coordinator.lastAppliedDocument != document
                || context.coordinator.lastContentSizeCategory != view.traitCollection.preferredContentSizeCategory else { return }
        let rendered = FruitfolioSemanticAttributedRenderer.render(document, traits: view.traitCollection)
        context.coordinator.lastAppliedDocument = document
        context.coordinator.lastContentSizeCategory = view.traitCollection.preferredContentSizeCategory
        if !view.attributedText.isEqual(to: rendered) {
            let range = view.selectedRange
            context.coordinator.isApplying = true
            view.attributedText = rendered
            if NSMaxRange(range) <= rendered.length { view.selectedRange = range }
            context.coordinator.isApplying = false
        }
    }
    final class Coordinator: NSObject, UITextViewDelegate {
        var isApplying = false
        var lastAppliedDocument: FruitfolioSemanticDocument?
        var lastContentSizeCategory: UIContentSizeCategory?
        weak var textView: UITextView?
        @objc func finishEditing() { textView?.resignFirstResponder() }
        var parent: Prompt10SemanticTextEditor
        init(_ parent: Prompt10SemanticTextEditor) { self.parent = parent }
        func textViewDidChange(_ view: UITextView) {
            guard !isApplying else { return }
            let updated = FruitfolioSemanticAttributedRenderer.document(from: view.attributedText)
            lastAppliedDocument = updated
            parent.document = updated
        }
        func textViewDidChangeSelection(_ view: UITextView) { if !isApplying { parent.selection = view.selectedRange } }
    }
}
