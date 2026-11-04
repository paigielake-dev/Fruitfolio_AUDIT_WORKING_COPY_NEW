# Cycle deletion failure-state safety

Inspection found both existing deletion methods cleared in-memory health/setup records before asking persistence to erase them. A disk refusal could therefore leave the UI showing empty records while the original saved records remained on disk and reappeared after restart.

Onboarding now resets the visible draft only after persistence accepts deletion. Cycle records now switch to the empty archive only after erase succeeds. If writing the subsequent empty envelope fails, the store remains empty and does not revive old health records after a successful deletion. Existing local profile/device identity preservation and derived-record clearing behavior are unchanged.

Three fault-injection tests cover failed cycle erase, failed setup erase, and successful erase followed by failed empty-envelope save. They assert exact original record retention on refusal and absence of revived health records after successful erase. Actual Xcode execution is pending. This does not claim complete cross-domain deletion coordination, concurrency acceptance, backup removal or privacy release readiness.

The personal-export fixture uses explicit integral timestamps for its stored encyclopedia and saved page. Its full exported-object equality assertion remains; no production date codec, medical validator or citation acceptance is weakened.
