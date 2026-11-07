# Language preference acknowledgement

Three regressions against parent9d0f65c reproduced four assertions: a dropped write retained an unacknowledged requested language, a dropped future-value replacement cleared review incorrectly, and an interleaved saved replacement was mistaken for the requested selection. The original source hashes and failed run are preserved with the batch receipts.

The existing raw-string preference key and language catalog are unchanged. Save now returns exact typed readback acknowledgement. Settings accepts successful writes normally; on failed acknowledgement it reloads the actual saved selection and review flag without an automatic repair write, and exposes controlled fixed-copy feedback. Explicitly selecting again can retry. No fallback overwrites an unknown/future value unless the user explicitly chooses a language.

Final focused tests also check exactly one attempted write, error state, and successful acknowledged retry clearing the message. Broad suites execute the initial three state regressions with the same production fix; the final focused run executes the strengthened write-count/retry assertions. These are real SettingsStore/UserDefaults paths, not a simulated preference model.

Readback is not an fsync/crash-durability guarantee. Linux excludes genuine Combine; transient notification ordering, SwiftUI selector behavior, actual error rendering/focus, global-layout updates and Apple UI remain NOT_RUN. No official MADLAD model inference or native-language quality is established. One English error fallback is added; existing catalog objects and scientific/source/user records stay unchanged.

The375–390 handoff preserves every remaining original visual/audio/accessibility check individually. It does not mark any of those whole requirements complete. Original374 still lacks the canonical tulip; official model/framework/clinical/device blockers remain separate.
