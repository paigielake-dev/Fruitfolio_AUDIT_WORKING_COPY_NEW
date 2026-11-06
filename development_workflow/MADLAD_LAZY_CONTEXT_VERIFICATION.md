# Allocate the native T5 context after input validation

A real-native before regression on parent 4a6f1c4 failed two assertions: an
over-budget input sampled two allocation calls and retained an unnecessary
context. The diagnostic-only modelLoaded flag was added before that run; allocation
behavior was unchanged. Original failure/hash: RUN_LOGS/T5-budget-context-before.json.

The production actor now loads/verifies the model and vocabulary, checks exact
language-tag round trip and actual input token budget, then lazily allocates its
context and greedy sampler. The original CPU/context/thread configuration, model
checksum/architecture/tokenizer gates, encoder/decoder and output guards remain.
There is no approximation or truncation of the input budget. Context construction
still checks cancellation/capacity and frees local/native state on failure.

The DEBUG state distinguishes model-only from model-plus-context. Actual native
regressions now verify one sampled model allocation and no context after an
oversized input; a later valid request reuses that model and creates its context,
then executes real encode/decode. They also release the model-only state, mutate
its original file and verify checksum rejection before reloading. A manifest that
falsely declares a missing actual vocabulary tag is rejected before context or
encoder/decoder, and a later real tag remains usable.

Model weights can remain cached after a rejected input; only compute-context/
sampler allocation is avoided. Explicit release handles both complete and partial
states. This is not a claim of zero model memory, a leak-detector result, process-
wide budget enforcement, or a measured 3B/iPhone memory saving. Source resource
ownership/cancellation and real Linux native control flow are distinct from Apple
SDK/UI/Metal/device/thermal/performance acceptance, which remains NOT_RUN. The
fixtures are synthetic untrained T5 tensors, not official MADLAD or translation/
clinical review. Official resource acquisition remains externally blocked.

Final feasible verification: 712 portable XCTest +21 Swift Testing; 729 native CPU XCTest +21 Swift Testing; 42 workflow checks; 306 compiler-parsed Swift files; actual production C-header API typecheck passed. Official model/device/quality gates remain NOT_RUN.
