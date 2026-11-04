Fruitfolio — Prompt 1B change breakdown

Part 1 — Universal app-wide systems

This part should be implemented first because nearly every other feature depends on it.

1\. Universal blur system

1\. Create one canonical blur treatment used throughout Fruitfolio.

2\. Apply identical blur appearance, intensity, opacity, and behavior wherever blur is required.

3\. Remove inconsistent feature-specific blur implementations.

4\. Specifically correct the different popup blur treatments in My Encyclopedias and Build Your Own Guide.

5\. Exception: retain the Hub’s existing tour-specific blur treatment.

6\. Ensure blur responds correctly to popup opening, closing, navigation, and other state changes.

2\. Universal button system

1\. Remove every gray button with a red outline.

2\. Replace those buttons with the appropriate existing control-pill artwork.

3\. Apply the same cute button-pop animation across the entire application.

4\. Include Cycle Tracker buttons, which were specifically identified as inconsistent.

5\. Keep button interaction, sound, and navigation synchronized.

6\. Prevent animations from introducing noticeable input lag.

3\. Universal popup layout system

13\. Create a dedicated shared Swift system for popup composition.

14\. Remove individual screens’ fragile popup positioning calculations.

15\. Measure each popup artwork asset’s actual dimensions and aspect ratio.

16\. Determine the usable writing area within each popup.

17\. Center text inside its intended writing area.

18\. Ensure text wraps without clipping, overflowing, or truncating with ellipses.

19\. Support different popup artwork sizes, text lengths, and screen sizes.

20\. Position popup buttons and other controls without collisions.

21\. Account for Strawberry, Blueberry, and Peach artwork.

22\. Preserve character proportions and prevent characters from overlapping text.

23\. Adapt popup layouts to Dynamic Type.

24\. Prioritize wrapping and responsive layout over reducing font size.

25\. Allow only small typography adjustments when necessary.

26\. Apply this system to all applicable confirmations, errors, help popups, character dialogue, and feature-specific overlays.

27\. Use the appropriate popup opening and closing sounds.

4\. Universal decorative artwork layout system

1\. Create a separate shared Swift system for decorative artwork.

2\. Preserve each screen’s founder-approved artwork selection.

3\. Preserve the intended location and relationship of each asset.

4\. Replace brittle absolute coordinates, negative padding, and fixed offsets where necessary.

5\. Position artwork relative to its actual parent container, paper, book, or other intended anchor.

6\. Account for actual image dimensions and aspect ratios.

7\. Account for transparent PNG boundaries and the visible painted footprint.

8\. Preserve watercolor proportions, visual weight, and orientation.

9\. Prevent artwork from overlapping headings, text, controls, citations, or scientific illustrations.

10\. Prevent decorative assets from colliding with one another.

11\. Respect safe areas and screen boundaries.

12\. Recalculate placement when content expands.

13\. Recalculate placement when the keyboard appears.

14\. Recalculate placement when a popup appears.

15\. Support different iPhone sizes and Dynamic Type settings.

16\. Resize, reposition, or temporarily omit artwork when necessary.

17\. Do not indiscriminately shrink artwork to make it fit.

18\. Do not randomly redistribute, substitute, or redesign the founder’s compositions.

The rule: existing design determines where artwork belongs; the shared system determines how it remains correctly positioned.

5\. Universal semantic text stylization

46\. Create one shared Swift system for bold, italic, and underline styling.

47\. Apply it across all eligible app-generated and dynamically presented text.

48\. Include Ask answers, fallbacks, Cycle Tracker, Fruit Basket, tutorials, popups, character dialogue, saved content, and guides.

49\. Remove separate feature-specific semantic formatting implementations.

50\. Determine emphasis from contextual meaning rather than keyword matching.

51\. Use bold for meaningful informational anchors.

52\. Include conditions, hormones, mechanisms, anatomy, nutrients, important numbers, and scientific concepts where appropriate.

53\. Preserve the rule that meaningful complete food names are bolded.

