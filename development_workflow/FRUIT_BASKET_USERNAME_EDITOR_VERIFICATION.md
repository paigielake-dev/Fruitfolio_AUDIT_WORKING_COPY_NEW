# Fruit Basket shared username editor protection

The existing leaderboard form now supplies its reviewed username snapshot to the
same actual shared authority used by Account. A changed same-authority name or
separate writer cannot silently authorize the old edit. Save shows success only
when that authority acknowledges its single-record persistence. A failed save
keeps the typed draft and requires renewed non-identifying confirmation. Unknown
records display the shared protection/reload message and disable saving.

Reappearing inside the existing game screen refreshes a clean form; it preserves
a dirty form. A changed authority invalidates its old confirmation without erasing
its draft. Public-name display requires the non-identifying confirmation and wraps
without shrinking. The existing worldwide registration-unavailable behavior stays
in place; a local name is not presented as reserved or uploaded.

Only the constant input label enters shared catalog/MADLAD resolution. The actual
field's value remains original user input. Confirmation and Save use existing
canonical controls and sound ownership. Error messages use shared translated/
semantic rendering. The leaderboard scroll view supports interactive keyboard
dismissal. Original game artwork, rules, progress, category totals and resources
are unchanged.

The existing private-suite Game QA fixture adds a future-format username scenario,
with actual schema protection and no research/auth/network calls. Its preferences
are owned until fixture deinit, instead of being erased on a transient view
appearance/background transition. Root RTL forcing is restricted to the registered
Game QA route and its modifier; English labels test layout, not reviewed Arabic.
Eight Apple UI launch cases cover normal/future formats, motion override and RTL
at Accessibility XXXL. They exercise dirty Home/leaderboard reappearance,
background/activate, confirmed actual save/readback, future-format reload and
unchanged dirty text. Capturing the actual typed draft avoids assuming the caret
position within an existing text field.

All those Apple UI cases, screenshots, keyboard/focus, real Combine observation,
foreground/background behavior and deinit lifecycle remain NOT_RUN on Linux.
The actual shared authority's stale/future/refused-write regressions run in the
portable/native suites; they do not prove SwiftUI behavior. No production assets
or existing backup source files were replaced. Explicit confirmation before
leaving the entire game with an unsaved username draft remains independent work.

Final feasible verification: 703 portable XCTest +21 Swift Testing; 716 native CPU XCTest +21 Swift Testing; 42 workflow checks; 302 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Changed Apple UI/lifecycle behavior remains NOT_RUN.
