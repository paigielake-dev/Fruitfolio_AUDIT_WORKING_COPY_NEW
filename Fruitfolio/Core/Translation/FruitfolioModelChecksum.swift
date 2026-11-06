import Foundation
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(FruitfolioOpenSSL)
import FruitfolioOpenSSL
#endif

/// Streaming SHA-256 using the host's established crypto implementation.
/// A correct digest proves byte integrity, not model origin or compatibility.
nonisolated enum FruitfolioModelChecksum {
    static func sha256(file: FileHandle) throws -> String {
        #if canImport(CryptoKit)
        var hash = SHA256()
        while let chunk = try file.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            try Task.checkCancellation()
            hash.update(data: chunk)
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
        #elseif canImport(FruitfolioOpenSSL)
        guard let context = EVP_MD_CTX_new() else { throw FruitfolioTranslationError.incompatibleModel }
        defer { EVP_MD_CTX_free(context) }
        guard EVP_DigestInit_ex(context, EVP_sha256(), nil) == 1 else {
            throw FruitfolioTranslationError.incompatibleModel
        }
        while let chunk = try file.read(upToCount: 1024 * 1024), !chunk.isEmpty {
            try Task.checkCancellation()
            let accepted = chunk.withUnsafeBytes { bytes in
                EVP_DigestUpdate(context, bytes.baseAddress, bytes.count)
            }
            guard accepted == 1 else { throw FruitfolioTranslationError.incompatibleModel }
        }
        var output = [UInt8](repeating: 0, count: 32)
        var length: UInt32 = 0
        guard EVP_DigestFinal_ex(context, &output, &length) == 1, length == 32 else {
            throw FruitfolioTranslationError.incompatibleModel
        }
        return output.map { String(format: "%02x", $0) }.joined()
        #else
        throw FruitfolioTranslationError.incompatibleModel
        #endif
    }
}
