import Foundation
import CryptoKit
import FruitfolioMADLADRuntime

nonisolated enum FruitfolioMADLADError: Error {
    case modelMissing, modelIntegrity, initializationFailed, inferenceFailed, invalidLanguage
}

private nonisolated final class FruitfolioMADLADHandle: @unchecked Sendable {
    let pointer: UnsafeMutableRawPointer
    init(directory: URL) throws {
        var error: UnsafeMutablePointer<CChar>?
        let loaded = directory.path.withCString { fruitfolio_madlad_open($0, &error) }
        if let error { fruitfolio_madlad_free_string(error) }
        guard let loaded else { throw FruitfolioMADLADError.initializationFailed }
        pointer = loaded
    }
    deinit { fruitfolio_madlad_close(pointer) }
}

/// Serial local encoder-decoder access. Raw generation is NOT a medical safety
/// approval; callers must preserve source boundaries and independently validate
/// translation. The production Ask fallback stays active until those gates pass.
actor FruitfolioMADLADLocalRuntime {
    private var handle: FruitfolioMADLADHandle?
    private var verifiedDirectory: URL?

    func translateRawSentence(_ sentence: String, target: String, directory: URL) throws -> String {
        guard target.range(of: "^[a-z]{2,3}$", options: .regularExpression) != nil else {
            throw FruitfolioMADLADError.invalidLanguage
        }
        if handle == nil || verifiedDirectory != directory {
            try verifyModel(directory)
            handle = try FruitfolioMADLADHandle(directory: directory)
            verifiedDirectory = directory
        }
        guard let handle else { throw FruitfolioMADLADError.initializationFailed }
        let prompt = "<2\(target)> " + sentence
        guard let result = prompt.withCString({ fruitfolio_madlad_translate(handle.pointer, $0) }) else {
            throw FruitfolioMADLADError.inferenceFailed
        }
        defer { fruitfolio_madlad_free_string(result) }
        let data = Data(String(cString: result).utf8)
        let decoded = try JSONDecoder().decode(FruitfolioMADLADRawResult.self, from: data)
        guard decoded.ok, let text = decoded.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FruitfolioMADLADError.inferenceFailed
        }
        return text
    }

    func unload() { handle = nil; verifiedDirectory = nil }

    private func verifyModel(_ directory: URL) throws {
        // Verify the exact official tokenizer and architecture configuration as
        // well as weights; a correct weight hash alone cannot validate decoding.
        let expected = [
            ("added_tokens.json", "d914176fd50bd7f565700006a31aa97b79d3ad17cee20c8e5ff2061d5cb74817"),
            ("generation_config.json", "0849b38987568ccfe4ebefc22bbda1cec4bee01c345e93bfab207d4692b0a1d5"),
            ("special_tokens_map.json", "7f79f1d5063d56c4b980eec0692f3c7429bdef335071d34e566bd00fd4b5e3e0"),
            ("config.json", "cad399cab799b99409a6ec2d90d72552257c2bb752861261d2016691e0643e7c"),
            ("tokenizer_config.json", "641fc660745306dfb935f666a68f8bc10a44c39241cfb357be518fda8c09662d"),
            ("spiece.model", "ef11ac9a22c7503492f56d48dce53be20e339b63605983e9f27d2cd0e0f3922c"),
            ("tokenizer.json", "a2799ccc696b752ba00c34f58726bfe253a04921ceb6cfc620400f560474790b"),
            ("model-q4k.gguf", "ea6e5531a3e95213c7f0635988d119e078a655c09306e47851e15d4c0c3f9c37")
        ]
        for (name, digest) in expected {
            let resource = directory.appendingPathComponent(name)
            guard FileManager.default.fileExists(atPath: resource.path) else { throw FruitfolioMADLADError.modelMissing }
            let file = try FileHandle(forReadingFrom: resource)
            defer { try? file.close() }
            var sha = SHA256()
            while let data = try file.read(upToCount: 8*1024*1024), !data.isEmpty { sha.update(data: data) }
            let actual = sha.finalize().map { String(format: "%02x", $0) }.joined()
            guard actual == digest else { throw FruitfolioMADLADError.modelIntegrity }
        }
    }
}

private nonisolated struct FruitfolioMADLADRawResult: Decodable, Sendable {
    let ok: Bool
    let text: String?
    let error: String?
}
