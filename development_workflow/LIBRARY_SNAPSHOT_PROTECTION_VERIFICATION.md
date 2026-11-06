# Saved Library snapshot preservation

Saved Library persistence now captures the exact baseline UserDefaults object and rejects a commit after that record changes or is cleared elsewhere. The existing actual store rolls back its candidate state on failure and exposes a specific protection reason. Explicit reload reads the latest saved baseline without writing or merging it. Protected records cannot create books, and Library, Guide Builder home and Ask save destinations provide the same inline reload notice. This is value comparison in the local process, not a cross-process transaction/ABA guarantee.

Added a Foundation JSON-field-coverage guard: after a successful typed decode, a temporary typed encoding is inspected recursively for discarded dictionary fields/array members. No scientific scalar values are changed or treated as clinically equivalent. Unknown nested book/page/citation fields prevent writes while known readable pages remain available; no raw record is rewritten. This conservative rule also protects explicit null fields omitted by the typed encoder rather than guessing they are disposable. Unreadable originals retain the existing read-only behavior. Reload does not clear an unsupported record; only a genuinely readable/round-trippable newer baseline re-enables edits.

The real Saved Library store now conditionally retains genuine Combine/ObservableObject on Apple and runs its identical control flow on Linux. Existing Saved Library tests execute against that actual store. Its physical asset-name enum is also compiled unchanged on Foundation platforms; only the SwiftUI image view is conditionally excluded. No artwork/resources or model implementation is replaced. New actual-store tests prove stale/cleared deletion rollback, exact original byte preservation, known-page/notes readability under unknown nested fields, null protection and read-only reload. A DEBUG private-suite route and an actual UI test exercise the protected notice, large text/Reduce Motion and opening the existing readable book. Apple SDK/publisher/UI/screenshots remain NOT_RUN.

The new field guard is currently applied to Saved Library only. Remaining measurement/context persistence needs the same stale/unsupported-record review and implementation; this batch does not claim all app stores are protected.


## Follow-up QA shell isolation correction

The feature fixture uses a private suite. Its new shell entry flag was initially missing from ContentView’s disposable-shell-preferences list; this was found before any Apple UI execution. The context-preservation batch adds the missing library/measurement flags and a bounded cross-file regression covering every literal shell QA entrypoint. See CONTEXT_SNAPSHOT_PROTECTION_VERIFICATION.md.
