# MADLAD verification

Full on-device inference remains required. A local T5 encoder/decoder implementation, checksum/architecture/tokenizer gates, scientific-token protection, and display-only translation paths now exist in source.

## Executed

- Python packaging tests validate that only actual vocabulary tags are declared supported and reject decoder-only/unpinned fixtures. These are fixture tests, not model inference.
- Swift syntax parser ran on changed sources. In addition, the real MADLAD Swift implementation typechecks against the actual checked-in llama C headers on Linux. This does not establish Apple binary ABI/link compatibility or real inference.
- Official metadata request to huggingface.co: configured proxy HTTP 403 CONNECT denial.
- Proposed network domain save: failed with draft_not_editable. No network change is confirmed.

## Not executed / unresolved

- No verified MADLAD GGUF/tokenizer is present. No language, including the requested Pacific languages, is claimed inference-verified.
- Swift build/link and real model inference have NOT_RUN. Existing Apple framework device/simulator ABI must be checked in Xcode.
- No offline device, loading/memory/latency/thermal/battery measurements or clinical translation-quality review have run.
- Chinese Traditional does not silently reuse the generic zh tag. All runtime targets require manifest membership and exact tokenizer tag round trip.
- Static String Catalog target values remain unfilled where the repository supplied no translation; English copies are not presented as translations.

## Reproduce resources

1. Enable huggingface.co in environment Internet settings and inspect any actual artifact redirect host separately. Keep proxy/TLS verification enabled. Do not bypass denials.
2. Obtain the official google/madlad400-3b-mt snapshot at its actual immutable 40-character commit, including original config, weights and SentencePiece model. Preserve provenance and checksums. No revision is invented here.
3. Install the vendored conversion prerequisites from llama.cpp/requirements/requirements-convert_hf_to_gguf.txt in an isolated Python environment. Build llama-quantize from the vendored source outside the checkout. Inspect available RAM/disk before converting the 3B checkpoint.
4. Run `bash Tools/convert_madlad_local.sh <verified-snapshot> <actual-revision> <quantizer> <new-output-directory>`. This pipeline is supplied but has NOT_RUN because resources are blocked.
5. The manifest tool extracts target tags from the converted GGUF vocabulary, validates T5 metadata and hashes the actual model. It does not assert model quality or independently attest a caller-supplied snapshot's origin.
6. Add MADLAD400.gguf and MADLAD400.manifest.json to app bundle resources. Do not commit large artifacts as plain Git blobs. Verify resource membership, build/link and execute translation on supported hardware in airplane mode.
7. Test scientific token/citation invariants, language coverage, unsupported tags, long inputs, cancellation, foreground/background changes and quality with qualified language reviewers. Keep the F16 model until quantized quality/inference is accepted.
