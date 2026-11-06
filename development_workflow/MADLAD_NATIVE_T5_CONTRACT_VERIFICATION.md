# Actual native T5 execution with untrained test tensors

The production `FruitfolioMADLADRuntime` has now executed actual native CPU T5
encoder and decoder calls using small deterministic, **synthetic untrained** GGUF
fixtures. This is execution-contract evidence only: **no official MADLAD weights,
linguistic translation, clinical accuracy or physical-device behavior is verified**.
Official model/tokenizer acquisition remains blocked by the documented enforced
network policy for huggingface.co. No language is promoted to verified status.

The test target creates the tensors and embedded UGM vocabulary in a UUID private
temporary directory, using GGUF v3, F32 weights and one encoder/decoder layer. Both
nongated ReLU and gated GELU graphs run against the existing vendored native llama
CPU archives. No vendor code changes, C mocks, fake native declarations or model
binaries enter app resources. Manifest repository/revision fields are deliberately
format-contract inputs (zero revision), not provenance. The file and model name
explicitly identify SYNTHETIC UNTRAINED / NOT MADLAD. The runtime's production
manifest, actual streaming digest, T5 metadata, actual loader, context, exact
language-token round trip and inference code run without validation bypasses.

Six initial native-only XCTest methods verify:

- Both graph variants successfully encode/decode, then reject immediate EOS with
  empty output. Explicit release is repeatable, and a later request reloads and
  executes again.
- A hard-wired normal token followed by EOS exercises the nonempty return path. The actual translation service rejects its output when it drops protected laboratory values and citation markers. This is synthetic output plumbing, not a translation.
- Unsupported tags and over-budget input execute no encoder/decoder call.
- A deterministic repeating-token graph reaches all eight decoder steps, rejects
  the partial result, and repeats correctly on the retained context. Cancellation
  on an already loaded actor executes no additional native calls.
- A cancelled request before loading allocates no model/context and executes no
  graph.
- Changed file bytes after release fail the actual checksum check on reload,
  before any further native graph call.

DEBUG counters increment only after successful real `llama_encode`/`llama_decode`
returns. They contain no user text. Resource state reports model/context presence;
it is not heap profiling, a leak detector, memory-pressure acceptance or device
performance evidence. Native calls cannot be interrupted while executing.

`Tools/run_portable_swift_tests.py --native-llama-build /tmp/fruitfolio-llama-build`
runs the actual production branch. Optional `--test-filter` is for focused
failure diagnosis; complete verification omits the filter. Without native llama,
these methods are intentionally not compiled and the regular Foundation suite
still runs. Apple framework linking, Metal, iPhone offline execution, actual 3B
MADLAD compatibility, language quality and scientific meaning remain NOT_RUN.

Final complete verification: 680 portable XCTest +21 Swift Testing; 691 native CPU XCTest +21 Swift Testing; 42 workflow checks; 298 Swift files parsed. Actual C-header API typecheck passed. Apple SDK typechecking/linking/UI/device behavior remains NOT_RUN.

Nonempty-output follow-up: all 692 native XCTest +21 Swift Testing cases pass, with 42 workflow checks and 298 parsed Swift files. The unchanged portable Foundation branches retain the preceding complete 680 +21 result. No official model/language/device gate is closed.

Control-label follow-up adds a seventh native method executing the actual display state through this same production service/runtime. Synthetic output losing protected lab values/citations remains original/unavailable. It does not approve a language or clinical translation.
