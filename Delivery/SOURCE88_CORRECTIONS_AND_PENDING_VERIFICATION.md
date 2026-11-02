# Source 88 corrections; Apple verification pending

Preserves source 87 and its official models. Intro background recovery now executes the unseen branding reveal, restores configured stage durations, re-registers ambience, and resolves painted-stage state at interruption boundaries. New tests execute the real 6–8 second state-machine clock in normal and Reduce Motion modes and cover interruption/skip behavior.

Catch registration now requires the current rendered landing generation to complete settling; stale, absent, disappeared and duplicate presentation callbacks cannot register a catch. Existing landed artwork does not replay its impact on remount. Tests cover these production state transitions. Visual gameplay acceptance remains pending; the app default research provider is not yet connected.

Run 85 actually passed both smoke XCTest cases (36.880 and 43.183 seconds). Its recorder exited with zero bytes, making the overall stage fail and incorrectly skipping later functional journeys. Workflow gates now use the actual XCTest exit status independently of recording. A failed recording remains preserved and triggers a separate real simulator recording retry; it is never described as a successful recording. Both failure and successful retry, if any, remain evidence.

No new requirement is marked PASS by this code-only checkpoint. Run 85 native accessibility stage failed; full attachment diagnosis and source 87 unit/offline results remain pending. No FINAL_COMPLETE archive is claimed.
