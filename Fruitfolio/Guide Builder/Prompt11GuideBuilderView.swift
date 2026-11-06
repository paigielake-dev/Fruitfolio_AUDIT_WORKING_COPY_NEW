import SwiftUI
import UIKit

struct Prompt11GuideBuilderView: View {
    @ObservedObject var store: Prompt10SavedLibraryStore

    let onBack: () -> Void
    let onGoToAsk: () -> Void

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var selectedGuideID: UUID?
    @StateObject private var formSession = Prompt11GuideFormSession()
    @State private var rootIsVisible = false
    @Environment(\.scenePhase) private var scenePhase
    private var overlay: Prompt11Overlay? { formSession.current }
    @State private var showingReadMode = false
    @State private var showingGuideOptions = false
    @State private var reorderMode = false
    @State private var reorderErrorMessage: String?
    @State private var savedStatusVisible = false
    @State private var savedStatusTask: Task<Void, Never>?
    @State private var savedStatusGuideID: UUID?
    #if DEBUG
    @State private var savedStatusRequests = 0
    #endif
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var searchText = ""

    init(
        store: Prompt10SavedLibraryStore,
        onBack: @escaping () -> Void,
        onGoToAsk: @escaping () -> Void,
        initialGuideID: UUID? = nil
    ) {
        self.store = store
        self.onBack = onBack
        self.onGoToAsk = onGoToAsk
        _selectedGuideID = State(initialValue: initialGuideID)
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.backgroundCream
                .ignoresSafeArea()

            Group {
                if let selectedGuideID,
                   let guide = store.encyclopedia(id: selectedGuideID) {
                    workspace(guide)
                } else {
                    home
                }
            }
            .fruitfolioModalBlur(
                active: overlay != nil,
                reduceMotion: motionPreferences.reduceMotionActive
            )

            if overlay != nil {
                DesignTokens.ColorToken.backgroundCream
                    .opacity(FruitfolioModalBlurSpec.dimOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(90)
            }

            overlayLayer
                .zIndex(100)

            if savedStatusVisible {
                savedStatus
                    .zIndex(110)
            }

        }
        .fullScreenCover(isPresented: $showingReadMode) {
            if let selectedGuideID {
                FruitfolioPresentedPopupHost {
                Prompt11ReadModeView(
                    store: store,
                    guideID: selectedGuideID,
                    onClose: {
                        showingReadMode = false
                    }
                )
                .environmentObject(audioManager)
                .environmentObject(motionPreferences)
                }
            }
        }
        .onAppear {
            rootIsVisible = true
            if scenePhase == .active { formSession.resume() }
            else { formSession.suspend() }
        }
        .onChange(of: scenePhase) { _, phase in
            if rootIsVisible, phase == .active { formSession.resume() }
            else { formSession.suspend() }
        }
        .onDisappear {
            rootIsVisible = false
            formSession.suspend()
            dismissSavedStatus()
        }
        .onChange(of: selectedGuideID) { _, guideID in
            reorderErrorMessage = nil
            if savedStatusGuideID != guideID { dismissSavedStatus() }
        }
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .preference(key: Prompt11GuideSavedStatusRequestKey.self, value: savedStatusRequests)
        #endif
    }

