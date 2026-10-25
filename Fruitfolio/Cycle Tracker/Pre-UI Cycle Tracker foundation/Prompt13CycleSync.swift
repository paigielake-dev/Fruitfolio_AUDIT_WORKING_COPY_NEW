import Foundation

nonisolated enum Prompt13SyncConflictKind:
    String,
    Codable,
    Sendable
{
    case sameRecordSameRevisionDifferentContent =
        "same_record_same_revision_different_content"

    case duplicateCycleStartDate =
        "duplicate_cycle_start_date"
}

nonisolated struct Prompt13SyncConflict:
    Codable,
    Equatable,
    Identifiable,
    Sendable
{
    let id: UUID
    let kind: Prompt13SyncConflictKind
    let localRecordID: UUID?
    let remoteRecordID: UUID?
    let date: Prompt13LocalDate?
    let detail: String

    init(
        id: UUID = UUID(),
        kind: Prompt13SyncConflictKind,
        localRecordID: UUID?,
        remoteRecordID: UUID?,
        date: Prompt13LocalDate?,
        detail: String
    ) {
        self.id = id
        self.kind = kind
        self.localRecordID = localRecordID
        self.remoteRecordID = remoteRecordID
        self.date = date
        self.detail = detail
    }
}

nonisolated struct Prompt13SyncConflictDetector:
    Sendable
{
    func conflicts(
        local: Prompt13CycleArchive,
        remote: Prompt13CycleArchive
    ) -> [Prompt13SyncConflict] {
        var conflicts:
            [Prompt13SyncConflict] = []

        let localByID =
            Dictionary(
                uniqueKeysWithValues:
                    local
                        .cycleStarts
                        .map {
                            (
                                $0.id,
                                $0
                            )
                        }
            )

        let remoteByID =
            Dictionary(
                uniqueKeysWithValues:
                    remote
                        .cycleStarts
                        .map {
                            (
                                $0.id,
                                $0
                            )
                        }
            )

        for id in
            Set(localByID.keys)
            .intersection(
                remoteByID.keys
            )
        {
            guard
                let localRecord =
                    localByID[id],
                let remoteRecord =
                    remoteByID[id]
            else {
                continue
            }

            if
                localRecord
                    .metadata
                    .revision ==
                remoteRecord
                    .metadata
                    .revision,
                localRecord !=
                remoteRecord
            {
                conflicts.append(
                    Prompt13SyncConflict(
                        kind:
                            .sameRecordSameRevisionDifferentContent,
                        localRecordID:
                            id,
                        remoteRecordID:
                            id,
                        date:
                            localRecord.date,
                        detail:
                            "The same CycleStart ID has different content at the same revision. Automatic merging is intentionally blocked."
                    )
                )
            }
        }

        let activeLocal =
            local
                .cycleStarts
                .filter {
                    !$0.metadata.isDeleted
                }

        let activeRemote =
            remote
                .cycleStarts
                .filter {
                    !$0.metadata.isDeleted
                }

        for localRecord in activeLocal {
            for remoteRecord in activeRemote
            where
                localRecord.id !=
                    remoteRecord.id &&
                localRecord.date ==
                    remoteRecord.date
            {
                conflicts.append(
                    Prompt13SyncConflict(
                        kind:
                            .duplicateCycleStartDate,
                        localRecordID:
                            localRecord.id,
                        remoteRecordID:
                            remoteRecord.id,
                        date:
                            localRecord.date,
                        detail:
                            "Two different active CycleStart IDs claim the same calendar date. This needs review rather than silent duplication."
                    )
                )
            }
        }

        return conflicts
            .reduce(
                into:
                    [Prompt13SyncConflict]()
            ) {
                result,
                conflict in

                let alreadyPresent =
                    result.contains {
                        $0.kind ==
                            conflict.kind &&
                        $0.localRecordID ==
                            conflict.localRecordID &&
                        $0.remoteRecordID ==
                            conflict.remoteRecordID &&
                        $0.date ==
                            conflict.date
                    }

                if !alreadyPresent {
                    result.append(
                        conflict
                    )
                }
            }
            .sorted {
                if
                    $0.kind.rawValue !=
                    $1.kind.rawValue
                {
                    return
                        $0.kind.rawValue <
                        $1.kind.rawValue
                }

                return
                    (
                        $0.date?.description ??
                        ""
                    ) <
                    (
                        $1.date?.description ??
                        ""
                    )
            }
    }
}
