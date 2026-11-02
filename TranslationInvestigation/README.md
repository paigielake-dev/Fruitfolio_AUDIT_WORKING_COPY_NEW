# Translation runtime investigation — historical probe and current Apple status

Current status: the application now links the official-format Candle encoder–decoder adapter through `Vendor/FruitfolioMADLAD.xcframework`. Actual simulator inference, strict protected-document fixtures and controlled-offline core verification have executed; see `Delivery/RUN97_OFFLINE_EXPANDED_LANGUAGE_FINDINGS.md` and the original Apple evidence. This does not establish medical translation acceptance. Aymara fails the expanded medical fixture, some targets have language/script defects, and Japanese retains mixed English anchors. The production medical translation gate remains closed.

The standalone Linux CLI below remains an investigation tool, separate from the iOS ABI in `src/lib.rs`. The following whole-document output and earlier Linux memory figures are preserved historical failures, not descriptions of every current protected-sentence fixture.

Candle source snapshot: https://github.com/huggingface/candle
Commit: 2cf0e66dcb2953e2aa7f4000cdd697239e9c16c5 (0.11.1).
The source and probe are siblings under this directory so the probe's path
references remain valid after extraction. Upstream licenses are retained.

With Rust installed, reproduce the CPU experiment:

    CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1 cargo build --release -j 1 --manifest-path madlad-candle-probe/Cargo.toml
    RAYON_NUM_THREADS=4 HF_HUB_OFFLINE=1 madlad-candle-probe/target/release/fruitfolio-madlad-original-format-probe ../Models/MADLAD '<2es> This is educational information, not medical advice. The result is 2.5 ng/mL [source-1].'

Rust crates may be downloaded for the research-tool build. Its inference reads
only local official weights, configuration and tokenizer. The actual Xcode app
does not build or link this probe. Do not treat it as an iOS MADLAD runtime.

Actual observed original-format Candle output:
El resultado es 2.5 ng/mL [fuente-1] y el nivel de TSH es 1.5 ng/mL [fuente-2].

This matches the experimental llama result and fails the medical acceptance
fixture. The original safety sentence is absent, source identifiers are changed,
and an unsupported numerical claim is introduced. This is not explained solely
by the format adaptation. The source model/quantization and robust medically
safe translation still require investigation; no clinical reliability is claimed.

The Linux Candle process peaked at 4,806,620 KiB RSS (~4.58 GiB), 15.66 seconds
including model load. The llama experiment peaked at ~3.19 GiB in a separate
Linux CLI run. Neither measures an iPhone or proves an iOS memory budget.
At the time of that initial Linux experiment, iOS integration had not been completed. Later Apple cross-compilation and actual simulator execution are documented separately. Run97's official-runtime core fixture recorded34.9003seconds for its bounded sequence,2,155,249,664bytes process peak Darwin RSS and7,516,192,768reported host physical bytes; actual inference was off the main thread. These are simulator observations, not an iPhone memory allowance, latency guarantee or medical approval. Physical-device translation acceptance remains unverified. FruitfolioAI remains a separate grounding/generation system.
