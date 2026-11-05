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
    @Published private(set) var answerHistory: [AskAnswer] = []
    @Published private(set) var phase: Phase = .ready
    @Published private(set) var searchStatusText = "looking through the FruitsofLife.xo library…"
    @Published private(set) var displayedAnswerText = ""
    @Published private(set) var displayedSemanticSpans: [FruitfolioSemanticSpan] = []
    @Published private(set) var selectedEducationalAssets: [EducationalAssetDescriptor] = []
    @Published var isSaved = false
    @Published var selectedExcerptText: String?
    @Published var selectedExcerptRange: NSRange?
    @Published private(set) var excerptSaved = false

    private(set) var conversationID: UUID

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
        if phase == .answering, let answer {
            displayedAnswerText = answer.answerText
            displayedSemanticSpans = FruitfolioSemanticDocument.spans(from: answer.answerText)
        }
        if phase == .searching || phase == .answering { phase = .ready }
    }

    var canSend: Bool {
        !inputText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
            && phase != .searching
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
        displayedSemanticSpans = []
        selectedEducationalAssets = []
        isSaved = false
        selectedExcerptText = nil
        selectedExcerptRange = nil
        excerptSaved = false
        inputText = ""

        messages.append(
            AskMessage(
                role: .user,
                text: question
            )
        )

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
                    guard let self, !Task.isCancelled,
                          self.requestGeneration == generation else { return }
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
            answer = response
            answerHistory.append(response)
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
            guard requestGeneration == generation else { return }
            if Task.isCancelled || error is CancellationError {
                phase = .ready
                return
            }
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
        conversationID = UUID()
        answerHistory = []

        inputText = ""
        answer = nil
        displayedAnswerText = ""
        displayedSemanticSpans = []
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

    private func beginTypewriter(text: String) {
        displayedAnswerText = ""
        displayedSemanticSpans = []
        let spans = FruitfolioSemanticDocument.spans(from: text)
        let total = spans.reduce(0) { $0 + $1.text.count }
        guard total > 0 else { phase = .ready; return }
        // Keep the existing long-answer speed while batching publications below
        // display refresh rate. Parse once, then reveal semantic span prefixes.
        let step = total > 480 ? 3 : 1
        let delay: UInt64 = total > 480 ? 21_000_000 : 22_000_000
        typingTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for count in stride(from: step, through: total + step - 1, by: step) {
                guard !Task.isCancelled else { return }
                displayedSemanticSpans = FruitfolioSemanticSlices.prefix(spans, characterCount: min(count, total))
                displayedAnswerText = displayedSemanticSpans.map(\.text).joined()
                do { try await Task.sleep(nanoseconds: delay) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            // Completed native selection surfaces parse the original full markup.
            displayedAnswerText = text
            displayedSemanticSpans = spans
            phase = .ready
        }
    }
}
