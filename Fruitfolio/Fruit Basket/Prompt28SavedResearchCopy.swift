import Foundation

/// A user saves the sourced lesson, not game counts attributed as medical facts.
/// Original per-source versions take precedence over the package-wide version.
nonisolated enum Prompt28SavedResearchCopy {
    static func pending(question: Prompt28Question) -> Prompt10PendingSavedContent? {
        guard question.isPlayable else { return nil }
        let versions = Dictionary(uniqueKeysWithValues: question.sourceIDs.map { id in
            (id, question.sourceRecords?.first(where: { $0.id == id })?.contentVersion ?? question.contentVersion)
        })
        return Prompt10PendingSavedContent(question: question.questionText, answer: question.explanation,
            saveType: .fullAnswer, originalAnswerID: "fruitbasket:" + question.id,
            sourceIDs: question.sourceIDs, sourceVersions: versions,
            knowledgeBaseVersion: question.contentVersion, generationTimestamp: question.createdAt,
            sourceRecords: question.sourceRecords)
    }
}
