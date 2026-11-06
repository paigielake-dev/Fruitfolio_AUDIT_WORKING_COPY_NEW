# Implementation log

## P1-modal-accessibility

- Recovered clean branch development/prompt-1b-complete from defa3c9; preserved existing app, artwork, research and resources.
- Preserved original source materials and all 478 checklist descriptions/printed IDs. Added checkpoint, evidence register and recovery protocol.
- Shared modal modifier now removes blocked background content from the accessibility tree. The existing hit-testing block remains active. Reduce Motion uses identity scale, retaining the existing short blur transition.
- Added Swift unit coverage for all four active/Reduce Motion combinations in FounderOverrideIntegrationTests. Swift/Xcode execution pending on macOS.
- Requirements: Part 1 sequences 1–6 and 70 remain IN_PROGRESS; broad visual/accessibility requirements are not marked complete.
- Commit: containing commit, batch P1-modal-accessibility. See Git history for authoritative SHA.
- Executed workflow integrity: 2 passed; Mac script syntax and diff whitespace checks passed. These do not establish iOS behavior.

## P1-popup-dismissal-ownership

- Previous checkpoint: 56723585e21a11416b22ce753b3743967e7f2cc8.
- Part 1 sequence 6: delayed host completion now captures popup UUID and coordinator rejects stale completions or non-dismissing states. Task cancellation exits without clearing a popup.
- Added regression tests covering a replacement that is itself dismissing and an attempted completion of a still-visible popup.
- Executed Python workflow tests: 2 passed. Diff check passed. Swift tests NOT_RUN; macOS verification script includes the affected suite.
- Removed a generated Python bytecode file accidentally included in the first checkpoint; added workflow ignore rules.
- Commit: containing commit, P1-popup-dismissal-ownership.

## P1-canonical-watercolor-controls

- Previous checkpoint: 00818937eb837d50ba905864584c0d0a07c34f20.
- Part 1 sequences 7–12: primary/secondary compatibility controls now use existing canonical pill artwork, shared pop animation, synchronous action and audio. Cycle onboarding callers inherit the change. Full app-wide control migration remains pending.
- Canonical pill labels have no line limit or font shrinking; height follows wrapped content, with resizable image-center regions preserving painted edges. Device visual inspection pending.
- Added UIHostingController sizing regression for a long label at accessibility3. NOT_RUN on Linux; added suite to Mac script.
- Python workflow tests: 2 passed. Shell syntax and whitespace checks passed. No iOS runtime claims.
- Commit: containing commit, P1-canonical-watercolor-controls.

## P1-scrollable-character-dialogue

- Previous checkpoint: 02e08666bfa46976777e92a2e3c0b7910e419b5c.
- Part 1 sequences 18–26 (selected related entries) remain IN_PROGRESS. Character dialogue scrolls inside the existing artwork writing area. Short content retains vertical centering. Labels wrap, scale with Dynamic Type and use minimum 44-point targets.
- Added stable scroll/action accessibility identifiers and a DEBUG-only isolated modal regression route; it does not read/write user data or enable itself in release.
- Added UI tests asserting hidden background, reachable long-content dismissal, restoration, Reduce Motion/accessibility size, and screenshot attachments. They have NOT_RUN here.
- Executed workflow tests: 2 passed; shell syntax and whitespace checks passed. Mac runner exits 2 with explicit missing-Xcode diagnostic.
- Founder binary specification preserved, but antiword download failed because distro package indexes do not list it. Full-text extraction remains pending; no content invented.
- Commit: containing commit, P1-scrollable-character-dialogue.

## P1-notebook-popup-geometry

- Parent checkpoint: 675d8a29a523acac9c8a58ab57356d1e40637bdd.
- Source-order requirements: [2, 3, 4, 13, 14, 15, 16, 17, 18, 19, 20, 23, 24, 26].
- Notebook popups use measured 684x564 artwork with a bounded scrollable writing region; viewport height and keyboard constraints determine aspect-preserving paper size. Removed nested dim tint and create dialog minimum-height/local geometry. Existing artwork and actions preserved. Device geometry/VoiceOver not yet run.
- Tests added/updated: Prompt1BPopupLayoutTests, WorkflowIntegrityTests/test_notebook_geometry_matches_actual_bundled_png.
- Verification: {"workflow": "3 passed", "shell_syntax": "passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Continue Part 1 decorative layout: handle collision avoidance using approved anchors and painted bounds without random repositioning; then reconcile semantic text paths.
- Commit: containing commit for batch P1-notebook-popup-geometry.

## P1-decorative-safe-resizing

- Parent checkpoint: 91449cdd12ae709639a02da853be5f7ddbf38548.
- Source-order requirements: [28, 31, 33, 34, 35, 36, 37, 42, 43, 44, 45].
- Decorative geometry now validates finite inputs and painted bounds, tries only role-bounded sizes at the approved anchor, and omits art when all candidates collide with protected content. Shared authority still needs screen-by-screen adoption; no claim of app-wide completion.
- Tests added/updated: Prompt1BDecorativeLayoutTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Consolidate semantic rendering and remove Ask keyword-underlining while preserving explicit contextual emphasis and saved content.
- Commit: containing commit for batch P1-decorative-safe-resizing.

## P1-semantic-rendering-consolidation

- Parent checkpoint: 3688eb8ff9ba4dd30033ef5e69183d17f5cbb367.
- Source-order requirements: [46, 47, 48, 49, 50, 51, 54, 56, 60, 61, 62, 63].
- SwiftUI and selectable UIKit Ask text now share explicit semantic spans and inline Markdown parsing. Removed symptom keyword underlining; explicit emphasis survives Codable round trips and full saved-answer display. Citation/numeric/plain text preservation has regression cases. UIKit rerendering is keyed to source and Dynamic Type to avoid resetting selection on unrelated updates. Full app-wide contextual annotation, streaming delimiter edge cases and saved-excerpt formatting remain incomplete.
- Tests added/updated: Prompt1BSemanticTextTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Inspect Part 1 lifecycle work, then implement Part 2 intro pacing and reduced-motion foreground resumption without restarting or introducing spatial motion.
- Commit: containing commit for batch P1-semantic-rendering-consolidation.

## P2-intro-pacing-and-resumption

- Parent checkpoint: b81f8f2e42be6465991d7285aa3484ce8c03b908.
- Source-order requirements: [71, 72, 73, 80, 83, 84, 85, 86, 87].
- First-launch stage holds now total about 6.8 seconds while retaining existing transition durations. Inactive state pauses progression; repeated inactive/background events do not overwrite the checkpoint. Foreground restores ambience and reduced-motion launches resume through crossfades instead of the normal spatial sequence. Simulator animation/audio verification remains pending.
- Tests added/updated: Prompt04IntroTests/testFirstLaunchScheduledDurationIsSixToEightSeconds, Prompt04IntroTests/testReducedMotionRemainsReducedAfterInterruption.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Cancel stale Hub invitation and navigation work; then continue Ask session/scroll correctness independently of Xcode.
- Commit: containing commit for batch P2-intro-pacing-and-resumption.

## P2-hub-invitation-ownership

- Parent checkpoint: 7a71d166216bdfc294150bf6404fbaa308539198.
- Source-order requirements: [88, 90, 91, 95].
- Hub invitation tasks are owned, cancelled on disappearance/inactivity/manual replay, and generation-checked after delay. Eligibility requires the active Hub and incomplete tutorial. Waiting invitations can retry when another popup clears, instead of appearing over a different screen. Existing popup audio and one-time tutorial persistence remain in their existing owners; semantic tour dialogue still needs further integration.
- Tests added/updated: Prompt07FirstLaunchTourTests/testDelayedInvitationRequiresActiveUncompletedHub.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Fix Ask request cancellation/reset races and session history so stale responses cannot mutate a newer session, then inspect earlier-answer save associations.
- Commit: containing commit for batch P2-hub-invitation-ownership.

## P3-ask-session-cancellation

- Parent checkpoint: 6415b10404b342cfc2c73ab9ad0c8506f9ca9a97.
- Source-order requirements: [97, 98, 118, 119, 120, 121, 122, 123, 124, 126, 136].
- Ask retains validated answers and assistant turns in session memory. Reset cancels both retrieval and typing, invalidates generation, clears history/draft and rotates session ID. Late provider responses/progress cannot mutate a reset or newer generation, even if cancellation is ignored. Cancellation no longer appears as a user-facing failure. Exiting Ask clears session while explicit saved library data is untouched. History UI integration is next.
- Tests added/updated: Prompt1BAskLifecycleTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Render ordered historical Ask answers and associate save state with answer identity; then implement near-bottom-only follow scrolling.
- Commit: containing commit for batch P3-ask-session-cancellation.

## P3-ordered-history-and-scroll-policy

- Parent checkpoint: 5722a4ec39da9e04896e4e507d83561b438fc560.
- Source-order requirements: [96, 97, 98, 100, 103, 105, 106, 107, 108, 109, 124, 125, 127].
- Ask now renders session turns in order, retains earlier selectable answers with their own citations and save actions, and builds saved content from the selected answer's original question/body/provenance. Save completion updates the matching answer ID rather than the newest response. Bottom geometry gates streamed/new-turn auto-follow; reading older content does not force a jump. Repeated identical excerpt occurrence identity and continuous paper edge treatment remain unfinished. Complete founder document extraction succeeded and is preserved for targeted reconciliation.
- Tests added/updated: Prompt1BAskLifecycleTests/testMultipleTurnsKeepAnswersInOriginalSessionOrder, Prompt1BAskScrollTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable", "founder_spec_extraction": "antiword built from HTTPS Git source; full UTF-8 output saved"}.
- Next action: Track excerpt saves by answer ID and exact rendered selection range; then continue image-import cancellation and persistence correctness in Part 4.
- Commit: containing commit for batch P3-ordered-history-and-scroll-policy.

## P3-exact-excerpt-save-identity

- Parent checkpoint: ca1f030e19db752073f25383449e665b70131564.
- Source-order requirements: [109, 124, 125, 127, 128, 156, 157, 158, 159].
- Save badges now use answer UUID plus exact rendered UTF-16 selection location/length rather than excerpt text. Both current and earlier answer selection delegates report ranges; immutable pending saves capture the selected identity. Only successful save callbacks record badges; cancelled requests do not. Two identical phrases in different answers or occurrences remain distinct. Existing persistence schemas and provenance are preserved.
- Tests added/updated: Prompt1BExcerptIdentityTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Inspect Part 4 image import ownership, cancellation, validation and off-main-thread processing; repair the next source defect.
- Commit: containing commit for batch P3-exact-excerpt-save-identity.

## P4-owned-validated-photo-import

- Parent checkpoint: dcad3186b73a29176efdd8d86afef5db19e8bf2a.
- Source-order requirements: [198, 201, 202, 203, 204, 205].
- Photo imports now cancel and invalidate previous loads, preserve newer selection state, and cancel when the page disappears/changes. ImageIO validates input, downsamples off-main with orientation applied, and strips camera metadata during JPEG encoding. Disk writing is off-main; failed/cancelled attachment removes newly written orphan files. Attachment reads current store state after awaits to avoid overwriting newer edits. Device photo-picker and persistence UI verification remains pending.
- Tests added/updated: Prompt1BImagePreparationTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Check shared guide persistence propagation, then Part 5 settings/account/context and hormone safeguards in source order, recording external blockers without fabricating services or algorithms.
- Commit: containing commit for batch P4-owned-validated-photo-import.

## P5-persistent-global-audio-mute

- Parent checkpoint: fd1b3ce56aa10f69fae8d8e261ded9eb828e5686.
- Source-order requirements: [222, 223, 224, 225, 226, 227, 228].
- Added a persistent global mute independent of per-channel toggles and volumes. All four audio channels consult the same policy; live audio reconciliation stops muted loops/one-shots and can restore requested loops after unmuting. Nonfinite stored volumes recover to zero. Existing settings and channel values remain intact. Device audio/interruption behavior is not yet verified.
- Tests added/updated: Prompt1BAudioSettingsTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable", "Swift_syntax_previous_batches": "36 changed Swift files parsed without syntax errors; not a build/runtime test"}.
- Next action: Replace production-facing demo authentication/sync success with explicit unavailable-service handling while preserving local profile data, then implement hormone-measurement safeguards.
- Commit: containing commit for batch P5-persistent-global-audio-mute.

## P5-honest-account-service-boundaries

- Parent checkpoint: a0c2281e82afb343cc23a6d06939ed46f3306eab.
- Source-order requirements: [229, 230, 231, 232, 233].
- Account UI no longer calls demo sign-in. Without an approved provider it reports the service unavailable and preserves local identity/data. Development sign-in is guarded out of release builds. Sync no longer claims successful uploads after a timer or clears pending edits; ownership checks no longer pretend a timer verified a receipt. Existing shared public username policy is retained. Production service/receipt integration is an explicit external blocker.
- Tests added/updated: Prompt12AccountPrivacyStoreTests/testProductionSignInCannotFabricateAnAuthenticatedAccount, Prompt12AccountPrivacyStoreTests/testUnavailableCloudSyncPreservesPendingLocalEdits.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Implement optional Hormone Information records, validation, local CRUD/history, and a My Context entry while keeping educational curves and predictions separate.
- Commit: containing commit for batch P5-honest-account-service-boundaries.

## P5-hormone-measurement-local-workflow

- Parent checkpoint: a878007b19b0c9bb89288971f7a941f8798e3dc2.
- Source-order requirements: [235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 262, 263, 265, 266, 270, 272, 273, 276, 278, 279, 280].
- Added optional My Context -> Hormone Information with seven specified hormones and controlled Other, required/optional fields, decimal validation, exact result/unit preservation, local chronological/filterable history, edit/delete confirmation and unsaved-edit protection. Corrupt storage is retained and cannot be silently overwritten. Measurements are separate from Ask, predictions and educational curves; insufficient-method explanation is shown instead of inventing calibration. Educational Hormone Library, full localization and richer device accessibility verification remain unfinished.
- Tests added/updated: Prompt1BHormoneMeasurementTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "new_hormone_syntax": "2 files parsed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Add explicit measurement export/erase controls and artwork, then repair cycle confidence boundary tiers and Fruit Basket interruption/finalization independently.
- Commit: containing commit for batch P5-hormone-measurement-local-workflow.

## P5-explicit-measurement-export-and-erasure

- Parent checkpoint: e5b44c983fb67fa0a14724f70d3fde7cfc80ba8d.
- Source-order requirements: [249, 252, 259, 260, 263, 265].
- Measurement history now offers explicit JSON file export and confirmed local erasure, scoped only to its own records. Corrupt records can be erased only through the explicit confirmation path. Added existing estrogen artwork beside the header, hidden from accessibility. No automatic sharing, unit conversion or prediction linkage added.
- Tests added/updated: Prompt1BHormoneMeasurementTests/testExplicitExportAndEraseContainOnlyMeasurements.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Correct cycle confidence thresholds at logged-period boundaries and verify no measurement-derived confidence changes; then inspect Fruit Basket finalization/interruption.
- Commit: containing commit for batch P5-explicit-measurement-export-and-erasure.

## P6-period-count-confidence-boundaries

- Parent checkpoint: 861dfaea9579d2b71da20dc96172ba0cce966f34.
- Source-order requirements: [281, 285, 286, 287, 288, 289, 300, 301].
- Corrected confidence and data-sufficiency off-by-one: five logged periods no longer qualify for strong confidence; at least six starts/five completed cycles are required. High-variation safeguards still downgrade confidence. Measurement records are not inputs. Updated older five-period strong-confidence expectations to the controlling founder tiers and added all count boundaries. Mac script now includes the full unit-test target rather than only early batches.
- Tests added/updated: Prompt17CyclePredictionEngineTests/confidencePeriodCountBoundaries.
- Verification: {"workflow": "3 passed", "shell_syntax": "passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Make Fruit Basket finalization idempotent and ensure interruptions cannot resume a round that has already ended; preserve exact bad-fruit star-pass behavior.
- Commit: containing commit for batch P6-period-count-confidence-boundaries.

## P7-owned-round-finalization

- Parent checkpoint: e1b17aa66cf812b4b2942d292297da56809a344b.
- Source-order requirements: [326, 327, 330, 331, 332, 333, 334, 338, 365, 366, 367].
- Round completion now owns a UUID and finalizes once before updating persistent totals. Inactivity/exit resolves an already-ended pending result instead of pausing and resurrecting it. Delayed tasks reject superseded rounds. Starting an explicit new attempt resets pause state. Existing engine rule remains exact: no pass ends round; a protected bad catch consumes one pass and continues. Regression cases cover both outcomes plus interruption and duplicate completion.
- Tests added/updated: Prompt28FruitBasketTests/testBadFruitWithoutPassCannotResumeAfterInterruptionOrFinalizeTwice, Prompt28FruitBasketTests/testBadFruitWithPassConsumesOneAndContinuesThroughPauseResume.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Review remaining FAQ/contact interactions, then implement MADLAD encoder-decoder inference and localization support validation with actual model/runtime constraints.
- Commit: containing commit for batch P7-owned-round-finalization.

## P8-faq-and-contact-interaction

- Parent checkpoint: 6fd34c9a6a695ac3586d0e5f754115e60b593054.
- Source-order requirements: [373, 374, 375, 376, 377, 378, 379, 380].
- FAQ disclosure buttons now use shared pop/sound behavior and expose expanded/collapsed values plus stable IDs. Answers use canonical semantic rendering. Fruit Basket FAQ explicitly states both final bad-fruit outcomes. Contact actions now report an unavailable device handler instead of silently doing nothing. Approved destination URLs/content are retained; no messages are sent automatically.
- Tests added/updated: Prompt1BFAQSafetyTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Implement local MADLAD encoder-decoder runtime, model manifest and language support gates; protect scientific tokens and integrate dynamic translation with Ask and reading workflows.
- Commit: containing commit for batch P8-faq-and-contact-interaction.

## P9-madlad-encoder-decoder-and-integrity

- Parent checkpoint: d2ea6d847b9e77a89661ba193fc5e2f8958f3b92.
- Source-order requirements: [392, 393, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433].
- Implemented a local serialized T5 path using llama_encode, decoder-start token and autoregressive llama_decode, deterministic sampling, cancellation, UTF-8 decoding and truncation rejection. Manifests require official checkpoint identity/revision, SHA-256 GGUF integrity and actual language-tag membership plus tokenizer round-trip checks. Shared process backend ownership prevents one model from freeing another's backend. Scientific placeholders reject lost/reordered tokens or added numerical claims. Runtime has not compiled or executed: official model access is denied by proxy and draft network edit was rejected as uneditable. No unsupported language or inference success is claimed.
- Tests added/updated: Prompt1BMADLADManifestTests, Prompt1BScientificTranslationTests, Prompt1BTranslationPipelineTests.
- Verification: {"workflow": "3 passed", "diff": "passed", "translation_syntax": "parsed without errors; not a compile/inference result", "Swift_iOS": "NOT_RUN: Xcode unavailable", "MADLAD_inference": "BLOCKED: no verified model/tokenizer resources; huggingface.co proxy 403; draft_not_editable"}.
- Next action: Build a reproducible local conversion/manifest tool and integrate display-only translation into Ask, saved pages and guide reading without changing source records.
- Commit: containing commit for batch P9-madlad-encoder-decoder-and-integrity.

## P9-display-translation-and-reproducible-packaging

- Parent checkpoint: a650b1a77cfca2b0bd43f266da37bf568f2c72be.
- Source-order requirements: [392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443].
- Added display-only, language-reactive translation to completed/current and historical Ask answers, app-generated saved pages and guide reading. Original source/provenance and user notes/measurements remain unchanged; failures visibly retain original text. Selection badge identity includes display language. Shared action labels now resolve catalog keys. Added a local F16-to-Q4_K_M conversion script and a manifest packager deriving coverage solely from GGUF tokenizer tags. Pipeline has not converted or inferred with real weights because model retrieval is blocked. Static translations, clinical quality, long-input chunking beyond paragraphs and physical-device acceptance remain incomplete.
- Tests added/updated: MADLADPackagingTests, Prompt1BMADLADManifestTests, Prompt1BScientificTranslationTests, Prompt1BTranslationPipelineTests.
- Verification: {"workflow_and_packaging": "5 passed", "shell_syntax": "passed", "Swift_syntax": "65 changed/new files, zero parser errors; not compiled", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable", "MADLAD_inference": "BLOCKED: official model/tokenizer absent, proxy 403"}.
- Next action: Run all supported verification, fix source/API issues found, reconcile tracker source mappings and then return to the first unfinished requirement; do not treat Part 10 checks as completion.
- Commit: containing commit for batch P9-display-translation-and-reproducible-packaging.

## P10-regression-review-and-intro-skip

- Parent checkpoint: 5b5fa8139d7b36820ac800bc52054783224b06e1.
- Source-order requirements: [81, 82, 83, 84, 85, 86, 87, 248, 252, 265, 444, 449, 471, 472, 473, 476, 477].
- During integration review, added missing bottom-left control_next skip control with caption and accessible 44-point action. Skipping cancels old sequence generations and completes at most once; disappearing intro views cancel remaining progression. Unified measurement delete/all-delete presentation to avoid competing confirmation dialogs, and made Core Foundation image-output bridging explicit. No build/runtime pass is inferred from syntax checks.
- Tests added/updated: Prompt04IntroTests/testSkipCompletesOnceAndCancelsOriginalSequence.
- Verification: {"workflow_and_packaging": "5 passed", "Swift_syntax": "changed sources parsed with no errors; not compiled", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable", "MADLAD_inference": "BLOCKED: official model/tokenizer absent, proxy 403"}.
- Next action: Return to first unfinished requirements, reconcile evidence mappings, add portable functional verification where feasible, and continue remaining popup/decorative/localization gaps. Model retrieval remains blocked independently.
- Commit: containing commit for batch P10-regression-review-and-intro-skip.

## P1-shared-icon-artwork-and-disabled-actions

- Parent checkpoint: 9f40b9f35b3efaa81a6af8a72212120d798c1f77.
- Source-order requirements: [7, 8, 9, 10, 11, 12, 70, 384, 389, 390].
- Back/Close/Add/Confirm and bookmark controls now use the supplied canonical artwork rather than SF Symbol substitutes. The shared gesture surface respects both its local enabled flag and inherited disabled state for touch and accessibility actions. Hold-label tasks are owned/cancelled and Reduced Motion uses an opacity-only identification transition. Device interaction/screenshot regression execution remains pending.
- Tests added/updated: Prompt08GlobalControlsTests.
- Verification: {"workflow_and_packaging": "5 passed", "Swift_syntax": "zero parser errors; not compiled", "diff": "passed", "Swift_iOS": "NOT_RUN: Xcode unavailable"}.
- Next action: Adopt shared decorative layout on FAQ/contact headers using measured assets and protected regions; keep missing tulip/cloud artwork as a precise resource blocker instead of substituting unrelated illustrations.
- Commit: containing commit for batch P1-shared-icon-artwork-and-disabled-actions.

## P10-compiled-portable-regressions

- Parent checkpoint: 308067e81304e7491fe0742fb8382df182eed5f1.
- Source-order requirements: [244, 245, 246, 247, 255, 288, 332, 333, 409, 422, 424, 426, 443, 444, 447, 448, 454, 458, 460, 462, 466, 467, 476, 477].
- Installed official Swift 6.2.1 after checking its detached signature with the Swift project's published release key (fingerprint 52BB7E3DE28A71BE22EC05FFEF80A866B47A981F). Isolated existing Foundation model/policy declarations without changing their type names or data keys. Portable runner compiles exact production source copies with existing/new XCTest and Swift Testing suites. Initial harness missing-source/cache issues and an ambiguous CGFloat.infinity test literal were diagnosed and fixed. Portable algorithms now compile and tests execute; Apple UI/framework/model inference remains unrun.
- Tests added/updated: Prompt17CyclePredictionEngineTests, Prompt1BPopupLayoutTests, Prompt1BExcerptIdentityTests, Prompt1BAskScrollTests, Prompt1BHormoneValidationTests, Prompt1BFruitBasketRulesTests, Prompt1BMADLADManifestTests, Prompt1BScientificTranslationTests, Prompt1BTranslationPipelineTests.
- Verification: {"portable_swift": "PASS; see complete current-run log for separate XCTest and Swift Testing counts", "workflow_and_packaging": "5 passed", "diff": "passed", "SwiftUI_UIKit": "NOT_RUN: Xcode unavailable", "MADLAD_inference": "BLOCKED: model/tokenizer absent, proxy 403"}.
- Next action: Implement actual shared decorative-header adoption with the approved Contact/Settings asset matrix; document missing tulip explicitly. Continue the remaining original checklist requirements after each batch.
- Commit: containing commit for batch P10-compiled-portable-regressions.

## P1-responsive-approved-header-art

- Parent checkpoint: 9aa3e44e623eaaa855fb76e1a50fde484589b444.
- Source-order requirements: [28, 29, 30, 31, 32, 33, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 385, 386].
- Shared decorative geometry is now used by sticky Contact, Settings and FAQ headers. Reserved columns protect text/back controls; artwork retains measured aspect ratios, uses bounded sizes and protected-region collision checks, and remains static while content scrolls. Contact uses green flecks/plum/sparkles; Settings uses lavender droplets/white flower/sparkles. FAQ removes conflicting fruit assignments but its required tulip remains an explicit missing-asset blocker; no unrelated flower or rain cloud is substituted. Converted geometry inputs to Foundation-only insets so its real tests compile on Linux.
- Tests added/updated: Prompt1BDecorativeLayoutTests, WorkflowIntegrityTests/test_header_art_dimensions_match_all_bundled_assets.
- Verification: {"portable_swift": "19 XCTest + 21 Swift Testing cases passed (40 total)", "workflow_and_packaging": "6 passed", "Swift_syntax": "72 changed files parsed, no errors; not an iOS build", "diff": "passed after removing trailing blank line in prior batch", "SwiftUI_UIKit": "NOT_RUN: Xcode unavailable"}.
- Next action: Implement the missing LifeBridge information destination and source slots with founder-provided official URLs, transparent missing-approved-content fallback and Ask discovery; then continue remaining shared/feature requirements.
- Commit: containing commit for batch P1-responsive-approved-header-art.

## P6-lifebridge-information-access

- Parent checkpoint: 588f20ce4d9ceaa91277200bbe6131c0a2ccb706.
- Source-order requirements: [315, 316, 317, 318, 319].
- Added a LifeBridge destination through FAQ and relevant Ask questions without adding a Hub button. Founder-specified official and Carrd URLs are exact, user-initiated and carry no health data. Approved-content slots require snapshots from both named sources with titles, URLs, retrieval/review dates and versions. Missing snapshots yield awaiting_verified_lifebridge_content and no organization-specific claims; normal-safety LifeBridge questions receive transparent missing-library fallback before unrelated research can be used as company evidence. Approved snapshots/application/disclosure are not invented and remain an external content dependency.
- Tests added/updated: Prompt1BLifeBridgeTests.
- Verification: {"portable_swift": "21 XCTest + 21 Swift Testing cases passed (42 total)", "workflow_and_packaging": "6 passed", "Swift_syntax": "zero parser errors; not an iOS build", "diff": "passed", "SwiftUI_UIKit": "NOT_RUN: Xcode unavailable"}.
- Next action: Correct Guide save confirmation artwork/Strawberry composition and own its cancellation lifecycle, then continue remaining original requirements.
- Commit: containing commit for batch P6-lifebridge-information-access.

## P4-strawberry-save-confirmation

- Parent checkpoint: 2e3bc7819ccdc28a0ab3f3826b157e9b7245581b.
- Source-order requirements: [217, 218, 219, 220, 221, 27, 70].
- Guide save feedback now uses the actual control_large_card artwork with Strawberry above the exact saved! caption, sized from measured 634x667 proportions. Removed the competing bookmark/extra celebration overlays. Save-feedback tasks cancel on replacement/disappearance and are scoped to the selected guide; open/close audio and VoiceOver announcement occur for successful saves. New compact-card geometry regression executes in portable Swift; rendered layout/audio remains pending on Apple hardware.
- Tests added/updated: Prompt1BPopupLayoutTests/testCompactSaveCardUsesOriginalAspectRatioAndWritingBounds.
- Verification: {"portable_swift": "22 XCTest + 21 Swift Testing cases passed (43 total)", "Swift_syntax": "zero parser errors; not an iOS build", "diff": "passed", "SwiftUI_UIKit": "NOT_RUN: Xcode unavailable"}.
- Next action: Repair semantic emphasis during partial streamed Markdown and preserve formatted excerpts, then continue localization catalog completeness and remaining context/education requirements.
- Commit: containing commit for batch P4-strawberry-save-confirmation.

## P10-native-runtime-recovery-and-apple-package

- Parent checkpoint: 2a0f59b7dfebe32db02515a34dc5115be2166229.
- Source-order requirements: [129, 136, 418, 419, 427, 428, 430, 441, 445, 446, 447, 448, 454, 466, 467, 475, 476, 477].
- Source files: Fruitfolio.xcodeproj/project.pbxproj, Fruitfolio/Core/Intelligence/FruitfolioGGUFResource.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Tools/build_llama_xcframework_mac.sh, Tools/typecheck_madlad_api.py, Tools/verify_apple_runtime.py, Tools/validate_xcode_project.swift, Tools/run_portable_swift_tests.py.
- Restored and SHA-verified the actual 491 MB Ask GGUF, built vendored CPU runtime outside the checkout, and executed local load/generation successfully. MADLAD's real Swift/C API path typechecks against supplied headers. Corrected absolute/stale Xcode references and added reproducible static device/simulator XCFramework packaging plus metadata preflight. Existing framework is simulator-only; actual Apple build/link remains blocked. Portable source isolation also includes Foundation semantic slice models/tests for the next streaming integration batch. In-progress Ask UI/view-model streaming changes remain uncommitted for the immediately following batch; recovery must preserve them.
- Tests added/updated: Prompt1BGGUFResourceTests, AppleRuntimePackagingTests, Prompt1BSemanticSliceTests.
- Verification: {"Ask_model_CPU": "PASS: actual verified GGUF generated a hello; exit 0; 0.518s wall; max RSS 566264KiB", "MADLAD_C_API_typecheck": "PASS; no Apple linking/inference", "project_metadata": "OpenStep parsed; target build-file references resolved", "portable_swift": "27 XCTest + 21 Swift Testing passed (48 total)", "workflow_and_packaging": "9 passed", "shell_syntax": "passed", "diff": "passed", "Apple_runtime": "NOT_RUN; device/simulator XCFramework not yet built", "MADLAD_model_inference": "BLOCKED: official resources unavailable through current network policy"}.
- Next action: Commit and continue the already-prepared semantic-span streaming integration after its portable slice tests; implement formatting-preserving saved excerpts and remaining original requirements.
- Commit: containing commit for batch P10-native-runtime-recovery-and-apple-package.

## P1-semantic-streaming-prefixes

- Parent checkpoint: ae335f75c2124cb6a009a4c5b0455fa75977051d.
- Source-order requirements: [46, 47, 48, 49, 50, 60, 62, 63, 65, 66, 67, 68, 69, 70, 134, 137].
- Source files: Fruitfolio/Ask/Prompt09AskViewModel.swift, Fruitfolio/Ask/Prompt09AskView.swift, FruitfolioTests/Prompt1BAskLifecycleTests.swift.
- Typewriter presentation now parses the complete validated answer once and reveals explicitly styled span prefixes, so unfinished Markdown delimiters never flash or change emphasis mid-word. Prefix slicing preserves grapheme clusters and semantic identities. Long answers batch three characters at the existing effective speed to reduce redundant publications. Cancelling only the presentation resolves to the already-validated full source instead of presenting a partial answer as complete. Portable span operations passed; the Combine/SwiftUI integration test is added but unrun on Linux.
- Tests added/updated: Prompt1BSemanticSliceTests, Prompt1BAskLifecycleTests/testTypewriterPublishesStyledPrefixesWithoutRawMarkdownMarkers.
- Verification: {"portable_swift": "27 XCTest + 21 Swift Testing passed (48 total); includes semantic slice behavior", "Swift_syntax": "zero parser errors; not an iOS build", "diff": "passed", "ViewModel_SwiftUI_integration": "NOT_RUN: Apple SDK/Combine unavailable on Linux"}.
- Next action: Carry exact styled excerpt spans through explicit save requests, saved pages and guide references with backward-compatible optional persistence fields; then continue remaining requirements.
- Commit: containing commit for batch P1-semantic-streaming-prefixes.

## P3-styled-excerpt-persistence-and-deduplication

- Parent checkpoint: 16c7474d6fed2267c2342eedee1317e8b12160a6.
- Source-order requirements: [61, 109, 124, 125, 127, 128, 156, 157, 158, 159, 206, 207, 209, 210, 431, 432, 433, 434].
- Source files: Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Ask/Prompt09AskViewModel.swift, Fruitfolio/Ask/Prompt09SelectableAnswerText.swift, Fruitfolio/Ask/Prompt09ConversationPolicies.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift, Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- Native selection now captures exact semantic spans and actual rendered language, including when unavailable translation falls back to the English original. Optional backward-compatible page fields preserve excerpt style, language and occurrence through save/reopen/guide references. Fixed the destination's answer-only duplicate guard, which previously blocked every second excerpt from an answer; de-duplication now distinguishes full answers, exact known occurrences, text and language. Legacy unknown occurrences are not guessed. Display translation can target English from a non-English saved excerpt without overwriting the stored original. Translated structured emphasis still needs annotation round-trip work; Apple UI selection integration remains unrun.
- Tests added/updated: Prompt1BSavedExcerptPersistenceTests, Prompt1BTranslationPipelineTests/testNonEnglishSavedContentCanRequestEnglishTranslation.
- Verification: {"portable_swift": "31 XCTest + 21 Swift Testing passed (52 total)", "Swift_syntax": "zero parser errors; an out-of-scope UIKit binding update found during source review was corrected before commit", "diff": "passed", "SwiftUI_UIKit": "NOT_RUN: Xcode unavailable"}.
- Next action: Preserve semantic annotations through translated excerpt display, then finish unsaved-note protection, shared imported-image references, additional specification tracking and remaining requirements.
- Commit: containing commit for batch P3-styled-excerpt-persistence-and-deduplication.

## P3-translated-semantic-annotation-roundtrip

- Parent checkpoint: 81ddc131db501e12dec672708af423fc5092bdc3.
- Source-order requirements: [61, 109, 124, 125, 127, 128, 156, 157, 158, 159, 206, 207, 209, 210, 431, 432, 433, 434].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioSemanticModel.swift, Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift, Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift.
- Canonical semantic markup preserves explicit underline and combined emphasis through translated excerpt display. Literal Markdown syntax and underline tags are protected from translation. Stored original text and semantic spans remain unchanged. Portable serialization/protection checks pass; Foundation Markdown rendering round-trip tests require Apple SDK and remain unrun.
- Tests added/updated: Prompt1BSemanticSliceTests, Prompt1BSemanticTextTests.
- Verification: {"portable_swift": "32 XCTest + 21 Swift Testing passed (53 total)", "Apple_rendering": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Implement unsaved saved-page note protection, then shared image references and remaining requirements.
- Commit: containing commit for batch P3-translated-semantic-annotation-roundtrip.

## P3-unsaved-note-ownership

- Parent checkpoint: 5b3e4695301958f66fc97316aa36530b8cc62a0c.
- Source-order requirements: [125, 127, 128, 156, 157, 158, 159].
- Source files: Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift.
- Saved-page Back now offers save, discard or keep editing for dirty notes; failed saves retain the editor. Draft ownership prevents media redraws from replacing active notes. Saving re-reads persisted page fields to preserve concurrent attachments, and stores authored whitespace unchanged. Interactive sheet dismissal is disabled for dirty notes. Other app-level navigation and process termination recovery still require broader integration.
- Tests added/updated: Prompt1BSavedExcerptPersistenceTests/testNoteDraftSurvivesMediaRefreshAndResetsOnlyForAnotherPage.
- Verification: {"portable_swift": "33 XCTest + 21 Swift Testing passed (54 total)", "workflow": "9 Python tests passed", "Swift_syntax": "85 files, zero parser errors", "UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Preserve shared imported-image references in guides, remove synchronous body decoding and continue remaining source-order requirements.
- Commit: containing commit for batch P3-unsaved-note-ownership.

## P3-shared-local-media-snapshots

- Parent checkpoint: e3bfb984a74f55ac412b21374667a1471a5ffa30.
- Source-order requirements: [61, 66, 67, 125, 128, 156, 157, 158, 159, 206, 207, 209, 210].
- Source files: Fruitfolio/Saved Library/Prompt10ImportedImage.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift.
- Guide snapshots now copy imported image IDs and render them with the same local-image component as saved pages. Background file reads and bounded ImageIO thumbnail decoding replace synchronous decoding inside view body; load tasks cancel on disappearance/ID changes. Detaching an original image checks all saved books before deleting its file, preserving guide references. Reference persistence tests pass on Linux; actual ImageIO/SwiftUI decoding and guide-store integration remain unrun without Apple SDK. Whole-book deletion currently conservatively retains media files, pending verified orphan cleanup.
- Tests added/updated: Prompt1BSavedExcerptPersistenceTests/testImageRemainsReferencedAfterOriginalSnapshotDetachesIt, Prompt11GuideBuilderTests/testAddingSavedMaterialCreatesReferenceAndPreventsDuplicate.
- Verification: {"portable_swift": "34 XCTest + 21 Swift Testing passed (55 total)", "Swift_syntax": "87 files, zero parser errors", "Apple_integration": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Resume first independent Part 1 gap: measured shared character/bubble layout for Strawberry, Blueberry and Peach; continue remaining requirements.
- Commit: containing commit for batch P3-shared-local-media-snapshots.

## P1-measured-character-dialogue-layout

- Parent checkpoint: 3c5e592bf97280e089b9477186ce696cce8c9c5a.
- Source-order requirements: [13, 14, 15, 16, 18, 19, 20, 21, 22, 23, 24, 33, 34, 35, 36, 38, 40, 42, 64].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/Fruit Popup Engine/FruitPopupView.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift.
- Shared character metrics now use actual Strawberry/Blueberry/Peach canvas sizes and alpha>12 painted bounds rather than guessed optical offsets. Exact 497x499 speech-bubble aspect ratio is preserved. Width/height bounded dialogue metrics remove narrow-screen overflow and constrain the popup to the keyboard/safe-area viewport, with scrolling retained inside its writing area. Portable geometry tests cover three characters, long messages, small widths and constrained heights; asset dimensions are checked against bundled PNG headers. Tour reuses corrected art/shell primitives but its independent positioning still needs integration and device inspection.
- Tests added/updated: Prompt1BPopupLayoutTests, WorkflowIntegrityTests/test_dialogue_art_dimensions_match_bundled_pngs.
- Verification: {"portable_swift": "37 XCTest + 21 Swift Testing passed (58 total)", "workflow": "10 Python tests passed", "Swift_syntax": "87 files, zero parser errors", "UI": "NOT_RUN: Xcode unavailable"}.
- Next action: Complete shared semantic-intent policy and model formatting instructions; preserve science/source language through MADLAD localization, then remaining Part 1 and later requirements.
- Commit: containing commit for batch P1-measured-character-dialogue-layout.

## P1-canonical-semantic-policy-and-source-language

- Parent checkpoint: 9c19522a231528ba4d566fef491e9f8081728cd5.
- Source-order requirements: [46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioSemanticModel.swift, Fruitfolio/Core/DesignSystems/FruitfolioSemanticTextStyle.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Fruitfolio/Fruit Popup Engine/FruitPopupView.swift.
- Added one shared semantic author/model contract covering selective anchors, complete food names, spoken stress, practical/symptom underline, contextual combinations, density and serious tone without keyword-based discovery or quotas. Structured normalization restricts triple emphasis to exact canonical not/never/every vocabulary and supports serious-context vocal-stress removal while preserving text and IDs. Shared popup messages now use the canonical renderer, with cautionary tone applying serious normalization. Fixed synthesis to preserve an English validated/stored source for downstream MADLAD display localization instead of generating in the UI language and mislabeling it English. Model compliance, all-feature adoption, clinical quality and Apple rendering remain unverified; this is not full semantic-classification completion.
- Tests added/updated: Prompt1BSemanticSliceTests/testExtremeEmphasisRequiresCanonicalVocabularyAndSeriousTextDropsVocalStress, Prompt1BSemanticTextTests, Prompt56ResearchIntelligenceTests/testGeneratedDraftKeepsEvidenceLinkedClaim.
- Verification: {"portable_swift": "38 XCTest + 21 Swift Testing passed (59 total)", "Swift_syntax": "88 files, zero parser errors", "Apple_model_and_rendering_tests": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Route remaining educational/tour/fallback surfaces through canonical semantic rendering, remove duplicate feature-specific styling, then continue independent requirements.
- Commit: containing commit for batch P1-canonical-semantic-policy-and-source-language.

## P1-shared-education-rendering-and-accessible-tour

- Parent checkpoint: 6dd200f013f6d06b71b2dc00478900881a56e53a.
- Source-order requirements: [13, 14, 18, 19, 20, 21, 22, 23, 24, 26, 40, 42, 46, 47, 48, 49, 61, 62, 63, 64, 66, 67, 68, 70].
- Source files: Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/First-Launch Tour/Prompt07TourOverlay 2.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift, Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationViews.swift, Fruitfolio/Cycle Tracker/Genetics + Body + Lab/Prompt27ScienceViews.swift, Fruitfolio/Cycle Tracker/Fertilization/Prompt25FertilizationView.swift, Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift, Fruitfolio/Fruit Popup Engine/Prompt06PopupGallery.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- Routed tour dialogue, Fruit Basket explanations, selected hormone/pregnancy/fertilization/genetics educational bodies, privacy confirmation messages and original-answer guide popup through canonical semantic rendering. Eligible educational text now shares display-only translation and preserves source IDs where supplied. Original translation disclosures render semantic text instead of exposing raw markers. Removed feature-local tour attributed-string styling and text shrinking; tour uses shared viewport-bounded dialogue metrics with its own smaller artwork role, scrollable writing area and 44-point actions. Step/motion entrance tasks now cancel on replacement/disappearance. Added isolated DEBUG tour harness plus a full-step accessibility-size UI regression test, not executed on Linux. Remaining eligible surfaces and full localization still incomplete.
- Tests added/updated: Prompt1BPopupLayoutTests/testTourRetainsItsApprovedSmallerRoleAndViewportBounds, Prompt1BModalAccessibilityTests/testTourActionsRemainReachableAtAccessibilitySize.
- Verification: {"portable_swift": "39 XCTest + 21 Swift Testing passed (60 total)", "workflow": "10 Python tests passed", "Swift_syntax": "95 files, zero parser errors", "UI_and_ImageIO": "NOT_RUN: Xcode unavailable"}.
- Next action: Continue introduction requirements: verify logo-centered reveal geometry and lifecycle ownership, then remaining Part 2 and later requirements.
- Commit: containing commit for batch P1-shared-education-rendering-and-accessible-tour.

## P2-logo-registration-and-reduced-motion-sequence

- Parent checkpoint: 533638a5f45ba4ce53067147d7c2401ed606cf5f.
- Source-order requirements: [71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 83, 84, 85, 86, 87].
- Source files: Fruitfolio/Introduction/Prompt04LogoRevealGeometry.swift, Fruitfolio/Introduction/Prompt04IntroView.swift, Fruitfolio/Introduction/Prompt04IntroStateMachine.swift, Fruitfolio/Introduction/Prompt04IntroConfiguration.swift.
- Replaced three drifting pigment origins with a fixed logo/wordmark registration point on the original branded-cover canvas and an animatable pigment mask with smooth guaranteed final coverage. The selected registration point (335,321 in 644x795 artwork) is based on source-art visual inspection and still requires on-device/founder visual acceptance, not claimed pixel-perfect runtime verification. Reduce Motion previously skipped nearly all stages through a 550ms path while still inheriting camera/scale geometry. It now uses the same readable stage sequence/timing as normal first/returning launch, replacing pigment/scale/camera motion with stationary crossfades. Removed its special resume restart so the existing logical-stage recovery applies consistently. Portable reveal geometry tests pass; Apple sequencing, rendering, full aspect/texture handoff and interruption tests remain unrun.
- Tests added/updated: Prompt1BLogoRevealTests, Prompt04IntroTests/testReducedMotionFirstLaunchRetainsEveryImportantVisualStage, Prompt04IntroTests/testReducedMotionRemainsReducedAfterInterruption.
- Verification: {"portable_swift": "41 XCTest + 21 Swift Testing passed (62 total)", "Swift_syntax": "97 files, zero parser errors", "Apple_intro_sequence": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Verify and fix Hub/tour button interaction and spotlight geometry, then continue continuous Ask paper and remaining source-order requirements.
- Commit: containing commit for batch P2-logo-registration-and-reduced-motion-sequence.

## P2-immediate-shared-hub-controls-and-runtime-spotlights

- Parent checkpoint: 75383323dd0ac32093046bd27748a902d411c156.
- Source-order requirements: [9, 11, 12, 65, 66, 67, 68, 70, 88, 89, 92, 93, 94].
- Source files: Fruitfolio/Hub/Prompt04HubBridgeView.swift, Fruitfolio/First-Launch Tour/Prompt07SpotlightGeometry.swift, Fruitfolio/First-Launch Tour/Prompt07TourOverlay 2.swift.
- Removed duplicate Hub button animation styles and their 240ms delayed-navigation tasks; both primary and utility controls now use CutePopButtonStyle and invoke navigation immediately, retaining central duplicate-navigation protection and pop audio. Moved named Hub measurement space to the common ancestor of controls/overlay. Shared spotlight geometry now sanitizes measured frames, omits missing/offscreen targets and clips cutout/border consistently to the actual viewport. Hub branding work is owned by scene/interaction keyed tasks and honors cancellation rather than completing from unowned callbacks after disappearance/inactivity. Portable resize/edge/invalid geometry tests pass; real Hub touch latency, coordinate alignment and UI transitions still need Apple verification.
- Tests added/updated: Prompt1BSpotlightGeometryTests, Prompt1BModalAccessibilityTests/testTourActionsRemainReachableAtAccessibilitySize.
- Verification: {"portable_swift": "43 XCTest + 21 Swift Testing passed (64 total)", "workflow": "10 Python tests passed", "Swift_syntax": "99 files, zero parser errors", "Hub_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Implement genuinely continuous Ask paper with responsive runtime text/art columns and no bottom edge; continue Part 3 and remaining requirements.
- Commit: containing commit for batch P2-immediate-shared-hub-controls-and-runtime-spotlights.

## P3-continuous-session-paper-and-opening-art

- Parent checkpoint: a9b595775a52421fc1f29e435bd6371a8944a7ad.
- Source-order requirements: [96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 33, 34, 35, 36, 61, 63, 64, 66, 67].
- Source files: Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Ask/Prompt09ContinuousPaper.swift, Fruitfolio/Ask/Prompt09ConversationPolicies.swift, Fruitfolio/Ask/Prompt09AskViewModel.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- Replaced per-answer/discovery paper backgrounds with one extensible scroll-content background for the complete session. The paper stays centered with a runtime-bounded text column; native-source cap strips preserve top/bottom artwork while the middle extends vertically and the bottom edge continues beyond content. Existing native selection, source actions, ordered history and near-bottom auto-follow remain connected. The opening card now remains part of the session, with one reserved art row; pear/orange slice/glow occupy equal runtime columns, orange centered, with measured visible-alpha optical centering and preserved native proportions instead of negative fixed offsets. Added isolated DEBUG two-long-answer fixture plus scroll/backtracking/horizontal-bound UI regression, unrun on Linux. Portable geometry and actual PNG metadata checks pass. Real paper texture transitions, bottom-edge behavior, Dynamic Type, gestures and text accessibility need Apple runtime verification; source edits are not accepted as runtime proof.
- Tests added/updated: Prompt1BAskPaperLayoutTests, WorkflowIntegrityTests/test_ask_paper_and_opening_fruit_dimensions_match_source_pngs, Prompt1BModalAccessibilityTests/testLongAskSessionKeepsBothQuestionsReachableWithinTheViewport.
- Verification: {"portable_swift": "46 XCTest + 21 Swift Testing passed (67 total)", "workflow": "11 Python tests passed", "Swift_syntax": "101 files, zero parser errors", "Ask_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Continue Ask lifecycle, citation/save and language handling requirements in source order; add supplemental-spec coverage tracker and remaining independent features.
- Commit: containing commit for batch P3-continuous-session-paper-and-opening-art.

## P3-measured-Ask-help-and-owned-typing-audio

- Parent checkpoint: 21ed84fb8da11a4c51fa8b317ec7b7aebf16f038.
- Source-order requirements: [13, 15, 16, 17, 18, 19, 20, 21, 23, 24, 26, 27, 46, 48, 138, 166, 167].
- Source files: Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Core/Assets/AudioManager.swift, Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/Core/DesignSystems/FruitfolioTapedWhitePopup.swift.
- Replaced the small Ask help tooltip with the founder-specified taped-white post-it artwork, Blueberry and concise session/research/save guidance. Measured 662x647 artwork retains its proportions and a tape-free scrollable writing region. Help now isolates both conversation and input with canonical modal blur/dimming, opens/closes with popup audio and has a reachable close action. Answer presentation owns typing ASMR loop intent; phase completion, inactivity, settings mute/disable and disappearance remove that intent. AudioManager now reconciles ASMR loops as well as one-shots when settings change and restores a still-owned loop after an audio interruption. Portable popup bounds pass; actual ASMR playback/mute regression and full help accessibility UI test are added but unrun without Apple SDK.
- Tests added/updated: Prompt1BPopupLayoutTests/testTapedWhitePopupPreservesArtworkAndTapeFreeWritingArea, Prompt1BAudioSettingsTests/testOwnedTypingLoopHonorsMuteToggleAndCanBeForgotten, Prompt1BModalAccessibilityTests/testAskHelpIsAScrollableModalAndRestoresConversationOnClose.
- Verification: {"portable_swift": "47 XCTest + 21 Swift Testing passed (68 total)", "Swift_syntax": "102 files, zero parser errors", "Audio_and_help_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Enforce default-no-illustration and one-major-visual Ask behavior; finish verified citation controls, source-grounded voice and remaining requirements.
- Commit: containing commit for batch P3-measured-Ask-help-and-owned-typing-audio.

## P3-default-text-only-and-single-educational-art

- Parent checkpoint: 221dbbbb5899f97e0170e0adf4d1201f7fee972f.
- Source-order requirements: [139, 140, 142, 143, 144, 145, 146, 147].
- Source files: Fruitfolio/Ask/Prompt09AskModels.swift, Fruitfolio/Ask/Prompt09AnswerSupport.swift, Fruitfolio/Ask/Prompt09EducationalAssetRouter.swift, Fruitfolio/Ask/Prompt09AskViewModel.swift, Fruitfolio/Ask/Prompt09AskView.swift.
- Ordinary Ask now defaults to no visible educational illustration. The evidence-gated router offers at most one candidate and requires fully supported content plus matching topic and specific concept; raw prose keywords do not directly display art. The user must explicitly open an educational illustration. Partial/unsupported answers offer no candidate, and high requested counts cannot create a collage. Existing 44 illustrations and resources are preserved; explicit sequential science modules remain separate. Removed viewport-relative minimum image width that could exceed a narrow paper text column. Pure router tests pass; ViewModel/user-action and actual illustration layout remain unrun on Apple.
- Tests added/updated: Prompt1BEducationalArtworkTests, Prompt1BAskLifecycleTests/testIllustrationIsNotDisplayedUntilExplicitEducationalAction.
- Verification: {"portable_swift": "49 XCTest + 21 Swift Testing passed (70 total)", "workflow": "11 Python tests passed", "Swift_syntax": "106 files, zero parser errors", "Apple_illustration_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Add functional links and preserved identifiers to verified citation records, then continue source-grounded voice and remaining requirements.
- Commit: containing commit for batch P3-default-text-only-and-single-educational-art.

## P3-persisted-citation-records-and-source-actions

- Parent checkpoint: 2f26f8ed07a871103dab3b9b3367f0a2ba358d03.
- Source-order requirements: [61, 109, 125, 141, 161, 162, 163, 206, 207, 209, 210, 431, 432, 433, 434].
- Source files: Fruitfolio/Ask/Prompt09AskModels.swift, Fruitfolio/Ask/Prompt09AnswerSupport.swift, Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Core/DesignSystems/FruitfolioSourceCitationList.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift.
- Added backward-compatible optional citation records to saved pages and pending-save payloads. Ask full/excerpt/historical saves and guide snapshots now retain exact original titles, APA reference text, publication details, IDs, DOI/URL and content versions beyond the Ask session. Shared source rendering displays original metadata verbatim and provides explicit source-open actions plus visible failure handling. Destinations use only supplied credential-free HTTPS addresses or syntactically valid DOI resolver paths; no invented search links or source metadata. Legacy records keep their original IDs fallback. Portable persistence and URL/DOI tests pass, including reserved suffix characters and invalid schemes; Apple UI/openURL and guide-store integration remain unrun. Network reachability and source-content approval are not inferred from URL parsing.
- Tests added/updated: Prompt1BCitationDestinationTests, Prompt1BSavedExcerptPersistenceTests, Prompt11GuideBuilderTests/testAddingSavedMaterialCreatesReferenceAndPreventsDuplicate.
- Verification: {"portable_swift": "51 XCTest + 21 Swift Testing passed (72 total)", "workflow": "11 Python tests passed", "Swift_syntax": "108 files, zero parser errors", "Apple_citation_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Restrict excerpt saves to explicit selected payloads, support optional scientific-image saves and supplemental founder requirements; continue canonical voice and original source-order backlog.
- Commit: containing commit for batch P3-persisted-citation-records-and-source-actions.

## P3-selected-save-payload-privacy

- Parent checkpoint: 069c4e59c9eda7aa355a7c4f6bd4aa19355c11e7.
- Source-order requirements: [118, 119, 120, 121, 122, 123, 124, 125, 126, 128].
- Source files: Fruitfolio/Saved Library/Prompt10PendingSavedContent.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift.
- New excerpt-save payloads retain only explicitly selected text, not the unsaved full answer that was previously copied alongside it. Exact answer/conversation identifiers and citation metadata remain available for attribution. Full answer text persists only when the full-answer save type is explicitly selected. The original-answer popup now identifies excerpt content and displays the selected body with its semantic/language metadata. Existing saved records were preserved, not silently migrated or deleted; legacy excerpt records may still contain the earlier full-answer field until explicitly erased by their owner. Payload privacy tests pass on Linux; Apple save/cancel navigation and persistence integration remain unrun.
- Tests added/updated: Prompt1BPendingSavePrivacyTests.
- Verification: {"portable_swift": "53 XCTest + 21 Swift Testing passed (74 total)", "Swift_syntax": "110 files, zero parser errors", "Apple_save_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Implement explicit scientific-illustration save selection and optional text/image combinations, index supplemental founder additions, then remaining source-order requirements.
- Commit: containing commit for batch P3-selected-save-payload-privacy.

## P3-explicit-scientific-illustration-save-payloads

- Parent checkpoint: 79b7e27c079f1ada790304ad7fa00168a6e10389.
- Source-order requirements: [61, 109, 124, 125, 126, 127, 128, 142, 143, 145, 147, 206, 207, 209, 210].
- Source files: Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Ask/Prompt09ConversationPolicies.swift, Fruitfolio/Core/DesignSystems/FruitfolioSavedScientificIllustrations.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10PendingSavedContent.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift.
- Implemented founder 3G/3I image-save choices in addition to the numbered checklist: opened canonical scientific art can be saved alone or explicitly included with selected text/full-answer saves. Default text saves omit images. Optional canonical image IDs persist with citation records, copy into guide snapshots and render on reopening; image-only saves retain no unsaved answer text. Opened art remains associated with its earlier answer during the active session. Excerpt save identity/de-duplication distinguishes illustrated and text-only payloads and recognizes repeated image-only saves. Existing records decode without the optional field. Whole-answer session badges still represent the answer-level save rather than each image variant; the independent image-only action remains available. Native selection/save UI and guide integration need Apple execution.
- Tests added/updated: Prompt1BPendingSavePrivacyTests/testImageOnlyAndTextWithImageRetainExactlyTheChosenContent, Prompt1BSavedExcerptPersistenceTests/testScientificImageSelectionPersistsWithoutUnsavedAnswerAndDistinguishesSaveVariants, Prompt1BExcerptIdentityTests/testOptionalIllustrationSelectionHasItsOwnSaveBadge, Prompt11GuideBuilderTests/testAddingSavedMaterialCreatesReferenceAndPreventsDuplicate.
- Verification: {"portable_swift": "56 XCTest + 21 Swift Testing passed (77 total)", "workflow": "11 Python tests passed", "Swift_syntax": "111 files, zero parser errors", "Apple_selection_and_save_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Protect library persistence from failed saves/corrupt loads, index supplemental founder requirements, then continue original source-order backlog.
- Commit: containing commit for batch P3-explicit-scientific-illustration-save-payloads.

## P4-library-commit-rollback-and-corruption-protection

- Parent checkpoint: 4afefc67b102dde2755d185902c7661ee56ed0ad.
- Source-order requirements: [119, 124, 125, 126, 127, 128, 198, 199, 200, 201, 202, 206, 207, 209, 210].
- Source files: Fruitfolio/Saved Library/Prompt10SavedLibraryPersistence.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift.
- Added a shared Foundation persistence snapshot for the existing library. Candidates encode successfully before the stored bytes/committed snapshot change; Store.persist rolls published mutations back on failure, so failed saves/media attachments do not linger as successful in-memory copies. Malformed JSON and wrong-type stored originals now remain untouched and read-only rather than being silently replaced by an empty library. Library, Guide home and Ask save destination show a recovery notice and suppress empty-state creation paths when storage is unreadable. Portable tests verify original bytes, snapshot rollback, reinitialization and wrong-type protection. UserDefaults.set still does not expose filesystem flush errors; actual app-restart durability and UI recovery require Apple testing. No user data was erased or migrated.
- Tests added/updated: Prompt1BLibraryPersistenceTests, Prompt10SavedLibraryTests/testFailedPageSaveRollsBackPublishedLibraryAndPreservesPriorBytes.
- Verification: {"portable_swift": "58 XCTest + 21 Swift Testing passed (79 total)", "workflow": "11 Python tests passed", "Swift_syntax": "115 files, zero parser errors", "Apple_store_UI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Index supplemental founder requirements without changing original 478 entries; continue retrieval/generation performance and canonical voice, then library requirements.
- Commit: containing commit for batch P4-library-commit-rollback-and-corruption-protection.

## workflow-exact-supplemental-founder-spec-index

- Parent checkpoint: d887ef16eb3bd9d1a2866e2d98d98b5972fe7c96.
- Source-order requirements: [].
- Source files: Tools/sync_supplemental_spec.py, development_workflow/SUPPLEMENTAL_SPEC_CHECKLIST.json, development_workflow/RECOVERY_PROTOCOL.md, development_workflow/BLOCKERS.md.
- Created a separate persistent index for all 24 numbered hormone/MADLAD additions plus 12 explicit binding founder additions, preserving exact source text, IDs, line locations and SHA-256. Original 478 labels/descriptions/sequences remain unchanged. Seeded conservative partial evidence and exact blockers, never acceptance completion. Added a lossless regeneration/check tool and recovery instructions. Corrected the extraction encoding note: the original contains a small number of undecodable legacy bytes, now read with surrogateescape without rewriting the source. Remaining unnumbered founder paragraphs are explicitly not yet fully reconciled. No application/source verification is inferred from this indexing batch.
- Tests added/updated: WorkflowIntegrityTests/test_supplemental_additions_preserve_exact_source_and_do_not_replace_478.
- Verification: {"supplemental": "36 exact additions indexed; original 478 unchanged", "workflow": "12 Python tests passed", "application": "No application changes in this indexing-only batch; next implementation starts immediately"}.
- Next action: Continue retrieval/generation performance and canonical normal/fallback voice, then library requirements; consult both persistent trackers and continue implementation batches.
- Commit: containing commit for batch workflow-exact-supplemental-founder-spec-index.

## P3-static-research-token-index-and-approved-source-gate

- Parent checkpoint: 67ea452f3f61f2a281d7549c857242a7f8677107.
- Source-order requirements: [65, 66, 67, 68, 129, 130, 131, 132, 133, 134, 135, 136, 137, 161, 163, 164, 165].
- Source files: Fruitfolio/Core/Intelligence/FruitfolioResearchRetrieval.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift.
- Extracted existing Foundation research models/retrieval into a reusable source file and pre-indexed static heading/body tokens and lowercased text once per package/locale, eliminating repeated full-corpus tokenization and per-chunk query normalization. Package actor caches only this static index; no user question/transcript cache is introduced. Indexing and rank searches now execute on that actor instead of the main actor; source expansion remains sequential because it depends on note-linked source IDs and coverage. Added cancellation checks around actor work and guards for nonpositive limits. Source indexes now exclude unapproved/unresolved/missing source records even when an expansion search has no restricted IDs. Golden ranking/coverage and approval-boundary tests pass. No device speed claim is made. Inspection also found the runtime expects FruitfolioResearchPackage.json but no generated package/compiler is present; the original approved DOCX/PDF are intact. Next batch must create a reproducible strict local package from those resources without fabricating claims or citations.
- Tests added/updated: Prompt1BResearchRetrievalTests.
- Verification: {"portable_swift": "60 XCTest + 21 Swift Testing passed (81 total)", "workflow": "12 Python tests passed", "Swift_syntax": "117 files, zero parser errors", "Apple_retrieval_UI": "NOT_RUN: Apple SDK unavailable", "research_resource": "Missing generated package identified; preserved source DOCX 1090803 bytes, PDF 70763509 bytes; implementation continues"}.
- Next action: Compile and validate the missing local research package from preserved founder DOCX/PDF with exact text/provenance, connect runtime loading, then canonical normal/fallback voice and remaining requirements.
- Commit: containing commit for batch P3-static-research-token-index-and-approved-source-gate.

## P3-reproducible-founder-research-package

- Parent checkpoint: 35ba5a5292739042506b2840bb3cdfc073af5665.
- Source-order requirements: [129, 133, 136, 137, 148, 149, 150, 161, 162, 163, 164, 165, 431, 432, 433, 434].
- Source files: Tools/compile_research_package.py, Fruitfolio/FruitfolioResearchPackage.json, Fruitfolio/Core/Intelligence/FruitfolioResearchRetrieval.swift, development_workflow/RESEARCH_PACKAGE_REPORT.json.
- Resolved the missing local package resource by compiling the preserved founder DOCX into exact, reproducible paragraph slices with original reference metadata and per-chunk provenance. Retained 4458 note chunks; 2722 are retrievable, with 144 topic groups explicitly quarantined for missing/ambiguous references or binding LifeBridge review. Quarantined notes cannot enter the Swift index. 715 APA-style metadata records retain original text and founderCorpusAPA7 attribution without claiming independent verification. No source text, clinical claim, author/date/DOI or full-source expansion is invented; full-source chunks remain empty. Original DOCX/PDF bytes are unchanged. Actual Swift decoded/searched the complete generated package; source-language/clinical interpretation and Xcode bundle inclusion remain external verification work. Latest Linux index sample 1.259s, 50 cached searches 1.284s; not an iPhone benchmark.
- Tests added/updated: ResearchCompilationTests, Prompt1BResearchPackageTests, Prompt56ResearchIntelligenceTests/testCompiledResearchPackageIsIncludedInTheApplicationBundle.
- Verification: {"portable_swift": "62 XCTest + 21 Swift Testing passed (83 total)", "workflow": "15 Python tests passed", "Swift_syntax": "118 files, zero parser errors", "resource_provenance": "Generated package and report reproducible; original source asset hashes preserved", "Apple_integrated_AI": "NOT_RUN: Xcode unavailable"}.
- Next action: Strengthen source-backed generated-claim/bridge validation and unify canonical normal/fallback voice, then continue library and remaining requirements.
- Commit: containing commit for batch P3-reproducible-founder-research-package.

## P3-complete-evidence-context-and-shared-canonical-voice

- Parent checkpoint: 9436aee1c0ddb87fbcbbc34bf1fc5fd3d1e40f9f.
- Source-order requirements: [46, 47, 48, 49, 50, 53, 54, 55, 56, 57, 58, 59, 61, 62, 63, 136, 137, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 164].
- Source files: Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchRetrieval.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceModels.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift, Fruitfolio/Core/Intelligence/FruitfolioHealthSafety.swift, Fruitfolio/Core/Intelligence/FruitfolioCanonicalVoice.swift, Fruitfolio/Core/ProductionPhases/Prompt32To55ProductionSystems.swift, Tools/compile_research_package.py, Fruitfolio/FruitfolioResearchPackage.json.
- Restored complete original paragraphs from a deduplicated provenance table before evidence mapping/synthesis/fallback, replacing unsafe mid-paragraph slices and 680-character presentation clipping. Generated facts now require exact complete-evidence preservation with only validated canonical styling; a shared word is no longer treated as medical entailment. This deliberately uses a conservative source-copy boundary until a validated paraphrase verifier exists. Arbitrary model bridge/limitation fields can no longer introduce uncited medical prose. One canonical voice contract/framing now serves generated and retrieval-only responses, with human bridge, main-point stars, bounded partial-support disclosure and urgent guidance only for urgent classifications. Corrected kaomoji policy maximum 4→3 and normal preference 0–1. Literal scientific operators are escaped for safe rendering, preserving dose, unit case and negative/qualifying language. Source clinical truth/relevance, complete source-authored kaomoji handling and full stylistic acceptance are not claimed verified. Pure shipping validation code and actual package context restoration execute on Linux; Apple UI/integrated AI remains unrun.
- Tests added/updated: Prompt1BEvidenceBoundaryTests, Prompt1BResearchPackageTests/testRankingRestoresWholeParagraphsBeforeScientificPresentation, ResearchCompilationTests.
- Verification: {"portable_swift": "67 XCTest + 21 Swift Testing passed (88 total)", "workflow": "15 Python tests passed", "Swift_syntax": "124 files, zero parser errors", "Apple_full_AI": "NOT_RUN: Apple SDK unavailable"}.
- Next action: Compile and run the full Foundation research engine headlessly, verify normal/failure/urgent boundaries, then connect remaining grounded feature providers and continue source-order requirements.
- Commit: containing commit for batch P3-complete-evidence-context-and-shared-canonical-voice.

## P3-real-Swift-native-inference-and-headless-engine

- Parent checkpoint: 5274726f31b17f5b47479c2fe22c9836d807c3c5.
- Source-order requirements: [65, 66, 67, 68, 118, 119, 120, 121, 122, 123, 129, 130, 131, 133, 134, 135, 136, 137, 148, 149, 150, 151, 152, 153, 158, 159, 160, 161, 162, 163, 164, 165, 431, 432, 433, 434].
- Source files: Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift, Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Fruitfolio/Ask/Prompt09AskModels.swift, Tools/run_portable_swift_tests.py.
- Expanded headless compilation to the actual production research engine and added injectable local resource URLs for tests. Fixed real Swift concurrency errors in the model protocol/actor initializer and main-actor progress callback contract. Added local urgent guidance before package/model loading, preserving no-diagnosis/no-fabricated-citation behavior. Linked the actual native Swift inference branches to exact vendor CPU libraries and the real Qwen GGUF. The first native run genuinely failed invalidOutput; request-scoped evidence-bound JSON grammar fixed it. Native generation now passes both structured production validation and quoted Unicode/scientific-unit preservation tests. Added token-step cancellation, explicit output-limit/UTF-8 rejection, request-scoped sampler cleanup and decoder KV cleanup. Actual headless engine fallback/citation and searched-unsupported tests pass against the real compiled founder corpus. Qwen fixture inference is verified on Linux, not full-corpus native synthesis or Apple runtime. MADLAD code compiles/links, but no T5 inference/quality/device claim is made without its blocked official weights.
- Tests added/updated: Prompt1BResearchEngineIntegrationTests, Prompt56ResearchIntelligenceTests/testNativeGGUFProducesStructuredDraftWithoutFallback, Prompt1BEvidenceBoundaryTests/testNativeConstrainedDraftPreservesQuotedUnicodeUnitsAndExactEvidenceID.
- Verification: {"Swift_6_headless": "78 XCTest + 21 Swift Testing passed (99 total)", "Swift_5_real_native": "80 XCTest + 21 Swift Testing passed (101 total), including real Qwen structured generation and Unicode/units/evidence validation", "workflow": "15 Python tests passed", "Swift_syntax": "125 files, zero parser errors", "Apple_and_MADLAD_inference": "NOT_RUN: Apple SDK/official MADLAD weights unavailable"}.
- Next action: Budget complete retrieved paragraphs for real native context/output capacity and verify full-corpus native engine behavior, then grounded feature-provider fallbacks and remaining source-order requirements.
- Commit: containing commit for batch P3-real-Swift-native-inference-and-headless-engine.

## P3-native-whole-paragraph-token-budgets

- Parent checkpoint: 1f4b7b05d41e415757124e3302bdde2fe873b9a1.
- Source-order requirements: [65, 66, 67, 68, 129, 130, 131, 133, 134, 135, 136, 137, 148, 149, 150, 153, 161, 162, 163, 164, 165].
- Source files: Fruitfolio/Core/Intelligence/FruitfolioEvidenceBudget.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Fruitfolio/Ask/Prompt09AskModels.swift, Fruitfolio/Ask/Prompt09AnswerSupport.swift.
- Added native-tokenizer admission for complete source paragraphs under actual context and output limits. Oversized paragraphs are omitted without cutting qualifiers or changing source text, and claim/evidence maps are restricted to admitted IDs. Grammar claim count uses conservative worst-alternative output costs. Added optional in-memory answer-path provenance so generation tests cannot pass by silently falling back. Cancellation now propagates through the engine rather than creating a fallback after cancellation. The actual full research engine, actual compiled founder corpus and real Qwen model passed a generated-path/citation assertion in 30.335 seconds on Linux CPU. This verifies functioning bounded inference but remains a latency concern; redundant autoregressive copying is the next optimization candidate. Apple runtime, clinical interpretation and MADLAD resources/inference remain unverified.
- Tests added/updated: Prompt1BEvidenceBudgetTests, Prompt1BResearchEngineIntegrationTests/testNativeModelAnswersFromActualCorpusWithinWholeParagraphBudgets.
- Verification: {"Swift_6_headless": "81 XCTest + 21 Swift Testing passed (102 total)", "Swift_5_native": "84 XCTest + 21 Swift Testing passed (105 total); real full-corpus engine path generated, 30.335 seconds", "Swift_syntax": "127 files, zero parser errors", "Apple_and_MADLAD": "NOT_RUN: Apple SDK/official MADLAD weights unavailable"}.
- Next action: Strengthen MADLAD scientific quantity protection for signs, comparisons and unsupported unit forms, then optimize redundant native evidence copying and continue grounded feature providers/source-order backlog.
- Commit: containing commit for batch P3-native-whole-paragraph-token-budgets.

## MADLAD-signed-quantities-units-and-reference-protection

- Parent checkpoint: 7e11028ccdf5dd8322b8f0bfb1c9a0cea5cb64df.
- Source-order requirements: [136, 418, 419, 420, 421, 422, 423, 424, 425, 426, 431, 432, 433, 434].
- Source files: Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- Fixed a clinical translation-protection gap: leading signs/comparators and units outside the old limited numeric regex could remain unprotected. Complete signed/comparison quantities, ratios/ranges/uncertainties, scientific powers, broader laboratory units and invariant labels are now protected atomically without interpreting/converting values. Post-restoration signatures also reject added unit/numeric claims and introduced structured references/URLs. Tests preserve escaped Markdown operators and avoid misclassifying ordinary translated contractions/words as bare units. All feasible protection/native regressions pass. These checks cannot prove non-numerical medical meaning or real language quality; official MADLAD weights/T5 inference and clinical review remain blocked/unrun.
- Tests added/updated: Prompt1BScientificTranslationTests.
- Verification: {"Swift_6_headless": "85 XCTest + 21 Swift Testing passed (106 total)", "Swift_5_native": "88 XCTest + 21 Swift Testing passed (109 total)", "workflow": "15 Python tests passed", "Swift_syntax": "128 files, zero parser errors", "MADLAD_inference": "NOT_RUN: official weights/tokenizer blocked; no translation-quality claim"}.
- Next action: Reduce measured native generation latency by selecting permitted evidence IDs and reconstructing exact paragraphs deterministically; verify actual corpus-backed generated path, then remaining feature providers and original backlog.
- Commit: containing commit for batch MADLAD-signed-quantities-units-and-reference-protection.

## Ask-compact-native-evidence-selection-and-exact-attribution

- Parent checkpoint: fcab0855be793a0f695b54f9b99ee3542d83cef7.
- Source-order requirements: [130, 131, 132, 133, 134, 135, 136, 137, 161, 162].
- Source files: Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift, Fruitfolio/Core/DesignSystems/FruitfolioSourceCitationList.swift.
- Native generation now selects grammar-constrained permitted evidence IDs; deterministic reconstruction preserves complete scientific paragraphs without autoregressive copying. Unknown/unpermitted/excessive selections fail, duplicates deduplicate, injected text cannot become evidence. Sources now reflect only paragraphs actually presented; empty source lists do not render a misleading footer. Actual Qwen plus actual corpus generated path passed in 10.572 seconds versus recorded 30.335-second baseline on Linux CPU. This is evidence selection, not validated clinical paraphrase or an Apple/device performance claim.
- Tests added/updated: Prompt1BEvidenceBoundaryTests, Prompt1BEvidenceBudgetTests, Prompt1BResearchEngineIntegrationTests.
- Verification: {"Swift_6_headless": "88 XCTest + 21 Swift Testing passed (109 total)", "Swift_5_native": "91 XCTest + 21 Swift Testing passed (112 total)", "workflow": "15 Python tests passed", "Swift_syntax": "128 files, zero parser errors", "native_corpus_generated": "10.572s Linux CPU; generated path asserted, not fallback", "Apple_UI_and_MADLAD": "NOT_RUN; existing blockers remain"}.
- Next action: Implement original source-order library requirements 168 onward: save transition treatment, canonical identical decorative shelf, accessible sorting, title/description validation; continue remaining original backlog.
- Commit: containing commit for batch Ask-compact-native-evidence-selection-and-exact-attribution.

## Library-canonical-shelf-and-accessible-sorting

- Parent checkpoint: 6423ddf1803f2056b389d13bc18e76f80bd465fa.
- Source-order requirements: [170, 171, 172, 173, 174, 175].
- Source files: Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift.
- Removed the populated-only duplicate book stack and plant from the shared decorative hero, so saved and empty libraries use the same unchanged decorative composition and keep actual books in the separate collection. Applied exact founder empty-state wording. Search/sort are available from the first saved encyclopedia rather than hidden below thirteen books; sort announces its current value, expansion state and selected option. Decorative shelf is hidden from accessibility. Source syntax verified; Apple UI compilation, VoiceOver and screenshot comparison are not available on Linux.
- Tests added/updated: .
- Verification: {"Swift_syntax": "128 files, zero parser errors", "diff": "passed", "Apple_UI": "NOT_RUN: Apple SDK absent; VoiceOver and visual acceptance remain open"}.
- Next action: Add shared grapheme-counted title/description validation with clear limits and bounded non-explicit rules that preserve legitimate sexual-health terminology, then continuous coded book transition requirements.
- Commit: containing commit for batch Library-canonical-shelf-and-accessible-sorting.

## Library-label-limits-clinical-language-and-description-layout

- Parent checkpoint: 3bd75ceab3f2037fc1e8808158b3d7ed6a268db1.
- Source-order requirements: [176, 177, 178, 179, 180, 181].
- Source files: Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryComponents.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift.
- Shared save-boundary validation enforces 48-grapheme titles and 160-grapheme descriptions without silently truncating; creation, renaming and guide descriptions use the same policy. Visible counts and accessibility guidance accompany main editing fields. Whole-word normalized profanity and explicit-threat checks preserve legitimate sexual-health, trauma, consent and clinical labels; this bounded English filter is not comprehensive multilingual moderation. Regression caught format-character filtering incorrectly rejecting joined emoji; corrected to actual control characters. Description now appears below the library book with independent spacing. Existing records and scientific evidence are not rewritten. Apple layout/typechecking remains unrun.
- Tests added/updated: Prompt1BBookLabelTests.
- Verification: {"Swift_6_headless": "91 XCTest + 21 Swift Testing passed (112 total)", "Swift_5_native": "94 XCTest + 21 Swift Testing passed (115 total)", "workflow": "15 Python tests passed", "Swift_syntax": "129 files, zero parser errors", "Apple_UI": "NOT_RUN; layout/VoiceOver acceptance open", "content_filter": "Bounded English whole-word/threat policy; multilingual review remains open"}.
- Next action: Replace staged artwork-swap book opening with continuous coded book geometry that persists into the inside-book content; preserve selected color, Reduce Motion, cancellation and bounded page layout.
- Commit: containing commit for batch Library-label-limits-clinical-language-and-description-layout.

## Library-continuous-owned-book-surface

- Parent checkpoint: 7c936fc50b32d78d58482135d22f484a52bd631c.
- Source-order requirements: [182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196].
- Source files: Fruitfolio/Saved Library/Prompt10BookMotion.swift, Fruitfolio/Saved Library/Prompt10ContinuousBook.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift.
- Replaced spine/front/closed/open image swapping and unowned delayed callbacks with a single coded surface used on shelf and retained through movement, reveal, continuous opening and complete-book settling into the reading view. Captured actual shelf frame, preserved selected style color, centered before opening, kept content in left/right book regions, removed duplicate small open-book and bottom bookmark/flower decorations. One owned task cancels stale transitions on departure/inactive scene; Reduce Motion uses the final book without travel/rotation. Pure tests verify continuity and whole-book bounds. Added disposable production-view UI harness and Mac test, NOT_RUN on Linux. Watercolor visual fidelity, iOS typecheck, screenshots, touch/VoiceOver, dynamic type and visual continuity remain unverified and requirements remain IN_PROGRESS.
- Tests added/updated: Prompt1BBookMotionTests, Prompt1BModalAccessibilityTests.testSelectedBookRemainsBoundedAndReturnsToShelf.
- Verification: {"Swift_6_headless": "93 XCTest + 21 Swift Testing passed (114 total)", "Swift_5_native": "96 XCTest + 21 Swift Testing passed (117 total)", "workflow": "15 Python tests passed", "Swift_syntax": "132 files, zero parser errors", "Apple_UI": "NOT_RUN: new book harness/test ready; visual and accessibility acceptance remain open"}.
- Next action: Implement independent user-authored research/material pages with editable notes, provenance and chapter selection, preserving unsaved edits; then remaining guide synchronization and source-order requirements.
- Commit: containing commit for batch Library-continuous-owned-book-surface.

## Library-user-material-provenance-editing-and-image-replacement

- Parent checkpoint: 3c159b1d327930cabda37870777f11c27c3ee88b.
- Source-order requirements: [197, 198, 199, 200, 201, 202, 203, 204, 205].
- Source files: Fruitfolio/Saved Library/Prompt10UserMaterial.swift, Fruitfolio/Saved Library/Prompt10UserMaterialEditor.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift.
- Added user-authored page creation/editing with chosen chapter, exact user body/notes, optional validated user-supplied address, explicit unverified-material provenance, save/cancel/discard dialog and error-retained drafts. Ask evidence cannot be overwritten through this editor. Updates preserve page identity, creation date and imported images, support moving to another chapter, and commit through existing rollback persistence. Guide snapshots retain user-material metadata. Existing image import now supports ordered atomic replacement with per-image picker ownership and stale-target rejection; detach refreshes UI before best-effort shared-reference-safe file cleanup. Clean note drafts refresh persisted editor changes without replacing dirty drafts. No generative images. User page editor requires an existing chapter; existing guide section creation supplies this. Global navigation/process-death recovery and Apple runtime validation remain open.
- Tests added/updated: Prompt1BUserMaterialTests, Prompt1BModalAccessibilityTests.testOwnMaterialSavesIntoChosenBookWithoutBecomingVerifiedResearch.
- Verification: {"Swift_6_headless": "99 XCTest + 21 Swift Testing passed (120 total)", "Swift_5_native": "102 XCTest + 21 Swift Testing passed (123 total)", "workflow": "15 Python tests passed", "Swift_syntax": "135 files, zero parser errors", "Apple_UI": "NOT_RUN: own-material UI regression added; Photos/VoiceOver/draft navigation acceptance open"}.
- Next action: Unify guide catalog visibility across Ask-created books, Saved Library and Guide Builder without cloning feature records; preserve original-page provenance and avoid self-copy candidates, then exact Guide Builder copy/art requirements.
- Commit: containing commit for batch Library-user-material-provenance-editing-and-image-replacement.

## Guides-shared-catalog-and-original-source-identity

- Parent checkpoint: db4651807dbcfb1562d80011d61f95b62a180b54.
- Source-order requirements: [206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217].
- Source files: Fruitfolio/Saved Library/Prompt10SharedLibraryCatalog.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderStoreBridge.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift.
- Guide Builder now projects all existing shared book records, including legacy Ask/library-created books, without a separate feature copy or flag-based visibility exclusion. Original-page lookup never substitutes a retained guide snapshot for a deleted original. Candidate dedup includes own-page IDs, and duplicate insertion returns the actual existing target page. Exact founder shelf/section text applied; selected guide no longer layers the initial-state folder. User material remains labeled unverified in shared guide reading paper. Added pure real-model catalog/provenance regression tests and a production-view cross-entry rename UI test (not run on Linux). Existing shared persistence and popup system retained; full Apple observation, deletion/recolor synchronization, sorting/accessibility acceptance remain unverified.
- Tests added/updated: Prompt1BSharedLibraryCatalogTests, Prompt1BModalAccessibilityTests.testLibraryCreatedBookIsSameGuideAndRenamePropagatesBack.
- Verification: {"Swift_6_headless": "101 XCTest + 21 Swift Testing passed (122 total)", "Swift_5_native": "104 XCTest + 21 Swift Testing passed (125 total)", "workflow": "15 Python tests passed", "Swift_syntax": "138 files, zero parser errors", "Apple_UI": "NOT_RUN: cross-entry rename, selected folder and popup acceptance await Apple runtime"}.
- Next action: Continue audio/Account source-order requirements; existing audio implementation needs Apple runtime checks, then harden shared pseudonymous username editing and non-identifying validation without pretending local names are globally reserved.
- Commit: containing commit for batch Guides-shared-catalog-and-original-source-identity.

## Account-shared-pseudonym-drafts-and-identity-guards

- Parent checkpoint: 01f901ccb8c0f41ce25a407d799821ba06d241e1.
- Source-order requirements: [229, 230, 231, 232, 233, 234].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioPseudonymPolicy.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernamePersistence.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift.
- Account and Fruit Basket retain one local username authority. Fruit Basket now edits an explicit draft/save instead of persisting each keystroke. Both paths validate original input without silently stripping/truncating names and require non-identifying confirmation; Account also rejects private identity fragments from email already supplied there, without retaining comparison data or reading health context. Confirmation is tied to the saved name; failed edits preserve the existing identity. Extracted actual Foundation persistence for Linux regression coverage, preserved invalid legacy bytes, and fixed cleared-name resurrection from old game preferences. Local saves do not claim global reservation. Unknown legal-name identity cannot be proved locally; exact limitation and authenticated-backend blocker documented. Apple shared-observation/UI tests remain unrun.
- Tests added/updated: Prompt1BPseudonymPolicyTests, Prompt1BUsernamePersistenceTests, FruitfolioUsernameStoreTests.
- Verification: {"Swift_6_headless": "105 XCTest + 21 Swift Testing passed (126 total)", "Swift_5_native": "108 XCTest + 21 Swift Testing passed (129 total)", "workflow": "15 Python tests passed", "Swift_syntax": "144 files, zero parser errors", "Apple_UI": "NOT_RUN: Combine store tests and Account/Fruit Basket UI acceptance await Apple runtime", "identity": "Unknown legal names cannot be proved from pseudonyms; public uniqueness/reservation blocked on secure backend"}.
- Next action: Strengthen actual local hormone measurement persistence against wrong-type/corrupt records, verify restart/export/delete and exact decimal/unit preservation with Foundation tests, then continue source-order health context and illustration requirements.
- Commit: containing commit for batch Account-shared-pseudonym-drafts-and-identity-guards.

## Hormones-exact-local-decimals-and-recoverable-persistence

- Parent checkpoint: 1d69886c449ca7277e3b28958a119a98663dc5e0.
- Source-order requirements: [235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 262, 263, 265, 266, 278, 279].
- Source files: Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift, Fruitfolio/Hormone Information/HormoneMeasurementStore.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift.
- Extracted the actual hormone local storage implementation for Foundation regression coverage and kept its ObservableObject API. Wrong-type, malformed and duplicate-ID records are preserved read-only until explicitly erased; saves encode before publishing, repeated IDs edit in place, exports and deletion are exercised across restart. Regression found Scanner.scanDecimal ignores decimal-comma locale on this runtime. Full-string validation now supports locale-specific separators and decimal digits, leading fractions and scientific notation while preserving original result/unit text. Optional result-entry locale prevents reinterpreting new records after device-language changes; legacy data is not guessed or rewritten. No Ask sharing, diagnostic interpretation, adjusted curves or prediction confidence changes introduced. UserDefaults flush durability, Apple editing/Photos/VoiceOver runtime and legacy missing-locale ambiguity remain unverified.
- Tests added/updated: Prompt1BHormonePersistenceTests, Prompt1BHormoneValidationTests.
- Verification: {"Swift_6_headless": "109 XCTest + 21 Swift Testing passed (130 total)", "Swift_5_native": "112 XCTest + 21 Swift Testing passed (133 total)", "workflow": "15 Python tests passed; 36 exact supplemental requirements verified", "Swift_syntax": "146 files, zero parser errors", "Apple_UI": "NOT_RUN: measurement editor/restart UI and accessibility await Apple runtime"}.
- Next action: Connect educational Hormone Library for seven supported hormones to actual approved local research paragraphs and exact source metadata; show explicit gaps instead of inventing biological/testing explanations. Then optional adjusted rhythm and remaining context requirements.
- Commit: containing commit for batch Hormones-exact-local-decimals-and-recoverable-persistence.

## Hormone-Library-real-approved-paragraphs-and-source-trails

- Parent checkpoint: dcd4873226bfb71c71adb8deb1dcaf6d04cd1e9d.
- Source-order requirements: [256, 257, 258, 259, 260, 261, 262].
- Source files: Fruitfolio/Hormone Information/HormoneLibraryProvider.swift, Fruitfolio/Hormone Information/HormoneLibraryView.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift.
- Connected an educational Hormone Library for all seven named hormones to the actual indexed local research package. Five topic sections retrieve complete eligible paragraphs, require an actual hormone name/abbreviation and section terms, retain original topic headings, and show only each paragraph's own exact approved citation metadata. Repeated paragraphs deduplicate; missing sections stay explicitly unavailable; no unspecified Other hormone card or model-memory facts. Reuses only existing relevant estrogen/progesterone/testosterone art, shared semantic translation display and citation controls. Cached static articles contain no measurement/profile input. Actual corpus regressions verify original text/source association for all seven; empty package yields gaps. These are partial retrieved excerpts, not comprehensive clinically reviewed educational synthesis. Apple UI/VoiceOver/localized translation quality remain unrun.
- Tests added/updated: Prompt1BHormoneLibraryTests, Prompt1BModalAccessibilityTests.testHormoneLibraryOriginalSourcesRemainReachableAtAccessibilitySize.
- Verification: {"Swift_6_headless": "112 XCTest + 21 Swift Testing passed (133 total)", "Swift_5_native": "115 XCTest + 21 Swift Testing passed (136 total)", "workflow": "15 Python tests passed", "Swift_syntax": "149 files, zero parser errors", "actual_corpus": "All seven named hormones returned complete eligible paragraphs with exact source association; missing sections/empty corpus remain gaps", "Apple_UI": "NOT_RUN: library source accessibility UI regression added; clinical completeness and translation review remain open"}.
- Next action: Add an explicit opt-in/restore flow for Adjusted Rhythm, fail closed while reviewed measurement-to-educational-curve methods/context are absent, preserve original graphs and measurements, and document the exact clinical-method blocker before moving on to shared health context.
- Commit: containing commit for batch Hormone-Library-real-approved-paragraphs-and-source-trails.

## Hormone-Rhythm-explicit-adjustment-request-and-scientific-gate

- Parent checkpoint: cb4576acb388b77d593ad54ff27ff367ac0e2b7f.
- Source-order requirements: [267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280].
- Source files: Fruitfolio/Hormone Information/HormoneAdjustmentPolicy.swift, Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift.
- Added explicit local opt-in/request and restore controls beside original Hormone Rhythm, with separate actual-measurements entry and distinct no-records/unreadable-storage/no-reviewed-method messages. The policy preserves the entire original presentation byte-for-value in every current decision, never maps laboratory values onto unitless curves, and has no prediction/Ask/measurement mutation path. Exact founder insufficient-information and applied-disclosure text centralized; applied text is deliberately not displayed because no adjustment is actually applied. Added original existing hormone core tests to portable coverage. Actual adjusted curves remain BLOCKED on a versioned clinically reviewed transformation with sufficient testing/measurement context; exact blocker documented rather than faking scientific personalization. Apple UI/runtime remains unrun.
- Tests added/updated: Prompt1BHormoneAdjustmentTests, Prompt22CoreTests.
- Verification: {"Swift_6_headless": "133 XCTest + 21 Swift Testing passed (154 total)", "Swift_5_native": "136 XCTest + 21 Swift Testing passed (157 total)", "workflow": "15 Python tests passed", "Swift_syntax": "151 files, zero parser errors", "adjusted_curves": "BLOCKED: reviewed transformation/required contexts absent; every current decision retains original curves", "Apple_UI": "NOT_RUN; opt-in, restore and disclosure accessibility await Apple runtime"}.
- Next action: Fix shared My Context persistence deleting corrupt private context and prevent stale policy updates after deletion; then add the founder illustrated optional Personal Health Context fields to the existing shared model with explicit provenance/removal timestamps.
- Commit: containing commit for batch Hormone-Rhythm-explicit-adjustment-request-and-scientific-gate.

## My-Context-preserved-corruption-and-atomic-local-updates

- Parent checkpoint: e0191841eab4c1f80ab8a4efdcac284c6a072f24.
- Source-order requirements: [281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291].
- Source files: Fruitfolio/Context Personalization/Prompt27ALocalContextPersistence.swift, Fruitfolio/Context Personalization/Prompt27AContextStore.swift, Fruitfolio/Context Personalization/Prompt27AContextViewModel.swift, Fruitfolio/Context Personalization/Prompt27AContextViews.swift.
- Fixed a data-loss path where loading corrupt My Context deleted the original payload. Exact local Foundation persistence now preserves corrupt/wrong-type records read-only, encodes candidate mutations before publishing or writing, rejects failed mutations without changing the snapshot, supports restart/export and explicit erase. Existing store API retained; context selections disable on unreadable storage and clearing requires explicit confirmation. Policy tasks verify their input still matches current context before publishing, preventing stale adaptation after edits/deletion. Added 71 existing context regressions to the portable suite, removing an unnecessary MainActor annotation from pure tests after Linux XCTest discovery crashed on synchronous actor tests. No prediction mathematics or logs modified. Apple Combine/UI behavior remains unrun.
- Tests added/updated: Prompt1BContextPersistenceTests, Prompt27AContextPersonalizationTests.
- Verification: {"Swift_6_headless": "206 XCTest + 21 Swift Testing passed (227 total)", "Swift_5_native": "209 XCTest + 21 Swift Testing passed (230 total)", "workflow": "15 Python tests passed", "Swift_syntax": "156 files, zero parser errors", "project_integrity": "Foundation OpenStep/project references validated; no Apple build/link", "Apple_UI": "NOT_RUN: corruption warning/clear confirmation/Combine observation await Apple runtime"}.
- Next action: Extend this same shared context model with optional illustrated Body/Genetics/Lab/medication/reproductive/general entries, user-reported or explicitly user-asserted clinician provenance, removal status/timestamps and backward-compatible Codable fields; then progressive-disclosure UI and onboarding integration.
- Commit: containing commit for batch My-Context-preserved-corruption-and-atomic-local-updates.

## Illustrated-personal-health-shared-model-and-entry-points

- Parent checkpoint: 106faad2a4953e39622848dcd5510ef805d63503.
- Source-order requirements: [281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291].
- Source files: Fruitfolio/Context Personalization/FruitfolioPersonalHealthContext.swift, Fruitfolio/Context Personalization/FruitfolioPersonalHealthContextView.swift, Fruitfolio/Context Personalization/Prompt27AContextModels.swift, Fruitfolio/Context Personalization/Prompt27AContextStore.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift.
- Added 33 optional Body/Genetics/Lab/reproductive/medication/general fields to the existing shared locally persisted context model, preserving old Codable payloads. Each illustrated entry maps to its specific canonical asset; no new artwork or guessed techniques/biology. Records distinguish user-provided from user-asserted clinician confirmation, carry creation/update timestamps and revision IDs, and remove medical text on deletion/decline. Progressive disclosure supports add/edit/remove/skip/prefer-not-to-say with dirty-draft protection. Settings My Context and optional onboarding use the same store; export/erase include the same fields. Actual Foundation codec/persistence tests verify restart, removal and no inferred biological/prediction-policy changes. New free text is intentionally not automatically included in minimized AI context; relevant evidence-informed personalization/explicit Ask sharing remain next work. Apple UI/VoiceOver and onboarding acceptance unrun.
- Tests added/updated: Prompt1BPersonalHealthContextTests, Prompt27AContextPersonalizationTests, Prompt1BModalAccessibilityTests.testOptionalPersonalContextCanBeAddedEditedAndRemoved.
- Verification: {"Swift_6_headless": "211 XCTest + 21 Swift Testing passed (232 total)", "Swift_5_native": "214 XCTest + 21 Swift Testing passed (235 total)", "workflow": "15 Python tests passed", "Swift_syntax": "161 files, zero parser errors", "privacy": "Shared local context; removal/decline carry no medical text; no account linkage or automatic new free-text AI inclusion", "Apple_UI": "NOT_RUN: isolated optional-profile UI regression added; illustrated layout/VoiceOver/onboarding acceptance open"}.
- Next action: Implement explicit session-only sharing of selected hormone/personal-context records into Ask with user-reported provenance, relevance and research-only claim boundaries, no autosend/no persistence; then remaining evidence-informed context adaptation and calendar/Today source-order requirements.
- Commit: containing commit for batch Illustrated-personal-health-shared-model-and-entry-points.

## Apple-regression-routes-use-real-shell-environment

- Parent checkpoint: 27f7b4c1d898a7fa78e08182002f79dc8e82206b.
- Source-order requirements: [].
- Source files: Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- Corrected a source-level issue in previously added DEBUG regression routes: they constructed production views directly from ContentView, bypassing required environment objects owned by Prompt03SkeletonView. Regression dispatch now lives inside the existing shell, so navigation/settings/audio/motion/context objects are provided exactly as in the app. ContentView supplies a disposable suite for QA runs and stops if suite creation fails; normal/release routing is unchanged. This makes the source wiring reviewable but does not verify Apple compilation or successful UI launch, which remain NOT_RUN on Linux.
- Tests added/updated: Prompt1BModalAccessibilityTests.
- Verification: {"Swift_syntax": "162 files, zero parser errors", "workflow": "15 Python tests passed", "Foundation_source": "unchanged; prior 232 headless / 235 native checks remain last verified", "Apple_UI": "NOT_RUN: environment wiring corrected, launch/typecheck still need Apple runtime"}.
- Next action: Implement explicit selection and session-only attachment of hormone/personal context into Ask, preserving user-provided provenance, research-only claims, deletion invalidation and no automatic sharing.
- Commit: containing commit for batch Apple-regression-routes-use-real-shell-environment.

## Ask-explicit-one-question-context-and-native-evidence-boundaries

- Parent checkpoint: 51380bfaf1ed35ae0c02ce92f4e383ffc261ec61.
- Source-order requirements: [136, 158, 263, 264, 281, 282, 283, 285, 286, 287, 288, 290, 291].
- Source files: Fruitfolio/Ask/FruitfolioAskUserContext.swift, Fruitfolio/Ask/FruitfolioAskContextPicker.swift, Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Ask/Prompt09AskViewModel.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceModels.swift, Fruitfolio/Core/Intelligence/FruitfolioEvidenceSynthesis.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift.
- Added explicit selection/attach/Send flow for one-question local hormone and personal-context snapshots. Nothing attaches by default; unselected/deleted/declined records are omitted, oversized context fails without truncation, exact values/units/locale and user-asserted provenance remain distinct from clinically verified facts. No attachment is copied into question text, transcript, answers, sources or persistent research cache. Known canonical topic hints can guide local retrieval; user free text cannot supply evidence IDs or factual output. Native grammar still selects approved IDs only, validators still require complete original evidence, and clinical tone is sensitive. Store changes invalidate selections and cancel affected pending/in-flight work; owned outer Send tasks and generation checks cover pre-start/departure races. Isolated Ask QA now uses fixture measurements, not production records. Actual full-corpus Swift/Qwen context path generated a source-grounded answer in 12.372s Linux CPU without emitting private fixture details. Apple UI/Combine lifecycle tests are added but unrun; no MADLAD or iOS inference claim.
- Tests added/updated: Prompt1BAskUserContextTests, Prompt1BAskLifecycleTests.testExplicitContextIsNotCopiedIntoMessagesAndCancellationRejectsLateResponse, Prompt1BModalAccessibilityTests.testAskContextRequiresAttachAndCancelDoesNotShare.
- Verification: {"Swift_6_headless": "215 XCTest + 21 Swift Testing passed (236 total)", "Swift_5_native": "219 XCTest + 21 Swift Testing passed (240 total)", "native_context": "Actual Swift/Qwen + actual corpus generated-path test passed in 12.372s; private fixture marker absent from answer/citations", "workflow": "15 Python tests passed", "Swift_syntax": "165 files, zero parser errors", "Apple_UI": "NOT_RUN: explicit picker, cancellation and shared-store observation require Apple runtime"}.
- Next action: Continue independent original-order Cycle Tracker wheel/Today responsive layout and calendar loading/transition interaction fixes; clinically reviewed free-text adaptation, adjusted-curve method, Apple runtime and MADLAD model blockers remain explicit.
- Commit: containing commit for batch Ask-explicit-one-question-context-and-native-evidence-boundaries.

## Cycle-wheel-bounded-notes-and-context-safe-calendar-loading

- Parent checkpoint: ea910a620c79475dc7b8d40b3a608e2f1a7a9fc7.
- Source-order requirements: [281, 283, 284, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296].
- Source files: Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18WheelNoteLayout.swift, Fruitfolio/Cycle Tracker/Cycle Wheel/Prompt18DynamicCycleWheel.swift, Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarPresentationPolicy.swift, Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarLoader.swift, Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarView.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Tools/check_swift_syntax.py.
- Wheel contextual notes now use shared taped-white layout/scrolling, true 497x499 art bounds, clamped placement and explicit close; shared press behavior respects Reduce Motion. Accessibility sizes expose full region/day-range controls and inline readable notes instead of overlapping ring labels; stale selections clear on model change. Calendar month loads capture month+context identity and reject stale results. Fixed incoming context policy not reaching the loader, and added immediate pure view-time suppression of only inapplicable estimate flags while preserving recorded periods, symptoms, BBT and notes. Independent supplemental loading begins alongside existing snapshots. Added original wheel/calendar core tests to portable coverage. Switched available syntax checking to actual Swift compiler parse phase after optional Tree-sitter reported false errors in valid pre-existing calendar expressions. No prediction math, source logs or artwork changed; Apple UI/rendering/loader typecheck remain unrun.
- Tests added/updated: Prompt1BWheelNoteLayoutTests, Prompt18CycleWheelTests, Prompt19CalendarEngineTests, Prompt1BCalendarPresentationPolicyTests, Prompt1BModalAccessibilityTests.testWheelNoteActionsStayReachableAtAccessibilitySize.
- Verification: {"Swift_6_headless": "244 XCTest + 21 Swift Testing passed (265 total)", "Swift_5_native": "248 XCTest + 21 Swift Testing passed (269 total)", "workflow": "15 Python tests passed", "Swift_syntax": "175 changed Swift files parsed by Swift 6.2.1 compiler; zero parse errors; no Apple typecheck/link", "Apple_UI": "NOT_RUN: isolated wheel accessibility harness/test added; note rendering, month interaction and scene behavior remain unverified"}.
- Next action: Reduce duplicate Today archive/onboarding reads using one coherent actor snapshot and derived state, verify actual Foundation loaders where possible, then remaining calendar/logging controls and source-order backlog.
- Commit: containing commit for batch Cycle-wheel-bounded-notes-and-context-safe-calendar-loading.

## Verified-local-Git-bundle-recovery-workflow

- Parent checkpoint: e0c0d3949a073e6e97481c9aa112fedf228bef78.
- Source-order requirements: [].
- Source files: Tools/create_local_recovery_bundle.py, development_workflow/RECOVERY_PROTOCOL.md.
- Added a local-only recovery bundle command that refuses dirty/different-branch state, uses a verified common prerequisite, validates the expected tip and writes SHA-256/restore metadata outside the checkout. A real Git fixture test restores into another repository verified to lack the checkpoint commit before bundle fetch, and verifies dirty changes are preserved on refusal. No network, push, merge or credential changes. Bundles contain Git objects only, not fetched LFS assets, and local files do not establish remote/cloud durability. Actual environment bundle is created immediately after this clean checkpoint.
- Tests added/updated: RecoveryBundleTests.
- Verification: {"workflow": "16 Python tests passed, including independent Git fixture recovery and dirty-state refusal", "Swift": "unchanged; prior 265 headless / 269 native checks remain latest verified", "real_bundle": "created after this clean checkpoint; inspect external SHA-256 manifest", "limits": "Local Git artifact only; retain/download it, restore prerequisite/LFS separately; no cloud persistence guarantee"}.
- Next action: Create verified /workspace/recovery/Fruitfolio-prompt-1b.bundle from the containing commit, then implement one coherent Today snapshot to remove redundant reads and retain deterministic context/prediction semantics.
- Commit: containing commit for batch Verified-local-Git-bundle-recovery-workflow.

## Today-coherent-cycle-read-and-actual-loader-regressions

- Parent checkpoint: f32842ab8b475e2a8ba2497f5e5381cb077e19bd.
- Source-order requirements: [281, 283, 284, 287, 288, 289, 290, 291, 295, 297].
- Source files: Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleModels.swift, Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleStore.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayModels.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Tools/run_portable_swift_tests.py.
- Replaced Today's repeated archive/onboarding reads with one actor-isolated archive+derived-state read and a reusable immutable Today load snapshot. Today state and its existing prediction bridge now consume the same captured inputs; onboarding and Daily Log work stay independently concurrent. Owned reveal tasks cancel on departure/inactive scene, returning active triggers a fresh load, generation guards reject stale completions, and load failure logging omits raw health errors. No prediction algorithms or stored observations changed. Expanded exact production Foundation compilation to real cycle/onboarding stores, Today loader and Calendar loader; original domain/onboarding/Today tests plus real-loader integration verify context suppression preserves recorded metadata and creates no fertile/ovulation windows. Test preferences now use disposable XDG_CONFIG_HOME. This verifies core runtime on Linux, not Apple UI, physical restart or device latency.
- Tests added/updated: Prompt1BTodaySnapshotTests, Prompt13CycleEngineTests, Prompt14CycleOnboardingTests, Prompt16TodayStateBuilderTests.
- Verification: {"Swift_6_headless": "296 XCTest + 21 Swift Testing passed (317 total)", "Swift_5_native": "300 XCTest + 21 Swift Testing passed (321 total)", "workflow": "16 Python tests passed", "Swift_syntax": "179 changed Swift files parsed by Swift 6.2.1 compiler; zero parse errors", "actual_loaders": "Real Foundation Cycle/Onboarding/Today/Calendar implementations compiled and tested; no prediction-math changes", "Apple_UI": "NOT_RUN: Today scene refresh/reveal and device performance remain unverified"}.
- Next action: Refresh the local recovery bundle, then correct canonical cycle LocalDate versus non-Gregorian device-calendar conversion boundaries with timezone/locale regression tests, preserving all existing stored logs rather than guessing legacy calendar identity. Continue source-order controls afterward.
- Commit: containing commit for batch Today-coherent-cycle-read-and-actual-loader-regressions.

## Canonical-civil-date-boundaries-and-invalid-record-protection

- Parent checkpoint: e8dda227cd2b22ee5b646cea21b55f07ad445545.
- Source-order requirements: [136, 247, 283, 287, 290, 295, 298, 299].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioCanonicalCalendar.swift, Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20CalendarProjection.swift, Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarLoader.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmLoader.swift, Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsLoader.swift.
- Fixed Date-to-civil-date conversions copying Buddhist/Hebrew/Islamic/Japanese device-calendar years into Gregorian cycle records. One validated shared boundary now retains caller time zone but canonical Gregorian components; typed reverse conversion replaces JSON/reflection work in Today/Calendar/Hormone/Trends and onboarding. Daily Log uses the same civil-date convention and projects explicitly to display-calendar month/day keys off the main actor. Custom decoding rejects impossible dates instead of rolling them forward; makeLog refuses invalid days, and actual cycle-file regression proves malformed original bytes cannot be overwritten by a new record. Closed a nonfinite BBT numeric gap without adding clinical range interpretations. Tests cover leap day, five calendars, travel, no epoch invention, actual Buddhist calendar-loader display and unchanged legacy valid years. Existing ambiguous legacy calendar identity is never guessed/migrated; exact limitation recorded. Apple date-picker and historical reconciliation acceptance remain unrun.
- Tests added/updated: Prompt1BCanonicalCalendarTests, Prompt13CycleEngineTests, Prompt14CycleOnboardingTests, Prompt1BTodaySnapshotTests.
- Verification: {"Swift_6_headless": "304 XCTest + 21 Swift Testing passed (325 total)", "Swift_5_native": "308 XCTest + 21 Swift Testing passed (329 total)", "workflow": "16 Python tests passed", "Swift_syntax": "189 changed Swift files parsed by Swift 6.2.1 compiler; zero parse errors", "date_safety": "Five calendar identifiers, leap/travel boundaries, actual Calendar loader and corrupted real cycle file exercised; old valid stored years remain unchanged", "Apple_UI": "NOT_RUN: date picker/display and full Hormone/Trends UI behavior await Apple runtime"}.
- Next action: Refresh recovery bundle, then preserve date-only hormone test days for new records and keep uncollected time-of-day out of explicit Ask context; retain legacy records without guessing original time zones. Resume original logging/control backlog afterward.
- Commit: containing commit for batch Canonical-civil-date-boundaries-and-invalid-record-protection.

## Hormone-civil-test-day-and-honest-Ask-date-precision

- Parent checkpoint: 5e6e53f074119ff849783614ab8cff33b829a46f.
- Source-order requirements: [242, 247, 249, 250, 251, 253, 263, 264].
- Source files: Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift, Fruitfolio/Ask/FruitfolioAskUserContext.swift, Fruitfolio/Ask/FruitfolioAskContextPicker.swift.
- New hormone entries preserve the explicitly reported Gregorian civil test day and date-entry timezone; no clinical collection time or lab location is invented. History sorts reported days with deterministic same-day IDs. Existing legacy entries remain unchanged unless the user explicitly confirms a displayed day. Ask attachments disclose day-only precision and legacy uncertainty instead of transmitting a fabricated timestamp. A civil day skipped in the display timezone remains explicit and is never silently replaced. Regression tests exercise actual model persistence and Ask snapshot semantics. Apple UI behavior remains unverified.
- Tests added/updated: Prompt1BHormoneCivilDateTests.
- Verification: {"Swift_6_headless": "308 XCTest +21 Swift Testing passed; final 5-test hormone suite also passed", "Swift_5_native": "312 XCTest +21 Swift Testing passed; final 5-test hormone suite also passed", "workflow": "16 Python tests passed", "Swift_syntax": "190 changed Swift files parsed, zero errors; no Apple typecheck", "Apple_runtime": "NOT_RUN; no Apple SDK/device", "MADLAD": "Official weights/tokenizer still blocked by proxy; T5 inference and clinical translation not verified"}.
- Next action: Continue daily-log shared controls, accessible unsaved confirmation and asynchronous draft/save correctness; then continue next independent original-order requirements.
- Commit: containing commit for batch Hormone-civil-test-day-and-honest-Ask-date-precision.

## Daily-log-immutable-writes-and-shared-controls

- Parent checkpoint: 0eda0425bf349e093a24df8c39f9578b21bc172f.
- Source-order requirements: [297, 298, 299, 300, 303].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift.
- Fixed in-flight draft edits being incorrectly marked saved and changed retry drafts reusing old idempotency IDs. Repository writes capture immutable drafts; baseline reconciliation preserves later edits, including durable writes after presentation cancellation. Cancelled initial loads become retryable, and loaded dirty drafts survive view reappearance. Explicit UI repository tasks are owned/cancelled, callbacks guarded, and dismissal prevented during active writes. Daily log actions use canonical Reduce Motion-aware press style; unsaved dialog uses measured shared taped-white popup. Added exact production store/integration sources and existing 36 daily-log tests to portable runner; converted 26 synchronous MainActor test signatures to async after Linux XCTest discovery cast crash, with assertions unchanged. Two actual view-model suspension tests added for Apple, not run on Linux.
- Tests added/updated: Prompt1BDailyLogWriteTests, Prompt20CoreTests, Prompt1BDailyLogViewModelTests (Apple NOT_RUN).
- Verification: {"headless_full": "313 XCTest +21 Swift Testing passed", "native_full": "317 XCTest +21 Swift Testing passed", "daily_log_expansion": "40 tests passed after resolving test-discovery crash; includes actual file persistence, idempotency, deletion, calendar metadata, future guards", "workflow": "16 Python tests passed; 36 exact supplemental requirements retained", "Swift_syntax": "193 changed Swift files parsed; zero errors before final trivial CloseControl disabled modifier; final parse follows", "Apple_UI_and_view_model": "NOT_RUN; SwiftUI/Combine and runtime absent"}.
- Next action: Correct unified symptom timeline to preserve distinct recorded dates and observations without cycle assignments; add detailed accessible observation list and regression coverage; continue remaining original-order requirements.
- Commit: containing commit for batch Daily-log-immutable-writes-and-shared-controls.

## Dated-unified-symptom-timeline-and-readable-observations

- Parent checkpoint: c41639bdfbc58f66d84328a90e9a7d346441f49b.
- Source-order requirements: [305, 306, 307, 308, 309].
- Source files: Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsModels.swift, Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsView.swift.
- Replaced overlapping cycle-day x coordinates with actual recorded civil dates; retains observations without cycle assignment, distinguishes same cycle day across months and uses civil-day spacing across DST. All logged symptom types initially visible, selected observations available in a readable expandable list with date/symptom/optional cycle day. Shared graph retains every selected point with bounded scroll width; missing days never become absence/zero/severity and no connecting trend is invented. Calculated recurrence summaries named per symptom, distinguished from raw dots and qualified as descriptive rather than diagnoses/predictions. Seven production timeline tests added; eight existing trends tests now portable with assertions preserved and async actor-safe signatures. UI and physical-device performance remain unverified.
- Tests added/updated: Prompt1BSymptomTimelineTests, Prompt24TrendsCoreTests, Prompt20CoreTests.
- Verification: {"Swift_6_headless": "364 XCTest +21 Swift Testing passed", "Swift_5_native": "368 XCTest +21 Swift Testing passed, includes real Qwen and explicit-context research generation", "workflow": "16 Python tests passed; 36 supplemental source texts retained", "Swift_syntax": "198 changed Swift files parsed; zero errors", "Apple_UI": "NOT_RUN; graph layout, detailed VoiceOver traversal and device performance await Apple runtime"}.
- Next action: Apply shared noncropping responsive scientific-art composition to education screens; preserve illustration/explanation relationship and noninteractive artwork hit behavior; shared semantic rendering and qualified personalization. Continue Fruit Basket requirements afterward.
- Commit: containing commit for batch Dated-unified-symptom-timeline-and-readable-observations.

## Shared-scientific-plates-and-typed-biology-context

- Parent checkpoint: 95661536839f87dcdc0d7237be427c5cb08b9529.
- Source-order requirements: [310, 311, 312, 313, 314].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioScientificArtSizing.swift, Fruitfolio/Core/DesignSystems/FruitfolioScientificIllustration.swift, Fruitfolio/Core/DesignSystems/FruitfolioSavedScientificIllustrations.swift, Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyLoader.swift, Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyView.swift, Fruitfolio/Cycle Tracker/Fertilization/Prompt25FertilizationView.swift, Fruitfolio/Cycle Tracker/Pregnancy/Prompt26PregnancyEducationViews.swift.
- Shared full-source-canvas aspect-fit layout now used for Body Biology hero, Fertilization primary, Pregnancy reference and explicitly saved science plates. Exact production sizing policy used in both SwiftUI measurement and placement; art is noninteractive, missing source explicit, source files/resources preserved. Oocyte offset scales with plate width, delayed motion rechecks Reduce Motion and active motion resets without animation. Fimbriae explanatory text no longer squeezed beside fixed-width art. Body Biology uses serious shared semantic/translation rendering and general-reference qualifier; Pregnancy research rendering serious. Production biology routing now uses typed Today state rather than localized title strings; no ovulation/luteal/follicular state inferred from day numbers, day-one character requires recorded bleeding. Legacy title helper compatibility-only. Clinical image registration, Apple custom Layout typecheck/hit testing and MT runtime remain unverified.
- Tests added/updated: Prompt1BScientificArtSizingTests, Prompt21BodyBiologyCoreTests.
- Verification: {"Swift_6_headless": "385 XCTest +21 Swift Testing passed", "Swift_5_native_full": "374 XCTest +21 Swift Testing passed before typed routing addition", "Swift_5_native_final_targeted": "21 actual production biology/sizing tests passed with final sources", "workflow": "16 Python tests passed", "Swift_syntax": "204 changed Swift files parsed; zero errors", "Apple": "NOT_RUN; no Apple SDK/UI/device; anatomical annotation/source review remains open", "MADLAD": "Integration retained; official weights/tokenizer acquisition and offline T5 inference still blocked, not verified"}.
- Next action: Distinguish a previously reported open period from a bleeding observation recorded today without inventing an end date or daily bleeding; then proceed to revised Fruit Basket text and real grounded research provider requirements320 onward. LifeBridge content remains externally gated as recorded.
- Commit: containing commit for batch Shared-scientific-plates-and-typed-biology-context.

## Open-period-report-versus-todays-recorded-bleeding

- Parent checkpoint: 6f374fd529f54334e83e83b5680122388957d506.
- Source-order requirements: [283, 287, 290, 298, 301, 302, 314].
- Source files: Fruitfolio/Cycle Tracker/Today/Prompt16TodayModels.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Fruitfolio/Cycle Tracker/Body Biology/Prompt21BodyBiologyLoader.swift.
- Separated a previously reported open period episode from a bleeding observation on today’s civil date. Earlier onboarding reports no longer assert current daily bleeding; they remain reported-open until updated, without inventing end dates or duration cutoffs. Invalid future/missing supplied starts and supplied ends cannot establish an open episode. Actual recorded bleeding takes precedence for today; following unlogged days manufacture no observations. Today shows explicit provenance ahead of a general wheel caption through serious shared semantic/translation renderer. Body Biology does not infer menstruation from bleeding/spotting alone: requires a reported open episode or explicit cycle day one plus today’s observation. Original records untouched. Actual store/loader regression tests cover before/same-day/next-day, ended/future episodes and neutral routing.
- Tests added/updated: Prompt16TodayStateBuilderTests, Prompt1BTodaySnapshotTests, Prompt21BodyBiologyCoreTests.
- Verification: {"Swift_6_headless": "389 XCTest +21 Swift Testing passed", "Swift_5_native": "393 XCTest +21 Swift Testing passed", "workflow": "16 Python tests passed", "Swift_syntax": "205 changed Swift files parsed; zero errors", "Apple_runtime": "NOT_RUN; actual Today/biology refresh, accessibility and display remain behind Mac/device gate"}.
- Next action: Implement revised Fruit Basket copy, serious sourced feedback and actual offline research-library question provider with citation preservation; continue gameplay star/vine/puddle requirements and remaining original-order checklist.
- Commit: containing commit for batch Open-period-report-versus-todays-recorded-bleeding.

## Fruit-Basket-offline-excerpt-practice-and-source-trails

- Parent checkpoint: 2f19f1ca02dd2a99f1a3569d0eb93ac912ddedbd.
- Source-order requirements: [320, 321, 322, 323, 324, 325, 326, 327, 338, 378, 379].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift, Fruitfolio/Core/Intelligence/FruitfolioHealthSafety.swift.
- Replaced production unavailable game adapter with offline exact-source-excerpt practice using actual research package eligibility, full paragraph restoration and exact source IDs/APA/DOI/URL/version. No generated clinical distractor assertions/model memory/network/health context. Explicit vocabulary practice label and clinical-review limitation; conceptual question-depth and atomic localized-quiz validation remain open, not falsely marked complete. Searches all ranked eligible paragraphs and exhausts practice IDs before exhaustion; quarantined/missing citations stay excluded. Literal semantic encoding preserves scientific operators/quantities. Source records now render in feedback/reveal and persist into saved content instead of count-only source labels. Revised founder game menu/instruction/topic wording and conditional star-pass instructions; canonical measured tour popup/background AX exclusion. Owned question tasks + generation/topic/difficulty/screen guards prevent stale results/error/history writes. Safety word-boundary fix avoids grapes/rape false positive while preserving real phrases, flexible whitespace/curly apostrophes. Two actual delayed-view-model regressions Apple-only unrun.
- Tests added/updated: Prompt1BFruitBasketResearchTests, Prompt1BHealthSafetyBoundaryTests, Prompt1BFruitBasketQuestionOwnershipTests (Apple NOT_RUN).
- Verification: {"Swift_6_headless": "399 XCTest +21 Swift Testing passed", "Swift_5_native": "403 XCTest +21 Swift Testing passed; includes actual corpus excerpt/citation and Qwen integration tests", "workflow": "16 Python tests passed", "Swift_syntax": "210 changed Swift files parsed; zero errors", "Apple_runtime": "NOT_RUN: game launch, tour, delayed view-model, citation interaction and saving UI require Apple runtime", "content_limits": "Source-excerpt practice is implemented; not a clinically reviewed conceptual question bank or verified localized quiz; full-source expansion and research review remain open"}.
- Next action: Implement measured basket-entry/settled treatment shared by independent stars and fruit, verify rarity/spawn concurrency, then continue wind/rain/puddle/branch/vine mechanics and progression requirements in original order. Preserve research practice limitations and continue conceptual/localized game generation backlog afterward.
- Commit: containing commit for batch Fruit-Basket-offline-excerpt-practice-and-source-trails.

## Measured-fruit-and-star-entry-before-awards

- Parent checkpoint: b2e427d0674d58114786e7a69c39b7d419b92907.
- Source-order requirements: [328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338].
- Source files: Fruitfolio/Fruit Basket/Prompt28CatchPresentation.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift.
- Active catch now starts a shared transit only when leading edge crosses the visible basket mouth, rather than awarding at y0.82 above the basket. Fruit/stars enter and visibly flatten/hold before exactly-once completion applies existing count/pass/consequence rules. Shared source-registered geometry used by physics/rendering; complete transformed bounds below rim before count. Original398x380PNG preserved; full back and lower source overlay occlude collected objects. Basket stores actual caught fruit IDs instead of cycling through possible good fruits. Pass bank visible and completion star chime uses existing audio. All fruit/stars/transits count toward concurrency limit; 8-fruit minimum star spacing plus5% draw, no pass quota, spawn intervals sampled once. Invalid/large frame deltas guarded; reduced motion static settled pose. Eight actual production Foundation regressions pass; two actual view-model frame tests Apple-only unrun. Visual registration/convincing animation and classification-mode star/settlement parity remain unfinished, not marked verified.
- Tests added/updated: Prompt1BCatchPresentationTests, Prompt1BCatchViewModelTests (Apple NOT_RUN), Prompt1BFruitBasketRulesTests.
- Verification: {"Swift_6_headless": "407 XCTest +21 Swift Testing passed", "Swift_5_native": "411 XCTest +21 Swift Testing passed", "workflow": "16 Python tests passed; 36 source-exact supplemental requirements retained", "Swift_syntax": "213 changed Swift files parsed; zero errors", "Apple_UI_and_view_model": "NOT_RUN; engineering geometry registration, source rim mask and visible settlement not runtime validated", "unfinished": "Classification-mode star interaction and settlement parity next; no completed-478 or full inference claim"}.
- Next action: Complete classification/accessibility mode standalone-star and shared delayed-settlement parity, then proceed immediately to wind/rain/puddle/branch/vine mechanics requirements339 onward. Add Mac regression route for physical acceptance when available; do not claim Apple runtime verified.
- Commit: containing commit for batch Measured-fruit-and-star-entry-before-awards.

## Classification-stars-and-shared-settlement-parity

- Parent checkpoint: a1294fb82dccc9bbf04cc9b3be41352f95f591d4.
- Source-order requirements: [328, 329, 330, 334, 335, 336, 338, 381].
- Source files: Fruitfolio/Fruit Basket/Prompt28CatchPresentation.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift.
- Accessible classification controls now expose rare standalone stars through explicit untimed catch/skip actions. Accepting fruit or stars enters the shared delayed settlement path, preserving exactly-once awards/pass use and actual collected fruit; skipping a star has no consequence and never fills fruit target. Shared local pose renders settlement in classification basket. Clock runs only while settlement is pending, stops on idle, resumes pending entries after pause and does not advance falling objects while in classification mode. Control changes retain earned counters/captured transits and discard unselected invisible presentations. One additional production local-pose test plus two actual Combine view-model classification tests added; latter unrun. Visual/VoiceOver acceptance still requires Apple runtime.
- Tests added/updated: Prompt1BCatchPresentationTests, Prompt1BCatchViewModelTests (Apple NOT_RUN).
- Verification: {"Swift_6_headless": "408 XCTest +21 Swift Testing passed", "Swift_5_native": "412 XCTest +21 Swift Testing passed", "workflow": "16 Python tests passed;36 exact supplemental entries preserved", "Swift_syntax": "213 changed Swift files parsed; zero errors", "Apple": "NOT_RUN: classification input, clock suspension and settlement visuals/VoiceOver await Apple SDK/runtime"}.
- Next action: Correct overly broad sensitive-topic exclusion in new game provider: retain serious sourced educational feedback while preserving urgent-request bypass. Then immediately continue wind/rain/puddle/branch/vine requirements339 onward.
- Commit: containing commit for batch Classification-stars-and-shared-settlement-parity.

## Serious-game-education-without-blanket-topic-exclusion

- Parent checkpoint: e67d22c0d26e4503602fc961d54cf12109d10aa9.
- Source-order requirements: [325, 338, 378, 379].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift.
- Corrected initial overly broad provider boundary: sensitive educational topics/paragraphs remain eligible and retain their full source trail, with serious neutral feedback instead of blanket exclusion. Urgent phrase requests retain canonical safety bypass. Query/source safety cannot be overridden by false tone metadata. Serious question feedback suppresses playful characters/emoticons/celebratory chime; ordinary correct copy now matches founder exact YAYYY! catch your fruit! :-). Distinguishes eligible-research-but-no-fair-vocabulary-question from no eligible source, avoiding false research-absence claims. Added source-retention/unavailability regressions and updated current verification document. This remains excerpt practice, not reviewed conceptual question-depth or jointly verified quiz localization.
- Tests added/updated: Prompt1BFruitBasketResearchTests.
- Verification: {"Swift_6_headless": "410 XCTest +21 Swift Testing passed; final8 game research tests also passed", "Swift_5_native": "414 XCTest +21 Swift Testing passed", "workflow": "16 Python tests passed", "Swift_syntax": "213 changed Swift files parsed; zero errors", "Apple": "NOT_RUN: feedback presentation, copy/tone/interaction and full app typechecking remain behind Mac/runtime gate"}.
- Next action: Implement wind/rain/puddle/branch/vine mechanics using preserved source art and shared painted-footprint geometry, actual code trajectories, rustle audio/contact strain, physically localized basket inertia, and specified Strawberry storm note. Continue original-order progression requirements afterward.
- Commit: containing commit for batch Serious-game-education-without-blanket-topic-exclusion.

## Evidence mapping correction — game versus Contact rows

Three recent game batches accidentally attached evidence to Contact rows 378/379/381 (universal Contact decoration, green flecks, sparkles). Those rows have been restored to their exact pre-game evidence/status from 2f19f1c; no app implementation or original requirement text was removed. Source-order IDs in historical log entries remain historical and are corrected here: b2e427d game retrieval/citations evidence also belongs to 125/136/162/163/165 and game 324–327/372; e67d22c classification accessibility belongs to game row 372, not Contact sparkle row381; e89369c serious research fallback evidence belongs to165/325/372, not Contact decoration378/379. MASTER_CHECKLIST is the corrected authoritative mapping. All remain source-reviewed/in-progress, without Apple runtime verification claims.

## Source-painted-game-obstacles-and-responsive-storm-note

- Parent checkpoint: e89369c17c9619897f0677a3fbb6750f90e03ef1.
- Source-order requirements: [36, 324, 327, 335, 336, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 372].
- Source files: Fruitfolio/Fruit Basket/Prompt28ObstacleGeometry.swift, Fruitfolio/Fruit Basket/Prompt28ObstaclePhysics.swift, Fruitfolio/Fruit Basket/Prompt28ObstacleMasks.json, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28CatchPresentation.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketEngine.swift, Fruitfolio/Core/DesignSystems/FruitfolioLargeControlCardPopup.swift, Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Tools/compile_fruit_basket_masks.py.
- Reproducible read-only alpha analysis of untouched founder vine/branch/puddle PNGs produces cached source-hash collision masks. Shared renderer/physics frames ignore transparent padding; vines at left actual paint, mirrored branch rooted at right playfield edge. Code wind affects trajectories; one bounded branch bounce/persistent reflection preserves captured base speed/drift. Good fruit/stars slow and visibly strain at actual painted vines; bad fruit never does; rustle emits on entry only. Rain always creates puddles, original puddle art subtly moves with pause/Reduce Motion cancellation. Painted lower-basket water contact gives target-following inertia that survives stopped touch events and restores dry response. Responsive basket/ground fits short landscape field and bottom safe area instead of offscreen counting. Canonical measured large original contact/control card shows exact Strawberry storm dialogue once per session/round, pauses until explicit close/ack, whole-background modal blur/AX exclusion. Restored missing good-fruit star badge used by instructions. No image bytes edited. Corrected three earlier game-evidence mappings erroneously attached to Contact decoration rows378/379/381; original requirement text/source work retained. Apple visual/typecheck/audio/touch/performance acceptance remains unverified.
- Tests added/updated: Prompt1BObstacleGeometryTests, Prompt1BObstaclePhysicsTests, Prompt1BCatchPresentationTests, Prompt1BPopupLayoutTests, test_fruit_basket_masks.
- Verification: {"Swift_6_headless": "424 XCTest +21 Swift Testing passed", "Swift_5_native": "428 XCTest +21 Swift Testing passed", "final_obstacle_targeted": "12 tests passed with final source/tests", "workflow": "18 Python tests passed;3 masks reproducible with original PNG bytes/SHA256 unchanged;36 supplemental source texts preserved", "Swift_syntax": "219 changed Swift files parsed; zero errors", "project": "Xcode project parsed; build-file references resolved. No Xcode build/link.", "Apple_runtime": "NOT_RUN: actual badge/alpha registration, physical animations, storm focus/scroll, audio, touch, FPS and device testing require Apple runtime", "tracker_fidelity": "Corrected misattached game evidence to research/game accessibility rows; Contact decor rows restored to pre-game evidence"}.
- Next action: Verify and implement progression358–367: gradual successful-round-based capped difficulty, immutable captured velocities, true round completion and exact accumulated result. Then update rules/FAQ/accessibility372 and add isolated game QA routes/tests before continuing Contact, account, localization, saved media, performance and final checklist sections. Continue remaining research/clinical/MADLAD blockers independently; no push.
- Commit: containing commit for batch Source-painted-game-obstacles-and-responsive-storm-note.

## Reset-safe-game-progression-and-protected-existing-state

- Parent checkpoint: 0d12fd190e32194bff8e290eacc9dd3f841809a5.
- Source-order requirements: [358, 359, 360, 361, 362, 363, 364, 365, 372].
- Source files: Fruitfolio/Fruit Basket/Prompt28ProgressionPolicy.swift, Fruitfolio/Fruit Basket/Prompt28GamePersistence.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift.
- Fixed reset-to-one immediately jumping back to lifetime difficulty after one win. Optional per-level success credit resets independently; lifetime wins/highest level/fruit/stars/scores remain. Ordinary2/2/2/3/3/4/4 advancement thresholds and cap8 preserved, failures never advance/consume credit, question depth independent. Legacy coherent tiers retain existing observable offset; inconsistent legacy reset states keep visible tier without guessed reset dates. Extracted actual Foundation game persistence preserving existing defaults key/JSONfields, optional format marker, no read-time migration write. Wrong type/corrupt/future/invalid data retained read-only; changed/cleared raw state cannot be blindly overwritten/resurrected in tested sequential stale-writer cases. Scrollable recovery UI stops owned questions/gameplay; reload accepts fresh state/preferences without rewriting history. Existing two Apple consequence tests now drive entry/settlement before asserting awards; fixed literal escaped UUID fixture namespace. Eight real persistence and five progression tests pass, including reset-after200wins through storage reinitialization. No cross-process atomicity/disk-crash durability or actual Apple runtime/playtesting claim.
- Tests added/updated: Prompt1BProgressionPolicyTests, Prompt1BGamePersistenceTests, Prompt28FruitBasketTests (Apple owner tests updated, NOT_RUN).
- Verification: {"Swift_6_headless": "437 XCTest +21 Swift Testing passed", "Swift_5_native_full": "440 XCTest +21 Swift Testing passed before final reset/storage E2E case", "Swift_5_native_final_targeted": "13 production persistence/progression tests passed with final Foundation sources", "workflow": "18 Python tests passed", "Swift_syntax": "224 changed Swift files parsed; zero errors", "Apple": "NOT_RUN: Combine store/controller integration, updated owner tests, recovery focus/scroll, actual cross-window behavior and physical cap/cozy evaluation", "storage_scope": "Original bytes/values retained in actual UserDefaults tests; reinitialization is not physical process restart, fingerprint guard is not a cross-process atomic transaction"}.
- Next action: Implement an exact per-round capture ledger/result snapshot for366–367: actual caught fruit, stars, passes spent, misses/consequences and earned versus cumulative score; count actual captures in failed as well as successful attempts without double counting or inventing legacy history. Render truthful success/failure summaries and source explanation separate from visual catch classification; make classification content scroll on short/large-text viewports. Then continue corrected rules/FAQ/accessibility368–372 and remaining sections.
- Commit: containing commit for batch Reset-safe-game-progression-and-protected-existing-state.

## Exact-round-results-and-preserved-source-versions

- Parent checkpoint: 9018a71da51d70a14c414fae25954bef1b1ae4d6.
- Source-order requirements: [125, 162, 366, 367, 372].
- Source files: Fruitfolio/Fruit Basket/Prompt28RoundLedger.swift, Fruitfolio/Fruit Basket/Prompt28SavedResearchCopy.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketStore.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketViewModel.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift.
- # Accepted-event round results and sourced saved lessons

A per-round ledger now records actual accepted object IDs, exact caught fruit order, standalone stars, carried-in passes, protected bad catches, the actual unprotected ending event and passed objects. Duplicate events, rewards after terminal completion, and a successful snapshot before the target are rejected. The controller checks terminal ledger/session agreement before final round accounting, then retains an immutable result with level played/next level, earned points versus cumulative session score, stars collected versus passes remaining, and consequences. The existing round-ID finalization guard remains.

Actual good captures now increment lifetime fruit totals when awarded, including captures in failed/unfinished attempts, matching the existing per-capture star accounting. The old implementation only added ten on successful completion and omitted earlier caught fruit. No historical amount is guessed or backfilled. New topics record complete-from-start accounting; legacy missing provenance stays unknown and the local totals view explains possible historical omissions. Failed attempts never advance catching difficulty. Round results remain separate from the medical/source explanation and are not written into health context, Ask memory, or lab data.

Reveal artwork and accessibility now use the captured result rather than a fixed unconditional ten. Both success and failure expose actual fruit/star/pass/score details. The old wording implying the clinical paragraph explained why a fruit was “good” is replaced by a separate library-explanation label; the catch rule remains its own game rule. Classification content and failed-attempt results scroll for short/large-text viewports.

Explicit user saving copies the original sourced lesson/question, citations and each source record's own content version, with the package version separately retained. It does not present game counts as sourced medical claims. Legacy known package versions remain fallback metadata; invalid duplicate source identities cannot create a false saved trail. No automatic save/health-profile transfer is added.

Five portable ledger regressions check premature completion, duplicate/late events, partial failure, pass conservation, score deltas, passed-object semantics and immutable snapshots; three portable saved-source regressions check actual payload/citation/version preservation and invalid-source refusal. The existing legacy document test now verifies unknown capture-accounting provenance is preserved. An additional actual Combine-controller test drives star protection, seven-fruit failure, ten-fruit retry, exact lifetime totals and repeated finalization; it is **NOT RUN on Linux**. UIKit rendering, source versus game visual hierarchy, VoiceOver, actual timers and app persistence remain behind the Apple/runtime gate. Source/core tests are not proof of device playability or clinical accuracy.

- Tests added/updated: Prompt1BRoundLedgerTests, Prompt1BGameSavedSourceTests, Prompt1BGamePersistenceTests, Prompt1BCatchViewModelTests (Apple NOT_RUN).
- Verification: {"Swift6": "445 XCTest +21 Swift Testing passed", "nativeSwift5": "449 XCTest +21 Swift Testing passed", "syntax": "228 changed Swift files parsed, zero errors", "Apple": "NOT_RUN: actual controller regression and UI/VoiceOver/runtime; Xcode unavailable"}.
- Next action: Continue leaderboard rules, shared username and accessibility requirements368–372; then FAQ and Contact in original source order. Preserve exact result/source separation and do not claim Apple runtime verification.
- Commit: containing commit for batch Exact-round-results-and-preserved-source-versions.

## Consistent-game-rules-FAQ-and-shared-username-drafts

- Parent checkpoint: c9906f2b3677ba9ceb790b6b6ca2019481186cb7.
- Source-order requirements: [368, 369, 370, 371, 372, 373].
- Source files: Fruitfolio/Fruit Basket/Prompt28RulesCopy.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Hub/FAQ/Prompt29FAQCatalog.swift, Fruitfolio/Hub/FAQ/Prompt29FAQView.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift.
- Shared canonical gameplay instruction text now distinguishes attached good-fruit badges from standalone protection stars, zero star score/fruit credit, entry/settlement, exact one-pass spending, retry/session pass scope, actual results versus sourced explanation and capture totals versus successful baskets. Leaderboard explains local totals, historical omissions and unavailable worldwide service. FAQ catalog is exact production Foundation data, portable regressions validate unique catalog identities/current rule availability and real engine score/protection behavior. FAQ questions explicitly regular-weight/verbatim. Both Account and game preserve dirty username drafts if the shared authority changes in the other location; confirmation resets with clear feedback; stable field accessibility identifiers added. No global registration or universal real-name detection claim. Existing shared persistence/policy regressions included in full portable suite. Apple UI/observer interactions unrun.
- Tests added/updated: Prompt1BGameRulesCatalogTests, Prompt1BUsernamePersistenceTests, Prompt1BPseudonymPolicyTests.
- Verification: {"Swift6": "447 XCTest +21 Swift Testing passed", "workflow": "18 tests passed", "syntax": "231 changed Swift files parsed; zero errors", "supplemental": "36 exact source requirements retained", "Apple": "NOT_RUN: observer drafts, actual FAQ/rules dynamic text and VoiceOver; no Apple SDK", "native": "Prior actual native-linked suite449+21 passed; current copy/catalog/UI changes do not change native model code"}.
- Next action: FAQ tulip remains unavailable: preserve approved sparkle/no unrelated rain cloud; proceed Contact378–383 shared link-failure modal, focus/Reduce Motion, responsive approved green flecks/plum/sparkles; then next original section.
- Commit: containing commit for batch Consistent-game-rules-FAQ-and-shared-username-drafts.

## Contact-measured-link-failure-modal-and-owned-request-recovery

- Parent checkpoint: d958e4d4c3ee53a7ab8f32ee173b8fedda568e99.
- Source-order requirements: [375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 389, 390].
- Source files: Fruitfolio/Hub/Contact/Prompt30ContactView.swift, Fruitfolio/Hub/Contact/Prompt30ContactDestination.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Core/DesignSystems/FruitfolioHeaderArtwork.swift.
- # Contact link failure and approved composition

The existing founder Instagram, TikTok, email and Carrd destinations are unchanged. Contact uses the existing green flecks, plum and sparkles header palette with the shared responsive protected-region placement. FAQ keeps its existing approved sparkle and omits an unavailable canonical tulip/cloud; no unrelated rain cloud or substitute flower is introduced.

The former system link-failure alert now uses the shared measured taped-white writing aperture, scrollable content, shared blur/dim/Reduce Motion policy and shared button sound/press style. Background art, header and links are excluded from interaction/accessibility while the dialog is visible. The destination remains selectable for copying, with explicit close/Escape and focus requested back to the initiating link. There is no timed dismissal.

The view owns actual request-identity state. A superseded, duplicate or post-disappearance external-app callback cannot present/reopen an obsolete failure. A failed request cannot be replaced by background links behind the modal. Portable regressions exercise the production state and all exact original destinations. A DEBUG-only route injects OpenURLAction.discarded into the actual Contact view inside the normal app shell/disposable preferences, without opening an external service. The added UI regression checks the modal writing area, background exclusion and restored link access at accessibility XXXL in both motion settings.

Apple tests, actual OpenURL completion behavior, VoiceOver focus restoration, smallest-screen rendering and physical app opening are NOT_RUN on Linux. Foundation execution and compiler parsing do not verify these runtime effects. The shared palette was preserved; no claim of rendered artwork inspection is made.

- Tests added/updated: Prompt1BContactDestinationTests, Prompt1BModalAccessibilityTests.testContactFailureUsesMeasuredModalAndRestoresLinkAccess (Apple NOT_RUN).
- Verification: {"nativeSwift5": "453 XCTest +21 Swift Testing passed with final Foundation sources and actual native library", "Swift6": "448 XCTest +21 Swift Testing passed before final additional request-state regression", "syntax": "233 changed Swift files parsed; zero errors", "Apple": "NOT_RUN actual Contact failure UI, OS URL actions, VoiceOver focus and physical artwork layout", "FAQart": "Canonical tulip/cloud absent; approved sparkles retained without substitute"}.
- Next action: Strengthen existing single language preference persistence and explicit-language resolution; keep global selector recognizable/reachable. Wire selected language into remaining dynamic FAQ/Contact/game UI and preserve original scientific/source fields through MADLAD display translation. Official model acquisition/device verification still blocked; continue independent localization and remaining source-order requirements.
- Commit: containing commit for batch Contact-measured-link-failure-modal-and-owned-request-recovery.

## Explicit-selected-language-authority-and-FAQ-display-translation

- Parent checkpoint: 16e52b5c071edb8e2df88393e6222d9454df3f55.
- Source-order requirements: [391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift, Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift, Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift, Fruitfolio/Hub/FAQ/Prompt29FAQView.swift, Fruitfolio/Hub/Contact/Prompt30ContactView.swift.
- # Explicit selected-language authority

SettingsStore remains the one observable app-wide language authority. Its exact injected UserDefaults language load/save implementation is now a Foundation helper shared with portable regressions. The global resolver requires an explicit language; Guide Builder's VoiceOver saved announcement now uses its actual environment SettingsStore instead of independently reading UserDefaults.standard. Root locale/layout direction remain bound to that same published selection. No historical source/saved text is rewritten.

Language is the first Settings section and retains recognizable native names and a permanent multilingual selector label/accessibility identifier. All listed languages remain selectable; a selector entry is not proof that that language has complete reviewed UI strings or verified MADLAD tokenizer/model support. Three Foundation regressions exercise every selector value through actual storage/reinitialization, independent injected suites, unknown-value preservation and RTL mapping. An additional actual Combine SettingsStore publication/reinitialization regression is Apple-only and NOT_RUN here.

FAQ section/question strings and Contact failure labels now resolve through the selected SettingsStore language. FAQ expanded answers use the existing scientific display-translation pipeline, preserving original text and explicit unavailable status. Machine translation is not a clinical review. Fruit Basket's sourced explanations already use that pipeline; its quiz question/options remain atomic original-language source-excerpt practice until jointly verified localization can preserve the answer contract. Translating those fields independently would not establish a valid localized quiz.

The string catalog still contains incomplete/unreviewed non-English entries and stale/missing source keys. Full screen/dialog/error/accessibility coverage, reviewed translations for all requested language families, jointly localized quiz generation, long-source translation and physical-device acceptance remain open. Official MADLAD resources are still blocked by the configured huggingface.co network restriction; no translated runtime output or language quality is claimed. This batch does not replace MADLAD with the Qwen assistant model.

- Tests added/updated: Prompt1BLanguagePreferencesTests, Prompt1BSettingsLanguageTests (Apple NOT_RUN).
- Verification: {"Swift6": "452 XCTest +21 Swift Testing passed", "syntax": "236 changed Swift files parsed; zero errors", "Apple": "NOT_RUN actual SettingsStore publication and UI locale switching; no Apple SDK", "translation": "FAQ display pipeline integrated; no actual MADLAD output/quality verified; full catalog incomplete"}.
- Next action: Continue localization397+ and MADLAD: replace unsafe legacy Qwen catalog auto-translation workflow with actual offline MADLAD/protected-content draft production and review gates; update catalog coverage for changed UI without claiming untranslated strings complete. Continue original-order requirements405+ after independent localization work; actual official weights/tokenizer and device quality remain explicit external blockers.
- Commit: containing commit for batch Explicit-selected-language-authority-and-FAQ-display-translation.

## Actual-offline-MADLAD-catalog-runner-and-unreviewed-recoverable-drafts

- Parent checkpoint: 96c31c93ec431644701ec029905b5dfaf91fe330.
- Source-order requirements: [397, 408, 409, 418, 419, 422, 423, 424, 425, 426, 427, 429, 430].
- Source files: Tools/MADLADCatalogRunner.swift, Tools/translate_catalog_with_madlad.py, Tools/translate_catalog_with_llama.py, Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- # Offline MADLAD catalog draft workflow

The legacy `translate_catalog_with_llama.py` entry point now forwards to the MADLAD workflow. Its old Qwen `--model`, `--llama-cli` and auto-approval `--overwrite` behavior is removed. No existing translations are overwritten or reclassified.

`Tools/MADLADCatalogRunner.swift` compiles the exact application MADLAD runtime, scientific protection, language mapping and translation service against actual native llama archives. One process retains its local model across sequential catalog jobs. It uses no remote inference, network client, Ollama, Ask model or test implementation. Each guarded result is written only to a separate unreviewed draft with source/catalog/manifest/runner hashes. Protected printf specifiers are passed intact into the application's protection envelope. Unsupported target tags, invalid resources, changed scientific information and truncated output remain errors. Raw Swift interpolation/plural variation entries require genuine Xcode extraction and are not translated as literal code.

Build on a host with the Swift compiler and a CPU native CMake build of the vendored llama source (disable optional BLAS/Accelerate/OpenMP backends unless their additional link flags are supplied):

```bash
python3 Tools/translate_catalog_with_madlad.py --build-only \
  --swift /path/to/swiftc --native-llama-build /path/to/llama-build \
  --runner /path/to/MADLADCatalogRunner
```

With the official converted/checksummed model and generated manifest in a local resource directory:

```bash
python3 Tools/translate_catalog_with_madlad.py \
  --runner /path/to/MADLADCatalogRunner \
  --catalog Fruitfolio/Localizable.xcstrings --resources /path/to/resources \
  --draft-output /path/to/catalog-es-drafts.json --locales es --limit 10
```

The output resumes completed entries only when the exact catalog, manifest and runner hashes match. Changed inputs require a separate draft path. It checkpoints every accepted result and records interrupted/failed processing. Source catalogs stay immutable. A successful exit is not linguistic/clinical acceptance; `runtimeVerified` deliberately remains false because this command does not attest installed-resource provenance, device performance or translation quality. Human/clinical review and a separate explicit reviewed merge remain required. No automatic import/approval tool is provided.

Verification here: the real C/Swift runner compiled/linked successfully against the native CPU archives; its actual missing-resource path returned the original-preserving error with no translated value. The actual repository catalog preflight recorded missing `MADLAD400.manifest.json` without starting inference or altering the catalog. Twenty-four workflow tests pass, including six new orchestration tests using an explicitly named fixture executable; those tests do not execute a translation model. The compiler parsed 237 changed Swift files without syntax errors.

Real T5 inference remains **NOT_RUN**: official weights/tokenizer acquisition is denied by the immutable cloud network policy for huggingface.co. In addition, the application manifest verifier currently requires CryptoKit; this Linux toolchain compiles its explicit rejection branch, while actual verified-model execution requires an Apple host with CryptoKit. No Linux CPU compatibility, actual model output, clinical language equivalence or iPhone memory/thermal claim is made. The previous real Qwen research inference is unrelated to MADLAD acceptance. See MADLAD_VERIFICATION.md and BLOCKERS.md for the exact open gates.

- Tests added/updated: development_workflow/tests/test_madlad_catalog_drafts.py, Actual native-linked missing-resource runner execution.
- Verification: {"runner": "Compiled/linked successfully; actual missing-resource guard returned error and no translated value", "catalog": "Missing manifest recorded; inference NOT_RUN and no source catalog writes", "workflow": "24 passed; fixture draft tests are orchestration only", "syntax": "237 changed Swift files parsed; zero errors", "MADLAD": "NOT_RUN actual T5 output: official resources blocked; current Linux branch also rejects checksum verification without CryptoKit", "Apple": "NOT_RUN device inference/UI; no Apple SDK"}.
- Next action: Continue individual/regional language mapping405–410 and translated layout411–417; preserve unsupported target tags as unverified. Then original-order431+ saved media/performance/final requirements. Resolve Linux hash verification limitation with a standard verified implementation if feasible; official MADLAD weights/tokenizer acquisition and actual T5/device/clinical verification remain externally blocked. Never replace with Ask/Qwen or mark machine drafts reviewed.
- Commit: containing commit for batch Actual-offline-MADLAD-catalog-runner-and-unreviewed-recoverable-drafts.

## Streaming-system-checksums-and-real-native-MADLAD-architecture-refusal

- Parent checkpoint: 074786c21dcb542991e06863c22f866e07a4a61f.
- Source-order requirements: [409, 418, 419, 424, 425, 426, 427, 428, 430, 439, 441, 466].
- Source files: Fruitfolio/Core/Translation/FruitfolioModelChecksum.swift, Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift, Tools/run_portable_swift_tests.py, Tools/translate_catalog_with_madlad.py.
- # Portable verified model bytes and native architecture refusal

Model checksum verification now streams through the host's established implementation: CryptoKit SHA256 on Apple and OpenSSL EVP SHA256 in the Linux native runner/test package. No custom cryptography, shell hashing, preverified bypass or full-model Data allocation is introduced. Both branches read bounded 1 MiB chunks, check cancellation and compare the complete digest before native loading. The existing original GGUF header, pinned manifest fields, exact architecture, encoder/decoder and tokenizer-tag checks remain.

The production Foundation checksum path passed known independently computed digest tests, including a payload crossing the 1 MiB read boundary, identical-header content mutation and cancellation of otherwise correct input. Existing LFS pointer/path/hash guards remain. Hash acceptance establishes bytes only; these tiny test fixtures are not executable or approved translation models.

The actual native MADLAD runner and permanent native-linked regression hashed the existing 491,400,032-byte Qwen assistant model, reached the real llama loader, observed qwen2 architecture and rejected it as incompatible before translation. The deliberately wrong architecture fixture exists only in an isolated temporary directory and never changes the supplied model or app resources. It is negative compatibility evidence, not T5 inference, model-origin attestation or translation quality. The standalone native guard also returned no translated value. OpenSSL 3.5.7/system headers were used in this cloud environment; no system package installation was performed.

Final verification: 455 XCTest +21 Swift Testing portable cases passed; 460 XCTest +21 Swift Testing cases passed with actual native libraries, including the permanent wrong-architecture regression. Twenty-four workflow tests pass. The native catalog runner rebuilt successfully. 238 changed Swift files parsed without syntax errors. An initial new cancellation test omitted `try` on its throwing Task value; it was fixed before the complete final suites above.

Actual official T5 offline inference, tokenizer/language quality and device/thermal behavior remain NOT_RUN because official model/tokenizer acquisition is denied by the huggingface.co policy and no Apple SDK/device is available. The earlier Linux CryptoKit-only checksum blocker is resolved; do not repeat it as a current blocker. No success is inferred from these negative checks.

- Tests added/updated: Prompt1BMADLADManifestTests, Actual native catalog-runner wrong-architecture execution.
- Verification: {"Swift6": "455 XCTest +21 Swift Testing passed", "nativeSwift5": "460 XCTest +21 Swift Testing passed; actual wrong-architecture model rejected after checksum", "standalone": "System OpenSSL checksum reached actual Qwen loader; runtime rejected qwen2; no translated value", "workflow": "24 passed", "syntax": "238 changed Swift files parsed; zero errors", "MADLAD": "Official T5 inference NOT_RUN: weights/tokenizer blocked; Apple/device/clinical quality unavailable", "resolved": "Linux CryptoKit-only checksum restriction removed using standard system OpenSSL EVP; no custom crypto"}.
- Next action: Add founder-specified individual Quechua/Guaraní/Aymara selectors and explicit unknown-language preference notice without guessing runtime support or silently replacing stored language; test actual authority. Continue405–417 language/layout work and then431+ preservation/integration requirements. Official T5 resources and Apple/clinical verification remain external blockers; Linux checksum restriction is resolved.
- Commit: containing commit for batch Streaming-system-checksums-and-real-native-MADLAD-architecture-refusal.

## Individual-founder-South-American-languages-and-visible-preference-recovery

- Parent checkpoint: c56a4bcbca6ea061322ef9e327233b0384d29244.
- Source-order requirements: [392, 398, 399, 405, 406, 407, 408, 409, 410, 425, 429, 440].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift, Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift.
- # Individual South American selectors and preserved unknown preferences

Added the founder-specified Quechua (`qu`, Runa Simi), Guaraní (`gn`, Avañeʼẽ) and Aymara (`ay`, Aymar aru) to the existing individual language/autonym architecture. Spanish and Portuguese remain. No generic “South American,” “African” or “Indian” replacement is introduced. This adds selectable stable identities and persistence, not a claim that the installed tokenizer/model has verified those target tags or that each regional variety is equivalent. Actual MADLAD vocabulary checks still gate every request.

Unknown/future or wrong-type stored language data is retained. Settings explicitly discloses the temporary English display fallback and only replaces that stored value after an explicit language assignment. The same published authority records whether review is needed. Settings also explains that unavailable translation leaves the original visible. No saved source, note or measurement is rewritten.

Five portable language tests now cover every individual selector's actual persistence/reinitialization, independent stores, original unknown/wrong-type bytes/objects, explicit recovery and RTL identities. Full portable verification: 457 XCTest +21 Swift Testing passed. The additional actual SettingsStore recovery/publication tests remain Apple-only and NOT_RUN. Compiler parsing covers238 changed files with zero errors. Source/API support is not complete reviewed translation, actual app process restart, dialect validation, or UI/VoiceOver/RTL rendering acceptance. Those gates remain open.

- Tests added/updated: Prompt1BLanguagePreferencesTests, Prompt1BSettingsLanguageTests (Apple NOT_RUN).
- Verification: {"Swift6": "457 XCTest +21 Swift Testing passed", "syntax": "238 changed Swift files parsed; zero errors", "Apple": "NOT_RUN actual SettingsStore observer/recovery and process restart/UI/RTL", "language_support": "Individual selectors/persistence added; actual MADLAD tags/clinical translation not verified without official resources"}.
- Next action: Implement bounded native translation resource lifecycle/memory pressure handling without fake hardware budgets; continue translated-layout411–417 and saved/source preservation431–434 actual regressions. Official T5 weights/tokenizer and device/clinical/per-language acceptance remain externally blocked. Continue remaining integrated changes and exact founder paragraphs without repeating completed broad audits.
- Commit: containing commit for batch Individual-founder-South-American-languages-and-visible-preference-recovery.

## Memory-pressure-translation-pause-and-native-model-release-reload

- Parent checkpoint: d1589239b40a2fa7d3488b10406cce25d36bc5e5.
- Source-order requirements: [419, 425, 426, 427, 428, 429, 430, 431, 432, 433, 434, 441, 466, 475].
- Source files: Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift, Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift, Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift.
- # Owned translation pause and actor-isolated native release

The real app shell observes iOS memory warnings. It sets a transient shared translation pause, which changes display-task identity and cancels outstanding owned translation requests, and requests release from both actual native model actors. The selected language and all persisted content remain unchanged. Paused readers keep already accepted translated text; unfinished/new translated readers show the original and a clear pause message with an explicit shared-style retry action. No timed/automatic retry reloads the model under pressure. The pause is process state, not a new persisted preference.

MADLAD releases sampler, context, vocabulary reference and model in dependency order, clearing stored handles and manifest so retry performs verified resource loading again. Ask releases its context/vocabulary/model without unregistering process-owned backends shared with translation. Actor isolation keeps release outside synchronous native encode/decode; cancellation is checked at existing boundaries. An active native C encode/decode call cannot be preempted immediately by this handler. No physical memory budget, guaranteed OS survival or hardware performance threshold is invented.

The service contract regression exercises explicit release forwarding without source mutation. The real native wrong-architecture regression tolerates repeated empty release before/after refusal. The existing actual research-generation regression now generates from the original corpus, releases twice, reloads and generates again with identical sourced result, then releases; no generated-answer cache or mock supplies the second answer. The full actual native suite passed463 XCTest +21 Swift Testing; portable suite passed458 XCTest +21 Swift Testing. Twenty-four workflow tests pass, and the exact production MADLAD catalog runner rebuilt after the release API addition. Compiler parsing covers238 changed Swift files with zero syntax errors.

Actual SettingsStore transient-pause/language-preservation test, iOS warning delivery, UI task cancellation/focus/retry, and measured native heap return are Apple/runtime gates and NOT_RUN here. Actual allocated T5 release/reload remains NOT_RUN until official resources are available; Ask's real CPU release/reload is not MADLAD proof. Qwen resource release does not cancel an owned Ask request mid-native-call; its actor releases after that call finishes. Native cancellation/physical stress behavior still requires device tests.

- Tests added/updated: Prompt1BTranslationPipelineTests, Prompt1BMADLADManifestTests, Prompt1BResearchEngineIntegrationTests, Prompt1BSettingsLanguageTests (Apple NOT_RUN).
- Verification: {"Swift6": "458 XCTest +21 Swift Testing passed", "nativeSwift5": "463 XCTest +21 Swift Testing passed, including real native generation after release/reload", "runner": "Actual production MADLAD adapter compiled/linked after protocol change", "workflow": "24 passed", "syntax": "238 changed Swift files parsed; zero errors", "Apple": "NOT_RUN memory warning delivery/UI pause/retry, transient SettingsStore test and measured device heap", "T5": "Actual allocated official T5 release/inference NOT_RUN; resources unavailable"}.
- Next action: Centralize saved-page display-translation eligibility/source-language/semantic selection so user-authored pages never auto-translate, full answers cannot accidentally inherit stale excerpt language/spans, and library/Guide/original viewer agree. Add actual storage/source-metadata preservation regression across display translation and language changes. Then continue full integrated verification and remaining exact founder requirements; official T5/device/clinical gates remain blocked.
- Commit: containing commit for batch Memory-pressure-translation-pause-and-native-model-release-reload.

## Shared-saved-display-translation-policy-and-original-storage-boundary

- Parent checkpoint: 2f9d5de4cbdc37cbb4aacf8d83537c7175053235.
- Source-order requirements: [125, 162, 431, 432, 433, 434, 435, 438, 443, 444, 457, 466, 474].
- Source files: Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift.
- # Shared saved display policy and immutable stored content

Library, Guide pages and the Guide original-source viewer now share the saved page's translation eligibility, source language and semantic-span policy. User-authored material is never automatically translated, including an inconsistent legacy record that also contains an original-answer identity. Unattributed pages remain original. Full answers consistently use original English and ignore stale excerpt-language/span metadata; actual saved excerpts retain their recorded display language.

A saved excerpt's semantic spans are used only when their complete plain text exactly matches its actual saved excerpt. Stale/different semantic metadata cannot replace the user's actual saved words, and user-authored material cannot acquire this source-excerpt styling. Mismatched metadata is retained unchanged in storage and simply not used for display. This is a display policy, not a source-data migration or guessed historical language correction.

Four new source regressions exercise full-answer versus excerpt behavior, conflicting user provenance, stale semantic refusal and the actual UserDefaults saved-library persistence boundary. The last test uses an explicitly named translation fixture that changes ordinary prose while retaining protected units/citations; switching Spanish, Arabic, Quechua and English leaves the exact persisted document bytes, original answer, user note, citation records and per-source versions unchanged after reinitialization. This is not proof of actual MT quality. Existing actual Ask rendering already waits until validated answer/typewriter completion before starting display translation; the targeted check found that guard and does not replace it.

Final full suites:462 XCTest +21 Swift Testing portable;467 XCTest +21 Swift Testing with real native libraries, including unchanged genuine native release/reload generation. Compiler parsed239 changed Swift files with zero syntax errors. Apple source-view layout/VoiceOver/selection and language-switch runtime remain NOT_RUN. Actual official MADLAD T5 offline output and clinical/per-language acceptance are still blocked by missing official resources and the Apple/device gate.

- Tests added/updated: Prompt1BSavedTranslationBoundaryTests.
- Verification: {"Swift6": "462 XCTest +21 Swift Testing passed", "nativeSwift5": "467 XCTest +21 Swift Testing passed", "syntax": "239 changed Swift files parsed; zero errors", "storage": "Actual UserDefaults saved bytes and reinitialized original source/citation/note metadata unchanged across fixture display translations/preferences", "Apple": "NOT_RUN saved display/selection/VoiceOver and complete per-language app acceptance", "MADLAD": "Official T5 inference/clinical quality NOT_RUN; fixture tests are storage/display policy only"}.
- Next action: Continue435–442 actual translation acceptance gates and443–478 remaining independent source/test fixes. Preserve runtime blockers explicitly. Reconcile remaining founder prose requirements against current implementation without repeating broad source audits; address independent production ownership verification and recovery/testing gaps when applicable. All unknown/MADLAD resource/device/clinical gates remain unverified, no push.
- Commit: containing commit for batch Shared-saved-display-translation-policy-and-original-storage-boundary.

## Actual-game-UI-scenarios-accessible-star-cues-and-serious-failure-feedback

- Parent checkpoint: 360052df7c2844ec39a22982bab7b6cb8c46d963.
- Source-order requirements: [325, 327, 338, 346, 347, 366, 367, 368, 369, 370, 372, 388, 390, 443, 444, 447, 448, 449, 462, 463, 468, 469, 470, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketModels.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- # Actual Fruit Basket UI scenarios and capture source

A DEBUG-only route now presents the production Fruit Basket view/controller inside the real root environment. Deterministic nonclinical fixtures expose good-fruit classification, a standalone star, storm note, seven-fruit failure, ten-fruit success, rules and leaderboard. Actual entry/settlement, engine, round ledger and finalization produce the result states. No fake medical material or results enter production research.

Game progress, username and even the reveal save destination use the same disposable QA-owned defaults suite; the normal route keeps the existing shared authorities. An owned StateObject fixture holds suite lifetime consistently through root redraws. It requests cleanup on disappearance; OS termination cannot guarantee disappearance delivery, so leftover QA suites may remain isolated under the random QA prefix. No fixture is written to the user's normal library.

Classification now exposes actual fruit/target/pass progress as readable text and a stable accessibility target. Its fruit description announces whether the visible attached star marker is present, preserving equivalence with the visual cue without confusing it with a standalone protection star. Stable catch/pass/result identifiers support actual UI assertions. Unsuccessful sensitive-education rounds now use neutral feedback/no Peach face and no playful point-loss line; ordinary founder copy remains.

Four added Apple UI test methods exercise actual classification awards, exact failed/successful result counts, storm modal exclusion/acknowledgment, and portrait/landscape rules/leaderboard capture at accessibility XXXL, with motion settings covered. Actual screenshot attachments are generated only when those tests run and are kept in the xcresult. No screenshots have been fabricated or claimed here. Badge visibility, alpha registration, artwork placement, VoiceOver focus and device feel still require rendered inspection.

Available verification:462 portable XCTest +21 Swift Testing passed;467 actual native-linked XCTest +21 Swift Testing passed, including the updated serious feedback assertion. Twenty-four workflow tests pass. Compiler parsed240 changed Swift files with zero errors. Xcode project build-file references parse/resolve. ALL added Apple UI/capture routes remain NOT_RUN on Linux; parser/reference checks are not app typechecking, linking or runtime acceptance.

- Tests added/updated: Prompt1BModalAccessibilityTests (four actual-game UI methods, Apple NOT_RUN), Prompt1BFruitBasketResearchTests.
- Verification: {"Swift6": "462 XCTest +21 Swift Testing passed", "nativeSwift5": "467 XCTest +21 Swift Testing passed", "workflow": "24 passed", "syntax": "240 changed Swift files parsed; zero errors", "project": "Build-file references resolved; no Xcode build/link", "Apple": "NOT_RUN four game UI tests and all screenshots/VoiceOver/landscape/motion effects; app typecheck unavailable"}.
- Next action: Make Mac runtime preflight check the requested simulator/device architecture without unnecessarily requiring an iPhone slice for simulator tests; retain strict both-platform release gate. Preserve unrun Apple screenshot/UI status. Then continue remaining independent verification/source failures and founder applicability reconciliation; do not stop at this batch.
- Commit: containing commit for batch Actual-game-UI-scenarios-accessible-star-cues-and-serious-failure-feedback.

## Destination-specific-Apple-test-preflight-with-strict-release-coverage

- Parent checkpoint: c6dcdd1c5af03b996191c795ce483bceeff08ec6.
- Source-order requirements: [409, 441, 466, 468, 469, 476, 477, 478].
- Source files: Tools/verify_apple_runtime.py, Tools/verify_prompt1b_mac.sh.
- # Destination-specific Apple test preflight

The Mac test script now checks the actual requested destination: an iOS Simulator run needs a declared simulator slice for its selected host architecture, while a physical-device run needs iOS arm64. A simulator test is no longer blocked solely because a device slice is absent. The standalone verifier's default remains the strict release gate requiring both device and simulator. Missing/escaping declared artifacts remain errors regardless of requested target; invalid/empty requested coverage cannot disable validation.

The Mac script records the exact xcresult path before launching tests so failures leave a findable recovery artifact. Simulator architecture defaults to `uname -m` and can be explicitly supplied with FRUITFOLIO_SIMULATOR_ARCHITECTURE when needed. The target check inspects metadata and artifact existence; it never claims Mach-O compatibility, SDK linkage, execution or inference.

Verification:29 workflow tests passed, including five added destination/architecture/strict-release/path-escape cases using explicit metadata fixtures. `bash -n Tools/verify_prompt1b_mac.sh` passed. Actual simulator and strict-release commands both correctly report missing configured `Fruitfolio/Frameworks/llama.xcframework` in this workspace (expected exit2). The preserved original framework is simulator-only; the supplied Mac build script still needs to create the configured XCFramework. No native artifacts were synthesized or substituted. Xcode/iOS UI tests, captures and physical-device acceptance remain NOT_RUN. The last unchanged Swift app suite remains462 portable and467 native-linked XCTest +21 Swift Testing each.

- Tests added/updated: development_workflow/tests/test_apple_runtime_packaging.py.
- Verification: {"workflow": "29 passed", "shell": "Syntax check passed", "actual_metadata": "Both commands correctly fail: configured llama.xcframework is absent; original preserved framework simulator-only", "Swift": "Unchanged since prior462 portable/467 native XCTest +21 Swift Testing passed; no redundant rerun", "Apple": "NOT_RUN Xcode build/link/UI/screenshots; destination fixtures are metadata checks only"}.
- Next action: Strengthen explicit full-citation/DOI literal protection in display translation, passing actual source records from Ask/saved/Guide/game while keeping original citations/metadata separate. Use immutable request snapshot parameters. Continue independent requirement fixes and remaining founder applicability; Apple configured framework/Xcode and official MADLAD resource gates stay explicit.
- Commit: containing commit for batch Destination-specific-Apple-test-preflight-with-strict-release-coverage.

## Full-bibliographic-literal-protection-and-immutable-translation-request

- Parent checkpoint: e32ff31b5fdfdc8a95f422b3a960a8302231ead6.
- Source-order requirements: [125, 162, 421, 422, 423, 424, 431, 432, 433, 434, 438, 443, 444, 466, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioCitationProtection.swift, Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderComponents.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderPopups.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Hormone Information/HormoneLibraryView.swift.
- # Full bibliographic literals and immutable translation requests

Display translation now derives protection from actual source records as well as citation IDs: exact original APA/source text, its semantic-escaped representation, bare DOI identifiers and source URLs remain verbatim. Ordinary source-title words/concepts are deliberately not frozen everywhere in prose. Duplicate/empty literals are removed without altering attribution spelling, case or metadata. Existing numeric/unit/reference/order checks remain.

Ask's current and historical answers, saved Library pages, Guide pages/original-source viewers, Fruit Basket explanations and Hormone Library excerpts pass their actual source records into the common display wrapper. The wrapper's task key includes the resulting literals, and the service receives the captured request's source/literals/language rather than separate live property lookups. No original source record, answer, user note or measurement is rewritten.

Three new portable regressions use an explicitly named text-changing fixture to verify that ordinary prose may change while complete APA author/title text and a bare DOI remain exact, escaped citation variants round-trip, duplicates stay stable, ordinary concept titles stay eligible for translation, and legacy records do not acquire invented attribution. These are protection-pipeline tests, not model/clinical equivalence tests.

Verification:465 portable XCTest +21 Swift Testing passed;470 actual native-linked XCTest +21 Swift Testing passed. Compiler parsed242 changed Swift files without syntax errors. Apple display/source-record propagation and actual selected-language UI remain NOT_RUN. Official MADLAD T5 output, linguistic/clinical equivalence and offline device behavior remain blocked by missing official resources and the Apple/device gate. Literal preservation cannot prove absence of semantic/negation errors; those review gates remain open.

- Tests added/updated: Prompt1BCitationTranslationTests.
- Verification: {"Swift6": "465 XCTest +21 Swift Testing passed", "nativeSwift5": "470 XCTest +21 Swift Testing passed", "syntax": "242 changed Swift files parsed; zero errors", "citation": "Full APA/bare DOI/escaped citation guards tested with fixture; actual source metadata unchanged", "Apple": "NOT_RUN source propagation and UI language handling", "MADLAD": "Official T5 output/clinical semantic equivalence NOT_RUN; literal fidelity alone is insufficient"}.
- Next action: Continue independent source/test gaps; investigate the existing ownership check stub as an applicable founder paid-app requirement and integrate real StoreKit AppTransaction verification without adding a paywall or fake purchased state. Preserve existing architecture/data, gate Apple runtime acceptance, and keep auth/sync and official MADLAD/clinical gates explicit. Reconcile remaining founder prose requirements as work continues.
- Commit: containing commit for batch Full-bibliographic-literal-protection-and-immutable-translation-request.

## Optional-real-StoreKit-app-ownership-with-owned-task-and-original-record-protection

- Parent checkpoint: 1424ad297e01b6ae719ba1be5e97c0e8d96db877.
- Source-order requirements: [443, 444, 467, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/FruitfolioOwnershipVerification.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift, Fruitfolio/Privacy Settings/Prompt12OwnershipView.swift.
- # Real optional StoreKit app-transaction adapter

The existing ownership check now calls StoreKit AppTransaction.shared and accepts only a verified app transaction matching this app's bundle identifier. Production and sandbox/Xcode test installations are distinct; unknown environments, invalid signatures/wrong apps, unavailable records and platform errors do not become verified production status. Test installations have an explicit test-only display state. No IAP product, purchase dialog, subscription, backend receipt upload, account prerequisite or second paywall is added. Existing installed paid-app access/default policy and canonical design price are preserved; app-transaction validation does not independently establish an actual charged amount.

The actual observable store owns/coalesces the task, recovers a persisted interrupted `validating` state as unavailable, and suppresses canceled/reset/late results. Unreadable original account/settings bytes are preserved when checking ownership. A sequential raw-byte fingerprint prevents the asynchronous completion from resurrecting a cleared record or overwriting a newer writer. It is not a cross-process atomic transaction or a general migration of the existing account persistence implementation. The legacy markPurchasedForInstalledApp entry point now invokes verification instead of creating a new unverified record.

Three portable tests execute the production record policy and actual Linux unavailable adapter. Three additional actual-store/continuation tests exercise coalescing, test-state persistence, corrupt/cleared/newer-record preservation and reset cancellation; these are Apple/Combine-only and NOT_RUN here. The production StoreKit API branch itself also requires Apple SDK compilation and signed receipt/sandbox/device execution; none is claimed verified by Linux tests. No real receipt was fabricated or used by a fixture.

Available verification:468 portable XCTest +21 Swift Testing passed;473 actual native-linked XCTest +21 Swift Testing passed;246 changed Swift files compiler-parsed without syntax errors. Actual Foundation ownership models now compile in those portable targets. Auth/cloud sync still have no configured service. StoreKit is now source-integrated and awaits Apple API/transaction verification, rather than an authentication backend.

- Tests added/updated: Prompt1BOwnershipRecordPolicyTests, Prompt1BOwnershipValidationTests (Apple/Combine NOT_RUN).
- Verification: {"Swift6": "468 XCTest +21 Swift Testing passed", "nativeSwift5": "473 XCTest +21 Swift Testing passed", "syntax": "246 changed Swift files parsed; zero errors", "Apple": "NOT_RUN StoreKit API typecheck/real transactions and three Combine-owner regressions", "ownership": "Production/test/wrong-bundle/signature policy tested; no real receipt/charge verification claimed", "services": "Auth/cloud backend still absent; actual StoreKit source adapter now integrated independently"}.
- Next action: Fix actual shared FruitPopupHost coverage: source inspection found its Hub/global requests lacked the common blur and the root did not host popups across all routes. Move hosting to the real root with nested-host suppression, shared blur/dim/Reduce Motion and background AX/hit exclusion. Replace remaining source-citation system alert through a measured white-paper global popup with owned late-link callbacks and UI regression capture. Preserve existing Hub tour and character art/default behavior; do not rebuild app.
- Commit: containing commit for batch Optional-real-StoreKit-app-ownership-with-owned-task-and-original-record-protection.

## Actual-root-and-native-popup-scope-with-owned-citation-dialog

- Parent checkpoint: 418c37b72feb12d9e6c0dfc2c800e6ca0a178437.
- Source-order requirements: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 125, 162, 388, 390, 443, 444, 445, 446, 447, 449, 468, 469, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/PopupCoordinator.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift, Fruitfolio/Fruit Popup Engine/FruitPopupModels.swift, Fruitfolio/Core/DesignSystems/FruitfolioSourceCitationList.swift, Fruitfolio/Core/DesignSystems/FruitfolioCitationRegressionHarness.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- # Real root/native-surface popup scope and original citations

Targeted citation failure work exposed an actual gap: FruitPopupHost existed in Hub/gallery but did not apply the shared blur itself, and other root routes had no host. The real root now wraps the existing NavigationStack with that same host. A scoped environment flag suppresses nested Hub/gallery hosts, preserving the existing character artwork, placement, queue and timing instead of rebuilding them or rendering duplicate dialogs. The host now owns shared blur/dim, no spatial scale under Reduce Motion, whole-content hit/VoiceOver exclusion, and modal accessibility traits.

Native Guide read-mode covers and Hormone Library sheets receive a presentation-surface host with its own coordinator. This prevents dialogs from rendering behind UIKit presentations or replaying sounds in root and modal hosts. The same host implementation handles both scopes. A new taped-white request surface uses the existing measured artwork/writing aperture, scroll, explicit actions, shared style/sounds and safe Escape dismissal. It renders no fruit character for the source-link error. Existing character speech remains the default. Root and native presentation/VoiceOver geometry remain Apple-runtime gates.

The last citation-link system alert is replaced by the owned white-paper request. Original citation titles, full APA/source text (when distinct from the title), publication data, DOI and URL remain verbatim/selectable. A late/superseded/disappeared source component cannot intentionally issue an obsolete request; owner disappearance/source changes cancel its current/queued request. Focus is requested back to a still-existing source button after dismissal. No clinical meaning, reference spelling or user data is rewritten.

The new queue-cancellation regression initially exposed a real defect: removing a queued request failed to remove its deduplication key, preventing retry. Cancellation now uses the existing key cleanup routine. Seven actual production coordinator tests execute on Linux after removing unnecessary SwiftUI imports and conditionally enabling only the real Combine observation layer on Apple. No fake ObservableObject/Published implementation or mirrored coordinator is used. Four pre-existing synchronous MainActor methods were made async for Linux XCTest discovery; assertions remain. A real Combine publisher regression is Apple-only and NOT_RUN.

Added actual UI source covers one nested root character popup, one measured citation popup, background exclusion/restoration, source controls and screenshots at accessibility XXXL in both motion settings and native-sheet/root scope. Corrected four invalid/redundant element firstMatch query forms in UI source. All added UIKit/SwiftUI tests and screenshots remain NOT_RUN. No visual, focus, sound or native-sheet layering success is inferred from source parsing.

Final available verification:475 portable XCTest +21 Swift Testing passed;480 actual native-linked XCTest +21 Swift Testing passed. Twenty-nine workflow tests pass;248 changed Swift files compiler-parse without syntax errors; Xcode project build-file references resolve. The configured XCFramework/Xcode and actual MADLAD resources/clinical/device acceptance remain external gates. Metadata/algorithm tests do not establish app typechecking or UI runtime behavior.

- Tests added/updated: Prompt06FruitPopupTests (7 actual core cases portable; Combine publisher case Apple NOT_RUN), Prompt1BModalAccessibilityTests (nested host/citation root+native scope UI NOT_RUN).
- Verification: {"Swift6": "475 XCTest +21 Swift Testing passed after queued dedup cancellation fix", "nativeSwift5": "480 XCTest +21 Swift Testing passed", "workflow": "29 passed", "syntax": "248 changed Swift files parsed; zero errors", "project": "Build-file references resolve; no Xcode build/link", "Apple": "NOT_RUN observation publisher/UI/sound/focus/native-sheet geometry and actual screenshots", "scope": "Production coordinator decision code executed; conditional Combine observation and SwiftUI host require Apple verification"}.
- Next action: Continue independent UX/source gaps: Data Management currently displays implementation-phase/coordinator language and only a deletion notice. Replace technical placeholder copy with truthful actionable feature-specific management options reusing existing actual deletion flows, without falsely claiming global deletion or export. Preserve privacy/data and native modal scopes; then remaining founder applicability/verification gaps. Do not stop between batches.
- Commit: containing commit for batch Actual-root-and-native-popup-scope-with-owned-citation-dialog.

## Tracker evidence correction after root popup scope batch

The root-popup batch accidentally attached its general evidence to original rows7/8/10 (gray/red button replacement and specifically Cycle Tracker buttons). Those three rows are restored from parent418c37b; their original descriptions and prior evidence are unchanged. Root/native host blur, shared paper composition and coordinator evidence remain on their actual applicable rows. This correction does not claim any new Cycle Tracker button or gray/red replacement in that batch.

## Truthful-data-management-measured-popup-and-actual-account-store-recovery

- Parent checkpoint: 1f218bf7f50441ee728414469228f3d42e8d82c2.
- Source-order requirements: [13, 14, 16, 17, 18, 19, 20, 23, 24, 386, 387, 390, 394, 395, 443, 444, 467, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementRegressionHarness.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift, Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- # Truthful data management, actual store regressions and measured popup

The Data screen no longer claims a data document is ready after creating only a metadata summary. It links to the working Hormone Information JSON exporter and to existing books, Guide organization, cycle-record and measurement management; Settings also supplies the actual My Context entry. No item is deleted merely by opening these options. Ask-session data is not advertised as a stored/exportable cache. A combined export remains open implementation work; its legacy method now reports unavailable without creating a false readiness record.

Remote account deletion no longer clears a local record and calls that remote success. With no configured account service it reports unavailable and preserves the local identity/pending edits. On loading, stored authenticated/in-flight/deletion flags are not treated as a new verified session/remote acknowledgment; local identity and raw saved bytes remain. Synced/syncing flags cannot establish present cloud availability. Existing installed paid-app access remains independent.

The actual account/privacy store now compiles as the same Foundation implementation on Linux, conditionally enabling real Combine observation only on Apple. No fake observation library or copied control-flow implementation is used. Eight actual store tests and three actual owned-verification tests now run, in addition to three restoration-policy tests. They verify original identity/bytes, unavailable exports/deletion, pending edits, coalesced verification, corrupt/cleared/newer state refusal and late reset suppression. MainActor tests were made async for actual Linux XCTest discovery. StoreKit signature validation and Combine publication remain Apple gates.

The popup uses the existing measured taped-white aperture and its scroll view, removing the fixed280-point/320-point minimum frame. Popup sections no longer layer separate coded cards inside the paper. Compact shared control sizing reduces blank padding while retaining15-point Dynamic Type labels and a44-point minimum target; ordinary control sizing remains. Body prose uses the existing selected-language display pipeline and thirteen-point scalable text. The actual Data UI regression source checks available actions, no fake readiness, management options, background isolation and Close at accessibility XXXL in both motion settings. UI/screenshot/actual route/file-export acceptance is NOT_RUN here.

Final verification:489 portable XCTest +21 Swift Testing passed;494 actual native-linked XCTest +21 Swift Testing passed. Twenty-nine workflow tests pass;251 changed Swift files parse without syntax errors. The three erroneous root-popup evidence attachments to unrelated rows7/8/10 were restored from their original parent; original478 descriptions are unchanged. These test-case counts are not checklist acceptance; app/clinical/MADLAD/device gates and remaining implementation work stay open.

Restored-file model check found only the existing executable Qwen model plus vendor vocabulary fixtures in accessible workspace/temporary files, and no tracked model paths in the other existing repository. No runnable official MADLAD model was recovered. The root-private HF cache was inaccessible and was not retried; the accessible workspace remains usable. No blocked-domain network attempt or alternate-source substitution was performed.

- Tests added/updated: Prompt1BAccountRestorationPolicyTests, Prompt12AccountPrivacyStoreTests, Prompt1BOwnershipValidationTests, Prompt1BModalAccessibilityTests.testDataManagementUsesMeasuredPaperAndTruthfulAvailableActions (Apple NOT_RUN).
- Verification: {"Swift6": "489 XCTest +21 Swift Testing passed", "nativeSwift5": "494 XCTest +21 Swift Testing passed", "workflow": "29 passed", "syntax": "251 changed Swift files parsed; zero errors", "account": "Actual UserDefaults/async store tests now run on Linux; no fake observation/receipt implementation", "Apple": "NOT_RUN Data popup/compact control rendered layout, actual navigation/export, Combine observers and real StoreKit branch", "open_source": "Combined saved-data/image export remains unimplemented; legacy helper cannot claim readiness", "MADLAD": "No runnable official model recovered in accessible workspace; official download remains blocked, private root cache not retried"}.
- Next action: Fix duplicate soft-pop ownership at callers of the canonical control pill (including Contact/Ownership/Account and actual other matching actions); preserve distinct popup-open/close cues. Inspect exact callbacks with AST or targeted source, add actual AudioManager DEBUG invocation/playback evidence UI source without pretending physical playback on Linux. Then harden account persistence against corrupt/future/stale writes and implement actual bounded local combined export rather than leaving a metadata-only placeholder. Official T5/Apple/clinical gates remain unverified.
- Commit: containing commit for batch Truthful-data-management-measured-popup-and-actual-account-store-recovery.

## Canonical-control-sound-ownership-and-opt-in-real-playback-diagnostics

- Parent checkpoint: a933a3f47029a043707f2c094db135315c694fe1.
- Source-order requirements: [9, 10, 11, 12, 389, 443, 444, 446, 465, 467, 468, 469, 472, 475, 476, 477, 478].
- Source files: Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Core/Assets/AudioManager.swift, Fruitfolio/Core/Assets/FruitfolioInteractionSoundDiagnostics.swift, Fruitfolio/Hub/Contact/Prompt30ContactView.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Ask/Prompt09AskView.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12ConfirmationPopup.swift, Fruitfolio/Privacy Settings/Prompt12OwnershipView.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Tools/normalize_control_sound_ownership.swift.
- # One canonical press cue and distinct popup cues

The existing canonical pill owns its press sound. Actual SwiftSyntax analysis found ten immediate caller duplicates in Ask, Cycle Tracker Daily Log/Today, Account, confirmation, ownership and saved pages. Those extra calls are removed without changing their actions, source labels, navigation or other cue types. Contact's indirect canonical-button callback had an eleventh duplicate and is corrected separately. Raw Button actions retain their own feedback. This is a bounded check of verified control types/direct callbacks, not a claim that every indirect interaction has been runtime-tested.

`Tools/normalize_control_sound_ownership.swift` uses the installed toolchain's real SwiftParser/SwiftSyntax. It checks exact immediate closure statements, preserving strings/comments, nested raw buttons, other sounds, UTF-8, source permissions and semicolon neighbors. All files parse before applying any change; a changed captured source is rejected. Six executable tool regressions passed. A second check of all app Swift sources reports zero remaining immediate duplicates for the seven verified owner types. The removal inventory is in RUN_LOGS/Control-sound-ownership-removals.json.

Contact's measured failure popup and the game storm note now have distinct open/close cues; repeated dismiss calls do not replay close. Contact Escape does not invent another button press. Buttons keep immediate action execution; no debounce delay was added. The compact control target also uses the shared minimum-hit-target token.

The actual AudioManager has opt-in DEBUG counters for three interaction cues only. Ordinary debug/release operation does not record interaction traces; nothing is persisted or sent. Requested calls and successful AVAudioPlayer.play() starts are separate. The Contact regression route enables this explicitly, displays the appropriate in-modal/outside diagnostic panel and tests one press cue plus mute behavior. A real AudioManager unit test covers opt-in/muted tracing. Both those Apple/AVFoundation test cases remain NOT_RUN; software play success would still not prove physical audibility/listening quality.

Available verification:35 workflow tests passed, including all six real SwiftSyntax regressions;489 portable XCTest +21 Swift Testing passed;494 actual native-linked XCTest +21 Swift Testing passed. Compiler parsed253 changed Swift files without syntax errors. Original soft-pop/open/close MP3 assets fully decoded with ffmpeg with no errors; ffprobe durations are2.136s/0.744s/0.417938s. Original resource hashes/metadata are recorded in RUN_LOGS/Interaction-cue-asset-decode.json. Decoding is not app-bundle or device playback acceptance. Actual tap latency, perceived mix, motion and audio remain Apple/device gates.

To build the source checker, use the Swift compiler with its matching `usr/lib/swift/host` imports/libraries, link SwiftSyntax/SwiftParser and set a writable module-cache path. `--check` reports/fails on findings, `--apply` removes only verified redundant statements, and the default is report-only. Run workflow tests with FRUITFOLIO_SWIFTC set to that compiler so these checks execute rather than skip when Swift is absent from PATH.

- Tests added/updated: development_workflow/tests/test_control_sound_ownership.py, Prompt1BAudioSettingsTests.testInteractionDiagnosticsAreOptInAndMuteDoesNotBecomePlaybackEvidence (Apple NOT_RUN), Prompt1BModalAccessibilityTests.testContactButtonOwnsOneSoftPopAndMutePreventsSoftwarePlayback (Apple NOT_RUN).
- Verification: {"Swift6": "489 XCTest +21 Swift Testing passed", "nativeSwift5": "494 XCTest +21 Swift Testing passed", "workflow": "35 passed, including6 real SwiftSyntax tool regressions", "sound_source": "10 direct duplicate cues removed by AST plus1 indirect Contact cue; actual supported direct owner check clean", "assets": "Three original MP3 files fully decode; durations/hashes logged; no resource edits", "syntax": "253 changed Swift files parsed; zero errors", "Apple": "NOT_RUN AVAudioManager/Contact sound counts, actual playback/mix/listening and tap/motion acceptance; decode is not device proof"}.
- Next action: Fix explicit selected-language bundle lookup: current Foundation resolver uses String(localized:locale:) whose locale primarily formats rather than selecting a resource language. Resolve the actual requested lproj table with source fallback, verify with real temporary localization bundles on Linux, then port exact SettingsStore preferences/allow-audio policy without fake Combine observation so mute/language persistence tests can execute. Continue account snapshot hardening and actual combined local archive export afterward.
- Commit: containing commit for batch Canonical-control-sound-ownership-and-opt-in-real-playback-diagnostics.

## Explicit-selected-language-resource-resolution-and-real-settings-tests

- Parent checkpoint: 975608cce45ee3cbc6ee3b5b3eb9c66379bd04bd.
- Source-order requirements: [392, 393, 395, 398, 408, 466, 467, 476, 477].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift, Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Tools/run_portable_swift_tests.py.
- Explicit runtime localization now opens the exact selected-language lproj table rather than relying on the formatting locale of String(localized:locale:). No other language or Chinese script is borrowed when a key is absent. English may use Base only for an English/unspecified development language. Missing/blank translations preserve the supplied source fallback exactly. Bundle injection permits real Foundation resource-table tests without changing production defaults.

SettingsStore now keeps its genuine Combine observation on Apple while compiling its identical preference/control-flow implementation on Foundation-only platforms. There is no Linux mock observable wrapper. Existing language persistence/recovery/memory-pressure tests now execute against the actual store; Apple publisher assertions remain conditional and unexecuted here. Tests exercise repeated en/es/ar resource lookup, script separation, Base safety, scientific fallback literals, four independent audio choices under global mute and persisted volume bounds. These fixtures do not prove that the app catalog contains complete or clinically reviewed translations; compiled iOS catalog lookup and UI behavior remain Apple gates.
- Tests added/updated: Prompt1BExplicitLocalizationTests, Prompt1BSettingsLanguageTests.
- Verification: {"Swift6": "498 XCTest +21 Swift Testing passed", "nativeSwift5": "503 XCTest +21 Swift Testing passed", "workflow": "35 tests passed, all6 SwiftSyntax cases executed", "syntax": "254 Swift files parsed,0errors; Xcode references resolved, not built", "Apple": "NOT_RUN compiled iOS catalog, publisher observation, UI/RTL/device translation acceptance"}.
- Next action: Add languages explicitly named in founder source lines352–359 that are missing from the shared enum: Thai, Mongolian, Indonesian, Russian, Polish, Dutch, Swedish, Ukrainian, Turkish, Kurdish and Hebrew. Preserve autonyms/preference raw values, apply Hebrew RTL and explicit Kurdish script semantics, verify persistence/manifest compatibility without asserting official model inference. Then continue general account-snapshot write protection and actual combined local export.
- Commit: containing commit for batch Explicit-selected-language-resource-resolution-and-real-settings-tests.

## Explicit-founder-Asian-European-Middle-Eastern-language-selectors

- Parent checkpoint: 7ca47cd67588dbdcdab231d68967b09c8f99df31.
- Source-order requirements: [391, 392, 398, 401, 402, 403, 407, 408, 409, 410, 466, 467, 476, 477].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioLanguage.swift.
- Added the explicitly named missing founder languages from source lines352–359 to the existing shared selector: Thai, Mongolian, Indonesian, Russian, Polish, Dutch, Swedish, Ukrainian, Turkish, Hebrew, and separate Kurdish Kurmanji/Sorani choices. Existing persisted codes remain unchanged. New codes are th/mn/id/ru/pl/nl/sv/uk/tr/he/ku/ckb with recognizable native labels. Hebrew and Sorani use RTL; Kurmanji retains Latin layout. All existing selector/preference loops now exercise the additions against actual UserDefaults and SettingsStore. A real translation-service contract fixture records twelve distinct forwarded tags; it is not evidence of model output or clinical translation quality. The production runtime continues requiring the exact target tag in the installed validated manifest. Official model support remains unverified because its artifacts are unavailable. Full static catalog coverage and Apple typography/RTL acceptance remain open.
- Tests added/updated: Prompt1BLanguagePreferencesTests, Prompt1BSettingsLanguageTests, Prompt1BTranslationPipelineTests.testNewFounderSelectorsForwardDistinctModelTagsWithoutClaimingSupport.
- Verification: {"Swift6": "500 XCTest +21 Swift Testing passed", "syntax": "254 Swift files parsed,0errors", "model": "New target tags forwarded by actual service with contract fixture only; official tokenizer/inference/quality NOT_VERIFIED", "Apple": "NOT_RUN new-script UI/RTL, font/accessibility and compiled catalog acceptance"}.
- Next action: Protect actual account/privacy persistence against unreadable, unknown-version/unknown-field, cleared and stale records across every mutator; persist the lock-screen privacy preference immediately; expose a measured recovery notice and read-only reload without overwriting originals. Test real UserDefaults and actual store, then implement actual combined local saved-data/image export.
- Commit: containing commit for batch Explicit-founder-Asian-European-Middle-Eastern-language-selectors.

## Account-snapshot-preservation-and-immediate-privacy-preference-persistence

- Parent checkpoint: bd5427d670454fc2a2c87d93d488cf322e231c28.
- Source-order requirements: [443, 444, 467, 468, 471, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift, Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift, Fruitfolio/Privacy Settings/Prompt12PrivacyView.swift, Fruitfolio/Privacy Settings/Prompt12OwnershipView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementRegressionHarness.swift.
- Account/privacy persistence now captures the exact original UserDefaults object and checks it before every account mutation/write. Unreadable/wrong-type records, unknown root/nested account/export fields and future schema keys are retained read-only rather than decoded-and-truncated or replaced with defaults. Later cleared/newer values are protected from stale writers. This is a synchronous single-store guard, not cross-process transactional locking. Ownership asynchronous generation/result guards remain intact. Lock-screen privacy changes persist immediately; rejected changes revert the displayed value. An explicit reload cancels old verification ownership, reads the latest record without writing and restores safe local/session state. Unreadable records remain protected after reload.

The existing Account, Privacy, Ownership, Settings and Data Management pages show a shared inline notice with a canonical reload button. Privacy/ownership controls are disabled when protected; navigation and independent features remain available. DEBUG Data Management QA can inject corrupt bytes only into its private suite. A new measured-paper/large-text UI case checks that reload remains available and does not trap the user; Apple UI execution is NOT_RUN.

Four actual-store Foundation regressions exercise all mutators against corrupt/wrong-type records, future root/nested fields, stale/cleared records, explicit read-only reload and immediate privacy-toggle persistence. Original values/bytes are compared exactly. The entire portable suite passed504 XCTest +21 Swift Testing;35 workflow tests passed with all6 SwiftSyntax cases executed. No auth/cloud service is invented. Actual Apple Combine publication, UI interaction and production receipt behavior remain separate gates.
- Tests added/updated: Prompt1BAccountPersistenceTests, Prompt1BOwnershipValidationTests, Prompt1BModalAccessibilityTests.testUnreadableAccountNoticeCanReloadWithoutBlockingLocalDataNavigation (Apple NOT_RUN).
- Verification: {"Swift6": "504 XCTest +21 Swift Testing passed", "workflow": "35 passed with6 actual SwiftSyntax cases", "Apple": "NOT_RUN inline recovery UI, large text/VO and Apple publishers; unit byte preservation is executed", "syntax": "257 Swift files parsed,0errors; no Apple typecheck"}.
- Next action: Implement actual combined local data/image export. Capture only explicitly enumerated saved app preference records and known cycle files, preserve original saved page/guide/notes/source bytes and local images, exclude unsaved Ask transcripts and model/research bundles. Produce a real portable archive, independently validate archive payloads and failure/cancellation cleanup, connect actual file export UI without metadata-only success.
- Commit: containing commit for batch Account-snapshot-preservation-and-immediate-privacy-preference-persistence.

## Actual-scoped-local-data-and-referenced-image-ZIP-export

- Parent checkpoint: 16bcac00f6b982c94554a41d0c9dfd5398569302.
- Source-order requirements: [123, 443, 444, 467, 468, 469, 474, 475, 476, 477, 478].
- Source files: Fruitfolio/Core/DataExport/FruitfolioZIPArchive.swift, Fruitfolio/Core/DataExport/FruitfolioLocalDataExport.swift, Fruitfolio/Core/DataExport/FruitfolioDataExportPicker.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementRegressionHarness.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift.
- Implemented actual combined local saved-data export, replacing the unused metadata-only account export API. Data Management captures an explicit allowlist of saved preference records and streams only the three existing cycle files and image UUIDs referenced by readable saved pages. Saved library/guide/original-answer references, notes, source IDs/versions, account state, My Context, measurements, username, game progress and settings retain their stored bytes/values. JSON/bin files preserve raw Data; other preference values use readable XML plist wrappers. Unsaved Ask text, unrelated preferences, orphan images, caches, model weights and research/artwork resources are excluded. Missing/invalid image IDs and unreadable records are reported in manifest.json rather than swept or repaired. No source file/default is changed. It is a sequential local export, not a cross-domain atomic snapshot, cloud export or restore/import feature.

The Foundation ZIP32 writer emits standard stored entries, CRC32/data descriptors and a central directory. Payloads stream in1MiB chunks. Output is exclusively created with0600 permissions; existing destinations are not overwritten. Relative ASCII paths, duplicates and ZIP32 bounds are checked; source links are rejected and opened with O_NOFOLLOW, expected size/inode/modification metadata are checked. Cancellation/error removes the owned partial archive, never the original. This is CRC integrity, not encryption/authentication or protection against every concurrent filesystem race.

The existing Data Management UI now prepares the archive off the main actor, supports cancellation and presents the actual iOS UIDocumentPicker for a URL copy. It reports saved only after the picker reports a destination, cleans its private temporary directory on completion/dismissal and distinguishes warnings/cancellation. Private-data scope is stated before export. The real measurement-only JSON path remains available. The DEBUG regression route injects private preferences and a private file root; its new UI case opens/cancels the real save picker without exporting actual user data. Apple API typechecking, provider save/cancel callbacks, screenshots, accessibility and device memory/performance remain NOT_RUN.

Independent Python zipfile tests validate CRCs, empty/UTF8 payloads, >1MiB file boundaries, exact raw scientific/provenance/notes records and image bytes, deduplication, wrong paths/duplicates/existing destinations, orphan/unsaved-Ask exclusion, unreadable-library warnings, and original preservation. Both pre-start and mid-stream cancellation plus missing/linked-source cleanup are exercised. The initial Foundation Process subprocess helper stalled after its Python child exited in this sandbox; those incomplete runs were stopped and are not counted. The corrected desktop-only test helper uses POSIX spawn/wait and actual Python zipfile; no archive reader clone or model fixture is substituted. The account regression now invokes a real archive and verifies that it does not fabricate a persisted readiness record. Historical lastExport metadata remains decodable without creating new summary-only success.
- Tests added/updated: Prompt1BLocalDataExportTests, Prompt12AccountPrivacyStoreTests.testRealLocalArchiveDoesNotCreateAnAccountReadinessRecord, Prompt1BModalAccessibilityTests.testLocalDataExportOpensRealSavePickerAndCancellationDoesNotClaimSaved (Apple NOT_RUN).
- Verification: {"Swift6": "512 XCTest +21 Swift Testing passed", "nativeSwift5": "517 XCTest +21 Swift Testing passed against actual CPU llama libraries", "archive": "8 production export tests executed; independent Python zipfile CRC/payload checks, pre-start/mid-stream cancellation and source preservation passed", "workflow": "35 passed with6 actual SwiftSyntax cases", "syntax": "261 Swift files parsed,0errors; Xcode references resolved;36 supplemental exact source texts retained", "Apple": "NOT_RUN SDK/typecheck, real iOS document provider saved/cancelled callbacks, UI/screenshots/VO/DT, large-data device memory/latency", "limitations": "Sequential local snapshot; ZIP32 bounds; no cloud-only export or import/restore; archives are not encrypted"}.
- Next action: Continue source preservation in actual Saved Library persistence: guard commits against cleared/newer UserDefaults values and unknown nested fields that Codable would otherwise discard. Keep original bytes and known readable pages available, retain candidate rollback/media safety, add exact production Foundation regressions and a user-visible reload path without overwriting storage. Then apply the same preservation boundary to measurement/context stores where applicable.
- Commit: containing commit for batch Actual-scoped-local-data-and-referenced-image-ZIP-export.

## Saved-library-stale-and-unknown-field-protection-with-readable-pages

- Parent checkpoint: 267c1f1ede47a9f6e1ae2279018718fe5a854beb.
- Source-order requirements: [125, 207, 443, 444, 457, 467, 468, 469, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/Persistence/FruitfolioJSONFieldCoverage.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryPersistence.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryAssets.swift, Fruitfolio/Saved Library/Prompt10LibraryStorageNotice.swift, Fruitfolio/Saved Library/Prompt10LibraryStorageRegressionHarness.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryView.swift, Fruitfolio/Guide Builder/Prompt11GuideBuilderView.swift, Fruitfolio/Saved Library/Prompt10AskSaveDestination.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- Saved Library persistence now captures the exact baseline UserDefaults object and rejects a commit after that record changes or is cleared elsewhere. The existing actual store rolls back its candidate state on failure and exposes a specific protection reason. Explicit reload reads the latest saved baseline without writing or merging it. Protected records cannot create books, and Library, Guide Builder home and Ask save destinations provide the same inline reload notice. This is value comparison in the local process, not a cross-process transaction/ABA guarantee.

Added a Foundation JSON-field-coverage guard: after a successful typed decode, a temporary typed encoding is inspected recursively for discarded dictionary fields/array members. No scientific scalar values are changed or treated as clinically equivalent. Unknown nested book/page/citation fields prevent writes while known readable pages remain available; no raw record is rewritten. This conservative rule also protects explicit null fields omitted by the typed encoder rather than guessing they are disposable. Unreadable originals retain the existing read-only behavior. Reload does not clear an unsupported record; only a genuinely readable/round-trippable newer baseline re-enables edits.

The real Saved Library store now conditionally retains genuine Combine/ObservableObject on Apple and runs its identical control flow on Linux. Existing Saved Library tests execute against that actual store. Its physical asset-name enum is also compiled unchanged on Foundation platforms; only the SwiftUI image view is conditionally excluded. No artwork/resources or model implementation is replaced. New actual-store tests prove stale/cleared deletion rollback, exact original byte preservation, known-page/notes readability under unknown nested fields, null protection and read-only reload. A DEBUG private-suite route and an actual UI test exercise the protected notice, large text/Reduce Motion and opening the existing readable book. Apple SDK/publisher/UI/screenshots remain NOT_RUN.

The new field guard is currently applied to Saved Library only. Remaining measurement/context persistence needs the same stale/unsupported-record review and implementation; this batch does not claim all app stores are protected.
- Tests added/updated: Prompt10SavedLibraryTests (actual store, now executable on Foundation), Prompt1BLibraryPersistenceTests, Prompt1BLibrarySnapshotProtectionTests, Prompt1BModalAccessibilityTests.testUnsupportedSavedLibraryKeepsReadableBooksAndMeasuredReloadAvailable (Apple NOT_RUN).
- Verification: {"Swift6": "528 XCTest +21 Swift Testing passed", "nativeSwift5": "533 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "35 passed with6 actual SwiftSyntax cases", "syntax": "266 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN private-suite read-only-library UI, large text/Reduce Motion, opening screenshots/VO and Combine publication", "scope": "Saved Library guard only; measurement/context preservation is next; explicit omitted-null fields are conservatively read-only"}.
- Next action: Apply stale/unsupported-record protection to actual hormone measurement persistence/store. Keep known readable scientific values available and raw bytes preserved; distinguish protected snapshots from unreadable data, guard explicit erase against stale records, add read-only reload, retain exact decimals/units/locale/date provenance, execute actual store tests. Then continue My Context preservation and full source/localization reconciliation.
- Commit: containing commit for batch Saved-library-stale-and-unknown-field-protection-with-readable-pages.

## Exact-measurement-snapshot-protection-and-truthful-save-feedback

- Parent checkpoint: 65b2fc6d9509be31c98eca9b10e0ea1f1dc98848.
- Source-order requirements: [251, 252, 265, 276, 278, 443, 444, 467, 474, 476, 477, 478].
- Source files: Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift, Fruitfolio/Hormone Information/HormoneMeasurementStore.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift.
- The actual measurement persistence/store now protect the captured saved baseline against later changes/clears before saves, individual deletes, exports and destructive erasure. Unknown fields detected by the shared typed-round-trip field guard keep known readable values available without permitting a lossy rewrite/export. An explicit reload reads the latest baseline without writing. Corrupt/wrong-type/duplicate-ID originals retain read-only protection. Explicit confirmed erase may remove its unchanged unreadable/unsupported baseline, but never a newer baseline. Store refresh occurs on errors as well as success, so the UI sees protection reasons instead of silently retaining an enabled state. The actual store retains real Combine observation on Apple and is now Foundation-executable without observation stubs.

Measurement UI displays a shared-style inline translated notice/reload action and pauses edit/delete/add/export for unsupported snapshots while keeping exact recorded values, units, notes and dates visible. The existing delete-all confirmation catches a protected erase failure. The specified insufficient-adjustment saved-message now appears only after a successful current-visit save, not merely because an old record exists; explicit reload/erase clears that claim. No adjusted curve, new clinical interpretation or prediction-confidence change is introduced.

Existing actual-store CRUD/unit/locale/corruption tests now execute on Linux alongside existing persistence tests. New actual-store regressions prove stale save/delete/export/erase rejection, unchanged original bytes/old state, read-only reload, unknown assay-field preservation, exact de_DE result string/µIU/mL/day/notes retention and explicit baseline erasure. A fixture helper initially omitted try for the real throwing civil-date initializer; the compiler caught it and the corrected tests use the actual constructor. No date bypass is used.

The two existing native confirmation dialogs in measurement deletion/editor discard remain a concrete Part1 source gap; replace them next with owned measured white-paper requests and local sheet host. Current Apple publisher, view/notice/saved-message behavior, accessibility, screenshots and device tests remain NOT_RUN.
- Tests added/updated: Prompt1BHormoneMeasurementTests (actual store now Foundation-executable), Prompt1BHormonePersistenceTests, Prompt1BHormoneSnapshotProtectionTests.
- Verification: {"Swift6": "534 XCTest +21 Swift Testing passed", "nativeSwift5": "539 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "35 passed with6 actual SwiftSyntax cases", "syntax": "267 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN measurement notice/saved-message UI and publisher/VO/DT/screenshots; actual native confirmation dialogs are next source work", "scope": "Exact scientific strings/units/date provenance preserved; explicit erase protects unchanged baseline, not a newer one"}.
- Next action: Replace the two concrete native confirmation dialogs in HormoneInformationView (delete measurement/all and editor discard) with owned shared measured-white-paper requests. Wrap the native editor sheet in its local PresentedPopupHost, cancel only owned queued/current dialogs on departure, guard stale/frozen destructive intent, restore correct accessibility focus, preserve dirty editor drafts and Reduce Motion. Add actual-core and Apple private-fixture UI regressions. Then continue My Context stale/unsupported persistence and source/localization reconciliation.
- Commit: containing commit for batch Exact-measurement-snapshot-protection-and-truthful-save-feedback.

## Owned-measurement-white-paper-confirmations-and-canonical-shared-actions

- Parent checkpoint: 536ad4521c1901b456a81d02d0b59cd1857eea18.
- Source-order requirements: [1, 2, 3, 6, 7, 9, 11, 12, 13, 14, 17, 18, 19, 20, 23, 24, 252, 443, 444, 446, 447, 467, 468, 469, 471, 472, 473, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioOwnedPopupSession.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift, Fruitfolio/Hormone Information/HormoneMeasurementDeletionIntent.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift, Fruitfolio/Hormone Information/HormoneMeasurementStore.swift, Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementRegressionHarness.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- Replaced the two remaining native measurement confirmation dialogs (one/all deletion and dirty-editor discard) with owned shared taped-white requests. The existing editor native sheet now has its own PresentedPopupHost above the sheet, preventing presentation behind it/double root hosts. Shared canonical blur/dim/hit/VoiceOver exclusion and Reduce Motion govern these requests. Shared paper actions now use the canonical control pill and its single soft-pop owner rather than plain raw buttons/manual cue calls. Paper message focus is requested after mounting and guarded by the current request identity/cancellation; translation disclosure/retry controls remain separate accessible children.

The actual Foundation FruitfolioOwnedPopupSession owns one queued/current request, cancels only that request on departure, ignores queued/old/replaced/dismissing actions, and keeps the first confirmation through rapid repeated presses. Its closing identity remains owned until real dismissal finishes, avoiding the deduplication race that could otherwise drop a replacement. Escape is cancellation and cannot turn into confirmation. Measurement UI restores focus only after the shared host is empty, choosing a surviving control/reload rather than a deleted row. Dirty-editor Keep/Escape retains draft text; explicit discard waits for the actual shared dismissal before closing its sheet. Text-field keyboard focus is released locally before requesting discard; no global keyboard action or extra timer is used.

Deletion intents contain only the target UUID/scope and an opaque in-memory saved revision. The actual persistence changes that revision on saves, reloads and erasure. A changed same-store record/reload invalidates an old confirmation; a separate writer still trips the exact saved-baseline guard. Successful deletion changes the revision, so replay fails. Missing targets do not become false success. No laboratory values are copied into popup ownership metadata or stored as analytics.

Six new actual-core regressions execute ownership/queue cancellation, single-use/Escape, repeated presentation through dismissal, priority replacement, same-store revision/replay and reload/external-writer preservation. New DEBUG measurement fixtures use only a private suite and inject the actual store into the actual existing screen. Three Apple UI regressions cover delete/cancel/confirm at large text with normal/Reduce Motion, dirty draft Keep/discard inside the native sheet, and readable original values under an unsupported future record. Those UI tests, real VoiceOver focus order, screenshots, native-sheet interaction and sound/listening acceptance remain NOT_RUN on Linux.

Available verification:540 portable XCTest +21 Swift Testing and545 native-linked XCTest +21 Swift Testing passed;35 workflow tests passed with all6 actual SwiftSyntax cases. All app Swift sources pass the bounded canonical immediate-cue ownership checker with zero findings. Compiler syntax parsed271 changed Swift files; Xcode project references resolve. These do not constitute an Apple build or device acceptance. The portable harness initially omitted its two new production sources; the resulting compile failure was corrected by adding the exact files, not substitutes.
- Tests added/updated: Prompt1BOwnedConfirmationTests, Prompt1BModalAccessibilityTests.testMeasurementDeletionUsesOneSharedPaperWithCancelAndConfirmedDelete (Apple NOT_RUN), Prompt1BModalAccessibilityTests.testMeasurementEditorNativeSheetHostsDirtyDraftPaperWithoutSavingDiscardedText (Apple NOT_RUN), Prompt1BModalAccessibilityTests.testMeasurementFutureRecordNoticeKeepsExactReadableValue (Apple NOT_RUN).
- Verification: {"Swift6": "540 XCTest +21 Swift Testing passed", "nativeSwift5": "545 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "35 passed including6 actual SwiftSyntax cases", "cue": "Actual bounded immediate-owner check clean across all app Swift files", "syntax": "271 Swift files parsed,0errors; Xcode references resolved", "Apple": "NOT_RUN actual SDK build/typecheck, shared-modal/native-sheet screenshots, VO/DT/focus, motion, real playback and device performance"}.
- Next action: Continue My Context persistence preservation: protect exact baseline and unknown nested fields before all mutations/exports/explicit erase, retain readable known optional context without inference, add a read-only reload path and actual-store Foundation tests. Propagate protection notices/disabled controls through existing My Context and Personal Health Context screens without changing cycle history or automatically sharing context with Ask. Then continue original-order source/localization reconciliation.
- Commit: containing commit for batch Owned-measurement-white-paper-confirmations-and-canonical-shared-actions.

## My-Context-stale-and-unknown-field-protection-and-private-shell-QA-coverage

- Parent checkpoint: 53f94d29d6db494fbb39db5cec80bc5f480c5c2f.
- Source-order requirements: [285, 287, 443, 444, 467, 468, 469, 474, 476, 477, 478].
- Source files: Fruitfolio/Context Personalization/Prompt27ALocalContextPersistence.swift, Fruitfolio/Context Personalization/Prompt27AContextStore.swift, Fruitfolio/Context Personalization/FruitfolioContextStorageNotice.swift, Fruitfolio/Context Personalization/FruitfolioContextStorageRegressionHarness.swift, Fruitfolio/Context Personalization/Prompt27AContextViews.swift, Fruitfolio/Context Personalization/FruitfolioPersonalHealthContextView.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift, Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmView.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift, Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- My Context persistence now captures the exact UserDefaults baseline, rejects stale/cleared writes and typed exports, and refuses lossy rewrites when nested fields would disappear in a typed Codable round-trip. Known optional selections, user wording, timestamps and provenance remain readable without changing the stored bytes. Unsupported/corrupt records remain protected after a read-only reload. Explicit local clear may erase the unchanged baseline the user confirmed; a newer baseline is preserved. This is a local value guard, not a cross-process transaction. Context mutation still does not reach into cycle logs, predictions, Ask transcripts, analytics or another data domain.

The actual Prompt27AContextStore now keeps real Apple Combine observation while compiling its identical control flow on Foundation platforms. No observable/persistence stub is used. Setter failures publish the protection reason without replacing context; thrown personal-health saves/exports refresh protection state too. Clear returns failure instead of fabricating a cleared state. Shared inline notices and canonical reload controls appear in existing My Context, Personal Health Context and its editor. Protected write controls are paused while local editor text can remain available for review/copy/discard. No biological fact, diagnosis or unknown future-field interpretation is inferred.

Three actual-store regressions exercise stale setters/personal-health save/export/clear, exact original/latest bytes and old-state retention, explicit read-only reload, unknown root/nested provenance fields, readable exact optional reports, confirmed baseline clearing and unrelated-domain preservation. Existing persistence/policy/health-context tests also execute. Native clear/discard/remove dialogs in My Context and Personal Health still need conversion to owned shared paper next; source preservation is not a claim that those modal gates or clinical acceptance are finished.

Following actual presentation paths also found that My Context and Hormone Rhythm could open measurement screens above the root host without their own host. They now use PresentedPopupHost. Settings full-screen My Context, its Personal Health sheet, Personal Health editor and Cycle Onboarding personal-health sheet have the same scoped host so owned requests stay above their native presentation. Actual iOS sheet/full-screen behavior remains NOT_RUN.

QA isolation correction: the private feature stores in65b2fc6 (library) and53f94d2 (measurements) were isolated, but their newly added entry flags were missing from ContentView’s shell-regression flag list. Shell preferences would have used ordinary defaults. No Apple UI runs occurred. Those flags and the new Context Storage QA flag now select a disposable shell suite, with no fallback to ordinary shell preferences. A bounded cross-file workflow regression requires every literal shell QA entrypoint to be registered. This is source inspection, not Apple runtime proof. The new context UI fixture is private and its unrun test verifies preserved selected state plus read-only reload/disabled controls at large text. Native verification first caught an assertion comparing a decoded millisecond-coded saved Date with finer pre-encoding live precision. The test now uses the actual decoded saved baseline and still requires exact original/latest bytes; the production codec/format is unchanged.
- Tests added/updated: Prompt1BContextPersistenceTests, Prompt1BContextSnapshotProtectionTests (actual store), development_workflow/tests/test_ui_qa_preference_isolation.py, Prompt1BModalAccessibilityTests.testContextUnknownFieldsKeepKnownSelectionAndPauseEditsAfterReadOnlyReload (Apple NOT_RUN).
- Verification: {"Swift6": "543 XCTest +21 Swift Testing passed after saved-timestamp assertion correction", "nativeSwift5": "548 XCTest +21 Swift Testing passed against actual CPU llama after correction", "workflow": "36 passed with6 real SwiftSyntax cases plus root QA preference-isolation invariant", "syntax": "274 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN context notice/known-selection UI, native-sheet hosting, publisher/VO/DT/screenshots and device acceptance", "scope": "Actual context bytes/readable known fields preserved; no clinical/future-field interpretation changes or cross-domain data deletion"}.
- Next action: Replace the three concrete Context native dialogs: My Context clear, personal-health dirty-editor save/discard/keep, and personal-health removal. Reuse actual OwnedPopupSession and the now-scoped PresentedPopupHosts; retain all three dirty-draft choices (shared popup model currently supports two actions, so extend measured action composition safely or use an existing equivalent). Freeze context revisions for clear/removal/save intent, never erase or overwrite a newer context, restore focus and preserve dirty drafts. Add exact-core/Apple private-fixture regressions; then continue original-order unnumbered requirement/localization reconciliation.
- Commit: containing commit for batch My-Context-stale-and-unknown-field-protection-and-private-shell-QA-coverage.

## Owned-context-three-choice-confirmations-and-frozen-editor-revisions

- Parent checkpoint: 1b54c7660395d3aedc8614275f6a88b59cf8ec17.
- Source-order requirements: [1, 2, 3, 6, 7, 9, 11, 12, 13, 14, 17, 18, 19, 20, 23, 24, 287, 443, 444, 446, 447, 467, 468, 469, 471, 472, 473, 474, 476, 477, 478].
- Source files: Fruitfolio/Fruit Popup Engine/FruitPopupModels.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift, Fruitfolio/Fruit Popup Engine/FruitPopupView.swift, Fruitfolio/Context Personalization/Prompt27AContextViews.swift, Fruitfolio/Context Personalization/FruitfolioPersonalHealthContextView.swift, Fruitfolio/Context Personalization/FruitfolioContextStorageNotice.swift, Fruitfolio/Context Personalization/Prompt27AContextStore.swift, Fruitfolio/Context Personalization/Prompt27ALocalContextPersistence.swift.
- Converted My Context clear, personal-health dirty-draft save/discard/keep and personal-health removal from native dialogs to owned shared taped-white requests. The existing scoped hosts keep those requests above Settings’ full-screen presentation and nested Personal Health editor sheets. The shared request model now has an optional third action (nil for existing callers); white-paper and character renderers include it in their existing vertically scrollable content with distinct accessibility identifiers. All three original dirty-draft choices remain available. No dialog option is silently removed. White-paper actions retain canonical control-pill styling and one press-cue owner.

Context clear is frozen to the saved revision when its dialog opens; a changed same-store record/reload invalidates that old intent, while separate writers still meet the exact persistence-baseline guard. Personal-health save/removal accepts an expected revision. The editor captures original wording, confirmation and revision in stable view State, so parent/store redraws cannot rebase an old draft automatically. Failed/stale saves keep the local draft. Explicit removal clears the selected private text through the actual domain operation and preserves other context. No context or popup metadata is sent to Ask/analytics or written to another domain.

Keep/Escape cancels without saving/removing. Save/discard/remove/clear wait for the actual shared dismissal before leaving a native sheet or mutating context, using the existing host completion rather than a new timer. Keyboard focus is released locally before a dirty-draft request. Owned queued/current requests are cancelled on departure; old/dismissing callbacks cannot execute. Cancel focus is restored after the host empties; failed clear/save requests focus the actual inline error message without folding translation controls into an inaccessible combined element. Real VoiceOver behavior remains an Apple gate.

Three new actual-store regressions prove old clear rejection, same-store revision/replay safety, stale editor save/removal rejection, unchanged raw bytes, current scoped removal of private text and reload invalidation. Apple UI regressions exercise cancelling/confirming clear of the private future-format fixture and every dirty-draft choice plus scoped removal inside the real native editor. The latter checks that kept text remains, saved text reloads, discarded additions disappear and removed context reports the actual removed state. They are NOT_RUN on Linux. All app-owned native-dialog call sites in Context and Measurement sources are now absent; the two remaining identified sites are Saved Library note/user-page discard, which are next source work.

Available verification:546 portable XCTest +21 Swift Testing;551 actual native-linked XCTest +21 Swift Testing;36 workflow tests including6 real SwiftSyntax cases;275 changed Swift files parsed without syntax errors. Bounded direct canonical-cue ownership check is clean across all app Swift sources. These results do not claim an Apple SDK build, native-sheet/VO/DT/screenshot acceptance, real audio listening, clinical approval or complete Prompt1B acceptance.
- Tests added/updated: Prompt1BContextConfirmationRevisionTests, Prompt1BModalAccessibilityTests.testContextClearUsesSharedPaperAndCancelPreservesUnsupportedOriginal (Apple NOT_RUN), Prompt1BModalAccessibilityTests.testPersonalHealthDirtyDraftRetainsAllThreeChoicesAndScopedRemoval (Apple NOT_RUN).
- Verification: {"Swift6": "546 XCTest +21 Swift Testing passed", "nativeSwift5": "551 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "36 passed including6 real SwiftSyntax cases", "cue": "Bounded immediate canonical-owner source check clean", "syntax": "275 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN actual sheet/focus/VO/DT/screenshot and audio/device acceptance", "remaining_modal_source": "Saved Library note and user-page native discard confirmations are next"}.
- Next action: Replace the two remaining identified app-owned native confirmation sites in Saved Library: Prompt10SavedLibraryDetail note save/discard/keep and Prompt10UserMaterialEditor page save/discard/keep. Reuse OwnedPopupSession/shared measured paper with all three choices, wrap any native page-editor sheet in PresentedPopupHost, freeze original note/page state against newer same-store updates, preserve dirty text on failure/cancel and restore focus. Add actual-store/core and private-fixture Apple regressions; continue remaining original-order source/localization work afterward.
- Commit: containing commit for batch Owned-context-three-choice-confirmations-and-frozen-editor-revisions.

## Owned-saved-note-user-page-confirmations-and-field-specific-conflict-guards

- Parent checkpoint: 8f4c4ac0ef61942a150a8d54bda0fab4119e4e76.
- Source-order requirements: [1, 2, 3, 6, 7, 9, 11, 12, 13, 14, 17, 18, 19, 20, 23, 24, 125, 443, 444, 446, 447, 467, 468, 469, 471, 472, 473, 474, 476, 477, 478].
- Source files: Fruitfolio/Saved Library/Prompt10UserMaterial.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryStore.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryModels.swift, Fruitfolio/Saved Library/Prompt10UserMaterialEditor.swift, Fruitfolio/Saved Library/Prompt10SavedLibraryDetail.swift, Fruitfolio/Saved Library/Prompt10ContinuousBook.swift, Tools/check_shared_confirmation_coverage.swift.
- Converted the final two identified app SwiftUI native confirmation sites: Saved Library notes and user-authored page save/discard/keep. Each uses OwnedPopupSession and all three measured white-paper actions. Keep/Escape retains the draft; Save waits for actual shared dismissal and leaves the editor/page open on failure; explicit Discard closes without persisting the draft. Keyboard/focus, page departure/change cancellation and error-message focus are owned by the active view. The user-page overlay has a scoped PresentedPopupHost, so confirmation blurs the editor once without stacking another whole-app blur over its already dimmed background. Saved notes restore their Back control on Keep and the contents row after actual departure.

Notes now save with their original field baseline. A newer same-store note cannot be silently replaced; stored answer text, source IDs/versions and other metadata remain unchanged. User-page editors freeze the original editable fields/chapter/identity in stable State. Their store API rejects newer wording, notes, source-address or chapter changes without altering the current snapshot. The comparison intentionally ignores unrelated imported-image/retained metadata changes: saving valid text clones the current page so new images survive. Existing persistence guards still protect outside-writer/unsupported records. Missing chapter selection produces a visible focused error rather than a silent no-op. Inputs survive failed saves; a success message is cleared when notes become dirty again.

The actual saved-note save/edit controls now use canonical feedback/animation. User-authored contents rows are labeled your own page rather than complete saved answer; long row titles wrap instead of truncating to two lines. Original art and source content are untouched. DEBUG Book QA can seed one synthetic user page only when explicitly requested, and synchronizes its root/local Reduce Motion preferences through the disposable shell suite. New Apple UI regressions walk Note Keep/Discard/Save and user-page overlay Keep/Discard/Save against actual private fixture records, checking original text/notes, retained drafts and one exposed confirmation scroll area. They remain NOT_RUN, as do VoiceOver, screenshots and actual device interaction.

Three actual-store Foundation regressions prove stale note refusal with exact raw bytes/citation metadata retained, independent images surviving note/user-page edits, and older page drafts unable to overwrite newer notes/source addresses/chapter moves. The new test initially used the wrong existing createChapter argument label; it was corrected to the actual in: API, with no production API substitution.

Added Tools/check_shared_confirmation_coverage.swift using actual SwiftParser/SwiftSyntax. This is a bounded read-only check for alert/confirmationDialog member calls, ignoring comments/string prose/authorization option values, with method-token source locations. Parse/read failure cannot produce a clean result. Three executable checker regressions include the actual complete app source scan; no such native calls remain. It does not type-resolve arbitrary custom methods or prove UIKit/system-prompt/layout acceptance. Thirty-nine workflow tests passed, including nine real SwiftSyntax tool cases. 549 portable XCTest +21 Swift Testing and554 native-linked XCTest +21 Swift Testing passed. Compiler syntax parsed277 changed Swift files; Apple typecheck/build/clinical/runtime acceptance remains open.
- Tests added/updated: Prompt1BSavedDraftConflictTests, development_workflow/tests/test_shared_confirmation_coverage.py, Prompt1BModalAccessibilityTests.testSavedNotesKeepDiscardAndSaveThroughOwnedPaper (Apple NOT_RUN), Prompt1BModalAccessibilityTests.testUserPageOverlayKeepDiscardAndSaveRetainOriginalUntilExplicitSave (Apple NOT_RUN).
- Verification: {"Swift6": "549 XCTest +21 Swift Testing passed", "nativeSwift5": "554 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "39 passed including9 actual SwiftSyntax cases", "modal_source": "Actual SwiftSyntax bounded app scan has0 alert/confirmationDialog calls; parse failures fail closed", "syntax": "277 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN actual saved-note/page overlay UI, focus/VO/DT, screenshots, sound/device acceptance"}.
- Next action: Continue the next independent incomplete source-of-truth requirement: inspect the approved LifeBridge source/snapshot contract and recover authentic content from the two exact founder-specified HTTPS sources if the current network policy allows it. Use available connected read tools or the configured proxy, retain provenance/citations, and never invent approval/application/clinical claims. If access/review is blocked, record the exact blocker and immediately continue static UI/localization coverage and other original-order source work; do not retry inaccessible resources repeatedly.
- Commit: containing commit for batch Owned-saved-note-user-page-confirmations-and-field-specific-conflict-guards.

## Catalog-first-translation-origin-memory-gating-and-undated-reference-protection

- Parent checkpoint: 71b2b173e85cc17eb28370d4cdcf5339e9f78d7c.
- Source-order requirements: [315, 316, 395, 397, 418, 419, 421, 422, 424, 427, 428, 430, 431, 434, 443, 444, 466, 467, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift, Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift, Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift, Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Tools/MADLADCatalogRunner.swift, Tools/translate_catalog_with_madlad.py.
- LifeBridge source recovery was checked against the actual connected environment’s enforced network policy (spec revision3). Neither exact founder host nor huggingface.co is allowed. No blocked HTTP request was attempted, alternate-domain route used, webpage content inferred or retrieval/review/approval date fabricated. The exact policy evidence and user-side allowlist action are in RUN_LOGS/Founder-source-host-policy-check.json and BLOCKERS.md. Existing information access remains explicit about missing approved snapshots; source work continues independently.

The actual translation service now prefers an exact selected-language source-controlled catalog entry before native inference, validates source-specific scientific literals/quantities/references and reports origin as source/catalog/machine. Catalog values identical to keys (such as DNA) are distinguished from missing values using a unique fallback sentinel; repeated missing/empty lookups cannot become fake translations. Catalog lookup/validation runs on the service actor and remains available when memory pressure prohibits inference. Non-English recorded originals are not reinterpreted as English UI keys. Missing/invalid catalog values go through the actual MADLAD path only when allowed, otherwise preserve the source with the existing memory-pressure error. Cached accepted display text survives memory release. Blank source text does not falsely become model-inference evidence.

Display wrappers now label only actual inference results as local machine translation, preserve their original-text disclosure and never alter saved/user-authored records. The catalog validator checks literals and signatures; it does not certify semantic or clinical translation quality. The shipped catalog still has652 keys and zero nonempty foreign-language values. Full reviewed catalog population, correct Xcode extraction of legacy expression-like keys, clinical/native-language review and runtime acceptance remain incomplete. Test bundle translations are controlled fixtures, not claims that those resources are shipped or clinically reviewed.

Scientific reference protection now includes canonical APA no-date citations and full-width round/square reference delimiters. Added/invented dated/no-date/full-width citations and new Unicode-number claims are rejected; original full attribution, identifiers, values and units remain exact. Ordinary translated words resembling unit abbreviations remain permitted when they were not protected source literals. No-date handling also applies to actual inference post-validation, not only catalog lookup.

Eight new production-service/Foundation regressions execute real temporary bundle lookup, catalog priority/identity, missing/empty sentinel behavior, memory gating, invalid scientific catalog fallback, full-attribution protection, Unicode digits/no-date/full-width references, non-English source handling, blank-input origin and explicit catalog bypass. Their identity runtime is a declared contract fixture, not T5 output. MADLADCatalogRunner now explicitly disables catalog preference so generated machine drafts cannot silently reuse static resources. Its build script includes the exact production localization source. The rebuilt real CPU-linked Swift5 runner rejects a nonempty offline request with missing resources and no result; RUN_LOGS/Catalog-first-actual-runner-resource-check.json preserves that evidence. Official T5 resources/inference/quality remain blocked.

Available verification:557 portable XCTest +21 Swift Testing and562 native-linked XCTest +21 Swift Testing passed;39 workflow tests including9 real SwiftSyntax tool cases;278 changed Swift files parsed without syntax errors. The updated CLI compiled/linked actual native archives. Apple app SDK/typechecking, UI origin labels/catalog compilation, screenshots/VO/DT and physical-device/clinical acceptance remain NOT_RUN. The fixture initially omitted the actual runtime protocol’s releaseResources method; it now implements that explicit empty-resource fixture contract. No production implementation is substituted.
- Tests added/updated: Prompt1BCatalogTranslationTests, Prompt1BExplicitLocalizationTests, Prompt1BScientificTranslationTests, Actual CPU-linked MADLADCatalogRunner missing-resource check (not T5 output).
- Verification: {"Swift6": "557 XCTest +21 Swift Testing passed", "nativeSwift5": "562 XCTest +21 Swift Testing passed against actual CPU llama", "workflow": "39 passed including9 real SwiftSyntax cases", "CLI": "Actual current-source Swift5/native runner rebuilt; nonempty offline request rejects absent resources with no translation", "sourceAccess": "Both LifeBridge hosts and huggingface.co excluded by enforced spec3; exact unblock action recorded, no bypass/approval invented", "catalog": "652 existing keys;0 nonempty foreign values; fixtures do not prove shipped/clinically reviewed localization", "syntax": "278 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN compiled app catalogs, origin labels/UI/screenshots/VO/DT, actual official T5/device/clinical acceptance"}.
- Next action: Connect the actual character dialogue renderers (FruitPopupView and First-Launch Tour shared bubble content) to the selected-language/citation-safe display translation pipeline instead of raw English dynamic text. Preserve intentional invitation layout, focus/motion and all actions; check canonical feedback ownership before changing raw action buttons. Then correct measurement editor result-format provenance/cycle-day Unicode parsing: it currently records Locale.current rather than the app-selected locale and uses raw Int(day), while existing numeric validation already normalizes Unicode digits. Preserve unknown legacy provenance without guessing or changing stored values.
- Commit: containing commit for batch Catalog-first-translation-origin-memory-gating-and-undated-reference-protection.

## Character-dialogue-canonical-translation-and-controls

- Parent checkpoint: 3cd888289806d5dbf799de15fd5a4a8f7ce26b3b.
- Source-order requirements: [11, 13, 20, 23, 24, 395, 396, 397, 411, 446, 447, 451, 466, 471, 472, 477].
- Source files: Fruitfolio/Fruit Popup Engine/FruitPopupView.swift, Fruitfolio/First-Launch Tour/Prompt07TourOverlay 2.swift.
- Character speech now uses the existing actor-based catalog/MADLAD translation pipeline with protected brand literals. Typography adjustments follow translation lookup, preserving canonical source strings. Tour already used translated text; it now uses the canonical model message rather than duplicate NBSP/Markdown lookup keys, preserves brand emphasis after translation, and uses compiler-localizable interpolated progress. Character and Tour actions now use canonical watercolor controls with shared press sound/motion, localized labels, wrapping and minimum targets; Tour actions stack inside the existing scroll area. Distinct popup-close sounds remain. Existing UI regression assertions now also bound character action width and minimum height. Full source parsing and portable tests passed; Apple UI tests, typechecking, screenshots, voiceover and device behavior remain NOT_RUN; no reviewed foreign catalog or actual T5 inference is claimed.
- Tests added/updated: Prompt1BModalAccessibilityTests.testTourActionsRemainReachableAtAccessibilitySize, Prompt1BModalAccessibilityTests.verifyModal.
- Verification: {"portable": "557 XCTest +21 Swift Testing passed", "workflow": "39 passed including9 actual SwiftSyntax tests", "syntax": "278 files parsed,0errors; not Apple typecheck", "Apple": "NOT_RUN character/Tour layouts, controls, localization and accessibility"}.
- Next action: Correct measurement editor result-locale provenance and Unicode cycle-day parsing while preserving exact reported strings and unknown legacy metadata. Continue independent requirements and actual MADLAD integration work without claiming missing official weights or Apple verification.
- Commit: containing commit for batch Character-dialogue-canonical-translation-and-controls.

## Measurement-reported-format-provenance-and-Unicode-cycle-day

- Parent checkpoint: 3b6246ad1d944eec7214adb0782f6175c5e23ddf.
- Source-order requirements: [243, 244, 245, 246, 247, 249, 250, 251, 278, 432, 458, 467, 474, 477].
- Source files: Fruitfolio/Hormone Information/HormoneInformationView.swift, Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift.
- The actual editor now uses the app-selected locale for newly typed results rather than Locale.current, keeps known report formats through later edits/language changes and offers explicit decimal-separator selection. Persistence no longer stamps unknown legacy result formats with the current locale on notes-only saves: exact original result/unit and missing provenance remain missing. Changing an unknown-format result or unit requires explicit format selection; rejected saves preserve bytes. Existing known format is retained even if a draft omits its metadata, rather than silently switching locale. Required nonnumeric metadata validation is separated so preserving an unparsed historical number does not assert its numeric interpretation. Unicode decimal-script cycle days are accepted through an exact positive integer parser; fractional/signed/separated/overflowing values reject. Three production persistence/parser regressions verify Arabic/Persian/Devanagari/fullwidth digits, malformed inputs, unchanged legacy provenance, rejected-write byte identity, explicit format confirmation, app-language changes and reload preservation. A real editor UI regression was added but NOT_RUN. Raw report values/units are never rewritten or converted.
- Tests added/updated: Prompt1BHormoneMeasurementTests, Prompt1BModalAccessibilityTests.testMeasurementEditorSavesArabicDecimalCycleDayAndKeepsReportedResult.
- Verification: {"portable": "560 XCTest +21 Swift Testing passed", "workflow": "39 passed including9 actual SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; Apple typecheck not available", "Apple": "NOT_RUN editor/picker/native keyboard UI, accessibility, device behavior"}.
- Next action: Continue Part1 shared character accessibility: character speech lacks the guarded initial message focus used by white-paper popups. Add identity-scoped focus and cancellation behavior; verify Tour step focus and Reduce Motion without timers. Continue independent original-order work and preserve all MADLAD external blockers.
- Commit: containing commit for batch Measurement-reported-format-provenance-and-Unicode-cycle-day.

## Shared-character-focus-escape-and-narrow-host-bounds

- Parent checkpoint: 30e0253034199b8b36ff4c66338e9487ad824941.
- Source-order requirements: [6, 13, 14, 18, 19, 20, 23, 24, 395, 411, 447, 451, 471, 472, 477].
- Source files: Fruitfolio/Core/AppArchitecture/PopupCoordinator.swift, Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift, Fruitfolio/Fruit Popup Engine/FruitPopupView.swift, Fruitfolio/First-Launch Tour/Prompt07TourOverlay 2.swift, Fruitfolio/Hub/Prompt04HubBridgeView.swift.
- Character speech now receives cancellable request-scoped accessibility message focus after a layout yield; host renderer identity resets between queued requests. Tour message focus follows actual step entrance with cancellation guards, resets its scroll region per step, and exposes Escape to skip with the existing close cue. Hub content is hidden from accessibility and hit testing while Tour is active without changing the approved tour veil/frame preferences. Both character and white-paper surfaces now share an identity-scoped coordinator Escape policy, preventing stale or repeated accessibility actions from closing replacements and preserving mandatory acknowledgment requests. Host width no longer invents a 240-point minimum; adaptive insets and the actual production width helper respect narrow/collapsed containers. Two new real coordinator/layout tests cover empty/current/queued/stale/replayed/persistent Escape and bounded narrow widths. Available source and Foundation verification is not proof of actual VoiceOver focus/scroll behavior, visual layout, Apple typechecking or device Reduce Motion; those remain NOT_RUN.
- Tests added/updated: Prompt06FruitPopupTests.testAccessibilityEscapeIsIdentityScopedAndCannotDismissAcknowledgmentOrReplacement, Prompt1BPopupLayoutTests.testActualHostWidthCannotExpandNarrowOrCollapsedContainers.
- Verification: {"portable": "562 XCTest +21 Swift Testing passed", "workflow": "39 passed including9 real SwiftSyntax cases", "syntax": "278 files parsed,0errors; not Apple typecheck", "Apple": "NOT_RUN actual focus/Escape/VO/DT/scroll/layout and Reduce Motion"}.
- Next action: Continue actual MADLAD compatibility integration: verify GGUF architecture and embedded T5 tokenizer metadata before native allocation, using bounded production Foundation parsing and actual negative model evidence. Official weights/tokenizer access remains externally blocked; do not fabricate successful T5 output. Then continue independent source-order requirements.
- Commit: containing commit for batch Shared-character-focus-escape-and-narrow-host-bounds.

## MADLAD-bounded-GGUF-tokenizer-preflight-before-native-allocation

- Parent checkpoint: 8d93d18978afda2384e48599a3e8317310d6f256.
- Source-order requirements: [409, 418, 419, 422, 425, 427, 428, 430, 443, 444, 466, 467, 475, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift, Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Tools/typecheck_madlad_api.py.
- The actual MADLAD runtime now validates actual GGUF T5 architecture and embedded tokenizer metadata after its streaming digest but before native model allocation. A bounded production Foundation reader handles GGUF2/3, skips vocabulary arrays without materializing them, checks remaining file size/length arithmetic, and rejects missing/duplicate keys, wrong types/architecture/tokenizer, truncation, unsupported/nested arrays, excessive counts/lengths and cancellation. Actual native context capacity is checked, and cancellations observed after native model/context allocation free those allocations. Native calls cannot be preempted mid-call. Metadata acceptance is not executable-model, official provenance or translation-quality proof. Four new production parser regressions use explicitly synthetic metadata fixtures, not fabricated model outputs. The actual checksum-verified assistant artifact is rejected by the actual MADLAD path before native allocation; it is never substituted for T5. The exact current native CLI compiled/linked actual CPU archives. The standalone API checker was stale after the earlier checksum integration; it now includes the actual checksum source/system OpenSSL headers and passes against actual supplied framework headers with no stubs. Initial cancellation test compilation exposed a missing try and Swift6 nonsendable XCTest self capture; fixed by capturing only Sendable config/URL and reran exact final suites. Full final portable566 XCTest+21 SwiftTesting and actual native571 XCTest+21 SwiftTesting pass. Workflow39 including9 real SwiftSyntax cases,278 Swift syntax parses, target-reference validation and Swift/C API typecheck pass. Actual official MADLAD weights/tokenizer/inference/clinical and physical-device quality/performance remain externally blocked/NOT_RUN, as do Apple app compilation/UI checks. Verification bounds documented in MADLAD_METADATA_PREFLIGHT_VERIFICATION.md.
- Tests added/updated: Prompt1BMADLADManifestTests, Actual native CPU-linked MADLADCatalogRunner compilation, Actual framework-header Swift/C API typecheck.
- Verification: {"portable": "566 XCTest +21 Swift Testing passed", "native": "571 XCTest +21 Swift Testing passed with actual CPU llama and actual negative-model preflight", "workflow": "39 passed including9 actual SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; target build-file references resolved", "CLI/API": "Current production CLI built/linked actual archives; Swift/C typecheck passed against supplied framework headers, no stubs", "T5/Apple": "NOT_RUN official T5 inference/tokenizer/quality/clinical/device performance, Apple SDK app build/UI"}.
- Next action: Strengthen scientific translation post-validation for introduced/changed scientific identifiers (for example AMH/FSH/HLA/rs IDs) and explicitly protected literals even when absent from the original. Preserve ordinary translated words that resemble units. Cover both real envelope restore and catalog candidates without claiming semantic/clinical review; then continue independent original-order requirements.
- Commit: containing commit for batch MADLAD-bounded-GGUF-tokenizer-preflight-before-native-allocation.

## Scientific-identifier-and-explicit-literal-translation-integrity

- Parent checkpoint: cebc3a76e19426c0eb72249717b9003823b7aa8e.
- Source-order requirements: [422, 424, 426, 431, 434, 443, 444, 466, 467, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- The actual envelope now compares scientific identifier signatures as well as quantities/references for both restored model output and catalog candidates. This closes the case where an added AMH/FSH/LH/TSH/pH/hCG/DHEA-S/HbA1c/rs/HLA identifier had no new numerical claim and could previously survive validation. Identifier source spelling/order/multiplicity remain exact. Explicitly protected literal signatures are checked even when absent from the source, so new/duplicate protected brands cannot be introduced silently. Ordinary translated words resembling unit abbreviations (for example Norwegian min) remain permitted. Three envelope regressions cover introductions/order/case/repetition/absent brands; an actual service regression deliberately injects invalid content in the second paragraph and verifies whole-passage failure rather than partial output; an actual catalog/bundle regression verifies invalid identifiers cannot bypass a memory pause and fall back only through the permitted runtime path. The deliberately corrupt/identity runtime fixtures prove service contracts, not native T5 output or clinical accuracy. Final571 portable XCTest+21 SwiftTesting and576 native-linked XCTest+21 SwiftTesting passed,39 workflow tests including9 real SwiftSyntax and278 syntax parses passed. These are bounded lexical integrity checks and do not establish semantic translation equivalence, preservation of every uncertainty qualifier or clinical/native-language approval. Official model and Apple/device gates remain open.
- Tests added/updated: Prompt1BScientificTranslationTests, Prompt1BTranslationPipelineTests.testLateIdentifierOrProtectedBrandInjectionRejectsWholePassage, Prompt1BCatalogTranslationTests.testCatalogWithInventedIdentifierCannotDisplayWhileModelIsPaused.
- Verification: {"portable": "571 XCTest +21 Swift Testing passed", "native": "576 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "39 passed including9 actual SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; no Apple typecheck", "external": "Official T5 inference/translation quality/clinical review and Apple app/UI/device checks NOT_RUN"}.
- Next action: Continue Part1 universal control consistency: Prompt03SkeletonView retains legacy private Prompt03TextButton coded gray/burgundy outline and plain Prompt03BackControl. Confirm route/caller cue ownership and replace their renderers with existing canonical controls without rebuilding navigation or altering the app artwork. Then continue independent source-order work.
- Commit: containing commit for batch Scientific-identifier-and-explicit-literal-translation-integrity.

## Canonical-Contact-failure-and-retained-architecture-controls

- Parent checkpoint: 4cf0711c6687e20231476224a837e377a460df44.
- Source-order requirements: [7, 8, 9, 11, 12, 20, 378, 381, 382, 389, 390, 446, 464, 471, 472, 477].
- Source files: Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Hub/Contact/Prompt30ContactView.swift.
- Contact failure close now uses the actual canonical watercolor pill, shared pop feedback/motion and localized wrapping label. The feature helper no longer plays an additional press cue; it retains the distinct popup-close cue, and accessibility Escape calls that helper without synthesizing a button press. The existing Contact UI regression additionally checks minimum action height and horizontal writing-area bounds; it remains NOT_RUN without Apple SDK. Retained historical Prompt03TextButton and Prompt03BackControl now delegate to existing canonical controls instead of keeping coded gray/burgundy outlines and plain behavior. These placeholder declarations are not routed by the current production route switch; this is source consistency, not a claim of a newly visible feature. The existing navigation shell/route architecture is preserved and its stale header comment corrected. Full available Foundation/real native regressions571/576 XCTest+21 SwiftTesting pass,39 workflow tests pass,278 Swift files parse, and the actual SwiftSyntax sound-owner all-app scan passes without duplicate direct press cues. Source/UI tests do not establish device sound playback, Apple typechecking, visual layout or VoiceOver/Reduce Motion behavior.
- Tests added/updated: Prompt1BModalAccessibilityTests.testContactFailureUsesMeasuredModalAndRestoresLinkAccess, Existing interaction audio UI regressions (NOT_RUN), Existing full portable/native/workflow regressions.
- Verification: {"portable": "571 XCTest +21 Swift Testing passed", "native": "576 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "39 passed including9 real SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; all-app direct canonical sound-owner scan clean", "Apple": "NOT_RUN updated Contact UI assertions, actual playback, Apple SDK build, layout/VO/DT/Reduce Motion"}.
- Next action: Continue universal control consistency in actual source-citation footers: replace the plain open-source action with the canonical compact watercolor control and remove its indirect manual press cue. Migrate link-failure ownership to the existing tested FruitfolioOwnedPopupSession so replayed close actions cannot dismiss unrelated replacement popups; preserve original citation fields and actual-source QA coverage.
- Commit: containing commit for batch Canonical-Contact-failure-and-retained-architecture-controls.

## Canonical-source-citation-control-and-owned-link-failure

- Parent checkpoint: fc8d9a7bbcbebcaa1d4fa891e4d4385b798cbe1f.
- Source-order requirements: [6, 8, 9, 11, 20, 125, 395, 446, 447, 455, 471, 472, 477].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioSourceCitationList.swift.
- The actual shared source-citation footer now uses a compact canonical watercolor control for open source. Its old indirect manual press cue and redundant motion/audio dependencies were removed, leaving the canonical control as the sole press-cue owner. Citation link failures now use the already tested FruitfolioOwnedPopupSession instead of separate unmanaged popup IDs and an unrestricted dismissCurrent close closure. Failure actions consume their own identity once; stale/queued/replayed actions cannot close another feature. Departures/source changes cancel only the owned request and active callback, while dismissed request ownership is observed before new opens and focus restoration still waits for actual host dismissal. Original source titles, full attribution, publication metadata, DOI, URL and IDs remain verbatim. The existing actual-root/native-sheet UI regression now checks action bounds and reopens/closes the failure to catch stuck ownership. Those UI assertions remain NOT_RUN on Linux. Full available suites571 portable XCTest+21 SwiftTesting and576 native XCTest+21 SwiftTesting passed;39 workflow tests including9 real SwiftSyntax,278 syntax parses and the all-app canonical sound-owner scan pass. Apple UI/VoiceOver, actual openURL callbacks and device audio/layout remain unverified.
- Tests added/updated: Prompt1BModalAccessibilityTests.testSourceLinkFailureUsesOneRootPaperPopupAndRestoresWholePageAccess, Prompt1BOwnedConfirmationTests existing actual ownership regressions.
- Verification: {"portable": "571 XCTest +21 Swift Testing passed", "native": "576 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "39 passed including9 real SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; all-app direct cue scan clean", "Apple": "NOT_RUN expanded citation UI reopen/width assertions, real openURL/audio/layout/VO/DT"}.
- Next action: Continue MADLAD missing-resource behavior: replace unbounded/opaque JSON decoding with a bounded, cancellation-aware actual manifest loader that returns precise invalidManifest/resourcesMissing errors; preserve actual checksum/metadata gates. Cover malformed/oversized/missing manifests and missing model files through Foundation and actual native runtime tests. Then continue independent original-order requirements.
- Commit: containing commit for batch Canonical-source-citation-control-and-owned-link-failure.

## MADLAD-bounded-manifest-loading-and-typed-resource-recovery

- Parent checkpoint: ac9e0e99be0d90b28182ee1e5b1bbf2a7c4e0ba2.
- Source-order requirements: [409, 418, 419, 425, 426, 427, 428, 430, 443, 444, 466, 467, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADModels.swift, Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- The production MADLAD manifest loader now reads at most64KiB plus one overflow byte in4KiB chunks, checks cancellation during reads and before return, validates decoded configuration and maps malformed/oversized JSON to invalidManifest while missing/unreadable manifests map to resourcesMissing. Model-open failures now map to resourcesMissing instead of leaking an opaque file error. The actual runtime uses this loader before the existing checksum/GGUF metadata/native graph gates and remains retryable after failed loads and idempotent resource release. Three new Foundation regressions test missing/malformed/invalid/over-limit resources, inclusive64KiB valid JSON boundary, cancellation and missing model files. A new actual native-runtime regression exercises missing then malformed manifests and missing model resources through the actual actor with no output; no stand-in model or fake translation is used. The exact production CLI was rebuilt/linked against actual CPU archives and all three nonempty requests returned the expected typed error with no translation value; exact evidence is in RUN_LOGS/MADLAD-actual-CLI-resource-error-check.json. Repeated fixture hashes/revision text are explicitly synthetic, not official provenance. Final574 portable XCTest+21 SwiftTesting,580 native-linked XCTest+21 SwiftTesting,39 workflow tests including9 actual SwiftSyntax and278 syntax parses passed; actual supplied-header API typecheck passed. Official T5 inference/quality/offline device/performance/clinical and Apple SDK/UI gates remain NOT_RUN.
- Tests added/updated: Prompt1BMADLADManifestTests, Actual rebuilt native MADLADCatalogRunner resource-error checks.
- Verification: {"portable": "574 XCTest +21 Swift Testing passed", "native": "580 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "39 passed including9 real SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors", "CLI/API": "Actual rebuilt CPU-linked CLI rejects3 resource scenarios with no value; actual header API typecheck passes", "T5/Apple": "NOT_RUN official T5 output/tokenizer/clinical/device quality and Apple SDK/UI"}.
- Next action: Correct shared character/Tour RTL artwork orientation: HStack mirrors child order in right-to-left layout, while the speech-bubble shell currently uses the unchanged physical left/right tail. Separate logical character placement from physical tail orientation, preserve native text direction/artwork proportions and add actual Foundation direction/layout regressions plus Apple UI coverage without claiming unrun screenshots.
- Commit: containing commit for batch MADLAD-bounded-manifest-loading-and-typed-resource-recovery.

## RTL-character-tail-orientation-and-shared-QA-motion-authority

- Parent checkpoint: b4eaa4e150099535aa58ceeb405db61ebd1bbd1f.
- Source-order requirements: [13, 19, 21, 22, 23, 24, 35, 38, 395, 396, 410, 411, 413, 415, 447, 451, 466, 471, 472, 477].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/Fruit Popup Engine/FruitPopupView.swift, Fruitfolio/First-Launch Tour/Prompt07TourOverlay 2.swift, Fruitfolio/Fruit Popup Engine/Prompt06PopupGallery.swift.
- Shared character and Tour speech-bubble tails now account for actual physical character placement after SwiftUI HStack mirrors logical child order in RTL. Logical leading/trailing request ordering remains native; only the physical tail/inset and entrance-anchor choice use the shared Foundation direction mapping. Artwork proportions, character imagery, screen position preferences and native text/layout direction are preserved; no global forced LTR workaround or mirrored fruit assets were introduced. One real Foundation regression exercises all four logical/direction cases and every selectable language direction. Two actual Apple UI regressions and RTL screenshot captures were added for scrollable character/Tour actions at accessibility size, but remain NOT_RUN. Private Modal/Tour QA fixtures now select Arabic through their disposable actual SettingsStore when the modifier flag is used, so root locale/direction/translation behavior stays on the real authority. Those fixtures also use actual MotionPreferences, setting the private reduce-motion override rather than bypassing canonical button motion with a standalone fixture bool. This corrects a fixture inconsistency exposed after canonical control integration; previously unrun UI tests are not retroactively claimed. Missing-model Arabic output remains the preserved source, not a claimed translation. Final575 portable XCTest+21 SwiftTesting and581 actual native-linked XCTest+21 SwiftTesting,39 workflow tests including9 real SwiftSyntax and278 syntax parses passed. Actual RTL artwork rendering/tail pixels, native text, focus/VO, Apple typechecking and motion/screenshots require Mac/device checks and are NOT_RUN.
- Tests added/updated: Prompt1BPopupLayoutTests.testCharacterTailUsesPhysicalSideAfterLogicalRTLPlacement, Prompt1BModalAccessibilityTests.testRTLCharacterDialogueKeepsActionsWithinWritingArea, Prompt1BModalAccessibilityTests.testRTLTourActionsRemainReachableAtAccessibilitySize.
- Verification: {"portable": "575 XCTest +21 Swift Testing passed", "native": "581 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "39 passed including9 actual SwiftSyntax cases", "syntax": "278 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN new RTL character/Tour UI/screenshot/focus/VO/motion checks; no Arabic T5 output claimed"}.
- Next action: Continue Part1 decorative painted-footprint requirements: header palettes currently pass only full PNG rectangles to the shared geometry and reserve full transparent canvases for later artwork. Measure the six exact bundled header PNGs non-destructively, persist their dimensions/alpha bounds/hash evidence, and connect actual palette placement to visible painted bounds while preserving approved assets/anchors/role sizes. Move only pure palette geometry into the existing Foundation layout file so its real production compositions can be regression-tested; no artwork substitutions or resource edits.
- Commit: containing commit for batch RTL-character-tail-orientation-and-shared-QA-motion-authority.

## Measured-header-artwork-painted-footprints-and-production-palette-regressions

- Parent checkpoint: 11bd0af4930ff86e004ab96bcffe55efdac73688.
- Source-order requirements: [28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 41, 42, 43, 44, 45, 443, 444, 448, 464, 469, 470, 476, 477].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioDecorativeArtLayout.swift, Fruitfolio/Core/DesignSystems/FruitfolioHeaderArtwork.swift, Tools/report_header_artwork_metrics.swift.
- Measured all six unchanged header PNGs with Pillow13.0.0 at alpha>12/255 and recorded exact dimensions, painted bounds and SHA256 in RUN_LOGS/Header-artwork-alpha-measurements.json. Existing approved contact/settings/FAQ asset selections, anchor sides, role size ranges and original image proportions are preserved; missing canonical FAQ art is not substituted. The actual production palette data/composition moved into the existing Foundation decorative geometry file so it can be executed by portable regressions. Header placement now passes each measured visibleAlphaBounds and reserves painted rectangles rather than transparent PNG canvases for subsequent decorations. Shared geometry exposes both canvas and painted frames; real headers render the resulting production placements. Three Swift regressions cover approved selections/prominent nominal art, actual all-palette compositions across constrained sizes, preserved canvas/painted ratios/safe bounds/role minima/noncollision, and overlapping transparent canvases with separated painted artwork. A new independently compiled production metadata report is compared with all seven palette references/six actual PNGs, alpha boxes and preserved hashes by a40th workflow test; the existing PNG-dimensions check follows the moved real model. Initial report execution exposed Linux JSONSerialization not accepting CGFloat directly; output now uses Double. An existing static dimension test initially referenced the old file and now references the real moved production model. Final578 portable XCTest+21 SwiftTesting and584 actual native-linked XCTest+21 SwiftTesting passed;40 workflow tests including9 SwiftSyntax cases and the new real Swift/PNG comparison,279 syntax parses and target build-file validation pass. No PNGs were edited. Device artwork appearance, faint-alpha edges, header pixels/DT/keyboard behavior and screenshots remain NOT_RUN; these measurements are not visual acceptance.
- Tests added/updated: Prompt1BDecorativeLayoutTests, HeaderArtworkMetricsTests actual compiled metadata/PNG comparison, WorkflowIntegrityTests.test_header_art_dimensions_match_all_bundled_assets.
- Verification: {"portable": "578 XCTest +21 Swift Testing passed", "native": "584 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed:9 real SwiftSyntax cases plus actual compiled Swift palette/PNG bounds/hash test", "syntax": "279 Swift files parsed,0errors; target build-file references resolved", "artwork": "6 originals hashed/measured;7 actual palette references independently match original PNGs; no resource edits", "Apple": "NOT_RUN rendered header artwork, visual collisions/DT/keyboard and screenshots"}.
- Next action: Strengthen actual shared character verification across all three assets and logical sides: the private Modal QA currently instantiates FruitPopupView directly rather than driving the actual root PopupCoordinator/host. Route the disposable fixture through the tested owned-session/shared host, add private character/trailing modifiers and all-character RTL/LTR UI capture paths, preserve private preference isolation and actual motion settings. Do not claim Apple UI execution on Linux. Then continue independent original-order requirements.
- Commit: containing commit for batch Measured-header-artwork-painted-footprints-and-production-palette-regressions.

## Actual-root-character-QA-and-all-asset-direction-matrix

- Parent checkpoint: 317edfdf44e589d5b7adab5acc19a6cf093d4d1e.
- Source-order requirements: [6, 13, 19, 20, 21, 22, 23, 24, 26, 27, 410, 411, 443, 445, 447, 468, 469, 470, 471, 472, 477].
- Source files: Fruitfolio/Fruit Popup Engine/Prompt06PopupGallery.swift.
- The disposable Modal QA route now requests a real owned character popup through the existing root PopupCoordinator/FruitPopupHost instead of drawing FruitPopupView directly and applying a separate fixture blur. It therefore exercises real host sizing, modal exclusion, opening/closing cues, dismissal, focus return and the same canonical actions as production. Preferences remain in the existing private QA suite, synchronized through the actual root settings/motion observers before initial presentation via one cancellable layout yield. Departure cancels only the fixture-owned request. Private modifiers select the existing strawberry/blueberry/peach assets and logical leading/trailing positions; unknown character input safely retains blueberry. The expanded actual UI matrix covers3characters x2directions x2logical sides at accessibility size/Reduce Motion, checks exactly one root speech scroll and reachable bounded action, closes and captures distinct screenshots. Existing normal/RTL modal tests now also use the actual root host. These Apple UI tests, sound playback, first-frame motion and rendered/focus results remain NOT_RUN; no screenshots were fabricated. Available regression suites578 portable XCTest+21 SwiftTesting,584 native-linked XCTest+21 SwiftTesting,40 workflow tests and279 syntax parses pass. This batch strengthens a real verification entrypoint; it does not claim those unrun runtime/visual gates have passed.
- Tests added/updated: Prompt1BModalAccessibilityTests.testEveryCharacterUsesTheRootHostInBothDirectionsAndLogicalSides, Prompt1BModalAccessibilityTests.verifyModal, Existing actual owned-session/coordinator and preference-isolation regressions.
- Verification: {"portable": "578 XCTest +21 Swift Testing passed", "native": "584 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 actual SwiftSyntax and actual compiled palette/PNG test", "syntax": "279 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN actual root3x2x2 character UI/screenshot/action/focus/motion/audio matrix"}.
- Next action: Correct the concrete standalone uppercase HCG protection gap: quantity lab labels already include HCG but standalone scientific identifier protection only recognizes hCG. Add the recognized uppercase spelling to the same identifier contract and regression cases for envelope, catalog and atomic second-paragraph failure, without a medical keyword formatting table or broad term inference. Continue independent source-order requirements.
- Commit: containing commit for batch Actual-root-character-QA-and-all-asset-direction-matrix.

## Whole-bibliographic-identifier-and-uppercase-HCG-translation-protection

- Parent checkpoint: 9d0c84febf42ce1c354b7d2bb2fa0c5324493781.
- Source-order requirements: [125, 162, 422, 424, 426, 431, 434, 443, 444, 466, 467, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioScientificQuantities.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- Standalone HCG now shares the same protected-identifier contract as hCG and the existing quantity label spelling. Introduced uppercase HCG is rejected in restored inference/catalog validation and whole-passage failure tests. Reference protection now includes complete bare/labeled DOI, PMID and PMCID identifiers; reference matching precedes the general quantity matcher so a bare DOI is protected whole instead of splitting off its numerical prefix and leaving a translatable suffix. This closes a concrete catalog/inference integrity gap where 10.1234/original could become10.1234/changed with unchanged numeric signatures. Added a full-identifier roundtrip regression with label variants/Unicode DOI suffixes and an actual catalog/service regression proving a changed suffix cannot display while paused and falls back only through the permitted runtime path. Existing deliberately corrupt second-paragraph contract tests now also include HCG/PMID additions and still reject whole passages. These are literal/citation integrity checks, not a semantic or clinical translation approval system. Final580 portable XCTest+21 SwiftTesting and586 native-linked XCTest+21 SwiftTesting,40 workflow tests and279 syntax parses passed. Official MADLAD resources/actual T5 clinical/offline device proof and Apple UI/typechecking remain NOT_RUN.
- Tests added/updated: Prompt1BScientificTranslationTests.testBareBibliographicIdentifiersAreProtectedWholeBeforeTheirNumericPrefixes, Prompt1BCatalogTranslationTests.testCatalogCannotAlterBareDOISuffixWhileKeepingItsNumericalPrefix, Prompt1BTranslationPipelineTests.testLateIdentifierOrProtectedBrandInjectionRejectsWholePassage.
- Verification: {"portable": "580 XCTest +21 Swift Testing passed", "native": "586 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 real SwiftSyntax and actual compiled palette/PNG comparison", "syntax": "279 Swift files parsed,0errors; no Apple typecheck", "external": "NOT_RUN actual official T5 output/tokenizer/clinical/native-language/device acceptance and Apple app/UI"}.
- Next action: Fix measurement editor stale-save protection. Current storage snapshot checks block outside writers but an open editor can still overwrite a newer measurement updated through the same store. Add a record-specific create/edit save intent in actual persistence/store, freeze the editor original/intent across parent redraws, preserve drafts on conflict and test stale same-store updates, deletion/recreation, creation replay, unrelated record updates, and outside-writer/reload behavior. Preserve exact values/units, locale provenance, dates and existing data.
- Commit: containing commit for batch Whole-bibliographic-identifier-and-uppercase-HCG-translation-protection.

## Record-specific-measurement-editor-save-conflict-protection

- Parent checkpoint: ef9e23ce5c69aafda769211c1e51506859a9bf45.
- Source-order requirements: [244, 246, 247, 248, 249, 250, 251, 278, 432, 458, 467, 471, 474, 477].
- Source files: Fruitfolio/Hormone Information/HormoneMeasurement.swift, Fruitfolio/Hormone Information/HormoneMeasurementPersistence.swift, Fruitfolio/Hormone Information/HormoneMeasurementStore.swift, Fruitfolio/Hormone Information/HormoneInformationView.swift.
- The actual measurement editor now carries a frozen create/edit intent captured at the Add/Edit action, instead of inferring whether a record is new from the changing store when a sheet redraws. Actual persistence checks candidate identity and current saved record before applying an edit; new writes require their allocated ID to be absent. A stale same-store update, deleted target, differently recreated target, mismatched ID or repeated creation is rejected before any persistence mutation. Unrelated measurements can change independently and remain preserved. Existing outside-writer and unknown-schema guards still run first. Editor original/intent are State snapshots, preventing parent publications from silently rebasing an old draft. Conflicts retain the draft and report an explicit recovery message; form errors use the existing protected translation pipeline and guarded accessibility focus after layout without stealing another popup focus. Exact result/unit/locale/date metadata and independent records remain unchanged. Five new actual-store regressions verify rejected-write bytes/revisions, creation replay/identity, deleted/recreated targets, independent edits/metadata/reload and outside writer followed by explicit reload/current-baseline recovery. Final585 portable XCTest+21 SwiftTesting and591 actual native-linked XCTest+21 SwiftTesting,40 workflow tests and279 syntax parses passed. Apple sheet redraws, focus/keyboard/draft UI and SDK typechecking remain NOT_RUN. Record equality is a current-content snapshot check, not a claim to detect a historical delete/recreate that restores every identical field; normal new records use distinct UUIDs.
- Tests added/updated: Prompt1BHormoneMeasurementTests5newactualstore/save-intentregressions, Existing measurement UI save/discard/Unicode regressions NOT_RUN.
- Verification: {"portable": "585 XCTest +21 Swift Testing passed", "native": "591 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 actual SwiftSyntax and actual compiled palette/PNG test", "syntax": "279 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN editor sheet/frozen-baseline/focus/keyboard UI and actual app SDK build"}.
- Next action: Fix a concrete Cycle daily-log actor reentrancy gap: Prompt20CycleDailyLogStore captures previous log/idempotency state then awaits MainActor.run for pure Prompt20DailyLogRules.makeLog, permitting another save to interleave and reuse a stale revision or rollback newer request state. Make pure rules explicitly nonisolated and execute validation/candidate construction synchronously inside the persistence actor while preserving its async public API. Add real concurrent-save revision/idempotency regressions. Then inspect independent daily-log file snapshot/future-field preservation without broad re-auditing.
- Commit: containing commit for batch Record-specific-measurement-editor-save-conflict-protection.

## Daily-log-nonsuspending-save-transactions-and-revision-integrity

- Parent checkpoint: 8f81d4e4f837bb7700579d7a16271f014b02d322.
- Source-order requirements: [67, 68, 461, 467, 474, 475, 476, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogStore.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift.
- New regressions first executed against the actual prior production store and reproduced the actor reentrancy bug:64 distinct same-day writes produced only revisions1/2 with final2, and32 copies of one idempotency request produced32 record identities. Two tests/four assertions failed before the fix; exact bounded evidence/source hashes are in RUN_LOGS/Daily-log-actual-concurrency-before-after.json. Pure daily-log rules and the stateless temperature formatter are now explicitly nonisolated. Both existing persistent and in-memory repository actors perform future-date validation/candidate construction synchronously within the actor transaction, with no MainActor suspension after reading saved/idempotency state. The async public interface and existing schema/clinical logic remain. Cancellation before entry or mutation rejects without writing; revision overflow/negative counters throw corruptPersistence instead of trapping, and tombstones reuse the checked candidate revision. Six new actual regressions exercise64 sequential revisions under concurrency,32 identical request identities committing once,16 independent real-file days/retry state across reload with byte-identical retries, the existing in-memory repository contract, cancellation/no file creation and Int.max rejection preserving original bytes. Final591 portable XCTest+21 SwiftTesting and597 actual native-linked XCTest+21 SwiftTesting,40 workflow tests and280 syntax parses passed. Apple app/typechecking/UI, device performance and clinical acceptance remain NOT_RUN. No assertion is made that serial transactions alone solve stale editors or outside-file changes; those remain separate independent work.
- Tests added/updated: Prompt20CoreTests6newactualconcurrency/cancellation/revisionregressions.
- Verification: {"beforeFix": "Actual64 same-day requests ->finalrevision2;32 identical requests ->32identities;2tests/4assertions failed", "portable": "591 XCTest +21 Swift Testing passed after fix", "native": "597 XCTest +21 Swift Testing passed with actual CPU llama after fix", "workflow": "40 passed including9 real SwiftSyntax and actual compiled palette/PNG check", "syntax": "280 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN app/UI/device/performance/clinical acceptance"}.
- Next action: Fix actual daily-temperature edit precision/source-unit loss: Prompt20DailyLogDraft.init(log:displayTemperatureUnit:) currently converts a saved original to the preferred display unit and rounds it through the display formatter, so a notes-only save can change the recorded value/unit. Keep edit inputs in their original unit with round-trip precision, make unit selection retain the entered number with a clear thermometer-value caption, and port the actual Foundation-only DailyLogViewModel using conditional genuine Combine so its real load/edit/save behavior can be tested on Linux. Preserve read-only conversion helpers. Then implement daily-log file snapshot/future-field guards and record-specific stale editor protection independently.
- Commit: containing commit for batch Daily-log-nonsuspending-save-transactions-and-revision-integrity.

## Daily-temperature-recorded-unit-and-roundtrip-edit-precision

- Parent checkpoint: aa87856f9c3a1d7568e9fac61a42cee1a116c79d.
- Source-order requirements: [432, 443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift, Tools/run_portable_swift_tests.py.
- Executed the actual daily-log view model on Foundation by conditionally retaining genuine Combine publishers/conformance on Apple and removing its unused SwiftUI import. No implementation replacement or fake publisher is used. Porting exposed an existing missing-return compiler error in validationMessage (one explicit return mixed with bare string switch cases); each case now returns explicitly. After that compile correction, two new actual-state/persistent-file regressions reproduced eleven assertions failing with the prior temperature algorithms: a notes-only edit changed98.6789012345F to37.04C or36.987654321C to98.6F solely due to preferred display units; unit selection converted/rounded37.123456789 to98.8 and back to37.11. Exact bounded evidence is in RUN_LOGS/Daily-temperature-actual-edit-before-after.json. Saved-temperature edit drafts now retain their original unit and use an unrounded round-trip Double string; preferred units apply when no reading exists. Unit selection retains the typed number, and the existing validation prevents an invalid new unit/value pair from overwriting saved data. A clear thermometer-value caption explains this actual input behavior. Read-only conversion/summary helpers remain available. Tests verify bit-pattern numerical preservation, original unit/reading type/note/provenance through notes-only saves/reloads for both units and independent defaults/invalid-input no-write behavior. Two existing pending-write/edit/cancellation view-model regressions previously gated on Apple frameworks now execute against the exact actual view-model logic; their delayed repository remains explicitly a sequencing contract fixture, separate from real-file tests. Final595 portable XCTest+21 SwiftTesting and601 native-linked XCTest+21 SwiftTesting,40 workflow tests and280 syntax parses passed. Original formatting/trailing zeros absent from the existing Double schema are not reconstructed. Actual Combine publication, Apple app typechecking/UI/thermometer keyboard and device checks remain NOT_RUN.
- Tests added/updated: Prompt1BDailyLogViewModelTests2newactualpersistent-temperature-regressions, Prompt1BDailyLogViewModelTests2previouslyguardedpending-write-regressions.
- Verification: {"beforeFix": "2actual tests/11assertions fail: notes-only saves converted/rounded original temperature and unit", "portable": "595 XCTest +21 Swift Testing passed after fix", "native": "601 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 actual SwiftSyntax and compiled production palette/PNG test", "syntax": "280 Swift files parsed,0errors; no Apple typecheck", "Apple": "NOT_RUN actual Combine/UI/native keyboard, app SDK build and physical-device acceptance"}.
- Next action: Protect the actual daily-log file store against outside writers, deletion and future fields: current loaded cache has no saved-file baseline and next persist can overwrite a newer file or resurrect cleared data; JSONDecoder silently ignores unknown fields. Add exact read-only snapshot/field-coverage guards before writes, explicit safe reload/retry for initial load failures, and real-file regressions preserving original bytes/unknown metadata. Preserve existing actor serialization, idempotency, tombstones, clinical observations and schema. Then add record-specific daily-log editor conflict checks and Unicode temperature entry without changing saved originals.
- Commit: containing commit for batch Daily-temperature-recorded-unit-and-roundtrip-edit-precision.

## Daily-log-exact-file-snapshots-future-fields-and-readonly-recovery

- Parent checkpoint: fc6e726558ae575751950b4b7b72c4732ce515c4.
- Source-order requirements: [8, 9, 11, 395, 432, 443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogStore.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift.
- The actual daily-log file actor now retains the exact loaded/written byte snapshot and checks it on cached reads and before writes. Newer/outside/cleared files reject with storageChanged; an old cache cannot recreate a deleted file through ordinary save/retry. Supported decoding is checked with the shared actual JSON field-coverage guard before any rewrite, preserving unknown root/log/temperature metadata and explicit nulls by rejecting unsupported data. Unsupported schema/history capacity, duplicate logical days/record IDs/request IDs no longer silently normalize or discard data; original bytes remain untouched. Explicit reloadSavedLogs is a read-only recovery capability and clears/rebuilds only in-memory state. Actual view-model retryLoad applies it only after an initial failed load without unsaved changes, never replacing an already loaded/dirty draft. Typed protected/corrupt/changed errors flow through the existing display translation pipeline with preserved typography; actual load/save retry actions now use canonical compact watercolor controls and sole press-cue ownership. Nine new actual core/view-model regressions cover two file writers, exact-byte whitespace changes, deletion/no resurrection, future fields/nulls, unsupported/ambiguous metadata, explicit reload failures, readable-current recovery and unsaved/failed draft retention. Initial malformed-archive fixture code attempted to mutate immutable log identity/date properties; corrected the raw JSON fixtures while keeping production identities immutable. Final604 portable XCTest+21 SwiftTesting and610 native-linked XCTest+21 SwiftTesting passed,40 workflow tests/280 syntax parses/all-app direct canonical sound-owner checks pass. Snapshot checks are not cross-process atomic compare-and-swap. Old editor protection after same-store changes or an explicit reload is a separate remaining requirement, not claimed solved here. Apple app/typechecking/UI/error focus/keyboard/audio remains NOT_RUN.
- Tests added/updated: Prompt20CoreTests6newreal-file-snapshot/schema/cleared-dataregressions, Prompt1BDailyLogViewModelTests3newactual-file/retry/draftprotectionregressions.
- Verification: {"portable": "604 XCTest +21 Swift Testing passed", "native": "610 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 actual SwiftSyntax and actual compiled palette/PNG test", "syntax": "280 Swift files parsed,0errors; all-app direct canonical cue scan clean", "Apple": "NOT_RUN actual error/reload/keyboard/Combine/audio UI, app SDK/typecheck and device acceptance", "scope": "Exact-file preservation and explicit read-only reload; record-specific stale editor guard remains next"}.
- Next action: Add record-specific daily-log editor save expectations and safe idempotent reconciliation. File snapshots alone cannot stop an old view-model draft overwriting a same-store update or saving after another view reloads a cleared file. Preserve the existing repository architecture/legacy explicit programmatic writes, require actual editor saves to match the active log snapshot captured on load/last confirmed save, check after idempotency lookup before mutation, and never silently rebase a mismatched saved receipt onto an old draft. Add real-store/two-editor/deletion/reload/retry regressions. Then implement Unicode temperature input and app-locale/canonical Gregorian daily date labels while preserving recorded originals.
- Commit: containing commit for batch Daily-log-exact-file-snapshots-future-fields-and-readonly-recovery.

## Daily-log-editor-snapshot-expectations-and-idempotent-receipt-integrity

- Parent checkpoint: e7612b482f06c178e36ccec64e12aa48a1c95096.
- Source-order requirements: [432, 443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogStore.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift.
- Actual daily-log editor writes now supply the active-record snapshot captured on load/last confirmed save. Both existing repository actors validate that snapshot after committed-request lookup and before any mutation, rejecting old same-store editors, concurrent first entries and cleared/reloaded/recreated days while permitting independent day changes. The existing async repository architecture and explicit legacy programmatic writes remain compatible through an unchecked adapter; the actual editor always uses the snapshot-bearing required method. Saved receipts are also checked against the attempted normalized recorded payload/owner/day before the editor updates its baseline. A retry that returns a newer different record cannot silently rebase an old draft and enable a later overwrite. Legitimate acknowledgement-loss retries reconcile without another revision; existing edits-during-save and cancellation reconciliation continue to pass. Six new actual-view-model/real-repository regressions cover two editors, deletion plus another client reload, new-day races, independent days, committed-write acknowledgement failure/retry, and superseded committed receipt rejection. The acknowledgement-error injector wraps the actual persistent actor and controls only its response boundary; it is explicitly not substitute storage. One additional real existing in-memory repository test covers checked snapshots and retry-before-expectation ordering. Final611 portable XCTest+21 SwiftTesting and617 actual native-linked XCTest+21 SwiftTesting,40 workflow tests and280 syntax parses passed. No disk schema or recorded data format was changed. Equality is a current-record/payload consistency guard, not a clinical validity review or cross-process atomic lock. Apple app/Combine/UI/focus/device acceptance remain NOT_RUN.
- Tests added/updated: Prompt1BDailyLogViewModelTests6newactual-editor/real-storage-reconciliationregressions, Prompt20CoreTests.testInMemoryRepositoryChecksActiveSnapshotAfterIdempotentRetryLookup.
- Verification: {"portable": "611 XCTest +21 Swift Testing passed", "native": "617 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 actual SwiftSyntax and actual compiled palette/PNG test", "syntax": "280 Swift files parsed,0errors; no Apple typecheck", "scope": "Real record-specific editor/receipt protection; no new disk schema; source/clinical UI/device gates remain open", "Apple": "NOT_RUN app SDK build, Combine publication, editor visual/focus/keyboard/device tests"}.
- Next action: Correct remaining actual daily-log localization input/display gaps: temperature validation/construction currently use Double(raw.replacingOccurrences(comma,dot)) and reject Arabic/Persian/Devanagari/fullwidth decimal digits; add one pure finite-number parser shared by both paths without rewriting stored original values/units. DailyLogView.displayDate is hardcoded en_US_POSIX and the caller calendar; use the app-selected locale with canonical Gregorian civil-day/timezone formatting, preserving English lowercase styling and unknown/skipped-day fallback. Add actual Foundation/store/view-model regressions for Unicode numeric entry and localized date labels, without claiming T5 translation or Apple UI execution.
- Commit: containing commit for batch Daily-log-editor-snapshot-expectations-and-idempotent-receipt-integrity.

## Daily-log-Unicode-decimal-input-and-selected-locale-civil-day-labels

- Parent checkpoint: 39d38c950f8115dd8482c9e40645a36fd86720db.
- Source-order requirements: [393, 397, 410, 432, 443, 444, 461, 466, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogModels.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogRules.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift.
- The actual temperature validator and recorded-value constructor now share one finite decimal parser. Unicode decimal digits normalize for parsing only, retaining the existing point/comma decimal meaning and supporting Arabic/fullwidth decimal separators. Draft text is unchanged; malformed/mixed separators, grouping marks, fractions, hexadecimal and nonfinite values reject, and existing broad typo bounds remain unchanged. Actual tests exercise Arabic/Persian/Devanagari/fullwidth/Thai/Bengali inputs and real view-model/file saves/reloads while preserving numerical values, chosen units and unknown reading type. The existing Double schema still does not retain original numeric script/trailing-zero formatting across reopening; that is not reconstructed or claimed. Daily-log date labels now use the actual app locale and the captured Gregorian civil day/timezone rather than hardcoded en_US_POSIX plus a potentially different-era calendar. English lowercase styling remains; other languages retain native capitalization/order. A skipped day keeps its exact ISO label instead of becoming a different date. Tests verify English/French/German labels, Arabic/Thai/Japanese Gregorian year stability under non-Gregorian calendars/timezone, and the Samoa skipped-day fallback. Four new production-source regressions pass with the complete suites:615 portable XCTest+21 SwiftTesting,621 actual native-linked XCTest+21 SwiftTesting,40 workflow tests and280 syntax parses. Apple rendering/bidi/keyboard/VO/DT and complete catalog/T5 localization remain NOT_RUN or externally blocked; no official MADLAD output is claimed.
- Tests added/updated: Prompt20CoreTests3newUnicode/date/civil-dayregressions, Prompt1BDailyLogViewModelTests.testUnicodeTemperatureEntryPersistsNumericalValueWithoutChangingDraftOrRecordedUnit.
- Verification: {"portable": "615 XCTest +21 Swift Testing passed", "native": "621 XCTest +21 Swift Testing passed with actual CPU llama", "workflow": "40 passed including9 real SwiftSyntax and compiled production palette/PNG test", "syntax": "280 Swift files parsed,0errors; no Apple typecheck", "locale": "Actual Foundation Unicode parse and ICU localized Gregorian labels tested; no new locale preference authority", "Apple/T5": "NOT_RUN bidi/keyboard/VO/DT rendering, app SDK build, reviewed full catalogs and official T5/device/clinical acceptance"}.
- Next action: Continue protection of the other two actual cycle files: Prompt13FileCyclePersistence and Prompt14FileOnboardingPersistence currently blindly encode saved values and ignore future fields, with no exact loaded-file baseline. Add read-only field/schema checks and exact snapshot checks before save/erase while preserving existing protocols, codecs and filenames. Inspect the actual high-level cycle/onboarding commit/rollback paths before editing to avoid introducing actor-reentrancy or false transaction guarantees. Add real-file outside-writer/cleared-file/future-metadata/erase regressions, then continue independent original-order work.
- Commit: containing commit for batch Daily-log-Unicode-decimal-input-and-selected-locale-civil-day-labels.

## Cycle-file-exact-snapshot-and-future-field-protection

- Parent checkpoint: 229cc2390a9c60cb94230987bcce6014edf1d71b.
- Source-order requirements: [443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CyclePersistence.swift, Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleModels.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingPersistence.swift.
- Both existing cycle file actors now retain exact loaded byte baselines, reject stale saves/erases and blind overwrites, preserve unsupported schema/unknown nested fields/explicit nulls, and allow explicit erasure only of the current exact baseline. Existing codecs, filenames, protocols and in-memory implementations remain. Eight actual-file regressions cover independent writers, deletion, cancellation, malformed/future records and explicit erase. High-level cycle/onboarding actor transaction and rollback gaps remain the next implementation task. No cross-process atomic compare-and-swap or Apple runtime acceptance is claimed.
- Tests added/updated: FruitfolioTests/Prompt1BCycleFileProtectionTests.swift.
- Verification: {"portable": "623 XCTest +21 SwiftTesting passed", "native": "629 XCTest +21 SwiftTesting passed", "workflow": "40 passed", "syntax": "283 Swift files parsed,0 errors; not Apple typechecking", "Apple/official MADLAD": "NOT_RUN or external resource blocked"}.
- Next action: Implement serialized high-level cycle operations with one final persistence write, rollback/reload after failure and no intermediate empty daily-log saves. Add actual-file counting/fault/concurrency regressions, then protect onboarding actor state and continue independent checklist work.
- Commit: containing commit for batch Cycle-file-exact-snapshot-and-future-field-protection.

## Cycle-actor-serialized-commit-and-failure-recovery

- Parent checkpoint: 1eaecb0bb09362bbe947d06d13d52fad85299423.
- Source-order requirements: [443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleStore.swift.
- All21 existing public async cycle operations now serialize across backend awaits and use private internal implementations to avoid recursive acquisition. Changed candidate archives commit once. Failure discards candidate state and forces a real backend reload, including lost-acknowledgment recovery. Clear atomically replaces the archive with the existing empty representation instead of erasing before a potentially failing save. Six actual-file tests cover linked observations, failed saves/clears, acknowledgment loss,21 concurrent notes and queued cancellation. The same tests against actual parent source reproduced7failures(1missing-file assertion error). Observation linkage already staged its log before this change; no old two-write observation regression is claimed. This is not cross-file/cross-process atomicity or Apple acceptance.
- Tests added/updated: FruitfolioTests/Prompt1BCycleTransactionTests.swift.
- Verification: {"portable": "629 XCTest+21 SwiftTesting passed", "native": "635 XCTest+21 SwiftTesting passed", "workflow": "40 passed", "syntax": "284 files parsed,0errors; no Apple typecheck", "project": "Build-file references resolved,notbuilt", "before": "6tests7failures(1unexpected missing-file assertion error),after6pass", "Apple/MADLAD": "Apple UI/device/official T5 output NOT_RUN or resource blocked"}.
- Next action: Protect Prompt14 onboarding actor state with serialized operations and rollback/reload on failed saves or erases. Keep actual cross-file cycle-start import recovery explicit: a committed cycle file cannot be physically rolled back by an onboarding acknowledgment failure. Add actual-file faults/concurrency/retry tests, then continue independent checklist requirements.
- Commit: containing commit for batch Cycle-actor-serialized-commit-and-failure-recovery.

## Onboarding-actor-serialized-save-erase-and-reload

- Parent checkpoint: e02adc992b8e55cb5ff5096574e0ea859339d55e.
- Source-order requirements: [443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift.
- Seven existing onboarding actor entry points now serialize suspended file/cycle operations. Changed drafts commit at one outer boundary. Failure discards candidate cache state and requires backend reload; explicit erase clears cache only after successful removal and can erase an unsupported current file without lossy decoding. Six real-file tests cover failed save/erase, acknowledgment loss,25concurrent date updates, unsupported erase and unchanged-draft completion retry preserving actual cycle record IDs. Parent-source rerun reproduced5failures across6tests; all now pass. Cross-file completion and arbitrary edits after partial completion remain explicitly unclaimed and are the next task.
- Tests added/updated: FruitfolioTests/Prompt1BOnboardingTransactionTests.swift.
- Verification: {"portable": "635 XCTest+21SwiftTesting passed", "native": "641 XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "286files parsed,0errors;noAppletypecheck", "project": "References resolved,notbuilt", "before": "6tests,5failures,0unexpected;after6pass", "external": "Apple UI/device,officialMADLAD output notverified"}.
- Next action: Implement one archive transaction for a complete onboarding date import/reconciliation so validation or file failure cannot partially import/delete period records. Replace Prompt14 per-date cycle-store calls with that API and add actual-file failure/provenance/counting tests. Then implement durable cross-file intent recovery and ordered editor saves without claiming cross-file atomicity.
- Commit: containing commit for batch Onboarding-actor-serialized-save-erase-and-reload.

## Onboarding-whole-history-single-archive-commit

- Parent checkpoint: 394f81bb72b03f5ba7f7313c1c6dc948d7fdf57d.
- Source-order requirements: [443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Pre-UI Cycle Tracker foundation/Prompt13CycleStore.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift.
- A new actual cycle-store operation validates the entire explicitly supplied date set before staging onboarding ownership migration, obsolete onboarding-only removals and missing-date insertions under one final archive write. Prompt14 completion and committed-history correction now use it rather than per-date public writes. Four actual-file regressions prove one-write multi-date import, stable IDs/no writes on unchanged retry, rejection of future dates before any change, failed replacement retaining exact bytes and reloaded records, and independent imported-record preservation. The original ISO8601 timestamp precision is unchanged; a failure comparison was corrected to use the actual decoded disk baseline. Cross-file durable intent recovery remains next; no cross-file atomicity is claimed.
- Tests added/updated: FruitfolioTests/Prompt1BCycleTransactionTests.swift:4new whole-history regressions, Existing Prompt14 and onboarding transaction tests.
- Verification: {"portable": "639 XCTest+21SwiftTesting passed", "native": "645 XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "286files parsed,0errors;notAppletypecheck", "testCorrection": "Initial one failure was comparing subsecond in-memory timestamps against existing second-precision reloaded codec; exact bytes unchanged. Final actual-disk baseline test passed.", "crossFile": "Durable intent recovery next; not atomic", "Apple/MADLAD": "Actual Apple UI/device/officialT5 output remainNOT_RUN/blocked"}.
- Next action: Persist a typed onboarding cycle-commit intent before touching the cycle archive, then clear it only after the cycle transaction and final draft acknowledgment. Resume exact validated intent on reload across failures/restart, test every persistence phase against real files, and preserve unsupported journals. Then order view-model autosaves and completion against pending edits.
- Commit: containing commit for batch Onboarding-whole-history-single-archive-commit.

## Onboarding-durable-cycle-intent-and-restart-recovery

- Parent checkpoint: 3796c60d7835e46c44167bacfcd0dcd688a752c1.
- Source-order requirements: [443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingModels.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift.
- An optional typed pendingCycleCommit preserves legacy draft decoding while recording exact dates, captured today, operation mode and completion request before the separate cycle archive write. Acknowledged final draft save clears intent; reload resumes a validated persisted request idempotently. Invalid/mismatched/duplicate/future intents preserve files. Explicit onboarding-only erase cancels pending intent without importing. Completed-date updates use the same path. Six new actual-file regressions inject before/after commit errors at intent,cycle,final-draft writes and recreate both actors; they verify recovery without duplicate IDs, subsequent edits, invalid journals and explicit cancellation. Outer operation skips redundant writes and does not manufacture cancellation failure after an acknowledged final write. This is resumable two-file recovery, not atomic cross-file/process visibility. Legacy unjournaled partial imports and ordered/stale-protected editor saves remain separately bounded.
- Tests added/updated: FruitfolioTests/Prompt1BOnboardingTransactionTests.swift:6new journal regressions and updated final-save retry, FruitfolioTests/Prompt1BCycleTransactionTests.swift:shared real-file fault boundary.
- Verification: {"portable": "645XCTest+21SwiftTesting passed", "native": "651XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "287files,0errors;notAppletypecheck", "project": "References resolved,notbuilt", "journal": "All three real persistence phases tested before/after physical commit with actor recreation", "Apple/officialMADLAD": "NOT_RUN or externally blocked"}.
- Next action: Port the actual Foundation-only onboarding view model behind conditional Combine, then order autosaves, retain unsaved drafts/errors and make finish await the latest successful edit. Add explicit store-side full-draft baseline expectations and real-file view-model regressions for rapid edits, failed loads/saves, stale editors and completion ordering. Continue independent checklist work without waiting for Apple SDK/official MADLAD hosts.
- Commit: containing commit for batch Onboarding-durable-cycle-intent-and-restart-recovery.

## Onboarding-editor-ordered-saves-stale-baselines-and-saved-receipts

- Parent checkpoint: de9b589d465faf5c386a917fe7296e7e221cf2d6.
- Source-order requirements: [393, 395, 443, 444, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingPersistence.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingStore.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingViewModel.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift.
- Actual onboarding view-model Foundation logic now compiles with conditional genuine Combine observation and uses ordered full-answer saves with acknowledged store baselines. Store refreshes actual bytes, compares saved answers/progress using existing codec precision excluding only administrative updatedAt, rejects different answers, and can recover an already saved receipt without saving the candidate again. Finish freezes editing, waits for the newest save and checks actual saved answers; failed loads/dirty reloads cannot overwrite defaults or drafts. Lost earlier acknowledgments do not prevent a newer queued answer after a matching physical-file receipt. UI offers canonical load/save retry, translates dynamic errors and syncs My Context from acknowledged savedDraft rather than uncommitted visible answers. Eleven actual file/model tests cover rapid edits, held writes/Finish, failures/retries, stale/same-store/outside editors, unsupported loads, saved receipt publication, completion acknowledgment loss, default clocks and stale completed receipts. Historical ABA/cross-process atomicity and Apple observation/rendering/sound acceptance are not claimed.
- Tests added/updated: FruitfolioTests/Prompt1BOnboardingViewModelTests.swift:11 actual model/file regressions, FruitfolioTests/Prompt1BOnboardingTransactionTests.swift:real-file suspension boundary.
- Verification: {"portable": "656XCTest+21SwiftTesting passed", "native": "662XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "288files parsed,0errors;notAppletypecheck", "project": "References resolved,notbuilt", "editor": "11actual view-model/file regressions passed; no mirrored implementation", "limits": "Apple UI/Combine rendering/VO/DT/sound and officialMADLAD device inference remainNOT_RUN/blocked; journal loader read ordering next"}.
- Next action: Fix downstream recovery ordering: Today, Calendar, Trends and Hormone Rhythm concurrently read cycle/onboarding snapshots, so onboarding journal recovery can produce an old archive/new draft pair. Await recovery before capturing cycle history, use one Today snapshot for Hormone Rhythm body/prediction input, compile the actual remaining Foundation loaders in portable suite and add real-file pending-recovery integration regressions. Then protect unsaved onboarding exit and retained shared daily-log confirmation controls.
- Commit: containing commit for batch Onboarding-editor-ordered-saves-stale-baselines-and-saved-receipts.

## Cycle-loaders-capture-history-after-journal-recovery

- Parent checkpoint: d938e03b29e0ad56608da26c7ec48d0699063258.
- Source-order requirements: [443, 444, 459, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Today/Prompt16TodayModels.swift, Fruitfolio/Cycle Tracker/Calendar/Prompt19CalendarLoader.swift, Fruitfolio/Cycle Tracker/Trends Engine/Prompt24TrendsLoader.swift, Fruitfolio/Cycle Tracker/Hormone Rhythm/Prompt22HormoneRhythmLoader.swift.
- Today,Calendar andTrends await onboarding journal recovery before capturing cycle history, retaining independent supplemental/log read concurrency. HormoneRhythm now derives its existing body context and unchanged Prompt17 prediction from one captured Today snapshot. Actual Trends/HormoneRhythm Foundation loaders now compile in portable tests. Four real-file tests hold final onboarding acknowledgment after the archive commits, then assert corrected day3/September5 marker/35day interval instead of old day7/September1/31days; recovery invents no temperatures/laboratory data. Identical tests against git-show parent actual four loaders reproduced8failures across4tests; current4pass. This fixes self-recovery read ordering, not atomic snapshots against arbitrary subsequent cross-file/external edits or clinical/rendering acceptance.
- Tests added/updated: FruitfolioTests/Prompt1BRecoveredCycleLoaderTests.swift:4actual recovery integration tests.
- Verification: {"portable": "660XCTest+21SwiftTesting passed", "native": "666XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "289files parsed,0errors;notAppletypecheck", "project": "References resolved,notbuilt", "before": "4tests8failures0unexpected;after4pass", "limits": "Cross-file atomic visibility,Apple screen/runtime/clinical and officialMADLAD output notverified"}.
- Next action: Migrate the active DailyLog local unsaved overlay to the existing identity-owned taped-white popup pipeline with canonical controls, delayed exit after dismissal and save/discard/keep-editing actions. Add onboarding dirty-exit protection using the same existing ownership pattern, with actual view-model discard/wait tests, cancellation/focus guards and source-level UI test coverage; keep Apple runtime NOT_RUN. Continue the original checklist and independent MADLAD/localization work.
- Commit: containing commit for batch Cycle-loaders-capture-history-after-journal-recovery.

## Cycle-owned-white-paper-confirmations-and-safe-draft-exit

- Parent checkpoint: 2d0ddc1ecdae16de146af3de30d3efe6d138fa29.
- Source-order requirements: [1, 2, 3, 6, 8, 9, 10, 11, 13, 18, 19, 20, 23, 26, 27, 63, 443, 444, 447, 461, 467, 474, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogViewModel.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingViewModel.swift, Fruitfolio/Cycle Tracker/Shell And Internal Navigation Layer/Prompt15CycleTrackerView.swift.
- Active DailyLog local two-tint unsaved overlay and inline populated-medication confirmation are migrated to existing identity-owned taped-white popup composition. The sheet has its own production PresentedPopupHost, placing shared blur/modal above presented content. Actions wait for owned dismissal, stale callbacks/view departures reject, focus restores only for this feature request, and removal targets the exact frozen medication entry. Remove/info/future Close use canonical small pills with one press-cue owner. Onboarding freezes and drains pending saves before exit; failed answers offer keep/save-for-exit/discard-local-draft through the shared owned modal. Discard preserves acknowledged data; save-for-exit does not complete/import periods. Native back/interactive dismissal guarded. Six new regressions:5actual-file cases plus1explicit suspended-save sequencing fixture. Existing modal ownership tests pass. Actual UI/VO/DT/motion/sound/typechecking remainNOT_RUN; source integration is not runtime proof.
- Tests added/updated: FruitfolioTests/Prompt1BDailyLogViewModelTests.swift:3confirmation regressions, FruitfolioTests/Prompt1BOnboardingViewModelTests.swift:3exit regressions, Existing real PopupCoordinator/OwnedPopupSession regressions.
- Verification: {"portable": "666XCTest+21SwiftTesting passed", "native": "672XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "290files parsed,0errors;notAppletypecheck", "soundSource": "ActualSwiftSyntax ownership checker emptyfindings;notplaybackproof", "project": "References resolved,notbuilt", "limits": "Feature-specific UI scenes/tests next; Apple VO/DT/motion/sounds NOT_RUN; officialMADLAD/device/clinical external blockers unchanged"}.
- Next action: Add disposable feature-specific Apple UI scenarios for the actual DailyLog and onboarding owned confirmations: private repository/files/preferences, root-host integration, accessible-size/reduced-motion actions, keep/edit/discard/save/removal bounds, focus/AX exclusion and lifecycle behavior. Register new QA route in private-shell allowlist; run all feasible compiler/workflow/Foundation checks without claiming unavailable Xcode execution. Then continue remaining original-order shared UI and independent MADLAD/localization requirements.
- Commit: containing commit for batch Cycle-owned-white-paper-confirmations-and-safe-draft-exit.

## Cycle-modal-disposable-Apple-UI-scenarios-and-keyboard-ownership

- Parent checkpoint: f528f2d80c53ec3f13d08cbbe87a186ff760cdb6.
- Source-order requirements: [6, 13, 18, 19, 20, 23, 26, 63, 443, 444, 447, 461, 467, 468, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Cycle Tracker/Prompt1BCycleModalRegressionHarness.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Cycle Tracker/Cycle Onboarding/Prompt14CycleOnboardingView.swift, Fruitfolio/Cycle Tracker/Daily Logging/Prompt20DailyLogView.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift.
- New DEBUG CycleModalQA route uses UUID temporary real files, explicit fixture owner, actual daily/onboarding views and actual production file actors/host. Private-shell preference/context allowlist includes the route. Three Apple UI test methods define28 cases atAccessibilityXXXL across motion override on/off and forcedLTR/RTL, checking owned paper actions/bounds44pt, AXexclusion, keep/discard/save actual-file readback, medication removal, screenshots and keyboard dismissal. Foundation portion compiles in both real test targets; SwiftUI/UIKit/XCTest UI portions NOT_RUN and NOTApple-typechecked. Stable feature accessibility IDs added. Shared host requests UIKit first-responder resignation for new or restored modal identity without replaying popup-open audio, closing source-level background keyboard ownership gap; UIKit runtime NOTverified. Mac gate script alreadyselects same UIclass. No production health/preferences/art/model resources changed by fixtures.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift:3new methods/28scenario executions defined,NOT_RUN onLinux, 40workflow tests including private-QA-route coverage, Actual Foundation QA boundary/fixture compiled in portable/native targets.
- Verification: {"portable": "666XCTest+21SwiftTesting passed", "native": "672XCTest+21SwiftTesting passed", "workflow": "40passed", "syntax": "291files,0errors;notAppletypecheck", "soundSource": "Empty actualSwiftSyntax ownership findings;notplaybackproof", "project": "Referencesresolved,notbuilt", "AppleUI": "3newmethods/28cases source-only; execution/screenshots/keyboard/UIKit/Combine/VO/DT/actualmotion/sound NOT_RUN", "external": "SDK/framework/officialMADLAD resources and clinical/approved-source blockers unchanged"}.
- Next action: Continue original Part1 active popup coverage: Prompt15PredictionInfoOverlay still uses local two-tint overlay, hard minimum292pt width,2/3line limits, font shrinking and30pt custom close button. Preserve actual popup_wooden_sign artwork while extending the existing shared measured surface/owned coordinator for this active prediction explanation; add measured actual-asset geometry and Foundation ownership/layout regressions plus Apple UI source scenario. Then review active account confirmation legacy path and remaining independent requirements/MADLAD source integration without repeating blocked network attempts.
- Commit: containing commit for batch Cycle-modal-disposable-Apple-UI-scenarios-and-keyboard-ownership.

## Shared-measured-wooden-prediction-popup-and-owned-focus

- Parent checkpoint: 1d251af6e1b7f74a94506991dc65d829c6e404a8.
- Source-order requirements: [1, 2, 3, 6, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 24, 25, 26, 27, 63, 443, 444, 447, 461, 467, 468, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Core/DesignSystems/FruitfolioPopupLayout.swift, Fruitfolio/Core/DesignSystems/FruitfolioWoodenSignPopup.swift, Fruitfolio/Fruit Popup Engine/FruitPopupModels.swift, Fruitfolio/Fruit Popup Engine/FruitPopupHost.swift, Fruitfolio/Cycle Tracker/Today/Prompt16PredictionPopupRequest.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayModels.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Fruitfolio/Cycle Tracker/Shell And Internal Navigation Layer/Prompt15CycleTrackerView.swift, Fruitfolio/Cycle Tracker/Prompt1BCycleModalRegressionHarness.swift.
- Active prediction explanation now extends the existing shared host with woodenSign measured surface and identity-owned requests instead of local two-tint/fixed292minwidth/line-limited/shrunken text/30pt-close overlay. Original594x517 wood and Peach/question-mark art preserved; hash2f42b8d3... unchanged. Chosen board writing rect(0.12,0.46,0.76,0.40) was visually reviewed against original PNG and excludes rope/top screws/edges; actualAlpha bounds cover fullcanvas, not an inferred writing contour. Text/actions scroll; close is compact canonical pill. Original info model moved unchanged to Foundation and one production request factory preserves title/body/progress without calculating new predictions. Tracker focus returns to actual explanation button; departed/queued/stale actions cannot dismiss others. Four new Foundation tests plus1actual compiler/PNG workflow test pass. Eight additional Apple UI scenarios use the real factory/host in portrait/landscape,forcedRTL andmotion modes atAXXXL; NOT_RUN. Initial CGFloat test ambiguity and LinuxXCTest synchronousMainActor discovery crash corrected in test harness with explicitCGFloat andasync test entrypoints; no app workaround or false runtime acceptance.
- Tests added/updated: FruitfolioTests/Prompt1BPopupLayoutTests.swift:wooden geometry regression, FruitfolioTests/Prompt1BPredictionPopupTests.swift:3 actual factory/owner/Escape regressions, development_workflow/tests/test_wooden_popup_metrics.py:actual compiled metadata vs original PNG/hash, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift:8new wooden scenarios source-only NOT_RUN.
- Verification: {"portable": "670XCTest+21SwiftTesting passed", "native": "676XCTest+21SwiftTesting passed", "workflow": "41passed including new actualcompiler/PNG test", "syntax": "295files parsed,0errors;notAppletypecheck", "soundSource": "Empty actualSwiftSyntax ownership findings;notplaybackproof", "project": "References resolved,notbuilt", "testRecovery": "Initial compile/test-only CGFloat ambiguity and synchronousMainActor XCTest discovery bridge corrected; final full suites pass", "AppleUI": "8newsource cases;36cycleQA cases total NOT_RUN/NOTApple-typechecked; realTrackerdata navigation nottested by layoutfixture", "limits": "No clinical/prediction recalculation/MADLAD output acceptance claimed; existing external blockers unchanged"}.
- Next action: Migrate active Prompt12AccountView sign-out/delete confirmation from legacy local overlay and Prompt12ConfirmationPopup to existing identity-owned white-paper pipeline with canonical controls. Freeze affected account/session intent, preserve local data by default, show actual typed failures instead of try?-closing dialogs, and verify failed/unconfigured auth/sync/delete operations against actual Foundation store. Preserve existing account architecture; no remote writes/push/merge. Add disposable Apple UI source coverage after coherent logic batch, then continue remaining original-order requirements and independent MADLAD/localization work.
- Commit: containing commit for batch Shared-measured-wooden-prediction-popup-and-owned-focus.

## Account-owned-confirmations-frozen-intents-and-acknowledged-local-signout

- Parent checkpoint: 1f107f9e2b2326b8fe005bd9479fdc7684d06498.
- Source-order requirements: [1, 2, 6, 9, 11, 13, 18, 19, 20, 23, 24, 26, 27, 63, 443, 444, 467, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyStore.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12SettingsView.swift, Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Tools/normalize_control_sound_ownership.swift.
- Active account sign-out/delete confirmations now use existing identity-owned white-paper pipeline, frozen identity/auth/pending/local-container expectation, post-dismissal execution, cancellation/lifetime/focus guards and visible translated typed failures. No try?-success or fake remote deletion. Sign-out makes1acknowledged local write, retains pending-local marker and local container/health files, rolls cache back on refused write; keepLocalData:false requires separate local review. Privacy toggles revert after refused actual record writes. Sync/deletion stay unavailable without fabricated cloud success. Existing decoder now protects explicit-null metadata via genuine JSON field coverage. Eight actual private UserDefaults/store/file regressions pass;2old-API probes against parent actualstore reproduced6failures, not mislabeled identicalafter suite. Actual SwiftSyntax tool removed9duplicate row-caller press cues; row nowuses globalCutePopButtonStyle and unbounded detail with accessible hint. Authdevelopment fixtures are not real authentication. UserDefaults readback notfsync/CAS. AppleUI/runtime remainNOT_RUN.
- Tests added/updated: FruitfolioTests/Prompt1BAccountActionTests.swift:8 actual store/defaults/file regressions, development_workflow/tests/test_control_sound_ownership.py:new actual SwiftSyntax navigation-row case, Existing AccountPersistence/Restoration/Ownership regressions.
- Verification: {"portable": "678XCTest+21SwiftTesting passed", "native": "684XCTest+21SwiftTesting passed", "workflow": "42passed", "syntax": "296files parsed,0errors;notAppletypecheck", "before": "2oldAPI probes6failures0unexpected; current8broader regressionspass;notidenticalafterprobe", "soundSource": "9duplicates removed from actual owned row callers; final all-app findings empty;notplaybackproof", "project": "References resolved,notbuilt", "external": "Productionauth/cloud absent; realremote deletion/sync notperformed. AppleUI/Combine/VO/DT/motion/audio and officialMADLAD inference stillNOT_RUN/blocked"}.
- Next action: Add disposable account-specific Apple UI route with actual AccountView/store, private UserDefaults/temporary cycle file and explicitly injected private username store. Cover cancel, pending-preserving sign-out, unconfigured remote deletion/sync, stale-identity confirmation and refused-write error without using production identity/preferences or any network operation. Register private-shell route and source UI scenarios with full feasible compiler/Foundation/workflow checks. Then continue remaining shared-modal original-order coverage and independent MADLAD/localization requirements.
- Commit: containing commit for batch Account-owned-confirmations-frozen-intents-and-acknowledged-local-signout.

## Account-action-disposable-UI-QA

- Parent checkpoint: ed6981592eb79d198cdef6dcb0d0437971ad67ce.
- Source-order requirements: [26, 63, 443, 444, 468, 471, 472, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12AccountActionRegressionHarness.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Tools/run_portable_swift_tests.py.
- Actual private-suite/account/cycle-file QA fixture and username injection; 20 Apple UI launch scenarios added but NOT_RUN. Root DEBUG RTL reaches shared popup host. SwiftPM unbatched compilation resolves reproducible compiler batching failure without skipping sources or altering persistence actor.
- Tests added/updated: FruitfolioTests/Prompt1BUsernamePersistenceTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 680, "native_CPU_XCTest": 686, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 297, "Apple_UI": "NOT_RUN; 20 new launch scenarios are source only", "official_MADLAD": "BLOCKED: official host excluded by enforced network policy", "sound_ownership": "actual SwiftSyntax checker: zero findings", "project_references": "resolved; not Apple build"}.
- Next action: Execute actual native T5 encoder/decoder through existing MADLAD runtime with explicitly synthetic untrained contract fixtures; retain official model/tokenizer blocker and do not claim semantic or official compatibility verification.
- Commit: containing commit for batch Account-action-disposable-UI-QA.

## Actual-native-synthetic-T5-encoder-decoder-contract

- Parent checkpoint: 8912dea4c0e970637e5fd726d2c4ab4e03d15888.
- Source-order requirements: [418, 419, 425, 426, 427, 428, 430, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Tools/run_portable_swift_tests.py.
- Actual production runtime executes native CPU nongated/gated T5 graphs from explicitly synthetic untrained temporary tensors. Five tests verify native encoder/decoder success counters, empty/partial output rejection, input/tag guards, cancellation, repeated release/reload and changed-file checksum revalidation. No official MADLAD, translations, clinical/device acceptance or verified language coverage is claimed.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 680, "native_CPU_XCTest": 691, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 298, "actual_C_API_typecheck": "PASS; not Apple ABI/link", "native_T5_contract_methods": 5, "official_MADLAD": "BLOCKED; synthetic untrained T5 only, no language or semantic approval", "Apple_UI_device": "NOT_RUN"}.
- Next action: Add deterministic nonempty synthetic T5 token-output contract and execute scientific protection through actual native runtime/service; no claim of linguistic translation. Then continue next independent source-order shared-modal requirements.
- Commit: containing commit for batch Actual-native-synthetic-T5-encoder-decoder-contract.

## Actual-native-T5-output-scientific-envelope-contract

- Parent checkpoint: 25475102288a31542e68bef099d521c9641d205d.
- Source-order requirements: [422, 426, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- A deterministic untrained T5 token followed by EOS executes the actual native nonempty return path. The actual translation service rejects this output when protected lab values/citation markers are absent. Six native methods pass; this is output/protection plumbing, not learned translation or semantic/clinical equivalence.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 680, "portable_status": "unchanged production Foundation branches; complete suite passed immediately preceding batch", "native_CPU_XCTest": 692, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 298, "native_T5_contract_methods": 6, "official_MADLAD": "BLOCKED; no linguistic/clinical acceptance from synthetic untrained tensors", "Apple_UI_device": "NOT_RUN"}.
- Next action: Complete local data-management popup modal identity, entry/return accessibility focus, Escape and one-opening-cue lifecycle using existing measured paper; preserve existing background blur/hit-testing and export behavior.
- Commit: containing commit for batch Actual-native-T5-output-scientific-envelope-contract.

## Data-popup-modal-focus-and-single-opening-lifecycle

- Parent checkpoint: 545621340ed66beefcf4b16bf0e62bdcec1af46f.
- Source-order requirements: [26, 63, 443, 444, 446, 447, 468, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementView.swift, Fruitfolio/Privacy Settings/Prompt12DataManagementRegressionHarness.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- Retains existing canonical background exclusion. Existing local data panel now has modal semantics, translated scalable heading focus, guarded accessibility Escape/once-only close path, account opener focus return and no repeated open cue on retained view reappearance. Eight source-only Apple UI scenarios plus real-picker-return cue assertions added; Apple runtime/typecheck NOT_RUN.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 680, "native_CPU_XCTest": 692, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 298, "sound_ownership_findings": 0, "project_references": "resolved; not Apple build", "Apple_UI": "NOT_RUN; 8 new data popup scenarios and picker-return assertions are source only", "official_MADLAD": "BLOCKED; synthetic T5 evidence does not verify translations"}.
- Next action: Integrate display-only catalog/MADLAD translation into canonical control labels without nesting interactive disclosure controls inside buttons or changing saved source labels; test actual state ownership, stale/cancelled results and original-preserving failure.
- Commit: containing commit for batch Data-popup-modal-focus-and-single-opening-lifecycle.

## Canonical-control-label-catalog-MADLAD-display-state

- Parent checkpoint: 998d8adba7e6f45b54a5d9fcf5c46d8803c9f90f.
- Source-order requirements: [393, 394, 395, 397, 418, 419, 422, 425, 426, 427, 429, 443, 444, 446, 466, 476, 477, 478].
- Source files: Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Core/Translation/FruitfolioControlTranslationState.swift.
- Canonical controls now resolve app-generated labels with actual catalog/scientific/MADLAD service, explicit original/machine/unavailable state, exact source/language ownership, cancellation and accepted-display retention after resource release. Root remains one genuine button with unchanged cue owner, shared semantic rendering/plain VoiceOver label and protected Fruitfolio/LifeBridge names. Eight actual-state tests and seventh native T5 contract method pass. Synthetic graph execution is not official MADLAD, language/clinical or Apple UI acceptance.
- Tests added/updated: FruitfolioTests/Prompt1BControlTranslationStateTests.swift, FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 688, "native_CPU_XCTest": 701, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 300, "sound_ownership_findings": 0, "control_state_methods": 8, "native_T5_contract_methods": 7, "Apple_UI_typecheck": "NOT_RUN; no Apple SDK", "official_MADLAD": "BLOCKED; actual synthetic T5 contracts are not linguistic or clinical acceptance"}.
- Next action: Apply the same protected display-only resolution to actual account navigation title/detail controls; retain single genuine button, artwork/cues, explicit source fallback, and accessibility identity. Then proceed to the next independent source-order requirement.
- Commit: containing commit for batch Canonical-control-label-catalog-MADLAD-display-state.

## Account-navigation-title-detail-protected-localization

- Parent checkpoint: 19eb52c3d4b23845991db94386e2d0c1cd66940c.
- Source-order requirements: [18, 24, 26, 47, 48, 62, 63, 393, 394, 395, 397, 418, 419, 422, 425, 426, 427, 429, 443, 444, 446, 466, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Core/Translation/FruitfolioControlTranslationState.swift.
- Actual navigation title/detail now resolve independently through shared catalog/scientific/MADLAD state, each with truthful original/machine/unavailable status, semantic/plain VO text and scalable type. Single genuine button/cue/artwork retained. Canonical controls share caption/hint/task keys. Actual independent concurrent title/detail regression passes; genuine Combine publisher test added but NOT_RUN on Linux.
- Tests added/updated: FruitfolioTests/Prompt1BControlTranslationStateTests.swift.
- Verification: {"portable_XCTest": 689, "native_CPU_XCTest": 702, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 300, "sound_ownership_findings": 0, "control_state_portable_methods": 9, "native_T5_contract_methods": 7, "Apple_Combine_publisher": "NOT_RUN; genuine publisher test requires Apple Combine", "Apple_UI_typecheck": "NOT_RUN; no Apple SDK", "official_MADLAD": "BLOCKED; synthetic T5 execution does not approve official/language/clinical behavior"}.
- Next action: Localize existing account/privacy route headers and explanatory text through shared display-only translation, preserving provider/email literals in signed-in status; retain existing layout/artwork and add Apple large-text header coverage.
- Commit: containing commit for batch Account-navigation-title-detail-protected-localization.

## Account-privacy-text-localization-and-literal-identity

- Parent checkpoint: 9e2b40d0e8267e508a13d4001cbe2f9cb2503ace.
- Source-order requirements: [18, 24, 47, 48, 62, 63, 393, 394, 395, 397, 418, 419, 422, 425, 426, 427, 443, 444, 466, 468, 471, 472, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12AccountPrivacyModels.swift, Fruitfolio/Privacy Settings/Prompt12OwnershipView.swift.
- Existing route headers/explanatory/status text now uses actual protected catalog/MADLAD display path and scalable type. Username remains verbatim. Actual Foundation account-status source escapes and masks provider/email as whole literals; two service regressions and actual native output rejection cover identity preservation. Original price token explicitly preserved. Four Apple large-text heading/identity scenarios added but NOT_RUN.
- Tests added/updated: FruitfolioTests/Prompt1BAccountActionTests.swift, FruitfolioTests/Prompt1BT5ExecutionContractTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 691, "native_CPU_XCTest": 704, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 300, "sound_ownership_findings": 0, "account_identity_service_methods": 2, "native_T5_contract_methods": 7, "Apple_UI_typecheck": "NOT_RUN; four new source-only launch scenarios", "official_MADLAD": "BLOCKED; synthetic graph contracts do not approve language or clinical equivalence"}.
- Next action: Localize actual canonical toggle labels/values and settings volume labels; format accessibility percentages for the selected locale without feeding numbers through translation or mutating saved preferences. Preserve binding-before-audio behavior and actual control identity.
- Commit: containing commit for batch Account-privacy-text-localization-and-literal-identity.

## Settings-toggle-volume-localization-and-selected-locale-percentages

- Parent checkpoint: 1852937cf7bd54d239567f3384d20b919d4c0d82.
- Source-order requirements: [7, 18, 24, 63, 393, 394, 395, 397, 410, 418, 419, 425, 426, 427, 429, 443, 444, 446, 466, 467, 468, 471, 472, 474, 476, 477, 478].
- Source files: Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Fruitfolio/Core/AppArchitecture/FruitfolioSettingsPercentage.swift, Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Fruitfolio/Core/AppArchitecture/Prompt1BSettingsControlRegressionHarness.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- Actual canonical toggle label/on-off values and volume label use shared protected translation state. Actual slider has 44pt minimum. Percentages use selected-locale Foundation formatting with bounds/nonfinite rejection, never translated or written back. Three formatter/private-store tests pass. Disposable registered actual-control QA scene and eight Apple source-only scenarios cover persistence, binding-before-cue, mute/motion/RTL; Apple runtime remains NOT_RUN.
- Tests added/updated: FruitfolioTests/Prompt1BSettingsLanguageTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 694, "native_CPU_XCTest": 707, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 302, "sound_ownership_findings": 0, "percentage_and_persistence_methods": 3, "Apple_UI_typecheck": "NOT_RUN; eight new actual-control launch scenarios source only", "official_MADLAD": "BLOCKED; no official language/clinical/device acceptance from synthetic T5 contracts"}.
- Next action: Supply the existing Today/Tracker previews with the settings authority required by localized controls and the Tracker presentation/context environment; then localize account input labels/placeholders and identity-confirmation toggle without translating entered user values.
- Commit: containing commit for batch Settings-toggle-volume-localization-and-selected-locale-percentages.

## Account-input-label-localization-and-preview-dependencies

- Parent checkpoint: 0b8af30668aabf3f980b9bda95212362ace9e524.
- Source-order requirements: [7, 18, 24, 63, 393, 394, 395, 397, 418, 419, 425, 426, 427, 429, 443, 444, 446, 466, 468, 471, 472, 474, 476, 477, 478].
- Source files: Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift, Fruitfolio/Cycle Tracker/Today/Prompt16TodayView.swift, Fruitfolio/Cycle Tracker/Shell And Internal Navigation Layer/Prompt15CycleTrackerView.swift.
- Actual account TextFields resolve constant source labels/prompts only; entered username/email bindings are never translation inputs. Explicit fallback/status hints, scalable email type and interactive keyboard dismissal retain drafts. Existing confirmation uses canonical toggle. Four source-only Apple UI scenarios check literal input/save/readback/signout/email. Existing previews receive settings locale/direction and Tracker context/popup host. Apple runtime/typecheck NOT_RUN; source inspection found username save acknowledgments need next-batch fault verification.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 694, "native_CPU_XCTest": 707, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 302, "sound_ownership_findings": 0, "Apple_UI_typecheck": "NOT_RUN; four new input/keyboard launch scenarios source only", "Xcode_previews": "NOT_RUN; source-level environment dependency repair only", "username_write_faults": "source gap identified; refused/partial-write reproduction is next batch", "official_MADLAD": "BLOCKED; no official language/clinical/device acceptance inferred from synthetic T5"}.
- Next action: Add genuine refused/partial UserDefaults username-save regressions against this parent source, then replace split name/consent writes with a versioned single-record commit while preserving legacy originals, shared APIs, future-format/stale protection, actual export coverage and read-only DEBUG inspection.
- Commit: containing commit for batch Account-input-label-localization-and-preview-dependencies.

## Recovered-workspace-and-acknowledged-shared-username-record

- Parent checkpoint: 7140173e0fad9f0edadbe395b7307784e5ee5280.
- Source-order requirements: [229, 230, 231, 232, 233, 369, 370, 371, 443, 444, 463, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioUsernamePersistence.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernameStore.swift, Fruitfolio/Core/DataExport/FruitfolioLocalDataExport.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift.
- Recovered original workspace after read-only confirmation of branch/7140173, five modified files and readable original bundle. Actual parent fault tests reproduced two failures. Shared username name/consent now commit in one acknowledged schema-2 record; legacy originals preserved, clear tombstone, bounded/future-field/type/stale guards, read-only inspector, frozen Account intent and 21-key explicit export coverage. Eight new username fault/protection tests and one actual export test pass. Original bundle retained; no assets/reset/merge/push.
- Tests added/updated: FruitfolioTests/Prompt1BUsernamePersistenceTests.swift, FruitfolioTests/Prompt1BLocalDataExportTests.swift.
- Verification: {"portable_XCTest": 703, "native_CPU_XCTest": 716, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 302, "sound_ownership_findings": 0, "before_actual_parent_fault_tests": "2 tests, 2 failures against 7140173", "focused_username_current": "11 tests, 0 failures", "original_recovery_bundle": "verified and unchanged; 7140173", "Apple_UI_typecheck": "NOT_RUN; no Apple SDK", "official_MADLAD": "BLOCKED; synthetic T5 evidence does not approve official translations"}.
- Next action: Apply frozen-name baseline, protected-record message/reload and dirty reappearance handling to existing Fruit Basket username editor using the same shared authority; preserve local-only/public-service-unavailable semantics and original typed draft.
- Commit: containing commit for batch Recovered-workspace-and-acknowledged-shared-username-record.

## Fruit-Basket-frozen-username-editor-and-safe-QA-lifetime

- Parent checkpoint: 0b37c0543180bc585c1b2f7d35ac8dbe32619376.
- Source-order requirements: [18, 24, 63, 229, 230, 231, 369, 370, 371, 393, 395, 397, 443, 444, 446, 463, 466, 468, 471, 472, 473, 474, 476, 477, 478].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift.
- Existing Game editor now passes frozen expected username, protects future records/reload, retains dirty drafts on reappearance and only reports acknowledged saves. Source-only label translation/canonical confirmation/save controls, original wrapping public name and confirmed-only display. Private QA future record and deinit-owned lifetime avoid transient background cleanup. Eight actual Apple source-only launch scenarios added; no Apple runtime/typecheck success inferred.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift, FruitfolioTests/Prompt1BUsernamePersistenceTests.swift.
- Verification: {"portable_XCTest": 703, "native_CPU_XCTest": 716, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 302, "sound_ownership_findings": 0, "Apple_UI_typecheck": "NOT_RUN; eight Game username launch scenarios source only", "official_MADLAD": "BLOCKED; no official language/clinical/device acceptance from synthetic T5"}.
- Next action: Replace unconditional whole-game Back with owned shared-paper save/discard/keep confirmation for dirty username drafts; freeze intent, wait for actual dismissal, preserve drafts/other records and add actual Foundation request/intent and Apple UI coverage.
- Commit: containing commit for batch Fruit-Basket-frozen-username-editor-and-safe-QA-lifetime.

## Owned-game-username-save-discard-keep-exit-session

- Parent checkpoint: f859c438fb87a0cdc952885ad8172c2513e487f5.
- Source-order requirements: [26, 63, 229, 230, 369, 370, 443, 444, 447, 463, 468, 471, 472, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioUsernameExitSession.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernamePersistence.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift.
- Actual Game Back now uses owned shared measured white-paper save/discard/keep for dirty username. Actual Foundation session freezes intent and delivers once after dismissal/all other popups, with protected Review, stale/replay/cancel guards. UI commits only acknowledged frozen intent and keeps errors/draft; discard is in-memory only. Six actual session/intent tests pass, 20 Apple launch scenarios added but NOT_RUN.
- Tests added/updated: FruitfolioTests/Prompt1BUsernameExitSessionTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 709, "native_CPU_XCTest": 722, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 304, "sound_ownership_findings": 0, "actual_username_exit_methods": 6, "Apple_UI_typecheck": "NOT_RUN; 20 new exit launch scenarios source only", "official_MADLAD": "BLOCKED; synthetic T5 contracts do not approve official language/clinical/device behavior"}.
- Next action: Protect Account Back from silently losing username and unsubmitted email drafts using the existing owned coordinator and shared paper; save only the username when available, never fabricate an email sign-in/save, preserve both drafts on errors and test all source choice variants.
- Commit: containing commit for batch Owned-game-username-save-discard-keep-exit-session.

## Owned-Account-username-and-unsubmitted-email-draft-exit

- Parent checkpoint: af96ea6ddb576ada1e5ef95bd257291e72d94e5d.
- Source-order requirements: [26, 63, 229, 230, 369, 443, 444, 447, 463, 468, 471, 472, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/FruitfolioAccountDraftExitRequest.swift, Fruitfolio/Core/AppArchitecture/FruitfolioUsernameExitSession.swift, Fruitfolio/Privacy Settings/Prompt12AccountView.swift, Fruitfolio/Privacy Settings/Prompt12SharedViews.swift, Fruitfolio/Privacy Settings/Prompt12AccountActionRegressionHarness.swift.
- Actual Account Back protects username/email/both drafts through existing owned shared paper. Email-only offers keep/discard; mixed save explicitly saves only acknowledged local username and discards unsubmitted email. Frozen identity exclusions survive to actual commit; failures retain both drafts/focus error, protected data offers no unavailable save. Three actual factory/intent tests pass; 32 Apple UI launch cases added but NOT_RUN.
- Tests added/updated: FruitfolioTests/Prompt1BAccountDraftExitTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 725, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "sound_ownership_findings": 0, "actual_account_draft_exit_methods": 3, "Apple_UI_typecheck": "NOT_RUN; 32 new draft-exit launch scenarios source only", "official_MADLAD": "BLOCKED; synthetic T5 contracts do not approve official language/clinical/device behavior"}.
- Next action: Measure actual native T5 blocking-call execution threads in DEBUG diagnostics and assert encoder/decoder/model/context calls stay off the physical main thread in CPU contract tests; retain separate Apple/device/official-model gates.
- Commit: containing commit for batch Owned-Account-username-and-unsubmitted-email-draft-exit.

## Actual-native-T5-blocking-call-thread-sampling

- Parent checkpoint: b27352d98543af73a373787cd50f1388adff7870.
- Source-order requirements: [418, 419, 427, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- DEBUG-only production call-site probes count invoking physical threads before real native model/context/encoder/decoder calls. Actual native synthetic T5 tests assert positive counts and zero Linux physical-main-thread invocations, including main-actor display bridge, reuse/reload, budget and cancellation. No text logs, release overhead, profiling or Apple/official model/clinical claim.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 725, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "native_T5_contract_methods": 7, "native_blocking_calls_physical_main_thread": "0 in asserted Linux synthetic T5 cases; positive probe counts verified", "actual_C_API_typecheck": "PASS; no Apple link/inference by that command", "Apple_UI_typecheck": "NOT_RUN; Linux thread sampling is not UIKit/iPhone evidence", "official_MADLAD": "BLOCKED; synthetic tensors do not approve official model/language/clinical behavior"}.
- Next action: Exercise real native T5 tokenizer dummy-prefix and control/user-defined language-tag metadata variants with Unicode/whitespace input through unchanged production inference; fix only evidence-backed compatibility failures and retain official tokenizer/model gate.
- Commit: containing commit for batch Actual-native-T5-blocking-call-thread-sampling.

## Native-T5-tokenizer-variants-and-preallocation-language-rejection

- Parent checkpoint: 759f8f47a69c58986ed1a4a17ab1aa793a0ba391.
- Source-order requirements: [418, 419, 425, 427, 428, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- Actual native untrained T5 graph accepts Unicode/whitespace with dummy-prefix on/off and CONTROL/USER_DEFINED language tags. Parent actual-native regression failed two allocation assertions. Production now rejects negative manifest language membership before checksum/model/context allocation while retaining every positive verification gate. Nine native methods pass; no official-tokenizer/language/device claim.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 727, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "actual_C_API_typecheck": "PASS; not Apple ABI/link", "native_T5_contract_methods": 9, "before_unsupported_regression": "1 actual native test, 2 failures on parent 759f8f4", "current_unsupported_language": "zero native load/context calls, no resources loaded", "native_tokenizer_variants": 4, "Apple_UI_typecheck": "NOT_RUN", "official_MADLAD": "BLOCKED; synthetic graph and metadata contracts are not official tokenizer, language or clinical verification"}.
- Next action: Delay actual native context/sampler allocation until exact language-token and input-token budget checks pass, preserving model/vocabulary loading and cancellation/free safety. Verify over-budget requests allocate no context and later valid requests reuse the model correctly.
- Commit: containing commit for batch Native-T5-tokenizer-variants-and-preallocation-language-rejection.

## Lazy-native-T5-context-after-exact-token-validation

- Parent checkpoint: 4a6f1c4bbc65783840e58da40547dd5b513be17a.
- Source-order requirements: [418, 419, 425, 426, 427, 428, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- Actual native parent budget regression failed two allocation assertions. Production now separates model/vocabulary preparation from context/sampler creation after exact tag/token-budget checks. Cancellation/failure cleanup covers partial/full states. Native tests prove model-only budget rejection, later model reuse, partial release/reload checksum protection and rejection of manifest-invented vocabulary tag before context. No zero-model-memory, official-model or iPhone footprint claim.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 729, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "native_T5_contract_methods": 11, "actual_C_API_typecheck": "PASS; not Apple ABI/link", "before_budget_regression": "1 actual native test, 2 failures against 4a6f1c4 allocation behavior", "overbudget_current": "model-only state, one sampled load, no context/encoder/decoder; valid retry reuses model", "Apple_UI_typecheck": "NOT_RUN", "official_MADLAD": "BLOCKED; synthetic T5 metadata/execution contracts do not approve official model/language/clinical/device behavior"}.
- Next action: Exercise concurrent real native translation and resource-release requests against the existing serialized actor; verify no partial output/resource use-after-free and successful final release/reload without claiming device/official-model performance.
- Commit: containing commit for batch Lazy-native-T5-context-after-exact-token-validation.

## Concurrent-real-native-T5-translation-release-and-reload

- Parent checkpoint: 59e8b545770e5958c5dc53c52069358151cf7fb3.
- Source-order requirements: [418, 419, 426, 427, 428, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- Actual native actor regression runs eight concurrent child tasks, each translating/releasing/translating with synthetic untrained T5. Sixteen complete fixed-token outputs, actual encode/decode/reload/thread counts and final release/reload pass. No scheduler/C replacements, no device stress/performance/leak/translation-quality claim.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 730, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "native_T5_contract_methods": 12, "native_concurrent_child_tasks": 8, "complete_native_translations_in_concurrent_phase": 16, "Apple_UI_typecheck": "NOT_RUN", "official_MADLAD": "BLOCKED; untrained synthetic execution does not approve official model, linguistic/clinical or device behavior"}.
- Next action: Replace game compact selector fixed-height/one-line shrinking text with existing canonical wrapping control while preserving selected artwork/traits and one cue owner; verify actual UI source scenarios without claiming Apple runtime.
- Commit: containing commit for batch Concurrent-real-native-T5-translation-release-and-reload.

## Wrapping-selected-game-controls

- Parent checkpoint: a4a1d6e3f28a0a5bd05f798c9a75bf5e17e42a2c.
- Source-order requirements: [7, 18, 24, 410, 411, 446, 468, 471, 472, 477].
- Source files: Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift.
- Game compact selectors delegate to the existing canonical wrapping localized control, retaining selected bold/trait and dimming artwork only. Removed duplicate button/sound owner and fixed-height single-line shrinking. Four Apple UI scenarios added but not run on Linux.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 730, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "SwiftSyntax_sound_ownership_findings": 0, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md"}.
- Next action: Replace suggested topic chips shrinking labels with the existing canonical localized wrapping control while passing the original source title to the existing game model.
- Commit: containing commit for batch Wrapping-selected-game-controls.

## Wrapping-localized-suggested-topic-controls

- Parent checkpoint: 15bd0f12010ae3eae869448274471fbc922af5f7.
- Source-order requirements: [7, 18, 24, 410, 411, 446, 468, 471, 472, 477].
- Source files: Fruitfolio/Global Controls/Prompt08GlobalControls.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift.
- Suggested topics delegate to canonical localized wrapping pills with preserved original artwork opacity and one cue owner. Existing research callback receives original source title. Four source UI scenarios added for large text, motion, RTL and input readback. Debug fixture now calls real openSetup rather than nonexistent setup case.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 730, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "SwiftSyntax_sound_ownership_findings": 0, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md"}.
- Next action: Bound native T5 tokenizer allocation using actual reported token count before allocating the token buffer; preserve exact context validation, source and failure behavior. Add actual native oversized-input regression.
- Commit: containing commit for batch Wrapping-localized-suggested-topic-controls.

## Bound-native-input-token-buffer-before-allocation

- Parent checkpoint: 8dffb3e6c52ba6adbf5db00bca87224ef84b4234.
- Source-order requirements: [418, 419, 425, 426, 428, 443, 444, 466, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift.
- Actual tokenizer required count is checked against context before Swift token-buffer allocation. Checked UTF-8 Int32 conversion and widened negation avoid Swift integer traps. Real native synthetic regression rejects oversized ASCII/Unicode with target-tag-only buffer and no compute context, then successfully retries. No official model/clinical/device quality claim.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 731, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 13}.
- Next action: Make existing leaderboard category controls wrap and retain at least 44pt targets without changing the original chalkboard artwork or suggesting unavailable worldwide rankings are configured. Add large-text selection regression scenarios.
- Commit: containing commit for batch Bound-native-input-token-buffer-before-allocation.

## Wrapping-chalkboard-categories-and-growing-writing-region

- Parent checkpoint: 38148356e8d5f2ade0fc30ae0c3f5b5ee3c745ba.
- Source-order requirements: [18, 24, 62, 63, 393, 394, 397, 410, 411, 446, 468, 471, 472, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift.
- Original chalkboard artwork now has content-owned growing center and preserved corners. Categories wrap with 44pt targets, actual shared control translation state, selected traits and one sound owner. Rank/name/score rows stop shrinking. Four Apple UI scenarios added but unrun; PNG unchanged; global rankings still explicitly unavailable.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 731, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 13, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Localize fixed leaderboard headings, rules and unavailable-service copy using existing translated content outside buttons; keep usernames/source data out of translation and preserve exact local totals.
- Commit: containing commit for batch Wrapping-chalkboard-categories-and-growing-writing-region.

## Leaderboard-fixed-copy-display-translation

- Parent checkpoint: 0115b12456b498f349213cc49fa90743adaa172f.
- Source-order requirements: [393, 394, 397, 410, 411, 431, 434, 466, 468, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Localizable.xcstrings.
- Fixed leaderboard headings/rules/unavailable-service copy uses the existing translation display with original wording/fonts. Four English source keys added; all 652 original catalog entries preserved exactly, now 656 keys with zero nonempty foreign units. No username/total value sent to translation, no fabricated translation. Apple catalog/UI remains unrun.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 712, "native_CPU_XCTest": 731, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 13, "catalog_keys": 656, "catalog_existing_entries_preserved": 652, "nonempty_foreign_units": 0}.
- Next action: Keep disposable regression preference suite alive across transient root disappearance/background; remove persistent-domain cleanup from onDisappear and attach it to fixture owner lifetime. Extend actual Apple background preference scenario, without touching production defaults.
- Commit: containing commit for batch Leaderboard-fixed-copy-display-translation.

## Disposable-root-preference-owner-lifetime

- Parent checkpoint: 01f9c584a6704311232ae386ab4ccfe0cc8fde0f.
- Source-order requirements: [443, 467, 468, 473, 474, 476, 477, 478].
- Source files: Fruitfolio/Core/AppArchitecture/SettingsStore.swift, Fruitfolio/Fruitfolio/ContentView.swift.
- DEBUG root preferences use a retained unique suite owner, cleaning only on owner deinit rather than transient onDisappear. Two actual Foundation tests prove independent domains, persisted settings across store recreation and cleanup after release. Eight Apple settings UI cases now background/reactivate; six invalid firstMatch chains corrected. Apple StateObject/Combine/lifecycle remains unrun.
- Tests added/updated: FruitfolioTests/Prompt1BSettingsLanguageTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift, development_workflow/tests/test_ui_qa_preference_isolation.py.
- Verification: {"portable_XCTest": 714, "native_CPU_XCTest": 733, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 13, "catalog_keys": 656, "catalog_existing_entries_preserved": 652, "nonempty_foreign_units": 0, "initial_workflow_failure": "One static assertion expected inline suite creation; updated route invariant and reran all 42 successfully"}.
- Next action: Translate the leaderboard total label separately from the locale-formatted integer using shared control translation state; keep actual count and usernames out of model input and preserve stored totals.
- Commit: containing commit for batch Disposable-root-preference-owner-lifetime.

## Leaderboard-label-and-locale-number-separation

- Parent checkpoint: d745bb3129c05fdeba2066b415d3b85210afd023.
- Source-order requirements: [393, 394, 397, 410, 411, 426, 431, 434, 466, 468, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Only fixed category total labels enter shared control translation. Original integer is separately Foundation-formatted with app locale and shown verbatim; model cannot rewrite it. Four English catalog keys added preserving 656 existing entries. Four new English/Arabic Apple UI cases read real private-fixture count with inference deliberately paused for fallback coverage; not executed on Linux.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 714, "native_CPU_XCTest": 733, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 13, "catalog_keys": 660, "catalog_existing_entries_preserved": 656, "nonempty_foreign_units": 0, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Exercise real Ask decoder runtime concurrently with synthetic native T5 translation/release using the shared backend, verifying translation resource release does not invalidate the existing separate Ask model. Keep this distinct from official MADLAD/clinical/device approval.
- Commit: containing commit for batch Leaderboard-label-and-locale-number-separation.

## Retained-Ask-model-through-native-T5-release

- Parent checkpoint: 6d7bec5d24a0511043c57c9c35402a5d9c794252.
- Source-order requirements: [418, 419, 427, 428, 443, 444, 466, 467, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioMADLADRuntime.swift, Fruitfolio/Core/Translation/FruitfolioLlamaBackend.swift, Fruitfolio/Core/Intelligence/FruitfolioResearchIntelligence.swift.
- New actual native cross-model regression retains a warmed Ask model, concurrently requests structured Ask output and eight T5 translation/release cycles, validates retained Ask decode afterward, then releases Ask and reloads T5. Focused and full CPU suites pass. Does not guarantee simultaneous C-call timing, official 3B memory budget, linguistic/clinical or device behavior.
- Tests added/updated: FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 714, "native_CPU_XCTest": 734, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 14, "catalog_keys": 660, "catalog_existing_entries_preserved": 656, "nonempty_foreign_units": 0, "cross_model_focused_XCTest": 1}.
- Next action: Replace FAQ question catalog-only label/state resolution with existing noninteractive control translation state; preserve original answers/copy, single button/sound ownership and expanded bindings. Add isolated large-text/RTL/fallback UI regression route.
- Commit: containing commit for batch Retained-Ask-model-through-native-T5-release.

## FAQ-question-state-translation-and-owned-disclosure

- Parent checkpoint: 1c930fcfb86ad9081f7f3069201e435122449218.
- Source-order requirements: [18, 24, 62, 63, 393, 394, 395, 397, 410, 411, 446, 466, 468, 471, 472, 477].
- Source files: Fruitfolio/Hub/FAQ/Prompt29FAQView.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Localizable.xcstrings.
- FAQ headings use display translation and questions/expanded states use shared noninteractive control translation inside one owned disclosure button. Wrapping, original answers, live expansion binding, chevron artwork and one cue retained. Isolated four-case large-text/Arabic RTL/motion/fallback UI scenarios added but unrun. Fifteen English source keys added preserving all 660 previous catalog entries.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 714, "native_CPU_XCTest": 734, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 14, "catalog_keys": 675, "catalog_existing_entries_preserved": 660, "nonempty_foreign_units": 0, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Coalesce concurrent identical in-flight machine translation requests without a persistent result cache, preserving per-caller cancellation, protected content validation, memory-pressure release and exact source bytes. Add controlled concurrency regressions plus real native evidence; do not retain deleted user material in a global result cache.
- Commit: containing commit for batch FAQ-question-state-translation-and-owned-disclosure.

## Bounded-inflight-translation-ownership-without-result-cache

- Parent checkpoint: 5df80f84cc54266d977f0ef2b689e82c520d2ae1.
- Source-order requirements: [418, 419, 422, 426, 427, 428, 429, 431, 434, 443, 444, 466, 467, 474, 475, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- Concurrent identical eligible machine requests share one validated operation, keyed by exact source/protection/language bytes. Per-owner cancellation, last-owner cancellation, generation guards and memory release preserve ownership. Bounded metadata overflows use original uncached caller path, never truncate/reject. No completed result/failure cache. Nine Foundation scheduling regressions plus actual native eight-owner decode/release/reload contract pass; no official-model/clinical/device memory claim.
- Tests added/updated: FruitfolioTests/Prompt1BScientificTranslationTests.swift, FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 723, "native_CPU_XCTest": 744, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 15, "catalog_keys": 675, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 9, "focused_initial_ownership_regressions": 7}.
- Next action: Inspect cancellation/release handling for unshared overflow translation work and ensure memory-pressure release cannot cause queued multi-paragraph work to silently reload resources; preserve per-caller cancellation and accepted displays, add production regression coverage if a concrete gap is confirmed.
- Commit: containing commit for batch Bounded-inflight-translation-ownership-without-result-cache.

## Owned-unshared-translation-release-and-paragraph-cancellation

- Parent checkpoint: 6bd4de7ae0750b7850f53a70ed85e62cd8b190b3.
- Source-order requirements: [418, 419, 426, 427, 428, 431, 434, 443, 444, 466, 467, 474, 475, 476, 477, 478].
- Source files: Fruitfolio/Core/Translation/FruitfolioScientificTranslation.swift.
- Overflow requests now have active cancellation handles, never source/result cache entries. Service release cancels shared and independent work before native release; caller cancellation affects only its owner. Exact prior service reproduced two real regression failures continuing after release into second paragraph. Eleven Foundation ownership cases and actual native pre-entry/post-first-paragraph release/reload cases pass. No official 3B/device/clinical claim.
- Tests added/updated: FruitfolioTests/Prompt1BScientificTranslationTests.swift, FruitfolioTests/Prompt1BT5ExecutionContractTests.swift.
- Verification: {"portable_XCTest": 725, "native_CPU_XCTest": 747, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 675, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "focused_current_ownership_regressions": 11, "prior_release_regression_XCTest": 1, "prior_release_regression_failures": 2}.
- Next action: Localize the fixed source-excerpt game question instruction separately from the literal cloze and original word choices, with a clear original-language notice. Preserve stored question/excerpt bytes, correct-answer mapping and scientific citations; use existing semantic/display controls and add exact-source presentation regressions.
- Commit: containing commit for batch Owned-unshared-translation-release-and-paragraph-cancellation.

## Exact-excerpt-framing-localization-and-scrollable-question

- Parent checkpoint: 55f8fcca515cf7db6c72eec7e0c42c71c6884793.
- Source-order requirements: [18, 24, 47, 48, 62, 63, 393, 394, 410, 411, 422, 431, 433, 434, 466, 468, 471, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28SavedResearchCopy.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketResearchBridge.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Known exact-excerpt question template splits read-only UTF-8 framing from the original literal cloze. Existing pipeline translates instruction/explicit source-language notice; original matching words and saved/citation data stay unchanged. Unknown templates retain complete text. Question flow scrolls. Two actual data/presentation regressions pass; four Apple large-text/RTL/motion/mapping UI cases added but unrun. Two English-only keys preserve all 675 prior catalog entries.
- Tests added/updated: FruitfolioTests/Prompt1BGameSavedSourceTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 727, "native_CPU_XCTest": 749, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 677, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "catalog_existing_entries_preserved": 675, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Remove the manual star chime from the canonical correct-answer catch navigation button, which already owns the soft-pop cue; retain the actual star-bank event chime. Extend actual opt-in audio request diagnostics and add a question-to-catch UI ownership regression without claiming physical audibility.
- Commit: containing commit for batch Exact-excerpt-framing-localization-and-scrollable-question.

## Catch-navigation-cue-owner-and-star-bank-event-diagnostics

- Parent checkpoint: 2c31047e69ea17a60148f57d5448683a1e5cb8f3.
- Source-order requirements: [9, 11, 12, 443, 446, 468, 472, 476, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Core/Assets/AudioManager.swift, Fruitfolio/Core/Assets/FruitfolioInteractionSoundDiagnostics.swift.
- Removed direct star-chime request from canonical correct-answer catch navigation; canonical pop remains and actual star-bank observer unchanged. Real opt-in AudioManager counters now include star requests. Eight Apple UI launches distinguish navigation from earned-star cues with mute/reduce-motion; unrun. Original audio payloads unchanged; Linux checks cannot verify AVFoundation/SwiftUI or physical audibility.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 727, "native_CPU_XCTest": 749, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 677, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Route existing fixed correct/incorrect game feedback and catch legend through shared display translation with serious-tone selection and citation protection intact; preserve original excerpt word choices and all domain fields. Extend actual question-flow UI scenarios.
- Commit: containing commit for batch Catch-navigation-cue-owner-and-star-bank-event-diagnostics.

## Question-feedback-and-catch-instruction-display-translation

- Parent checkpoint: 170821fbe5ce618ed5ce640d4571fe72c9e8bbf8.
- Source-order requirements: [47, 48, 59, 62, 63, 393, 394, 395, 397, 410, 411, 422, 431, 433, 434, 466, 468, 471, 472, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Existing correct/incorrect feedback and catch instructions/legend use shared display translation with original copy, serious-tone choice and explicit source protection. Domain questions, literal choices, scoring and metadata unchanged. Sixteen synthetic Apple UI launch cases added for correct/incorrect, serious, English/Arabic fallback and motion; unrun. Four English-only keys preserve all 677 prior entries.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 727, "native_CPU_XCTest": 749, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 681, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0, "catalog_existing_entries_preserved": 677}.
- Next action: Localize failed-attempt fixed feedback and round-statistic labels; keep count/score formatting separate from inference using the selected app locale. Preserve failed-round ledger/citations and serious retry tone. Add actual numeric integrity and result UI regressions.
- Commit: containing commit for batch Question-feedback-and-catch-instruction-display-translation.

## Failed-attempt-copy-and-locale-integer-statistics

- Parent checkpoint: db6f937b51b2f440e4be93acf05f25bbb2ee1d09.
- Source-order requirements: [18, 24, 47, 48, 50, 53, 59, 62, 63, 393, 394, 410, 411, 422, 431, 432, 433, 434, 466, 467, 468, 471, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28RoundLedger.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Fixed statistic labels use shared control translation, integers/fractions/signed scores use display-only Foundation locale formatting and never enter inference. Failure copy preserves serious/story choice; serious retry omits heart. Ending fruit is an explicit whole-name semantic anchor within a full sentence. Two Foundation formatting regressions across all locales and integer limits pass; eight Apple UI ledger/readback/retry scenarios added but unrun. Real QA model/store are observed. Twenty-seven English-only keys preserve 681 prior entries.
- Tests added/updated: FruitfolioTests/Prompt1BRoundLedgerTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 729, "native_CPU_XCTest": 751, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 708, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0, "catalog_existing_entries_preserved": 681, "focused_ledger_cases": 7}.
- Next action: Replace the generic translated-content original-text DisclosureGroup with the existing canonical wrapping/motion-aware cue-owned control. Preserve source text/translation origin and test the accepted catalog branch through an isolated genuine temporary catalog fixture, without official-model/clinical claims.
- Commit: containing commit for batch Failed-attempt-copy-and-locale-integer-statistics.

## Canonical-original-source-and-memory-retry-controls

- Parent checkpoint: 6d911f0c596f8ee094c7b15010c188f310bc0ac0.
- Source-order requirements: [7, 8, 9, 11, 18, 24, 62, 63, 393, 410, 411, 428, 431, 434, 443, 446, 466, 467, 468, 471, 472, 477].
- Source files: Fruitfolio/Core/Translation/FruitfolioTranslatedContent.swift, Fruitfolio/Core/AppArchitecture/FruitfolioLocalization.swift, Fruitfolio/Core/AppArchitecture/Prompt03SkeletonView.swift, Fruitfolio/Fruitfolio/ContentView.swift, Fruitfolio/Localizable.xcstrings.
- Shared original-source disclosure and memory-retry use canonical compact wrapping cue/motion-owned pills, explicit show/hide and selected state. Saved/source/origin data preserved. Genuine temporary nonclinical catalog fixture resolves protected markup through production service while inference paused; default bundle remains main and bundle path joins request key. Eight Apple size/RTL/mute/motion UI scenarios added but unrun. Two English-only keys preserve 708 prior entries.
- Tests added/updated: FruitfolioTests/Prompt1BSettingsLanguageTests.swift, FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 730, "native_CPU_XCTest": 752, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 710, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0, "catalog_existing_entries_preserved": 708, "genuine_temporary_catalog_focused_XCTest": 1}.
- Next action: Localize existing Fruit Basket tutorial headings/body using the shared display pipeline, keep step counters and exact game-state demonstrations separate from inference, preserve tutorial completion/progress and owned overlay accessibility. Add isolated tutorial progression regression cases.
- Commit: containing commit for batch Canonical-original-source-and-memory-retry-controls.

## Fruit-Basket-tutorial-copy-localization-and-ten-page-catalog

- Parent checkpoint: 1446227f58a863afdd82fc1cfa825d0eeee86f2d.
- Source-order requirements: [9, 11, 18, 24, 47, 48, 62, 63, 393, 394, 410, 411, 422, 431, 434, 443, 446, 466, 468, 471, 472, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28RulesCopy.swift, Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Preserved all ten actual title/body pairs and page-five demo in one ordered Foundation catalog, with actual source-copy comparison receipt. Title/body use shared translation; locale-formatted counter never enters inference. Canonical skip preserves existing skip-to-rules/completion behavior. Eight Apple full-progression/skip/Arabic fallback/motion UI cases added but unrun. Twenty-one English-only keys preserve all 710 prior catalog entries.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 730, "native_CPU_XCTest": 752, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 731, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0, "catalog_existing_entries_preserved": 710, "tutorial_source_pairs_preserved": 10}.
- Next action: Give standalone Fruit Basket tutorial modal scope an escape-to-existing-skip action, heading focus and once-per-logical-open/close cues; preserve current step across reappearance. Exercise actual cue/background/escape handler through private QA without claiming OS VoiceOver gesture verification.
- Commit: containing commit for batch Fruit-Basket-tutorial-copy-localization-and-ten-page-catalog.

## Tutorial-modal-focus-escape-cues-and-reappearance

- Parent checkpoint: 1435d1db8f1ced41e1a08bcc2312e82e8305467a.
- Source-order requirements: [6, 9, 11, 18, 23, 26, 27, 42, 63, 443, 446, 447, 468, 471, 472, 473, 476, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Core/Assets/AudioManager.swift.
- Standalone tutorial gains modal scope, real semantic-heading focus and guarded escape-to-existing-skip handler. Logical show/hide owns opening/closing cues; reappearance keeps current step. Private QA diagnostics capture initial presentation before onAppear and stay in modal scope. Eight Apple background/handler/cue cases added but unrun, with QA handler explicitly distinct from OS VoiceOver gesture proof.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 730, "native_CPU_XCTest": 752, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 731, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0}.
- Next action: Apply the same modal scope/heading focus and logical cue ownership to the existing storm note; keep pause/resume and guarded dismissal intact. Use actual overlay visibility for private diagnostic placement and add close/acknowledge/escape/background regression cases without OS-gesture or physical-sound claims.
- Commit: containing commit for batch Tutorial-modal-focus-escape-cues-and-reappearance.

## Storm-note-modal-focus-tone-and-logical-cues

- Parent checkpoint: f5255f38614ff81d1c3b3964ed93ff17c83027e4.
- Source-order requirements: [6, 9, 11, 18, 23, 26, 27, 42, 59, 63, 443, 446, 447, 468, 471, 472, 473, 476, 477].
- Source files: Fruitfolio/Fruit Basket/Prompt28FruitBasketView.swift, Fruitfolio/Fruit Basket/Prompt28GameRegressionHarness.swift, Fruitfolio/Localizable.xcstrings.
- Storm note gains modal scope and actual heading focus/return path, logical open/close cue ownership covering forced closes, and guarded close/acknowledge/shared-escape handling preserving pause/resume/storm key. Serious context uses neutral heading/hidden playful character. Actual overlay visibility places QA diagnostics inside the owner scope. Twelve Apple paired-mode background/dismissal cases added but unrun; one English-only key preserves 731 prior entries.
- Tests added/updated: FruitfolioUITests/Prompt1BModalAccessibilityTests.swift.
- Verification: {"portable_XCTest": 730, "native_CPU_XCTest": 752, "SwiftTesting_each_suite": 21, "workflow_checks": 42, "Swift_syntax_files": 306, "Apple_UI_typecheck": "NOT_RUN; Apple SDK unavailable", "official_MADLAD": "BLOCKED; see BLOCKERS.md", "native_T5_contract_methods": 16, "catalog_keys": 732, "nonempty_foreign_units": 0, "Foundation_shared_ownership_regressions": 11, "SwiftSyntax_sound_ownership_findings": 0, "catalog_existing_entries_preserved": 731}.
- Next action: Replace the gameplay HUD fixed-width single-line shrinking text with wrapping canonical controls and separately formatted numeric metadata. Reserve a measured header viewport and keep real playfield geometry synchronized below it, preserving collision/ledger logic; add available geometry regressions and Apple layout cases.
- Commit: containing commit for batch Storm-note-modal-focus-tone-and-logical-cues.
