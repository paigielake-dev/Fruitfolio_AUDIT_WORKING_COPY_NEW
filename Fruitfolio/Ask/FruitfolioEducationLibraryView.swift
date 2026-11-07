import SwiftUI
import UIKit

/// A visit owned by the existing Ask presentation. Only explicit page actions
/// prepare sources or a save payload; navigation never depends on predictions.
@MainActor
private final class FruitfolioEducationVisit: ObservableObject {
    @Published var path = NavigationPath()
    @Published var sources: [AskSourceRecord] = []
    @Published var sourceTitle = "approved sources"
    @Published var showingSources = false
    @Published var pendingSave: Prompt10PendingSavedContent?
    @Published var status: String?
    @Published private(set) var loading = false
    let research: FruitfolioEducationResearch
    weak var popups: PopupCoordinator?
    var visible = false
    var active = false
    private var operation: Task<Void, Never>?
    private var generation = UUID()

    init(research: FruitfolioEducationResearch) { self.research = research }
    private var canAct: Bool {
        visible && active && UIApplication.shared.applicationState == .active &&
            popups?.currentPopup == nil && !showingSources && pendingSave == nil
    }
    func cancelRead() {
        generation = UUID()
        operation?.cancel()
        operation = nil
        loading = false
    }
    private func owns(_ id: UUID, path expected: NavigationPath) -> Bool {
        canAct && generation == id && path == expected && !Task.isCancelled
    }
    func openSources(_ ids: [String]) {
        guard canAct, !ids.isEmpty else { return }
        cancelRead()
        let identity = generation, expected = path, research = research
        loading = true
        operation = Task { @MainActor [weak self] in
            do {
                let records = try await research.sourceRecords(ids: ids)
                guard let self, self.owns(identity, path: expected) else { return }
                self.sources = records
                self.sourceTitle = "approved sources"
                self.showingSources = true
                self.loading = false
                self.operation = nil
            } catch {
                guard let self, self.owns(identity, path: expected) else { return }
                self.status = "approved source details aren’t available for this page yet."
                self.loading = false
                self.operation = nil
            }
        }
    }
    func save(_ contentID: String) {
        guard canAct else { return }
        cancelRead()
        let identity = generation, expected = path, research = research
        loading = true
        operation = Task { @MainActor [weak self] in
            do {
                let article = try await research.article(for: contentID)
                let pending = try article.prepareSave()
                guard let self, self.owns(identity, path: expected) else { return }
                self.pendingSave = pending
                self.loading = false
                self.operation = nil
            } catch {
                guard let self, self.owns(identity, path: expected) else { return }
                self.status = "this page has no complete, versioned approved source yet; nothing was saved."
                self.loading = false
                self.operation = nil
            }
        }
    }
    func openFertilization() {
        guard canAct else { return }
        cancelRead()
        path.append(FruitfolioEducationCollection.fertilization)
    }
    deinit { operation?.cancel() }
}

