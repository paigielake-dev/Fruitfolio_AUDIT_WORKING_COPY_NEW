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

    static func notebook(available: CGSize) -> Metrics {
        guard available.width.isFinite, available.height.isFinite,
              available.width > 0, available.height > 0 else {
            return Metrics(paperSize: .zero, writingSize: .zero)
        }
        let widthLimit = max(0, min(340, available.width - 32))
        let heightLimit = max(0, available.height - 32)
        let width = min(widthLimit, heightLimit * notebookPixelSize.width / notebookPixelSize.height)
        let paper = CGSize(width: width, height: width * notebookPixelSize.height / notebookPixelSize.width)
        return Metrics(paperSize: paper,
                       writingSize: CGSize(width: paper.width * 0.80, height: paper.height * 0.72))
    }
}