54\. Use italics for natural spoken stress.

55\. Use underline for symptoms and meaningful practical or qualifying clues.

56\. Restrict combined emphasis to situations where its meaning warrants it.

57\. Reserve extreme combined emphasis for the approved exceptional vocabulary and contexts.

58\. Avoid excessive formatting density.

59\. Reduce decorative emphasis in serious or safety-critical content.

60\. Preserve formatting during progressive rendering.

61\. Preserve formatting when content is saved, reopened, or inserted into guides.

62\. Prevent raw Markdown formatting markers from appearing on-screen.

63\. Preserve readable VoiceOver output.

64\. Ensure styling never causes text overflow or popup collisions.

6\. Performance and responsiveness

65\. Audit unnecessary loading delays across the application.

66\. Remove avoidable UI-thread blocking.

67\. Reduce redundant calculations and processing.

68\. Ensure animations and navigation remain responsive.

69\. Optimize transitions without changing their intended appearance.

70\. Preserve Reduce Motion behavior while eliminating unnecessary lag.



⸻



Part 2 — Introduction and Hub

2A. Introduction

71\. Make the entire introduction transition smooth and continuous.

72\. Target an overall duration of approximately 6–8 seconds.

73\. Give each important visual stage enough time to register.

74\. Add a watercolor ripple/puddle-style logo reveal.

75\. Center that reveal precisely on the book’s existing logo position.

76\. Make the logo appear gradually rather than abruptly swapping between states.

77\. Smooth the transition from the blank book to the branded book.

78\. Smooth the slightly-open and fully-open book transitions.

79\. Smooth the right-page zoom and transition into the Hub.

80\. Eliminate visible jumps, rushed stages, and avoidable lag.

81\. Add a bottom-left skip control using the existing control_next artwork.

82\. Place the text “skip tour” underneath that control, as specified.

83\. Make the reduced-motion introduction smooth without simply accelerating the sequence.

84\. Pause the introduction when the app becomes inactive.

85\. Resume from the current logical stage rather than restarting.

86\. Prevent timers and animations from progressing invisibly in the background.

87\. Restore a completed stage cleanly when exact animation-frame restoration is unsafe.

2B. Hub and guided tour

88\. Optimize Hub loading and navigation responsiveness.

89\. Apply the universal button-pop animation to Hub interactions.

90\. Play popup-opening audio when the tour invitation appears.

91\. Play popup-closing audio when the tour is dismissed or skipped.

92\. Calculate tour highlights from actual button positions and dimensions.

93\. Remove fixed-device assumptions from the tour spotlight geometry.

94\. Keep the highlighted region precisely aligned with its corresponding button.

95\. Apply semantic bold styling to important feature names in fruit-character tour dialogue.



⸻



Part 3 — Ask the Encyclopedia

This is one of the largest implementation parts.

3A. Continuous paper and conversation behavior

96\. Replace the limited answer presentation with a continuous vertically scrollable paper experience.

97\. Keep previous questions and answers visible throughout the active Ask session.

98\. Support multiple questions and long answers on the same paper.

99\. Make the paper extend downward without an obvious bottom edge.

100\. Prevent hard height caps and truncated answers.

101\. Keep the paper horizontally centered.

102\. Keep the text column centered inside the paper.

103\. Calculate layout using actual runtime dimensions.

104\. Prevent long answers from widening or shifting the paper.

105\. Allow text to wrap and expand vertically.

106\. Preserve scrolling in both directions.

107\. Automatically follow new streamed text only when the user is near the bottom.

108\. Do not force scrolling to the bottom while the user is reading older content.

109\. Preserve text selection, citation interactions, and accessibility reading order.

3B. Ask fruit artwork

110\. Position the orange slice, orange glow, and pear relative to the opening paper.

111\. Center the orange composition.

112\. Balance the other fruit artwork evenly on either side.

113\. Maintain visually consistent spacing.

114\. Use responsive paper-relative positioning.

