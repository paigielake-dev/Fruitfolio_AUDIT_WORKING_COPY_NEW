# Fruitfolio implementation checkpoint — incomplete

Primary goal remains the completed Prompt 1B application and final ZIP. This
checkpoint is not named FINAL_COMPLETE and is not release-ready.

## Source changes made

- Added FruitfolioResearchPackage.json: 395 topics, 5,477 note paragraphs,
  294 source records and 470 actual supplied-guide page excerpts.
- Preserved original wording and provenance. 183 ambiguous bibliography blocks
  are retained for review and excluded from approved citation display. A
  source's presence in the founder corpus is not independent scientific or
  external bibliographic verification. Topic associations do not establish
  claim-level entailment. Full raw DOCX paragraphs remain in the provenance.
- Added local hormone measurement models, required-field/decimal validation,
  exact unit preservation, history/filter/sort, editing, confirmed deletion,
  unsaved-change protection, a research-only educational library, and local
  erase controls. No measurement is passed to Ask or cycle predictions.
- Added Cycle Tracker -> My Context -> Hormone Information navigation.
- Measurement storage is local, backup-excluded and file-protected on iOS;
  corrupt/unreadable storage is preserved and cannot be silently overwritten.
- Retained prior Ask answers/citations in memory; cleared session/draft on
  exit; guarded against late completion; added cancellation checks and native
  inference memory clearing. Earlier answers keep their own save provenance.
- Reworked the Ask journal's paper and opening-art arrangement in source.
  Simulator visual behavior remains to be assessed.
- Moved full-library retrieval off the main actor and restricted source
  expansion to eligible source records.
- Replaced the unsafe one-token-overlap generated-claim acceptance rule with
  complete-evidence-chunk matching. Free paraphrase is currently restricted;
  unvalidated generated bridges/limitations are not displayed. This is a
  temporary extractive safety boundary, not a completed semantic entailment
  verifier. Generated content rejected by this boundary uses the existing
  research fallback.
- Added Intro skip and inactive-state interruption handling.
- Included the exact supplied cloud PNG and its registry entry. Updated FAQ
  decoration and button pop handling. A distinct canonical tulip asset has
  not been identified; the full founder art matrix is not verified.
- Corrected the absolute framework path, excluded legacy native binaries and
  app backups from synchronized membership, added a shared Xcode scheme,
  an Apple runtime build recipe, and a macOS CI workflow.

## Work that remains

- Exhaustive, page-grounded requirement extraction and full requirement-to-code
  review are unfinished. SOURCE_REVIEW_REGISTER.csv preserves 6,354 source
  blocks, not 6,354 approved/atomized requirements. All remain NOT VERIFIED.
  The DOC metadata says 320 pages; the request says 308. Text extraction has
  six replacement characters needing comparison with the original DOC.
- Full Prompt 1B feature/state, visual, localization, medical, accessibility,
  privacy, persistence and performance verification is not complete.
- The research import needs manual resolution of ambiguous references,
  accurate APA normalization, and claim-specific source validation. The
  supplied guide is secondary educational content, not independently retrieved
  primary-paper full text. No fabricated primary-paper excerpts were added.
- Hormone Rhythm opt-in scientific personalization, complete localization of
  new hormone screens and canonical popup/semantic rendering are unfinished.
- Full Personal Health Context categories, bidirectional onboarding/context
  synchronization and every context-policy boundary require further work.
- Existing Account sign-in, sync, export and ownership code includes development
  simulations (including timer-based synced/purchased states). These are not
  real authentication, remote sync, data exports or verified App Store access.
  They have NOT been represented as completed production functionality.
- Full universal artwork/popup/semantic systems and all call sites need review.
- MADLAD is acquired, not production-integrated. Its original Candle-format
  Q4 is incompatible with direct llama loading. An experimental lossless
  repack runs on Linux but failed paragraph-level safety/citation tests.
  Plausible short-sentence translations do not resolve that failure.
- Supported iPhone memory tiers, actual model co-residency, distribution size,
  latency, thermals and offline restart behavior are not established.

The GitHub development branch and draft PR preserve the source changes. The
Apple CI result and evidence index are authoritative for actual executed tests;
static checks are never a substitute for Xcode or simulator behavior.

Additional corrections after the first checkpoint: retrieval token indexes are
cached in the research actor, avoiding full-library tokenization per question;
Ask typing ASMR is connected to the independent audio channel with an 80 ms
throttle and player reuse. A real AVAudioPlayer-state test is staged. A selected
non-English language now receives an explicit original-English/translation-
unavailable notice instead of silently pretending its Ask answer was translated.
No new iOS test pass is asserted by these source changes.

The Debug build configuration now explicitly enables DEBUG, -Onone and incremental Swift compilation. Native XCTest accessibility audits for Hub and feature opening states are staged without suppressing audit issues; these are not substitutes for manual VoiceOver testing. New measurement test dates require explicit selection/confirmation rather than silently saving the current date.

Actual Run3 failed its test build because the DEBUG-only audio observation was
not compiled. The explicit Debug flags address that cause. The build log also
showed x86_64 compilation against an arm64-only simulator runtime and no direct
runtime-header search path. Debug/CI now target active arm64 and receive the
SDK-specific runtime module headers. The native model test now explicitly
fails if the llama module is absent, rather than conditionally disappearing.
These corrections require their own successful Apple rerun.

Run6 exposed a module redefinition: Xcode already copies the XCFramework module
map into its product include directory, so adding its original SDK header
folder exposed the same module twice. The redundant explicit header paths were
removed; active arm64 targeting and the mandatory native-inference test remain.
Unit/native tests and UI tests are now separate CI steps with early evidence
uploads, so a long UI traversal cannot hide the unit/model result.

Actual Run7 unit execution did not bootstrap: dyld looked for the obsolete
llama.framework dynamic dependency. No unit case can be counted as passed from
that run. The legacy framework was preserved under Vendor/LegacyMacOS, outside
Xcode's synchronized app tree, to prevent its automatic discovery/autolink.
An explicit linked-library gate and short simulator smoke stage are added
before the full UI traversal. A successful compile was not a runtime pass.
