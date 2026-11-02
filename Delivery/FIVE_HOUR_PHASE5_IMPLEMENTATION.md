# Phase 5: Fruit Basket

Original window: 17:15:27–17:45:27 UTC. Original final deadline remains20:15:27 UTC, 2026-11-02. No reset.

Existing engine already ends a round when a registered bad-fruit catch has no pass, consumes exactly one available pass to continue, and accumulates standalone-star passes without a fixed cap. These implementations and their existing tests are preserved. Actual Run9 records include passing `testBadCatchWithoutStarPassEndsRound` and `testStarPassAccumulationHasNoArtificialCapAndConsumesOneAtATime`; historical evidence is not a fresh full-game acceptance run.

Question lifecycle correction: asynchronous research now belongs to its exact generation, session, topic and difficulty. Leaving/replacing loading, changing the topic/difficulty or leaving the feature cancels that request. A deliberately late result cannot replace the current question, report an old error or add a question to the wrong topic’s history. Question metadata must match the requested topic/difficulty. Loading cancellation returns to usable setup. Three new tests use actual bundled grounded questions behind a deliberately noncooperative callback provider. They have not executed in Xcode. Existing timer/settling/scoring behavior is preserved.
