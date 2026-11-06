import Foundation

enum FruitfolioTranslationError: LocalizedError, Equatable {
    case resourcesMissing, invalidManifest, checksumMismatch, incompatibleModel
    case unsupportedLanguage(String), inputTooLong, inferenceFailed, truncatedOutput, protectedContentChanged
    var errorDescription: String? {
        switch self {
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

    func verifyModel(at url: URL) throws {
        try validate()
        let file = try FileHandle(forReadingFrom: url)
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
}
