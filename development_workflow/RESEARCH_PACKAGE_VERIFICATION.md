# Local research package verification

The runtime's missing `FruitfolioResearchPackage.json` is now generated from the preserved founder DOCX by `python3 Tools/compile_research_package.py`. Run with `--check` to verify exact reproducibility, original-asset hashes, package bytes and per-chunk paragraph provenance. The package is a resource at the existing app folder root; actual Xcode bundle inclusion has an added test and remains unrun on Linux.

- 395 source topic groups; 4,458 exact paragraph slices, including quarantined originals.
- 2,722 retrievable note chunks; 715 original APA-style reference records.
- 144 topic groups are quarantined for missing/ambiguous references or the binding LifeBridge two-source requirement. See `RESEARCH_PACKAGE_REPORT.json` for every reason and source paragraph.
- `retrievalEligibility: false` excludes a quarantined note from the actual Swift index. The optional field preserves older package decoding.
- `founderCorpusAPA7` identifies attribution in the supplied founder corpus. It is **not** independent clinical/source verification. Authors, titles, publication dates, DOI and URL metadata are never invented; the full source reference is preserved verbatim.
- No citation string is treated as full-source scientific text. `sourceChunks` is empty until approved full-text source excerpts are actually supplied/compiled. The PDF is preserved and hashed as the founder voice reference; it is not automatically converted into scientific claims.
- The original DOCX and PDF bytes remain unchanged.

Actual Foundation Swift tests decoded the full package, verified all eligible note/source associations, excluded LifeBridge notes and exercised repeated retrieval. Latest Linux sample: index construction 1.259 seconds; 50 cached searches 1.284 seconds. This is not a before/after speedup claim or iPhone performance result.

Remaining acceptance: resolve quarantined references against original material, independently review clinical/citation accuracy, integrate approved full-source text, verify application-bundle loading and normal/fallback generation, then physical-device responsiveness/memory and MADLAD language accuracy. Compilation is not acceptance of runtime medical behavior.

## Complete-context presentation

The compiled resource now preserves the original paragraph table alongside compact ranking slices. Retrieval restores/deduplicates complete paragraphs before synthesis and fallback presentation, preventing a slice boundary or the old 680-character display cap from dropping a qualifier. Generated facts must match a complete supplied paragraph (semantic markup may vary); arbitrary bridge/limitation fields are ignored in favor of shared deterministic framing. This is a conservative source-copy boundary, not a validated medical paraphrase/entailment engine. Clinical correctness and passage relevance still need review.
