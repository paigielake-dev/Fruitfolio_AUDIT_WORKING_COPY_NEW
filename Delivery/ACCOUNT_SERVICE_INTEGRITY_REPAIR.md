# Account service integrity repair — verification pending

The inherited sign-in implementation accepted any nonblank email, constructed a provider=demo identity locally and declared remote sync complete. syncNow used a 450 ms local delay as its success condition. Account deletion removed the local identity while naming the operation remote deletion. No authenticated account provider, server endpoint, account-service credentials or remote deletion acknowledgement exists in the supplied project.

Production sign-in now reports service unavailable without creating or persisting an entered email as an account. Sync never drops pending changes or declares a local delay remotely synced. Remote account deletion fails closed and preserves the identity. Older demo identities remain preserved for export and local sign-out but no longer restore as authenticated sessions. The account design, username system, installed paid-app access and local health data remain intact.

Tests replace acceptance of fake authentication with rejection/restart/no-account assertions and preservation of pending changes. This repairs false success; it does not implement remote accounts. Full account functionality is blocked by the absent approved authentication/synchronization service and its deployment configuration. No provider or remote health-data policy was invented. Unrelated work continues.
