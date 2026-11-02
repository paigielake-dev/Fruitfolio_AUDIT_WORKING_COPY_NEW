# Storefront ownership verification

The previous ownership check waited briefly and then unconditionally reported a purchased state. It now calls StoreKit's actual signed AppTransaction API. Only StoreKit-verified information for Fruitfolio's own bundle identifier can set the separate `ownershipVerifiedByStorefront` result. Unverified, unavailable and wrong-bundle information cannot do so. A persisted interrupted check reopens as unavailable instead of a permanent spinner. The verification flag is in memory only; a cached preference cannot masquerade as a fresh signed StoreKit verification, and no signed payload or transaction identifier is persisted by this change.

The installed paid-app access policy remains separate: an offline or unavailable storefront check does not introduce a second paywall, subscription, in-app unlock, or account requirement. Sign-in/data restoration is also separate from storefront ownership. No refresh prompt, purchase or subscription API is invoked.

Added state-transition tests use explicit fixtures and do not constitute an App Store purchase test. A separate test attempts the actual SDK call and retains its real result; an unavailable result must remain NOT VERIFIED for paid-receipt acceptance. These new tests have not yet executed. Production signed storefront, account and distribution verification remain dependent on their real external environment.

Primary API documentation:
https://developer.apple.com/documentation/storekit/apptransaction/shared
https://developer.apple.com/documentation/storekit/apptransaction
