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
