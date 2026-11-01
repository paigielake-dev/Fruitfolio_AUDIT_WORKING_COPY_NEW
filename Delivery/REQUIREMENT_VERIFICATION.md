# Requirement verification status — incomplete

This is a partial verification report, not an exhaustive atomic Prompt 1B matrix.
The entire specification has not yet been reviewed and accepted.
The unit PASS rows below refer specifically to Run9, not every later revision.
Run10 had one native invalid-JSON failure; its two simulator smoke tests passed.
Latest source 04d55dbc adds grammar/ID constraints and a two-request evidence-
validation test. Its build passed; its unit/native result remains pending. The extracted
source register remains pending. No overall completion percentage is claimed.

| Scope | Actual result | Evidence / limit |
|---|---|---|
| Xcode application and both test-target compilation | PASS | Run9 build-for-testing, actual hosted Mac |
| Obsolete dynamic native dependency removed | PASS | Run9 linked-libraries gate |
| XCTest unit suite | PASS: 436 cases, zero failures | Run9 Unit.xcresult, log, case CSV |
| Swift Testing suites | PASS: 25 cases, zero failures | Run9 log; these include unit-level localization identities, not full UI translation |
| Swift native FruitfolioAI inference | PASS: one structured-draft fixture | Actual GGUF generation without fallback, 35.630 s; not full answer/citation quality acceptance |
| Bundled research JSON integrity | PASS: decoding/link/schema fixture | Not external bibliographic or clinical claim validation |
| Typing audio player state | PASS | Real AVAudioPlayer state/mute/reuse; listening/recording NOT VERIFIED |
| Static archive/project checks | PASS: seven checks | Not application behavior |
| Full navigation, every visual/state/animation and accessibility behavior | NOT VERIFIED | Simulator traversal still pending; no manual VoiceOver claim |
| Full local health-data runtime persistence | NOT VERIFIED | Model/store unit cases pass; UI create/restart/edit/delete pending |
| Every Prompt 1B requirement | NOT VERIFIED | Full atomic source-to-code/evidence audit unfinished |
| APA normalization and every claim-to-source citation | NOT VERIFIED | 183 ambiguous reference blocks excluded pending review |
| MADLAD official acquisition/integrity | PASS | Official Q4 + tokenizer/config resources, integrity manifest |
| MADLAD direct llama loading | FAIL | Original GGUF Candle layout unsupported directly |
| Experimental Linux T5 translation | FAIL medical gate | Paragraph altered citation, dropped safety sentence, introduced unsupported number |
| MADLAD iOS integration/offline execution | NOT VERIFIED / NOT ENABLED | No unsafe model substitution or cloud service |
| Full production account/sync/purchase behavior | NOT COMPLETE | Existing development simulations remain |
| Physical iPhone performance/memory/thermal and distribution acceptance | NOT VERIFIED | Linux and simulator results do not establish physical-device budgets |

Original-format Candle now actually executes the official Q4 on Linux and reproduces the same failed paragraph translation as the repack. Peak child RSS 4,806,620 KiB; iPhone compatibility is not established. Intro blending shows doubled book-edge contours in a sampled transition frame, so seamless transition acceptance remains FAIL/unfinished.


Latest actual Run11 result: compilation passed; 436 XCTest cases ran, with one
native case failing its evidence-validation assertion on both requests (two
assertion failures). All 25 Swift Testing cases passed. Both drafts decoded,
but neither passed the independent evidence validator. Native grounded-answer
acceptance remains FAILED, despite the earlier weaker smoke pass. The test now
attaches its synthetic-fixture drafts to support diagnosis in the next run.
No test assertion or safety validator was weakened to obtain a pass.
