import SwiftUI
import PhotosUI
import UIKit

struct Prompt10EncyclopediaDetailView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onBack: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var selectedPage: Prompt10SavedPage?
    @State private var expandedChapterIDs: Set<UUID> = []
    @State private var showingMaterialEditor = false
    @State private var materialToEdit: Prompt10SavedPage?

    private var encyclopedia: Prompt10Encyclopedia? {
        store.encyclopedia(id: encyclopediaID)
    }

    var body: some View {
        Group {
            if let encyclopedia {
                GeometryReader { geometry in
                    HStack(alignment: .top, spacing: max(12, geometry.size.width * 0.05)) {
                        encyclopediaContents(encyclopedia)
                            .allowsHitTesting(selectedPage == nil)
                            .accessibilityHidden(selectedPage != nil)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("contents, left book page")
                        Group {
                            if let selectedPage {
                                Prompt10SavedPageView(store: store, encyclopediaID: encyclopediaID, page: selectedPage,
                                    onPageChanged: { updated in self.selectedPage = updated },
                                    onBack: { self.selectedPage = nil },
                                    onEditUserMaterial: { page in materialToEdit = page; showingMaterialEditor = true })
                            } else {
                                ScrollView {
                                    Text("choose a saved page from the contents to read it here.")
                                        .font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                                        .padding(.vertical, 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("saved content, right book page")
                    }
                }
            }
        }
        .fruitfolioModalBlur(active: showingMaterialEditor, reduceMotion: motionPreferences.reduceMotionActive)
        .overlay {
            if showingMaterialEditor {
                ZStack {
                DesignTokens.ColorToken.backgroundCream.opacity(FruitfolioModalBlurSpec.dimOpacity).ignoresSafeArea().allowsHitTesting(false)
                Prompt10UserMaterialEditor(store: store, encyclopediaID: encyclopediaID, existing: materialToEdit,
                    onSaved: { page in selectedPage = page; showingMaterialEditor = false; materialToEdit = nil },
                    onCancel: { showingMaterialEditor = false; materialToEdit = nil })
                }
            }
        }
    }

    private func encyclopediaContents(
        _ encyclopedia: Prompt10Encyclopedia
    ) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                detailHeader(
                    encyclopedia
                )

                Text(encyclopedia.name)
                    .font(.custom("Chalkboard SE", size: 21, relativeTo: .title2).bold())
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button("add my own page") {
                    materialToEdit = nil
                    showingMaterialEditor = true
                }
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .disabled(encyclopedia.chapters.isEmpty)

                if encyclopedia.chapters.isEmpty {
                    Text("this little book is ready for saved pages ♡")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13
                            )
                        )
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 18)

                } else {
                    VStack(spacing: 12) {
                        ForEach(
                            encyclopedia.chapters.sorted {
                                $0.order < $1.order
                            }
                        ) { chapter in
                            chapterSection(
                                chapter
                            )
                        }
                    }
                }


            }
            .padding(.horizontal, 4)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            // A saved encyclopedia should never open looking empty when it already
            // contains pages. Expand populated chapters by default; the user can
            // still collapse any chapter afterward.
            if expandedChapterIDs.isEmpty {
                expandedChapterIDs = Set(
                    encyclopedia.chapters
                        .filter { !$0.pages.isEmpty }
                        .map(\.id)
                )
            }
        }
    }

    private func detailHeader(
        _ encyclopedia: Prompt10Encyclopedia
    ) -> some View {
        VStack(spacing: 8) {
            ZStack {
                HStack {
                    BackControl {
                        audioManager.play(.buttonSoftPop)
                        onBack()
                    }

                    Spacer()
                }

                Text("encyclopedia")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 18
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
            }

            HStack(spacing: 12) {
                Button("rename") {
                    audioManager.play(.buttonSoftPop)
                    onRename()
                }
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 11
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion:
                            motionPreferences.reduceMotionActive
                    )
                )
                .frame(
                    minHeight:
                        DesignTokens.Layout.minimumHitTarget
                )

                Button("delete") {
                    audioManager.play(.buttonSoftPop)
                    onDelete()
                }
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 11
                    )
                )
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion:
                            motionPreferences.reduceMotionActive
                    )
                )
                .frame(
                    minHeight:
                        DesignTokens.Layout.minimumHitTarget
                )
            }
        }
        .padding(.top, 10)
    }

    private func chapterSection(
        _ chapter: Prompt10Chapter
    ) -> some View {
        let expanded = expandedChapterIDs.contains(chapter.id)

        return VStack(spacing: 8) {
            Button {
                if expanded {
                    expandedChapterIDs.remove(chapter.id)
                } else {
                    expandedChapterIDs.insert(chapter.id)
                }
            } label: {
                HStack {
                    Image("library_label")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42)
                        .accessibilityHidden(true)

                    Text(chapter.name)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 14
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )

                    Spacer()

                    Text("\(chapter.pages.count)")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 11
                            )
                        )
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }
                .frame(
                    minHeight:
                        DesignTokens.Layout.minimumHitTarget
                )
            }
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion:
                        motionPreferences.reduceMotionActive
                )
            )

            if expanded {
                VStack(spacing: 6) {
                    ForEach(
                        chapter.pages.sorted {
                            $0.order < $1.order
                        }
                    ) { page in
                        Button {
                            selectedPage = page
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image("library_bookmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(
                                        page.question.isEmpty
                                            ? "saved page"
                                            : page.question
                                    )
                                    .font(
                                        .custom(
                                            "Chalkboard SE",
                                            size: 12.5
                                        )
                                    )
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        DesignTokens.ColorToken.primaryBurgundy
                                    )
                                    .lineLimit(2)

                                    Text(
                                        page.saveType == .excerpt
                                            ? "saved excerpt"
                                            : "complete saved answer"
                                    )
                                    .font(
                                        .custom(
                                            "Chalkboard SE",
                                            size: 9.5
                                        )
                                    )
                                    .foregroundStyle(
                                        DesignTokens.ColorToken.secondaryBurgundy
                                    )
                                }

                                Spacer()
                            }
                            .frame(
                                minHeight:
                                    DesignTokens.Layout.minimumHitTarget
                            )
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion:
                                    motionPreferences.reduceMotionActive
                            )
                        )
                    }
                }
                .transition(.opacity)
            }
        }
        .padding(.vertical, 4)
    }
}

