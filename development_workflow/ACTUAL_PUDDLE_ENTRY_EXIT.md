# Actual puddle entry and exit

The actual game controller regression `testActualPaintedPuddleEntryAndExitRestoreNormalBasketMovement` uses the checked-in painted mask manifest in portrait and landscape. A legal level-six rainy round crosses from dry ground through the painted puddle. It checks bounded monotonic movement, contact and resistance before the target, restoration on exit, immediate subsequent dry movement, and unchanged saved progress/credits.

The gameplay header now shows the existing fixed-copy explanation while the basket touches the puddle. Its height stays reserved throughout puddle rounds to prevent contact-driven playfield resizing. It uses the existing translation path and hides the inactive explanation from accessibility. The existing basket accessibility ground-state description remains available.

Linux controller tests do not verify actual SwiftUI layout, gesture feel, VoiceOver, translated rendering or believable painted resistance. These require an Apple build and device/UI execution. No whole requirement is marked complete from these changes. Batch results and remaining verification are recorded per checklist entry.
