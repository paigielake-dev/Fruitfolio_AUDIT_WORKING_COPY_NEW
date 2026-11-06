# Native T5 tokenizer variants and early unsupported-language rejection

The actual native CPU T5 runtime now runs its deterministic untrained token-output
contract with dummy-space-prefix metadata on/off and both CONTROL/USER_DEFINED
language-tag token types. All four variants accept Unicode/whitespace encoder
input, pass the actual single-tag round trip, execute encoder/decoder and return
the fixed test token. These are actual embedded UGM/GGUF/native paths, not a
Python/tokenizer imitation. They do not verify the official SentencePiece model,
its precompiled character map, learned translation or any requested language.

A targeted real-native regression against parent 759f8f4 reproduced unnecessary
allocation: a manifest-unsupported language still sampled two native load/context
calls and retained resources. One test failed two assertions. The original log
hash/excerpts are in RUN_LOGS/T5-unsupported-language-before.json.

The production loader now rejects negative manifest membership before checksum,
model or context loading. It returns the existing original-preserving unsupported
error and allocates no native resources for that rejected request. This negative
check does not attest any model or language. Declared-supported requests still
require the actual digest, T5/tokenizer metadata, native encoder/decoder graph,
context, exact tag round trip and inference gates. Cached models retain the
existing membership check. Missing/invalid manifest recovery is unchanged.

Input over-budget detection still needs the actual native tokenizer and currently
loads both model and context. Its encoder/decoder calls remain zero. Further
reducing that allocation is independent work, not claimed fixed here.

Nine native contract methods pass in the focused suite, including the four new
metadata/input variants and separated unsupported/budget tests. Physical-thread
checks remain Linux-specific; official weights/tokenizer are blocked by the
existing enforced network policy. Apple SDK/ABI/UI/device/memory/thermal and
linguistic/clinical quality remain NOT_RUN. No model binary or fake provenance is
installed into app resources; test fixtures retain explicit synthetic naming and
format-only manifest fields.

Final feasible verification: 712 portable XCTest +21 Swift Testing; 727 native CPU XCTest +21 Swift Testing; 42 workflow checks; 306 compiler-parsed Swift files; actual C-header API typecheck passed. Official model/Apple/device gates remain NOT_RUN.
