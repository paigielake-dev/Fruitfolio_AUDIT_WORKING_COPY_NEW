import Foundation

struct Prompt10PendingSavedContent: Equatable {
    let question: String
    let answer: String
    let saveType: Prompt10SavedPageType
    let excerptText: String?
    let selectedRenderedRange: NSRange?
    let selectedDisplayLanguage: String
    let selectedSemanticSpans: [FruitfolioSemanticSpan]?

    let originalAnswerID: String?
    let originalConversationID: String?

    let sourceIDs: [String]
    let educationalAssetIDs: [FruitfolioAssetID]?
    let sourceRecords: [AskSourceRecord]?
    let sourceVersions: [String: String]
    let knowledgeBaseVersion: String?
    let generationTimestamp: Date?
    let evidenceSupport: Prompt09SavedAnswerSupport?

    init(
        question: String,
        answer: String,
        saveType: Prompt10SavedPageType,
        excerptText: String? = nil,
        originalAnswerID: String? = nil,
        originalConversationID: String? = nil,
        sourceIDs: [String] = [],
        sourceVersions: [String: String] = [:],
        knowledgeBaseVersion: String? = nil,
        generationTimestamp: Date? = nil,
        selectedRenderedRange: NSRange? = nil,
        selectedDisplayLanguage: String = "en",
        selectedSemanticSpans: [FruitfolioSemanticSpan]? = nil,
        sourceRecords: [AskSourceRecord]? = nil,
        educationalAssetIDs: [FruitfolioAssetID]? = nil,
        evidenceSupport: Prompt09SavedAnswerSupport? = nil
    ) {
        self.question = question
        // Only the selected save payload may outlive the active Ask session.
        self.answer = saveType == .excerpt ? (excerptText ?? "") : answer
        self.saveType = saveType
        self.excerptText = excerptText
        self.selectedRenderedRange = selectedRenderedRange
        self.selectedDisplayLanguage = selectedDisplayLanguage
        self.selectedSemanticSpans = selectedSemanticSpans
        self.originalAnswerID = originalAnswerID
        self.originalConversationID = originalConversationID
        self.sourceIDs = sourceIDs
        self.educationalAssetIDs = educationalAssetIDs
        self.sourceRecords = sourceRecords
        self.sourceVersions = sourceVersions
        self.knowledgeBaseVersion = knowledgeBaseVersion
        self.generationTimestamp = generationTimestamp
        self.evidenceSupport = evidenceSupport?.restricted(to: saveType)
    }
}

