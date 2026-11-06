#if DEBUG
import SwiftUI

@MainActor
private final class Prompt12DataRegressionFixture: ObservableObject {
    let store: Prompt12AccountPrivacyStore
    private let suite = "Fruitfolio.dataUIQA." + UUID().uuidString
    let defaults: UserDefaults
    let support = FileManager.default.temporaryDirectory.appendingPathComponent("Fruitfolio.dataUIQA." + UUID().uuidString)
    init() {
        defaults = UserDefaults(suiteName: suite)!
        if ProcessInfo.processInfo.arguments.contains("-fruitfolioDataUnreadableAccount") {
            defaults.set(Data("unreadable UI fixture".utf8), forKey: "fruitfolio.prompt12.accountPrivacy.v1")
        }
        store = Prompt12AccountPrivacyStore(defaults: defaults)
    }
    func cleanUp() {
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: support)
    }
}

/// Popup/layout checks only: no measurement export or destructive operation is
/// invoked by setup. Feature-management buttons keep their production actions.
struct Prompt12DataManagementRegressionHarness: View {
    @StateObject private var fixture = Prompt12DataRegressionFixture()
    @State private var presented = true
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motion: MotionPreferences
    var body: some View {
        ZStack {
            Button("data QA background") { presented = true }
                .accessibilityIdentifier("dataQA.background")
                .fruitfolioModalBlur(active: presented, reduceMotion: motion.reduceMotionActive)
            if presented {
                DesignTokens.ColorToken.backgroundCream.opacity(FruitfolioModalBlurSpec.dimOpacity)
                    .ignoresSafeArea().accessibilityHidden(true)
                Prompt12DataManagementView(store: fixture.store, mode: .popup, onBack: { presented = false },
                    exportPreferences: { try FruitfolioLocalDataExport.capturePreferences(defaults: fixture.defaults) },
                    exportApplicationSupport: fixture.support)
            }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioDataReduceMotion")
        }
        .onDisappear { fixture.cleanUp() }
    }
}
#endif
