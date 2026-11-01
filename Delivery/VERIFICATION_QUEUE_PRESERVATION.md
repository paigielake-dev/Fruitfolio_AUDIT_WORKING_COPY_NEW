# Verification queue preservation

Mac capacity was occupied by older broad-diagnostic runs while repaired source waited. A narrowly scoped CI-only Ubuntu job inventories old Run47–49 and Run52–57 state, uploads each candidate's run/job/step/artifact metadata, and requests cancellation only if it is still unfinished. Explicitly requested Run50 and Run51 are preserved, along with completed runs, all commits, all artifacts, all later runs, main, and the development branch. The script cannot delete artifacts or source. Cancelled/unexecuted stages remain NOT VERIFIED; cancellation never establishes a test PASS. The older completed focused artifacts and unit results remain valid only for their original source and scope.

The job runs only for this repository's same-repository Fruitfolio alignment branch. Only that administrative job receives Actions-write permission; app build/testing remains read-only. It uses GitHub's documented cancel-workflow-run REST endpoint and never prints tokens. Metadata is uploaded before any cancellation request. This is fixed one-time queue maintenance, not automatic cancellation of future verification work.

Reference: https://docs.github.com/en/rest/actions/workflow-runs#cancel-a-workflow-run