struct Prompt10SavedPageView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    let encyclopediaID: UUID
    let page: Prompt10SavedPage
    let onPageChanged: (Prompt10SavedPage) -> Void
    let onBack: () -> Void
    var onEditUserMaterial: ((Prompt10SavedPage) -> Void)? = nil

    @EnvironmentObject private var audioManager: AudioManager
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var imageImportTask: Task<Void, Never>?
    @State private var imageImportGeneration = UUID()
    @State private var mediaMessage: String?
    @State private var notes = Prompt10NoteDraft()
    @State private var confirmDiscardNotes = false

    private var hasUnsavedNotes: Bool { notes.hasChanges }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    HStack {
                        BackControl {
                            audioManager.play(.buttonSoftPop)
                            if hasUnsavedNotes { confirmDiscardNotes = true } else { onBack() }
                        }

                        Spacer()
                    }

                    Text("saved page")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 18
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                }

                Text(page.question)
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 17
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                if !page.displayBody.isEmpty {
                FruitfolioTranslatedText(
                    source: page.displayBody, protectedLiterals: page.sourceIDs,
                    enabled: page.allowsAutomaticDisplayTranslation,
                    font: .custom("Chalkboard SE", size: 14, relativeTo: .body),
                    sourceLanguage: page.displaySourceLanguage,
                    semanticSpans: page.displaySemanticSpans, sourceRecords: page.sourceRecords ?? []
                )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 14
                        )
                    )
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .textSelection(.enabled)

                }

                FruitfolioSavedScientificIllustrations(assetIDs: page.educationalAssetIDs ?? [])
                if let provenance = page.userMaterial {
                    Text("your own material · not verified research")
                        .font(.caption).bold()
                    if let address = provenance.sourceURL {
                        Text(verbatim: address).font(.caption).textSelection(.enabled)
                    }
                    if let onEditUserMaterial {
                        Button("edit my page") {
                            if hasUnsavedNotes { mediaMessage = "save or discard your note changes before editing this page." }
                            else { onEditUserMaterial(page) }
                        }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                    }
                }
                notesSection
                importedImagesSection

                if let records = page.sourceRecords, !records.isEmpty {
                    FruitfolioSourceCitationList(sources: records)
                } else if !page.sourceIDs.isEmpty {
                    Divider()
                        .overlay(
                            DesignTokens.ColorToken.primaryBurgundy.opacity(0.18)
                        )

                    Text("sources")
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 13
                            )
                        )
                        .fontWeight(.bold)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )

                    ForEach(
                        Array(page.sourceIDs.enumerated()),
                        id: \.offset
                    ) { _, sourceID in
                        Text(sourceID)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 11
                                )
                            )
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        .onDisappear { cancelImageImport() }
        .onChange(of: page.id) { _, _ in
            cancelImageImport()
            loadNotesIfNeeded()
        }
        .onAppear { loadNotesIfNeeded() }
        .onChange(of: page.notes) { _, _ in loadNotesIfNeeded() }
        .interactiveDismissDisabled(hasUnsavedNotes)
        .confirmationDialog("save your note changes?", isPresented: $confirmDiscardNotes, titleVisibility: .visible) {
            Button("save and go back") { if saveNotes() { onBack() } }
            Button("discard changes", role: .destructive) {
                notes.discard()
                onBack()
            }
            Button("keep editing", role: .cancel) {}
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("my notes")
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .headline))
                .fontWeight(.bold)
            TextEditor(text: $notes.text)
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
                .frame(minHeight: 110)
                .padding(8)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            Button("save notes") { _ = saveNotes() }
            .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
        }

    }

    private func loadNotesIfNeeded() {
        // Re-rendering after an image import must not overwrite an active draft.
        notes.load(pageID: page.id, notes: page.notes)
    }

    @discardableResult
    private func saveNotes() -> Bool {
        do {
            try store.updatePageNotes(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, notes: notes.text)
            notes.didSave()
            // Preserve concurrently attached images and other persisted fields.
            if let updated = store.encyclopedia(id: encyclopediaID)?.chapters
                .first(where: { $0.id == page.chapterID })?.pages.first(where: { $0.id == page.id }) {
                onPageChanged(updated)
            }
            mediaMessage = "notes saved!"
            return true
        } catch {
            mediaMessage = "those notes could not be saved."
            return false
        }
    }

    @ViewBuilder
    private var importedImagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("my images")
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .headline))
                .fontWeight(.bold)
                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)

            ForEach(page.importedImageIDs ?? [], id: \.self) { imageID in
                VStack(spacing: 6) {
                    Prompt10ImportedImage(imageID: imageID)
                    Prompt10ReplaceImagePicker(imageID: imageID) { item, target in
                        beginImageImport(item, replacing: target)
                    }
                    Button("remove image") { removeImage(imageID) }
                        .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("add image")
                    .font(.custom("Chalkboard SE", size: 13, relativeTo: .headline))
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                beginImageImport(item, replacing: nil)
            }

            if let mediaMessage {
                Text(mediaMessage)
                    .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func cancelImageImport() {
        imageImportGeneration = UUID()
        imageImportTask?.cancel()
        imageImportTask = nil
        selectedPhotoItem = nil
    }

    private func beginImageImport(_ item: PhotosPickerItem, replacing imageID: String?) {
        imageImportTask?.cancel()
        imageImportGeneration = UUID()
        let generation = imageImportGeneration
        imageImportTask = Task { await importImage(item, generation: generation, replacing: imageID) }
    }

    private func importImage(_ item: PhotosPickerItem, generation: UUID, replacing replacedID: String?) async {
        defer {
            if imageImportGeneration == generation {
                selectedPhotoItem = nil
                imageImportTask = nil
            }
        }
        var writtenID: String?
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw Prompt10ImagePreparationError.invalidImage
            }
            try Task.checkCancellation()
            guard imageImportGeneration == generation else { return }
            let prepared = try await Prompt10ImagePreparation.prepare(data)
            try Task.checkCancellation()
            guard imageImportGeneration == generation else { return }
            let id = try await Task.detached(priority: .utility) {
                try Prompt10LocalMediaStore.shared.saveImageData(prepared)
            }.value
            writtenID = id
            try Task.checkCancellation()
            guard imageImportGeneration == generation else { throw CancellationError() }
            // Read current store state after the await; a stale view snapshot
            // must not overwrite images or edits made while the picker loaded.
            guard let latest = store.encyclopedia(id: encyclopediaID)?.chapters
                .first(where: { $0.id == page.chapterID })?.pages.first(where: { $0.id == page.id }) else {
                throw Prompt10LibraryError.pageNotFound
            }
            let ids = try Prompt10ImageAttachmentMutation.attaching(id, replacing: replacedID, to: latest.importedImageIDs ?? [])
            try store.setImportedImageIDs(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, imageIDs: ids)
            writtenID = nil
            var updated = latest
            updated.importedImageIDs = ids
            onPageChanged(updated)
            mediaMessage = replacedID == nil ? "image added!" : "image replaced!"
            if let replacedID, !Prompt10MediaReferences.contains(replacedID, in: store.encyclopedias) {
                // Persist and refresh first; file cleanup must not turn a saved
                // attachment change into an apparent rollback.
                _ = await Task.detached(priority: .utility) { try? Prompt10LocalMediaStore.shared.delete(replacedID) }.value
            }
        } catch {
            if let orphan = writtenID {
                _ = await Task.detached(priority: .utility) { try? Prompt10LocalMediaStore.shared.delete(orphan) }.value
            }
            guard !Task.isCancelled, imageImportGeneration == generation else { return }
            mediaMessage = "that image could not be imported."
        }
    }

    private func removeImage(_ id: String) {
        do {
            guard let latest = store.encyclopedia(id: encyclopediaID)?.chapters
                .first(where: { $0.id == page.chapterID })?.pages.first(where: { $0.id == page.id }) else {
                throw Prompt10LibraryError.pageNotFound
            }
            var ids = latest.importedImageIDs ?? []
            ids.removeAll { $0 == id }
            try store.setImportedImageIDs(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, imageIDs: ids)
            var updated = latest
            updated.importedImageIDs = ids
            onPageChanged(updated)
            mediaMessage = "image removed."
            // Detaching is already committed. Cleanup failures must not leave
            // the screen displaying the removed image as if persistence failed.
            if !Prompt10MediaReferences.contains(id, in: store.encyclopedias) {
                try? Prompt10LocalMediaStore.shared.delete(id)
            }
        } catch {
            mediaMessage = "that image could not be removed."
        }
    }
}
