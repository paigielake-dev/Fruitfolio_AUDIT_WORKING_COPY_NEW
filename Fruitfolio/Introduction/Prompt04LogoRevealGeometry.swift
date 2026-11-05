import Foundation

/// Registration is expressed in the original 644x795 branded-cover canvas.
/// The center of its logo/wordmark region stays fixed while pigment spreads;
/// this does not resize, crop or replace either founder-painted book asset.
enum Prompt04LogoRevealGeometry {
    static let brandedPixelSize = CGSize(width: 644, height: 795)
    static let logoCenterInPixels = CGPoint(x: 335, y: 321)

    struct Metrics {
        let center: CGPoint
        let diameter: CGFloat
        let progress: CGFloat
        let finalCoverage: Double
    }

    static func metrics(size: CGSize, progress: CGFloat) -> Metrics {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else {
            return Metrics(center: .zero, diameter: 0, progress: 0, finalCoverage: 0)
        }
        let p = progress.isFinite ? min(1, max(0, progress)) : 0
        let center = CGPoint(x: size.width * logoCenterInPixels.x / brandedPixelSize.width,
                             y: size.height * logoCenterInPixels.y / brandedPixelSize.height)
        let farX = max(center.x, size.width - center.x)
        let farY = max(center.y, size.height - center.y)
        let distance = hypot(farX, farY)
        let diameter = (size.width * 0.025) + distance * 5 * p
        let finish = min(1, max(0, (p - 0.78) / 0.22))
        let smoothFinish = finish * finish * (3 - 2 * finish)
        return Metrics(center: center, diameter: diameter, progress: p, finalCoverage: Double(smoothFinish))
    }
}