115\. Prevent fruit artwork from overlapping text or controls.

116\. Make the decorations scroll naturally with the paper.

117\. Do not duplicate the fruit artwork on every extended paper segment.

3C. Session-only history

118\. Keep Ask conversation history only while the user remains in the active Ask session.

119\. Clear unsaved questions and answers when the user exits Ask.

120\. Clear unsaved draft text when the session ends.

121\. Open Ask with a fresh paper when the user returns.

122\. Do not silently restore old conversations after restarting the app.

123\. Do not persist transcripts through account state, analytics, or other hidden storage.

124\. Preserve only explicitly selected content saved through the Guide workflow.

125\. Retain citations and attribution for successfully saved content.

126\. Do not delete saved Guide content when the Ask session clears.

127\. Confirm successful saves.

128\. Prevent canceled or failed saves from creating persistent copies.

3D. Ask AI performance

129\. Audit the complete local retrieval and generation pipeline.

130\. Identify repeated retrieval and redundant model operations.

131\. Eliminate unnecessary sequential processing.

132\. Run independent operations concurrently where safe.

133\. Cache appropriate reusable results.

134\. Begin displaying validated content as soon as practical.

135\. Reduce delays for typed and suggested questions.

136\. Preserve research retrieval, claim/evidence mapping, medical safety, and citation validation.

137\. Preserve Canonical Voice and semantic styling during performance optimization.

3E. Answer presentation

138\. Use typing ASMR during answer presentation unless disabled by the user.

139\. Ensure answers remain fully contained inside the paper.

140\. Keep answer text horizontally centered within its readable area.

141\. Preserve selectable text and functional citation controls.

142\. Default to no educational illustration.

143\. Display scientific artwork only when it materially improves understanding.

144\. Do not select artwork merely because an asset matches a keyword.

145\. Generally limit an ordinary answer to one major educational illustration when genuinely appropriate.

146\. Reserve sequential scientific artwork for explicitly opened illustrated experiences.

147\. Do not create anatomy collages or use educational illustrations as decoration.

3F. Canonical AI writing

148\. Apply FruitsofLife.xo’s canonical writing style to normal Ask responses.

149\. Apply the same style to retrieval-only fallbacks.

150\. Apply it to model-failure and other substantive fallback responses.

151\. Remove any separate simplified fallback voice.

152\. Make fallback responses answer the user’s question before presenting supporting research.

153\. Preserve the human-bridge-to-evidence response structure.

154\. Use ☆ for main points and - for supporting points where appropriate.

155\. Follow lowercase and approved capitalization rules.

156\. Apply approved punctuation, contractions, rhythm, and warmth.

157\. Use kaomojis sparingly according to the canonical frequency rules.

158\. Suppress kaomojis in serious medical, safety-critical, abuse/consent, and laboratory-interpretation contexts.

159\. Adapt tone to reasonably evident conversational cues without diagnosing the user’s emotional state.

160\. Apply the universal semantic styling system to every substantive answer pathway.

3G. Research and source handling

161\. Ensure source displays use verified source information.

162\. Preserve source titles, publication details, and citation identifiers.

163\. Apply the document’s approved-source access rules without weakening the local research architecture.

164\. Preserve distinctions between supported, partially supported, and unsupported questions.

165\. Do not use unsupported-topic fallbacks before the available research architecture has been appropriately searched.

3H. Ask interaction changes

166\. Correct the help overlay to provide the requested actual help popup.

167\. Apply the updated popup system to Ask help and save interactions.

168\. Integrate the specified save-related visual treatment.

169\. Preserve correct transitions into the selected save destination.



⸻



Part 4 — My Encyclopedias and Guide Builder

4A. My Encyclopedias

1\. Change the empty-state wording to the specified “nothing here yet!” version.

2\. Make the populated decorative bookshelf identical to the empty-state decorative bookshelf.

3\. Remove duplicate bookshelf artwork.

4\. Do not add duplicate books, flowers, labels, bookmarks, plants, or other decorations.

