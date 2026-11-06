# Classification decision ownership

Each displayed fruit/star decision captures the existing controller interaction identity. Fruit buttons additionally capture the exact falling-fruit UUID. The actual MainActor controller validates these values before clearing a fruit, recording a pass, starting a transit or changing score. Consuming or spawning a decision and pausing rotate the identity. Thus a delayed tap cannot act on a replacement item or regain validity after pause/resume. The actual SwiftUI callbacks also check the root active-scene/popup ownership gate.

Programmatic controller calls retain optional identity arguments for compatibility; actual UI supplies captured identities. The same round engine, rare-star planner, research, citations, artwork and persistence schema remain in use. Deterministic tests expose later decisions directly instead of depending on rare-drop randomness.

Pre-fix actual controller execution: 49 tests, two failed assertions (fruit and star pass failed to invalidate the prior identity). Final verification is recorded in the matching batch run log and per-entry checklist evidence. Apple SDK typechecking, actual SwiftUI queued gestures, VoiceOver/focus, device gameplay and genuine Combine publication remain unexecuted on Linux. No official MADLAD inference or whole requirement certification follows from these controller tests.
