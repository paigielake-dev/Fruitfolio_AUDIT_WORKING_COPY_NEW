# Strict accessibility diagnostics

Run29 and Run35 contain actual contrast/text-clipping audit failures. They remain failures. The screenshot for Run35's large Contact control visually contains burgundy text on the original pale painted pill, but that visual observation does not overrule XCTest or establish the source of its reported issue.

The next test revision records each audit issue's native type, descriptions, actual element label/identifier/frame and element hierarchy as an attachment and in the test log. The issue handler returns `false` unconditionally, preserving XCTest's reporting of every issue. No audit type, label, color, element or issue is filtered or accepted as an exception.

The diagnostic implementation uses Apple's `XCUIAccessibilityAuditIssue` properties and `performAccessibilityAudit(for:_:)` API:
https://developer.apple.com/documentation/xcuiautomation/xcuiaccessibilityauditissue
https://developer.apple.com/documentation/xcuiautomation/xcuiapplication/performaccessibilityaudit(for:_:)

These additional diagnostics have not yet executed. Their source is not proof that any contrast, clipping, VoiceOver or other accessibility requirement passes.

## Actual Run42 contrast viewport

The strict audit still fails the accessibility-XXXL Contact TikTok StaticText. The newly captured actual audit viewport is `4B6E1731-F770-48E5-8A27-40F535B66B4D.png` from artifact13098716389 (SHA256 ea66072e4b13e0e1c3bde00c8aa72a3fa070c19a204f0e67f1bb1a3807e8344b). The failing StaticText frame exactly equals the whole 292×218.3-point painted button, including its watercolor border and padding. Text is visibly burgundy on pale paper.

The candidate correction puts shell padding and background on a separate layout container, leaving the Text accessibility node bounded by its actual label. Artwork, color, font, wrapping, visual spacing, hit area and strict all-types audit are preserved. A new actual audit must establish whether this resolves the failure; no result is accepted from visual inspection alone.

Actual Run43 retained a Contact accessibility-XXXL contrast failure despite separating the visual layout container. The next repair exposes each named native action as one Button accessibility element with its exact full label and button trait, instead of duplicate StaticText nodes over the painted control. The strict all-types audit remains unchanged and unsuppressed; a regression assertion verifies one accessible action. Ask's header now wraps instead of enforcing one line and shrinking. The contrast reference helper now matches the actual #800000 palette. New behavior requires its own actual Apple run.

Audio follow-up: zero category volume now actually pauses loops and removes effects/typing players. Newly published volume values are cached before SettingsStore's willSet completes, so raising a slider resumes only a requested, enabled loop and never replays old cues. A real AVAudioPlayer regression test accompanies this repair; not yet accepted as passed.
