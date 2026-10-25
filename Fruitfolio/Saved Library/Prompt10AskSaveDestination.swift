import SwiftUI

// Prompt 09 → Prompt 10 bridge.
// Ask determines WHAT is saved. This sheet determines WHERE it is tucked.

struct Prompt10PendingSavedContent: Equatable {
    let question: String
    let answer: String
    let saveType: Prompt10SavedPageType
    let excerptText: String?

    let originalAnswerID: String?
    let originalConversationID: String?

    let sourceIDs: [String]
    let sourceVersions: [String: String]
    let knowledgeBaseVersion: String?
    let generationTimestamp: Date?

    init(
        question: String,
        answer: String,
        saveType: Prompt10SavedPageType,
        excerptText: String? = nil,
        originalAnswerID: String? = nil,
        originalConversationID: String? = nil,
        sourceIDs: [String] = [],
        sourceVersions: [String: String] = [:],
        knowledgeBaseVersion: String? = nil,
        generationTimestamp: Date? = nil
    ) {
        self.question = question
        self.answer = answer
        self.saveType = saveType
        self.excerptText = excerptText
        self.originalAnswerID = originalAnswerID
        self.originalConversationID = originalConversationID
        self.sourceIDs = sourceIDs
        self.sourceVersions = sourceVersions
        self.knowledgeBaseVersion = knowledgeBaseVersion
        self.generationTimestamp = generationTimestamp
    }
}

