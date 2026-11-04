# Actual MADLAD device and distribution review

The official google/madlad400-3b-mt Q4 GGUF is a T5 encoder–decoder, not a decoder-only Llama model. The tested Candle-based Apple runtime executes the encoder and decoder locally; original FruitfolioAI research generation remains separate. Exact official weights and all tokenizer/configuration hashes are checked before inference. Actual tested arm64 iPhone and arm64 Simulator static libraries are present; this establishes compilation/runtime fixtures, not acceptance on physical supported iPhones.

Run64's actual bounded Apple-runtime attachment reports 127.408 seconds for its collected short fixtures, peak process RSS 1,645,395,968 bytes, host physical memory 7,516,192,768 bytes, and inference off the main thread. These are Simulator process/host measurements, not iPhone memory limits or per-sentence latency promises. Long answers, concurrent model residency, thermal behavior, cancellation under load and 4/6 GB physical phones remain NOT VERIFIED. Official model storage is 1,654,597,280 bytes; preserved FruitfolioAI is 491,400,032 bytes, plus tokenizers/art/audio/app resources. Neither model is omitted.

Run61 unsigned generic-device Release bundle measured 2,257,000 KiB via du (allocated disk usage, not an App Store thinned-download measurement). The project retains its approved iOS17 deployment target. Apple currently lists a 4 GB uncompressed upload limit, while its separate game/download and resource documentation distinguish a 2 GB thinned bundle limit before iOS18 versus 4 GB for iOS18+. These are different measurements; successful unsigned compilation does not prove App Store distribution compatibility for every iOS17 device variant. An actual signed archive/thinning size report and App Store validation are required before claiming distribution readiness. No deployment-target increase, on-demand model download or model substitution was silently adopted.

Primary Apple references checked November 2, 2026:

- https://developer.apple.com/help/app-store-connect/reference/app-uploads/maximum-build-file-sizes/
- https://developer.apple.com/help/app-store-connect/reference/app-uploads/on-demand-resources-size-limits/
- https://developer.apple.com/documentation/gamekit/improving-the-player-experience-for-games-with-large-downloads

Official approved model resources include Q4 GGUF and original model/configuration resources; no smaller approved prequantized variant has been demonstrated compatible with this application. Requantization would require renewed runtime, numerical, language-quality and medical-preservation tests. The existing Q4 resources remain unchanged. Exact missing target tags tpi, ty, rar, niu and gil are not replaced with guessed aliases.