5\. Keep actual saved encyclopedias in their separate interactive collection.

6\. Improve accessibility of sorting controls.

7\. Add appropriate character limits to encyclopedia titles.

8\. Add appropriate character limits to descriptions.

9\. Validate titles and descriptions against the specified non-explicit-content rules.

10\. Do not incorrectly reject legitimate sexual-health terminology.

11\. Improve the positioning of book titles and descriptions.

12\. Prevent text from bunching up against book artwork.

4B. Book-opening animation

182\. Replace the staged artwork-swap animation with a continuous coded book animation.

183\. Begin with the user’s actual selected book spine.

184\. Preserve the selected book color throughout the sequence.

185\. Move the same book forward from the bookshelf.

186\. Center it in front of the user.

187\. Animate the book opening continuously.

188\. Move from closed to partially open to fully open without discrete image swaps.

189\. Keep the complete open book visible.

190\. Do not zoom into the right-hand page.

191\. Smoothly reposition and scale the entire book into the inside-book layout.

192\. Render saved content inside that same book.

193\. Prevent book duplication, disappearance, jumps, and color resets.

194\. Remove the smaller library_book_open artwork from inside the book.

195\. Center the final coded open book near the top of the screen.

196\. Remove the extra bottom bookmark and flower decorations.

4C. Encyclopedia editing

197\. Allow users to add their own notes.

198\. Allow users to import their own images from their device or photo library.

199\. Allow users to add independently researched material.

200\. Let users choose the chapter or location where material belongs.

201\. Allow user-added content to be edited.

202\. Allow imported images to be removed or replaced.

203\. Provide save and discard behavior.

204\. Protect unsaved edits.

205\. Do not generate images on the user’s behalf.

4D. Shared Guide data

206\. Create one shared source of truth for guides.

207\. Synchronize guides across Ask, My Encyclopedias, and Build Your Own Guide.

208\. Ensure creation, renaming, editing, recoloring, and deletion propagate everywhere.

209\. Preserve guide title, cover style, contents, ordering, and edits.

210\. Prevent duplicate feature-specific guide records.

4E. Build Your Own Guide

211\. Apply the updated empty-shelf wording.

212\. Remove the decorative guide folder once a guide is selected.

213\. Show only the selected guide spine in its chosen color/style during editing.

214\. Keep the folder artwork in the initial Guide Builder state only.

215\. Apply the specified updated empty-section and empty-guide wording.

216\. Ensure the empty-section text includes the requested exclamation point.

217\. Apply universal popup layout rules to guide creation and editing.

218\. Replace the save confirmation with the specified Strawberry presentation.

219\. Show Strawberry with “saved!” directly underneath.

220\. Use the existing large control-card popup artwork.

221\. Adjust that card’s scale to fit the intended composition.



⸻



Part 5 — Settings, Account, My Context, and Hormone Information

5A. Settings and audio

222\. Add or verify separately adjustable volume controls for music, rain, sound effects, and typing.

223\. Ensure each control updates the actual audio system.

224\. Provide a functioning global mute.

225\. Provide a functioning background-music toggle.

226\. Prevent muted or disabled audio from continuing to play.

227\. Ensure audio preferences persist appropriately.

228\. Apply the shared control artwork and button interactions.

5B. Account

229\. Allow users to create and edit their username alongside their email.

230\. Use the same username for Account and Fruit Basket.

231\. Synchronize username changes automatically.

232\. Apply appropriate username character limits and moderation.

233\. Reject explicit or otherwise prohibited usernames.

234\. Enforce the requirement against using real names for leaderboard identities.

5C. Hormone Information — new section

1\. Add Cycle Tracker → My Context → Hormone Information.

2\. Keep the entry visible even when no measurements exist.

3\. Make hormone tracking optional.

4\. Add the specified empty-state text.

5\. Add an Add Measurement button.

6\. Support estradiol, progesterone, LH, FSH, testosterone, prolactin, and AMH.

