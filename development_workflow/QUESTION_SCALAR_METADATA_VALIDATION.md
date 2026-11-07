# Question scalar metadata validation

The existing production isPlayable boundary now requires nonblank explanation, source identifiers, package version and review-status label plus a finite creation timestamp. Invalid data cannot proceed to the existing gameplay or saved-research builder gates. Valid strings/identifiers/dates are not trimmed or rewritten; the check only rejects malformed values. A nonblank review label is structural presence, not proof of clinical review or citation authenticity.

One genuine production-type/saved-builder regression covers six invalid cases: blank explanation/source ID/version/review label, NaN date and infinite date. The pre-fix six-case saved-source suite reproduced twelve assertions. Boolean-only failure output avoids treating nonfinite-date formatting as part of the contract. Existing original excerpt UTF8, citation/version precedence, legacy known-package fallback and duplicate-source rejection tests remain.

The saved-copy builder, persisted schemas, research/citation text, source-record version policy, assets and safety router are unchanged. Existing valid legacy attribution remains accepted without inventing source records. Individual source-record version presence is a separate follow-up, not certified by these question-level checks.

Final supported suite results are attached to batch/checklist evidence. Structural validity does not establish factual accuracy, human clinical/source approval, genuine Apple provider/error/recovery presentation, device behavior or official MADLAD/native-language inference. These external/runtime requirements remain open.
