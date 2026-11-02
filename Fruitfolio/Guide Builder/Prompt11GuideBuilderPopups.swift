import SwiftUI

struct Prompt11CreateGuidePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onCreated: (UUID) -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    private enum Field: Hashable { case name, description }
    @FocusState private var focusedField: Field?
    @State private var name = ""
    @State private var guideDescription = ""
    @State private var style: Prompt10BookStyle = .sage
    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                Text("let’s make your guide ♡")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Image(style.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 88)
                    .accessibilityHidden(true)

                Text("guide name")
                    .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("ex. my hormone guide", text: $name)
                    .focused($focusedField, equals: .name)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                    .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 46)
                    .background(
                        DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )

                Text("little description")
                    .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField(
                    "ex. everything i want to remember about my cycle",
                    text: $guideDescription,
                    axis: .vertical
                )
                .focused($focusedField, equals: .description)
                .submitLabel(.done)
                .onSubmit { focusedField = nil }
                .font(.custom("Chalkboard SE", size: 12, relativeTo: .body))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .textFieldStyle(.plain)
                .lineLimit(2...3)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

                HStack(spacing: 7) {
                    ForEach(Prompt10BookStyle.allCases, id: \.self) { option in
                        Button {
                            style = option
                        } label: {
                            Image(option.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 48)
                                .padding(3)
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .stroke(
                                        style == option
                                            ? DesignTokens.ColorToken.primaryBurgundy.opacity(0.35)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                                }
                                .frame(
                                    minWidth: DesignTokens.Layout.minimumHitTarget,
                                    minHeight: DesignTokens.Layout.minimumHitTarget
                                )
                        }
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion: motionPreferences.reduceMotionActive
                            )
                        )
                        .accessibilityLabel("\(option.displayName) cover")
                        .accessibilityAddTraits(
                            style == option ? .isSelected : []
                        )
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                }

                Prompt10PillArtButton(
                    label: "create my guide",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    createGuide()
                }

                WatercolorSecondaryButton(
                    label: "not yet"
                ) {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
            .padding(.top, 26)
            .padding(.bottom, 18)
        }
        .safeAreaInset(edge: .bottom) {
            if focusedField != nil {
                HStack {
                    Spacer()
                    Button("done") { focusedField = nil }
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("guide.keyboardDone")
                }
                .padding(.horizontal, 20)
                .background(DesignTokens.ColorToken.backgroundCream)
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }

    private func createGuide() {
        do {
            let guide = try store.createGuideEncyclopedia(
                name: name,
                subtitle: guideDescription,
                style: style
            )

            audioManager.play(.bookClose)
            onCreated(guide.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct Prompt11RenameGuidePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentName: String
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var name: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentName: String,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentName = currentName
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _name = State(initialValue: currentName)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image("guide_rename")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54)
                    .accessibilityHidden(true)

                Text("rename guide")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField("guide name", text: $name)
                    .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 46)
                    .background(
                        DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save name",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    do {
                        try store.renameEncyclopedia(
                            id: encyclopediaID,
                            to: name
                        )
                        audioManager.play(.buttonSoftPop)
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11DescriptionPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentDescription: String
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var guideDescription: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentDescription: String,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentDescription = currentDescription
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _guideDescription = State(initialValue: currentDescription)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("edit little description")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField(
                    "ex. everything i want to remember about my cycle",
                    text: $guideDescription,
                    axis: .vertical
                )
                .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .textFieldStyle(.plain)
                .lineLimit(3...6)
                .padding(12)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save description",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    do {
                        try store.updateEncyclopediaDescription(
                            id: encyclopediaID,
                            description: guideDescription
                        )
                        audioManager.play(.buttonSoftPop)
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11ChangeCoverPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentStyle: Prompt10BookStyle
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var style: Prompt10BookStyle
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentStyle: Prompt10BookStyle,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentStyle = currentStyle
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _style = State(initialValue: currentStyle)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("choose a cover")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Image(style.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76, height: 96)
                    .accessibilityHidden(true)

                HStack(spacing: 7) {
                    ForEach(Prompt10BookStyle.allCases, id: \.self) { option in
                        Button {
                            style = option
                        } label: {
                            Image(option.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 48)
                                .padding(3)
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 10,
                                        style: .continuous
                                    )
                                    .stroke(
                                        style == option
                                            ? DesignTokens.ColorToken.primaryBurgundy.opacity(0.35)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                                }
                                .frame(
                                    minWidth: DesignTokens.Layout.minimumHitTarget,
                                    minHeight: DesignTokens.Layout.minimumHitTarget
                                )
                        }
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion: motionPreferences.reduceMotionActive
                            )
                        )
                        .accessibilityLabel("\(option.displayName) cover")
                        .accessibilityAddTraits(
                            style == option ? .isSelected : []
                        )
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "use this cover",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    do {
                        try store.changeEncyclopediaStyle(
                            id: encyclopediaID,
                            to: style
                        )
                        audioManager.play(.buttonSoftPop)
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11DeleteGuidePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onDeleted: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image("guide_delete")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52)
                    .accessibilityHidden(true)

                Text("delete this guide?")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Text(
                    "the guide will disappear, but the things you saved from Ask will stay in your saved library."
                )
                .font(.custom("Chalkboard SE", size: 11.5, relativeTo: .body))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "keep it",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    audioManager.play(.popupClose)
                    onDismiss()
                }

                WatercolorSecondaryButton(label: "delete guide") {
                    do {
                        try store.deleteEncyclopedia(id: encyclopediaID)
                        audioManager.play(.bookClose)
                        onDeleted()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11SectionPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let chapterID: UUID?
    let initialName: String
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var name: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        chapterID: UUID? = nil,
        initialName: String = "",
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.chapterID = chapterID
        self.initialName = initialName
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _name = State(initialValue: initialName)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text(chapterID == nil ? "name this section" : "rename section")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField("ex. hormones", text: $name)
                    .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 46)
                    .background(
                        DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: chapterID == nil ? "add section" : "save section",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    do {
                        if let chapterID {
                            try store.renameChapter(
                                encyclopediaID: encyclopediaID,
                                chapterID: chapterID,
                                to: name
                            )
                        } else {
                            _ = try store.createChapter(
                                in: encyclopediaID,
                                name: name
                            )
                        }

                        audioManager.play(.buttonSoftPop)
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11NotePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let chapterID: UUID
    let pageID: UUID
    let initialNote: String
    let onSaved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var note: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        chapterID: UUID,
        pageID: UUID,
        initialNote: String,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.chapterID = chapterID
        self.pageID = pageID
        self.initialNote = initialNote
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        _note = State(initialValue: initialNote)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("my note")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField(
                    "write something you want to remember…",
                    text: $note,
                    axis: .vertical
                )
                .font(.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .textFieldStyle(.plain)
                .lineLimit(4...7)
                .padding(12)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save note",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    do {
                        try store.updatePageNotes(
                            encyclopediaID: encyclopediaID,
                            chapterID: chapterID,
                            pageID: pageID,
                            notes: note
                        )
                        audioManager.play(.buttonSoftPop)
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11MovePagePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let fromChapterID: UUID
    let pageID: UUID
    let onMoved: () -> Void
    let onNewSection: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var errorMessage: String?

    private var guide: Prompt10Encyclopedia? {
        store.encyclopedia(id: encyclopediaID)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                Text("move this page to…")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                if let guide {
                    ForEach(
                        guide.chapters.sorted { $0.order < $1.order }
                    ) { chapter in
                        Button {
                            move(to: chapter.id)
                        } label: {
                            HStack {
                                Text(chapter.name)
                                    .font(.custom("Chalkboard SE", size: 11.5, relativeTo: .body))

                                Spacer()

                                if chapter.id == fromChapterID {
                                    Text("current")
                                        .font(.custom("Chalkboard SE", size: 9.5, relativeTo: .body))
                                }
                            }
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )
                            .frame(
                                minHeight: DesignTokens.Layout.minimumHitTarget
                            )
                        }
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion: motionPreferences.reduceMotionActive
                            )
                        )
                        .disabled(chapter.id == fromChapterID)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Button("+ new section") {
                    onNewSection()
                }
                .font(.custom("Chalkboard SE", size: 11.5, relativeTo: .body))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion: motionPreferences.reduceMotionActive
                    )
                )

                WatercolorSecondaryButton(label: "cancel") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }

    private func move(to chapterID: UUID) {
        do {
            try store.movePage(
                encyclopediaID: encyclopediaID,
                pageID: pageID,
                fromChapterID: fromChapterID,
                toChapterID: chapterID
            )
            audioManager.play(.pageTurn)
            onMoved()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct Prompt11RemovePagePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let chapterID: UUID
    let pageID: UUID
    let onRemoved: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("remove this page from your guide?")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                Text("it’ll stay safely in your saved library.")
                    .font(.custom("Chalkboard SE", size: 11.5, relativeTo: .body))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "keep it here",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    audioManager.play(.popupClose)
                    onDismiss()
                }

                WatercolorSecondaryButton(label: "remove page") {
                    do {
                        try store.deletePage(
                            encyclopediaID: encyclopediaID,
                            chapterID: chapterID,
                            pageID: pageID
                        )
                        audioManager.play(.pageTurn)
                        onRemoved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}

struct Prompt11OriginalAnswerPopup: View {
    let sourcePage: Prompt10SavedPage?
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(alignment: .leading, spacing: 10) {
                Text("original answer")
                    .font(.custom("Chalkboard SE", size: 16, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                if let sourcePage {
                    ScrollView {
                        Text(sourcePage.answer)
                            .font(.custom("Chalkboard SE", size: 12, relativeTo: .body))
                            .foregroundStyle(
                                DesignTokens.ColorToken.primaryBurgundy
                            )
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 330)
                } else {
                    Text("this saved page is no longer in your library")
                        .font(.custom("Chalkboard SE", size: 12, relativeTo: .body))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                WatercolorSecondaryButton(label: "close") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)
        }
    }
}
