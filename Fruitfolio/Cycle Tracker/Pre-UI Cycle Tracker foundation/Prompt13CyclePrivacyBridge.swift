import Foundation

/// Prompt 12/13 boundary: sensitive cycle content stays in the Cycle domain.
/// UI/account code may call this bridge for explicit export or erase actions without learning cycle internals.
nonisolated struct Prompt13CyclePrivacyBridge:
    Sendable
{
    let store: Prompt13CycleStore

    init(
        store:
            Prompt13CycleStore =
            .shared
    ) {
        self.store =
            store
    }

    func exportReadableJSON()
        async throws
        -> Data
    {
        try await
            store
                .exportArchiveJSON()
    }

    func eraseLocalCycleData()
        async throws
    {
        try await
            store
                .eraseAllLocalCycleData()
    }
}