    private var home: some View {
        ScrollView {
            VStack(spacing: 18) {
                homeHeader

                Prompt10LibraryStorageNotice(store: store)
                if !store.storageUnreadable {
                    homeEnvironment

                    if store.prompt11Guides.isEmpty {
                        emptyState
                    } else {
                        guideGrid
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 44)
        }
        .scrollIndicators(.hidden)
    }

    private var homeHeader: some View {
        VStack(spacing: 5) {
            ZStack {
                HStack {
                    Prompt11GuideIconButton(
                        assetName: "guide_back",
                        identificationWord: "back",
                        accessibilityLabel: "Back",
                        reduceMotion: motionPreferences.reduceMotionActive,
                        width: 34,
                        action: onBack
                    )

                    Spacer()
                }

                Text("build your own guide")
                    .font(.custom("Chalkboard SE", size: 25))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 56)
            }

            Text(
                "turn the things you’ve saved into an encyclopedia of your own ♡"
            )
            .font(.custom("Chalkboard SE", size: 12.5))
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
            .multilineTextAlignment(.center)

            Image("guide_star_divider")
                .resizable()
                .scaledToFit()
                .frame(width: 88)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .padding(.top, 10)
    }

    private var homeEnvironment: some View {
        ZStack {
            Image("guide_folder")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 320)
                .accessibilityHidden(true)

            Image("decor_bow")
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .offset(x: -118, y: -72)
                .accessibilityHidden(true)

            Image("guide_orange_star_brush")
                .resizable()
                .scaledToFit()
                .frame(width: 90)
                .offset(x: 105, y: 88)
                .accessibilityHidden(true)
        }
        .frame(height: 225)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image("fruit_blueberry_friendly")
                .resizable()
                .scaledToFit()
                .frame(width: 66)
                .accessibilityHidden(true)

            Text("your bookshelf is waiting. :-)")
                .font(.custom("Chalkboard SE", size: 17))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            Text(
                "save things from Ask the Encyclopedia, then bring your favorites together here."
            )
            .font(.custom("Chalkboard SE", size: 12.5))
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
            .multilineTextAlignment(.center)
            .frame(maxWidth: 270)

            if store.prompt11AllSavedMaterial().isEmpty {
                Text(
                    "you’ll need something saved before your first guide has pages to gather."
                )
                .font(.custom("Chalkboard SE", size: 11))
                .foregroundStyle(
                    DesignTokens.ColorToken.secondaryBurgundy
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 270)
            }

            Prompt10PillArtButton(
                label: "make my first guide",
                reduceMotion: motionPreferences.reduceMotionActive
            ) {
                setGuideOverlay(.createGuide)
            }
            .accessibilityIdentifier("guide.create.open")

            Button("go to ask") {
                audioManager.play(.buttonSoftPop)
                onGoToAsk()
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

    private var guideGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 22, alignment: .top),
                GridItem(.flexible(), spacing: 22, alignment: .top)
            ],
            spacing: 24
        ) {
            Prompt11NewGuideTile(
                reduceMotion: motionPreferences.reduceMotionActive
            ) {
                audioManager.play(.buttonSoftPop)
                setGuideOverlay(.createGuide)
            }

            ForEach(store.prompt11Guides) { guide in
                Prompt11GuideBookTile(
                    encyclopedia: guide,
                    reduceMotion: motionPreferences.reduceMotionActive
                ) {
                    audioManager.play(.pageTurn)

                    withAnimation(openAnimation) {
                        selectedGuideID = guide.id
                        searchText = ""
                        reorderMode = false
                        showingGuideOptions = false
                    }
                }
            }
        }
    }

    private func workspace(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    workspaceHeader(guide)
                    Prompt10LibraryStorageNotice(store: store)
                    if let reorderErrorMessage {
                        FruitfolioTranslatedText(source: reorderErrorMessage,
                            font: .custom("Chalkboard SE", size: 14, relativeTo: .body), serious: true)
                            .accessibilityIdentifier("guide.reorder.error")
                    }

                    guideCoverEnvironment(guide)

                    if showingGuideOptions {
                        guideOptions(guide)
                    }

                    guideProgress(guide)

                    if guide.savedPageCount >= 8 {
                        guideSearch(guide, proxy: proxy)
                    }

                    tableOfContents(guide, proxy: proxy)

                    HStack(spacing: 10) {
                        Prompt10PillArtButton(
                            label: "+ add saved pages",
                            reduceMotion: motionPreferences.reduceMotionActive
                        ) {
                            setGuideOverlay(.addSavedPages(guide.id))
                        }
                        .accessibilityIdentifier("guide.savedPages.open")

                        Prompt11GuideIconButton(
                            assetName: "guide_sort",
                            identificationWord: "sort",
                            accessibilityLabel: "Reorder guide",
                            reduceMotion: motionPreferences.reduceMotionActive,
                            width: 34
                        ) {
                            audioManager.play(.buttonSoftPop)

                            withAnimation(
                                motionPreferences.reduceMotionActive
                                    ? .easeOut(duration: 0.12)
                                    : .easeOut(duration: 0.20)
                            ) {
                                reorderMode.toggle()
                            }
                        }
                        .accessibilityIdentifier("guide.reorder.toggle")
                    }

                    Button("+ new section") {
                        audioManager.play(.buttonSoftPop)
                        setGuideOverlay(.addSection(guide.id))
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

                    sections(guide)

                    Button("read my guide") {
                        audioManager.play(.pageTurn)
                        showingReadMode = true
                    }
                    .font(.custom("Chalkboard SE", size: 12))
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
                    .disabled(guide.savedPageCount == 0)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func workspaceHeader(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        VStack(spacing: 4) {
            ZStack {
                HStack {
                    Prompt11GuideIconButton(
                        assetName: "guide_back",
                        identificationWord: "back",
                        accessibilityLabel: "Back",
                        reduceMotion: motionPreferences.reduceMotionActive,
                        width: 34
                    ) {
                        audioManager.play(.pageTurn)

                        withAnimation(openAnimation) {
                            selectedGuideID = nil
                            showingGuideOptions = false
                            reorderMode = false
                            searchText = ""
                        }
                    }

                    Spacer()

                    Button("guide options") {
                        audioManager.play(.buttonSoftPop)

                        withAnimation(
                            motionPreferences.reduceMotionActive
                                ? .easeOut(duration: 0.12)
                                : .easeOut(duration: 0.20)
                        ) {
                            showingGuideOptions.toggle()
                        }
                    }
                    .accessibilityIdentifier("guide.options.open")
                    .font(.custom("Chalkboard SE", size: 10.5))
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

                Text(guide.name)
                    .font(.custom("Chalkboard SE", size: 22))
                    .fontWeight(.bold)
                    .foregroundStyle(
                        DesignTokens.ColorToken.primaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .padding(.horizontal, 94)
            }

            Text(
                "\(guide.savedPageCount) \(guide.savedPageCount == 1 ? "saved page" : "saved pages")"
            )
            .font(.custom("Chalkboard SE", size: 11))
            .foregroundStyle(
                DesignTokens.ColorToken.secondaryBurgundy
            )
        }
        .padding(.top, 10)
    }

    private func guideCoverEnvironment(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        ZStack {
            Image(guide.style.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 104)
                .accessibilityHidden(true)

            if let subtitle = guide.subtitle,
               !subtitle.isEmpty {
                Text(subtitle)
                    .font(.custom("Chalkboard SE", size: 9.5))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .frame(width: 160)
                    .offset(y: 80)
            }
        }
        .frame(height: 220)
    }

    private func guideOptions(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Button {
                    audioManager.play(.buttonSoftPop)
                    setGuideOverlay(.renameGuide(guide.id, guide.name))
                } label: {
                    HStack(spacing: 5) {
                        Image("guide_rename")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 28, height: 28)
                            .accessibilityHidden(true)

                        Text("rename")
                    }
                }

                Button("change cover") {
                    audioManager.play(.buttonSoftPop)
                    setGuideOverlay(.changeCover(guide.id, guide.style))
                }

                Button("description") {
                    audioManager.play(.buttonSoftPop)
                    setGuideOverlay(.editDescription(
                        guide.id,
                        guide.subtitle ?? ""
                    ))
                }
                .accessibilityIdentifier("guide.description.open")
            }

            Button {
                audioManager.play(.buttonSoftPop)
                setGuideOverlay(.deleteGuide(guide.id))
            } label: {
                HStack(spacing: 5) {
                    Image("guide_delete")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .accessibilityHidden(true)

                    Text("delete guide")
                }
            }
        }
        .font(.custom("Chalkboard SE", size: 10.5))
        .fontWeight(.bold)
        .foregroundStyle(
            DesignTokens.ColorToken.primaryBurgundy
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.80),
            in: RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
        )
        .buttonStyle(
            CutePopButtonStyle(
                reduceMotion: motionPreferences.reduceMotionActive
            )
        )
    }

    private func guideProgress(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        Text(
            "\(guide.chapterCount) \(guide.chapterCount == 1 ? "section" : "sections") · \(guide.savedPageCount) \(guide.savedPageCount == 1 ? "page" : "pages")"
        )
        .font(.custom("Chalkboard SE", size: 10.5))
        .foregroundStyle(
            DesignTokens.ColorToken.secondaryBurgundy
        )
    }

    private func guideSearch(
        _ guide: Prompt10Encyclopedia,
        proxy: ScrollViewProxy
    ) -> some View {
        VStack(spacing: 7) {
            FruitfolioFixedTextField("find something in this guide…", text: $searchText)
                .font(.custom("Chalkboard SE", size: 12))
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(
                    DesignTokens.ColorToken.backgroundCream.opacity(0.82),
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )

            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let matches = searchMatches(in: guide)

                if matches.isEmpty {
                    Text("nothing matched this little search.")
                        .font(.custom("Chalkboard SE", size: 10.5))
                        .foregroundStyle(
                            DesignTokens.ColorToken.secondaryBurgundy
                        )
                } else {
                    VStack(spacing: 4) {
                        ForEach(Array(matches.prefix(6))) { match in
                            Button {
                                withAnimation(openAnimation) {
                                    proxy.scrollTo(match.page.id, anchor: .top)
                                }
                            } label: {
                                HStack {
                                    Text(match.page.question.isEmpty ? "saved page" : match.page.question)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(match.section)
                                        .font(.custom("Chalkboard SE", size: 9.5))
                                }
                                .font(.custom("Chalkboard SE", size: 10.5))
                                .foregroundStyle(
                                    DesignTokens.ColorToken.primaryBurgundy
                                )
                                .frame(minHeight: 38)
                            }
                            .buttonStyle(
                                CutePopButtonStyle(
                                    reduceMotion: motionPreferences.reduceMotionActive
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    private func tableOfContents(
        _ guide: Prompt10Encyclopedia,
        proxy: ScrollViewProxy
    ) -> some View {
        let entries = store.prompt11TableOfContents(for: guide.id)

        return VStack(alignment: .leading, spacing: 7) {
            Text("contents")
                .font(.custom("Chalkboard SE", size: 15))
                .fontWeight(.bold)
                .foregroundStyle(
                    DesignTokens.ColorToken.primaryBurgundy
                )

            if entries.isEmpty {
                Text("your sections will gather here as you build.")
                    .font(.custom("Chalkboard SE", size: 11))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )

            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        audioManager.play(.pageTurn)

                        withAnimation(openAnimation) {
                            proxy.scrollTo(entry.id, anchor: .top)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(String(format: "%02d", index + 1))
                                .fontWeight(.bold)

                            Text(entry.sectionName)
                                .lineLimit(1)

                            Spacer()

                            Text("\(entry.firstPageNumber)")
                        }
                        .font(.custom("Chalkboard SE", size: 11))
                        .foregroundStyle(
                            DesignTokens.ColorToken.primaryBurgundy
                        )
                        .frame(minHeight: 38)
                    }
                    .buttonStyle(
                        CutePopButtonStyle(
                            reduceMotion: motionPreferences.reduceMotionActive
                        )
                    )
                }
            }
        }
        .padding(14)
        .background(
            DesignTokens.ColorToken.backgroundCream.opacity(0.72),
            in: RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
    }

    private func sections(
        _ guide: Prompt10Encyclopedia
    ) -> some View {
        let sortedChapters = guide.chapters.sorted { $0.order < $1.order }

        return VStack(spacing: 18) {
            if sortedChapters.isEmpty {
                Text("make a section, then tuck your saved pages inside! <3")
                    .font(.custom("Chalkboard SE", size: 12))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 18)
            }

            ForEach(sortedChapters) { chapter in
                section(
                    guide: guide,
                    chapter: chapter,
                    isFirst: chapter.id == sortedChapters.first?.id,
                    isLast: chapter.id == sortedChapters.last?.id
                )
                .id(chapter.id)
            }
        }
    }

    private func section(
        guide: Prompt10Encyclopedia,
        chapter: Prompt10Chapter,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        VStack(spacing: 12) {
            Prompt11SectionDivider(
                title: chapter.name,
                pageCount: chapter.pages.count
            )

            HStack(spacing: 10) {
                Button("rename") {
                    setGuideOverlay(.renameSection(
                        guide.id,
                        chapter.id,
                        chapter.name
                    ))
                }

                if reorderMode {
                    Button("move up") {
                        moveChapter(guide.id, chapter.id, offset: -1)
                    }
                    .accessibilityIdentifier("guide.section.moveUp." + chapter.id.uuidString)
                    .disabled(isFirst)

                    Button("move down") {
                        moveChapter(guide.id, chapter.id, offset: 1)
                    }
                    .accessibilityIdentifier("guide.section.moveDown." + chapter.id.uuidString)
                    .disabled(isLast)
                }
            }
            .font(.custom("Chalkboard SE", size: 10.5))
            .fontWeight(.bold)
            .foregroundStyle(
                DesignTokens.ColorToken.primaryBurgundy
            )
            .buttonStyle(
                CutePopButtonStyle(
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            )

            if chapter.pages.isEmpty {
                Text("nothing tucked into this section yet!")
                    .font(.custom("Chalkboard SE", size: 11))
                    .foregroundStyle(
                        DesignTokens.ColorToken.secondaryBurgundy
                    )
                    .padding(.vertical, 12)
            }

            let sortedPages = chapter.pages.sorted { $0.order < $1.order }

            ForEach(sortedPages) { page in
                VStack(spacing: 7) {
                    Prompt11SavedPagePaper(
                        page: page,
                        pageNumber: pageNumber(for: page.id, in: guide),
                        sourceStillExists: sourceStillExists(page),
                        onAddNote: {
                            setGuideOverlay(.addNote(
                                guide.id,
                                chapter.id,
                                page.id,
                                page.notes
                            ))
                        }
                    )
                    .id(page.id)

                    pageActions(
                        guide: guide,
                        chapter: chapter,
                        page: page,
                        isFirst: page.id == sortedPages.first?.id,
                        isLast: page.id == sortedPages.last?.id
                    )
                }
            }
        }
    }

    private func pageActions(
        guide: Prompt10Encyclopedia,
        chapter: Prompt10Chapter,
        page: Prompt10SavedPage,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        Menu("page options") {
            Button("move") {
                setGuideOverlay(.movePage(
                    guide.id,
                    chapter.id,
                    page.id
                ))
            }

            Button("add a note") {
                setGuideOverlay(.addNote(
                    guide.id,
                    chapter.id,
                    page.id,
                    page.notes
                ))
            }

            if let sourceKey = page.sourceSavedPageID {
                Button("view original") {
                    setGuideOverlay(.viewOriginal(sourceKey))
                }
            }

            if reorderMode {
                Button("move up") {
                    movePage(
                        guide.id,
                        chapter.id,
                        page.id,
                        offset: -1
                    )
                }
                .disabled(isFirst)

                Button("move down") {
                    movePage(
                        guide.id,
                        chapter.id,
                        page.id,
                        offset: 1
                    )
                }
                .disabled(isLast)
            }

            Button("remove from guide") {
                setGuideOverlay(.removePage(
                    guide.id,
                    chapter.id,
                    page.id
                ))
            }
        }
        .font(.custom("Chalkboard SE", size: 10.5))
        .fontWeight(.bold)
        .foregroundStyle(
            DesignTokens.ColorToken.primaryBurgundy
        )
        .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
    }

    @ViewBuilder
    private var overlayLayer: some View {
        switch overlay {
        case .none:
            EmptyView()

        case .createGuide:
            Prompt11CreateGuidePopup(
                store: store,
                onCreated: { guideID in
                    setGuideOverlay(nil)
                    selectedGuideID = guideID
                    audioManager.play(.pageTurn)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .renameGuide(let guideID, let currentName):
            Prompt11RenameGuidePopup(
                store: store,
                encyclopediaID: guideID,
                currentName: currentName,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .editDescription(let guideID, let currentDescription):
            Prompt11DescriptionPopup(
                store: store,
                encyclopediaID: guideID,
                currentDescription: currentDescription,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .changeCover(let guideID, let currentStyle):
            Prompt11ChangeCoverPopup(
                store: store,
                encyclopediaID: guideID,
                currentStyle: currentStyle,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .deleteGuide(let guideID):
            Prompt11DeleteGuidePopup(
                store: store,
                encyclopediaID: guideID,
                onDeleted: {
                    setGuideOverlay(nil)
                    selectedGuideID = nil
                    showingGuideOptions = false
                    reorderMode = false
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .addSection(let guideID):
            Prompt11SectionPopup(
                store: store,
                encyclopediaID: guideID,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .renameSection(let guideID, let chapterID, let currentName):
            Prompt11SectionPopup(
                store: store,
                encyclopediaID: guideID,
                chapterID: chapterID,
                initialName: currentName,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .addNote(let guideID, let chapterID, let pageID, let currentNote):
            Prompt11NotePopup(
                store: store,
                encyclopediaID: guideID,
                chapterID: chapterID,
                pageID: pageID,
                initialNote: currentNote,
                onSaved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .addSavedPages(let guideID):
            Prompt11SavedPagePicker(
                store: store,
                encyclopediaID: guideID,
                onAdded: { count in
                    let wasEmpty = store.encyclopedia(id: guideID)?.savedPageCount == count
                    setGuideOverlay(nil)
                    showSavedStatus()

                    if wasEmpty && count > 0 {
                        showFirstPageCelebration()
                    }
                },
                onNeedsSection: {
                    setGuideOverlay(.addSection(guideID))
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .movePage(let guideID, let chapterID, let pageID):
            Prompt11MovePagePopup(
                store: store,
                encyclopediaID: guideID,
                fromChapterID: chapterID,
                pageID: pageID,
                onMoved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onNewSection: {
                    setGuideOverlay(.addSection(guideID))
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .removePage(let guideID, let chapterID, let pageID):
            Prompt11RemovePagePopup(
                store: store,
                encyclopediaID: guideID,
                chapterID: chapterID,
                pageID: pageID,
                onRemoved: {
                    setGuideOverlay(nil)
                    showSavedStatus()
                },
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )

        case .viewOriginal(let sourceKey):
            Prompt11OriginalAnswerPopup(
                sourcePage: store.prompt11SourcePage(sourceKey: sourceKey),
                onDismiss: {
                    setGuideOverlay(nil)
                },
                isCurrent: formIsCurrent(formSession.ticket)
            )
        }
    }

    private var savedStatus: some View {
        GeometryReader { geometry in
            let metrics = FruitfolioPopupLayout.saveConfirmation(available: geometry.size,
                expanded: dynamicTypeSize.isAccessibilitySize || settings.language != .english)
            ZStack {
                FruitfolioImage(id: .control_large_card)
                    .scaledToFit()
                    .frame(width: metrics.paperSize.width, height: metrics.paperSize.height)
                    .accessibilityHidden(true)
                ScrollView {
                    VStack(spacing: 10) {
                        FruitfolioImage(id: .fruit_strawberry_silly)
                            .scaledToFit()
                            .frame(width: min(72, metrics.paperSize.width * 0.30))
                            .accessibilityHidden(true)
                        FruitfolioFixedText(source: "saved!",
                            font: .custom("Chalkboard SE", size: 16, relativeTo: .body))
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("guide.savedConfirmation.label")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
                .frame(width: metrics.writingSize.width, height: metrics.writingSize.height)
                .accessibilityIdentifier("guide.savedConfirmation.content")
            }
            .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .transition(.opacity)
        .accessibilityIdentifier("guide.savedConfirmation")
    }

    private func searchMatches(
        in guide: Prompt10Encyclopedia
    ) -> [Prompt11GuideSearchMatch] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanSearch.isEmpty else {
            return []
        }

        return guide.chapters
            .sorted { $0.order < $1.order }
            .flatMap { chapter in
                chapter.pages
                    .sorted { $0.order < $1.order }
                    .filter { page in
                        page.question.localizedCaseInsensitiveContains(cleanSearch) ||
                            page.displayBody.localizedCaseInsensitiveContains(cleanSearch) ||
                            page.notes.localizedCaseInsensitiveContains(cleanSearch)
                    }
                    .map { page in
                        Prompt11GuideSearchMatch(
                            page: page,
                            section: chapter.name
                        )
                    }
            }
    }

    private func pageNumber(
        for pageID: UUID,
        in guide: Prompt10Encyclopedia
    ) -> Int? {
        let pages = guide.chapters
            .sorted { $0.order < $1.order }
            .flatMap { chapter in
                chapter.pages.sorted { $0.order < $1.order }
            }

        guard let index = pages.firstIndex(where: { $0.id == pageID }) else {
            return nil
        }

        return index + 1
    }

    private func sourceStillExists(
        _ page: Prompt10SavedPage
    ) -> Bool {
        guard let sourceKey = page.sourceSavedPageID else {
            return true
        }

        return store.prompt11SourcePage(sourceKey: sourceKey) != nil
    }

    private func moveChapter(
        _ guideID: UUID,
        _ chapterID: UUID,
        offset: Int
    ) {
        do {
            guard try store.moveChapter(
                encyclopediaID: guideID,
                chapterID: chapterID,
                offset: offset
            ) else { return }
            reorderErrorMessage = nil
            audioManager.play(.pageTurn)
            showSavedStatus()
        } catch {
            reorderErrorMessage = store.storageProtectionReason == nil ? error.localizedDescription : nil
        }
    }

    private func movePage(
        _ guideID: UUID,
        _ chapterID: UUID,
        _ pageID: UUID,
        offset: Int
    ) {
        do {
            guard try store.movePageWithinChapter(
                encyclopediaID: guideID,
                chapterID: chapterID,
                pageID: pageID,
                offset: offset
            ) else { return }
            reorderErrorMessage = nil
            audioManager.play(.pageTurn)
            showSavedStatus()
        } catch {
            reorderErrorMessage = store.storageProtectionReason == nil ? error.localizedDescription : nil
        }
    }

    private func setGuideOverlay(_ next: Prompt11Overlay?) {
        if next != nil { dismissSavedStatus() }
        for cue in formSession.transition(to: next) {
            audioManager.play(cue == .open ? .popupOpen : .popupClose)
        }
    }

    private func formIsCurrent(_ ticket: Prompt11GuideFormTicket?) -> @MainActor () -> Bool {
        let owner = formSession
        return { [weak owner] in owner?.isCurrent(ticket) == true }
    }

    private func dismissSavedStatus() {
        savedStatusTask?.cancel()
        savedStatusTask = nil
        if savedStatusVisible { audioManager.play(.popupClose) }
        savedStatusVisible = false
    }

    private func showSavedStatus() {
        #if DEBUG
        savedStatusRequests += 1
        #endif
        savedStatusTask?.cancel()
        if !savedStatusVisible { audioManager.play(.popupOpen) }
        savedStatusVisible = true
        savedStatusGuideID = selectedGuideID
        if voiceOverEnabled {
            UIAccessibility.post(notification: .announcement,
                                 argument: settings.localized("saved!"))
        }
        let delay: Double = voiceOverEnabled || dynamicTypeSize.isAccessibilitySize || settings.language != .english ? 4.0 : 1.35
        savedStatusTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(delay)) }
            catch { return }
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.16)) { savedStatusVisible = false }
            audioManager.play(.popupClose)
            savedStatusTask = nil
        }
    }

    private func showFirstPageCelebration() {
        // The same compact Strawberry card is already shown by the save action.
        // Do not stack a second toast or launch another dismissal timer.
        audioManager.play(.gentleCheer)
    }

    private var openAnimation: Animation {
        motionPreferences.reduceMotionActive
            ? .easeOut(duration: 0.14)
            : .easeOut(duration: 0.30)
    }
}
