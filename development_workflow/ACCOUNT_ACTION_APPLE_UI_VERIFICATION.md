# Disposable account confirmation scenarios

Apple UI status: **NOT_RUN**. Linux Foundation compilation/execution does not
verify SwiftUI/Combine/UIKit typechecking, VoiceOver focus, visible bounds, sound,
Dynamic Type, reduced-motion rendering or screenshots.

The DEBUG route -fruitfolioAccountActionQA uses the existing shell's registered
private preferences/context suite. -fruitfolioAccountActionQAScenario selects
sign-out, unavailable-delete, unavailable-sync, stale-sign-out or rejected-write.
Flags -fruitfolioAccountActionReduceMotion and -fruitfolioAccountActionRTL select
the override and forced root RTL layout. Fixture labels explicitly use English;
this is layout coverage, not reviewed Arabic/MADLAD translation acceptance.

The actual AccountView receives an explicit private username authority, private
account UserDefaults and a UUID temporary cycle file. Back/privacy/export routes
are disabled by fixture callbacks, so unrelated flows cannot open production data.
The unrelated ownership verifier explicitly returns unavailable and never inspects
a real StoreKit receipt or supplies a fake verified result. Local development
identities are labeled fixtures, not production authentication. The app's normal
initializers still use the existing shared username authority and export flow.

The fixture refuses only selected account writes, or changes the local fixture
identity while confirmation is open. Normal persistence is the actual private
UserDefaults suite and actual cycle file actor. Diagnostic readback compares real
record bytes and the actual cycle file after dismissal. Cleanup removes its own
suite/directory; no production credentials or health content are used.

Three new methods in the existing selected Prompt1BModalAccessibilityTests class
define 20 launch cases at Accessibility XXXL, across motion override on/off and
LTR/forcedRTL. They check cancel/reopen, pending-preserving sign-out, unavailable
sync/deletion errors, frozen stale identity, refused-write errors, minimum 44pt
modal actions, scroll bounds, hidden underlying controls and saved-data readback.
Screenshot names include scenario, override and direction. No screenshots have
been produced on Linux. The Mac verification script already selects this class.

The root DEBUG RTL override reaches the actual outer popup host; feature-local
overrides alone did not. Both account and cycle scenes now use this guarded root
override without changing production language authority. The actual observable
username store uses conditional genuine Combine and is compiled in the portable
suite. Two new Foundation methods verify independent injected username namespaces
and execute the actual QA fixture's preparation/sign-out/private-file invariants.
Combine observation and the UI callbacks still require Apple verification.

## SwiftPM compiler recovery

Swift 6.2.1's batched frontend diagnosed an inferred nonisolated initializer on an
unchanged actor after the new DEBUG source entered the primary-file batches. The
complete actual sources independently typechecked, emitted a module and emitted
a linked library, both with and without the fixture. Unbatched SwiftPM compilation
then passed the complete source/test sets. The runner now passes
-Xswiftc -disable-batch-mode. No source or tests are skipped, no API stubs are used,
and the persistence actor is unchanged. The private fixture's dependencies are
created during initialization, consistent with the existing cycle fixture. The
mode flag affects compiler batching, not the language mode or model execution.
