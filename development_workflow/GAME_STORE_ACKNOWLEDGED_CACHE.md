# Game store cache acknowledgement

The actual disk adapter already required exact write readback, but the observable store advanced topic/history/tour caches before that check. The store now stages candidate persisted state, calls the same unchanged disk adapter, and applies the candidate only after successful acknowledgement. Changed-only application retains the existing per-property Combine interface. Preference fields that are directly edited retain their existing interface; a failed commit restores the last acknowledged cache.

Failure never calls load or accepts external bytes. Only explicit reload accepts the current persisted record and clears write protection. Reload still sanitizes the legacy name and ignores legacy global leaderboard opt-in as proof of registration. Persisted schema, key, unknown-field checks, source research and artwork are unchanged.

Two new actual-store tests inject dropped writes through real UserDefaults subclass seams, covering progress, new topic, question history, tour completion/reset and preferences. The corrected pre-fix run executed 14 persistence tests and reproduced seven assertion failures; an earlier fixture used an unavailable difficulty case and failed compilation with zero executed cases, not a passing run. Tests verify original bytes and acknowledged caches, then explicit reload and a fresh successful progress increment.

Final executed results are recorded in matching batch/checklist evidence. Genuine Combine notification ordering and Apple UI recovery remain NOT RUN on Linux. This batch does not yet fix controller session/ledger credits or terminal-round bookkeeping that happen before store acknowledgement; those are the next independent requirement. Synthetic T5 remains distinct from official MADLAD inference.
