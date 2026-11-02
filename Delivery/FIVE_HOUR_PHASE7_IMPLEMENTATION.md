# Phase 7: remaining and cross-feature corrections

Original window18:15:27–18:45:27 UTC. Final deadline remains20:15:27 UTC, 2026-11-02. No reset.

Round-finalization repair: a final registered catch previously locked the round but left its persistence behind a cancellable presentation delay. Pause/background/navigation could cancel that task and strand an ended round. Actual result/source/catch/score records now commit immediately; visual presentation keeps its existing delay. Per-attempt idempotence prevents repeated callbacks from incrementing progress twice. Pause cannot escape a locked result; leaving/background/retry finish the pending presentation safely. Basket movement stops at logical round end. Existing scores and progression formulas are preserved.

Five new XCTest cases cover immediate commit even if the host is dropped, repeated interruption, bad-fruit failure, fresh retry and normal delayed reveal. They are source only until run on founder Mac. No new native/physical-device verification is claimed. MADLAD inference remains excluded.

Inactive-audio repair: willResignActive now uses the existing stop/preserve-request lifecycle path before background entry, including Control Center/app-switcher inactivity. New runtime test source checks all four channels, inactive playback/settings requests and eligible loop-only restoration. No audio runtime execution is claimed.

Atomic round snapshot: result attribution and progress are now staged and encoded together, then saved in one existing UserDefaults snapshot before publishing memory changes. Encoding failure or unreadable prior storage leaves original bytes and progress unchanged and displays a save warning. Duplicate record identity accepts only the exact already committed record, without incrementing progress. New rejection/idempotence test source uses a deliberately non-encodable timestamp and compares original bytes, progress, records and reopening. UserDefaults API return is not a physical-device durability guarantee.

Outstanding: classification controls do not currently offer standalone-star acquisition. Adding an arbitrary automatic pass/yes-button award would violate the required fully-entered, visibly settled catch mechanic. Existing catch mode retains actual rare-star physics and settling. This parity gap remains PARTIAL pending an accessible, specification-consistent implementation and verification; it is not marked PASS.
