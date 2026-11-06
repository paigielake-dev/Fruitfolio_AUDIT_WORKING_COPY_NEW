# Native input token-buffer bound

The production runtime still asks the actual tokenizer for its exact required token count. It now checks that count against the installed context limit before allocating a Swift token array. The independent post-tokenization context check remains. UTF-8 byte length uses checked Int32 conversion; the negative native required count is widened before negation, avoiding signed overflow. No passage is truncated or silently partially translated.

An actual native regression supplies large repeated ASCII and multibyte Unicode inputs to the synthetic untrained T5 fixture, expects inputTooLong, and checks no encoder/decoder/context allocation and only the one-token target-tag Swift buffer. A subsequent valid request must reuse the model and produce its complete fixed test token. The DEBUG allocation statistic measures only the largest Swift token array, not the source string, native tokenizer internals, total resident memory or leaks.

This fixture does not establish official MADLAD compatibility, real language translation, clinical equivalence, performance or device memory behavior. Official weights/tokenizer and Apple/device verification remain blocked. Final feasible results are in the batch run log.
