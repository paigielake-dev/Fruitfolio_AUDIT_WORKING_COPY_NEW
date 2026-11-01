# Hormone measurement presentation

## Implemented approach

The existing educational Hormone Rhythm remains intact. Optional Adjusted Rhythm continues to refuse an unsupported personal calibration and displays the founder's exact insufficient-information message. A measured-history presentation now uses only separate point marks at actual recorded dates, with no line, fitted curve, interpolation, extrapolation, inferred missing value, or normal/abnormal classification. Exact entered strings remain visible beside the graph and unchanged in storage.

Series are separated by hormone (including the exact Other Hormone name), exact unit string, and exact sample type. Different units and samples are never converted or combined. Numeric coordinates are display-only; the exact-value text is authoritative. Invalid or undated records cannot become chart points. Existing measurement records and prediction-confidence calculations are not modified.

## Scientific investigation

Reviewed on November 1, 2026:

- American Society for Reproductive Medicine. *Fertility evaluation of infertile women: a committee opinion* (2026). https://www.asrm.org/practice-guidance/practice-committee-documents/fertility-evaluation-of-infertile-women-a-committee-opinion-2026
- American Society for Reproductive Medicine. *Testing and interpreting measures of ovarian reserve: a committee opinion* (2020). https://www.asrm.org/practice-guidance/practice-committee-documents/testing-and-interpreting-measures-of-ovarian-reserve-a-committee-opinion-2020/

These clinical sources distinguish the interpretation of individual tests from a continuous personal hormone profile. Measurement timing matters; hormone-specific variability limits conclusions from an isolated result. They do not provide a validated general algorithm for reconstructing all of a user's hormone curves from sparse, heterogeneous entries. The engineering inference is therefore to present observations as observations and retain the adjustment guard, rather than invent a calibration.

This investigation is engineering documentation, not a new approved in-app evidence source. No external article was silently added to the Approved Source Library or substituted for the founder-provided research. The sources do not establish that all educational personalization is impossible; they do not resolve the missing approved quantitative calibration contract.

## Remaining verification/dependency

The new chart code compiled in actual Run46 and all three series-data unit tests passed. Dedicated point-graph simulator visual/accessibility review remains pending. Dynamic Type, VoiceOver reading order, multiple series, repeated same-day results, and graph visual states must be verified before these requirements can be marked PASS. Full Adjusted Rhythm remains dependent on a scientifically defensible, approved mapping with explicit sufficient-context criteria; it is not claimed complete.
