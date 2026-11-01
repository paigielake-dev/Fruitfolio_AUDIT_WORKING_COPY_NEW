import Combine
import Foundation

@MainActor
final class Prompt09AskViewModel: ObservableObject {
    enum Phase: Equatable {
        case ready
        case searching
        case answering
        case failed(String)
    }

    static let greeting = "hi hi! ⟡ ݁ ₊ . what would you like to learn today?"
    static let sourcesHeading = "sources ˚ ☆ ‧ ₊"
    static let educationDisclaimer = "this is for education only, not medical advice."

    static let suggestedQuestions = [
        "why does cervical mucus change?",
        "what happens during ovulation?",
        "why do breasts feel sore before a period?",
        "what does progesterone do?",
        "what happens after fertilization?"
    ]

    @Published var inputText = ""
    @Published private(set) var messages: [AskMessage]
    @Published private(set) var answer: AskAnswer?
    @Published private(set) var sessionAnswers: [UUID: AskAnswer] = [:]
    @Published private(set) var phase: Phase = .ready
    @Published private(set) var searchStatusText = "looking through the FruitsofLife.xo library…"
    @Published private(set) var displayedAnswerText = ""
    @Published private(set) var selectedEducationalAssets: [EducationalAssetDescriptor] = []
    @Published var isSaved = false
    @Published var selectedExcerptText: String?
    @Published var selectedExcerptRange: NSRange?
    @Published private(set) var excerptSaved = false

    let conversationID: UUID

    private let engine: any AskKnowledgeServing
    private let router: EducationalAssetRouter
    private var typingTask: Task<Void, Never>?
    private var requestTask: Task<Void, Never>?
    private var requestGeneration = UUID()

    init(
        conversationID: UUID = UUID(),
        engine: (any AskKnowledgeServing)? = nil,
        saver: (any AskSaving)? = nil,
        router: EducationalAssetRouter? = nil
    ) {
        self.conversationID = conversationID
        self.engine = engine ?? FruitfolioResearchIntelligenceEngine.shared
        self.router = router ?? .shared

        self.messages = [
            AskMessage(
                role: .fruitfolio,
                text: Self.greeting
            )
        ]
    }

    deinit {
        typingTask?.cancel()
        requestTask?.cancel()
    }

    func cancelOutstandingWork() {
        requestTask?.cancel()
        requestTask = nil
        requestGeneration = UUID()
        typingTask?.cancel()
        typingTask = nil
    }

    var canSend: Bool {
        !inputText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
            && phase != .searching
    }

    var visibleMessages: [AskMessage] {
        let answerIDs = Set(sessionAnswers.values.map(\.id))
        return messages.filter { !answerIDs.contains($0.id) }
    }

    var isConversationStarted: Bool {
        messages.contains {
            $0.role == .user
        }
    }

    func useSuggestion(
        _ suggestion: String
    ) {
        inputText = suggestion
    }

    func submitCurrentQuestion(
        reduceMotion: Bool
    ) async {
        guard canSend else { return }
        requestTask?.cancel()
        let generation = UUID()
        requestGeneration = generation
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performSubmitCurrentQuestion(reduceMotion: reduceMotion, generation: generation)
        }
        requestTask = task
        await task.value
        if requestGeneration == generation {
            requestTask = nil
        }
    }

    private func performSubmitCurrentQuestion(
        reduceMotion: Bool,
        generation: UUID
    ) async {
        let question = inputText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard
            !question.isEmpty,
            phase != .searching
        else {
            return
        }

        guard !Task.isCancelled, requestGeneration == generation else { return }
        typingTask?.cancel()

        answer = nil
        displayedAnswerText = ""
        selectedEducationalAssets = []
        isSaved = false
        selectedExcerptText = nil
        selectedExcerptRange = nil
        excerptSaved = false
        inputText = ""

        let questionMessage = AskMessage(role: .user, text: question)
        messages.append(questionMessage)

        phase = .searching
        searchStatusText = "looking through the FruitsofLife.xo library…"

        do {
            let response: AskAnswer

            if let progressive = engine as? any AskResearchProgressServing {
                response = try await progressive.answer(
                    question: question,
                    conversation: messages,
                    trackerContext: nil
                ) { [weak self] progress in
                    guard let self, self.requestGeneration == generation, !Task.isCancelled else { return }
                    switch progress {
                    case .lookingThroughLibrary:
                        self.searchStatusText = "looking through the FruitsofLife.xo library…"
                    case .searchingApprovedSources:
                        self.searchStatusText = "searching sources . . ."
                    case .synthesizing:
                        self.searchStatusText = "putting the evidence together…"
                    case .validating:
                        self.searchStatusText = "checking the answer…"
                    }
                }
            } else {
                response = try await engine.answer(
                    question: question,
                    conversation: messages
                )
            }

            try Task.checkCancellation()
            guard requestGeneration == generation else { return }
            sessionAnswers[questionMessage.id] = response
            answer = response
            messages.append(AskMessage(id: response.id, role: .fruitfolio, text: response.answerText))

            selectedEducationalAssets =
                router.assets(
                    for: response.conceptTags,
                    support: response.support
                )

            phase = .answering

            if reduceMotion {
                displayedAnswerText =
                    response.answerText

                phase = .ready
            } else {
                beginTypewriter(
                    text: response.answerText
                )
            }
        } catch {
            guard !Task.isCancelled, requestGeneration == generation else { return }
            phase = .failed(
                error.localizedDescription
            )
        }
    }

    func showAll() {
        guard let answer else {
            return
        }

        typingTask?.cancel()

        displayedAnswerText =
            answer.answerText

        phase = .ready
        searchStatusText = "looking through the FruitsofLife.xo library…"
    }


    func resetConversation() {
        cancelOutstandingWork()
        sessionAnswers.removeAll()

        inputText = ""
        answer = nil
        displayedAnswerText = ""
        selectedEducationalAssets = []
        isSaved = false
        selectedExcerptText = nil
        selectedExcerptRange = nil
        excerptSaved = false
        phase = .ready

        messages = [
            AskMessage(
                role: .fruitfolio,
                text: Self.greeting
            )
        ]
    }

    private func beginTypewriter(
        text: String
    ) {
        displayedAnswerText = ""

        let characters = Array(text)

        let delay: UInt64 =
            characters.count > 480
            ? 7_000_000
            : 22_000_000

        typingTask = Task {
            @MainActor [weak self] in

            guard let self else {
                return
            }

            for character in characters {
                if Task.isCancelled {
                    return
                }

                displayedAnswerText.append(
                    character
                )

                try? await Task.sleep(
                    nanoseconds: delay
                )
            }

            if !Task.isCancelled {
                phase = .ready
            }
        }
    }
}
