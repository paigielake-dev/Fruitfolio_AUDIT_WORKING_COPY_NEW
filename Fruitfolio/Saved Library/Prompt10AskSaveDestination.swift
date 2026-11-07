import SwiftUI
import UIKit

// Prompt 09 → Prompt 10 bridge.
// Ask determines WHAT is saved. This sheet determines WHERE it is tucked.

struct Prompt10AskSaveDestination: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let pending: Prompt10PendingSavedContent
    let onSaved: () -> Void
    let onCancel: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @State private var presentationIsVisible = false
    @State private var presentationCompleted = false
    @State private var presentationGeneration = UUID()
    private func ownsInteraction(_ identity: UUID) -> Bool {
        ownsPresentation && identity == presentationGeneration
    }
    private var ownsPresentation: Bool {
        presentationIsVisible && !presentationCompleted && scenePhase == .active &&
            UIApplication.shared.applicationState == .active && popupCoordinator.currentPopup == nil
    }
    private var canEditDestination: Bool { ownsPresentation && store.storageProtectionReason == nil }

    @State private var selectedEncyclopediaID: UUID?
    @State private var selectedChapterID: UUID?

    @State private var showingNewEncyclopedia = false
    @State private var newEncyclopediaName = ""
    @State private var selectedNewEncyclopediaStyle: Prompt10BookStyle = .sage
    @State private var errorMessage: String?
    @State private var errorIsFixedCopy = false

    var body: some View {
        let interactionID = presentationGeneration
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                FruitfolioFixedText(source: "where should i tuck it?", font: .custom("Chalkboard SE", size: 16, relativeTo: .headline))
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

                Prompt10LibraryStorageNotice(store: store, interactionAllowed: { ownsInteraction(interactionID) })
                if store.storageProtectionReason != nil {
                    // Original pending Ask content remains owned by this popup;
                    // no write or automatic destination change is attempted.
                    EmptyView()
                } else if store.encyclopedias.isEmpty {
                    FruitfolioFixedText(source: "make your first little encyclopedia ♡",
                        font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body))
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
                                    guard canEditDestination, ownsInteraction(interactionID), store.encyclopedia(id: encyclopedia.id) != nil else { return }
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

                                        Text(verbatim: encyclopedia.name)
                                            .font(
                                                .custom(
                                                    "Chalkboard SE",
                                                    size: 11.5
                                                )
                                            )
                                            .foregroundStyle(
                                                DesignTokens.ColorToken.primaryBurgundy
                                            )
                                            .fixedSize(horizontal: false, vertical: true)

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
                                .accessibilityIdentifier("library.saveDestination.bookRow")
                                .accessibilityAddTraits(selectedEncyclopediaID == encyclopedia.id ? .isSelected : [])
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
                            FruitfolioFixedText(source: "chapter", font: .custom("Chalkboard SE", size: 10.5, relativeTo: .caption))
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
                                    guard canEditDestination, ownsInteraction(interactionID), selectedEncyclopediaID == encyclopedia.id,
                                          store.encyclopedia(id: encyclopedia.id)?.chapters.contains(where: { $0.id == chapter.id }) == true else { return }
                                    selectedChapterID = chapter.id
                                } label: {
                                    HStack {
                                        Text(verbatim: chapter.name)
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
                                .accessibilityIdentifier("library.saveDestination.chapterRow")
                                .accessibilityAddTraits(selectedChapterID == chapter.id ? .isSelected : [])
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

                Button {
                    guard canEditDestination, ownsInteraction(interactionID) else { return }
                    showingNewEncyclopedia.toggle()
                } label: {
                    FruitfolioFixedText(source: "+ new encyclopedia", font: .custom("Chalkboard SE", size: 11, relativeTo: .body))
                }
                .accessibilityIdentifier("library.saveDestination.newBook")
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
                    FruitfolioFixedTextField(
                        "encyclopedia name",
                        text: Binding(get: { newEncyclopediaName }, set: { if canEditDestination && ownsInteraction(interactionID) { newEncyclopediaName = $0 } })
                    )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 12
                        )
                    )
                    .accessibilityIdentifier("library.saveDestination.bookName")
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
                                guard canEditDestination, ownsInteraction(interactionID) else { return }
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
                            .modifier(FruitfolioFixedAccessibilityLabel(source: "\(style.displayName) book"))
                            .accessibilityAddTraits(
                                selectedNewEncyclopediaStyle == style ? .isSelected : []
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    WatercolorSecondaryButton(
                        label: "create encyclopedia"
                    ) {
                        createAndSelectEncyclopedia(interactionID: interactionID)
                    }
                    .accessibilityIdentifier("library.saveDestination.createBook")
                }

                if let errorMessage {
                    Group {
                        if errorIsFixedCopy {
                            FruitfolioTranslatedText(source: errorMessage,
                                font: .custom("Chalkboard SE", size: 10, relativeTo: .caption), serious: true)
                        } else {
                            // Unknown system errors may contain paths or authored values.
                            Text(verbatim: errorMessage)
                                .font(.custom("Chalkboard SE", size: 10, relativeTo: .caption))
                        }
                    }
                    .foregroundStyle(DesignTokens.ColorToken.secondaryBurgundy)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("library.saveDestination.error")
                }

                WatercolorPrimaryButton(
                    label: "save here"
                ) {
                    savePendingContent(interactionID: interactionID)
                }
                .accessibilityIdentifier("library.saveDestination.save")
                .disabled(
                    !canEditDestination || selectedEncyclopediaID == nil ||
                    selectedChapterID == nil
                )

                WatercolorSecondaryButton(
                    label: "cancel"
                ) {
                    guard ownsInteraction(interactionID) else { return }
                    presentationCompleted = true
                    audioManager.play(.popupClose)
                    onCancel()
                }
                .accessibilityIdentifier("library.saveDestination.cancel")
            }
        }
        .disabled(!ownsPresentation)
        .onChange(of: scenePhase) { _, _ in presentationGeneration = UUID() }
        .onDisappear {
            presentationIsVisible = false
            presentationGeneration = UUID()
        }
        .onAppear {
            presentationGeneration = UUID()
            presentationIsVisible = true
            guard !presentationCompleted else { return }
            audioManager.play(.popupOpen)

            if selectedEncyclopediaID == nil, let first =
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

    private func createAndSelectEncyclopedia(interactionID: UUID) {
        guard canEditDestination, ownsInteraction(interactionID) else { return }
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
            errorIsFixedCopy = error is Prompt10LibraryError
            errorMessage =
                error.localizedDescription
        }
    }

    private func savePendingContent(interactionID: UUID) {
        guard canEditDestination, ownsInteraction(interactionID), let encyclopediaID =
                selectedEncyclopediaID,
              let chapterID =
                selectedChapterID else {
            return
        }

        do {
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
                    pending.generationTimestamp,
                excerptSemanticSpans: pending.selectedSemanticSpans,
                excerptSelectionLocation: pending.selectedRenderedRange?.location,
                excerptSelectionLength: pending.selectedRenderedRange?.length,
                excerptLanguage: pending.saveType == .excerpt ? pending.selectedDisplayLanguage : nil,
                sourceRecords: pending.sourceRecords,
                educationalAssetIDs: pending.educationalAssetIDs,
                evidenceSupport: pending.evidenceSupport
            )

            if let selected = store.encyclopedia(id: encyclopediaID),
               selected.chapters.flatMap(\.pages).contains(where: { $0.isDuplicateSave(of: page) }) {
                errorIsFixedCopy = true
                errorMessage = "that content is already tucked into this encyclopedia ♡"
                return
            }

            _ = try store.savePage(
                page,
                to: encyclopediaID,
                chapterID: chapterID
            )

            presentationCompleted = true
            audioManager.play(.buttonSoftPop)
            onSaved()

        } catch {
            errorIsFixedCopy = error is Prompt10LibraryError
            errorMessage =
                error.localizedDescription
        }
    }
}
