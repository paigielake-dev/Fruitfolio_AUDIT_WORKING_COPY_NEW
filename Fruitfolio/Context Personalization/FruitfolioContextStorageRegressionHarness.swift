#if DEBUG
import SwiftUI

@MainActor
private final class FruitfolioContextStorageFixture: ObservableObject {
    let store: Prompt27AContextStore
    let setupFailure: String?
    private let suite = "Fruitfolio.contextStorageUIQA." + UUID().uuidString
    private let defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: suite)!
        var failure: String?
        do {
            var context = Prompt27AUserReproductiveContext(timestamp: Date(timeIntervalSince1970: 0))
            context.setTrackingGoal(.tryingToConceive, at: Date(timeIntervalSince1970: 10))
            try context.setPersonalHealth(.thyroid, text: "QA user-provided context fixture", at: Date(timeIntervalSince1970: 20))
            let bytes = try Prompt27AContextCodec().encode(context)
            var object = try JSONSerialization.jsonObject(with: bytes) as! [String: Any]
            object["futureQAField"] = ["revision": 99]
            defaults.set(try JSONSerialization.data(withJSONObject: object), forKey: "fixture")
        } catch { failure = "context QA fixture could not be prepared" }
        setupFailure = failure
        store = Prompt27AContextStore(defaults: defaults, key: "fixture")
    }
    func cleanUp() { defaults.removePersistentDomain(forName: suite) }
}

struct FruitfolioContextStorageRegressionHarness: View {
    @StateObject private var fixture = FruitfolioContextStorageFixture()
    @State private var presented = true
    @EnvironmentObject private var settings: SettingsStore
    var body: some View {
        Group {
            if let failure = fixture.setupFailure { Text(failure) }
            else if presented { Prompt27AMyContextView(store: fixture.store, onBack: { presented = false }) }
            else { Button("open context QA") { presented = true } }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioContextReduceMotion")
        }
        .onDisappear { fixture.cleanUp() }
    }
}
#endif
