import Combine
import Foundation

/// Owns one user-requested export preparation. Cancellation prevents a late
/// snapshot from opening a destination after its owner has been left behind.
@MainActor
final class FruitfolioExportPreparation: ObservableObject {
    @Published private(set) var isPreparing = false
    private var requestID: UUID?
    private var task: Task<Void, Never>?

    deinit { task?.cancel() }

    func start(operation: @escaping @MainActor () async throws -> Data,
               completion: @escaping @MainActor (Result<Data, Error>) -> Void) {
        cancel()
        let id = UUID()
        requestID = id
        isPreparing = true
        task = Task { [weak self] in
            let result: Result<Data, Error>
            do {
                try Task.checkCancellation()
                let data = try await operation()
                try Task.checkCancellation()
                result = .success(data)
            } catch {
                result = .failure(error)
            }
            guard !Task.isCancelled, let self, self.requestID == id else { return }
            self.requestID = nil
            self.task = nil
            self.isPreparing = false
            completion(result)
        }
    }

    func cancel() {
        requestID = nil
        task?.cancel()
        task = nil
        isPreparing = false
    }
}
