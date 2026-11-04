# Fruit Basket rain and good-fruit indicator repairs

Prompt 1B section 19P requires rain to create the puddle; 19M and the catch instructions distinguish starred good fruit from unstarred bad fruit. Inspection found that the existing rain schedule could select rounds without a puddle and that Prompt28MovingFruit computed a star size without rendering the star.

Every existing soft-rain round now includes its puddle, retaining the existing maximum of two obstacles rather than stacking an extra hazard. Good falling fruit uses the original registered fruitbasket_star indicator; bad fruit remains unstarred. Standalone stars remain separate drops and their existing single-use pass, scoring and target rules are unchanged.

The actual basket publishes whether it is crossing the puddle. Its existing displacement response is preserved; a small tilt and eased movement make that resistance visible, with no tilt or movement animation under Reduced Motion. Outside the puddle, the next movement resumes the original direct response. Two added deterministic tests cover every rainy round across levels 1–8 and 48 rounds, the two-obstacle ceiling, and resistance removal after exit. Actual Xcode execution and visual motion acceptance are pending.

This is not full Fruit Basket acceptance. Storm dialogue/card presentation, visibly grounded branch collision, vine-contact geometry/rustling, star and fruit settled catch treatment, full-round results, complete accessibility, actual audio quality, and cozy-difficulty play testing remain to be verified or implemented against the specification.

The new citation-save UI journey also had an exact-selector error in Run49: the nonempty library action is literally “+ add another little encyclopedia”, while the test queried the string without its plus prefix. The captured native hierarchy proves the real action was present. Correct that exact selector; retain all source-reference, restart, saved-content and version assertions. Run49 never reached the new citation save assertions and does not verify them.
