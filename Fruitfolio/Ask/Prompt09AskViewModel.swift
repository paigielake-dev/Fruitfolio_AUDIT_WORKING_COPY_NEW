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

    static let greeting = Prompt09ControlledCopy.greeting
    static let sourcesHeading = "sources ˚ ☆ ‧ ₊"
    static let educationDisclaimer = Prompt09ControlledCopy.educationDisclaimer

    static let suggestedQuestions = [
        "why does cervical mucus change?",
        "what happens during ovulation?",
        "why do breasts feel sore before a period?",
        "what does progesterone do?",
        "what happens after fertilization?"
    ]

    @Published var inputText = ""
    @Published private(set) var hasUserContextInFlight = false
    @Published private(set) var messages: [AskMessage]
    @Published private(set) var answer: AskAnswer?
    @Published private(set) var answerHistory: [AskAnswer] = []
    @Published private(set) var phase: Phase = .ready
    @Published private(set) var searchStatusText = "looking through the FruitsofLife.xo library…"
    @Published private(set) var displayedAnswerText = ""
    @Published private(set) var displayedSemanticSpans: [FruitfolioSemanticSpan] = []
    @Published private(set) var availableEducationalAssets: [EducationalAssetDescriptor] = []
    @Published private(set) var selectedEducationalAssets: [EducationalAssetDescriptor] = []
    @Published var isSaved = false
    @Published var selectedExcerptText: String?
    @Published var selectedExcerptRange: NSRange?
    @Published var selectedExcerptSemanticSpans: [FruitfolioSemanticSpan]?
    @Published var selectedExcerptLanguage: String?
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

    #if DEBUG
    /// Deterministic presentation fixture; no inference or user records written.
    static func paperRegressionFixture(illustrationOption: Bool = false) -> Prompt09AskViewModel {
        let model = Prompt09AskViewModel()
        let body = String(repeating: "UI regression paragraph. **Formatting** and long wrapped text remain inside the same paper. This is a layout fixture, not research or health guidance.\n\n", count: 12)
        let first = AskAnswer(originalQuestion: "First regression question", answerText: body,
                              support: .supported, knowledgeBaseVersion: "ui-fixture", isDevelopmentPreview: true)
        let second = AskAnswer(originalQuestion: "Second regression question", answerText: body,
                               support: .supported, knowledgeBaseVersion: "ui-fixture",
                               conceptTags: illustrationOption ? ["ovulation", "follicle"] : [], isDevelopmentPreview: true)
        model.messages = [AskMessage(role: .user, text: first.originalQuestion),
                          AskMessage(id: first.id, role: .fruitfolio, text: first.answerText),
                          AskMessage(role: .user, text: second.originalQuestion),
                          AskMessage(id: second.id, role: .fruitfolio, text: second.answerText)]
        model.answerHistory = [first, second]
        model.answer = second
        if illustrationOption {
            model.availableEducationalAssets = model.router.assets(for: second.conceptTags, support: second.support, maximumCount: 1)
        }
        model.displayedAnswerText = second.answerText
        model.displayedSemanticSpans = FruitfolioSemanticDocument.spans(from: second.answerText)
        return model
    }
    #endif

    deinit {
        typingTask?.cancel()
        requestTask?.cancel()
    }

    func cancelOutstandingWork() {
        hasUserContextInFlight = false
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

    /// Preserve a newer unsent draft; restore the interrupted question only if
    /// its submission cleared the field. Late provider callbacks stay rejected.
    func suspendForInactivity() {
        if phase == .searching, inputText.isEmpty {
            inputText = messages.last(where: { $0.role == .user })?.text ?? ""
        }
        cancelOutstandingWork()
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
        reduceMotion: Bool,
        userContext: FruitfolioAskUserContext? = nil
    ) async {
        requestTask?.cancel()
        let generation = UUID()
        requestGeneration = generation
        hasUserContextInFlight = userContext != nil
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performSubmitCurrentQuestion(reduceMotion: reduceMotion, generation: generation, userContext: userContext)
        }
        requestTask = task
        await withTaskCancellationHandler {
            await task.value
        } onCancel: {
            task.cancel()
        }
        if requestGeneration == generation {
            requestTask = nil
            hasUserContextInFlight = false
        }
    }

    private func performSubmitCurrentQuestion(
        reduceMotion: Bool,
        generation: UUID,
        userContext: FruitfolioAskUserContext?
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
        hasUserContextInFlight = userContext != nil
        defer { if requestGeneration == generation { hasUserContextInFlight = false } }

        answer = nil
        displayedAnswerText = ""
        displayedSemanticSpans = []
        selectedEducationalAssets = []
        availableEducationalAssets = []
        isSaved = false
        selectedExcerptText = nil
        selectedExcerptRange = nil
        selectedExcerptSemanticSpans = nil
        selectedExcerptLanguage = nil
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

            let progressHandler: @MainActor @Sendable (FruitfolioResearchProgress) -> Void = { [weak self] progress in
                guard let self, !Task.isCancelled, self.requestGeneration == generation else { return }
                switch progress {
                case .lookingThroughLibrary: self.searchStatusText = "looking through the FruitsofLife.xo library…"
                case .searchingApprovedSources: self.searchStatusText = "searching sources . . ."
                case .synthesizing: self.searchStatusText = "putting the evidence together…"
                case .validating: self.searchStatusText = "checking the answer…"
                }
            }
            if let contextual = engine as? any AskContextualResearchServing {
                response = try await contextual.answer(question: question, conversation: messages,
                    trackerContext: nil, userContext: userContext, progress: progressHandler)
            } else if userContext != nil {
                // Never pretend an attached record reached an unsupported engine.
                throw AskEngineError.knowledgeProviderUnavailable
            } else if let progressive = engine as? any AskResearchProgressServing {
                response = try await progressive.answer(question: question, conversation: messages,
                    trackerContext: nil, progress: progressHandler)
            } else {
                response = try await engine.answer(question: question, conversation: messages)
            }

            try Task.checkCancellation()
            guard requestGeneration == generation else { return }
            answer = response
            answerHistory.append(response)
            messages.append(AskMessage(id: response.id, role: .fruitfolio, text: response.answerText))

            availableEducationalAssets =
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

    /// An explicit educational action, never decoration selected from raw prose.
    func revealEducationalIllustration() {
        guard phase == .ready, answer?.support == .supported else { return }
        selectedEducationalAssets = Array(availableEducationalAssets.prefix(1))
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
        availableEducationalAssets = []
        isSaved = false
        selectedExcerptText = nil
        selectedExcerptRange = nil
        selectedExcerptSemanticSpans = nil
        selectedExcerptLanguage = nil
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
            for count in stride(from: step, through: total + step - 1, by: step) {
                guard !Task.isCancelled else { return }
                // End strong ownership before suspending between publications.
                do {
                    guard let self else { return }
                    self.displayedSemanticSpans = FruitfolioSemanticSlices.prefix(spans, characterCount: min(count, total))
                    self.displayedAnswerText = self.displayedSemanticSpans.map(\.text).joined()
                }
                do { try await Task.sleep(nanoseconds: delay) }
                catch { return }
            }
            guard let self, !Task.isCancelled else { return }
            // Completed native selection surfaces parse the original full markup.
            self.displayedAnswerText = text
            self.displayedSemanticSpans = spans
            self.phase = .ready
            self.typingTask = nil
        }
    }
}
