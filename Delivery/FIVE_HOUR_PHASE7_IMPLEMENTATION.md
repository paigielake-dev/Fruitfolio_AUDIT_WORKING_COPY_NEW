# Phase 7: remaining and cross-feature corrections

Original window18:15:27–18:45:27 UTC. Final deadline remains20:15:27 UTC, 2026-11-02. No reset.

Round-finalization repair: a final registered catch previously locked the round but left its persistence behind a cancellable presentation delay. Pause/background/navigation could cancel that task and strand an ended round. Actual result/source/catch/score records now commit immediately; visual presentation keeps its existing delay. Per-attempt idempotence prevents repeated callbacks from incrementing progress twice. Pause cannot escape a locked result; leaving/background/retry finish the pending presentation safely. Basket movement stops at logical round end. Existing scores and progression formulas are preserved.

Five new XCTest cases cover immediate commit even if the host is dropped, repeated interruption, bad-fruit failure, fresh retry and normal delayed reveal. They are source only until run on founder Mac. No new native/physical-device verification is claimed. MADLAD inference remains excluded.
