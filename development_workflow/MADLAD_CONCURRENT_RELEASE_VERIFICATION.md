# Concurrent native translation/release ownership contract

A new actual native regression launches eight child tasks against the same
production actor. Each performs a deterministic synthetic T5 translation,
explicitly releases resources, then translates again. This exercises sixteen
actual encoder calls, thirty-two decoder calls and resource disposal/reloading
while other requests are pending. Every result must be complete and exact for the
untrained fixed-token graph. The assertions require repeated model/context setup
and zero sampled physical-main-thread calls on this Linux host.

After all requests finish, explicit release must clear both model/context state.
One further real request must load again, encode/decode and return its complete
test token, with the expected native call-count increment. The focused case passed
against the actual vendored CPU archives. No C API implementation, scheduler or
actor is replaced by a test double.

This is evidence for the exercised actor/resource ownership and output contract,
not a proof of every interleaving, a leak detector, benchmark or memory-pressure
simulation. Native calls remain non-preemptible while executing. Existing actual
cancellation, checksum, vocabulary-tag, partial-state and scientific-protection
regressions remain separate. The tensors are explicitly synthetic and untrained;
no official MADLAD weights, language translation, medical equivalence or 3B device
resource behavior is verified. Apple UIKit/Metal, physical-device memory/thermal/
battery/latency and linguistic/clinical gates remain NOT_RUN.

Final feasible verification: 712 portable XCTest +21 Swift Testing; 730 native CPU XCTest +21 Swift Testing; 42 workflow checks; 306 compiler-parsed Swift files. All twelve native T5 methods pass. Apple/official-model/quality gates remain NOT_RUN.
