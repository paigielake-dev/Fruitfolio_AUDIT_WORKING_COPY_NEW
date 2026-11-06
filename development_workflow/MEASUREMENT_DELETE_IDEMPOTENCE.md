# Repeated measurement deletion

Deleting an absent ID now checks writable/current storage first, then returns without writing or advancing the acknowledged revision. A repeated request cannot rewrite unchanged medical records or invalidate an unrelated open editor solely because its target is absent. Actual existing-record deletion still uses the canonical encode/write/readback path.

The new regression uses actual production persistence with a counting UserDefaults subclass. It checks absent storage, an existing unrelated exact snapshot and revision, and a foreign replacement. The foreign replacement must still block deletion and remain untouched. Pre-fix:11 XCTest cases, seven failed assertions in the new case; other ten passed. Hash receipt:RUN_LOGS/Measurement-missing-delete-prior-failure.json.

Apple UI/device, cold-process UserDefaults durability and clinical/official MADLAD acceptance are not established by these in-process storage tests. See this batch verification record for executed final suite results. Whole checklist requirements remain IN_PROGRESS.