7\. Include a controlled Other Hormone option.

8\. Add required fields for hormone, numerical result, unit, and test date.

9\. Add optional fields for sample type, cycle day, laboratory reference range, and notes.

10\. Validate numerical values and required fields.

11\. Permit decimal values.

12\. Preserve the exact entered units.

13\. Do not silently convert units or infer missing information.

14\. Support cancellation and unsaved-change protection.

15\. Store measurements locally.

16\. Preserve measurements across app restarts.

17\. Allow viewing, filtering, sorting, editing, and deleting records.

18\. Confirm deletion.

19\. Support repeated measurements over time.

20\. Restrict measurement graphs to actual recorded values.

21\. Never invent or interpolate missing laboratory results.

22\. Add an educational Hormone Library for the supported hormones.

23\. Include biological functions, reproductive relevance, measurement limitations, testing context, and appropriate medical guidance.

24\. Ground educational explanations in approved research.

25\. Reuse existing hormone artwork.

26\. Position artwork without interfering with controls or measurements.

27\. Ensure the feature supports Dynamic Type, VoiceOver, and accessible graph distinctions.

28\. Prevent diagnostic conclusions, medication dosing recommendations, or unsupported normal/abnormal classifications.

29\. Do not automatically share measurements with Ask.

30\. Require explicit user action before sharing measurements in Ask.

31\. Ensure deleted measurements are removed from local storage.

5D. Hormone Rhythm integration

1\. Keep Hormone Rhythm and My Measurements as distinct presentations.

2\. Add optional Adjusted Rhythm functionality.

3\. Allow users to opt into research-supported educational adjustments.

4\. Use actual measurements as reference points only.

5\. Adjust educational curves only when sufficient evidence and context exist.

6\. Preserve scientifically established hormone relationships.

7\. Never fabricate a user’s unmeasured hormone concentrations.

8\. Never label adjusted educational curves as actual measured levels.

9\. Distinguish educational curves from actual results with labels, legends, and styling.

10\. Add the specified educational-adjustment disclosure.

11\. Add the specified insufficient-information message.

12\. Allow users to restore the original Hormone Rhythm.

13\. Never overwrite actual measurement records.

14\. Never modify cycle-prediction confidence merely because hormone measurements were entered.

15\. Never use adjusted curves to diagnose, confirm ovulation, establish fertility, or recommend treatment.



⸻



Part 6 — Cycle Tracker and scientific education

6A. My Context personalization

281\. Connect optional My Context information to the relevant Cycle Tracker interpretation systems.

282\. Make context adaptation evidence-informed.

283\. Apply relevant context to predictions and educational explanations only where justified.

284\. Distinguish altered-cycle contexts from ordinary cycle estimates.

285\. Avoid treating context entries as diagnostic proof.

286\. Preserve uncertainty when available information is insufficient.

287\. Ensure context changes do not corrupt previous logs.

288\. Keep prediction confidence tied to appropriate prediction evidence.

6B. Today and cycle visualization

289\. Ensure context-dependent changes appear consistently in the Today presentation.

290\. Preserve distinctions between predicted and confirmed biological events.

291\. Avoid displaying unsupported fertility or ovulation certainty.

292\. Ensure wheel regions and contextual educational information respond correctly.

293\. Apply responsive artwork layout to the cycle wheel and surrounding content.

294\. Apply universal button animation to Today controls.

6C. Calendar and logging

295\. Optimize calendar loading and month transitions.

296\. Apply the canonical button animation to calendar controls.

297\. Apply the same interaction treatment to Log Today and related logging controls.

298\. Preserve correct daily-log state when moving between Calendar and Today.

299\. Prevent lag during date selection and log opening.

300\. Ensure logging overlays use the universal popup and control systems.

6D. Hormone and symptom education

301\. Keep educational hormone patterns visually separate from user-entered measurements.

302\. Apply context-appropriate explanatory limitations.

303\. Preserve accessibility and reduced-motion behavior.

