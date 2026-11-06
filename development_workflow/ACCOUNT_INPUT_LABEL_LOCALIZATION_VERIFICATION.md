# Account input labels and literal entered values

Account username/email titles, prompts and accessibility labels now resolve only
the constant app-generated label through the existing protected control state.
Neither usernameDraft nor email is a translation request source. TextField bindings
and native accessibility values retain the entered text. Pure Text prompts use the
shared semantic plain-text projection; no disclosure/retry control is nested in a
field. Status captions identify original/machine/unavailable text, with the same
status in the actual field's accessibility hint.

The existing non-identifying-name confirmation now uses the canonical watercolor
toggle and unchanged Boolean binding, giving it the shared label/value path,
minimum target/style and one sound owner. The email field's font scales relative
to body type. The existing account ScrollView allows interactive keyboard
dismissal so larger form controls remain reachable without discarding edits.
Existing username validation, save and sign-in action semantics are retained.

A DEBUG readback reads the actual injected username persistence for the registered
private Account QA scene. Four new Apple UI scenarios type an underscore username,
confirm/save it, check persisted readback, sign out through the real owned paper
flow, and type an email verbatim. Motion override and forced RTL vary at
Accessibility XXXL; identifiers remain attached to the actual fields/actions.
The QA sign-in identity, saved name and typed email are disposable fixtures. No
real authentication service or user credentials are used. These UI methods and
screenshots are NOT_RUN on Linux.

The two existing Today/Tracker previews now receive their existing SettingsStore
instance plus matching locale/direction. Tracker's preview also receives the real
presented popup host and context authority required by the existing screen.
Original preview content and app runtime architecture remain. Preview macros and
SwiftUI/Combine/UIKit behavior cannot be typechecked/executed here; these changes
are source-level dependency repairs, not verified Xcode previews.

Official MADLAD weights/tokenizer, language quality, clinical meaning, device
performance and all Apple input/VoiceOver/keyboard acceptance remain blocked/open.
The current username save implementation still needs explicit rejected/partial
UserDefaults-write regression coverage before a saved-message acknowledgment can
be treated as verified under those faults. That is the next independent batch.

Final feasible verification: 694 portable XCTest +21 Swift Testing; 707 native CPU XCTest +21 Swift Testing; 42 workflow checks; 302 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Changed Apple input and preview behavior remains NOT_RUN.
