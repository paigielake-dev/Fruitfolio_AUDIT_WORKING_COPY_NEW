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
