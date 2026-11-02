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
