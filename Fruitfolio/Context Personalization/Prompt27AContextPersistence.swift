import Foundation

nonisolated enum Prompt27AContextPersistenceError: Error, Equatable, Sendable {
    case encodingFailed
    case decodingFailed
}

nonisolated enum Prompt27AContextMigrationResult: Equatable, Sendable {
    case noStoredValue
    case decoded(Prompt27AUserReproductiveContext)
    case corruptStoredValue

    var context: Prompt27AUserReproductiveContext {
        switch self {
        case .decoded(let context): return context
        case .noStoredValue, .corruptStoredValue: return .unspecified
        }
    }
}

nonisolated struct Prompt27AContextCodec: Sendable {
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        self.decoder = decoder
    }

    func encode(_ context: Prompt27AUserReproductiveContext) throws -> Data {
        do { return try encoder.encode(context) }
        catch { throw Prompt27AContextPersistenceError.encodingFailed }
    }

    func decode(_ data: Data) throws -> Prompt27AUserReproductiveContext {
        do { return try decoder.decode(Prompt27AUserReproductiveContext.self, from: data) }
        catch { throw Prompt27AContextPersistenceError.decodingFailed }
    }

    func migrationResult(data: Data?) -> Prompt27AContextMigrationResult {
        guard let data else { return .noStoredValue }
        guard let context = try? decode(data) else { return .corruptStoredValue }
        return .decoded(context)
    }

    /// Compatibility helper for call sites that only need the recovered value.
    /// Callers that own persistence should use `migrationResult(data:)` so a
    /// corrupt payload is handled explicitly rather than silently treated as a
    /// valid empty context.
    func migrateExistingUser(data: Data?) -> Prompt27AUserReproductiveContext {
        migrationResult(data: data).context
    }
}
