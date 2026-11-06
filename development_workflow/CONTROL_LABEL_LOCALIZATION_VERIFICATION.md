# Canonical control label translation

The existing canonical watercolor button previously rendered only a catalog-key
Text. It now resolves its app-generated source label through the actual
catalog-first scientific translation service, including MADLAD fallback when
resources and an exact target tag are available. Existing compatibility wrappers,
artwork, action closures, small/large sizing, responsive wrapping, Reduce Motion
style and single soft-pop owner remain. Source labels and saved records are not
rewritten. The existing shared semantic renderer consumes any inline markup rather than showing raw markers; its plain text supplies the VoiceOver label. The root remains one actual Button, preserving caller identifiers and
focus bindings. There are no nested buttons or disclosure controls in its label.

The new actual main-actor state owns source/language and request generations.
Late/cancelled results cannot replace the current label. Until resolution and on
failure it displays the original label; a short source/unavailable caption makes
fallback explicit. Machine results have a machine-translation caption and the
original in the accessibility hint. Catalog entries use the existing exact-lproj
lookup and scientific guards. Existing accepted display text survives model
release/memory pause; unresolved text cannot start inference while paused. All
inference remains on the existing serialized runtime actor. Fruitfolio and LifeBridge names are explicitly protected; output dropping them is rejected. No new network client,
model substitution, persistent translation cache or user-data write is added.

Eight actual Foundation-state tests use explicitly named controlled runtime
fixtures to verify English/blank bypass, actual private Foundation bundle lookup
while paused (including a legitimate unchanged DNA label), unresolved new
source/language fallback, unavailable/paused original retention, accepted display
retention after release, held old result rejection and cancellation/retry. These
fixtures test state ownership and are not linguistic inference evidence.

An additional native test runs this same state and production service against the
explicit synthetic untrained T5 graph. A deterministic token/EOS result can reach
machine-display state; output dropping laboratory values/citation markers becomes
original/unavailable instead. Actual encoder/decoder success counts are checked.
This does not verify an official MADLAD model or scientific meaning in another
language. See MADLAD_NATIVE_T5_CONTRACT_VERIFICATION.md.

Apple SwiftUI/Combine observation, control geometry/focus/identifiers, VoiceOver
hints, sound playback and screenshots remain NOT_RUN. Existing Account/data/shared
popup Apple UI scenarios exercise these actual canonical controls when run on
Mac. Official weights/tokenizer access, clinical/linguistic review, all requested
language coverage and physical-device performance remain open. Foreign catalog
entries are not fabricated or marked complete. Captions themselves still require
reviewed localization; English originals are explicitly identified as such.

Final feasible verification: 688 portable XCTest +21 Swift Testing; 701 native CPU XCTest +21 Swift Testing; 42 workflow checks; 300 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Bounded actual test excerpts and complete-log hashes are preserved in RUN_LOGS/Control-label-actual-test-excerpts.json. SwiftUI/Combine/UI/device acceptance remains NOT_RUN.
