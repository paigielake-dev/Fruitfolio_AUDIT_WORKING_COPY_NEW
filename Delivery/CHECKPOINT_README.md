# Fruitfolio — incomplete implementation checkpoint

This is the modified Xcode project, not the original repository and not a final
Prompt 1B release. Do not relabel it FINAL_COMPLETE or distribute it as accepted.
Full specification implementation/review and runtime acceptance remain unfinished.

## Open the application

Open `Fruitfolio.xcodeproj` on an Apple Silicon Mac. Select the shared
`Fruitfolio` scheme and an installed iPhone simulator. Run Product → Build,
then Product → Test. Choose your own signing team for a physical device.
`Vendor/llama.xcframework` is the actual Apple-built arm64 iOS/simulator static
runtime. Its vendored source and rebuild recipe are included. Intel simulator
support is not included. See `Delivery/BUILD_AND_RUN.md`.

## Included resources and changes

- Complete active Swift/SwiftUI sources, Xcode configuration, asset catalogs,
  original artwork/audio/research documents, localization and test targets.
- Original `FruitfolioAI.gguf` (491,400,032 bytes, baseline SHA-256 preserved).
- Official MADLAD `model-q4k.gguf` (1,654,597,280 bytes), tokenizer/configuration
  resources and verified acquisition integrity records, under `Models/MADLAD`.
- Actual supplied research JSON: 395 topics, 5,477 note chunks, 294 source records,
  and 470 page-located guide excerpts. All 7,365 original DOCX paragraphs remain
  in provenance. 183 ambiguous reference blocks remain ineligible for citations.
  These are not independently verified primary-paper bodies or normalized APA.
- Private local hormone records with validation, create/edit/delete, history,
  sort/filter, unsaved-change protection, corruption preservation and navigation.
- Ask session history/citations/save provenance, reset/cancellation fixes, native
  KV cleanup, off-main retrieval indexes and independent typing-audio controls.
- Supplied cloud artwork, intro skip, 7.43-second first-launch pacing and paced
  Reduced Motion crossfades, portable runtime linkage and a shared Xcode scheme.
- Latest native-output correction: JSON grammar, permitted evidence-ID literals,
  greedy selection and separate English grounded generation. Evidence validation
  remains independent; grammar is not a clinical entailment verifier.

## Actual verification and revision boundaries

At source commit `36f985f4`, hosted Xcode built the app and both test targets;
436 XCTest + 25 Swift Testing cases passed with zero failures. Native GGUF
structured generation ran without fallback in 35.630 seconds. Bundled research
JSON decoding and real AVAudioPlayer typing-state/mute/reuse tests passed.
A real simulator smoke test passed and exported Intro/Hub screenshots plus an
actual H264 recording. These artifacts were downloaded with SHA verification.

At `4b84f3d8`, compilation and both normal/Reduced Motion smoke tests passed,
but the native model test failed with invalid JSON. The later grammar correction
is in `04d55dbc`; its build passed, but its expanded native test was still running
at this checkpoint update. See current evidence/status files for any later result.
Do not attribute an earlier pass to code that had not been tested yet.

Full UI traversals are ongoing, not accepted. Captured default-size Intro/Hub
images are not every-screen, Dynamic Type, VoiceOver or clinical acceptance.
Some transition frames show doubled book-edge contours while different original
book assets blend; seamless transition acceptance is still unresolved. Typing
player-state testing is not an audible quality review or audio recording.
Physical iPhone memory, thermal, model co-residency and performance are unverified.

## MADLAD is NOT integrated

The original official Q4 executes with Candle's encoder–decoder T5 implementation
on Linux. It and the experimental llama adaptation produced the same failing
medical-paragraph output: a citation identifier changed, the safety sentence
vanished, and an unsupported TSH value appeared. This is not explained solely
by conversion. The Candle process peaked at ~4.58 GiB RSS on Linux; that is not
an iPhone measurement. Raw logs, source revision, probe and original model are
included. `TranslationInvestigation` is a reproducible research experiment,
not a SwiftUI dependency or an iOS translation runtime. No cloud or alternate
translation model replaced MADLAD. Do not enable it before the required gates pass.

## Remaining work and handoff

The entire Prompt 1B has not been exhaustively read/reviewed and verified.
`SOURCE_REVIEW_REGISTER.csv` is a pending extraction register, not a completed
binding-requirement matrix. The original DOC is preserved under `Specification`.
Full Hormone Rhythm adjustment/localization, health-context synchronization,
universal semantic/artwork/popup review, actual citation entailment and APA
normalization, complete screen/state/runtime/accessibility checks and genuine
account/sync/StoreKit behavior remain unresolved. Existing account code includes
development simulations. The partial verification report marks these honestly.

Source branch: `fruitfolio/prompt-1b-alignment`
Source commit: `04d55dbcd5c2972a1cfccb800be7b0ae7823c245`
Draft PR: https://github.com/paigielake-dev/Fruitfolio_AUDIT_WORKING_COPY_NEW/pull/1
Latest Apple run: https://github.com/paigielake-dev/Fruitfolio_AUDIT_WORKING_COPY_NEW/actions/runs/41269988574
Main/baseline `defa3c9c062230325262e6f36296d0877655ad5e` is preserved.

`PACKAGE_MANIFEST.json` provides per-file SHA-256 checksums. The archive validation
report verifies CRC, exact payload hashes, safe filenames, real extraction and
asset references. Archive structural validity is not product completion.


Latest actual Run11 result: compilation passed; 436 XCTest cases ran, with one
native case failing its evidence-validation assertion on both requests (two
assertion failures). All 25 Swift Testing cases passed. Both drafts decoded,
but neither passed the independent evidence validator. Native grounded-answer
acceptance remains FAILED, despite the earlier weaker smoke pass. The test now
attaches its synthetic-fixture drafts to support diagnosis in the next run.
No test assertion or safety validator was weakened to obtain a pass.
