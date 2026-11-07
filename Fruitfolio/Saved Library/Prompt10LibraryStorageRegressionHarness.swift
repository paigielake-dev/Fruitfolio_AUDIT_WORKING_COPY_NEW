#if DEBUG
import SwiftUI

@MainActor
private final class Prompt10LibraryStorageFixture: ObservableObject {
    let store: Prompt10SavedLibraryStore
    let setupFailure: String?
    @Published private(set) var externalDeleteFailure: String?
    private let suite = "Fruitfolio.libraryStorageUIQA." + UUID().uuidString
    private let defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: suite)!
        var failure: String?
        do {
            let id = UUID(), chapterID = UUID()
            let page = Prompt10SavedPage(chapterID: chapterID, question: "QA fixture page",
                answer: "Nonmedical UI fixture. This page checks readable saved material only.", saveType: .fullAnswer,
                notes: "QA original note")
            let chapter = Prompt10Chapter(id: chapterID, encyclopediaID: id, name: "QA chapter", order: 0, pages: [page])
            let book = Prompt10Encyclopedia(id: id, name: "QA readable book", style: .sage, chapters: [chapter])
            let bytes = try JSONEncoder().encode([book])
            var objects = try JSONSerialization.jsonObject(with: bytes) as! [[String: Any]]
            if !ProcessInfo.processInfo.arguments.contains("-fruitfolioLibraryEditableFixture") {
                objects[0]["futureFixtureField"] = ["revision": 99]
            }
            defaults.set(try JSONSerialization.data(withJSONObject: objects), forKey: "fixture")
        } catch { failure = "library QA fixture could not be prepared" }
        setupFailure = failure
        store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
    }
    func deleteFixtureBookThroughSharedStore() {
        guard ProcessInfo.processInfo.arguments.contains("-fruitfolioLibraryExternalDeleteFixture"),
              let id = store.encyclopedias.first?.id else { return }
        do { try store.deleteEncyclopedia(id: id) }
        catch { externalDeleteFailure = "disposable shared-delete fixture failed" }
    }
    func cleanUp() { defaults.removePersistentDomain(forName: suite) }
}

struct Prompt10LibraryStorageRegressionHarness: View {
    @StateObject private var fixture = Prompt10LibraryStorageFixture()
    @State private var presented = true
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Group {
            if let failure = fixture.setupFailure { Text(failure) }
            else if presented {
                VStack(spacing: 0) {
                    if ProcessInfo.processInfo.arguments.contains("-fruitfolioLibraryExternalDeleteFixture") {
                        Button("delete disposable book through shared store") { fixture.deleteFixtureBookThroughSharedStore() }
                            .accessibilityIdentifier("libraryQA.externalDelete")
                        if let error = fixture.externalDeleteFailure {
                            Text(verbatim: error).accessibilityIdentifier("libraryQA.externalDeleteError")
                        }
                    }
                    Prompt10SavedLibraryView(store: fixture.store, onBack: { presented = false })
                }
            }
            else { Button("open library QA") { presented = true } }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioLibraryReduceMotion")
        }
        .onDisappear { fixture.cleanUp() }
    }
}
#endif
