import Foundation

/// Active-visit UI state only. Neither selections nor successful-save badges
/// create a second persisted conversation or modify a source answer.
nonisolated struct AskExcerptIdentity: Hashable, Sendable {
    let answerID: UUID
    let range: NSRange
    let text: String
}

nonisolated struct AskExcerptSelection: Equatable, Sendable {
    var text: String?
    var range: NSRange?

    func validated(for answer: AskAnswer) -> (identity: AskExcerptIdentity, document: FruitfolioSemanticDocument)? {
        guard let text, !text.isEmpty, let range,
              let document = answer.resolvedSemanticDocument.slice(utf16Range: range),
              document.plainText.utf8.elementsEqual(text.utf8) else { return nil }
        return (.init(answerID: answer.id, range: range, text: text), document)
    }
}
