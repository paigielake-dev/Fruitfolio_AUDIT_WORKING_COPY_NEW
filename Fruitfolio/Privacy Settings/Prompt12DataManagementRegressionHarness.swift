#if DEBUG
import SwiftUI

@MainActor
private final class Prompt12DataRegressionFixture: ObservableObject {
    let store: Prompt12AccountPrivacyStore
    private let suite = "Fruitfolio.dataUIQA." + UUID().uuidString
    private let defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: suite)!
        store = Prompt12AccountPrivacyStore(defaults: defaults)
    }
    func cleanUp() { defaults.removePersistentDomain(forName: suite) }
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
                Prompt12DataManagementView(store: fixture.store, mode: .popup, onBack: { presented = false })
            }
        }
        .onAppear {
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioDataReduceMotion")
        }
        .onDisappear { fixture.cleanUp() }
    }
}
#endif
