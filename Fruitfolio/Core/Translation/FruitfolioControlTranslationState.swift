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
        // Patient originals and citation identifiers retain their exact bytes.
        // Swift String equality otherwise merges NFC/NFD representations.
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.language == rhs.language &&
            lhs.source.utf8.elementsEqual(rhs.source.utf8) &&
            lhs.protectedLiterals.count == rhs.protectedLiterals.count &&
            zip(lhs.protectedLiterals, rhs.protectedLiterals).allSatisfy {
                $0.utf8.elementsEqual($1.utf8)
            }
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(language)
            hasher.combine(Data(source.utf8))
            hasher.combine(protectedLiterals.count)
            for literal in protectedLiterals { hasher.combine(Data(literal.utf8)) }
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

/// One app-shell owner serializes lifecycle changes through actual resource
/// acknowledgements. UI pause remains set throughout release/foreground races.
@MainActor
final class FruitfolioTranslationLifecycleOwner {
    private let settings: SettingsStore
    private let service: FruitfolioTranslationService
    private var desiredActive: Bool?
    private var suspendedToken: UUID?
    private var foregroundEstablished = false
    private var worker: Task<Void, Never>?

    init(settings: SettingsStore, service: FruitfolioTranslationService = .shared) {
        self.settings = settings; self.service = service
        settings.translationPausedForLifecycle = true
    }

    func setActive(_ active: Bool) {
        guard desiredActive != active else { return }
        desiredActive = active
        settings.translationPausedForLifecycle = true
        guard worker == nil else { return }
        worker = Task { [weak self] in
            guard let self else { return }
            await self.reconcile()
        }
    }

    private func reconcile() async {
        while true {
            if desiredActive == true {
                if let token = suspendedToken {
                    if await service.resumeAfterLifecycle(token) {
                        suspendedToken = nil
                    } else {
                        let replacement = UUID()
                        await service.suspendForLifecycle(replacement)
                        suspendedToken = replacement
                    }
                    continue // Recheck desired activity after each actor hop.
                }
                if !foregroundEstablished {
                    guard await service.establishForegroundLifecycle() else { continue }
                    foregroundEstablished = true
                    continue
                }
                settings.translationPausedForLifecycle = false
                worker = nil
                return
            }
            if suspendedToken != nil {
                worker = nil
                return
            }
            let token = UUID()
            await service.suspendForLifecycle(token)
            suspendedToken = token
        }
    }

    #if DEBUG
    func debugWaitForReconciliation() async { await worker?.value }
    #endif
}
#if canImport(Combine)
extension FruitfolioTranslationLifecycleOwner: ObservableObject {}
#endif
