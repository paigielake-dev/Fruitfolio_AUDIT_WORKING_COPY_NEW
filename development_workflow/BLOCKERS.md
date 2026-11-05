# Confirmed blockers and prerequisites

- This Linux executor has no Swift compiler or Xcode. Swift tests, simulator geometry/VoiceOver, and device inference/performance have not run. Use Tools/verify_prompt1b_mac.sh on a Mac; physical-device measurements remain separate.
- FruitfolioAI.gguf is a Git LFS pointer for a 491400032-byte asset, not an executable model in this checkout. Retrieve and verify its declared SHA-256 before claiming local AI generation.
- No MADLAD checkpoint or matching tokenizer was found in the initial targeted file inventory. Runtime/model compatibility, language coverage, conversion, offline inference and performance remain unfinished; this does not remove them from scope.
- The supplied checklist is present and contains exactly 478 requirements after excluding six numbered Part 1 headings. Its original printed IDs restart within Part 1. Keep printed IDs plus source-order sequence.
- The binary founder specification and complete antiword UTF-8 extraction are preserved under SOURCE_MATERIALS. Extraction succeeded using grobian/antiword built in /tmp. Reconciliation of additional specification requirements is pending; do not claim the checklist is an exhaustive specification inventory.

- Production authentication/cloud sync: no approved backend/provider implementation is configured. Sign-in now reports unavailable; sync preserves pending local changes rather than simulating success. StoreKit ownership checking also reports unavailable until actual receipt verification is integrated. No credentials are requested or fabricated.
