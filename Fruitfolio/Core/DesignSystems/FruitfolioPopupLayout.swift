import Foundation

/// Geometry shared by popup families. Pixel dimensions come from the bundled
/// artwork; normalized writing areas deliberately exclude painted edges.
/// Content scrolls within that area instead of stretching watercolor artwork.
enum FruitfolioPopupLayout {
    enum CharacterArtwork: CaseIterable {
        case strawberry, blueberry, peach

        var pixelSize: CGSize {
            switch self {
            case .strawberry: return CGSize(width: 280, height: 193)
            case .blueberry: return CGSize(width: 1353, height: 1163)
            case .peach: return CGSize(width: 247, height: 207)
            }
        }

        /// Bundled PNG painted bounds at alpha > 12/255 (faint export noise excluded).
        var paintedBounds: CGRect {
            switch self {
            case .strawberry: return CGRect(x: 59, y: 9, width: 151, height: 168)
            case .blueberry: return CGRect(x: 167, y: 25, width: 1002, height: 1032)
            case .peach: return CGRect(x: 41, y: 16, width: 173, height: 168)
            }
        }

        func opticalOffset(boxSide: CGFloat) -> CGSize {
            guard boxSide.isFinite, boxSide > 0 else { return .zero }
            let scale = min(boxSide / pixelSize.width, boxSide / pixelSize.height)
            return CGSize(width: (pixelSize.width / 2 - paintedBounds.midX) * scale,
                          height: (pixelSize.height / 2 - paintedBounds.midY) * scale)
        }
    }

    struct DialogueMetrics {
        let characterWidth: CGFloat
        let bubbleWidth: CGFloat
        let spacing: CGFloat
        var totalWidth: CGFloat { characterWidth + bubbleWidth + spacing }
    }

    static let speechBubblePixelSize = CGSize(width: 497, height: 499)

    static func dialogue(availableWidth: CGFloat, availableHeight: CGFloat = .greatestFiniteMagnitude, messageCount: Int,
                         maximumBubbleWidth: CGFloat = 246, maximumCharacterWidth: CGFloat = 72) -> DialogueMetrics {
        guard availableWidth.isFinite, availableWidth > 0, availableHeight.isFinite, availableHeight > 0, maximumBubbleWidth.isFinite,
              maximumCharacterWidth.isFinite, maximumBubbleWidth > 0, maximumCharacterWidth >= 0 else {
            return DialogueMetrics(characterWidth: 0, bubbleWidth: 0, spacing: 0)
        }
        let character = min(maximumCharacterWidth, availableWidth * 0.18, availableHeight)
        let spacing = -min(14, character * 0.20)
        let bonus: CGFloat = messageCount <= 58 ? 0 : (messageCount <= 105 ? 18 : 30)
        let desired = max(availableWidth * 0.58, 184) + bonus
        let bubble = min(desired, maximumBubbleWidth, max(0, availableWidth - character - spacing),
                         availableHeight * speechBubblePixelSize.width / speechBubblePixelSize.height)
        return DialogueMetrics(characterWidth: character, bubbleWidth: bubble, spacing: spacing)
    }

    struct Metrics: Equatable {
        let paperSize: CGSize
        let writingSize: CGSize
    }

    static let notebookPixelSize = CGSize(width: 684, height: 564)

    static let saveCardPixelSize = CGSize(width: 634, height: 667)

    static func notebook(available: CGSize) -> Metrics {
        artwork(available: available, pixels: notebookPixelSize, maximumWidth: 340,
                writingFraction: CGSize(width: 0.80, height: 0.72))
    }

    static func saveConfirmation(available: CGSize) -> Metrics {
        artwork(available: available, pixels: saveCardPixelSize, maximumWidth: 240,
                writingFraction: CGSize(width: 0.78, height: 0.72))
    }

    private static func artwork(available: CGSize, pixels: CGSize, maximumWidth: CGFloat,
                                writingFraction: CGSize) -> Metrics {
        guard available.width.isFinite, available.height.isFinite,
              available.width > 0, available.height > 0 else {
            return Metrics(paperSize: .zero, writingSize: .zero)
        }
        let widthLimit = max(0, min(maximumWidth, available.width - 32))
        let heightLimit = max(0, available.height - 32)
        let width = min(widthLimit, heightLimit * pixels.width / pixels.height)
        let paper = CGSize(width: width, height: width * pixels.height / pixels.width)
        return Metrics(paperSize: paper,
                       writingSize: CGSize(width: paper.width * writingFraction.width, height: paper.height * writingFraction.height))
    }
}