304\. Apply universal semantic styling to generated educational explanations.

6E. Trends

1\. Replace separate symptom-specific trend presentations with the requested unified symptom-pattern graph.

2\. Ensure the graph presents recorded symptom information accurately.

3\. Preserve distinctions between actual observations and interpretations.

4\. Do not manufacture trends when insufficient data exists.

5\. Make the graph responsive and accessible.

6F. Scientific education modules

310\. Apply shared responsive artwork placement to relevant scientific education screens.

311\. Preserve the correct relationship between scientific illustrations and explanations.

312\. Prevent decorative artwork from interfering with interactive scientific hotspots.

313\. Apply the shared semantic text system to generated explanations.

314\. Keep medically sensitive educational personalization appropriately qualified.

6G. LifeBridge information

1\. Implement the added LifeBridge information-access requirement within Fruitfolio.

2\. Use the founder-corrected LifeBridge source-of-truth rule.

3\. Ensure the feature provides the authorized informational access described in Prompt 1B.

4\. Preserve appropriate privacy, research, and medical-safety boundaries.

5\. Avoid treating LifeBridge information as automatically available for unrelated AI claims.



⸻



Part 7 — Fruit Basket

This part includes substantial gameplay changes, not just visual corrections.

7A. Text and interface

320\. Apply the founder’s revised Fruit Basket home text.

321\. Apply the revised How It Works instructions.

322\. Apply the revised topic-selection wording.

323\. Explain starred fruit, unstarred fruit, and standalone stars.

324\. Apply the universal popup system.

325\. Apply canonical semantic styling and appropriate Fruitfolio dialogue rules.

7B. Game rules

1\. Preserve the required order: answer the question → catch fruit → reveal basket.

2\. Make the game distinguish between good fruit, bad fruit, and standalone stars.

3\. Introduce standalone stars as rare beneficial drops.

4\. Allow players to catch standalone stars independently of fruit.

5\. Make each collected star grant one star pass.

6\. Allow star passes to accumulate without a fixed maximum.

7\. Consume exactly one star pass when a bad-fruit catch triggers its protective use.

8\. Allow the round to continue when a star pass protects against an otherwise round-ending bad-fruit catch.

9\. Do not count standalone stars toward the good-fruit basket target.

10\. Require stars to fully enter the basket before being counted.

11\. Apply the same convincing flattened/settled catch treatment to stars and fruit.

12\. Ensure star drops remain genuinely rare.

13\. Update all game instructions and feedback to reflect the implemented star-pass rules.

Important source conflict

The corrections document contains two incompatible bad-fruit instructions:

\* One states that bad fruit ends the round when no star pass is available.

\* Another states that catching bad fruit applies a negative consequence but does not end the round unless a separate round-ending condition occurs.

Those cannot both govern the same gameplay event. This is a genuine conflict in the requested changes, so it must be resolved before implementing the final bad-fruit logic.

7C. Weather and obstacles

339\. Implement wind movement in code rather than relying solely on animated artwork.

340\. Use the existing wind artwork as the visual reference.

341\. Make wind alter fruit trajectories slightly.

342\. Play the appropriate wind audio.

343\. Use existing rain and rain-cloud artwork for soft rain.

344\. Make rain produce puddle obstacles.

345\. Animate puddles subtly while preserving the original artwork.

346\. Display Strawberry’s specified storm popup using the existing large contact-card artwork.

347\. Include the specified storm dialogue.

348\. Add basket inertia while the basket physically passes through a puddle.

349\. Visually communicate the basket’s resistance.

350\. Restore normal movement after leaving the puddle.

351\. Position branch obstacles as though growing from the screen edge.

352\. Make fruit bounce off branches and change trajectory.

353\. Make vines slow good fruit passing through them.

354\. Make vines slow standalone stars.

355\. Prevent bad fruit from using the vine-slowing interaction.

356\. Play rustling audio when appropriate objects contact vines.

