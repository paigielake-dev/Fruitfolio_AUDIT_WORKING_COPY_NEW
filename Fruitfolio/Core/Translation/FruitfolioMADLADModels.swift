import Foundation

enum FruitfolioTranslationError: LocalizedError, Equatable {
    case resourcesMissing, invalidManifest, checksumMismatch, incompatibleModel, pausedForMemoryPressure
    case unsupportedLanguage(String), inputTooLong, inferenceFailed, truncatedOutput, protectedContentChanged
    var errorDescription: String? {
        switch self {
        case .pausedForMemoryPressure: return "local translation is paused to reduce memory use. the original text is preserved."
        case .resourcesMissing: return "translation resources are not available on this device. the original text is preserved."
        case .unsupportedLanguage: return "this language is not verified for the installed translation model. the original text is preserved."
        case .invalidManifest, .checksumMismatch, .incompatibleModel:
            return "the translation model could not be verified. the original text is preserved."
        case .inputTooLong: return "this passage is too long for the installed translation model. the original text is preserved."
        case .inferenceFailed, .truncatedOutput: return "translation could not finish. the original text is preserved."
        case .protectedContentChanged: return "translation changed protected scientific information and was not used. the original text is preserved."
        }
    }
}

struct FruitfolioMADLADManifest: Codable, Equatable, Sendable {
    let modelFile: String
    let sha256: String
    let sourceRepository: String
    let sourceRevision: String
    let architecture: String
    let tokenizer: String
    let supportedLanguageTags: [String]
    let contextLength: Int
    let maximumOutputTokens: Int

    /// Small local configuration only. A corrupt resource must not allocate an
    /// arbitrarily large JSON buffer or expose an opaque decoder error to UI.
    static func load(at url: URL) throws -> Self {
        try Task.checkCancellation()
        let file: FileHandle
        do { file = try FileHandle(forReadingFrom: url) }
        catch { throw FruitfolioTranslationError.resourcesMissing }
        defer { try? file.close() }
        let limit = 64 * 1024
        var data = Data()
        do {
            while true {
                try Task.checkCancellation()
                guard let chunk = try file.read(upToCount: min(4096, limit + 1 - data.count)),
                      !chunk.isEmpty else { break }
                data.append(chunk)
                guard data.count <= limit else { throw FruitfolioTranslationError.invalidManifest }
            }
        } catch let error as CancellationError { throw error }
        catch let error as FruitfolioTranslationError { throw error }
        catch { throw FruitfolioTranslationError.resourcesMissing }
        let config: Self
        do { config = try JSONDecoder().decode(Self.self, from: data) }
        catch { throw FruitfolioTranslationError.invalidManifest }
        try config.validate()
        try Task.checkCancellation()
        return config
    }

    func validate() throws {
        let hex = CharacterSet(charactersIn: "0123456789abcdef")
        guard architecture == "t5", tokenizer == "embedded-sentencepiece",
              modelFile.hasSuffix(".gguf"), modelFile == URL(fileURLWithPath: modelFile).lastPathComponent,
              !modelFile.contains(".."), sha256.count == 64,
              sha256.unicodeScalars.allSatisfy(hex.contains),
              sourceRepository == "google/madlad400-3b-mt", sourceRevision.count == 40,
              sourceRevision.unicodeScalars.allSatisfy(hex.contains),
              contextLength >= 64, contextLength <= 4096,
              maximumOutputTokens > 0, maximumOutputTokens < contextLength,
              !supportedLanguageTags.isEmpty,
              supportedLanguageTags.allSatisfy({ $0.range(of: "^[A-Za-z][A-Za-z0-9_-]{0,15}$", options: .regularExpression) != nil }) else {
            throw FruitfolioTranslationError.invalidManifest
        }
    }

    /// Header/tokenizer compatibility is independent of digest acceptance. This
    /// bounded check rejects incompatible resources before native allocation;
    /// only actual encode/decode can establish executable graph compatibility.
    func verifyExecutableMetadata(at url: URL) throws {
        do {
            let reader = try FruitfolioGGUFCompatibilityReader(url: url)
            let metadata = try reader.compatibilityMetadata()
            guard metadata["general.architecture"] == architecture,
                  metadata["tokenizer.ggml.model"] == "t5" else {
                throw FruitfolioTranslationError.incompatibleModel
            }
        } catch let error as CancellationError { throw error }
        catch { throw FruitfolioTranslationError.incompatibleModel }
    }

