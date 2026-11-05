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
