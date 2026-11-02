# Actual Sprint Run 2 UI findings and corrections

Run 2 at 624d7a5b532e91f1d52f31eafa2d96322f60e35a built successfully and executed 81 XCTest cases: 78 PASS, 3 FAIL, 0 skipped. The 74 selected core unit tests passed, including real bundled collision audio playback, player reuse/release, volumes, and Ask scroll policy. Four of seven UI cases passed. Both continuous-paper journeys failed; the actual game-background journey retained its paused values but incorrectly exposed the underlying Pause action.

Production game repair: the paused menu now applies the canonical hidden/noninteractive blurred state to the underlying gameplay header. The menu is vertically scrollable with its available viewport and exposes modal traits, preserving all actions and wording. No lifecycle/scoring rules changed.

Ask helper repair: original logs show a real UITextView automation-class mismatch after scrolling, so the stable accessibility identity is now queried across actual types. Long-history panning uses the blank left paper margin and a larger bounded traversal budget instead of dragging selectable text/right scroll indicators. The original visibility, answer-integrity, single-paper and citation assertions remain. This is not a claim that the Ask production issue is resolved; rerun evidence is required.

Raw original job log and per-case execution results are retained under Fruitfolio_Verification_Evidence/AppleRuns/SprintRun2. The oversized original artifact (13148295738, SHA256 1cd298572cf8a506b67b6cd397db5ed4ae13c0cb89bf3384c179229685e46806) retains screenshots/xcresult. Binary artifact recovery remains pending.

The follow-up batch also schedules the existing controlled-offline firewall protocol in native-grounding-only mode: strict bundled FruitfolioAI grounding plus real Ask. No MADLAD fixture executes. Original raw xcresults remain separately retained, while logs/exported visual evidence use a smaller downloadable artifact; no evidence is deleted to reinterpret results.
