# Performance evidence

No iOS/device benchmarks have run. No launch, memory, latency, thermal or battery claims are made.

## Existing Ask GGUF, Linux CPU smoke

One warm run: 0.518 s wall; max RSS 566264 KiB; model-reported load 261.63 ms; 9 generated tokens. Actual prompt/output and stderr are in RUN_LOGS/Ask-model-CPU-smoke.*. This does not measure iOS app launch, research retrieval, MADLAD, device thermals or battery.

## Actual compiled research index (Linux)

- Real founder package: 4,458 retained note chunks; 2,722 eligible indexed chunks.
- Latest sample: static index construction 1.259 seconds; 50 cached searches 1.284 seconds (about 25.7 ms/search in this run).
- No user-query cache, no network calls, and no device-speed claim. Original-tokenization baseline and integrated iOS frame responsiveness remain unmeasured.
