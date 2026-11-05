import Foundation

/// Geometry shared by popup families. Pixel dimensions come from the bundled
/// artwork; normalized writing areas deliberately exclude painted edges.
/// Content scrolls within that area instead of stretching watercolor artwork.
enum FruitfolioPopupLayout {
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
