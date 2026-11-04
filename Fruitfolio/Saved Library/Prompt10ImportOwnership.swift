import Foundation

/// Generation ownership for one editor's current system-photo transfer. Older
/// completions cannot clear a newer transfer's save/discard guard or selection.
nonisolated struct Prompt10ImportOwnership: Sendable {
    private var generation: UUID?
    var isImporting: Bool { generation != nil }

    mutating func begin() -> UUID {
        let id = UUID(); generation = id; return id
    }
    func owns(_ id: UUID) -> Bool { generation == id }
    @discardableResult mutating func finish(_ id: UUID) -> Bool {
        guard owns(id) else { return false }
        generation = nil; return true
    }
    mutating func invalidate() { generation = nil }
}
