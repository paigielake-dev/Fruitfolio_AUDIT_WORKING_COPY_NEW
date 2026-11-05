import Foundation

/// Uses measured runtime frames in the shared Hub coordinate space. The veil
/// cutout and its border receive the same clipped geometry.
enum Prompt07SpotlightGeometry {
    static func highlight(target: CGRect?, viewport: CGRect, padding: CGFloat = 6) -> CGRect? {
        guard let target,
              [target.minX, target.minY, target.width, target.height,
               viewport.minX, viewport.minY, viewport.width, viewport.height, padding].allSatisfy({ $0.isFinite }),
              target.width > 0, target.height > 0, viewport.width > 0, viewport.height > 0,
              target.intersects(viewport) else { return nil }
        let result = target.insetBy(dx: -max(0, padding), dy: -max(0, padding)).intersection(viewport)
        return result.isNull || result.isEmpty ? nil : result
    }
}
