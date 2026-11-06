# Account username/email draft exit

The actual Account header Back action now detects a changed username or a nonempty
unsubmitted email draft. It uses the existing owned session and shared measured
white-paper host. Clean Back retains the existing navigation callback. Keep and
Escape retain the drafts; Discard clears only those in-memory edits before leaving.

A writable changed username offers Save Username + Leave. Mixed-draft copy
explicitly states that this saves only the local username and that leaving
discards the unsubmitted email. Email-only drafts offer Keep/Discard, with no
save/authentication option. Protected username records also omit an unavailable
save action. No entered value or account identity appears in popup metadata.

The username intent freezes its baseline, confirmation and local identifying-text
exclusions. Actual persistence still checks acknowledgment and current namespace.
A rejected save preserves both drafts and focuses the inline username error;
no navigation callback runs. A successful save updates only the username record,
clears the explicitly disclosed unsubmitted email draft, then leaves. There is
no email submission, account update, remote authentication or fake sign-in.

Actions are consumed only by the currently owned request and performed by the
existing post-dismissal observer. Departure cancels ownership/pending actions.
Return focus uses the actual username/email field. Original account deletion,
sign-out and unavailable-sync actions keep their independent frozen snapshots.

Three actual Foundation methods verify email-only action routing, writable versus
protected mixed-draft choices/disclosure, and actual frozen identity exclusions
rejecting a pseudonym derived from the email before any preference write. They use
the production request factory, intent and shared persistence, not UI replacements.

Thirty-two new Apple launch scenarios cover username/email/mixed drafts with all
applicable choices, motion override and RTL at Accessibility XXXL. They type actual
fixture fields, use real sign-out to expose email, check keyboard/form accessibility
exclusion, callback counts, persisted username, retained/discarded drafts and
unchanged health-file readback, and attach case-specific screenshots. All Apple
SDK/SwiftUI/Combine, keyboard, focus/VoiceOver, actual navigation, geometry, motion,
audio and screenshots remain NOT_RUN. The fixture counts the real callback while
keeping navigation inside disposable data. Official MADLAD/model/language/clinical
and physical-device gates remain open.

Final feasible verification: 712 portable XCTest +21 Swift Testing; 725 native CPU XCTest +21 Swift Testing; 42 workflow checks; 306 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Apple and official-model gates remain NOT_RUN.
