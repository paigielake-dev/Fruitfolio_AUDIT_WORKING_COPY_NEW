import SwiftUI

struct Prompt10CreateEncyclopediaPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onDismiss: () -> Void
    let onFull: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var title = ""
    @FocusState private var titleFocused: Bool
    @State private var selectedStyle: Prompt10BookStyle = .sage
    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup { popupContent }
            .onAppear { audioManager.play(.popupOpen) }
    }

    private var popupContent: some View {
        VStack(spacing: 0) {
            popupTitle
                .padding(.bottom, 12)

            encyclopediaNameField
                .padding(.bottom, 20)

            coverPicker
                .padding(.bottom, 28)

            if let errorMessage {
                errorMessageView(
                    errorMessage
                )
                .padding(.bottom, 16)
            }

            createButton
                .padding(.bottom, 6)

            cancelButton
        }
    }

    private var popupTitle: some View {
        Text(
            "what should we call this little encyclopedia? ☆"
        )
        .font(
            .custom(
                "Chalkboard SE",
                size: 13.5
            )
        )
        .fontWeight(.bold)
        .foregroundStyle(
            DesignTokens.ColorToken.primaryBurgundy
        )
        .multilineTextAlignment(.center)
        .fixedSize(
            horizontal: false,
            vertical: true
        )
        .frame(maxWidth: 285)
    }

    private var encyclopediaNameField: some View {
        TextField(
            "encyclopedia name",
            text: $title
        )
        .font(
            .custom(
                "Chalkboard SE",
                size: 13
            )
        )
        .foregroundStyle(
            DesignTokens.ColorToken.primaryBurgundy
        )
        .textFieldStyle(.plain)
        .focused($titleFocused)
        .submitLabel(.done)
        .onSubmit { titleFocused = false }
        .padding(.horizontal, 14)
        .frame(minHeight: 46)
        .frame(maxWidth: 300)
        .background {
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                DesignTokens.ColorToken
                    .backgroundCream
                    .opacity(0.88)
            )
        }
    }

    private var coverPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 54, maximum: 64), spacing: 12)], spacing: 12) {
            ForEach(
                Prompt10BookStyle.allCases,
                id: \.self
            ) { style in
                coverButton(
                    for: style
                )
            }
        }
        .frame(maxWidth: 300)
    }

    private func coverButton(
        for style: Prompt10BookStyle
    ) -> some View {
        Button {
            selectedStyle = style

        } label: {
            Image(style.assetName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: 34,
                    height: 46
                )
                .padding(5)
                .background {
                    coverSelectionBackground(
                        for: style
                    )
                }
                .frame(
                    minWidth:
                        DesignTokens
                            .Layout
                            .minimumHitTarget,
                    minHeight:
                        DesignTokens
                            .Layout
                            .minimumHitTarget
                )
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
        .accessibilityLabel(
            "\(style.displayName) book"
        )
        .accessibilityAddTraits(
            selectedStyle == style
                ? .isSelected
                : []
        )
    }

    private func coverSelectionBackground(
        for style: Prompt10BookStyle
    ) -> some View {
        RoundedRectangle(
            cornerRadius: 10,
            style: .continuous
        )
        .fill(
            selectedStyle == style
                ? DesignTokens
                    .ColorToken
                    .backgroundCream
                    .opacity(0.92)
                : Color.clear
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .stroke(
                selectedStyle == style
                    ? DesignTokens
                        .ColorToken
                        .primaryBurgundy
                        .opacity(0.32)
                    : Color.clear,
                lineWidth: 1
            )
        }
    }

    private func errorMessageView(
        _ message: String
    ) -> some View {
        Text(message)
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 10.5
                )
            )
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
            .multilineTextAlignment(.center)
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .frame(maxWidth: 285)
    }

    private var createButton: some View {
        Prompt10PillArtButton(
            label: "create encyclopedia",
            reduceMotion:
                motionPreferences.reduceMotionActive
        ) {
            createEncyclopedia()
        }
        .frame(maxWidth: 295)
    }

    private var cancelButton: some View {
        WatercolorSecondaryButton(
            label: "cancel"
        ) {
            audioManager.play(
                .popupClose
            )

            onDismiss()
        }
        .frame(maxWidth: 170)
    }

    private func createEncyclopedia() {
        do {
            _ = try store.createEncyclopedia(
                name: title,
                style: selectedStyle
            )

            audioManager.play(
                .buttonSoftPop
            )

            onDismiss()

        } catch Prompt10LibraryError
            .encyclopediaLimitReached {

            onFull()

        } catch {
            errorMessage =
                error.localizedDescription
        }
    }
}


