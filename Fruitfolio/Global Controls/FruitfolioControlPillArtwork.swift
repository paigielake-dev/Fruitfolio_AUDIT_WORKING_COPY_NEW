import SwiftUI
import UIKit

/// Uses the founder's actual PNG. Only straight middle sections expand; the
/// prepared image retains the original aspect ratio and painted end contours.
@MainActor
enum FruitfolioControlArtwork {
    private static let cache: NSCache<NSString, UIImage> = {
        let value = NSCache<NSString, UIImage>()
        value.totalCostLimit = 8 * 1024 * 1024
        value.countLimit = 16
        return value
    }()

    static func pill(width: CGFloat, displayScale: CGFloat) -> UIImage? {
        guard width.isFinite, width > 0, displayScale.isFinite, displayScale > 0 else { return nil }
        let key = "pill-\(width)-\(displayScale)" as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let original = try? FruitfolioAssetLoader.uiImage(.control_pill_outline) else { return nil }
        let size = CGSize(width: width, height: width * original.size.height / original.size.width)
        let format = UIGraphicsImageRendererFormat()
        format.scale = displayScale
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            original.draw(in: CGRect(origin: .zero, size: size))
        }
        cache.setObject(image, forKey: key, cost: Int(size.width * size.height * displayScale * displayScale * 4))
        return image
    }
}

struct FruitfolioControlPillArtwork: View {
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        GeometryReader { geometry in
            if let image = FruitfolioControlArtwork.pill(width: geometry.size.width, displayScale: displayScale) {
                Image(uiImage: image)
                    .resizable(capInsets: EdgeInsets(
                        top: image.size.height * 0.40, leading: image.size.height * 0.48,
                        bottom: image.size.height * 0.40, trailing: image.size.height * 0.48
                    ), resizingMode: .stretch)
            } else {
                // Same registered original; asset loader exposes missing resources.
                FruitfolioImage(id: .control_pill_outline).scaledToFit()
            }
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
