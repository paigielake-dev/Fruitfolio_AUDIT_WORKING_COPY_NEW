# Phase 2: audio source integration

Original deadline remains 2026-11-02 16:15:27.152808 UTC. No clock reset.

Changes preserve the four independently controlled music, rain, SFX and typing channels, existing assets, settings persistence and collision ownership. Audio interruptions without `shouldResume` now hold individual continuous channels; foregrounding and volume changes cannot silently restart them. An explicit fresh play or category-enable request releases only that category. Media-service loss stops players, and reset rebuilds eligible continuous requests without replaying effects. Nonfinite fade-in durations are normalized before entering AVAudioPlayer APIs. Repeated shared button/popup/page feedback reuses a player rather than stacking the same cue; gameplay collision sounds remain separate.

Five meaningful XCTest cases were added: interruption/foreground/category isolation and OS resume permission; invalid fade durations with actual players; UI feedback coalescing with independent game sound and no stale replay; media-service loss/reset; and actual channel loop-resource replacement. These tests are source only until executed on the founder Mac. Posted-notification tests do not prove real phone-call, route-change or hardware playback behavior.

Feasible check: changed Swift files pass `git diff --check`. No Xcode, simulator, physical speaker/headphone test, perceptual Foley acceptance or new runtime PASS is claimed. Existing real Run 9 and earlier audio evidence remains unchanged and applies to its recorded source commit.

Outstanding: run the new and prior audio suites on Mac, test real interruptions and routes, test every slider/mute independently, listen for unwanted overlap and clipping, verify background/foreground and Reduce Motion interactions. Existing Foley assets are preserved without regeneration. MADLAD inference remains excluded for the founder-handled future sprint.

Feasible tooling regression run: `python -m unittest discover -s Tools/tests -v` executed 11 tests, all passed (0.049 s). This verifies research-update and XCTest-report tooling, not audio runtime acceptance.

Unchanged Foley resource checks: all three committed WAV files matched their original SHA256, sample rate, channel count, sample width and exact frame count. Results and a distinct tooling regression log are retained in `Fruitfolio_Verification_Evidence/FiveHourSprint/Phase2Audio/`. This is resource-integrity evidence only.

Founder Mac runner: `python3 Tools/verify_audio_on_mac.py --destination 'platform=iOS Simulator,id=<actual UDID>' --source-commit <final source SHA>`. It builds and executes only the actual audio/typing XCTest suites, preserves unique invocation, Xcode version, full build/test log, xcresult and individual execution results, and propagates failures. It does not execute MADLAD fixtures. Local `--help` and Python compilation passed; the runner has not executed Xcode here. Use a simulator listed by `xcrun simctl list devices available`. Physical audio quality and real interruption/route checks remain manual acceptance tasks.
