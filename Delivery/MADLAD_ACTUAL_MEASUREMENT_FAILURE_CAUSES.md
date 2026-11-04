# Exact actual MADLAD measurement failure causes and guarded repair

The actual Run72 raw-output attachment was recovered losslessly from its referenced zstd XCTest payload despite the unfinished result bundle. Artifact SHA/CRC, object/payload SHA and test-summary reference are preserved beside the unmodified3020-byte JSON. This is actual model evidence, not regenerated expected text.

Observed causes:

- Portuguese/Italian changed2.5 to locale spelling2,5.
- Japanese used full-width２．５ｎｇ／ｍＬ.
- Simplified/Traditional Chinese translated the unit as纳克/毫升 or納克 / 毫升; Arabic usedنانوغرام/ملليلتر.
- Hindi changed the generic result into a density statement,2.5 grams per cubic centimetre, adding the digit3 and an unsupported physical quantity. That is a real semantic/unit failure, not a harmless punctuation variant. It stays rejected.

The guarded candidate adapter now treats explicit numeric-plus-immutable-unit spans as opaque source metadata, as it already does for citation IDs. MADLAD translates surrounding sentence content with private opaque slots; the adapter accepts restoration only if every exact slot occurs once and in the original order, with no added slots. Missing, duplicate or reordered slots fail closed. Original precision, exponent, spacing and unit bytes are restored verbatim. Final number/literal/citation checks remain strict. No dictionary guesses, changed-value acceptance, unit conversion, alternate model or cloud service is used.

Exact full-width ASCII counterparts may be canonicalized to restore those opaque IDs; other scripts are untouched. Scientific numeric notation is checked as a complete token so a changed exponent cannot pass as rearranged fragments. New pure tests cover precision, scientific notation, marker collisions, missing/duplicate/reordered/invented slots, full-width spelling and continued rejection of the actual unsafe Hindi output.

The existing actual eleven-target runtime test now exercises this candidate adapter with the same original medical fixture and same required invariants. Whether the official model reliably preserves the slots and medical wording must be demonstrated by the actual rerun. Candidates remain marked medicalMeaningVerified=false; production Ask translation is not enabled or claimed complete. Whole-language/clinical quality and all required-language end-to-end acceptance remain unfinished.
