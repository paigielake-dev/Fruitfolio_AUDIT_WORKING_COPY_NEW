import SwiftUI

struct Prompt10SavedLibraryView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var searchText = ""
    @State private var sort: Prompt10LibrarySort = .recentlyUpdated
    @State private var popup: PopupState?
    @State private var selectedEncyclopediaID: UUID?
    @State private var openingEncyclopediaID: UUID?
    @State private var openingStage: BookOpeningStage = .idle
    @Namespace private var bookTransitionNamespace

    init(
        store: Prompt10SavedLibraryStore,
        onBack: @escaping () -> Void
    ) {
        self.store = store
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            Group {
                if let selectedEncyclopediaID,
                   let encyclopedia = store.encyclopedia(
                        id: selectedEncyclopediaID
                   ) {

                    Prompt10EncyclopediaDetailView(
                        store: store,
                        encyclopediaID: encyclopedia.id,
                        onBack: {
                            withAnimation(detailTransition) {
                                self.selectedEncyclopediaID = nil
                            }
                        },
                        onRename: {
                            popup = .rename(
                                encyclopedia.id,
                                encyclopedia.name
                            )
                        },
                        onDelete: {
                            popup = .delete(
                                encyclopedia.id
                            )
                        }
                    )
                    .transition(
                        motionPreferences.reduceMotionActive
                            ? .opacity
                            : .opacity.combined(
                                with: .scale(scale: 0.985)
                            )
                    )

                } else {
                    libraryCollection
                }
            }
            .fruitfolioModalBlur(
                active: popup != nil,
                reduceMotion: motionPreferences.reduceMotionActive
            )


            bookOpeningOverlay
                .zIndex(80)

            popupLayer
                .zIndex(100)
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .animation(
            motionPreferences.reduceMotionActive
                ? .easeOut(duration: 0.14)
                : .easeOut(duration: 0.24),
            value: store.encyclopedias
        )
    }

    private var libraryCollection: some View {
        ScrollView {
            VStack(spacing: 18) {
                if let error = store.loadError {
                    Text(error).font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                        .fixedSize(horizontal: false, vertical: true)
                    FruitfolioControlPillButton(label: "try opening my library again") { store.retryLoad() }
                }

                header

                composedLibraryHero

                if store.encyclopedias.isEmpty {
                    emptyState
                } else {
                    if store.encyclopedias.count >= 13 {
                        managementTools
                    }

                    encyclopediaGrid

                    createAnotherControl
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        VStack(spacing: 5) {
            ZStack {
                HStack {
                    BackControl {
                        onBack()
                    }

                    Spacer()
                }

                Text("my encyclopedias")
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 26
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
            }

            Text(
                "your saved little corner of Fruitfolio ♡"
            )
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 12.5
                )
            )
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
            .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    private var composedLibraryHero: some View {
        ZStack {
            Prompt10LibraryHero(
                isEmpty: store.encyclopedias.isEmpty
            )
            .scaleEffect(1.10)

            // Pink washed-out flower — upper left
            Prompt10LibraryAssetImage(
                asset: .flower
            )
            .frame(width: 46)
            .offset(
                x: -104,
                y: -54
            )

            // Yellow flower bundle — upper right
            Prompt10LibraryAssetImage(
                asset: .flowerBundle
            )
            .frame(width: 46)
            .offset(
                x: 104,
                y: -54
            )

            // Potted plant — lower left
            Prompt10LibraryAssetImage(
                asset: .pottedPlant
            )
            .frame(width: 58)
            .offset(
                x: -104,
                y: 74
            )

            // Bookmark — resting near the plant
            Prompt10LibraryAssetImage(
                asset: .bookmark
            )
            .frame(width: 34)
            .rotationEffect(
                .degrees(-8)
            )
            .offset(
                x: -50,
                y: 96
            )

            // Stacked books — lower right
            Prompt10LibraryAssetImage(
                asset: .bookStack
            )
            .frame(width: 82)
            .offset(
                x: 92,
                y: 84
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: 310)
        .accessibilityElement(
            children: .contain
        )
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("nothing here yet ✿")
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

            Text(
                "save something you love and we’ll start your first little book."
            )
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
            .frame(maxWidth: 260)

            Prompt10PillArtButton(
                label: "build my first encyclopedia",
                reduceMotion:
                    motionPreferences.reduceMotionActive
            ) {
                audioManager.play(
                    .buttonSoftPop
                )

                popup = .create
            }
        }
        .padding(.top, 2)
    }

    private var managementTools: some View {
        VStack(spacing: 8) {
            Prompt10QuietSearchField(
                text: $searchText
            )

            HStack {
                Spacer()

                Prompt10SortPicker(
                    sort: $sort,
                    reduceMotion:
                        motionPreferences.reduceMotionActive
                )
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion:
                            motionPreferences.reduceMotionActive
                    )
                )
            }
        }
    }

    private var encyclopediaGrid: some View {
        let books = store.sorted(
            by: sort,
            searchText: searchText
        )

        return Group {
            if books.isEmpty &&
                !searchText.isEmpty {

                VStack(spacing: 8) {
                    Text(
                        "no little books matched that search ✿"
                    )
                    .font(
                        .custom(
                            "Chalkboard SE",
                            size: 13
                        )
                    )
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                    WatercolorSecondaryButton(
                        label: "clear search"
                    ) {
                        searchText = ""
                    }
                }
                .padding(.vertical, 20)

            } else {
                LazyVGrid(
                    columns: [
                        GridItem(
                            .flexible(),
                            spacing: 22,
                            alignment: .top
                        ),
                        GridItem(
                            .flexible(),
                            spacing: 22,
                            alignment: .top
                        )
                    ],
                    spacing: 24
                ) {
                    ForEach(books) { encyclopedia in
                        Prompt10BookTile(
                            encyclopedia: encyclopedia,
                            reduceMotion:
                                motionPreferences
                                    .reduceMotionActive
                        ) {
                            beginOpening(
                                encyclopedia
                            )
                        }
                        .buttonStyle(
                            CutePopButtonStyle(
                                reduceMotion:
                                    motionPreferences
                                        .reduceMotionActive
                            )
                        )
                        .matchedGeometryEffect(
                            id: bookGeometryID(
                                encyclopedia.id
                            ),
                            in: bookTransitionNamespace,
                            isSource: true
                        )
                        .opacity(
                            openingEncyclopediaID ==
                                encyclopedia.id
                                ? 0
                                : 1
                        )
                        .allowsHitTesting(
                            openingEncyclopediaID == nil
                        )
                    }
                }
            }
        }
    }

    private var createAnotherControl: some View {
        Button {
            audioManager.play(
                .buttonSoftPop
            )

            if store.canCreateEncyclopedia {
                popup = .create
            } else {
                popup = .full
            }

        } label: {
            Text(
                "+ add another little encyclopedia"
            )
            .font(
                .custom(
                    "Chalkboard SE",
                    size: 12
                )
            )
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .frame(
                minHeight:
                    DesignTokens.Layout.minimumHitTarget
            )
            .padding(.horizontal, 12)
        }
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion:
                    motionPreferences.reduceMotionActive
            )
        )
    }

    @ViewBuilder
    private var popupLayer: some View {
        switch popup {
        case .none:
            EmptyView()

        case .create:
            Prompt10CreateEncyclopediaPopup(
                store: store,
                onDismiss: {
                    popup = nil
                },
                onFull: {
                    popup = .full
                }
            )

        case .rename(
            let id,
            let currentName
        ):
            Prompt10RenameEncyclopediaPopup(
                store: store,
                encyclopediaID: id,
                currentName: currentName,
                onDismiss: {
                    popup = nil
                }
            )

        case .delete(let id):
            Prompt10DeleteEncyclopediaPopup(
                store: store,
                encyclopediaID: id,
                onDismiss: {
                    popup = nil
                },
                onDeleted: {
                    selectedEncyclopediaID = nil
                    popup = nil
                }
            )

        case .full:
            Prompt10FullLibraryPopup {
                popup = nil
            }
        }
    }

    @ViewBuilder
    private var bookOpeningOverlay: some View {
        if let openingEncyclopediaID,
           let encyclopedia = store.encyclopedia(
                id: openingEncyclopediaID
           ) {

            ZStack {
                DesignTokens.ColorToken.backgroundCream
                    .opacity(
                        openingStage == .open
                            ? 0.08
                            : 0.18
                    )
                    .ignoresSafeArea()

                Prompt10BookOpeningArtwork(
                    encyclopedia: encyclopedia,
                    stage: openingStage
                )
                .matchedGeometryEffect(
                    id: bookGeometryID(
                        encyclopedia.id
                    ),
                    in: bookTransitionNamespace,
                    isSource: false
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
            .allowsHitTesting(true)
            .accessibilityHidden(true)
            .transition(.opacity)
        }
    }

    private func beginOpening(
        _ encyclopedia: Prompt10Encyclopedia
    ) {
        guard openingEncyclopediaID == nil else {
            return
        }

        audioManager.play(
            .buttonSoftPop
        )

        if motionPreferences.reduceMotionActive {
            audioManager.play(
                .pageTurn
            )

            withAnimation(
                .easeOut(duration: 0.14)
            ) {
                selectedEncyclopediaID =
                    encyclopedia.id
            }

            return
        }

        withAnimation(
            .spring(
                response: 0.30,
                dampingFraction: 0.78,
                blendDuration: 0
            )
        ) {
            openingEncyclopediaID =
                encyclopedia.id
            openingStage = .spine
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.18
        ) {
            guard openingEncyclopediaID ==
                    encyclopedia.id else {
                return
            }

            withAnimation(
                .easeInOut(duration: 0.12)
            ) {
                openingStage = .front
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.31
        ) {
            guard openingEncyclopediaID ==
                    encyclopedia.id else {
                return
            }

            withAnimation(
                .easeInOut(duration: 0.13)
            ) {
                openingStage = .closed
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.45
        ) {
            guard openingEncyclopediaID ==
                    encyclopedia.id else {
                return
            }

            audioManager.play(
                .pageTurn
            )

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.82,
                    blendDuration: 0
                )
            ) {
                openingStage = .open
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.67
        ) {
            guard openingEncyclopediaID ==
                    encyclopedia.id else {
                return
            }

            withAnimation(
                detailTransition
            ) {
                selectedEncyclopediaID =
                    encyclopedia.id
            }
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.82
        ) {
            guard openingEncyclopediaID ==
                    encyclopedia.id else {
                return
            }

            openingEncyclopediaID = nil
            openingStage = .idle
        }
    }

    private func bookGeometryID(
        _ id: UUID
    ) -> String {
        "prompt10-book-\(id.uuidString)"
    }

    private var detailTransition: Animation {
        motionPreferences.reduceMotionActive
            ? .easeOut(duration: 0.14)
            : .easeOut(duration: 0.35)
    }

    fileprivate enum BookOpeningStage: Equatable {
        case idle
        case spine
        case front
        case closed
        case open
    }

    private enum PopupState: Equatable {
        case create

        case rename(
            UUID,
            String
        )

        case delete(UUID)

        case full
    }
}



// MARK: - Prompt 10 Book Opening Transition

private struct Prompt10BookOpeningArtwork: View {
    let encyclopedia: Prompt10Encyclopedia
    let stage:
        Prompt10SavedLibraryView.BookOpeningStage

    var body: some View {
        ZStack {
            switch stage {
            case .idle:
                Color.clear

            case .spine:
                Image(
                    encyclopedia.style.assetName
                )
                .resizable()
                .scaledToFit()
                .frame(width: 76)

            case .front:
                tintedArtwork(
                    assetName:
                        "library_book_blank",
                    tintStrength: 0.30
                )
                .frame(width: 178)

            case .closed:
                tintedArtwork(
                    assetName:
                        "library_book_closed",
                    tintStrength: 0.26
                )
                .frame(width: 188)

            case .open:
                tintedArtwork(
                    assetName:
                        "library_book_open",
                    tintStrength: 0.12
                )
                .frame(width: 322)
            }
        }
        .frame(
            width: 340,
            height: 330
        )
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func tintedArtwork(
        assetName: String,
        tintStrength: Double
    ) -> some View {
        ZStack {
            Image(assetName)
                .resizable()
                .scaledToFit()

            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    encyclopedia.style
                        .openingTint
                        .opacity(
                            tintStrength
                        )
                )
                .blendMode(.multiply)
        }
        .compositingGroup()
    }
}

private extension Prompt10BookStyle {
    var openingTint: Color {
        switch self {
        case .sage:
            return Color(
                red: 0.52,
                green: 0.64,
                blue: 0.54
            )

        case .yellow:
            return Color(
                red: 0.88,
                green: 0.73,
                blue: 0.40
            )

        case .pink:
            return Color(
                red: 0.84,
                green: 0.60,
                blue: 0.67
            )

        case .coral:
            return Color(
                red: 0.84,
                green: 0.50,
                blue: 0.46
            )

        case .lavender:
            return Color(
                red: 0.69,
                green: 0.61,
                blue: 0.79
            )
        }
    }
}

// MARK: - Prompt 10 Pill Art Button

/// Legacy entry point retained; sizing, artwork and pop are canonical.
struct Prompt10PillArtButton: View {
    let label: String
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        FruitfolioControlPillButton(label: label, playsSound: false, action: action)
            .environment(\.fruitfolioReduceMotion, reduceMotion)
    }
}
