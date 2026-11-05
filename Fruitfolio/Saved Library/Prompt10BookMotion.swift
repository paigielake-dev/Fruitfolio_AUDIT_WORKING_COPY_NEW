import Foundation

/// Shared continuous values; interrupted transitions never select another book.
nonisolated enum Prompt10BookMotion {
    static func unit(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0 }
    static func lerp(_ start: Double, _ end: Double, progress: Double) -> Double {
        start + (end - start) * unit(progress)
    }
    static func finalFrame(in viewport: CGSize) -> CGRect {
        let width = max(1, viewport.width.isFinite ? viewport.width : 1)
        let height = max(1, viewport.height.isFinite ? viewport.height : 1)
        let inset = min(16.0, width * 0.04)
        return CGRect(x: inset, y: min(24, height * 0.04), width: max(1, width - 2 * inset), height: max(1, height - min(48, height * 0.08)))
    }
    static func frame(from origin: CGRect, in viewport: CGSize, progress: Double) -> CGRect {
        let final = finalFrame(in: viewport)
        let width = min(final.width, 360)
        let height = min(final.height, 300)
        let centered = CGRect(x: final.midX - width / 2, y: final.midY - height / 2, width: width, height: height)
        let p = unit(progress)
        return p <= 0.5 ? frame(from: origin, to: centered, progress: p * 2)
                        : frame(from: centered, to: final, progress: (p - 0.5) * 2)
    }
    static func frame(from origin: CGRect, to destination: CGRect, progress: Double) -> CGRect {
        CGRect(x: lerp(origin.minX, destination.minX, progress: progress),
               y: lerp(origin.minY, destination.minY, progress: progress),
               width: max(1, lerp(origin.width, destination.width, progress: progress)),
               height: max(1, lerp(origin.height, destination.height, progress: progress)))
    }
}
