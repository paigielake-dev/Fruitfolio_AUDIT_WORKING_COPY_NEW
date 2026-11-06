# Acknowledged shared username records

Two actual private-UserDefaults fault regressions failed against parent 7140173:
refusing writes still returned saved, and refusing the old confirmation write
reported success with a new name whose consent was false. The original failure
excerpts/hash are retained in RUN_LOGS/Username-refused-and-partial-before.json.
The fixture refuses selected writes; reads and all other writes remain genuine
UserDefaults operations. These are persistence tests, not replacement storage.

The existing persistence/store API now commits name and non-identifying consent
as one schema-2 JSON Data preference at the original key plus .snapshot.v2. It
checks the actual readback before returning success. Existing v1 name, consent,
initialization and game records remain intact; migration happens only on an
explicit valid save. Clear writes an acknowledged empty tombstone so those legacy
originals cannot become the active name again through this reader. It does not
claim to erase historical copies or the game domain.

Known records require bounded size, schema/consent/name validation and a typed
field-preserving round trip. Future fields (including explicit null), unsupported
versions/types and malformed data preserve the original and block mutations.
Account shows the protection message/reload control and disables persistence while
protected. Stale canonical bytes or legacy fields reject a write before mutation.
A frozen Account intent additionally rejects changes through the same shared
store before the UI has observed them. Error reload refreshes the actual authority;
the dirty form keeps its draft and requires renewed confirmation. Reappearance
refreshes a clean form but preserves a dirty one. Apple lifecycle behavior is
NOT_RUN.

The DEBUG inspector reads actual storage without changing the write baseline.
Identical acknowledged semantic content returns a read-only receipt, retaining
original JSON bytes. The explicit export whitelist includes the new raw record
and both old consent/initialization preferences, preserving migration originals
without sweeping unrelated preferences. It now covers 21 known preference keys.

Six new protection tests cover legacy migration/clear/refused clear, future and
malformed formats, separate/stale writers plus inspector non-rebasing, frozen
same-authority intents, unsupported legacy types and read-only retry receipts.
The two original fault tests now pass, and an actual export capture regression
verifies that the new record bytes and original legacy preference values are retained.

UserDefaults readback is an in-process acknowledgment, not fsync, a transactional
cross-process compare-and-swap, or proof of crash/power-loss durability. The single
object prevents a name/consent split inside the application representation. These
checks do not configure global username registration/moderation/auth services.
Apple SDK/Combine/SwiftUI, real Account/Fruit Basket interaction, VoiceOver and
screenshots remain NOT_RUN. Official MADLAD/language/clinical/device gates remain
open independently.

Final feasible verification: 703 portable XCTest +21 Swift Testing; 716 native CPU XCTest +21 Swift Testing; 42 workflow checks; 302 compiler-parsed Swift files; zero actual SwiftSyntax sound ownership findings. Original 7140173 recovery bundle is retained unchanged. Apple/runtime/official-model gates remain open.
