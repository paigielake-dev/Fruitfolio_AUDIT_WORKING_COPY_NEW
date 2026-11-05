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
