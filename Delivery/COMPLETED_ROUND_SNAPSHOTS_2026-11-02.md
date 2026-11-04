# Completed-round persistence — Apple execution pending

Completed attempts now record the actual `Prompt28RoundCollection`, session/round/attempt identities, score, remaining passes, outcome and personal-best state together with the original full `Prompt28Question`. Its evidence snapshot retains the exact approved passage and source records, including source versions. Both successful and unsuccessful completed attempts are retained. The attempt identifier prevents duplicate completion records. New attempts reset current collections without deleting historical records.

The private game store adds an optional persisted history field, decoded as empty only when genuinely absent in a valid legacy document. Corrupt documents still fail explicitly and retain their bytes. JSON export includes this completed-round history and discloses its scope; legacy exports can omit the new optional field.

The frame-driven actual collection test now checks stored/reopened outcomes and duplicate prevention. A separate real bundled-research fixture checks that a new provider using an explicitly test-only successor package does not rewrite saved explanations, source versions or stored bytes. The latter is a persistence/retrieval fixture, not a second physical round execution. Both Apple test extensions remain pending.

This preserves original educational explanations; it does not establish that every explanation is sufficiently bite-sized, independently medically reviewed, or visually accepted at all text sizes. No summarization or truncation was introduced. Completed-round browsing and full requirement acceptance remain unfinished where not already evidenced. Existing Basket Reveal save-to-encyclopedia behavior is preserved.
