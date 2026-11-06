import Foundation

/// Contains only opaque local identities, never copied laboratory values.
struct FruitfolioMeasurementDeletionIntent: Equatable, Sendable {
    enum Scope: Equatable, Sendable { case one(UUID), all }
    let scope: Scope
    let savedRevision: UUID

    @MainActor
    func perform(in store: FruitfolioHormoneMeasurementStore) throws {
        guard store.savedRecordRevision == savedRevision else { throw FruitfolioHormoneMeasurementError.confirmationChanged }
        switch scope {
        case .one(let id):
            guard store.records.contains(where: { $0.id == id }) else { throw FruitfolioHormoneMeasurementError.confirmationChanged }
            try store.delete(id: id)
        case .all:
            try store.eraseAllMeasurements()
        }
    }
}
