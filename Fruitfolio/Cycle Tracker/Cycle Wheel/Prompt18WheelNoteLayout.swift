import Foundation

/// Native taped-white ratio, bounded on both axes. Never estimate a square
/// artwork's height from its text or shrink text to make a note fit.
nonisolated enum Prompt18WheelNoteLayout {
    static func frame(in available: CGSize, fraction: Double, idealWidth: Double = 205) -> CGRect {
        let width = available.width.isFinite ? max(0, available.width) : 0
        let height = available.height.isFinite ? max(0, available.height) : 0
        let inset = min(6, width / 2, height / 2)
        let ratio = 499.0 / 497.0
        let noteWidth = max(0, min(idealWidth.isFinite ? max(0, idealWidth) : 205, width - 2 * inset, (height - 2 * inset) / ratio))
        let noteHeight = noteWidth * ratio
        let boundedFraction = fraction.isFinite ? min(1, max(0, fraction)) : 0
        let radians = (-90 + boundedFraction * 360) * Double.pi / 180
        let radius = min(width, height) * 0.26
        let rawX = width / 2 + cos(radians) * radius
        let rawY = height / 2 + sin(radians) * radius
        let x = min(max(rawX - noteWidth / 2, inset), max(inset, width - inset - noteWidth))
        let y = min(max(rawY - noteHeight / 2, inset), max(inset, height - inset - noteHeight))
        return CGRect(x: x, y: y, width: noteWidth, height: noteHeight)
    }
}

/// Connects measured, intrinsically sized phase descriptions to their actual
/// represented wheel interval. No assumed fixed phase durations or text sizes.
nonisolated enum Prompt18WheelAnnotationGeometry {
    struct Arrow: Equatable {
        let tail: CGPoint
        let firstBend: CGPoint
        let secondBend: CGPoint
        let tip: CGPoint
        let left: CGPoint
        let right: CGPoint
    }

    static func ringSide(in size: CGSize) -> CGFloat {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0 else { return 0 }
        return min(min(size.width, size.height) * 0.66, 286)
    }

    static func arrow(callout: CGRect, wheel: CGRect, fraction: Double, above: Bool) -> Arrow? {
        let values = [callout.minX, callout.minY, callout.width, callout.height,
                      wheel.minX, wheel.minY, wheel.width, wheel.height]
        guard values.allSatisfy(\.isFinite), callout.width > 0, callout.height > 0,
              wheel.width > 0, wheel.height > 0, fraction.isFinite, (0...1).contains(fraction) else { return nil }
        let radius = ringSide(in: wheel.size) / 2
        let angle = -Double.pi / 2 + 2 * Double.pi * fraction
        let tip = CGPoint(x: wheel.midX + radius * cos(angle), y: wheel.midY + radius * sin(angle))
        let tail = CGPoint(x: callout.midX, y: above ? callout.maxY + 4 : callout.minY - 4)
        let inset = min(4, wheel.width / 4)
        let routingX = tip.x >= wheel.midX ? wheel.maxX - inset : wheel.minX + inset
        let firstBend = CGPoint(x: routingX, y: tail.y)
        let secondBend = CGPoint(x: routingX, y: tip.y)
        let dx = tip.x - secondBend.x, dy = tip.y - secondBend.y
        let distance = hypot(dx, dy)
        guard distance > 0 else { return nil }
        let head = min(6, distance / 3)
        let ux = dx / distance, uy = dy / distance
        return Arrow(tail: tail, firstBend: firstBend, secondBend: secondBend, tip: tip,
            left: CGPoint(x: tip.x - head * ux - head * 0.55 * uy,
                          y: tip.y - head * uy + head * 0.55 * ux),
            right: CGPoint(x: tip.x - head * ux + head * 0.55 * uy,
                           y: tip.y - head * uy - head * 0.55 * ux))
    }
}
