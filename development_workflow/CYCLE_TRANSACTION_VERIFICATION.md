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

## Onboarding draft boundary

Prompt14 now queues its seven existing public operations across file and cycle
actor awaits. Changed drafts save once at the outer boundary. Failed operations
discard candidate cache state and reload the actual saved draft on the next call.
Explicit onboarding-only erase clears the cache only after backend acknowledgment;
it can remove a current unsupported file without a lossy decode. The lower-level
file baseline guard still rejects stale erasure. A lost save acknowledgment reloads
what was physically committed rather than pretending that it was undone.

Six additional actual-file tests cover failed update/erase, acknowledgment loss,
25 concurrent date updates, unsupported-file erasure, and completion retry after
cycle records committed but onboarding save failed. Retrying that unchanged draft
reuses the same actual cycle record IDs. It does not prove arbitrary draft edits
after partial cross-file completion are reconciled, or that multiple period imports
form one archive transaction. Those recovery/import improvements remain next.

## Whole-history archive import

Prompt13.reconcileOnboardingCycleStarts validates the entire explicit date set,
then stages ownership migration/removal/insertion under its existing operation
boundary. Prompt14 completion and committed-history correction now call this API
instead of making separate public writes for every date. Initial completion reuses
existing dates without claiming independent provenance. Committed-history edits
retain the existing narrow migration behavior for matching user-confirmed dates,
remove obsolete onboarding-owned starts only, and preserve unrelated user/imported
records. An unchanged retry retains IDs and performs no archive write.

Four actual-file tests verify one write for multiple dates, invalid-candidate
rejection before changes, failed-replacement preservation of exact file bytes and
reloaded records, and independent-record/ID preservation. Failed-write comparison
uses the actual reloaded baseline because the pre-existing ISO8601 codec stores
second-precision timestamps; this batch does not change that codec.

This still does not commit the cycle and onboarding files atomically. A durable
intent/recovery phase and ordered editor autosaves remain subsequent tasks.
