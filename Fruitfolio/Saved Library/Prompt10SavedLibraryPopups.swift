import SwiftUI
import UIKit

struct Prompt10CreateEncyclopediaPopup: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onDismiss: () -> Void
    let onFull: () -> Void

    @EnvironmentObject private var audioManager: AudioManager

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var formIsVisible = false
    @State private var actionEpoch = UUID()
    private var canInteract: Bool {
        formIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var title = ""
    @State private var selectedStyle: Prompt10BookStyle = .sage
    @State private var errorMessage: String?
    @State private var errorIsFixedCopy = false

    private var titleBinding: Binding<String> {
        let capturedEpoch = actionEpoch
        return Binding(get: { title }, set: { value in
            guard canInteract, capturedEpoch == actionEpoch else { return }
            title = value
        })
    }

    var body: some View {
        Prompt10WatercolorPopup {
            popupContent
        }
        .disabled(!canInteract)
        .onDisappear { formIsVisible = false; actionEpoch = UUID() }
        .onChange(of: scenePhase) { _, _ in actionEpoch = UUID() }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in actionEpoch = UUID() }
        .onAppear {
            formIsVisible = true
            guard canInteract else { return }
            audioManager.play(.popupOpen)
        }
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
                .accessibilityIdentifier("library.createBook.error")
                .padding(.bottom, 16)
            }

            createButton
                .padding(.bottom, 6)

            cancelButton
        }
    }

    private var popupTitle: some View {
        FruitfolioFixedText(source: "what should we call this little encyclopedia? ☆", protectedLiterals: ["☆"],
            font: .custom("Chalkboard SE", size: 13.5, relativeTo: .body))
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
        FruitfolioFixedTextField(
            "encyclopedia name",
            text: titleBinding
        )
                .accessibilityIdentifier("library.createBook.name")
        .bookLabelGuidance(text: title, maximum: Prompt10BookLabelPolicy.maximumTitleLength)
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
        HStack(spacing: 12) {
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
        let capturedEpoch = actionEpoch
        return Button {
            guard canInteract, capturedEpoch == actionEpoch else { return }
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
        .accessibilityIdentifier("library.createBook.style." + style.rawValue)
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
        Prompt10LibraryPopupErrorText(message: message, isFixedCopy: errorIsFixedCopy)
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
        let capturedEpoch = actionEpoch
        return Prompt10PillArtButton(
            label: "create encyclopedia",
            reduceMotion:
                motionPreferences.reduceMotionActive
        ) {
            guard canInteract, capturedEpoch == actionEpoch else { return }
            createEncyclopedia()
        }
        .frame(maxWidth: 295)
        .accessibilityIdentifier("library.createBook.submit")
    }

    private var cancelButton: some View {
        let capturedEpoch = actionEpoch
        return WatercolorSecondaryButton(
            label: "cancel"
        ) {
            guard canInteract, capturedEpoch == actionEpoch else { return }
            audioManager.play(
                .popupClose
            )

            onDismiss()
        }
        .frame(maxWidth: 170)
        .accessibilityIdentifier("library.createBook.cancel")
    }

    private func createEncyclopedia() {
        guard canInteract else { return }
        do {
            _ = try store.createEncyclopedia(
                name: title,
                style: selectedStyle
            )

            onDismiss()

        } catch Prompt10LibraryError
            .encyclopediaLimitReached {

            onFull()

        } catch {
            errorIsFixedCopy = error is Prompt10LibraryError
            errorMessage = error.localizedDescription
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

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var formIsVisible = false
    @State private var actionEpoch = UUID()
    private var canInteract: Bool {
        formIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }

    @State private var title: String
    @State private var errorMessage: String?
    @State private var errorIsFixedCopy = false

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

    private var titleBinding: Binding<String> {
        let capturedEpoch = actionEpoch
        return Binding(get: { title }, set: { value in
            guard canInteract, capturedEpoch == actionEpoch else { return }
            title = value
        })
    }

    var body: some View {
        let capturedEpoch = actionEpoch
        return Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                FruitfolioFixedText(source: "rename this little encyclopedia",
            font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

                FruitfolioFixedTextField(
                    "encyclopedia name",
                    text: titleBinding
                )
                .accessibilityIdentifier("library.renameBook.name")
                .bookLabelGuidance(text: title, maximum: Prompt10BookLabelPolicy.maximumTitleLength)
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
                    Prompt10LibraryPopupErrorText(message: errorMessage, isFixedCopy: errorIsFixedCopy)
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
                    guard canInteract, capturedEpoch == actionEpoch else { return }
                    do {
                        try store.renameEncyclopedia(
                            id: encyclopediaID,
                            to: title,
                            expectedName: currentName
                        )


                        onDismiss()

                    } catch {
                        errorIsFixedCopy = error is Prompt10LibraryError
                        errorMessage = error.localizedDescription
                    }
                }

                WatercolorSecondaryButton(
                    label: "cancel"
                ) {
                    guard canInteract, capturedEpoch == actionEpoch else { return }
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }
            }
        }
        .disabled(!canInteract)
        .onDisappear { formIsVisible = false; actionEpoch = UUID() }
        .onChange(of: scenePhase) { _, _ in actionEpoch = UUID() }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in actionEpoch = UUID() }
        .onAppear {
            formIsVisible = true
            guard canInteract else { return }
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

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var formIsVisible = false
    @State private var actionEpoch = UUID()
    private var canInteract: Bool {
        formIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }

    @State private var errorMessage: String?
    @State private var errorIsFixedCopy = false

    var body: some View {
        let capturedEpoch = actionEpoch
        return Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image(
                    "fruit_peach_soft"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .accessibilityHidden(true)

                FruitfolioFixedText(source: "delete this encyclopedia?",
            font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
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

                    FruitfolioFixedText(source: "deleting it removes the saved collection inside it.",
            font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body), color: DesignTokens.ColorToken.secondaryBurgundy)
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                }

                if let errorMessage {
                    Prompt10LibraryPopupErrorText(message: errorMessage, isFixedCopy: errorIsFixedCopy)
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
                    guard canInteract, capturedEpoch == actionEpoch else { return }
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }

                WatercolorSecondaryButton(
                    label: "delete encyclopedia"
                ) {
                    guard canInteract, capturedEpoch == actionEpoch else { return }
                    do {
                        try store.deleteEncyclopedia(
                            id: encyclopediaID
                        )

                        audioManager.play(
                            .bookClose
                        )

                        onDeleted()

                    } catch {
                        errorIsFixedCopy = error is Prompt10LibraryError
                        errorMessage = error.localizedDescription
                    }
                }
            }
        }
        .disabled(!canInteract)
        .onDisappear { formIsVisible = false; actionEpoch = UUID() }
        .onChange(of: scenePhase) { _, _ in actionEpoch = UUID() }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in actionEpoch = UUID() }
        .onAppear {
            formIsVisible = true
            guard canInteract else { return }
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

    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var formIsVisible = false
    @State private var actionEpoch = UUID()
    private var canInteract: Bool {
        formIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }

    var body: some View {
        let capturedEpoch = actionEpoch
        return Prompt10WatercolorPopup {
            VStack(spacing: 12) {
                Image(
                    "fruit_blueberry_friendly"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .accessibilityHidden(true)

                FruitfolioFixedText(source: "your little library is completely full.",
            font: .custom("Chalkboard SE", size: 15, relativeTo: .body))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .multilineTextAlignment(.center)

                FruitfolioFixedText(source: "delete an encyclopedia you don’t need anymore to make room for another! :-)",
            font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body), color: DesignTokens.ColorToken.secondaryBurgundy)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)

                WatercolorPrimaryButton(
                    label: "back to my library"
                ) {
                    guard canInteract, capturedEpoch == actionEpoch else { return }
                    audioManager.play(
                        .popupClose
                    )

                    onDismiss()
                }
            }
        }
        .disabled(!canInteract)
        .onDisappear { formIsVisible = false; actionEpoch = UUID() }
        .onChange(of: scenePhase) { _, _ in actionEpoch = UUID() }
        .onChange(of: popupCoordinator.currentPopup?.id) { _, _ in actionEpoch = UUID() }
        .onAppear {
            formIsVisible = true
            guard canInteract else { return }
            audioManager.play(
                .popupOpen
            )
        }
    }
}


/// Controlled library validation can be translated. Unknown system errors may
/// contain paths or authored values and remain verbatim.
private struct Prompt10LibraryPopupErrorText: View {
    let message: String
    let isFixedCopy: Bool
    var body: some View {
        Group {
            if isFixedCopy {
                FruitfolioFixedText(source: message,
                    font: .custom("Chalkboard SE", size: 10.5, relativeTo: .caption),
                    color: DesignTokens.ColorToken.secondaryBurgundy, serious: true)
            } else {
                Text(verbatim: message)
                    .font(.custom("Chalkboard SE", size: 10.5, relativeTo: .caption))
            }
        }
    }
}
