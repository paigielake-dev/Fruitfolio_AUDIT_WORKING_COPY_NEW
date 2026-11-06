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

## Durable cross-file intent and restart recovery

The existing onboarding draft now has an optional typed pendingCycleCommit field.
Old drafts without it remain decodable. Completion and committed-date edits first
save the exact supplied dates, operation mode, request time, completion request
(if any), and captured civil today. They then apply the single cycle archive
transaction and clear the intent in a final onboarding save. A resumed snapshot
finishes an already persisted explicit request before exposing the draft. It does
not infer unrecorded periods. Pending intents must exactly match the draft's
normalized supplied dates and contain no future dates against captured today;
invalid journals preserve both files and report unsupportedFormat.

The outer save boundary recognizes acknowledged intermediate/final draft writes,
avoiding a redundant third save and avoiding a cancellation error after successful
final acknowledgment. An error forces a real reload, including when an injected
error follows a physical commit. Explicit onboarding-only erase skips resumption,
allowing that specific pending request to be canceled without importing it.
Committed-date changes through update also use the same journal path.

Six additional regression methods exercise all three physical writes (intent,
cycle archive, final draft), failures before and after each commit, recreation of
both actors from real files, invalid/mismatched/duplicate-date journals, committed
history edit recovery followed by another edit, explicit pending-intent erase,
and completed-draft updates. Earlier final-save retry coverage now verifies the
persisted intent before automatic recovery rather than expecting recovery to leave
an intentionally unfinished cache. Cycle boundaries count successful real writes;
no fake backend is used to claim actual persistence.

This is a resumable local two-file workflow, not atomic visibility across the
files or across multiple independent processes. Legacy partial imports created
before journals existed cannot be assigned an invented intent. Ordered view-model
autosaves, stale editor baseline protection, Apple UI/device verification and
clinical review remain separate work.

## Ordered editor saves and saved receipts

The actual onboarding view model now uses conditional genuine Combine observation
and Foundation state logic in the portable suite. A chain of answer saves uses the
last acknowledged draft as its expectation. Each store save refreshes the actual
file before validating answers/progress or issuing an idempotent receipt. The
comparison preserves all saved fields except the administrative updatedAt clock,
and uses the original ISO8601 precision. This handles a missing file's fresh default
clock without treating it as a new answer. It is not a historical revision/ABA test.

A different saved answer rejects with editingConflict. Candidate equality can issue
a read-only receipt rather than reapply it. After an acknowledgment error the view
model checks an actual saved receipt without retrying the mutation; a matching
physical file permits the next queued answer to proceed. A different/unavailable
receipt preserves the visible draft and reports failure. Receipt loading may resume
an already persisted journal request; it never creates an intent from the candidate.

Finish freezes editing, waits for the newest queued save and refuses incomplete or
failed answers. It validates the saved baseline before journaled completion. An
already completed copy of the same saved answers can be acknowledged without
re-importing dates. Failed initial loads cannot save defaults; dirty drafts cannot
be erased by another load call. Retry controls use the existing canonical pill and
one cue owner. Errors pass through the shared translation view.

The SwiftUI view syncs My Context from acknowledged savedDraft receipts rather than
uncommitted visible answers, disables the form during Finish, and offers explicit
load/save retry states. Eleven actual view-model/file regressions exercise rapid queued
answers, a held save while Finish waits, failed answers/retry, same-store stale
editors, outside file writers, unsupported initial loads, held receipt publication,
completion acknowledgment recovery, absent-file default clocks and earlier lost
acknowledgments followed by a newer answer, and a completed editor refusing a stale
receipt after outside answers change. Completion receipts refresh actual storage
before comparison. Foundation tests do not verify Apple
ObservableObject rendering, keyboard, VoiceOver, Dynamic Type or UI sound playback.

Next integration concern: loaders that concurrently read cycle and onboarding
snapshots must await onboarding journal recovery before capturing cycle history;
otherwise they may combine an older archive with a newly recovered draft.

## Loader ordering after recovery

Today, Calendar and Trends now await the onboarding snapshot before reading cycle
history. Independent supplemental/log reads remain concurrent. Hormone Rhythm
captures one Today snapshot and derives both its existing body context and unchanged
Prompt17 prediction input from that captured archive/draft, removing two competing
loads. The actual Trends and Hormone Rhythm Foundation loaders are now compiled
in the portable suite as well as their unchanged engines.

Four real-file integration tests persist a pending correction from September 1 to
September 5, retaining August 1. They hold the final onboarding acknowledgment
while the new archive has already committed, then verify the screens use day3,
September5's recorded marker and35-day interval instead of old day7/September1/
31days. They verify recovery creates no temperatures or laboratory measurements.
The same tests using parent d938e03's actual four loader sources in an isolated
package reported8failures across4tests; the current sources pass all4.

This closes the known self-recovery read-order gap. It does not provide atomic
cross-file snapshots against unrelated operations after recovery, nor verify Apple
screen rendering, clinical interpretation or reviewed educational copy.
