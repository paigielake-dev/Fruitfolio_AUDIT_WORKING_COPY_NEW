# Native T5 blocking-call thread sampling

The actual production runtime now samples the invoking physical thread immediately
before four potentially expensive native operations: model loading, context
allocation, encoder execution and decoder execution. DEBUG-only counters report
how many such calls were sampled and how many invoked from Thread.isMainThread.
There are no text/token/identity logs, runtime behavior changes or release-build
counter overhead. This is sampling at those call sites, not a UI profiler.

The existing real native synthetic T5 contract tests now assert positive sample
counts and zero physical-main-thread invocations for both nongated/gated graph
execution, release/reload, retained-context decoder-budget retries and a call
through the actual main-actor control display state. Early cancellation samples
zero native operations; changed-file reload is rejected before further allocation.
Unsupported/input-budget cases sample actual load/context but no encoder/decoder.

The seven focused native methods passed against the actual checked-in CPU llama
archives on Linux. Synthetic, untrained tensors establish graph/control-flow and
these host-specific execution facts only. Linux MainActor scheduling and a
physical-main-thread check do not establish iPhone UIKit responsiveness, Apple
executor behavior, Metal compatibility, official 3B MADLAD performance, memory,
thermal/battery effects, language quality or clinical semantics. Those gates remain
NOT_RUN. Other C APIs, resource destruction and allocator internals are not
individually sampled by this counter and are not claimed profiled.

Final feasible verification: 712 portable XCTest +21 Swift Testing; 725 native CPU XCTest +21 Swift Testing; 42 workflow checks; 306 compiler-parsed Swift files; actual production release-branch Swift/C-header API typecheck passed. Official model/device gates remain open.
