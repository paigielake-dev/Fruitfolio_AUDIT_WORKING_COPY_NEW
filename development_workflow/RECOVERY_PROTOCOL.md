# Resume implementation

Use the existing isolated checkout; do not create a worktree or rebuild the app.
1. Run `git status --short --branch`, `git log -5 --oneline`, and `git diff`.
2. Read CURRENT_CHECKPOINT.json, MASTER_CHECKLIST.json, SUPPLEMENTAL_SPEC_CHECKLIST.json, BLOCKERS.md and the last IMPLEMENTATION_LOG.md entry. Preserve all uncommitted changes; never reset to the checkpoint SHA.
3. Reconcile the checkpoint with actual HEAD and source. A checkpoint records the parent of its containing commit to avoid a self-referential SHA; `git log` is authoritative. Inspect newer commits before resuming.
4. Run `python3 -m unittest discover -s development_workflow/tests -v`. On macOS run `bash Tools/verify_prompt1b_mac.sh` with an available iOS Simulator destination.
5. Select the first unfinished source-order requirement; inspect its files and tests. Continue Part 1 shared systems before dependent screens. Implement, test, record evidence, and commit each coherent batch locally.
6. Never equate source review, Linux tooling checks, model presence, and iOS runtime verification. Keep them separate. Full MADLAD inference remains required; the master protocol supersedes historical exclusions.
7. Update checklist, verification register, blockers and checkpoint after each batch. Reference a batch name in the containing commit, then record its SHA in the next checkpoint. Do not push or merge without permission.

8. Run `python3 Tools/sync_supplemental_spec.py --check` to verify 36 exact founder additions. These supplement the original 478 and do not renumber them. Continue reconciling remaining unnumbered founder paragraphs. The extracted document contains legacy undecodable bytes; use UTF-8 with surrogateescape for lossless reads, and never rewrite its original bytes.

9. After a clean local checkpoint, run `python3 Tools/create_local_recovery_bundle.py --output /workspace/recovery/Fruitfolio-prompt-1b.bundle`. It refuses pending changes or a different branch, excludes the verified common origin/main prerequisite, verifies the branch tip, and writes a SHA-256 manifest outside the checkout. No network, push or merge occurs. Its fixture regression independently restores a checkpoint into a repository lacking that commit. The real bundle is local Git data only: preserve/download it if needed; it does not guarantee cloud workspace persistence or include fetched LFS objects. Restore the existing repository/prerequisite and LFS assets first, then follow the manifest. Never reset over newer local work merely to match a bundle.

### Canonical sound source checker

`Tools/normalize_control_sound_ownership.swift` compiles against the actual toolchain host SwiftSyntax/SwiftParser libraries, outside the iOS target. Set `FRUITFOLIO_SWIFTC=/path/to/swiftc` when running workflow tests to execute its six regression cases. Use a writable module cache (for example `/tmp/fruitfolio-swift-module-cache`); do not retry writes to the read-only home cache. The source check is not iOS audio playback evidence. See CONTROL_SOUND_OWNERSHIP_VERIFICATION.md.

## Mandatory per-batch checklist evidence

For every completed batch, record the source-order requirement IDs, concrete implementation evidence, executed results, tests written but not run, and remaining requirement-wide verification. Use `python3 Tools/record_prompt1b_batch.py --batch <manifest.json>` from this checkout. The manifest must include `verification.executed` (object), `verification.not_run` (list), and `verification.remaining` (list), in addition to the batch/source/test/result/next-action fields used in the implementation log.

The recorder places this information in each targeted master entry's `latest_batch_verification` and `remaining_verification_requirements`, the checkpoint, verification register and unique run log. These are batch-scoped results, not certification of the whole original requirement. Apple tests that are only written must remain explicitly NOT_RUN. Passing Linux contracts must not automatically promote an item to complete. Preserve all existing requirement text, numbering and order; reconcile stale statuses only with individual source/test evidence.

Validate/test the implementation first, record the batch, review its Git diff, then commit locally and create a new uniquely named recovery bundle after the working tree is clean. Existing run logs are not overwritten. If execution interrupts between structured-file writes, inspect and reconcile that uncommitted diff against the manifest and Git checkpoint before resuming; the recorder does not claim a multi-file filesystem transaction. `current_HEAD` and the dirty-file list in a committed checkpoint describe its pre-commit state; current Git HEAD/status and the verified bundle are authoritative.

A batch may additionally provide `entry_evidence`, keyed by its targeted source-order IDs. Each entry explicitly supplies its own `files`, `tests`, `summary`, and `verification` object. This keeps, for example, an unexecuted Apple intro test from inheriting a passed Linux book-geometry claim. Unlisted/invalid/incomplete per-entry mappings are rejected before any recovery-file write. Global results remain scoped to the batch; per-entry evidence governs the corresponding original checklist record.
