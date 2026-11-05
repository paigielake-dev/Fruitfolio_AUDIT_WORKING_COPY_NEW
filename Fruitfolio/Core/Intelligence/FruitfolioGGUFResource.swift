import Foundation

/// Resource-format preflight only. A positive result is not evidence that the
/// model can load, generate, fit in memory, or meet quality requirements.
enum FruitfolioGGUFResource {
    static func isReadableModel(at url: URL) -> Bool {
        guard let file = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? file.close() }
        guard let header = try? file.read(upToCount: 24), header.count == 24,
              header.prefix(4) == Data("GGUF".utf8) else { return false }
        let bytes = Array(header)
        let version = UInt32(bytes[4]) | UInt32(bytes[5]) << 8 | UInt32(bytes[6]) << 16 | UInt32(bytes[7]) << 24
        let tensorCount = (0..<8).reduce(UInt64(0)) { $0 | UInt64(bytes[8 + $1]) << ($1 * 8) }
        return (version == 2 || version == 3) && tensorCount > 0
    }
}
