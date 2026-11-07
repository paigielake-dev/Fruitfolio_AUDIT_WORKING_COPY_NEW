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
    @State private var presented = false
    @State private var initialized = false
    @EnvironmentObject private var audio: AudioManager
    @AccessibilityFocusState private var openerFocused: Bool
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var motion: MotionPreferences
    var body: some View {
        ZStack {
            Button("data QA background") { openerFocused = false; presented = true }
                .accessibilityFocused($openerFocused)
                .accessibilityIdentifier("dataQA.background")
                .fruitfolioModalBlur(active: presented, reduceMotion: motion.reduceMotionActive)
            if presented {
                FruitfolioModalBackdrop().accessibilityHidden(true).allowsHitTesting(false)
                Prompt12DataManagementView(store: fixture.store, mode: .popup, onBack: {
                    presented = false
                    Task { @MainActor in
                        await Task.yield()
                        guard !presented else { return }
                        openerFocused = true
                    }
                },
                    exportPreferences: { try FruitfolioLocalDataExport.capturePreferences(defaults: fixture.defaults) },
                    exportApplicationSupport: fixture.support)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                FruitfolioInteractionSoundDiagnostics()
            }
        }
        .task {
            guard !initialized else { return }
            initialized = true
            settings.language = .english
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioDataReduceMotion")
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioDiagnostics") {
                settings.globallyMuted = ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioMuted")
                audio.debugRecordInteractions(true)
            }
            presented = true
        }
        .onDisappear {
            audio.debugRecordInteractions(false)
            fixture.cleanUp()
        }
    }
}
#endif
