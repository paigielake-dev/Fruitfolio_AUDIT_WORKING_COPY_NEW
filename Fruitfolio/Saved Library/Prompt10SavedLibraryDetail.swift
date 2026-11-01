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
    @State private var editingChapterID: UUID?
    @State private var managingChapters = false

    private var encyclopedia: Prompt10Encyclopedia? {
        store.encyclopedia(id: encyclopediaID)
    }

    var body: some View {
        Group {
            if let encyclopedia {
                if let selectedPage {
                    Prompt10SavedPageView(
                        store: store,
                        encyclopediaID: encyclopediaID,
                        page: selectedPage,
                        onPageChanged: { updated in self.selectedPage = updated },
                        onBack: {
                            self.selectedPage = nil
                        }
                    )

                } else {
                    encyclopediaContents(
                        encyclopedia
                    )
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

                ZStack {
                    Prompt10LibraryAssetImage(
                        asset: .openBook
                    )
                    .frame(maxWidth: 350)
                    .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(encyclopedia.name)
                            .font(
                                .custom(
                                    "Chalkboard SE",
                                    size: 21
                                )
                            )
                            .fontWeight(.bold)
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 48)
                    }
                }

                FruitfolioControlPillButton(label: "manage chapters") { managingChapters = true }

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
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $managingChapters) {
            Prompt10ChapterManagementView(store: store, encyclopediaID: encyclopediaID)
        }
        .sheet(isPresented: Binding(get: { editingChapterID != nil }, set: { if !$0 { editingChapterID = nil } })) {
            if let chapterID = editingChapterID {
                Prompt10UserPageEditor(store: store, encyclopediaID: encyclopediaID, chapterID: chapterID,
                    onSaved: { page in editingChapterID = nil; selectedPage = page },
                    onCancel: { editingChapterID = nil })
            }
        }
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
                .contentShape(Rectangle())
            }
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion:
                        motionPreferences.reduceMotionActive
                )
            )

            if expanded {
                VStack(spacing: 6) {
                    FruitfolioControlPillButton(label: "add my own page") { editingChapterID = chapter.id }
                        .accessibilityIdentifier("library.addPage.\(chapter.id)")

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
                                        page.isUserAuthored == true ? "my own page" : page.saveType == .excerpt
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

    @EnvironmentObject private var audioManager: AudioManager
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var mediaMessage: String?
    @State private var noteDraft = ""
    @State private var editingPage = false
    @State private var showUnsavedNotes = false
    @State private var showDeletePage = false
    @State private var editAfterNotes = false
    @FocusState private var notesFocused: Bool
    @EnvironmentObject private var motion: MotionPreferences

    var body: some View {
        ZStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ZStack {
                    HStack {
                        BackControl {
                            audioManager.play(.buttonSoftPop)
                            editAfterNotes = false
                            notesFocused = false
                            if noteDraft != page.notes { showUnsavedNotes = true } else { onBack() }
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

                FruitfolioSemanticText(document: page.resolvedSemanticDocument,
                    baseFont: .custom("Chalkboard SE", size: 14, relativeTo: .body))
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

                if page.isUserAuthored == true {
                    FruitfolioControlPillButton(label: "edit my page") {
                        editAfterNotes = true; notesFocused = false
                        if noteDraft != page.notes { showUnsavedNotes = true } else { editingPage = true }
                    }
                }
                notesSection
                importedImagesSection
                WatercolorSecondaryButton(label: "delete saved page") {
                    notesFocused = false; showDeletePage = true
                }

                if !page.sourceIDs.isEmpty {
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
        .fruitfolioModalBlur(active: showUnsavedNotes || showDeletePage, reduceMotion: motion.reduceMotionActive)
        if showDeletePage {
            Prompt12ConfirmationPopup(assetName: "popup_warning", title: "delete saved page?",
                message: "this removes this page and its notes from this encyclopedia, including any unsaved notes. other saved copies stay in their own books.",
                primaryLabel: "keep page", secondaryLabel: nil, destructiveLabel: "delete page",
                primaryAction: { showDeletePage = false }, secondaryAction: nil, destructiveAction: deletePage)
        }
        if showUnsavedNotes {
            Prompt12ConfirmationPopup(assetName: "popup_warning", title: "unsaved changes",
                message: "would you like to save your notes?", primaryLabel: "save notes",
                secondaryLabel: "keep editing", destructiveLabel: "discard changes",
                primaryAction: { if saveNotes() { continueAfterNotes() } },
                secondaryAction: { showUnsavedNotes = false }, destructiveAction: {
                    noteDraft = page.notes; showUnsavedNotes = false; continueAfterNotes()
                })
        }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if notesFocused { Spacer(); Button("done") { notesFocused = false } }
            }
        }
        .sheet(isPresented: $editingPage) {
            Prompt10UserPageEditor(store: store, encyclopediaID: encyclopediaID, chapterID: page.chapterID,
                page: page, onSaved: { updated in onPageChanged(updated); editingPage = false },
                onCancel: { editingPage = false })
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("my notes")
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .headline))
                .fontWeight(.bold)
            TextEditor(text: $noteDraft)
                .focused($notesFocused)
                .accessibilityIdentifier("savedPage.notes")
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
                .frame(minHeight: 110)
                .padding(8)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            Button("save notes") { _ = saveNotes() }
            .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
        }
        .onAppear { noteDraft = page.notes }
    }

    private func deletePage() {
        do {
            try store.deletePage(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id)
            for id in page.importedImageIDs ?? [] where !store.imageIsReferenced(id) {
                try? Prompt10LocalMediaStore.shared.delete(id)
            }
            showDeletePage = false
            onBack()
        } catch {
            showDeletePage = false
            mediaMessage = "that page could not be deleted."
        }
    }

    private func continueAfterNotes() {
        if editAfterNotes { editingPage = true } else { onBack() }
    }

    @discardableResult
    private func saveNotes() -> Bool {
        do {
            try store.updatePageNotes(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, notes: noteDraft)
            var updated = page
            updated.notes = noteDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            noteDraft = updated.notes
            onPageChanged(updated)
            mediaMessage = "notes saved!"
            showUnsavedNotes = false
            return true
        } catch {
            showUnsavedNotes = false
            mediaMessage = "those notes could not be saved. your writing is still here."
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
                if let data = Prompt10LocalMediaStore.shared.data(for: imageID),
                   let image = UIImage(data: data) {
                    VStack(spacing: 6) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .accessibilityLabel("user imported image")

                        Button("remove image") { removeImage(imageID) }
                            .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                    }
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text("add image")
                    .font(.custom("Chalkboard SE", size: 13, relativeTo: .headline))
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task { await importImage(item) }
            }

            if let mediaMessage {
                Text(mediaMessage)
                    .font(.custom("Chalkboard SE", size: 11, relativeTo: .caption))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func importImage(_ item: PhotosPickerItem) async {
        defer { selectedPhotoItem = nil }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                mediaMessage = "that image could not be imported."
                return
            }
            let id = try Prompt10LocalMediaStore.shared.saveImageData(data)
            var ids = page.importedImageIDs ?? []
            ids.append(id)
            try store.setImportedImageIDs(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, imageIDs: ids)
            var updated = page
            updated.importedImageIDs = ids
            onPageChanged(updated)
            mediaMessage = "image added!"
        } catch {
            mediaMessage = "that image could not be imported."
        }
    }

    private func removeImage(_ id: String) {
        do {
            var ids = page.importedImageIDs ?? []
            ids.removeAll { $0 == id }
            try store.setImportedImageIDs(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, imageIDs: ids)
            if !store.imageIsReferenced(id) { try Prompt10LocalMediaStore.shared.delete(id) }
            var updated = page
            updated.importedImageIDs = ids
            onPageChanged(updated)
            mediaMessage = "image removed."
        } catch {
            mediaMessage = "that image could not be removed."
        }
    }
}
