# Literal Unicode hormone-name matching

The post-retrieval hormone matcher now accepts Unicode dash punctuation and spacing separators inside the full Anti-Müllerian and follicle-stimulating names. Existing diacritic/case folding, letter/number word boundaries and short-symbol aliases are unchanged. This is search-only matching; original paragraph, heading and citation data are not normalized or rewritten.

Actual pre-fix focused suite: six tests with 17 failed assertions. The source/log hash receipt is RUN_LOGS/Hormone-Unicode-name-matching-prior-failure.json. All six pass after the narrow fix. Three new cases cover typographic hyphens/spaces, retained boundary/loose-word rejection, and the actual provider returning byte-identical Unicode paragraphs only when both note eligibility and source-approval flags permit them. The approval fixture is explicitly synthetic/nonclinical, not a real medical source. The separate real-corpus case continues to verify complete eligible paragraphs and their own source records for all seven specified hormones.

Full suites: 793 portable XCTest, 815 native CPU XCTest, 21 Swift Testing per overlapping run; 60 workflow checks. 311 Swift files parsed, project references resolved and actual SwiftSyntax sound ownership clean. No corpus, artwork, models, storage schema or catalog changed.

All 20 measurement and 56 Guide Apple UI launches remain written but NOT_RUN. Real library rendering/selection, primary-source completeness, clinical citation/meaning review, official MADLAD weights/tokenizer/language inference and device acceptance remain open. Retrieval provenance tests are not clinical approval or verification of model translation.
