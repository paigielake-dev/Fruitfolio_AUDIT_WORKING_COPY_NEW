# Guide ordering acknowledgment and recovery

Chapter reordering, within-chapter page reordering and cross-chapter moves now return whether they actually changed the canonical library. Zero/out-of-range/overflowing offsets and same-chapter moves perform no writes, timestamp changes or success effects. Actual Guide callers emit page-turn and saved-status only after a changed operation was acknowledged. Adjacent move behavior and existing content fields remain unchanged.

The selected Guide workspace now includes the existing shared library protection/reload notice, previously present only on its home screen. Reorder failures are no longer silently discarded: storage protection uses that existing notice and other errors appear through the shared semantic translation renderer. Reload is explicit and never writes or rolls back foreign bytes.

Three additional actual Foundation cases cover no-op/extreme offsets, chapter/page/move persisted order and complete content equality, and rejected writes for all three move types with entire acknowledged snapshot restoration. The focused library suite passes 15 cases. Full suite counts are recorded in the batch run log.

Eight new Apple UI launches target actual reorder controls with accepted or dropped writes, normal/reduced motion and English RTL layout. They require independent persisted section order, exact one write, no false saved status on failure and an explicit no-write reload. All 52 Guide Apple UI launches remain written but NOT_RUN. Apple typecheck, error visibility/focus, accessibility, rendering and physical audio/device acceptance remain open. This batch does not prove full Guide integration or official MADLAD inference.
