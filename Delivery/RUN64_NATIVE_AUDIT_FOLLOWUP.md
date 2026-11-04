# Actual Run64 native audit follow-up

Actual native audits: Account, Ask, Contact, FAQ, Library and Settings PASS; Cycle, Fruit Basket, Guide and Hub FAIL. These are default-size screen audits, separate from the largest Contact fixture.

Cycle's exact failing node was disabled continue: the feature applied 50% opacity to its entire control. Unanswered/invalid continuation remains disabled with the same conditions and traits, while its visual opacity is now 82% to keep burgundy text readable. No step is automatically answered or bypassed.

Hub contact and Guide make-a-new-guide Text nodes inherited their entire icon-plus-label container bounds (122×58 and170×147 respectively), rather than intrinsic text bounds. Their actual label layout now uses containment, and the actual native Button explicitly retains its complete label, matching the already verified repair pattern. Visible Text remains exposed and artwork/typography/actions are preserved.

Fruit Basket's failing node was the decorative cloud at exactly138pt width. Its individual image already requested hidden accessibility, but the real tree still exposed it through the decoration wrapper. The entire pure cloud/grass scene-decoration layer now explicitly opts out of accessibility. No functional or scientific content is hidden.

Existing unfiltered native audit tests are unchanged. All these repairs require actual rerun; source/syntax alone is not acceptance.
