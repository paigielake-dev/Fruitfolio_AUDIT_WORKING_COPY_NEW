#if DEBUG
import SwiftUI

/// Fault injection is confined to this disposable fixture key; reads remain
/// genuine UserDefaults reads and all normal cases use the real setter.
private final class Prompt11GuideFaultDefaults: UserDefaults, @unchecked Sendable {
    var rejectLibraryWrites = false
    var libraryWriteAttempts = 0
    override func set(_ value: Any?, forKey key: String) {
        if key == "fruitfolio.guideSaveQA.library" {
            libraryWriteAttempts += 1
            if rejectLibraryWrites { return }
        }
        super.set(value, forKey: key)
    }
}

/// Nonclinical QA content, in a disposable suite. The actual Guide Builder,
/// popup callbacks and library persistence perform every edit/write.
@MainActor
private final class Prompt11GuideSaveFixture: ObservableObject {
    static let key = "fruitfolio.guideSaveQA.library"
    let defaults: UserDefaults
    let store: Prompt10SavedLibraryStore
    let initialGuideID: UUID?
    let baselineBytes: Data?
    let token = UUID().uuidString
    private let suite = "Fruitfolio.guideSaveUIQA." + UUID().uuidString
    init() {
        defaults = Prompt11GuideFaultDefaults(suiteName: suite)!
        store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: Self.key)
        let args = ProcessInfo.processInfo.arguments
        let scenario = args.firstIndex(of: "-fruitfolioGuideSaveQAScenario")
            .flatMap { $0 + 1 < args.count ? args[$0 + 1] : nil } ?? "description"
        if scenario == "create" { initialGuideID = nil }
        else {
            do {
                initialGuideID = try store.createGuideEncyclopedia(name: "QA original guide",
                    subtitle: "QA original description", style: .sage).id
            } catch { preconditionFailure("Could not create the private Guide Builder fixture") }
        }
        if ["pages", "batch-pages", "dropped-batch-pages"].contains(scenario), let guideID = initialGuideID {
            do {
                _ = try store.createChapter(in: guideID, name: "QA first section")
                _ = try store.createChapter(in: guideID, name: "QA second section")
                let source = try store.createEncyclopedia(name: "QA source book", style: .pink)
                let section = source.chapters[0]
                let page = Prompt10SavedPage(chapterID: section.id, question: "QA source page",
                    answer: "Nonclinical private fixture only.", saveType: .fullAnswer)
                _ = try store.savePage(page, to: source.id, chapterID: section.id)
                if scenario != "pages" {
                    let second = Prompt10SavedPage(chapterID: section.id, question: "QA second source page",
                        answer: "Second nonclinical private fixture.", saveType: .excerpt, excerptText: "Second fixture")
                    _ = try store.savePage(second, to: source.id, chapterID: section.id)
                }
            } catch { preconditionFailure("Could not create the private saved-page fixture") }
        }
        if scenario == "stale-description" {
            // A real external byte replacement after the store loaded: the
            // normal save baseline guard must reject it, not a fake UI flag.
            defaults.set(Data(#"{"futureSchema":3,"preserve":{"field":null}}"#.utf8), forKey: Self.key)
        }
        if ["dropped-description", "dropped-batch-pages"].contains(scenario) {
            (defaults as? Prompt11GuideFaultDefaults)?.rejectLibraryWrites = true
        }
        (defaults as? Prompt11GuideFaultDefaults)?.libraryWriteAttempts = 0
        baselineBytes = defaults.data(forKey: Self.key)
    }
    deinit { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
}

struct Prompt11GuideSaveRegressionHarness: View {
    @StateObject private var fixture = Prompt11GuideSaveFixture()
    @State private var configured = false
    @State private var savedStatusRequests = 0
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audio: AudioManager
    var body: some View {
        Prompt11GuideBuilderView(store: fixture.store, onBack: {}, onGoToAsk: {}, initialGuideID: fixture.initialGuideID)
            .onPreferenceChange(Prompt11GuideSavedStatusRequestKey.self) { savedStatusRequests = $0 }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading) {
                    Prompt11GuideSaveReadback(store: fixture.store, defaults: fixture.defaults,
                        baseline: fixture.baselineBytes, token: fixture.token, savedStatusRequests: savedStatusRequests,
                        guideID: fixture.initialGuideID)
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                        FruitfolioInteractionSoundDiagnostics()
                    }
                }.font(.caption2).allowsHitTesting(false)
            }
            .task {
                guard !configured else { return }
                configured = true
                let args = ProcessInfo.processInfo.arguments
                settings.language = .english // Layout-only RTL; no translation claim.
                settings.translationPausedForMemoryPressure = true
                settings.reduceAnimationOverride = args.contains("-fruitfolioGuideSaveReduceMotion")
                if args.contains("-fruitfolioAudioDiagnostics") { audio.debugRecordInteractions(true) }
            }
    }
}

@MainActor
private struct Prompt11GuideSaveReadback: View {
    @ObservedObject var store: Prompt10SavedLibraryStore
    let defaults: UserDefaults
    let baseline: Data?
    let token: String
    let savedStatusRequests: Int
    let guideID: UUID?
    var body: some View {
        // Independently load actual acknowledged bytes rather than equating
        // the editor's memory or a displayed “saved” label with persistence.
        let persisted = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: Prompt11GuideSaveFixture.key)
        VStack(alignment: .leading) {
            Text("persisted guide count: \(persisted.prompt11Guides.count)").accessibilityIdentifier("guideQA.persistedCount")
            Text("persisted name: " + (persisted.prompt11Guides.first?.name ?? "none")).accessibilityIdentifier("guideQA.persistedName")
            Text("persisted description: " + (persisted.prompt11Guides.first?.subtitle ?? "none")).accessibilityIdentifier("guideQA.persistedDescription")
            Text("original bytes intact: \(defaults.data(forKey: Prompt11GuideSaveFixture.key) == baseline)").accessibilityIdentifier("guideQA.originalBytesIntact")
            Text("library write attempts: \((defaults as? Prompt11GuideFaultDefaults)?.libraryWriteAttempts ?? -1)").accessibilityIdentifier("guideQA.writeAttempts")
            Text("write protected: \(store.storageProtectionReason != nil)").accessibilityIdentifier("guideQA.writeProtected")
            Text("fixture owner: " + token).accessibilityIdentifier("guideQA.owner")
            Text("saved status requests: \(savedStatusRequests)").accessibilityIdentifier("guideQA.savedStatusRequests")
            if let guideID, let guide = persisted.encyclopedia(id: guideID) {
                let sections = guide.chapters.sorted { $0.order < $1.order }
                Text("first section pages: \(sections.first?.pages.count ?? 0)").accessibilityIdentifier("guideQA.firstSectionPages")
                Text("second section pages: \(sections.count > 1 ? sections[1].pages.count : 0)").accessibilityIdentifier("guideQA.secondSectionPages")
            }
        }
    }
}
/// A count emitted by the actual save-status entry point; not a fabricated save.
nonisolated struct Prompt11GuideSavedStatusRequestKey: PreferenceKey {
    static let defaultValue = 0
    static func reduce(value: inout Int, nextValue: () -> Int) { value = max(value, nextValue()) }
}
#endif
