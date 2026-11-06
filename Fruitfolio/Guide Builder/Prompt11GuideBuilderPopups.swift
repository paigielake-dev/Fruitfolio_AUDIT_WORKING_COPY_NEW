import SwiftUI

// The parent Guide form session owns logical open/close cues. Children own
// their interaction/operation cues and validate the captured form ticket.

struct Prompt11CreateGuidePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onCreated: (UUID) -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var name = ""
    @State private var guideDescription = ""
    @State private var style: Prompt10BookStyle = .sage
    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                Text("let’s make your guide ♡")
                    .font(.custom("Chalkboard SE", size: 16))
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
                    .font(.custom("Chalkboard SE", size: 10.5))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("ex. my hormone guide", text: $name)
                .accessibilityIdentifier("guide.create.name")
                .bookLabelGuidance(text: name, maximum: Prompt10BookLabelPolicy.maximumTitleLength)
                    .font(.custom("Chalkboard SE", size: 12.5))
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
                    .font(.custom("Chalkboard SE", size: 10.5))
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
                .accessibilityIdentifier("guide.create.description")
                .bookLabelGuidance(text: guideDescription, maximum: Prompt10BookLabelPolicy.maximumDescriptionLength)
                .font(.custom("Chalkboard SE", size: 12))
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
                            guard isCurrent() else { return }
                            audioManager.play(.buttonSoftPop)
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                }

                Prompt10PillArtButton(
                    label: "create my guide",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    createGuide()
                }
                .accessibilityIdentifier("guide.create.save")

                WatercolorSecondaryButton(
                    label: "not yet"
                ) {
                    guard isCurrent() else { return }
                    onDismiss()
                }
                .accessibilityIdentifier("guide.create.cancel")
            }
            .padding(.top, 26)
            .padding(.bottom, 18)
        }
        .accessibilityIdentifier("guide.create.form")
    }

    private func createGuide() {
        guard isCurrent() else { return }
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
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var name: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentName: String,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        isCurrent: @escaping @MainActor () -> Bool = { true }
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentName = currentName
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isCurrent = isCurrent
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
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField("guide name", text: $name)
                .bookLabelGuidance(text: name, maximum: Prompt10BookLabelPolicy.maximumTitleLength)
                    .font(.custom("Chalkboard SE", size: 12.5))
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save name",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    do {
                        try store.renameEncyclopedia(
                            id: encyclopediaID,
                            to: name,
                            expectedName: currentName
                        )
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
            }
        }
    }
}

struct Prompt11DescriptionPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentDescription: String
    let onSaved: () -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var guideDescription: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentDescription: String,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        isCurrent: @escaping @MainActor () -> Bool = { true }
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentDescription = currentDescription
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isCurrent = isCurrent
        _guideDescription = State(initialValue: currentDescription)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("edit little description")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField(
                    "ex. everything i want to remember about my cycle",
                    text: $guideDescription,
                    axis: .vertical
                )
                .accessibilityIdentifier("guide.description.input")
                .bookLabelGuidance(text: guideDescription, maximum: Prompt10BookLabelPolicy.maximumDescriptionLength)
                .font(.custom("Chalkboard SE", size: 12.5))
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save description",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    do {
                        try store.updateEncyclopediaDescription(
                            id: encyclopediaID,
                            description: guideDescription,
                            expectedDescription: currentDescription
                        )
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .accessibilityIdentifier("guide.description.save")

                WatercolorSecondaryButton(label: "cancel") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
                .accessibilityIdentifier("guide.description.cancel")
            }
        }
        .accessibilityIdentifier("guide.description.form")
    }
}

struct Prompt11ChangeCoverPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentStyle: Prompt10BookStyle
    let onSaved: () -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var style: Prompt10BookStyle
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentStyle: Prompt10BookStyle,
        onSaved: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        isCurrent: @escaping @MainActor () -> Bool = { true }
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentStyle = currentStyle
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isCurrent = isCurrent
        _style = State(initialValue: currentStyle)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("choose a cover")
                    .font(.custom("Chalkboard SE", size: 16))
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
                            guard isCurrent() else { return }
                            audioManager.play(.buttonSoftPop)
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "use this cover",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    do {
                        try store.changeEncyclopediaStyle(
                            id: encyclopediaID,
                            to: style,
                            expectedStyle: currentStyle
                        )
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
            }
        }
    }
}

struct Prompt11DeleteGuidePopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onDeleted: () -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

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
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Text(
                    "the guide will disappear, but the things you saved from Ask will stay in your saved library."
                )
                .font(.custom("Chalkboard SE", size: 11.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "keep it",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    onDismiss()
                }

                WatercolorSecondaryButton(label: "delete guide") {
                    guard isCurrent() else { return }
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
    }
}

