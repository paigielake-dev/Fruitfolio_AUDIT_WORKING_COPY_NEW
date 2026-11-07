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


/// The same immutable payload-to-page conversion is used by the native dialog
/// and Foundation regression tests; it never chooses or writes a destination.
extension Prompt10PendingSavedContent {
    func makeSavedPage(chapterID: UUID) -> Prompt10SavedPage {
        Prompt10SavedPage(chapterID: chapterID, question: question, answer: answer, saveType: saveType,
            excerptText: excerptText, originalAnswerID: originalAnswerID, originalConversationID: originalConversationID,
            sourceIDs: sourceIDs, sourceVersions: sourceVersions, knowledgeBaseVersion: knowledgeBaseVersion,
            generationTimestamp: generationTimestamp, excerptSemanticSpans: selectedSemanticSpans,
            excerptSelectionLocation: selectedRenderedRange?.location, excerptSelectionLength: selectedRenderedRange?.length,
            excerptLanguage: saveType == .excerpt ? selectedDisplayLanguage : nil,
            sourceRecords: sourceRecords, educationalAssetIDs: educationalAssetIDs, evidenceSupport: evidenceSupport)
    }
}
