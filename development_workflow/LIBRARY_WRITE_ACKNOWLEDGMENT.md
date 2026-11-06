# Canonical library write acknowledgment

The canonical persistence owner now advances its committed snapshot and expected storage baseline only after an exact Data readback. A dropped write, foreign replacement or wrong type blocks mutations until explicit reload. The actual Store restores its last acknowledged in-memory snapshot; foreign backing bytes are never rolled back. Encoding failures remain distinct.

Actual pre-fix fault tests: six cases, 19 failed assertions (four new cases failed); receipt in RUN_LOGS/Library-write-acknowledgment-prior-failure.json. After fix: six cases passed. Full Linux: 761 portable XCTest, 783 native CPU XCTest, 21 Swift Testing per run, 50 workflow checks passed. 311 Swift files parsed; project references resolved and actual SwiftSyntax sound ownership found no violations.

32 Guide Apple UI cases are written, not executed, including four new dropped-description cases using the actual private Store. Apple typecheck, rendering, accessibility and physical audio/device acceptance remain unverified. Production catalog has 802 English keys and no nonempty foreign translations. Native synthetic T5 tests are not official MADLAD inference.

This is API readback acknowledgment, not fsync, a cross-process transaction or compare-and-swap. Multi-page Guide submissions still require a single staged commit; this batch does not close whole original requirements.
