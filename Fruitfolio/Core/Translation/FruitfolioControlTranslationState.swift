import Foundation
#if canImport(Combine)
import Combine
#endif

/// Display-only state for a single real control. No source label or saved record
/// is rewritten. The generation guard owns results across actor suspension.
@MainActor
final class FruitfolioControlTranslationState {
    struct Key: Hashable, Sendable {
        let source: String
        let language: FruitfolioLanguage
        let protectedLiterals: [String]
        init(source: String, language: FruitfolioLanguage, protectedLiterals: [String] = []) {
            self.source = source
            self.language = language
            self.protectedLiterals = protectedLiterals
        }
    }
    struct Presentation: Equatable, Sendable {
        let text: String
        let status: Status
        enum Status: Equatable, Sendable {
            case source, preparing, catalog, machine, unavailable
            var captionKey: String? {
                switch self {
                case .source, .catalog: return nil
                case .preparing: return "original text"
                case .machine: return "local machine translation"
                case .unavailable: return "original text — translation unavailable"
                }
            }
            func accessibilityDetail(original: String, localized: (String) -> String) -> String {
                switch self {
                case .source, .catalog: return ""
                case .preparing: return localized("original text — preparing local translation…")
                case .machine: return localized("local machine translation") + ". " + localized("original text") + ": " + original
                case .unavailable: return localized("original text — translation unavailable")
                }
            }
        }
    }
    struct TaskKey: Hashable, Sendable {
        let key: Key
        let inferenceAllowed: Bool
    }
    private let service: FruitfolioTranslationService
    private var generation = UUID()
    private var resolvedKey: Key?
    #if canImport(Combine)
    @Published private var resolved: Presentation?
    #else
    private var resolved: Presentation?
    #endif

    init(service: FruitfolioTranslationService = .shared) { self.service = service }

    func presentation(for key: Key) -> Presentation {
        if resolvedKey == key, let resolved { return resolved }
        return .init(text: key.source, status: key.language == .english ? .source : .preparing)
    }

    func resolve(_ key: Key, inferenceAllowed: Bool, bundle: Bundle = .main) async {
        // Releasing native allocations does not invalidate accepted display text.
        if resolvedKey == key, let resolved,
           resolved.status == .catalog || resolved.status == .machine || resolved.status == .source { return }
        let request = UUID()
        generation = request
        resolvedKey = key
        resolved = .init(text: key.source, status: key.language == .english ? .source : .preparing)
        do {
            let result = try await service.translateForDisplay(key.source, language: key.language,
                protectedLiterals: ["Fruitfolio", "LifeBridge"] + key.protectedLiterals, inferenceAllowed: inferenceAllowed, bundle: bundle)
            try Task.checkCancellation()
            guard generation == request, resolvedKey == key else { return }
            let status: Presentation.Status
            switch result.origin {
            case .source: status = .source
            case .catalog: status = .catalog
            case .machine: status = .machine
            }
            resolved = .init(text: result.text, status: status)
        } catch {
            guard !Task.isCancelled, generation == request, resolvedKey == key else { return }
            resolved = .init(text: key.source, status: .unavailable)
        }
    }
}
#if canImport(Combine)
extension FruitfolioControlTranslationState: ObservableObject {}
#endif
