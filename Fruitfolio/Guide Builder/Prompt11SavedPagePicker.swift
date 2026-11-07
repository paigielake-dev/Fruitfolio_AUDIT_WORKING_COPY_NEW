import SwiftUI

// The parent Guide form session owns logical open/close cues. Children own
// their interaction/operation cues and validate the captured form ticket.

struct Prompt11SavedPagePicker: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let encyclopediaID: UUID
    let onAdded: (Int) -> Void
    let onNeedsSection: () -> Void
    let onDismiss: () -> Void
    var isCurrent: @MainActor () -> Bool = { true }

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var searchText = ""
    @State private var filter: Prompt11SavedMaterialFilter = .all
    @State private var selectedSourceKeys = Set<UUID>()
    @State private var selectedChapterID: UUID?
    @State private var errorMessage: Prompt10SavedPageNotice?

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
                FruitfolioFixedText(source: "what should we add?",
                        font: .custom("Chalkboard SE", size: 16, relativeTo: .headline), serious: false)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )

                FruitfolioFixedText(source: "choose from your saved answers, excerpts and your own material.",
                    font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body), serious: false)
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)

                FruitfolioFixedTextField("search my saved things…", text: $searchText)
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
                        Button {
                            guard isCurrent() else { return }
                            audioManager.play(.buttonSoftPop)
                            filter = option
                        } label: {
                            FruitfolioFixedText(source: option.label,
                                font: .custom("Chalkboard SE", size: 10.5).weight(filter == option ? .bold : .regular),
                                color: DesignTokens.ColorToken.primaryBurgundy)
                        }
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .fontWeight(filter == option ? .bold : .regular)
                        .accessibilityAddTraits(filter == option ? .isSelected : [])
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                        .padding(.horizontal, 9)
                        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
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
                        selection: Binding<UUID?>(
                            get: {
                                selectedChapterID ??
                                    guide.chapters
                                        .sorted { $0.order < $1.order }
                                        .first?
                                        .id
                            },
                            set: {
                                guard isCurrent() else { return }
                                audioManager.play(.buttonSoftPop)
                                selectedChapterID = $0
                            }
                        )
                    ) {
                        ForEach(
                            guide.chapters.sorted { $0.order < $1.order }
                        ) { chapter in
                            Text(verbatim: chapter.name)
                                .tag(Optional(chapter.id))
                        }
                    } label: { FruitfolioFixedText(source: "section") }
                    .pickerStyle(.menu)
                    .modifier(FruitfolioFixedAccessibilityLabel(source: "Section"))
                    .accessibilityIdentifier("guide.savedPages.destination")

                } else {
                    VStack(spacing: 6) {
                        FruitfolioFixedText(source: "make a section first so these pages have somewhere to settle.",
                                font: .custom("Chalkboard SE", size: 11, relativeTo: .body), serious: false)
                            .foregroundStyle(
                                DesignTokens.ColorToken.secondaryBurgundy
                            )
                            .multilineTextAlignment(.center)

                        Button {
                            guard isCurrent() else { return }
                            audioManager.play(.buttonSoftPop)
                            onNeedsSection()
                        } label: {
                            FruitfolioFixedText(source: "+ new section", font: .custom("Chalkboard SE", size: 11.5).bold(),
                                color: DesignTokens.ColorToken.primaryBurgundy)
                        }
                        .accessibilityIdentifier("guide.savedPages.newSection")
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
                    FruitfolioFixedText(source: store.prompt11AllSavedMaterial().isEmpty
                            ? "nothing has been saved from Ask yet."
                            : "nothing matched this little search.",
                        font: .custom("Chalkboard SE", size: 11, relativeTo: .body))
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
                    Prompt10SavedPageNoticeText(notice: errorMessage,
                            font: .custom("Chalkboard SE", size: 10.5, relativeTo: .body))
                        .accessibilityIdentifier("guide.form.error")
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .multilineTextAlignment(.center)
                }

                Prompt10PillArtButton(
                    label: selectedSourceKeys.isEmpty
                        ? "add saved pages"
                        : "add \(selectedSourceKeys.count.formatted(.number.locale(Locale(identifier: settings.language.localeIdentifier)))) \(selectedSourceKeys.count == 1 ? "page" : "pages")",
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    guard isCurrent() else { return }
                    addSelected()
                }
                .accessibilityIdentifier("guide.savedPages.add")
                .disabled(
                    selectedSourceKeys.isEmpty || selectedChapterID == nil
                )

                WatercolorSecondaryButton(label: "not yet") {
                    guard isCurrent() else { return }
                    onDismiss()
                }
                .accessibilityIdentifier("guide.savedPages.cancel")
            }
            .padding(.vertical, 10)
        }
        .onAppear {
            if selectedChapterID == nil {
                selectedChapterID = guide?.chapters
                    .sorted { $0.order < $1.order }
                    .first?
                    .id
            }
        }
    }

    private func candidateRow(
        _ candidate: Prompt11SavedMaterialCandidate
    ) -> some View {
        Button {
            guard isCurrent() else { return }
            guard !candidate.isAlreadyInGuide else {
                return
            }
            audioManager.play(.buttonSoftPop)

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
                    Group {
                        if candidate.page.question.isEmpty {
                            FruitfolioFixedText(source: "saved page",
                                font: .custom("Chalkboard SE", size: 11.5, relativeTo: .body))
                        } else {
                            Text(verbatim: candidate.page.question)
                        }
                    }
                    .font(.custom("Chalkboard SE", size: 11.5, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .lineLimit(2)

                    Text(verbatim: candidate.page.displayBody)
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                        .lineLimit(3)

                    if settings.language.rawValue != candidate.page.displaySourceLanguage {
                        Text(verbatim: settings.localized("original text")).font(.caption2)
                    }

                    HStack(spacing: 7) {
                        FruitfolioFixedText(source: candidate.page.saveType == .excerpt ? "excerpt" : "full answer",
                            font: .custom("Chalkboard SE", size: 9.5, relativeTo: .caption))

                        Text(
                            candidate.page.savedAt,
                            style: .date
                        )

                        if candidate.isAlreadyInGuide {
                            FruitfolioFixedText(source: "already in this guide", font: .custom("Chalkboard SE", size: 9.5, relativeTo: .caption))
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
        .modifier(Prompt11CandidateAccessibility(question: candidate.page.question, alreadyAdded: candidate.isAlreadyInGuide))
        .accessibilityIdentifier("guide.savedPages.candidate." + candidate.id.uuidString)
    }

    private func addSelected() {
        guard let chapterID = selectedChapterID else {
            errorMessage = .chooseGuideSection
            return
        }

        do {
            let added = try store.prompt11AddSavedMaterialSelection(
                sourceKeys: selectedSourceKeys, to: encyclopediaID, chapterID: chapterID
            )
            // A changed filter/selection must never produce a false saved card.
            guard !added.isEmpty else { return }

            audioManager.play(.pageTurn)
            onAdded(added.count)
        } catch {
            errorMessage = Prompt10SavedPageNotice(error: error)
        }
    }
}

private struct Prompt11CandidateAccessibility: ViewModifier {
    let question: String
    let alreadyAdded: Bool
    func body(content: Content) -> some View {
        if question.isEmpty {
            content.modifier(FruitfolioFixedAccessibilityLabel(source: alreadyAdded ? "saved page. Already in this guide." : "saved page"))
        } else if alreadyAdded {
            let literal = FruitfolioSemanticMarkup.markdown([.init(text: question)])
            content.modifier(FruitfolioFixedAccessibilityLabel(source: literal + ". Already in this guide.", protectedLiterals: [literal]))
        } else {
            content.accessibilityLabel(Text(verbatim: question))
        }
    }
}
