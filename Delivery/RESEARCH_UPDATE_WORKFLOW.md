# Founder research updates (local, offline, build-time)

This workflow edits one structured Research Library package, not gameplay Swift files. It does not expose an editor to app users or fetch external research. Publication selects a validated local snapshot; installation updates the resource for the **next application build**. A running installed app does not hot-load this directory. Its cached package and value-type question/evidence snapshots remain pinned. Distribute an updated app through the approved distribution process after regression testing. In-app update distribution is not implemented or implied.

## Schema and stable identifiers

The application-compatible schema remains `schemaVersion: 1` in `Fruitfolio/FruitfolioResearchPackage.json`: `contentVersion`, provenance (`generatedFrom`, `generationNote`), `researchNoteChunks`, `sources`, and `sourceChunks`. Keep existing `chunkID`, `researchTopicID`, `sourceID`, and `sourceChunkID` when correcting the same logical entry. Never derive a replacement ID from an array position, changed title or new wording. Use a new UUID-based ID for a genuinely new logical record. Existing imported IDs remain opaque, unchanged identifiers.

Notes contain topic ID, heading, exact approved passage/explanation, supporting source IDs and semantic/domain tags. Source records contain title, publication details, exact APA reference, verification/retrieval eligibility, source version, review date and content version. Unknown publication dates remain explicit `null`; do not invent them. A bibliography entry is not available primary-source content and must not be made retrieval-eligible just because its reference is formatted correctly. The existing strict native claim validator remains independently required.

An accompanying manifest has `schemaVersion: 1`, the SHA-256 of the **exact package bytes**, unique `supportedTopicIDs`, and `retiredIDs` arrays keyed by `sources`, `researchNoteChunks`, and `sourceChunks`. Every removal relative to the active baseline must be declared exactly. Remove retired entries from future active retrieval, retaining all immutable historical snapshots. Correcting a source or citation requires a new `sourceVersion`. A revision needs a new `contentVersion`, and a historical content version cannot name different bytes.

`Delivery/ResearchUpdate_Baseline_Manifest.json` describes the existing unchanged package. It is not a review receipt or newly approved science. `Tools/tests/test_research_snapshot_updates.py` contains deliberately synthetic schema examples confined to tests; do not install them as research.

## Edit, validate and preview

1. Copy the current package to a local candidate file and make the intended additions/corrections/retirements. Preserve exact scientific qualifiers and attribution. For a new note, provide an approved educational passage and valid supporting sources. New topic IDs must be explicitly listed in the manifest.
2. Compute `python3 -c 'import hashlib; print(hashlib.sha256(open("candidate.json","rb").read()).hexdigest())'` and put the digest in the manifest. Any subsequent edit requires a new digest and renewed review.
3. Run `python3 Tools/manage_research_snapshot.py validate --package candidate.json --manifest manifest.json --root ResearchUpdates`.
4. Run `python3 Tools/manage_research_snapshot.py preview --package candidate.json --manifest manifest.json --root ResearchUpdates > research-preview.json`. Review the actual passages, topics, citations and version changes. No generated scientific summaries are substituted.

Automated validation rejects duplicate JSON keys/IDs, unsupported schemas/topics, missing explanations, broken/ineligible references, missing approved citation metadata, undeclared retirements, changed sources without new versions and incomplete packages. These are structural checks. They do **not** independently detect every false, unsafe, unsupported or misleading scientific statement. A qualified scientific review and founder approval are mandatory before publication. The tool never fabricates a review receipt.

## Review and publish

Create a separate review JSON only after genuine review: `packageSHA256`, `founderApproved: true`, `scientificReviewApproved: true`, and nonempty `reviewer`, `qualifications`, `reviewedAt`, `scope`, `evidenceAssessment`, and `revisionReason`. All notes/claims, their uncertainty, source associations, available original materials, and proposed educational explanations must fall within that review. The receipt binds exact candidate bytes. This local workflow trusts the founder's files; a typed receipt is not a digital signature, independent verification of credentials, or an automatic medical approval service.

Run `python3 Tools/manage_research_snapshot.py publish --package candidate.json --manifest manifest.json --review review.json --root ResearchUpdates`. On the first publication, archive the existing baseline with a genuine review receipt before publishing its successor. This preserves an immediate rollback target. Never backfill a fabricated approval for the baseline.

The tool writes immutable digest-addressed package/manifest/review files, verifies them, then atomically replaces `CURRENT.json`. The previous validated digest remains available. A complete staging directory is renamed into the archive before activation; a partial directory or rejected candidate is never made active. A local publication lock serializes publication and rollback. Keep this archive under founder-controlled version control and durable backup. Do not change archived files; corruption fails integrity checks instead of silently selecting different science.

## Install for the next build

Run `python3 Tools/manage_research_snapshot.py install --root ResearchUpdates --destination Fruitfolio/FruitfolioResearchPackage.json`. It verifies the active package and review, atomically installs the exact bytes, and reads them back. Commit the approved package, manifest, review and archive on the development branch. Build and rerun real Ask retrieval, strict grounding, all-topic/difficulty game providers, saved citations, offline fallback, educational facts and applicable accessibility/UI tests before release.

This installation path is the existing Xcode resource consumed by `FruitfolioResearchPackageStore`. It does not modify spawn timing, scoring, fruit classification, collisions, obstacles, star passes or app data. A running app's package cache is not invalidated; active questions retain their original choices, answer key, explanation and evidence. New app launches use the newly bundled version. Saved content must continue using its serialized source/version snapshots, never a lookup of the newest source by ID alone.

## Rollback and migrations

Run `python3 Tools/manage_research_snapshot.py rollback --root ResearchUpdates`, then repeat `install`, rebuild and verify. Rollback verifies the prior immutable snapshot first and swaps only the local selection pointer. It does not delete later snapshots or rewrite saved questions, completed rounds, citations or user data.

Schema changes require a separately reviewed explicit migration; the tool rejects unknown application schemas. Never migrate historical educational facts by regenerating them from current research. Preserve their original text, source versions and recorded outcomes. Missing legacy snapshots must be reported as missing rather than invented. This tooling does not yet establish full completed-round fact persistence or all end-to-end update compatibility; those app acceptance tests remain required.

## Actual verification

Six local Python tests cover valid activation/rollback with byte-for-byte old snapshot preservation, rejected update/review nonmutation, duplicate IDs/topics/versions/retirement, corrupt archived bytes, duplicate JSON keys, and exact resource installation without changing a synthetic gameplay file. The original 5,477-note package passes these structural compatibility checks unchanged. These are tooling tests, not iOS runtime, clinical review or complete 478-item acceptance. Actual application compatibility and approved live-content update tests remain pending.
