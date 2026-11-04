# Founder Mac verification of the integrated source

This document is a runnable handoff, not an assertion that the delivered revision has built or passed on a Mac. Historical CI evidence is preserved by its actual source commit. New Swift, SwiftUI, UIKit-hosting and UI tests added during the five-hour source sprint remain unexecuted until the commands below run successfully.

## Open and build

1. Reconstruct all binary ZIP parts in numeric order, verify the part and full-archive checksums, and extract the ZIP preserving UTF-8 filenames. The project belongs at the extracted root: `Fruitfolio.xcodeproj`.
2. Use an Apple Silicon Mac with a full selected Xcode installation and an installed iPhone simulator. The supplied runtime XCFrameworks contain device ARM64 and simulator ARM64, not Intel simulator slices. Run Terminal/Python natively on ARM64. Use the historically verified Xcode 26.6 toolchain (17F113, Swift 6.3.3) where available; its actual version logs are preserved. Earlier Xcode/compiler compatibility is NOT VERIFIED. Synchronized source-group support alone does not establish compatibility with all Swift concurrency syntax in this project. iOS deployment target is 17.0. Compatibility with every supported physical iPhone remains unverified.
3. Open `Fruitfolio.xcodeproj`, select the shared **Fruitfolio** scheme and an available iPhone simulator. Original artwork, audio, research, FruitfolioAI and the preserved MADLAD resources are included; no manual multi-gigabyte download should be necessary. Do not replace either model or regenerate artwork.
4. For a physical iPhone, select your signing team and bundle identifier as appropriate for your account. Simulator batches below disable signing. Production account services, global username reservation and StoreKit distribution configuration still need founder-controlled credentials/configuration; no production purchase or remote account acceptance is claimed.

The reconstruction and verification scripts use Python 3.9 or newer and the standard library. A Python 3.9 interpreter was not available here for a separate compatibility run; actual tooling execution used the local Python version recorded in the logs.

From the extracted root:

```bash
xcode-select -p
xcodebuild -version
xcrun simctl list devices available
```

Copy an actual available iPhone simulator UDID. Get the exact delivered commit from `Delivery/PackagedFileIntegrity.json` (inside the archive) or its adjacent parts index, rather than an older local clone HEAD:

```bash
FRUITFOLIO_DELIVERED_COMMIT="<full delivered GitHub commit>"
FRUITFOLIO_SIMULATOR_UDID="<actual available iPhone simulator UDID>"
python3 Tools/verify_integrated_source_on_mac.py --group build --source-commit "$FRUITFOLIO_DELIVERED_COMMIT" --simulator-id "$FRUITFOLIO_SIMULATOR_UDID"
python3 Tools/verify_integrated_source_on_mac.py --group unit --source-commit "$FRUITFOLIO_DELIVERED_COMMIT" --simulator-id "$FRUITFOLIO_SIMULATOR_UDID"
python3 Tools/verify_integrated_source_on_mac.py --group ui --source-commit "$FRUITFOLIO_DELIVERED_COMMIT" --simulator-id "$FRUITFOLIO_SIMULATOR_UDID"
python3 Tools/verify_integrated_source_on_mac.py --group audio --source-commit "$FRUITFOLIO_DELIVERED_COMMIT" --simulator-id "$FRUITFOLIO_SIMULATOR_UDID"
python3 Tools/verify_integrated_source_on_mac.py --group native --source-commit "$FRUITFOLIO_DELIVERED_COMMIT" --simulator-id "$FRUITFOLIO_SIMULATOR_UDID"
```

Run each command even if an earlier test batch fails, after addressing a blocking compilation error. Each invocation uses a unique evidence folder and retains its full command, actual source hashes, Xcode version, log, native xcresult, individual XCTest executions and attachment exports where supported. A build is not a test pass; skipped, unfinished and failed executions are not accepted requirements. Swift Testing results remain separate from XCTest counts in the native result/log. Do not add overlapping executions from different batches to claim a unique suite total.

The unit batch excludes native model execution so failures can be repaired independently; the native batch explicitly runs the real FruitfolioAI test and actual Ask journey. The UI batch seeds one original cloud PNG into the **simulator's** Photos library for import testing. It does not read or change the founder's personal photo library. All batches explicitly skip `AAAA_MADLADRuntimeIntegrationTests`. Pure existing language metadata/preservation logic may be tested; **MADLAD inference is EXCLUDED — FOUNDER-HANDLED FUTURE SPRINT**.

