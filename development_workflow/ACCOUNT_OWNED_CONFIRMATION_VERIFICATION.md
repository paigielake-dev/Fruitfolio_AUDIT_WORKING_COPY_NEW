# Account intents, persistence acknowledgment and owned confirmations

Active account sign-out/deletion now use the existing identity-owned taped-white
pipeline. Account identity/authentication state, pending-local flag and local
container ID are frozen when the request opens and checked again after dismissal.
A changed account/record rejects rather than applying an older action. Cancellation,
Escape and view departure use existing ownership guards. Failure text is visible
in both signed-in and signed-out layouts and uses translated semantic text with a
lifetime-checked focus request. There are no swallowed try?-success paths for these
actions. The complex existing data-export form/role is preserved separately.

Sign-out makes one final local record write, preserves the pending-local marker
(no upload occurred), retains the local container and does not touch health files.
It rolls back affected cache fields and throws if actual UserDefaults readback
does not acknowledge that write. Passing keepLocalData:false now requires separate
review in data management rather than silently implying local deletion. Privacy
toggles also revert when their actual record write is unacknowledged. Readback is a
process/suite acknowledgment, not a claim of fsync durability or cross-process CAS.

The unavailable cloud-sync attempt keeps identity/pending information and reports
serviceNotConfigured. Remote account deletion still reports remoteDeletionUnavailable
without writing a local success or deleting local information. No production
auth/cloud service is configured and this batch adds no network operation or fake
service acknowledgment. Development identities in tests are local fixtures only.

The existing account decoder now also uses actual JSON field-coverage validation,
protecting explicit-null optional metadata as well as future root/nested fields
from a lossy Codable rewrite. Unsupported saved records remain read-only.

Eight new real-store regression methods cover pending-marker/container/actual
cycle-file preservation, stale identity and new pending changes, unavailable sync/
delete, separate local-deletion review, a rejected record write/cache rollback,
explicit-null fields and failed privacy toggles. The rejection fixture subclasses
real UserDefaults and drops only the selected write; normal reads/writes retain the
actual private suite backing. Two old-API probes against parent1f107f9's actual
store reproduced6failures; the current8broader tests pass. The old probes were not
rerun verbatim against current source, so this is not mislabeled an identical suite.

Prompt12NavigationRow now uses the existing canonical CutePopButtonStyle and no
longer truncates its detail to two lines. The actual SwiftSyntax owner tool removed
9duplicate caller buttonSoftPop calls from Account/Settings; the row itself keeps
its existing one cue. A new compiler-backed regression tests row ownership while
retaining a distinct popupClose cue. Source checks are not audible device playback.

Apple SwiftUI/Combine/UIKit typechecking, modal rendering, VoiceOver, Dynamic Type,
reduced-motion and audio playback are NOT_RUN on Linux. Disposable account-specific
Apple UI scenarios, including private username injection, are the next batch. No
production credentials, remote deletion, push or merge were performed.
