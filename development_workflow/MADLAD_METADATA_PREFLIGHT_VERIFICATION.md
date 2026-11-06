# MADLAD metadata preflight

The application runtime now checks the GGUF metadata after the streaming digest
and before `llama_model_load_from_file`. It requires `general.architecture=t5`
and `tokenizer.ggml.model=t5`; a manifest assertion alone cannot satisfy these
checks. Supported GGUF versions are 2 and 3. The reader bounds metadata to 4,096
keys, keys to 1,024 bytes, selected values to 64 bytes, and arrays to 1,000,000
entries. Unneeded values are skipped with file-bound and overflow checks;
vocabulary/tensor payloads are never materialized by this reader. Duplicate
keys, unsupported types, nested arrays, truncation and cancellation reject.

The native loader still validates the graph and encoder/decoder architecture.
The allocated context must cover the requested context length. Cancellation
observed after native model/context allocation frees those allocations before
throwing. Native calls themselves cannot be preempted while executing.

Evidence distinctions:

- Metadata-only synthetic fixtures exercise the real parser, including T5/T5
  headers, vocabulary arrays, wrong types/architecture/tokenizer, missing and
  duplicate keys, version, truncation, huge lengths and cancellation. A passing
  synthetic header is not an executable model and proves no translation.
- The actual SHA-verified Qwen assistant artifact is rejected by the actual
  MADLAD runtime as incompatible before the native model allocation path. It is
  never substituted for the translation model.
- The actual native CPU archives compile/link the production runtime. This
  does not establish official MADLAD graph compatibility or successful T5
  encode/decode, translation quality, clinical accuracy or iOS performance.
- Official weights/tokenizer access remains blocked by the enforced network
  policy. Apple SDK/device checks remain unavailable. These gates are NOT_RUN.

The reader verifies the two compatibility fields, not tensor correctness or
source provenance. The existing pinned manifest/digest and native loader are
separate gates; official source verification and clinical review remain needed.
