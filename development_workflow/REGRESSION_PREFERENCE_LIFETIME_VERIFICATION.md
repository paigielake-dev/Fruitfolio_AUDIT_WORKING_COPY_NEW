# Disposable regression preference lifetime

DEBUG UI regression routes now retain an explicit root StateObject owner of their unique private preference suite. Transient disappearance does not remove that domain. The owner deletes only its generated suite on deinitialization; no caller can supply the standard or arbitrary production domain. The production route still constructs the original shell with its normal authority.

Two actual Foundation regressions exercise saved settings read through recreated stores until owner release, domain cleanup after release even while a UserDefaults reference remains, independent simultaneously owned suites, and absence of a write to a unique standard-domain probe. These tests do not execute SwiftUI StateObject lifetime, UIKit background behavior or Combine on Linux.

The existing eight settings UI combinations now background and reactivate after changes, checking saved volume/effects and live toggle value. Six existing invalid element.firstMatch query chains were corrected to matching(identifier:).firstMatch. Apple typechecking and UI execution remain NOT_RUN.

The initial workflow run rejected a static assertion expecting the old inline suite creation. The route invariant was updated to the new owner-backed authority; actual creation/cleanup is tested with Foundation, not inferred from that source assertion. Final feasible counts are recorded in the batch log.
