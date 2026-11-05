# Native runtime evidence

- FruitfolioAI.gguf restored via authenticated Git LFS, using existing platform Git access. LFS filters were installed locally without changing hooks. No token or secret was requested.
- Exact asset: 491400032 bytes, SHA-256 `74a4da8c9fdbcd15bd1f6d01d621410d31c6fc00986f5eb687824e7b93d7a9db`.
- GGUF metadata: architecture qwen2, name qwen2.5-0.5b-instruct, 291 tensors. This is the existing Ask model, not MADLAD.
- Vendored source built as a CPU-only `llama-simple` executable outside the checkout at /tmp/fruitfolio-llama-build. Parallelism: 2; native host-specific instruction selection disabled. The vendor's CLI target requires server tooling in this revision, so the small local-only example was used instead.
- Actual smoke prompt: a brief hello through Qwen chat delimiters. Result: `Hello! How can I assist you today?`; 9 tokens generated; process exit 0.
- Measured Linux run: 0.518 s wall, 566264 KiB maximum RSS, model-reported load 261.63 ms. These are one warm host run, not iPhone performance or an integrated research-grounding test.
- `Tools/typecheck_madlad_api.py` typechecks the real T5 implementation against checked-in llama C headers, with no stub symbols and no linking. Passed using Swift 6.2.1, Swift language mode 5 matching the app.
- The supplied Mach-O framework has platform-7 iOS Simulator slices for arm64 and x86_64. It is not a device runtime.
- Xcode project now references one repository-relative static XCFramework; duplicate automatic framework ingestion and a stale example-project reference are removed. Its OpenStep plist parses and target build-file references resolve.
- `Tools/build_llama_xcframework_mac.sh` creates both iOS-device and simulator static frameworks from vendored source, with embedded Metal support. It has been shell-syntax checked, not executed on Linux.
- Apple build/link, model load/generation in the app, MADLAD weights/inference, clinical answer quality, and physical-device memory/thermal/battery behavior remain unverified.

## Reproduce CPU smoke test

Install CMake in an isolated tools environment. Configure the vendored source out of tree with Release, GGML_NATIVE=OFF, GGML_OPENMP=OFF, GGML_CUDA=OFF, GGML_BLAS=OFF, LLAMA_BUILD_SERVER=OFF, LLAMA_BUILD_UI=OFF, LLAMA_BUILD_TESTS=OFF, LLAMA_BUILD_EXAMPLES=ON, LLAMA_BUILD_APP=OFF and BUILD_SHARED_LIBS=OFF. Build target llama-simple with parallelism 2. Run it with explicit `-m <checkout>/FruitfolioAI.gguf -ngl 0 -n 24 <Qwen chat prompt>`. No model download/server/remote-inference option is used.