## Required new regressions

Inspect failures and screenshots before changing helpers or assertions. Preserve original full-visibility, contrast and grounding assertions.

- Cycle onboarding: delayed/rejected saves, restored drafts, finish after rejected write, concurrent snapshots/edits, My Context using persisted rather than optimistic data. Cross-file onboarding/cycle-history atomicity remains an outstanding limitation.
- Hormones: real values/units/timestamps, duplicate identity corruption, failed writes preserving bytes, unsaved editor Keep Editing/Discard, restart, exact export equality and separate guarded deletion. Do not draw medically unsupported personalized curves.
- Account/Basket: invalid and overlong username rejection without silent sanitization, shared editing, previous-value preservation and restart; backend availability remains separate.
- Ask: actual native grounded evidence selection, strict citation rejection/attribution, original source-version snapshots, continuous paper, earlier-reading position, Reduce Motion changed during retrieval/typing, no session transcript persistence, explicit saved-page persistence. Inspect long passages and source readability without truncating evidence.
- Game: first-use tour/rules, long question/evidence scrolling, normal/largest Dynamic Type, actual registered catches/stars/passes/reveal, immediate unprotected bad-fruit failure, exactly one consumed pass, uncapped earned passes, real settling acknowledgements, background/leave/retry/host release, immediate single-snapshot result persistence and duplicate identity rejection. Classification-control standalone-star acquisition remains PARTIAL.
- Shared UI: native button labels and traits, actual visible text, Contact/FAQ, Hub clipping, guarded deletion Cancel fully visible, popup focus/dismiss/Escape, book color and continuous deformation, normal/largest text, VoiceOver and live Reduce Motion.
- Localization: stored selection including unreadable/unknown preferences, exact Simplified/Traditional script choice, Arabic/Hebrew direction, restart, readable native labels and source-language fallback disclosure. Catalog coverage is incomplete; selecting a language or recognizing a target tag does not establish localized or medically accurate content.
- Privacy export: Save then reopen and decode the actual saved bytes; exact populated health/context/hormone/cycle/game/question/citation/timestamp equality; Cancel must never report success or mutate account metadata/stores. Preserve unreadable original bytes and report failure instead of treating corruption as empty data.

## Offline and physical verification

The runner does not disable the founder's network or modify firewall settings. A successful native test alone is not controlled offline acceptance. On a dedicated test environment, retain evidence of a reachable external origin before isolation, real isolation during native inference and Ask navigation, failed independent outbound probes throughout the test, and restoration afterward. The existing `Tools/verify_offline_madlad_ci.sh native-grounding` is restricted to a disposable GitHub-hosted macOS VM; **do not run its firewall changes on a personal Mac**. Do not invoke its default/MADLAD modes in this sprint.

Use Xcode's test result attachments for screenshots. Use `xcrun simctl io "$FRUITFOLIO_SIMULATOR_UDID" recordVideo <output.mov>` and interrupt recording after the required animation; retain representative frames with the exact settings/source revision. Manually compare original approved compositions, all responsive states and largest text. An attachment from an older source is historical evidence, not a screenshot of this delivered source.

Listen to the four independent audio channels and master mute. Verify splash only on puddle entry, movement only while moving in water, branch impact only on branch contact, all respecting SFX volume/mute; test background/inactive/app-switcher, interruptions and route changes. The new Foley is synthesized, not a field recording, and its subjective realism is not accepted. Simulator player observations do not establish audible quality, Bluetooth/headphone behavior or physical-device interruption behavior.

Run on supported physical iPhones to measure startup, memory/thermal pressure, inference latency, offline cold launch, storage use, accessibility, recordings/audio routes, protected-data behavior and app restarts. Do not promote hardware-only skips to PASS. Reconcile each requirement with its exact evidence and remaining discrepancy before release. No merge into main is authorized.

## One-command continuation verification

```bash
python3 Tools/verify_continuation_on_mac.py --simulator-id "<actual available iPhone simulator UDID>" --source-commit "<full delivered Git commit>"
```

This executes the five existing batches in order and records every exit/result. Build or preflight failure blocks subsequent batches explicitly; later test failures are retained while other runnable batches continue. MADLAD inference remains excluded. No run of this command has occurred on a local Mac here.
