# Terminal round acknowledgement

The actual terminal-success path previously set the personal-best flag before the statistics write was acknowledged. Both success and failure paths marked their private finalization identity before the write. They now publish finalization after the explicit store acknowledgement, and success publishes its personal-best flag at that same confirmed boundary. Missing progress uses the single terminal candidate write.

A valid new catch round clears the previous round’s personal-best flag. Invalid/duplicate begin requests still return before clearing an accepted result. Score, progression policy, artwork, scientific sources, persisted schema and ordinary success/failure presentation remain in use.

Two actual-controller regressions cover a ten-fruit settled success whose terminal stats write is dropped, and an acknowledged personal best followed by a fresh legitimate question/intro/round. The rejected-write pre-fix run executed one test and reproduced one failed personal-best assertion. The tests check protected storage, unchanged acknowledged cache/original bytes, no result on failure, preserved earned catch score, explicit reload→topic setup, and clearing the prior flag on the fresh round. Existing full suites cover normal success/failure and single-use reveal/retry.

Pending terminal intent remains consumed on failure, preserving existing recovery: explicit reload returns to topic setup. This change does not automatically replay an old session after accepting external data. Private finalization marker placement is source-reviewed; tests assert public state rather than exposing a test-only production API.

Final supported results are recorded in batch/checklist evidence. Genuine Apple Combine/SwiftUI personal-best visual timing, failed-save recovery presentation, accessibility/audio/device behavior and official MADLAD inference remain NOT RUN. Whole requirement acceptance is not inferred from these controller checks.
