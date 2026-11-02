import Foundation

/// Freezes only the original answer's used source records. This is save-boundary
/// integrity validation, not scientific entailment or new source approval.
struct AskSavedAttributionSnapshot: Equatable, Sendable {
    let sourceIDs: [String]
    let sourceVersions: [String: String]
    let sources: [AskSourceRecord]

    init(answer: AskAnswer) throws {
        let ids = answer.sourceIDs
        guard ids.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw SnapshotError.invalidSourceID
        }
        guard Set(ids).count == ids.count else { throw SnapshotError.duplicateSourceID }
        let used = Set(ids)
        let selected = answer.sources.filter { used.contains($0.id) }
        guard Set(selected.map(\.id)).count == selected.count else { throw SnapshotError.duplicateSourceID }
        guard Set(selected.map(\.id)) == used else { throw SnapshotError.missingSourceSnapshot }
        var records: [String: AskSourceRecord] = [:]
        var versions: [String: String] = [:]
        for source in selected {
            guard let version = source.contentVersion,
                  !version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SnapshotError.missingSourceVersion
            }
            records[source.id] = source
            versions[source.id] = version
        }
        sourceIDs = ids
        sourceVersions = versions
        sources = ids.compactMap { records[$0] }
    }

    enum SnapshotError: LocalizedError, Equatable {
        case invalidSourceID, duplicateSourceID, missingSourceSnapshot, missingSourceVersion
        var errorDescription: String? {
            "this answer’s original source information is incomplete or conflicting, so it can’t be saved safely yet. your answer is still here."
        }
    }
}
