import Foundation

/// Pure scroll policy shared by streaming and new-turn insertion.
enum Prompt09ScrollFollowPolicy {
    static func isNearBottom(bottom: CGFloat, viewportHeight: CGFloat, tolerance: CGFloat = 120) -> Bool {
        bottom.isFinite && viewportHeight.isFinite && viewportHeight > 0 && bottom <= viewportHeight + max(0, tolerance)
    }
}

/// Measured content and viewport-relative bottom belong to one layout pass.
struct Prompt09ConversationScrollMetrics: Equatable {
    let bottom: CGFloat
    let contentHeight: CGFloat
}

/// Content growth is not a user scrolling away. Retain follow intent while
/// the content offset is unchanged, even when one large streamed batch moves
/// the new bottom beyond the proximity tolerance.
struct Prompt09ScrollFollowSession {
    private(set) var shouldFollow = true
    private var previousOffset: CGFloat?
    private var previousContentHeight: CGFloat?

    mutating func observe(_ metrics: Prompt09ConversationScrollMetrics,
                          viewportHeight: CGFloat, permitted: Bool) -> Bool {
        guard metrics.bottom.isFinite, metrics.contentHeight.isFinite,
              metrics.contentHeight > 0, viewportHeight.isFinite, viewportHeight > 0 else { return false }
        let offset = metrics.contentHeight - metrics.bottom
        let near = Prompt09ScrollFollowPolicy.isNearBottom(bottom: metrics.bottom, viewportHeight: viewportHeight)
        if let previousOffset {
            // UIScrollView offsets can advance by fractions of a point.
            if abs(offset - previousOffset) > 0.01 { shouldFollow = near }
            else if near { shouldFollow = true }
        } else { shouldFollow = near }
        let grew = previousContentHeight.map { metrics.contentHeight > $0 + 0.5 } ?? false
        previousOffset = offset
        previousContentHeight = metrics.contentHeight
        return permitted && shouldFollow && grew
    }
}

/// Session-only save badge identity. Equal text at two positions or in two
/// answers is not the same selection. Ranges are UTF-16, matching UITextView.
struct Prompt09ExcerptIdentity: Hashable, Sendable {
    let answerID: UUID
    let location: Int
    let length: Int
    let language: String
    let selectionText: String
    let educationalAssetIDs: [FruitfolioAssetID]

    init?(answerID: UUID, renderedRange: NSRange?, language: String = "en", selectionText: String = "", educationalAssetIDs: [FruitfolioAssetID] = []) {
        guard let range = renderedRange, range.location != NSNotFound,
              range.location >= 0, range.length > 0 else { return nil }
        self.answerID = answerID
        self.language = language
        self.educationalAssetIDs = educationalAssetIDs
        self.selectionText = selectionText
        location = range.location
        length = range.length
    }
}

/// One centered paper/text column for the complete active session. The extended
/// background continues below the scrollable content so its bottom edge cannot
/// be revealed by reaching the end of an answer.
enum Prompt09PaperLayout {
    static let paperPixels = CGSize(width: 851, height: 1317)
    static let bottomOverflow: CGFloat = 128
    struct Metrics {
        let paperWidth: CGFloat
        let textColumnWidth: CGFloat
        let imageScale: CGFloat
        let sourceHeight: CGFloat
    }
    static func metrics(viewport: CGSize) -> Metrics {
        guard viewport.width.isFinite, viewport.height.isFinite,
              viewport.width > 16, viewport.height > 0 else {
            return Metrics(paperWidth: 0, textColumnWidth: 0, imageScale: 0, sourceHeight: 1317)
        }
        let width = min(680, viewport.width - 16)
        let scale = width / paperPixels.width
        let inset = min(32, max(16, width * 0.07))
        return Metrics(paperWidth: width, textColumnWidth: max(0, width - inset * 2),
                       imageScale: scale, sourceHeight: max(paperPixels.height, (viewport.height + bottomOverflow) / scale))
    }
}

enum Prompt09OpeningFruitArtwork: String, CaseIterable {
    case pear = "decor_pear"
    case orangeSlice = "decor_orange_slice"
    case orangeGlow = "decor_orange_glow"

    var pixels: CGSize {
        switch self {
        case .pear: return CGSize(width: 399, height: 481)
        case .orangeSlice: return CGSize(width: 523, height: 402)
        case .orangeGlow: return CGSize(width: 413, height: 386)
        }
    }
    /// Visible alpha > 12/255, excluding faint export noise.
    var paintedBounds: CGRect {
        switch self {
        case .pear: return CGRect(x: 0, y: 0, width: 351, height: 454)
        case .orangeSlice: return CGRect(x: 49, y: 8, width: 440, height: 367)
        case .orangeGlow: return CGRect(x: 1, y: 9, width: 361, height: 371)
        }
    }
    func opticalOffset(box: CGSize) -> CGSize {
        guard box.width.isFinite, box.height.isFinite, box.width > 0, box.height > 0 else { return .zero }
        let scale = min(box.width / pixels.width, box.height / pixels.height)
        return CGSize(width: (pixels.width / 2 - paintedBounds.midX) * scale,
                      height: (pixels.height / 2 - paintedBounds.midY) * scale)
    }
}

/// A queued send belongs to one visible, active presentation epoch. Repeated
/// active notifications preserve a live ticket; inactivity/remount invalidates it.
struct Prompt09RequestInteraction: Sendable {
    private(set) var isVisible = false
    private(set) var isActive = false
    private var generation = UUID()
    var ticket: UUID? { isVisible && isActive ? generation : nil }
    mutating func appear(active: Bool) {
        generation = UUID(); isVisible = true; isActive = active
    }
    mutating func setActive(_ active: Bool) {
        if isActive != active { generation = UUID() }
        isActive = active
    }
    mutating func disappear() {
        generation = UUID(); isVisible = false; isActive = false
    }
    func accepts(_ ticket: UUID) -> Bool {
        isVisible && isActive && generation == ticket
    }
}

/// Captured when an answer's controls render, checked again when they act.
/// A callback cannot move an old answer into a new conversation/language epoch.
struct Prompt09AnswerActionOwner: Sendable {
    let conversationID: UUID
    let answerID: UUID
    let language: FruitfolioLanguage
    func accepts(answer: AskAnswer, conversationID: UUID, language: FruitfolioLanguage,
                 history: [AskAnswer], isActive: Bool) -> Bool {
        guard isActive, self.conversationID == conversationID, self.language == language,
              answerID == answer.id else { return false }
        let matches = history.filter { $0.id == answerID }
        return matches.count == 1 && matches[0] == answer
    }
}