// MARK: - Rename Encyclopedia

struct Prompt10RenameEncyclopediaPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let currentName: String
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    @State private var title: String
    @State private var errorMessage: String?

    init(
        store: Prompt10SavedLibraryStore,
        encyclopediaID: UUID,
        currentName: String,
        onDismiss: @escaping () -> Void
    ) {
        self.store = store
        self.encyclopediaID = encyclopediaID
        self.currentName = currentName
        self.onDismiss = onDismiss

        _title = State(
            initialValue: currentName
        )
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Text(
                    "rename this little encyclopedia"
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 15
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

                TextField(
                    "encyclopedia name",
                    text: $title
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 13
                    )
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: 46)
                .background {
                    RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                    .fill(
                        DesignTokens.ColorToken
                            .backgroundCream
                            .opacity(0.88)
                    )
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 10.5
                            )
                        )
                        .foregroundStyle(
                            DesignTokens.ColorToken
                                .secondaryBurgundy
                        )
                }

                WatercolorPrimaryButton(
                    label: "save name"
                ) {
                    do {
                        try store.renameEncyclopedia(
                            id: encyclopediaID,
                            to: title
                        )

                        audioManager.play(
                            .buttonSoftPop
                        )

                        onDismiss()

                    } catch {
                        errorMessage =
                            error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(
                    label: "cancel"
                ) {
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(
                .popupOpen
            )
        }
    }
}


// MARK: - Delete Encyclopedia

struct Prompt10DeleteEncyclopediaPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onDismiss: () -> Void
    let onDeleted: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    @State private var errorMessage: String?

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image(
                    "fruit_peach_soft"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .accessibilityHidden(true)

                Text(
                    "delete this encyclopedia?"
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 15
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

                HStack(spacing: 6) {
                    Image(
                        "popup_warning"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 18,
                        height: 18
                    )
                    .accessibilityHidden(true)

                    Text(
                        "deleting it removes the saved collection inside it."
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
                    .multilineTextAlignment(.center)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(
                            .custom(
                                "Chalkboard SE",
                                size: 10.5
                            )
                        )
                        .foregroundStyle(
                            DesignTokens.ColorToken
                                .secondaryBurgundy
                        )
                }

                WatercolorPrimaryButton(
                    label: "keep my encyclopedia"
                ) {
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }

                WatercolorSecondaryButton(
                    label: "delete encyclopedia"
                ) {
                    do {
                        try store.deleteEncyclopedia(
                            id: encyclopediaID
                        )

                        audioManager.play(
                            .bookClose
                        )

                        onDeleted()

                    } catch {
                        errorMessage =
                            error.localizedDescription
                    }
                }
            }
        }
        .onAppear {
            audioManager.play(
                .popupOpen
            )
        }
    }
}


// MARK: - Full Library

struct Prompt10FullLibraryPopup: View {
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image(
                    "fruit_blueberry_friendly"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .accessibilityHidden(true)

                Text(
                    "your little library is completely full."
                )
                .font(
                    .custom(
                        "Chalkboard SE",
                        size: 15
                    )
                )
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .multilineTextAlignment(.center)

                Text(
                    "delete an encyclopedia you don’t need anymore to make room for another! :-)"
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
                .multilineTextAlignment(.center)

                WatercolorPrimaryButton(
                    label: "back to my library"
                ) {
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }
            }
        }
        .onAppear {
            audioManager.play(
                .popupOpen
            )
        }
    }
}
