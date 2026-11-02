# Account metadata integrity and immediate privacy-preference persistence

Corrected another unreadable-store path: quiet ownership/account state writes can no longer replace unreadable account metadata with a new empty local identity. Account/export actions reject the unreadable domain and preserve its original bytes across restart. Production export preparation explicitly checks this domain before presenting Files. Account/Privacy show a clear preserved-data error.

The private-notification wording preference now persists immediately on the actual toggle, rather than relying on a later unrelated snapshot write. Corrupt storage cannot silently persist or lower that preference. Added immediate restart and unreadable-storage/action/export/isolation tests. StoreKit receipts, backend credentials and actual delivery of notifications remain separate verification limitations; no authenticated service was fabricated.
