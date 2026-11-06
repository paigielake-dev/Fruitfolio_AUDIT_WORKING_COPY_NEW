# One acknowledged Guide selection

The actual saved-page picker now resolves all selected source keys against the current shared catalog, independently of its visible search and material filter. A missing key rejects the selection instead of silently saving a subset. Empty/already-added selections cannot emit a page-turn request or saved-status callback.

The canonical Store stages all new pages and persists the library once. Guide references deduplicate against every destination chapter and the batch. Single-page callers retain their existing return/duplicate behavior. Reference construction retains the original fields, including citations, semantic spans, excerpt range/language, image ownership, educational assets, source versions and user provenance. Ordinary source-page private notes retain the existing exclusion policy; user-material notes are preserved. Original source books are unchanged.

Six new Foundation cases cover one-write acknowledgment and independent reload, source-field equality (including nonempty spans and user provenance), dropped writes with no partial selection, duplicates/empty selections, invalid destination, pre/post-write external replacement, and missing-key rejection. The final focused library suite has 12 passing cases.

Full Linux suite results and individual checklist evidence are recorded in RUN_LOGS/Single-acknowledged-Guide-page-selection.json. The full suite snapshots preceded the final enhanced provenance/span assertions; the final focused suite reran those assertions successfully afterward.

Eight new Apple UI launches cover two selected pages with accepted or silently dropped writes, normal/reduced motion and English RTL layout. All 40 Guide launch cases remain NOT_RUN on Linux. Actual SwiftUI typecheck, rendered filter-selection behavior, callback wiring, accessibility, audio and physical-device acceptance require Apple tooling. One JSON write plus exact API readback is not cross-process CAS or power-loss durability. Official MADLAD inference remains unverified without official resources.
