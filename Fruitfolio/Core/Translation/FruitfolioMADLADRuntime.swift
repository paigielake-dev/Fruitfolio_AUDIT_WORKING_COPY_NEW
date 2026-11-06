import Foundation
#if canImport(llama)
import llama

/// Serial, local-only T5 encoder/decoder execution. This actor does not contain
/// a downloader or a network client. All resources must be installed beforehand.
actor FruitfolioMADLADRuntime: FruitfolioLocalTranslationRuntime {
    static let shared = FruitfolioMADLADRuntime()
    private var model: OpaquePointer?
    private var context: OpaquePointer?
    private var vocab: OpaquePointer?
    private var sampler: UnsafeMutablePointer<llama_sampler>?
    private var manifest: FruitfolioMADLADManifest?
    private let resourceDirectory: URL?

    init(resourceDirectory: URL? = nil) { self.resourceDirectory = resourceDirectory }
    deinit {
        if let sampler { llama_sampler_free(sampler) }
        if let context { llama_free(context) }
        if let model { llama_model_free(model) }
    }

    /// Actor-isolated: synchronous encode/decode cannot be freed mid-call.
    /// The caller cancels owned translation tasks before requesting release.
    func releaseResources() {
        if let sampler { llama_sampler_free(sampler) }
        sampler = nil
        if let context { llama_free(context) }
        context = nil
        vocab = nil
        if let model { llama_model_free(model) }
        model = nil
        manifest = nil
        // Process-wide backend registration also serves Ask; never free it here.
    }

    func translate(_ text: String, targetTag: String) async throws -> String {
        try Task.checkCancellation()
        try loadIfNeeded()
        guard let model, let context, let vocab, let sampler, let manifest else {
            throw FruitfolioTranslationError.resourcesMissing
        }
        defer { llama_memory_clear(llama_get_memory(context), true) }
        guard manifest.supportedLanguageTags.contains(targetTag) else {
            throw FruitfolioTranslationError.unsupportedLanguage(targetTag)
        }
        let tag = "<2\(targetTag)>"
        let tagTokens = try tokenize(tag, vocab: vocab, addSpecial: false)
        guard tagTokens.count == 1,
              String(bytes: try piece(tagTokens[0], vocab: vocab, special: true), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) == tag else {
            throw FruitfolioTranslationError.unsupportedLanguage(targetTag)
        }
        let input = try tokenize("\(tag) \(text)", vocab: vocab, addSpecial: true)
        guard input.count < manifest.contextLength else { throw FruitfolioTranslationError.inputTooLong }
        llama_memory_clear(llama_get_memory(context), true)
        llama_sampler_reset(sampler)
        var batch = llama_batch_init(Int32(manifest.contextLength), 0, 1)
        defer { llama_batch_free(batch) }
        for (index, token) in input.enumerated() { try add(token, position: index, logits: false, batch: &batch) }
        try Task.checkCancellation()
        guard llama_encode(context, batch) == 0 else { throw FruitfolioTranslationError.inferenceFailed }
        var decoderToken = llama_model_decoder_start_token(model)
        if decoderToken == LLAMA_TOKEN_NULL { decoderToken = llama_vocab_bos(vocab) }
        guard decoderToken != LLAMA_TOKEN_NULL else { throw FruitfolioTranslationError.incompatibleModel }
        var output: [UInt8] = []
        for position in 0..<manifest.maximumOutputTokens {
            try Task.checkCancellation()
            batch.n_tokens = 0
            try add(decoderToken, position: position, logits: true, batch: &batch)
            guard llama_decode(context, batch) == 0 else { throw FruitfolioTranslationError.inferenceFailed }
            let sampled = llama_sampler_sample(sampler, context, -1)
            if llama_vocab_is_eog(vocab, sampled) {
                guard let result = String(bytes: output, encoding: .utf8), !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw FruitfolioTranslationError.inferenceFailed
                }
                return result.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            output.append(contentsOf: try piece(sampled, vocab: vocab, special: false))
            decoderToken = sampled
        }
        // A length-limited output is not a successful translation.
        throw FruitfolioTranslationError.truncatedOutput
    }

    private func loadIfNeeded() throws {
        if model != nil { return }
        let directory = resourceDirectory ?? Bundle.main.resourceURL
        guard let directory,
              let data = try? Data(contentsOf: directory.appendingPathComponent("MADLAD400.manifest.json")) else {
            throw FruitfolioTranslationError.resourcesMissing
        }
        let config = try JSONDecoder().decode(FruitfolioMADLADManifest.self, from: data)
        try config.validate()
        let modelURL = directory.appendingPathComponent(config.modelFile)
        try config.verifyModel(at: modelURL)
        try config.verifyExecutableMetadata(at: modelURL)
        try Task.checkCancellation()
        FruitfolioLlamaBackend.initialize()
        var parameters = llama_model_default_params()
        // Start with CPU execution on all targets. Enable Metal only after the
        // installed T5 graph passes compatibility and device memory checks.
        parameters.n_gpu_layers = 0
        guard let loaded = llama_model_load_from_file(modelURL.path, parameters) else {
            throw FruitfolioTranslationError.incompatibleModel
        }
        guard !Task.isCancelled else {
            llama_model_free(loaded)
            throw CancellationError()
        }
        var architecture = [CChar](repeating: 0, count: 64)
        let architectureCapacity = architecture.count
        let length = llama_model_meta_val_str(loaded, "general.architecture", &architecture, architectureCapacity)
        guard length > 0, Int(length) < architectureCapacity, String(cString: architecture) == "t5",
              llama_model_has_encoder(loaded), llama_model_has_decoder(loaded) else {
            llama_model_free(loaded)
            throw FruitfolioTranslationError.incompatibleModel
        }
        var contextParameters = llama_context_default_params()
        contextParameters.n_ctx = UInt32(config.contextLength)
        contextParameters.n_batch = UInt32(config.contextLength)
        contextParameters.n_ubatch = UInt32(config.contextLength)
        let threads = Int32(max(1, min(4, ProcessInfo.processInfo.activeProcessorCount - 1)))
        contextParameters.n_threads = threads
        contextParameters.n_threads_batch = threads
        guard let loadedContext = llama_init_from_model(loaded, contextParameters) else {
            llama_model_free(loaded)
            throw FruitfolioTranslationError.incompatibleModel
        }
        guard !Task.isCancelled else {
            llama_free(loadedContext); llama_model_free(loaded)
            throw CancellationError()
        }
        guard llama_n_ctx(loadedContext) >= UInt32(config.contextLength) else {
            llama_free(loadedContext); llama_model_free(loaded)
            throw FruitfolioTranslationError.incompatibleModel
        }
        guard let loadedVocab = llama_model_get_vocab(loaded) else {
            llama_free(loadedContext); llama_model_free(loaded)
            throw FruitfolioTranslationError.incompatibleModel
        }
        guard let loadedSampler = llama_sampler_init_greedy() else {
            llama_free(loadedContext); llama_model_free(loaded)
            throw FruitfolioTranslationError.inferenceFailed
        }
        model = loaded
        context = loadedContext
        vocab = loadedVocab
        sampler = loadedSampler
        manifest = config
    }

    private func tokenize(_ text: String, vocab: OpaquePointer, addSpecial: Bool) throws -> [llama_token] {
        let required = llama_tokenize(vocab, text, Int32(text.utf8.count), nil, 0, addSpecial, true)
        guard required < 0 else { throw FruitfolioTranslationError.inferenceFailed }
        var tokens = [llama_token](repeating: 0, count: Int(-required))
        let capacity = Int32(tokens.count)
        let count = llama_tokenize(vocab, text, Int32(text.utf8.count), &tokens, capacity, addSpecial, true)
        guard count > 0, Int(count) <= tokens.count else { throw FruitfolioTranslationError.inferenceFailed }
        return Array(tokens.prefix(Int(count)))
    }

    private func add(_ token: llama_token, position: Int, logits: Bool, batch: inout llama_batch) throws {
        let index = Int(batch.n_tokens)
        guard let ids = batch.seq_id[index] else { throw FruitfolioTranslationError.inferenceFailed }
        batch.token[index] = token
        batch.pos[index] = Int32(position)
        batch.n_seq_id[index] = 1
        ids[0] = 0
        batch.logits[index] = logits ? 1 : 0
        batch.n_tokens += 1
    }

    private func piece(_ token: llama_token, vocab: OpaquePointer, special: Bool) throws -> [UInt8] {
        var buffer = [CChar](repeating: 0, count: 128)
        var capacity = Int32(buffer.count)
        var count = llama_token_to_piece(vocab, token, &buffer, capacity, 0, special)
        if count < 0 {
            buffer = [CChar](repeating: 0, count: Int(-count))
            capacity = Int32(buffer.count)
            count = llama_token_to_piece(vocab, token, &buffer, capacity, 0, special)
        }
        guard count >= 0, Int(count) <= buffer.count else { throw FruitfolioTranslationError.inferenceFailed }
        return buffer.prefix(Int(count)).map { UInt8(bitPattern: $0) }
    }
}
#else
actor FruitfolioMADLADRuntime: FruitfolioLocalTranslationRuntime {
    static let shared = FruitfolioMADLADRuntime()
    func releaseResources() {}
    func translate(_ text: String, targetTag: String) async throws -> String {
        throw FruitfolioTranslationError.resourcesMissing
    }
}
#endif
