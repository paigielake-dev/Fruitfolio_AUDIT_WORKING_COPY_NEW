# Source 89: grounded playable fallback and actual audit repairs

## Confirmed defect
The production Fruit Basket view constructed Prompt28UnavailableResearchProvider by default. No active application call supplied a working provider. Existing physics/menu tests did not prove educational gameplay could start.

## Repair and boundaries
The default is now a canonical-library provider using the existing package store, local retriever, source approval predicate, safety router and unchanged strict generated-draft validator. It retrieves notes first, then actual available approved source chunks if needed. It never makes scientific claims from model memory or bibliography labels. A deterministic reading-comprehension question removes one literal word from a complete source passage; answer choices are individual words from that passage, never fabricated medical statements. The exact original passage is restored as its explanation, with approved APA references at reveal. Topic relevance must be present in the passage. Urgent or decorative/kaomoji-bearing excerpts are not gamified.

This is a usable bounded fallback, not acceptance of complete AI question generation or all difficulty/depth requirements. Exact source snapshots, versions, passage and evidence identity are encoded with the question; saving no longer substitutes the package version for each original source version. Legacy questions remain decodable. Unverified legacy attribution is not fabricated.

New Apple tests cover all five menu topics at each difficulty, exact passage reconstruction, approved source identity, persistence roundtrip, stable exclusion and fail-closed unsupported/unapproved requests. These tests are written, not yet executed. No game requirement is promoted to PASS by this checkpoint. Actual end-to-end gameplay and visual settling remain pending.

## Actual Run 85 evidence
Commit 8316cac3f512c6789c8c43cfe126d564bb039d2c built successfully. Both smoke XCTest cases passed; recorder failed with zero bytes. Strict native accessibility: 9 passed and 2 failed. Account, Ask, Contact, Cycle, FAQ, Guide, Hub normal, Library and Settings passed. Fruit Basket failed text clipping. Hub largest failed an unnamed inner Button nested below the named outer action. Exact artifact 13117681784 SHA256 c141b1b2fc3fffc0285c261caf74d37ee0b457c5f343bbc7de403909a5ff2483; full ZIP CRC verified. Original issue descriptions and screenshots preserved under AppleRuns/Run85/AccessibilityAudit.

The Hub action now retains one native Button rather than creating an additional container-button node. Its visible label remains a detectable child. Fruit Basket home keeps its watercolor composition and minimum viewport height while allowing text/content to grow in a real scroll view. Strict audit thresholds remain unchanged. Rerun pending.
