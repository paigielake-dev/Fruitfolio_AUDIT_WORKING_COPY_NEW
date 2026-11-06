# Local data-management popup lifecycle

Apple status: **NOT_RUN**. The UI source is not typechecked against SwiftUI/UIKit
on Linux; VoiceOver, focus, Dynamic Type, audio playback, child-sheet transitions,
RTL screenshots and accessibility Escape remain runtime acceptance gates.

The existing account blur modifier already removes background accessibility and
hit testing. This batch preserves that behavior. The dim-only visual layer is now
explicitly hidden from accessibility and passes touches through to the already
blocked content. The existing measured white-paper component remains unchanged.

The actual data-management popup now declares modal identity, focuses its
translated scalable heading on first presentation and dismisses through one
guarded close path. Accessibility Escape cannot dismiss the underlying panel
while a measurement or export-picker child is presented. Feature navigation and
Close share the same once-only close guard/cue. Closing during export retains the
existing cancellation/temporary-folder cleanup. Account focus returns to the real
export opener after close while that view is still visible and no shared popup
owns presentation. Keyboard resignation uses the same UIKit operation as the
existing shared host. It has NOT_RUN here.

Opening sound is requested once per view presentation identity, instead of on
each appearance. Returning from a child sheet cannot request a second opening cue
for the retained panel. This is a source correction, not a reproduced Apple audio
failure. No claim of physical audibility is made.

The existing private-suite/temp-directory DataManagement QA route now initializes
its English source labels, Reduce Motion override and opt-in genuine AudioManager
counters before presenting. It restores focus to its actual background opener.
Forced RTL is guarded by the registered DEBUG route at the root host; production
language authority is unchanged. Layout-only English fixtures do not count as
reviewed translation.

A new XCTest UI method defines eight launch scenarios (mute x motion override x
LTR/RTL), each opening, closing and reopening the real panel at Accessibility XXXL.
It checks hidden background, 44pt Close, one open/close/press request per encounter,
accepted soft-pop starts under mute, and screenshot attachments. The existing
real document-picker cancellation test additionally asserts one opening request
and no closing request after returning. It still exports only its private fixture.
All these Apple UI methods remain NOT_RUN. Manual VoiceOver must verify heading,
reading order, Escape, child ownership and return to the account opener.

Available final verification: 680 portable XCTest +21 Swift Testing; 692 native CPU XCTest +21 Swift Testing; 42 workflow checks; 298 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings; Xcode project references resolve. These do not Apple-typecheck or execute the changed UI.