357\. Make vine resistance visibly believable rather than merely changing an invisible velocity value.

7D. Difficulty progression

358\. Increase falling speed gradually as game levels advance.

359\. Base progression primarily on successfully completed rounds.

360\. Keep early levels slow and forgiving.

361\. Introduce bounded difficulty increases at later levels.

362\. Do not increase difficulty after an unsuccessful round.

363\. Stop increasing difficulty after the tested maximum level.

364\. Never change an object’s velocity while it is already falling.

365\. Keep gameplay challenging but not excessively demanding.

7E. Results and leaderboard

366\. Trigger basket reveal after the actual round finishes.

367\. Include accumulated fruit, stars, rewards, and consequences in the result.

368\. Update leaderboard instructions and game rules to match the final mechanics.

369\. Share one username source between Account and Fruit Basket.

370\. Allow username creation and editing from both locations.

371\. Apply non-explicit and non-real-name username requirements.

372\. Update accessibility descriptions, FAQs, and tests to match the corrected gameplay.



⸻



Part 8 — FAQ, Contact, and remaining visual corrections

8A. FAQ

373\. Remove bold formatting from FAQ questions.

374\. Use the existing approved tulip artwork.

375\. Use the existing sparkle artwork.

376\. Add an approved cloud only if a suitable asset already exists.

377\. Do not substitute an unrelated rain cloud simply because it is available.

378\. Apply universal popup and decorative artwork rules.

8B. Contact

379\. Use the existing green flecks artwork.

380\. Use the existing plum artwork.

381\. Use the existing sparkles.

382\. Correct any conflicting older artwork assignments.

383\. Preserve the intended composition through responsive placement.

8C. Remaining application-wide cleanup

384\. Remove remaining inconsistent gray/red buttons.

385\. Remove duplicated or incorrectly layered decorative artwork.

386\. Correct text that clips or overlaps artwork.

387\. Correct popup text that exceeds its writing area.

388\. Ensure all relevant character dialogue receives the shared semantic styling.

389\. Correct inconsistent button animations and popup sounds.

390\. Apply the updated accessibility behavior to all affected states.



⸻



Part 9 — Localization and MADLAD

This is the final implementation part, as you requested.

It should be audited alongside the other requirements, but implemented after the other corrections.

9A. App-wide language system

391\. Add one global language selector in Settings.

392\. Create one persistent source of truth for the selected language.

393\. Synchronize that language across all screens.

394\. Include onboarding, Hub, Ask, My Encyclopedias, Guide Builder, Cycle Tracker, Hormone Information, Fruit Basket, FAQ, Contact, Account, Privacy, and Purchase.

395\. Translate popups, notifications, validation messages, errors, and accessibility labels.

396\. Translate applicable fruit-character dialogue and dynamically generated content.

397\. Remove hard-coded English strings that bypass the selected language.

398\. Persist the language preference across restarts and navigation.

399\. Ensure users can always understand and access the language selector.

9B. Language coverage

400\. Support the specified major African languages.

401\. Support the specified major Asian languages.

402\. Support the specified major Middle Eastern languages.

403\. Support the specified major European languages.

404\. Support the specified major Pacific Islander languages.

405\. Support the specified major South American languages.

406\. Include relevant regional and Indigenous languages within that scope.

407\. Identify languages individually rather than using labels such as “African” or “Indian.”

408\. Build an extensible language architecture.

409\. Verify actual model/runtime support rather than assuming every requested language works.

9C. Layout and writing systems

410\. Support right-to-left writing systems where required.

411\. Adapt layout to different text lengths and writing systems.

412\. Prevent translated text from clipping or overflowing.

413\. Prevent translated text from colliding with artwork.

414\. Allow responsive container growth and scrolling.

415\. Preserve readable font sizes.

416\. Support Dynamic Type.

417\. Preserve Fruitfolio’s visual hierarchy, tone, and appropriate kaomoji usage.

9D. MADLAD integration

418\. Integrate the approved MADLAD model into the actual SwiftUI application.

