# Fruitfolio llama / Xcode 27 integration boundary

## What this candidate fixes in source
- `FruitfolioResearchIntelligence.swift` now conditionally imports `llama` with `#if canImport(llama)`.
- If the llama module is absent, Fruitfolio uses the existing deterministic research-grounded fallback instead of failing compilation merely because the external module is missing.
- The native batch helper no longer force-unwraps `batch.seq_id`; failure is propagated as a decode failure.
- The expected model resource remains `FruitfolioAI.gguf` in the application bundle.

## What is intentionally NOT fabricated
The uploaded project archive does not contain an importable llama binary/XCFramework and does not contain `FruitfolioAI.gguf`. A working release build therefore still requires the exact runtime and model to be restored.

For Xcode 27, prefer ONE intentional llama integration. Do not add recovered CMake-generated `CompilerIdC.xcodeproj`, `CompilerIdCXX.xcodeproj`, `ggml.xcodeproj`, or repeated `llama.cpp.xcodeproj` references to Fruitfolio.

The official llama.cpp project documents using its built iOS XCFramework in another Xcode project. Use a single `llama.xcframework` dependency that exposes module `llama`, then ensure `FruitfolioAI.gguf` is in the Fruitfolio target's Copy Bundle Resources exactly once.

Do not keep both a source/CMake llama integration and an XCFramework integration in the same app target.
