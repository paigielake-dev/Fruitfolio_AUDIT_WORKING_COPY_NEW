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

/// Read-only split of the known exact-excerpt template. The literal cloze and
/// answer words must stay in their source language for exact-word matching.
nonisolated struct Prompt28ExcerptQuestionPresentation: Equatable, Sendable {
    static let category = "source-excerpt practice"
    static let instructionSource = "which word completes this exact library excerpt?"
    static let noticeSource = "this exact excerpt and its answer choices stay in the source language."
    static let readingAidNoticeSource = "this is a reading aid. use the original excerpt and original answer choices to answer the practice question."
    static let citationNoticeSource = "exact-excerpt practice; vocabulary difficulty is separate from catching level. source citations reflect the founder library attribution, not independent clinical review."
    static let prefix = instructionSource + "\n\n"
    let literalExcerpt: String
    let readingAidProtectedLiterals: [String]

    init?(question: Prompt28Question) {
        guard question.category == Self.category,
              question.questionText.utf8.starts(with: Self.prefix.utf8) else { return nil }
        let bytes = question.questionText.utf8.dropFirst(Self.prefix.utf8.count)
        guard !bytes.isEmpty else { return nil }
        literalExcerpt = String(decoding: bytes, as: UTF8.self)
        // Absent answer literals are protected too: inference must not insert
        // an omitted answer or a distractor into the translated reading aid.
        var seen: Set<String> = []
        readingAidProtectedLiterals = (["[blank]"] + question.answerOptions.map(\.text) + question.sourceIDs)
            .filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}