    func verifyModel(at url: URL) throws {
        try validate()
        let file: FileHandle
        do { file = try FileHandle(forReadingFrom: url) }
        catch { throw FruitfolioTranslationError.resourcesMissing }
        defer { try? file.close() }
        guard try file.read(upToCount: 4) == Data("GGUF".utf8) else {
            throw FruitfolioTranslationError.incompatibleModel
        }
        try file.seek(toOffset: 0)
        guard try FruitfolioModelChecksum.sha256(file: file) == sha256 else {
            throw FruitfolioTranslationError.checksumMismatch
        }
    }
}

protocol FruitfolioLocalTranslationRuntime: Sendable {
    func translate(_ text: String, targetTag: String) async throws -> String
    func releaseResources() async
}

/// Reads only GGUF metadata, never tensor payloads or a vocabulary-sized buffer.
/// Unneeded values are skipped with file-bound/overflow checks. This is not a
/// replacement for llama's graph loader or verification of official provenance.
private final class FruitfolioGGUFCompatibilityReader {
    private let file: FileHandle
    private let length: UInt64
    private var offset: UInt64 = 0
    private let maximumEntries: UInt64 = 1_000_000

    init(url: URL) throws {
        let opened = try FileHandle(forReadingFrom: url)
        do {
            length = try opened.seekToEnd()
            try opened.seek(toOffset: 0)
            file = opened
        } catch { try? opened.close(); throw error }
    }
    deinit { try? file.close() }

    func compatibilityMetadata() throws -> [String: String] {
        guard try bytes(4) == Data("GGUF".utf8) else { throw invalid }
        let version = try unsigned(4)
        guard version == 2 || version == 3 else { throw invalid }
        _ = try unsigned(8) // Tensor count: the native loader owns tensor checks.
        let count = try unsigned(8)
        guard count <= 4096 else { throw invalid }
        var result: [String: String] = [:]
        var seenKeys = Set<String>()
        for _ in 0..<count {
            try Task.checkCancellation()
            let key = try string(maximumBytes: 1024)
            guard seenKeys.insert(key).inserted else { throw invalid }
            let type = try unsigned(4)
            if key == "general.architecture" || key == "tokenizer.ggml.model" {
                guard type == 8 else { throw invalid }
                result[key] = try string(maximumBytes: 64)
            } else { try skipValue(type) }
        }
        return result
    }

    private var invalid: FruitfolioTranslationError { .incompatibleModel }
    private func bytes(_ count: UInt64) throws -> Data {
        try Task.checkCancellation()
        guard count <= length - offset, count <= UInt64(Int.max),
              let data = try file.read(upToCount: Int(count)), data.count == Int(count) else { throw invalid }
        offset += count
        return data
    }
    private func unsigned(_ width: UInt64) throws -> UInt64 {
        let data = try bytes(width)
        return data.enumerated().reduce(UInt64(0)) { $0 | (UInt64($1.element) << (8 * $1.offset)) }
    }
    private func string(maximumBytes: UInt64) throws -> String {
        let count = try unsigned(8)
        guard count <= maximumBytes, let value = String(data: try bytes(count), encoding: .utf8) else { throw invalid }
        return value
    }
    private func skip(_ count: UInt64) throws {
        try Task.checkCancellation()
        guard count <= length - offset else { throw invalid }
        offset += count
        try file.seek(toOffset: offset)
    }
    private func fixedWidth(_ type: UInt64) -> UInt64? {
        switch type {
        case 0, 1, 7: return 1
        case 2, 3: return 2
        case 4, 5, 6: return 4
        case 10, 11, 12: return 8
        default: return nil
        }
    }
    private func skipValue(_ type: UInt64) throws {
        if let width = fixedWidth(type) { try skip(width); return }
        switch type {
        case 8:
            try skip(unsigned(8))
        case 9:
            let elementType = try unsigned(4)
            let count = try unsigned(8)
            guard count <= maximumEntries else { throw invalid }
            if let width = fixedWidth(elementType) {
                let (size, overflow) = count.multipliedReportingOverflow(by: width)
                guard !overflow else { throw invalid }
                try skip(size)
            } else if elementType == 8 {
                for _ in 0..<count { try skip(unsigned(8)) }
            } else { throw invalid } // GGUF arrays cannot contain arrays.
        default: throw invalid
        }
    }
}