419\. Implement working local inference.

420\. Connect the selected language to the Ask translation pipeline.

421\. Translate grounded answers after research and evidence validation.

422\. Preserve citations, scientific meaning, numerical values, and safety warnings.

423\. Preserve uncertainty and unsupported-evidence distinctions.

424\. Prevent translation from introducing new medical claims.

425\. Handle unavailable models and unsupported languages gracefully.

426\. Prevent incomplete translations from appearing complete.

427\. Keep inference off the main UI thread.

428\. Avoid excessive memory consumption.

429\. Do not silently reset the selected language.

430\. Ensure translation operates without internet access, cloud APIs, remote inference, or Ollama.

9E. Saved content and verification

431\. Preserve original saved content when switching languages.

432\. Preserve user-entered notes and measurements.

433\. Preserve citations and metadata.

434\. Do not silently overwrite user-authored content with translations.

435\. Verify the selected language across every applicable feature.

436\. Verify Ask responses in each supported language.

437\. Verify clinical meaning and safety-language preservation.

438\. Verify citations remain unchanged.

439\. Verify offline inference.

440\. Verify language persistence after restarting the app.

441\. Verify the actual MADLAD runtime executes locally.

442\. Test layout and accessibility for each supported writing system.



⸻



Part 10 — Testing, integration, and final verification

This is the final verification stage, but tests for each feature should be written alongside its implementation, not postponed until the end.

443\. Create tests for every applicable Prompt 1B change.

444\. Add tests to the project’s source rather than relying only on an external checklist.

445\. Test the shared blur system.

446\. Test button animation and sound consistency.

447\. Test popup text fitting and character placement.

448\. Test decorative artwork responsiveness.

449\. Test semantic styling across normal and fallback responses.

450\. Test intro timing, interruption, and reduced-motion behavior.

451\. Test Hub tour highlights on different screen sizes.

452\. Test Ask continuous scrolling and session-only history.

453\. Test successful and canceled Guide saves.

454\. Test Ask evidence grounding, citations, and fallback behavior.

455\. Test encyclopedia creation, editing, image import, and deletion.

456\. Test continuous book-opening behavior.

457\. Test Guide synchronization between features.

458\. Test Hormone Information creation, editing, deletion, and persistence.

459\. Test educational Hormone Rhythm separation.

460\. Test My Context adaptation and prediction safeguards.

461\. Test Cycle Tracker interactions and unified symptom trends.

462\. Test Fruit Basket star passes, physics, weather, and progression.

463\. Test username synchronization.

464\. Test FAQ and Contact artwork.

465\. Test audio preferences and global mute.

466\. Test localization and offline MADLAD integration when that phase is implemented.

467\. Run relevant unit tests.

468\. Run UI tests.

469\. Capture screenshots of all affected screens and meaningful nested states.

470\. Inspect visual layouts for clipping, collisions, duplication, and misalignment.

471\. Test accessibility, including VoiceOver and Dynamic Type.

472\. Test Reduce Motion.

473\. Test app backgrounding and foregrounding.

474\. Test persistence and data deletion.

475\. Test app performance and responsiveness.

476\. Produce logs and evidence for completed corrections.

477\. Identify remaining failures rather than declaring unverified requirements complete.

478\. Run the full integrated test suite after combining the corrected parts.



⸻



Implementation order

Part	Area	Dependency

1	Universal systems	Foundation for everything

2	Introduction and Hub	Depends on Part 1

3	Ask the Encyclopedia	Depends on Part 1

4	My Encyclopedias and Guide Builder	Depends on Parts 1 and 3

5	Settings, Account, Hormone Information	Depends on Part 1

6	Cycle Tracker and scientific education	Depends on Parts 1 and 5

7	Fruit Basket	Depends on Parts 1 and 5

8	FAQ, Contact, visual cleanup	Depends on Part 1

9	Localization and MADLAD	Last implementation phase

10	Final integration and verification	After all implementation phases