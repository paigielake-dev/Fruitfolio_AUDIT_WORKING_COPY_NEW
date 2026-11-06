# Audio settings reconciliation

The actual AudioManager music/rain/effects enable observers now reconcile the full current preference state on the main run loop, matching global mute and typing. Four volume observers also wait until @Published has stored the new value. Music/rain enable callbacks no longer independently resume a channel while global mute is active. Resume additionally checks actual channel eligibility.

Reconciliation covers all four categories, including explicitly requested effect loops. Disabled/muted loops are set to zero and paused immediately; logical requests remain owned for permitted resume. One-shots in disabled categories stop. Volume reads use SettingsStore.playbackVolume, the same finite/category/global-mute policy exercised by portable tests; independent stored preferences are preserved.

Two new actual SettingsStore tests cover all channels, disabled/global-mute gates, independent persisted preferences and nonfinite/out-of-range live and reloaded values. Full final results are recorded in the batch run log. Newly written tests initially failed actor checking because they were placed in the nonisolated percentage-test class; they were moved into the existing MainActor settings suite, preserving all isolation. The failed builds executed no assertions.

Three new real Combine/AVAudioPlayer tests cover live/rapid volume updates, enabling requested music/rain while globally muted, and physical pause/retained ownership/disabled resume across all four explicit loop categories. All seven AudioSettings Apple unit cases remain NOT_RUN on Linux. No fake Combine or AVFoundation is supplied. Actual SDK typecheck, player behavior, hearing/route/interruption, foreground/background and physical-device acceptance remain open. The Mac verification script includes the full FruitfolioTests target.

No audio artwork, recordings, aliases, research, model resources or production preference keys changed. This batch does not establish complete app-wide audio acceptance, official MADLAD inference or device performance.
