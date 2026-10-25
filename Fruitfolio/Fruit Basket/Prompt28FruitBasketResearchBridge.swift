import Foundation

/// Prompt 28 consumes approved, already-retrieved educational records through this
/// narrow contract. It never falls back to web search or model memory.
protocol Prompt28ResearchProviding: Sendable {
    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question
}

enum Prompt28ResearchError: LocalizedError, Equatable, Sendable {
    case providerUnavailable
    case unsupportedTopic
    case topicExhausted
    case invalidQuestion
    case sourceValidationFailed

    var errorDescription: String? {
        switch self {
        case .providerUnavailable:
            return "the approved FruitsofLife.xo research library is not connected to Fruit Basket in this build yet."
        case .unsupportedTopic:
            return "i don’t have enough approved research on that one in the FruitsofLife.xo library yet :,)"
        case .topicExhausted:
            return "you picked through this little patch for now. wanna try another topic?"
        case .invalidQuestion:
            return "that question could not be validated for a fair Fruit Basket round."
        case .sourceValidationFailed:
            return "the source trail for that question could not be verified."
        }
    }
}

/// Safe production default for the current Prompt 01–27A source tree.
/// Prompt 09 explicitly identifies its provider as a development layout preview,
/// so Prompt 28 refuses to turn that preview into medical/scientific game content.
struct Prompt28UnavailableResearchProvider: Prompt28ResearchProviding {
    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question {
        throw Prompt28ResearchError.providerUnavailable
    }
}

/// Adapter point for the later canonical Research Library/RAG implementation.
/// A real provider supplies a fully validated Prompt28Question only after retrieval,
/// source validation, catch-concept validation, and available-art validation.
struct Prompt28ResearchLibraryBridge: Prompt28ResearchProviding {
    typealias Resolver = @Sendable (
        _ topic: String,
        _ normalizedTopic: String,
        _ difficulty: Prompt28EducationalDifficulty,
        _ excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question

    private let resolver: Resolver

    init(resolver: @escaping Resolver) {
        self.resolver = resolver
    }

    func question(
        topic: String,
        normalizedTopic: String,
        difficulty: Prompt28EducationalDifficulty,
        excludingQuestionIDs: Set<String>
    ) async throws -> Prompt28Question {
        let candidate = try await resolver(topic, normalizedTopic, difficulty, excludingQuestionIDs)
        guard candidate.isPlayable else { throw Prompt28ResearchError.invalidQuestion }
        guard !candidate.sourceIDs.isEmpty else { throw Prompt28ResearchError.sourceValidationFailed }
        return candidate
    }
}
