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
    @State private var bookContentVisible = false
    @State private var bookFrames: [String: CGRect] = [:]
    @State private var lastInsideBookFrame: CGRect?
    @State private var openingOriginFrame: CGRect?
    @State private var openingTask: Task<Void, Never>?

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

            ZStack {
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
                                openingTask?.cancel()
                                openingTask = nil
                                self.selectedEncyclopediaID = nil
                                openingEncyclopediaID = nil
                                openingStage = .idle
                                bookContentVisible = false
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
                    .opacity(bookContentVisible || motionPreferences.reduceMotionActive ? 1 : 0)
                    .allowsHitTesting(bookContentVisible || motionPreferences.reduceMotionActive)
                    .accessibilityHidden(!bookContentVisible && !motionPreferences.reduceMotionActive)
                    .transition(
                        motionPreferences.reduceMotionActive
                            ? .opacity
                            : .opacity.combined(
                                with: .scale(scale: 0.985)
                            )
                    )

                } else {
                    libraryCollection
                        .fruitfolioModalBlur(active: openingEncyclopediaID != nil,
                            reduceMotion: motionPreferences.reduceMotionActive)
                }
            }
            .zIndex(selectedEncyclopediaID == nil ? 0 : 2)
            bookOpeningOverlay.zIndex(1)
            }
            .fruitfolioModalBlur(
                active: popup != nil,
                reduceMotion: motionPreferences.reduceMotionActive
            )


            popupLayer
                .zIndex(100)
        }
        .coordinateSpace(name: "prompt10.bookStage")
        .onPreferenceChange(Prompt10BookFramePreference.self) { frames in
            let inside = openingEncyclopediaID.flatMap { frames["inside:" + $0.uuidString] }
            let settling = inside != nil && lastInsideBookFrame == nil && !bookContentVisible
            if settling && !motionPreferences.reduceMotionActive {
                withAnimation(detailTransition) { bookFrames = frames; lastInsideBookFrame = inside }
            } else {
                // Scroll geometry follows its actual content immediately; do
                // not animate the book behind already scrolling live text.
                var transaction = Transaction(); transaction.disablesAnimations = true
                withTransaction(transaction) {
                    bookFrames = frames
                    if let inside { lastInsideBookFrame = inside }
                }
            }
        }
        .onChange(of: motionPreferences.reduceMotionActive) { _, reduced in
            guard reduced, let id = openingEncyclopediaID else { return }
            openingTask?.cancel()
            openingTask = nil
            var transaction = Transaction(); transaction.disablesAnimations = true
            withTransaction(transaction) {
                openingStage = .open; selectedEncyclopediaID = id; bookContentVisible = true
            }
        }
        .onDisappear {
            openingTask?.cancel()
            openingTask = nil
            if !bookContentVisible {
                openingEncyclopediaID = nil; selectedEncyclopediaID = nil; openingStage = .idle
            }
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
                    FruitfolioControlPillButton(label: "try opening my library again", localizationKey: "try opening my library again") { store.retryLoad() }
                }

                if let error = store.mediaRecoveryError {
                    Text(error).font(.custom("Chalkboard SE", size: 14, relativeTo: .body))
                        .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                        .fixedSize(horizontal: false, vertical: true)
                    FruitfolioControlPillButton(label: "try recovering my images again", localizationKey: "try recovering my images again") { store.recoverMedia() }
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
                        label: "clear search", localizationKey: "clear search"
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
                    openingTask?.cancel()
                    openingTask = nil
                    selectedEncyclopediaID = nil
                    openingEncyclopediaID = nil
                    bookContentVisible = false
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
        if let id = openingEncyclopediaID, let encyclopedia = store.encyclopedia(id: id) {
            GeometryReader { proxy in
                let width = min(max(1, proxy.size.width - 40), 430)
                let centered = CGRect(x: (proxy.size.width - width) / 2,
                    y: (proxy.size.height - width * 0.72) / 2, width: width, height: width * 0.72)
                let shelf = openingOriginFrame ?? bookFrames["shelf:" + id.uuidString] ?? centered
                let inside = bookFrames["inside:" + id.uuidString] ?? lastInsideBookFrame ?? centered
                let target = selectedEncyclopediaID == id ? inside : (openingStage == .spine ? shelf : centered)
                Prompt10CodedBookArtwork(style: encyclopedia.style, openness: bookOpenness)
                    .frame(width: max(1, target.width), height: max(1, target.height))
                    .position(x: target.midX, y: target.midY)
                    .id(id)
            }
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private var bookOpenness: CGFloat {
        switch openingStage {
        case .idle, .spine: return 0
        case .front: return 0.12
        case .closed: return 0.22
        case .open: return 1
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
        bookContentVisible = false
        openingOriginFrame = bookFrames["shelf:" + encyclopedia.id.uuidString]
        lastInsideBookFrame = nil

        if motionPreferences.reduceMotionActive {
            openingEncyclopediaID = encyclopedia.id
            openingStage = .open
            bookContentVisible = true
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

        openingTask?.cancel()
        openingTask = nil
        openingTask = Task { @MainActor in
            defer { if !Task.isCancelled { openingTask = nil } }
            do {
                try await Task.sleep(for: .milliseconds(180))
                guard !Task.isCancelled, openingEncyclopediaID == encyclopedia.id else { return }
                withAnimation(.easeInOut(duration: 0.12)) { openingStage = .front }
                try await Task.sleep(for: .milliseconds(130))
                guard !Task.isCancelled, openingEncyclopediaID == encyclopedia.id else { return }
                withAnimation(.easeInOut(duration: 0.13)) { openingStage = .closed }
                try await Task.sleep(for: .milliseconds(140))
                guard !Task.isCancelled, openingEncyclopediaID == encyclopedia.id else { return }
                audioManager.play(.pageTurn)
                withAnimation(.easeInOut(duration: 0.28)) { openingStage = .open }
                try await Task.sleep(for: .milliseconds(330))
                guard !Task.isCancelled, openingEncyclopediaID == encyclopedia.id else { return }
                withAnimation(detailTransition) { selectedEncyclopediaID = encyclopedia.id }
                try await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled, openingEncyclopediaID == encyclopedia.id else { return }
                withAnimation(.easeOut(duration: 0.14)) { bookContentVisible = true }
                // The same coded book remains alive behind the measured inside
                // slot. No final PNG/book representation replaces it.
            } catch { return }
        }
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

extension Prompt10BookStyle {
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