@MainActor
struct FruitfolioEducationLibraryView: View {
    @StateObject private var visit: FruitfolioEducationVisit
    @ObservedObject private var library: Prompt10SavedLibraryStore
    @EnvironmentObject private var popups: PopupCoordinator
    @EnvironmentObject private var audio: AudioManager
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.scenePhase) private var scenePhase
    private let onClose: () -> Void
    private let onAsk: (String) -> Void

    init(library: Prompt10SavedLibraryStore, research: FruitfolioEducationResearch = .shared,
         onClose: @escaping () -> Void, onAsk: @escaping (String) -> Void) {
        _library = ObservedObject(wrappedValue: library)
        _visit = StateObject(wrappedValue: FruitfolioEducationVisit(research: research))
        self.onClose = onClose
        self.onAsk = onAsk
    }

    var body: some View {
        NavigationStack(path: $visit.path) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    FruitfolioFixedText(source: "explore encyclopedia education",
                        font: .custom("Chalkboard SE", size: 22, relativeTo: .title2), serious: true)
                        .accessibilityAddTraits(.isHeader)
                    FruitfolioFixedText(source: "open an illustrated topic when you choose. viewing pregnancy or fertilization education does not mean either has occurred.",
                        font: .custom("Chalkboard SE", size: 15, relativeTo: .body), serious: true)
                    ForEach(FruitfolioEducationCollection.allCases) { collection in
                        NavigationLink(value: collection) {
                            FruitfolioFixedText(source: collection.title,
                                font: .custom("Chalkboard SE", size: 15, relativeTo: .body), serious: true)
                                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }
                        .buttonStyle(CutePopButtonStyle())
                        .accessibilityIdentifier("education.collection." + collection.rawValue)
                    }
                    FruitfolioFixedText(source: "pages show complete excerpts available in the approved local library, not a complete textbook or a personal assessment. detailed sections without approved content remain unavailable.", font: .footnote, serious: true)
                }
                .padding(20)
                .frame(maxWidth: DesignTokens.Layout.compactReadingMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .background(DesignTokens.ColorToken.backgroundCream)
            .navigationTitle(Text(verbatim: settings.localized("education")))
            .navigationDestination(for: FruitfolioEducationCollection.self) { destination in
                collection(destination)
            }
            .navigationDestination(for: Prompt27ScienceAssetID.self) { id in
                if let asset = Prompt27ScientificAssetCatalog().asset(for: id) { sciencePage(asset) }
            }
        }
        .tint(DesignTokens.ColorToken.primaryBurgundy)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                FruitfolioControlPillButton(label: "close", action: onClose)
                    .modifier(FruitfolioFixedAccessibilityLabel(source: "close education"))
                    .accessibilityIdentifier("education.close")
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if !visit.path.isEmpty {
                    FruitfolioFixedText(source: "educational research excerpts, not a diagnosis or a personal treatment recommendation.",
                        font: .custom("Chalkboard SE", size: 12, relativeTo: .footnote), serious: true).padding(8)
                }
                if visit.loading { ProgressView().padding(8) }
                if let status = visit.status {
                    FruitfolioFixedText(source: status,
                        font: .custom("Chalkboard SE", size: 12, relativeTo: .footnote), serious: true).padding(12)
                }
            }.background(DesignTokens.ColorToken.backgroundCream)
        }
        .sheet(isPresented: $visit.showingSources) {
            FruitfolioPresentedPopupHost {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        BackControl(action: { visit.showingSources = false })
                            .accessibilityIdentifier("education.sources.back")
                        FruitfolioFixedText(source: visit.sourceTitle, font: .headline, serious: true)
                            .accessibilityAddTraits(.isHeader)
                        FruitfolioSourceCitationList(sources: visit.sources)
                    }.padding(20)
                }
            }
        }
        .sheet(isPresented: Binding(get: { visit.pendingSave != nil }, set: { if !$0 { visit.pendingSave = nil } })) {
            if let pending = visit.pendingSave {
                FruitfolioPresentedPopupHost {
                    Prompt10AskSaveDestination(store: library, pending: pending,
                        onSaved: { visit.pendingSave = nil; visit.status = "saved to your encyclopedia ♡" },
                        onCancel: { visit.pendingSave = nil })
                }
            }
        }
        .onAppear { visit.visible = true; visit.active = scenePhase == .active; visit.popups = popups }
        .onChange(of: scenePhase) { _, phase in
            visit.active = phase == .active
            if !visit.active { visit.cancelRead() }
        }
        .onChange(of: visit.path) { _, _ in
            visit.cancelRead()
            visit.status = nil
            audio.play(.pageTurn)
        }
        .onDisappear { visit.visible = false; visit.cancelRead() }
    }

    @ViewBuilder
    private func collection(_ destination: FruitfolioEducationCollection) -> some View {
        switch destination {
        case .fertilization:
            Prompt25FertilizationModule(contentProvider: FruitfolioFertilizationResearchAdapter(research: visit.research),
                onBack: { if !visit.path.isEmpty { visit.path.removeLast() } },
                onSources: { stage in
                    visit.openSourcesForStage(stage)
                },
                onAsk: { stage in onAsk("explain the " + stage.title + " stage of fertilization.") },
                onSave: { stage in visit.save(stage.shortContentID) },
                onRelatedTopic: { topic in
                    visit.cancelRead()
                    switch topic {
                    case .implantation, .earlyPregnancyBiology:
                        visit.path.append(FruitfolioEducationCollection.pregnancy)
                        visit.path.append(Prompt26PregnancyTopicID.earlyDevelopment)
                    case .ovulation: onAsk("explain ovulation biology.")
                    case .reproductiveAnatomy: onAsk("explain reproductive anatomy.")
                    case .menstrualCycleBiology: onAsk("explain menstrual cycle biology.")
                    }
                },
                onPageSound: { visit.cancelRead(); audio.play(.pageTurn) })
                .navigationBarBackButtonHidden(true)
        case .pregnancy:
            Prompt26PregnancyEducationRootView(provider: FruitfolioPregnancyResearchAdapter(research: visit.research),
                actions: .init(openSources: { [weak visit] ids in Task { @MainActor in visit?.openSources(ids) } },
                    saveEducationEntry: { [weak visit] entry in Task { @MainActor in visit?.save(entry.contentID) } },
                    openFertilizationEducation: { [weak visit] in Task { @MainActor in visit?.openFertilization() } }),
                entryContext: .intentionalEncyclopediaOpen)
                .accessibilityIdentifier("education.module.pregnancy")
        case .genetics, .body, .laboratory:
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(scienceAssets(destination)) { asset in
                        NavigationLink(value: asset.id) {
                            FruitfolioFixedText(source: FruitfolioEducationResearch.title(for: asset),
                                protectedLiterals: ["DNA", "RNA", "PCR"],
                                font: .custom("Chalkboard SE", size: 15, relativeTo: .body), serious: true).frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        }.buttonStyle(CutePopButtonStyle())
                        .accessibilityIdentifier("education.asset." + asset.id.rawValue)
                    }
                }.padding(20)
            }.navigationTitle(Text(verbatim: settings.localized(destination.title)))
                .background(DesignTokens.ColorToken.backgroundCream)
        }
    }

    private func scienceAssets(_ collection: FruitfolioEducationCollection) -> [Prompt27ScientificAsset] {
        let family: Prompt27ScienceVisualFamily = collection == .genetics ? .genetics : (collection == .body ? .body : .lab)
        return Prompt27ScientificAssetCatalog().productionAssets.filter { $0.family == family }
    }

    private func sciencePage(_ asset: Prompt27ScientificAsset) -> some View {
        let id = FruitfolioEducationResearch.scienceID(for: asset)
        let section = Prompt27ContextualScienceSection(id: id,
            title: FruitfolioEducationResearch.title(for: asset),
            bodyContentID: id, primaryVisualFamily: asset.family, primaryIllustrationAssetID: asset.id,
            altText: asset.altText)
        return Prompt27ContextualScienceSectionView(section: section,
            provider: FruitfolioScienceResearchAdapter(research: visit.research),
            actions: .init(showSources: { [weak visit] ids in Task { @MainActor in visit?.openSources(ids) } },
                saveEducationalContent: { [weak visit] _ in Task { @MainActor in visit?.save(id) } }))
    }
}

extension FruitfolioEducationVisit {
    func openSourcesForStage(_ stage: Prompt25FertilizationStage) {
        // Stage navigation calls cancelRead synchronously through its existing
        // page callback, so an older stage cannot open a later page's sources.
        guard canAct else { return }
        cancelRead()
        let identity = generation, expected = path, research = research
        loading = true
        operation = Task { @MainActor [weak self] in
            do {
                let article = try await research.article(for: stage.shortContentID)
                guard let self, self.owns(identity, path: expected) else { return }
                self.sources = article.sources
                self.sourceTitle = "sources — " + stage.title
                self.showingSources = true
                self.loading = false
                self.operation = nil
            } catch {
                guard let self, self.owns(identity, path: expected) else { return }
                self.status = "approved source details aren’t available for this page yet."
                self.loading = false
                self.operation = nil
            }
        }
    }
}
