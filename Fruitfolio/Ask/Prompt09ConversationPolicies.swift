import Foundation

/// Pure scroll policy shared by streaming and new-turn insertion.
enum Prompt09ScrollFollowPolicy {
    static func isNearBottom(bottom: CGFloat, viewportHeight: CGFloat, tolerance: CGFloat = 120) -> Bool {
        bottom.isFinite && viewportHeight.isFinite && viewportHeight > 0 && bottom <= viewportHeight + max(0, tolerance)
    }
}

/// Session-only save badge identity. Equal text at two positions or in two
/// answers is not the same selection. Ranges are UTF-16, matching UITextView.
struct Prompt09ExcerptIdentity: Hashable, Sendable {
    let answerID: UUID
    let location: Int
    let length: Int
    let language: String

    init?(answerID: UUID, renderedRange: NSRange?, language: String = "en") {
        guard let range = renderedRange, range.location != NSNotFound,
              range.location >= 0, range.length > 0 else { return nil }
        self.answerID = answerID
        self.language = language
        location = range.location
        length = range.length
    }
}
