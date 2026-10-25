import SwiftUI

struct Prompt11SavedPagePicker: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onAdded: (Int) -> Void
    let onNeedsSection: () -> Void
    let onDismiss: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var searchText = ""
    @State private var filter: Prompt11SavedMaterialFilter = .all
    @State private var selectedSourceKeys = Set<UUID>()
    @State private var selectedChapterID: UUID?
    @State private var errorMessage: String?

    private var guide: Prompt10Encyclopedia? {
        store.encyclopedia(id: encyclopediaID)
    }

    private var candidates: [Prompt11SavedMaterialCandidate] {
        store.prompt11SavedMaterialCandidates(
            for: encyclopediaID,
            filter: filter,
            searchText: searchText
        )
    }

    var body: some View {
        Prompt10WatercolorPopup {
            VStack(spacing: 10) {
                Text("what should we add?")
                    .font(.custom("Chalkboard SE", size: 16))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                Text(
                    "choose from the things you’ve saved in Ask the Encyclopedia."
                )
                .font(.custom("Chalkboard SE", size: 11.5))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)

                TextField("search my saved things…", text: $searchText)
                    .font(.custom("Chalkboard SE", size: 12))
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(
                        DesignTokens.ColorToken.backgroundCream.opacity(0.88),
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )

                HStack(spacing: 6) {
                    ForEach(Prompt11SavedMaterialFilter.allCases) { option in
                        Button(option.label) {
                            filter = option
                        }
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .fontWeight(filter == option ? .bold : .regular)
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                        .padding(.horizontal, 9)
                        .frame(minHeight: 38)
                        .background(
                            filter == option
                                ? DesignTokens.ColorToken.backgroundCream.opacity(0.94)
                                : DesignTokens.ColorToken.backgroundCream.opacity(0.52),
                            in: Capsule()
                        )
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion: motionPreferences.reduceMotionActive
                            )
                        )
                    }
                }

                if let guide,
                   !guide.chapters.isEmpty {
                    Picker(
                        "section",
                        selection: Binding<UUID?>(
                            get: {
                                selectedChapterID ??
                                    guide.chapters
                                        .sorted { $0.order < $1.order }
                                        .first?
                                        .id
                            },
                            set: { selectedChapterID = $0 }
                        )
                    ) {
                        ForEach(
                            guide.chapters.sorted { $0.order < $1.order }
                        ) { chapter in
                            Text(chapter.name)
                                .tag(Optional(chapter.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .accessibilityLabel("Section")

                } else {
                    VStack(spacing: 6) {
                        Text("make a section first so these pages have somewhere to settle.")
                            .font(.custom("Chalkboard SE", size: 11))
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                            .multilineTextAlignment(.center)

                        Button("+ new section") {
                            onNeedsSection()
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
                    }
                }

                if candidates.isEmpty {
                    Text(
                        store.prompt11AllSavedMaterial().isEmpty
                            ? "nothing has been saved from Ask yet."
                            : "nothing matched this little search."
                    )
                    .font(.custom("Chalkboard SE", size: 11))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 16)

                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(candidates) { candidate in
                                candidateRow(candidate)
                            }
                        }
                    }
                    .frame(maxHeight: 280)
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
                    label: selectedSourceKeys.isEmpty
                        ? "add saved pages"
                        : "add \(selectedSourceKeys.count) \(selectedSourceKeys.count == 1 ? "page" : "pages")",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    addSelected()
                }
                .disabled(
                    selectedSourceKeys.isEmpty || selectedChapterID == nil
                )

                WatercolorSecondaryButton(label: "not yet") {
                    audioManager.play(.popupClose)
                    onDismiss()
                }
            }
            .padding(.vertical, 10)
        }
        .onAppear {
            audioManager.play(.popupOpen)
            selectedChapterID = guide?.chapters
                .sorted { $0.order < $1.order }
                .first?
                .id
        }
    }

    private func candidateRow(
        _ candidate: Prompt11SavedMaterialCandidate
    ) -> some View {
        Button {
            guard !candidate.isAlreadyInGuide else {
                return
            }

            if selectedSourceKeys.contains(candidate.sourceKey) {
                selectedSourceKeys.remove(candidate.sourceKey)
            } else {
                selectedSourceKeys.insert(candidate.sourceKey)
            }

        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(
                    candidate.isAlreadyInGuide ||
                    selectedSourceKeys.contains(candidate.sourceKey)
                        ? "control_radio_selected"
                        : "control_radio_unselected"
                )
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(
                        candidate.page.question.isEmpty
                            ? "saved page"
                            : candidate.page.question
                    )
                    .font(.custom("Chalkboard SE", size: 11.5))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .lineLimit(2)

                    Text(candidate.page.displayBody)
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .lineLimit(3)

                    HStack(spacing: 7) {
                        Text(
                            candidate.page.saveType == .excerpt
                                ? "excerpt"
                                : "full answer"
                        )

                        Text(
                            candidate.page.savedAt,
                            style: .date
                        )

                        if candidate.isAlreadyInGuide {
                            Text("already in this guide")
                                .fontWeight(.bold)
                        }
                    }
                    .font(.custom("Chalkboard SE", size: 9.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                }

                Spacer()
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                DesignTokens.ColorToken.backgroundCream.opacity(0.72),
                in: RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
            )
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: motionPreferences.reduceMotionActive
            )
        )
        .disabled(candidate.isAlreadyInGuide)
        .accessibilityLabel(
            candidate.isAlreadyInGuide
                ? "\(candidate.page.question). Already in this guide."
                : candidate.page.question
        )
    }

    private func addSelected() {
        guard let chapterID = selectedChapterID else {
            errorMessage = "make a section first so these pages have somewhere to settle."
            return
        }

        do {
            var added = 0

            for candidate in candidates
            where selectedSourceKeys.contains(candidate.sourceKey) &&
                !candidate.isAlreadyInGuide {
                _ = try store.prompt11AddSavedMaterial(
                    candidate.page,
                    to: encyclopediaID,
                    chapterID: chapterID
                )
                added += 1
            }

            audioManager.play(.pageTurn)
            onAdded(added)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
