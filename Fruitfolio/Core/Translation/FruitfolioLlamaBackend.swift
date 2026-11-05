#if canImport(llama)
import llama

/// llama backend registration belongs to the process, not an individual model.
/// Models and contexts are released independently; freeing global backends while
/// another actor is decoding would invalidate that actor's runtime.
enum FruitfolioLlamaBackend {
    private static let initialized: Void = { llama_backend_init() }()
    static func initialize() { _ = initialized }
}
#endif
