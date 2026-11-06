# Owned whole-game exit for dirty username drafts

The game's actual Back control now checks its local username draft. Clean exits
retain the existing callback. Dirty exits use the shared measured taped-white
popup with Keep Editing, Save + Leave and Discard Edit + Leave. A protected record
offers Review instead of a save action known to be unavailable. The popup message
and routing metadata contain no entered username or saved identity fields.

The actual Foundation FruitfolioUsernameExitSession owns that request through the
existing coordinator/session. It freezes the name/consent/baseline intent, keeps
the first rapid request, rejects replayed/queued/departed actions, and delivers a
choice once only after real dismissal and any other active popup. It never saves
or navigates from the popup callback. Cancel clears pending work without touching
another owner's request. Escape cancels and returns focus to Back.

The actual game then commits the frozen intent through the acknowledged shared
username authority. Errors keep the draft, require renewed confirmation, return
to the editor and focus the readable error. Keep returns to the field. Review
reloads without saving. Discard replaces only this in-memory edit with the current
saved name. Successful Save and explicit Discard call the existing game exit
callback after dismissal; other saved domains are not erased. Keyboard focus is
released before presentation. Owner departure cancels pending actions.

Six actual Foundation tests execute dismissal ordering and frozen commit, rapid
presentation/stale-name rejection, protected Review, distinct Keep/Discard/Escape,
waiting for another owner's queued popup, and cancellation/late-callback safety.
The actual persistence implementation and coordinator run without UI replacements.
These tests do not execute UIKit navigation or audio.

Twenty new Apple launch scenarios at Accessibility XXXL vary action, protection,
confirmation, motion override and RTL. They check actual paper action geometry,
background exclusion, keyboard dismissal, retained/discarded text, actual storage
readback and exit callback counts. The fixture counts the real callback rather
than navigating into production data. A common paper-action helper preserves
case-specific screenshot names for Game and Account.

All Apple SDK/SwiftUI/Combine typechecking/rendering, actual keyboard/focus,
VoiceOver, screenshots, motion/audio and native navigation remain NOT_RUN. The
Foundation tests establish callback/intent contracts only. Official MADLAD
resources, language/clinical review and physical-device performance remain open.

Final feasible verification: 709 portable XCTest +21 Swift Testing; 722 native CPU XCTest +21 Swift Testing; 42 workflow checks; 304 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Actual Apple rendering/navigation/VO and official model gates remain NOT_RUN.
