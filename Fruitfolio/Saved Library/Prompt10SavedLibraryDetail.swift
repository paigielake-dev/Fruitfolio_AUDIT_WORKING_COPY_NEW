import SwiftUI
import PhotosUI
import UIKit

struct Prompt10EncyclopediaDetailView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onBack: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.layoutDirection) private var layoutDirection
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var selectedPage: Prompt10SavedPage?
    @State private var expandedChapterIDs: Set<UUID> = []
    @State private var showingMaterialEditor = false
    @State private var materialToEdit: Prompt10SavedPage?
    @AccessibilityFocusState private var focusedPageID: UUID?

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
                            .modifier(FruitfolioFixedAccessibilityLabel(source: layoutDirection == .rightToLeft
                                ? "contents, right book page" : "contents, left book page"))
                            .accessibilityIdentifier("savedBook.contents")
                        Group {
                            if let selectedPage {
                                Prompt10SavedPageView(store: store, encyclopediaID: encyclopediaID, page: selectedPage,
                                    onPageChanged: { updated in self.selectedPage = updated },
                                    onBack: {
                                        self.selectedPage = nil
                                        focusedPageID = selectedPage.id
                                    },
                                    onEditUserMaterial: { page in materialToEdit = page; showingMaterialEditor = true })
                            } else {
                                ScrollView {
                                    FruitfolioFixedText(source: "choose a saved page from the contents to read it here.",
                                        font: .custom("Chalkboard SE", size: 14, relativeTo: .body),
                                        color: DesignTokens.ColorToken.primaryBurgundy)
                                        .accessibilityIdentifier("savedBook.choosePage")
                                        .padding(.vertical, 24)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityElement(children: .contain)
                        .modifier(FruitfolioFixedAccessibilityLabel(source: layoutDirection == .rightToLeft
                            ? "saved content, left book page" : "saved content, right book page"))
                        .accessibilityIdentifier("savedBook.savedContent")
                    }
                }
            }
        }
        .fruitfolioModalBlur(active: showingMaterialEditor, reduceMotion: motionPreferences.reduceMotionActive)
        .overlay {
            if showingMaterialEditor {
                ZStack {
                FruitfolioModalBackdrop().allowsHitTesting(false)
                FruitfolioPresentedPopupHost {
                    Prompt10UserMaterialEditor(store: store, encyclopediaID: encyclopediaID, existing: materialToEdit,
                        onSaved: { page in selectedPage = page; showingMaterialEditor = false; materialToEdit = nil },
                        onCancel: { showingMaterialEditor = false; materialToEdit = nil })
                }
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

                Text(verbatim: encyclopedia.name)
                    .accessibilityIdentifier("savedBook.title")
                    .font(.custom("Chalkboard SE", size: 21, relativeTo: .title2).bold())
                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    materialToEdit = nil
                    showingMaterialEditor = true
                } label: { FruitfolioFixedText(source: "add my own page") }
                .accessibilityIdentifier("savedBook.addOwnPage")
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .disabled(encyclopedia.chapters.isEmpty)

                if encyclopedia.chapters.isEmpty {
                    FruitfolioFixedText(source: "this little book is ready for saved pages ♡", protectedLiterals: ["♡"],
                        font: .custom("Chalkboard SE", size: 13),
                        color: DesignTokens.ColorToken.secondaryBurgundy)
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
            HStack(spacing: 8) {
                BackControl { onBack() }
                    .accessibilityIdentifier("savedBook.back")
                FruitfolioFixedText(source: "encyclopedia",
                    font: .custom("Chalkboard SE", size: 18).bold(),
                    color: DesignTokens.ColorToken.primaryBurgundy)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("savedBook.heading")
                Color.clear.frame(width: DesignTokens.Layout.minimumHitTarget, height: 1)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 12) {
                Button {
                    audioManager.play(.buttonSoftPop)
                    onRename()
                } label: {
                    FruitfolioFixedText(source: "rename", font: .custom("Chalkboard SE", size: 11).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)
                }
                .accessibilityIdentifier("savedBook.rename")
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

                Button {
                    audioManager.play(.buttonSoftPop)
                    onDelete()
                } label: {
                    FruitfolioFixedText(source: "delete", font: .custom("Chalkboard SE", size: 11),
                        color: DesignTokens.ColorToken.secondaryBurgundy)
                }
                .accessibilityIdentifier("savedBook.delete")
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

                    Text(verbatim: chapter.name)
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

                    Text(verbatim: chapter.pages.count.formatted(.number.locale(Locale(identifier: settings.language.localeIdentifier))))
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
            .accessibilityIdentifier("savedBook.chapter." + chapter.id.uuidString)
            .modifier(FruitfolioFixedAccessibilityValue(source: expanded ? "expanded" : "collapsed"))
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
                            focusedPageID = nil
                            selectedPage = page
                        } label: {
                            HStack(alignment: .top, spacing: 10) {
                                Image("library_bookmark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22)
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 3) {
                                    Group {
                                        if page.question.isEmpty {
                                            FruitfolioFixedText(source: "saved page",
                                                font: .custom("Chalkboard SE", size: 12.5).bold(),
                                                color: DesignTokens.ColorToken.primaryBurgundy)
                                        } else {
                                            Text(verbatim: page.question)
                                                .font(.custom("Chalkboard SE", size: 12.5).bold())
                                                .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                                        }
                                    }
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)

                                    FruitfolioFixedText(source:
                                        page.userMaterial != nil ? "your own page"
                                            : (page.saveType == .excerpt ? "saved excerpt" : "complete saved answer"),
                                        font: .custom("Chalkboard SE", size: 9.5),
                                        color: DesignTokens.ColorToken.secondaryBurgundy)

                                }

                                Spacer()
                            }
                            .frame(
                                minHeight:
                                    DesignTokens.Layout.minimumHitTarget
                            )
                            .padding(.vertical, 4)
                        }
                        .accessibilityIdentifier("savedBook.page." + page.id.uuidString)
                        .accessibilityFocused($focusedPageID, equals: page.id)
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
    @State private var mediaMessage: Prompt10SavedPageNotice?
    @State private var notes = Prompt10NoteDraft()
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var popupOwner: FruitfolioOwnedPopupSession?
    @State private var viewIsVisible = false
    @State private var pendingNoteAction: NoteAction?
    @State private var returnBackFocus = false
    @State private var popupInstanceID = UUID()
    @State private var excerptCleanupCompleted = false
    @State private var pendingExcerptCleanup: Prompt10SavedPage?
    @AccessibilityFocusState private var excerptReviewFocused: Bool
    @State private var returnExcerptReviewFocus = false
    @State private var notesMessage: Prompt10SavedPageNotice?
    @State private var notesFocusRequest = UUID()
    @AccessibilityFocusState private var backFocused: Bool
    @AccessibilityFocusState private var notesMessageFocused: Bool
    @FocusState private var notesFocused: Bool
    private enum NoteAction { case save, discard }

    private var hasUnsavedNotes: Bool { notes.hasChanges }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 8) {
                    BackControl {
                        if hasUnsavedNotes { requestBack() } else { onBack() }
                    }
                    .accessibilityIdentifier("savedPage.back")
                    .accessibilityFocused($backFocused)

                    FruitfolioFixedText(source: "saved page",
                        font: .custom("Chalkboard SE", size: 18).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("savedPage.heading")
                    Color.clear.frame(width: DesignTokens.Layout.minimumHitTarget, height: 1)
                        .accessibilityHidden(true)
                }

                Text(verbatim: page.question)
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
                    FruitfolioFixedText(source: "your own material · not verified research", font: .caption.bold(), serious: true)
                        .accessibilityIdentifier("savedPage.userMaterialQualifier")
                    if let address = provenance.sourceURL {
                        Text(verbatim: address).font(.caption).textSelection(.enabled)
                    }
                    if let onEditUserMaterial {
                        WatercolorSecondaryButton(label: "edit my page") {
                            if hasUnsavedNotes { mediaMessage = .saveDraftBeforeEditing }
                            else { onEditUserMaterial(page) }
                        }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                        .accessibilityIdentifier("savedPage.editOwnPage")
                        .controlSize(.small)
                    }
                }
                legacyExcerptReview
                notesSection
                importedImagesSection

                if page.userMaterial == nil, let notice = page.evidenceSupport?.restricted(to: page.saveType).notice {
                    FruitfolioFixedText(source: notice, font: .caption, color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
                        .accessibilityIdentifier("savedPage.evidenceSupport")
                }
                if let records = page.sourceRecords, !records.isEmpty {
                    FruitfolioSourceCitationList(sources: records)
                } else if !page.sourceIDs.isEmpty {
                    Divider()
                        .overlay(
                            DesignTokens.ColorToken.primaryBurgundy.opacity(0.18)
                        )

                    FruitfolioFixedText(source: "sources",
                        font: .custom("Chalkboard SE", size: 13).bold(),
                        color: DesignTokens.ColorToken.primaryBurgundy)

                    ForEach(
                        Array(page.sourceIDs.enumerated()),
                        id: \.offset
                    ) { _, sourceID in
                        Text(verbatim: sourceID)
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
        .accessibilityIdentifier("savedPage.scroll")
        .onDisappear {
            viewIsVisible = false
            cancelImageImport()
            popupOwner?.cancel()
            pendingNoteAction = nil
            pendingExcerptCleanup = nil
            excerptCleanupCompleted = false
            returnExcerptReviewFocus = false
            returnBackFocus = false
        }
        .onChange(of: page.id) { _, _ in
            cancelImageImport()
            popupOwner?.cancel()
            pendingNoteAction = nil
            pendingExcerptCleanup = nil
            excerptCleanupCompleted = false
            returnExcerptReviewFocus = false
            returnBackFocus = false
            notesMessage = nil
            loadNotesIfNeeded()
        }
        .onAppear {
            viewIsVisible = true
            if popupOwner == nil { popupOwner = FruitfolioOwnedPopupSession(coordinator: popupCoordinator) }
            loadNotesIfNeeded()
        }
        .onChange(of: page.notes) { _, _ in loadNotesIfNeeded() }
        .onChange(of: notes.text) { _, _ in
            if notesMessage == .notesSaved { notesMessage = nil }
        }
        .interactiveDismissDisabled(hasUnsavedNotes)
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in
            popupOwner?.observeDismissal()
            guard viewIsVisible, popupOwner?.requestID == nil, popupCoordinator.currentPopup == nil else { return }
            if let expected = pendingExcerptCleanup {
                pendingExcerptCleanup = nil
                guard expected.id == page.id else { return }
                do {
                    let updated = try store.removeLegacyExcerptRemainder(afterConfirming: expected)
                    onPageChanged(updated)
                    excerptCleanupCompleted = true
                } catch { mediaMessage = Prompt10SavedPageNotice(error: error) }
            }
            if returnExcerptReviewFocus {
                returnExcerptReviewFocus = false
                excerptReviewFocused = true
            }
            let action = pendingNoteAction
            pendingNoteAction = nil
            switch action {
            case .save:
                returnBackFocus = false
                if saveNotes() { onBack() }
            case .discard:
                returnBackFocus = false
                notes.discard()
                onBack()
            case nil: break
            }
            if returnBackFocus { returnBackFocus = false; backFocused = true }
        }
    }

    private func requestBack() {
        guard viewIsVisible, let owner = popupOwner else { return }
        returnBackFocus = true
        backFocused = false
        notesFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "save, discard or keep editing your note changes? the saved page text and its source details will be kept.",
                primaryAction: .init(label: "keep editing") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "save and go back") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingNoteAction = .save
                },
                tertiaryAction: .init(label: "discard changes") {
                    guard viewIsVisible, owner.consumeAction(for: id) else { return }
                    pendingNoteAction = .discard
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "saved-note-draft", deduplicationKey: "saved-note-draft-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    @ViewBuilder
    private var legacyExcerptReview: some View {
        if excerptCleanupCompleted {
            FruitfolioFixedText(source: "the saved excerpt now retains only the selected text.",
                font: .caption, color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
                .accessibilityIdentifier("savedPage.legacyExcerptCleaned")
                .accessibilityFocused($excerptReviewFocused)
        } else if page.hasLegacyExcerptRemainder {
            VStack(alignment: .leading, spacing: 8) {
                FruitfolioFixedText(source: page.canReviewLegacyExcerptCleanup
                    ? "this older excerpt also retains the original answer. nothing has been removed."
                    : "this older excerpt retains answer text but has no recorded selection. it has been preserved for review.",
                    font: .caption, color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
                    .accessibilityIdentifier("savedPage.legacyExcerptNotice")
                if page.canReviewLegacyExcerptCleanup {
                    WatercolorSecondaryButton(label: "review retained answer text") { requestExcerptCleanup() }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                        .accessibilityIdentifier("savedPage.reviewLegacyExcerpt")
                        .accessibilityFocused($excerptReviewFocused)
                }
            }
        }
    }

    private func requestExcerptCleanup() {
        guard viewIsVisible, page.canReviewLegacyExcerptCleanup, let owner = popupOwner else { return }
        let expected = page
        returnExcerptReviewFocus = true
        excerptReviewFocused = false
        notesFocused = false
        owner.present { id in
            FruitPopupRequest(id: id, character: .blueberry,
                message: "keep only the recorded selected text? this removes the retained answer remainder from this excerpt and its linked saved copies. your notes, images and citations are kept. this cannot be undone.",
                primaryAction: .init(label: "keep everything") {
                    guard viewIsVisible else { return }
                    _ = owner.consumeAction(for: id)
                },
                secondaryAction: .init(label: "keep selected text only") {
                    guard viewIsVisible, page.id == expected.id, owner.consumeAction(for: id) else { return }
                    pendingExcerptCleanup = expected
                }, dismissBehavior: .explicitActionOnly, tone: .cautionary, priority: .sensitive,
                source: "legacy-excerpt-review", deduplicationKey: "legacy-excerpt-review-" + popupInstanceID.uuidString,
                surface: .tapedWhite)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Prompt10LibraryStorageNotice(store: store)
            FruitfolioFixedText(source: "my notes",
                font: .custom("Chalkboard SE", size: 13, relativeTo: .headline).bold())
            TextEditor(text: $notes.text)
                .focused($notesFocused)
                .accessibilityIdentifier("savedPage.notes")
                .modifier(FruitfolioFixedAccessibilityLabel(source: "my notes"))
                .font(.custom("Chalkboard SE", size: 13, relativeTo: .body))
                .frame(minHeight: 110)
                .padding(8)
                .background(DesignTokens.ColorToken.backgroundCream.opacity(0.75), in: RoundedRectangle(cornerRadius: 12))
            WatercolorSecondaryButton(label: "save notes") { _ = saveNotes() }
                .disabled(store.storageProtectionReason != nil)
                .accessibilityIdentifier("savedPage.saveNotes")
            if let notesMessage {
                Prompt10SavedPageNoticeText(notice: notesMessage,
                    font: .custom("Chalkboard SE", size: 14, relativeTo: .body))
                    .accessibilityIdentifier("savedPage.notesStatus")
                    .accessibilityFocused($notesMessageFocused)
                    .task(id: notesFocusRequest) {
                        await Task.yield()
                        guard !Task.isCancelled, viewIsVisible else { return }
                        notesMessageFocused = true
                    }
            }
        }

    }

    private func loadNotesIfNeeded() {
        // Re-rendering after an image import must not overwrite an active draft.
        notes.load(pageID: page.id, notes: page.notes)
    }

    @discardableResult
    private func saveNotes() -> Bool {
        do {
            try store.updatePageNotes(encyclopediaID: encyclopediaID, chapterID: page.chapterID, pageID: page.id, notes: notes.text, expectedNotes: notes.baseline)
            notes.didSave()
            // Preserve concurrently attached images and other persisted fields.
            if let updated = store.encyclopedia(id: encyclopediaID)?.chapters
                .first(where: { $0.id == page.chapterID })?.pages.first(where: { $0.id == page.id }) {
                onPageChanged(updated)
            }
            notesMessage = .notesSaved
            notesFocusRequest = UUID()
            return true
        } catch {
            notesMessage = Prompt10SavedPageNotice(error: error)
            notesFocusRequest = UUID()
            return false
        }
    }

    @ViewBuilder
    private var importedImagesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            FruitfolioFixedText(source: "my images",
                font: .custom("Chalkboard SE", size: 13, relativeTo: .headline).bold(),
                color: DesignTokens.ColorToken.primaryBurgundy)

            ForEach(page.importedImageIDs ?? [], id: \.self) { imageID in
                VStack(spacing: 6) {
                    Prompt10ImportedImage(imageID: imageID)
                    Prompt10ReplaceImagePicker(imageID: imageID) { item, target in
                        beginImageImport(item, replacing: target)
                    }
                    Button { removeImage(imageID) } label: {
                        FruitfolioFixedText(source: "remove image",
                            font: .custom("Chalkboard SE", size: 11, relativeTo: .caption))
                    }
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                FruitfolioFixedText(source: "add image",
                    font: .custom("Chalkboard SE", size: 13, relativeTo: .headline))
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                beginImageImport(item, replacing: nil)
            }

            if let mediaMessage {
                Prompt10SavedPageNoticeText(notice: mediaMessage,
                    font: .custom("Chalkboard SE", size: 11, relativeTo: .caption))
                    .accessibilityIdentifier("savedPage.mediaStatus")
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
            mediaMessage = replacedID == nil ? .imageAdded : .imageReplaced
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
            mediaMessage = .imageImportFailed
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
            mediaMessage = .imageRemoved
            // Detaching is already committed. Cleanup failures must not leave
            // the screen displaying the removed image as if persistence failed.
            if !Prompt10MediaReferences.contains(id, in: store.encyclopedias) {
                try? Prompt10LocalMediaStore.shared.delete(id)
            }
        } catch {
            mediaMessage = .imageRemovalFailed
        }
    }
}

/// Only typed app copy enters translation. External messages remain exact text.
struct Prompt10SavedPageNoticeText: View {
    let notice: Prompt10SavedPageNotice
    let font: Font
    var body: some View {
        Group {
            if let source = notice.controlledSource {
                FruitfolioFixedText(source: source, protectedLiterals: notice.protectedLiterals, font: font, serious: true)
            } else {
                Text(verbatim: notice.source).font(font)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
