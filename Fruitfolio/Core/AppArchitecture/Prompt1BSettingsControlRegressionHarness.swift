#if DEBUG
import SwiftUI

/// The registered QA shell supplies its actual disposable SettingsStore, audio
/// and motion authorities. This scene has no production navigation/export path.
struct Prompt1BSettingsControlRegressionHarness: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var audio: AudioManager
    @State private var initialized = false
    var body: some View {
        ScrollView {
            if initialized {
                VStack(alignment: .leading, spacing: 24) {
                    WatercolorToggle(label: "sound effects", isOn: $settings.soundEffectsEnabled)
                        .accessibilityIdentifier("settingsControls.effects")
                    Prompt12VolumeRow(title: "sound effects", value: $settings.soundEffectsVolume)
                    Text("saved effects: \(settings.debugStoredEffects.enabled ? "true" : "false")")
                        .accessibilityIdentifier("settingsControls.savedEffects")
                    Text("saved volume: \(settings.debugStoredEffects.volume)")
                        .accessibilityIdentifier("settingsControls.savedVolume")
                }
                .padding(24)
            }
        }
        .overlay(alignment: .bottomTrailing) { FruitfolioInteractionSoundDiagnostics() }
        .task {
            guard !initialized else { return }
            settings.language = .english
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioSettingsControlsReduceMotion")
            settings.globallyMuted = ProcessInfo.processInfo.arguments.contains("-fruitfolioAudioMuted")
            settings.soundEffectsEnabled = false
            settings.soundEffectsVolume = 0.25
            audio.debugRecordInteractions(true)
            initialized = true
        }
        .onDisappear { audio.debugRecordInteractions(false) }
    }
}

/// Uses actual Settings and FAQ with the shell's shared language/locale objects.
/// Only the explicitly UUID-scoped DEBUG fixture can survive a test relaunch.
struct Prompt1BLanguagePersistenceRegressionHarness: View {
    @EnvironmentObject private var preferences: FruitfolioRegressionPreferenceSuite
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var direction
    @State private var store: Prompt12AccountPrivacyStore?
    @State private var showingFAQ = false
    @State private var cleared = false

    var body: some View {
        VStack(spacing: 0) {
            if let store {
                if showingFAQ {
                    Prompt29FAQView(onBack: { showingFAQ = false })
                } else {
                    Prompt12SettingsView(store: store, onBack: { showingFAQ = true },
                        onShowAccount: { showingFAQ = true }, onShowPrivacy: { showingFAQ = true })
                }
            } else { ProgressView() }
            VStack(spacing: 2) {
                Text("persistent fixture: \(preferences.isPersistentFixture ? "true" : "false")")
                    .accessibilityIdentifier("languagePersistence.fixture")
                Text("selected language: \(settings.language.rawValue)")
                    .accessibilityIdentifier("languagePersistence.selected")
                Text("saved language: \(preferences.defaults?.string(forKey: FruitfolioLanguagePreferences.defaultsKey) ?? "missing")")
                    .accessibilityIdentifier("languagePersistence.saved")
                Text("locale: \(locale.identifier); direction: \(direction == .rightToLeft ? "rtl" : "ltr")")
                    .accessibilityIdentifier("languagePersistence.environment")
                HStack {
                    Button("QA FAQ") { showingFAQ = true }
                        .accessibilityIdentifier("languagePersistence.showFAQ")
                    Button("QA settings") { showingFAQ = false }
                        .accessibilityIdentifier("languagePersistence.showSettings")
                    Button("QA clear") {
                        preferences.cleanUp()
                        cleared = true
                    }
                    .disabled(cleared)
                    .accessibilityIdentifier("languagePersistence.clear")
                }
                .frame(minHeight: 44)
            }
            .font(.caption2)
            .padding(4)
        }
        .task {
            guard store == nil, let defaults = preferences.defaults else { return }
            settings.translationPausedForMemoryPressure = true
            settings.reduceAnimationOverride = ProcessInfo.processInfo.arguments.contains("-fruitfolioLanguagePersistenceReduceMotion")
            store = Prompt12AccountPrivacyStore(defaults: defaults, persistenceKey: "languagePersistence.accountFixture")
            if ProcessInfo.processInfo.arguments.contains("-fruitfolioLanguagePersistenceCleanup") {
                preferences.cleanUp()
                cleared = true
            }
        }
    }
}
#endif
