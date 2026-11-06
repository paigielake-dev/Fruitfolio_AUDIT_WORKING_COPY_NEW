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
#endif