struct Prompt10AskSaveDestination: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let pending: Prompt10PendingSavedContent
    let onSaved: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var selectedEncyclopediaID: UUID?
    @State private var selectedChapterID: UUID?

    @State private var showingNewEncyclopedia = false
    @State private var newEncyclopediaName = ""
    @State private var selectedNewEncyclopediaStyle: Prompt10BookStyle = .sage
    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                Text("where should i tuck it?")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 16
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                if store.encyclopedias.isEmpty {
                    Text(
                        "make your first little encyclopedia ♡"
                    )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 11.5
                        )
                    )
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )

                } else {
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(
                                store.sorted(
                                    by: .recentlyUpdated
                                )
                            ) { encyclopedia in
                                Button {
                                    selectedEncyclopediaID = encyclopedia.id
                                    selectedChapterID =
                                        encyclopedia.chapters
                                            .sorted { $0.order < $1.order }
                                            .first?
                                            .id
                                } label: {
                                    HStack {
                                        Image(
                                            encyclopedia.style.assetName
                                        )
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 34)
                                        .accessibilityHidden(true)

                                        Text(encyclopedia.name)
                                            .font(
                                                .custom(
                                                    "Chalkboard SE",
                                                    size: 11.5
                                                )
                                            )
                                            .foregroundStyle(
                                                DesignTokens.ColorToken.primaryBurgundy
                                            )
                                            .lineLimit(2)

                                        Spacer()

                                        if selectedEncyclopediaID == encyclopedia.id {
                                            Text("✓")
                                                .accessibilityHidden(true)
                                        }
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
                            }
                        }
                    }
                    .frame(maxHeight: 180)

                    if let encyclopedia = selectedEncyclopedia {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("chapter")
                                .font(
                                    .custom(
                                        "Chalkboard SE",
                                        size: 10.5
                                    )
                                )
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    DesignTokens.ColorToken.secondaryBurgundy
                                )

                            ForEach(
                                encyclopedia.chapters.sorted {
                                    $0.order < $1.order
                                }
                            ) { chapter in
                                Button {
                                    selectedChapterID = chapter.id
                                } label: {
                                    HStack {
                                        Text(chapter.name)
                                            .font(
                                                .custom(
                                                    "Chalkboard SE",
                                                    size: 11
                                                )
                                            )

                                        Spacer()

                                        if selectedChapterID == chapter.id {
                                            Text("✓")
                                                .accessibilityHidden(true)
                                        }
                                    }
                                    .foregroundStyle(
                                        DesignTokens.ColorToken.primaryBurgundy
                                    )
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
                            }
                        }
                    }
                }

                Button("+ new encyclopedia") {
                    showingNewEncyclopedia.toggle()
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

                if showingNewEncyclopedia {
                    TextField(
                        "encyclopedia name",
                        text: $newEncyclopediaName
                    )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 12
                        )
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background {
                        RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                        .fill(
                            DesignTokens.ColorToken.backgroundCream.opacity(0.88)
                        )
                    }

                    HStack(spacing: 7) {
                        ForEach(Prompt10BookStyle.allCases, id: \.self) { style in
                            Button {
                                selectedNewEncyclopediaStyle = style
                            } label: {
                                Image(style.assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 54)
                                    .padding(4)
                                    .background {
                                        RoundedRectangle(
                                            cornerRadius: 12,
                                            style: .continuous
                                        )
                                        .fill(
                                            selectedNewEncyclopediaStyle == style
                                                ? DesignTokens.ColorToken.backgroundCream.opacity(0.92)
                                                : Color.clear
                                        )
                                        .overlay {
                                            RoundedRectangle(
                                                cornerRadius: 12,
                                                style: .continuous
                                            )
                                            .stroke(
                                                selectedNewEncyclopediaStyle == style
                                                    ? DesignTokens.ColorToken.primaryBurgundy.opacity(0.32)
                                                    : Color.clear,
                                                lineWidth: 1
                                            )
                                        }
                                    }
                                    .frame(
                                        minWidth: DesignTokens.Layout.minimumHitTarget,
                                        minHeight: DesignTokens.Layout.minimumHitTarget
                                    )
                            }
                            .buttonStyle(
                                CutePopButtonStyle(
                                    reduceMotion:
                                        motionPreferences.reduceMotionActive
                                )
                            )
                            .accessibilityLabel("\(style.displayName) book")
                            .accessibilityAddTraits(
                                selectedNewEncyclopediaStyle == style ? .isSelected : []
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    WatercolorSecondaryButton(
                        label: "create encyclopedia"
                    ) {
                        createAndSelectEncyclopedia()
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 10
                            )
                        )
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                }

                WatercolorPrimaryButton(
                    label: "save here"
                ) {
                    savePendingContent()
                }
                .disabled(
                    selectedEncyclopediaID == nil ||
                    selectedChapterID == nil
                )

                WatercolorSecondaryButton(
                    label: "cancel"
                ) {
                    audioManager.play(.popupClose)
                    onCancel()
                }
            }
        }
        .onAppear {
            audioManager.play(.popupOpen)

            if let first =
                store.sorted(
                    by: .recentlyUpdated
                )
                .first {

                selectedEncyclopediaID = first.id
                selectedChapterID =
                    first.chapters
                        .sorted { $0.order < $1.order }
                        .first?
                        .id
            }
        }
    }

    private var selectedEncyclopedia: Prompt10Encyclopedia? {
        guard let selectedEncyclopediaID else {
            return nil
        }

        return store.encyclopedia(
            id: selectedEncyclopediaID
        )
    }

    private func createAndSelectEncyclopedia() {
        do {
            let encyclopedia =
                try store.createEncyclopedia(
                    name: newEncyclopediaName,
                    style: selectedNewEncyclopediaStyle
                )

            selectedEncyclopediaID =
                encyclopedia.id

            selectedChapterID =
                encyclopedia.chapters.first?.id

            newEncyclopediaName = ""
            showingNewEncyclopedia = false
            errorMessage = nil

            audioManager.play(.buttonSoftPop)

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }

    private func savePendingContent() {
        guard let encyclopediaID =
                selectedEncyclopediaID,
              let chapterID =
                selectedChapterID else {
            return
        }

        do {
            if let origin = pending.originalAnswerID,
               let selected = store.encyclopedia(id: encyclopediaID),
               selected.chapters.flatMap(\.pages).contains(where: { $0.originalAnswerID == origin }) {
                errorMessage = "that reveal is already tucked into this encyclopedia ♡"
                return
            }

            let page = Prompt10SavedPage(
                chapterID: chapterID,
                question: pending.question,
                answer: pending.answer,
                saveType: pending.saveType,
                excerptText: pending.excerptText,
                originalAnswerID:
                    pending.originalAnswerID,
                originalConversationID:
                    pending.originalConversationID,
                sourceIDs:
                    pending.sourceIDs,
                sourceVersions:
                    pending.sourceVersions,
                knowledgeBaseVersion:
                    pending.knowledgeBaseVersion,
                generationTimestamp:
                    pending.generationTimestamp
            )

            _ = try store.savePage(
                page,
                to: encyclopediaID,
                chapterID: chapterID
            )

            audioManager.play(.buttonSoftPop)
            onSaved()

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}
