# Offline MADLAD catalog draft workflow

The legacy `translate_catalog_with_llama.py` entry point now forwards to the MADLAD workflow. Its old Qwen `--model`, `--llama-cli` and auto-approval `--overwrite` behavior is removed. No existing translations are overwritten or reclassified.

`Tools/MADLADCatalogRunner.swift` compiles the exact application MADLAD runtime, scientific protection, language mapping and translation service against actual native llama archives. One process retains its local model across sequential catalog jobs. It uses no remote inference, network client, Ollama, Ask model or test implementation. Each guarded result is written only to a separate unreviewed draft with source/catalog/manifest/runner hashes. Protected printf specifiers are passed intact into the application's protection envelope. Unsupported target tags, invalid resources, changed scientific information and truncated output remain errors. Raw Swift interpolation/plural variation entries require genuine Xcode extraction and are not translated as literal code.

Build on a host with the Swift compiler and a CPU native CMake build of the vendored llama source (disable optional BLAS/Accelerate/OpenMP backends unless their additional link flags are supplied):

```bash
python3 Tools/translate_catalog_with_madlad.py --build-only \
  --swift /path/to/swiftc --native-llama-build /path/to/llama-build \
  --runner /path/to/MADLADCatalogRunner
```

With the official converted/checksummed model and generated manifest in a local resource directory:

```bash
python3 Tools/translate_catalog_with_madlad.py \
  --runner /path/to/MADLADCatalogRunner \
  --catalog Fruitfolio/Localizable.xcstrings --resources /path/to/resources \
  --draft-output /path/to/catalog-es-drafts.json --locales es --limit 10
```

The output resumes completed entries only when the exact catalog, manifest and runner hashes match. Changed inputs require a separate draft path. It checkpoints every accepted result and records interrupted/failed processing. Source catalogs stay immutable. A successful exit is not linguistic/clinical acceptance; `runtimeVerified` deliberately remains false because this command does not attest installed-resource provenance, device performance or translation quality. Human/clinical review and a separate explicit reviewed merge remain required. No automatic import/approval tool is provided.

Verification here: the real C/Swift runner compiled/linked successfully against the native CPU archives; its actual missing-resource path returned the original-preserving error with no translated value. The actual repository catalog preflight recorded missing `MADLAD400.manifest.json` without starting inference or altering the catalog. Twenty-four workflow tests pass, including six new orchestration tests using an explicitly named fixture executable; those tests do not execute a translation model. The compiler parsed 237 changed Swift files without syntax errors.

Real T5 inference remains **NOT_RUN**: official weights/tokenizer acquisition is denied by the immutable cloud network policy for huggingface.co. In addition, the application manifest verifier currently requires CryptoKit; this Linux toolchain compiles its explicit rejection branch, while actual verified-model execution requires an Apple host with CryptoKit. No Linux CPU compatibility, actual model output, clinical language equivalence or iPhone memory/thermal claim is made. The previous real Qwen research inference is unrelated to MADLAD acceptance. See MADLAD_VERIFICATION.md and BLOCKERS.md for the exact open gates.
