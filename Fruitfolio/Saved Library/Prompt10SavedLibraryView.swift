import SwiftUI
import UIKit

struct Prompt10SavedLibraryView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onBack: () -> Void

    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var popupCoordinator: PopupCoordinator
    @State private var rootIsVisible = false
    @State private var actionEpoch = UUID()
    private var ownerIsActive: Bool {
        rootIsVisible && scenePhase == .active && UIApplication.shared.applicationState == .active
            && popupCoordinator.currentPopup == nil
    }
    private var canBrowse: Bool { ownerIsActive && popup == nil && openingEncyclopediaID == nil }
    private var canUseBook: Bool { ownerIsActive && popup == nil && selectedEncyclopediaID != nil }

    @State private var searchText = ""
    @State private var sort: Prompt10LibrarySort = .recentlyUpdated
    @State private var popup: PopupState?
    @State private var selectedEncyclopediaID: UUID?
    @State private var openingEncyclopediaID: UUID?
    @State private var bookTravel = 0.0
    @State private var bookReveal = 0.0
    @State private var bookOpenness = 0.0
    @State private var bookFrames: [UUID: CGRect] = [:]
    @State private var openingOrigin = CGRect.zero
    @State private var openingTask: Task<Void, Never>?
    @State private var openingGeneration = UUID()
    @Environment(\.scenePhase) private var scenePhase

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

            libraryCollection
                .allowsHitTesting(canBrowse)
                .accessibilityHidden(openingEncyclopediaID != nil || popup != nil || !ownerIsActive)
                .opacity(openingEncyclopediaID == nil ? 1 : 0.18)
                .fruitfolioModalBlur(active: popup != nil, reduceMotion: motionPreferences.reduceMotionActive)

            if popup != nil {
                FruitfolioModalBackdrop()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(90)
            }

            bookOpeningOverlay
                .zIndex(80)

            popupLayer
                .accessibilityHidden(!ownerIsActive)
                .zIndex(100)
        }
        .coordinateSpace(name: "Prompt10BookSpace")
        .onPreferenceChange(Prompt10BookFramePreference.self) { bookFrames = $0 }
        .onAppear { rootIsVisible = true }
        .onDisappear { rootIsVisible = false; cancelOpening() }
        .onChange(of: scenePhase) { _, phase in
            actionEpoch = UUID()
            if phase != .active, openingTask != nil { cancelOpening() }
        }
        .onChange(of: popupCoordinator.currentPopup != nil) { _, covered in
            actionEpoch = UUID()
            if covered, openingTask != nil { cancelOpening() }
        }
        .onChange(of: motionPreferences.reduceMotionActive) { _, reduced in
            if reduced, openingTask != nil { settleOpeningForReducedMotion() }
        }
        .onChange(of: store.encyclopedias) { _, _ in
            if let id = openingEncyclopediaID, store.encyclopedia(id: id) == nil {
                // Another shared-library surface may delete this same record.
                // Restore the shelf instead of leaving a dimmed, disabled shell.
                cancelOpening()
            }
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .animation(
            motionPreferences.reduceMotionActive
                ? nil
                : .easeOut(duration: 0.24),
            value: store.encyclopedias
        )
    }

    private var libraryCollection: some View {
        ScrollView {
            VStack(spacing: 18) {
                header

                Prompt10LibraryStorageNotice(store: store)
                if !store.storageUnreadable {
                    composedLibraryHero

                    if store.encyclopedias.isEmpty {
                        emptyState
                    } else {
                        managementTools

                        encyclopediaGrid

                        createAnotherControl
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
    }

    private var header: some View {
        let capturedEpoch = actionEpoch
        return VStack(spacing: 5) {
            ZStack {
                HStack {
                    BackControl {
                        guard canBrowse, capturedEpoch == actionEpoch else { return }
                        onBack()
                    }

                    Spacer()
                }

                FruitfolioFixedText(source: "my encyclopedias",
                font: .custom("Chalkboard SE", size: 26, relativeTo: .body))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
            }

            FruitfolioFixedText(source: "your saved little corner of Fruitfolio ♡", protectedLiterals: ["Fruitfolio", "♡"],
                font: .custom("Chalkboard SE", size: 12.5, relativeTo: .body), color: DesignTokens.ColorToken.secondaryBurgundy)
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
            .multilineTextAlignment(.center)
        }
        .padding(.top, 10)
    }

    private var composedLibraryHero: some View {
        ZStack {
            Prompt10LibraryHero()
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
        .accessibilityHidden(true)
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        let capturedEpoch = actionEpoch
        return VStack(spacing: 10) {
            FruitfolioFixedText(source: "nothing here yet! ☆", protectedLiterals: ["☆"],
                font: .custom("Chalkboard SE", size: 17, relativeTo: .body))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            FruitfolioFixedText(source: "save something you love and we’ll start your first little book.",
                font: .custom("Chalkboard SE", size: 13, relativeTo: .body), color: DesignTokens.ColorToken.secondaryBurgundy)
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
                guard canBrowse, capturedEpoch == actionEpoch else { return }
                popup = .create
            }
        }
        .padding(.top, 2)
    }

    private var searchBinding: Binding<String> {
        let capturedEpoch = actionEpoch
        return Binding(get: { searchText }, set: { value in
            guard canBrowse, capturedEpoch == actionEpoch else { return }
            searchText = value
        })
    }

    private var managementTools: some View {
        VStack(spacing: 8) {
            Prompt10QuietSearchField(
                text: searchBinding
            )

            HStack {
                Spacer()

                Prompt10SortPicker(sort: $sort, reduceMotion: motionPreferences.reduceMotionActive,
                    isEnabled: canBrowse,
                    canInteract: { canBrowse })
            }
        }
    }

    private var encyclopediaGrid: some View {
        let capturedEpoch = actionEpoch
        let books = store.sorted(
            by: sort,
            searchText: searchText
        )

        return Group {
            if books.isEmpty &&
                !searchText.isEmpty {

                VStack(spacing: 8) {
                    FruitfolioFixedText(source: "no little books matched that search ✿", protectedLiterals: ["✿"],
                font: .custom("Chalkboard SE", size: 13, relativeTo: .body), color: DesignTokens.ColorToken.secondaryBurgundy)
                    .accessibilityIdentifier("library.search.noMatches")
                    .foregroundStyle(
                        DesignTokens.ColorToken
                            .secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)

                    WatercolorSecondaryButton(
                        label: "clear search"
                    ) {
                        guard canBrowse, capturedEpoch == actionEpoch else { return }
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
                            guard canBrowse, capturedEpoch == actionEpoch else { return }
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
        let capturedEpoch = actionEpoch
        return Button {
            guard canBrowse, capturedEpoch == actionEpoch else { return }
            audioManager.play(
                .buttonSoftPop
            )

            if store.canCreateEncyclopedia {
                popup = .create
            } else {
                popup = .full
            }

        } label: {
            FruitfolioFixedText(source: "+ add another little encyclopedia",
                font: .custom("Chalkboard SE", size: 12, relativeTo: .body))
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
        .accessibilityIdentifier("library.createAnother")
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
                    cancelOpening()
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
        let capturedEpoch = actionEpoch
        if let id = openingEncyclopediaID, let encyclopedia = store.encyclopedia(id: id) {
            let copy = Prompt10BookTileCopy.opening(name: encyclopedia.name)
            GeometryReader { geometry in
                let frame = Prompt10BookMotion.frame(from: openingOrigin, in: geometry.size, progress: bookTravel)
                ZStack {
                    Prompt10ContinuousBook(style: encyclopedia.style, reveal: bookReveal, openness: bookOpenness)
                    if selectedEncyclopediaID == id {
                        Prompt10EncyclopediaDetailView(
                            store: store, encyclopediaID: id,
                            onBack: { guard canUseBook, capturedEpoch == actionEpoch else { return }; cancelOpening() },
                            onRename: { guard canUseBook, capturedEpoch == actionEpoch else { return }; popup = .rename(id, encyclopedia.name) },
                            onDelete: { guard canUseBook, capturedEpoch == actionEpoch else { return }; popup = .delete(id) })
                        .allowsHitTesting(canUseBook)
                        .padding(.horizontal, max(12, frame.width * 0.06))
                        .padding(.vertical, max(18, frame.height * 0.075))
                        .transition(.opacity)
                    }
                }
                .frame(width: frame.width, height: frame.height)
                .position(x: frame.midX, y: frame.midY)
                .accessibilityIdentifier("library.openBook")
            }
            .fruitfolioModalBlur(active: popup != nil, reduceMotion: motionPreferences.reduceMotionActive)
            .accessibilityElement(children: .contain)
            .accessibilityHidden(popup != nil || !ownerIsActive)
            .modifier(FruitfolioFixedAccessibilityLabel(source: copy.source, protectedLiterals: copy.protectedLiterals))
        }
    }

    private func beginOpening(_ encyclopedia: Prompt10Encyclopedia) {
        guard canBrowse else { return }
        actionEpoch = UUID()
        audioManager.play(.buttonSoftPop)
        openingGeneration = UUID()
        let generation = openingGeneration
        openingOrigin = bookFrames[encyclopedia.id] ?? CGRect(x: 20, y: 80, width: 116, height: 142)
        bookTravel = 0
        bookReveal = 0
        bookOpenness = 0
        openingEncyclopediaID = encyclopedia.id
        openingTask = Task { @MainActor in
            do {
                // Give the source-sized surface a frame before changing targets.
                try await Task.sleep(nanoseconds: 20_000_000)
                guard !Task.isCancelled, ownerIsActive, popup == nil, generation == openingGeneration else { return }
                if motionPreferences.reduceMotionActive {
                    bookTravel = 1
                    bookReveal = 1
                    bookOpenness = 1
                    var transaction = Transaction(); transaction.disablesAnimations = true
                    withTransaction(transaction) { selectedEncyclopediaID = encyclopedia.id }
                } else {
                    withAnimation(.easeInOut(duration: 0.32)) { bookTravel = 0.5; bookReveal = 1 }
                    try await Task.sleep(nanoseconds: 330_000_000)
                    try Task.checkCancellation()
                    guard ownerIsActive, popup == nil, generation == openingGeneration else { return }
                    audioManager.play(.pageTurn)
                    withAnimation(.easeInOut(duration: 0.55)) { bookOpenness = 1 }
                    try await Task.sleep(nanoseconds: 560_000_000)
                    try Task.checkCancellation()
                    withAnimation(.easeInOut(duration: 0.36)) { bookTravel = 1 }
                    try await Task.sleep(nanoseconds: 370_000_000)
                    try Task.checkCancellation()
                    guard ownerIsActive, popup == nil, generation == openingGeneration else { return }
                    withAnimation(.easeOut(duration: 0.16)) { selectedEncyclopediaID = encyclopedia.id }
                }
                openingTask = nil
            } catch { /* Owner cancels and resets the same book. */ }
        }
    }

    private func settleOpeningForReducedMotion() {
        guard let id = openingEncyclopediaID, store.encyclopedia(id: id) != nil else { return }
        openingGeneration = UUID()
        openingTask?.cancel()
        openingTask = nil
        var transaction = Transaction(); transaction.disablesAnimations = true
        withTransaction(transaction) {
            bookTravel = 1; bookReveal = 1; bookOpenness = 1
            selectedEncyclopediaID = id
        }
    }

    private func cancelOpening() {
        actionEpoch = UUID()
        openingGeneration = UUID()
        openingTask?.cancel()
        openingTask = nil
        selectedEncyclopediaID = nil
        openingEncyclopediaID = nil
        bookTravel = 0
        bookReveal = 0
        bookOpenness = 0
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



// MARK: - Prompt 10 Pill Art Button

/// Compatibility API for existing Library/Guide call sites. The canonical
/// control owns wrapping artwork, semantic localization, hit target and pop.
struct Prompt10PillArtButton: View {
    let label: String
    let reduceMotion: Bool
    let action: () -> Void

    var body: some View {
        FruitfolioControlPillButton(label: label, reduceMotionOverride: reduceMotion, action: action)
            .controlSize(.small)
    }
}
