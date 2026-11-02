# Outstanding implementation and acceptance work

This report does not invent an external blocker for ordinary unfinished development. The five-hour delivery is a source handoff; the following gaps remain. Per-item details and old failures are retained in the 478-item tracker.

## 1. Run the delivered source on a Mac

No new Apple compilation or runtime execution occurred here. Run the supplied separate build/unit/UI/audio/native batches, preserve actual xcresults/screenshots/logs, fix compiler or reproducible runtime failures and rerun. Historical sprint Run 9's four UI failures remain open: background/resume's underlying pause control; Files save/readback helper; largest-text game accessibility; normal game-opening contrast. Verify the original strict assertions, not weakened substitutes. Review every affected normal/largest text, VoiceOver, Reduce Motion, popup focus/dismiss and full-visibility state. Physical-device-only checks, audible quality, route/interruption behavior, performance/memory/thermal behavior and protected-data lifecycle remain unverified.

## 2. Finish core data and game gaps

Cycle onboarding now serializes draft access and protects rejected draft saves. **Onboarding and cycle-history files are not one atomic cross-file transaction**: reconciliation can still modify cycle history before a later onboarding-file write fails. Complete a format-preserving transaction/recovery design and fault-injection tests before accepting full persistence safety.

Run all new hormone unsaved-edit/restart/corruption tests, export snapshot/cancellation/equality tests, and the actual Files save-and-reopen test. Confirm real account metadata, health context, cycle data, hormone values, game progress/questions/citations and timestamps retain original values; unreadable data must preserve bytes and fail explicitly. Confirm intentional deletion affects only its specified stores.

Fruit Basket finalization now commits actual progress and original round evidence in one staged snapshot before visual delays. Seven new persistence cases and the actual hosting/settling cases need Mac execution. **Classification controls still lack standalone-star acquisition**. Implement accessible star entry/settling consistent with the specification; do not silently auto-award a pass. Verify actual catches/reveal, bad fruit with zero/one/multiple passes, rare drops, painted collision bounds, timers/deallocation/retry, rainy obstacles and long-source question scrolling.

## 3. Complete specification alignment and visuals

All 478 IDs are accounted for;364 still explicitly have PENDING authoritative-spec cross-reference metadata. Resolve individual exact references, acceptance criteria and discrepancies against the full 308-page source. Source existence and a successful build do not complete a requirement.

The coded book preserves continuous deformation and selected color in source, but actual selected-spine continuity, saved reading-content composition, duplicate/jump prevention and responsive visual acceptance remain partial/unverified. Review launch/Hub/tour, continuous Ask paper and reading position, shelves/pages/Guide saving, all popup layouts, Contact/FAQ, wheel/calendar/logging, Settings/Account/privacy/export and Fruit Basket nested states. No new current-source screenshots or animation recordings were captured.

**Approved FAQ tulip artwork or its authoritative existing-asset mapping is missing.** Do not substitute unrelated art or generate replacement founder artwork. Preserve existing cloud/sparkles and Contact assignments. Founder/About copy and LifeBridge details must come from approved content; current fallback/placeholder boundaries do not establish complete feature acceptance.

## 4. Preserve science and finish reviewed content

Adjusted Hormone Rhythm lacks a validated, approved calibration method and sufficient evidence/context for personalized educational adjustment. Keep actual measurements as actual dated points with exact units/sample types; do not fabricate concentrations, interpolate unmeasured values or imply ovulation/fertility/diagnostic certainty. Complete supported disclosures and context-specific educational content with approved evidence. Pregnancy/contextual education structural checks are not clinical review or complete production wiring.

The supplied research corpus and original documents are retained and structurally checked. Bibliography-only records are not full-text evidence. Complete claim-by-claim scientific/APA7 review and source-version/fallback verification across supported topics; never invent citations or reinterpret source content to increase coverage.

## 5. Complete founder-controlled services and localization

Verify the actual founder account, access/purchase and distribution configuration. Local shared username validation/persistence is implemented, but production identity reservation, comprehensive multilingual moderation and privacy-preserving real-name enforcement are unresolved. Do not add legal-name collection or a fake backend. Keep health data local according to the specification. LifeBridge approved integration details remain a content dependency.

Complete the UI catalog and all screens/dialogue/errors/accessibility for every required individual language, with native review, RTL/script layout and restart tests. The catalog/selector does not establish localized or medically accurate content. Missing translations currently disclose source-English fallback.

MADLAD inference is reserved for the separate founder sprint. Preserve official files and prior diagnostics. Historically reported mixed-language Japanese and broad medical accuracy/tag/script/memory issues remain unaccepted; five previously absent exact target tags were tpi,ty,rar,niu,gil, not re-investigated here. Do not substitute another model/language/cloud service.
