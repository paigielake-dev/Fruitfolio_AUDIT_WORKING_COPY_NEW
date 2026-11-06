# Cycle archive operation boundaries

The existing Prompt13 actor now queues every public asynchronous entry point.
Internal calls use private implementations, avoiding recursive acquisition.
A public operation loads before taking its rollback baseline, stages its changes,
and saves a changed complete archive once. Readers queue behind suspended writes.
On failure the candidate is discarded and the next operation reloads the actual
backend: a lost acknowledgment does not imply that the physical write rolled back.
Cancellation is checked after acquiring the queue and before final persistence;
no failure is synthesized after a successful backend acknowledgment.

Clear now replaces the archive with the same existing empty-archive representation,
preserving identity when requested. It does not delete the file before a potentially
failing replacement. Production file actor baseline/future-field checks still apply.

The actual observation linkage helper already staged its daily log before this
change; it did not call the separately persisted public dailyLog method. The new
single-write observation test confirms retained behavior rather than claiming an
old two-write regression. The failures reproduced against parent 1eaecb0 were:
unsaved daily logs/notes remaining in cache, canceled queued writes still occurring,
and a failed clear deleting the prior physical file. Six new tests reported seven
failures (one missing-file assertion error) against that source, and all pass after.
Tests use the actual file actor with explicit counting/failure/suspension boundaries.
Other tests cover 21 concurrent notes, linked IDs, and commit-then-fail recovery.

This is serialization within one store actor, not cross-process atomic compare and
swap or a transaction across the onboarding and cycle files. Onboarding's separate
failure/reconciliation workflow remains a subsequent task. Apple application build,
UI behavior, device data protection and clinical acceptance are NOT_RUN on Linux.
