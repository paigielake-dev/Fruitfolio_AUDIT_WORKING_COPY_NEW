# Phase 1 — visuals, artwork and animations

New sprint checkpoint: c5c6f81386618f482e143ef4984120b2e18eaa06. The immutable new clock is recorded separately; prior verified source, resources and evidence remain intact.

Implemented source changes:
- Replaced staged opening PNG swaps with one continuously deforming coded Canvas book, retaining the selected cover palette, measured shelf-image origin, centered opening, and measured inside-book target. The coded book stays alive after opening rather than being replaced by another image. Saved titles remain native live content over its reserved region; existing chapter/page interactions remain. Removed the old inside-book PNG and specified repeated decorative bookmark. All original artwork files remain available as references/resources.
- The same shared blur surrounds the whole book/detail presentation for modals; opening also blocks and hides the underlying collection. Live scroll geometry tracks the book without a lagging implicit animation. Cancellable opening work cannot complete on a departed screen, and enabling Reduce Motion finishes without movement.
- Restored full saved descriptions below shelf spines with dynamic wrapping and accessible values, without changing stored metadata.
- Corrected the exact normal game-rule contrast failure identified by immutable Run 9 evidence: full-strength native burgundy body text replaces translucent SwiftUI text. Tour progress likewise uses full-strength native ink; the largest-text original audit supplied no element, so its resolution requires a fresh strict audit. No threshold, issue handler or visibility assertion was changed.
- Closed the imported-image worker's atomic promotion read window by retrying the committed location if a pending image moves during a preview read; original bytes are not changed.

Tests added: 25 actual coded-book render frames across five cover colors/open fractions, selected-title centering in normal/largest actual page journeys, and actual native rule-body color/full-text fitting at normal/largest sizes. Test source is integrated; these new tests have NOT EXECUTED in this phase.

Remaining acceptance: exact founder-reference visual comparison, physical leaf-motion fidelity, every saved reading/page-state book-container composition, all screen sizes and actual animation/simulator evidence. The coded renderer is an implementation improvement, not proof that the entire multi-part book requirement is accepted. No requirement is promoted to PASS solely by these source changes.

Additional shared-popup correction: the taped-paper popup now uses the actual approved popup_taped_white PNG with its measured 662×647 aspect and a tape-safe writing area, replacing the coded imitation. Content scrolls inside that region. About headings/body now scale with Dynamic Type, use full readable burgundy ink, and receive native modal focus/Escape dismissal. Added keyboard/phone geometry tests and an actual largest-type Close/return UI journey. Existing About copy is preserved; its unfinished dedicated-content wording remains a separate core-content issue, not accepted as complete. FAQ's exact tulip remains unavailable in the supplied named/visually inspected canonical flower assets; no substitute flower or generated art was introduced.

Hub tour entrance work now belongs to a cancellable task keyed to the actual step. Rapid step changes or dismissal cannot allow an old delayed entrance to reactivate the next/removed dialogue. The approved tour veil, spotlight geometry, dialogue and reduced-motion presentation are unchanged.