struct Prompt11SectionPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let chapterID: UUID?
    let initialName: String
    let onSaved: () -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

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
        onDismiss: @escaping () -> Void,
        isCurrent: @escaping @MainActor () -> Bool = { true }
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.chapterID = chapterID
        self.initialName = initialName
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isCurrent = isCurrent
        _name = State(initialValue: initialName)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text(chapterID == nil ? "name this section" : "rename section")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField("ex. hormones", text: $name)
                    .font(.custom("Chalkboard SE", size: 12.5))
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: chapterID == nil ? "add section" : "save section",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    do {
                        if let chapterID {
                            try store.renameChapter(
                                encyclopediaID: encyclopediaID,
                                chapterID: chapterID,
                                to: name,
                                expectedName: initialName
                            )
                        } else {
                            _ = try store.createChapter(
                                in: encyclopediaID,
                                name: name
                            )
                        }

                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
                .accessibilityIdentifier("guide.section.cancel")
            }
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
    var isCurrent: @MainActor () -> Bool = { true }

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
        onDismiss: @escaping () -> Void,
        isCurrent: @escaping @MainActor () -> Bool = { true }
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.chapterID = chapterID
        self.pageID = pageID
        self.initialNote = initialNote
        self.onSaved = onSaved
        self.onDismiss = onDismiss
        self.isCurrent = isCurrent
        _note = State(initialValue: initialNote)
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("my note")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                TextField(
                    "write something you want to remember…",
                    text: $note,
                    axis: .vertical
                )
                .font(.custom("Chalkboard SE", size: 12.5))
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "save note",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    do {
                        try store.updatePageNotes(
                            encyclopediaID: encyclopediaID,
                            chapterID: chapterID,
                            pageID: pageID,
                            notes: note
                        )
                        onSaved()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(label: "cancel") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
            }
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
    var isCurrent: @MainActor () -> Bool = { true }

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
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                if let guide {
                    ForEach(
                        guide.chapters.sorted { $0.order < $1.order }
                    ) { chapter in
                        Button {
                            guard isCurrent() else { return }
                            move(to: chapter.id)
                        } label: {
                            HStack {
                                Text(chapter.name)
                                    .font(.custom("Chalkboard SE", size: 11.5))

                                Spacer()

                                if chapter.id == fromChapterID {
                                    Text("current")
                                        .font(.custom("Chalkboard SE", size: 9.5))
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
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Button("+ new section") {
                    guard isCurrent() else { return }
                    onNewSection()
                }
                .font(.custom("Chalkboard SE", size: 11.5))
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
                    guard isCurrent() else { return }
                    onDismiss()
                }
            }
        }
    }

    private func move(to chapterID: UUID) {
        do {
            guard try store.movePage(
                encyclopediaID: encyclopediaID,
                pageID: pageID,
                fromChapterID: fromChapterID,
                toChapterID: chapterID
            ) else { return }
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
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text("remove this page from your guide?")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                Text("it’ll stay safely in your saved library.")
                    .font(.custom("Chalkboard SE", size: 11.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                }

                Prompt10PillArtButton(
                    label: "keep it here",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    onDismiss()
                }

                WatercolorSecondaryButton(label: "remove page") {
                    guard isCurrent() else { return }
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
    }
}

struct Prompt11OriginalAnswerPopup: View {
    let sourcePage: Prompt10SavedPage?
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(alignment: .leading, spacing: 10) {
                Text(sourcePage?.saveType == .excerpt ? "saved selection" : "original answer")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .frame(maxWidth: .infinity, alignment: .center)

                if let sourcePage {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if !sourcePage.displayBody.isEmpty {
                                FruitfolioTranslatedText(source: sourcePage.displayBody, protectedLiterals: sourcePage.sourceIDs,
                                    enabled: sourcePage.allowsAutomaticDisplayTranslation, font: .custom("Chalkboard SE", size: 12, relativeTo: .body),
                                    sourceLanguage: sourcePage.displaySourceLanguage, semanticSpans: sourcePage.displaySemanticSpans, sourceRecords: sourcePage.sourceRecords ?? [])
                            }
                            FruitfolioSavedScientificIllustrations(assetIDs: sourcePage.educationalAssetIDs ?? [])
                            if let records = sourcePage.sourceRecords, !records.isEmpty {
                                FruitfolioSourceCitationList(sources: records)
                            }
                        }
                    }
                    .frame(maxHeight: 330)
                } else {
                    Text("this saved page is no longer in your library")
                        .font(.custom("Chalkboard SE", size: 12))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                WatercolorSecondaryButton(label: "close") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
            }
        }
    }
}
