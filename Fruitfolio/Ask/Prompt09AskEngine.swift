import Foundation

/// Development-only provider used until the later canonical Research Library/RAG phases
/// connect the real local approved corpus. It deliberately contains no medical facts.
struct Prompt09DevelopmentAskEngine: AskKnowledgeServing {
    func answer(question: String, conversation: [AskMessage]) async throws -> AskAnswer {
        let normalized = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { throw AskEngineError.emptyQuestion }

        try? await Task.sleep(nanoseconds: 420_000_000)

        return AskAnswer(
            originalQuestion: normalized,
            answerText: "this is the Prompt 09 layout preview. the production answer will only be generated from approved FruitsofLife.xo research once the canonical research library is connected.",
            support: .supported,
            supportMap: [],
            sourceIDs: [],
            sources: [],
            knowledgeBaseVersion: "prompt09-development-preview",
            conceptTags: [],
            researchGap: nil,
            isDevelopmentPreview: true
        )
    }
}

actor Prompt09InMemorySaveStore: AskSaving {
    private(set) var requests: [AskSaveRequest] = []

    func save(_ request: AskSaveRequest) async throws {
        requests.append(request)
    }

    func savedRequests() -> [AskSaveRequest] {
        requests
    }
}
