import SwiftUI

/// One continuously deforming book. Original book PNGs remain visual references
/// and shelf artwork; no opening/closed/front image is swapped by this renderer.
struct Prompt10CodedBookArtwork: View, Animatable {
    let style: Prompt10BookStyle
    var openness: CGFloat

    var animatableData: CGFloat {
        get { openness }
        set { openness = newValue }
    }

    var body: some View {
        let coverColor = style.openingTint
        Canvas { context, size in
            guard size.width > 0, size.height > 0 else { return }
            let p = openness.isFinite ? min(1, max(0, openness)) : 0
            let middle = size.width * 0.5
            let half = size.width * (0.17 + 0.30 * p)
            let top = size.height * (0.025 + 0.065 * p)
            let bottom = size.height * (0.965 - 0.035 * p)
            let spine = size.width * (0.085 - 0.07 * p)
            let cover = CGRect(x: middle - half, y: top, width: half * 2, height: bottom - top)
            let coverPath = Path(roundedRect: cover, cornerSize: CGSize(width: min(size.width, size.height) * 0.025, height: min(size.width, size.height) * 0.025))
            context.fill(coverPath, with: .color(coverColor))
            context.stroke(coverPath, with: .color(coverColor.opacity(0.7)), lineWidth: 2)
            let spineLabel = Path(roundedRect: cover.insetBy(dx: cover.width * 0.16, dy: cover.height * 0.07), cornerSize: CGSize(width: 1, height: 1))
            context.stroke(spineLabel, with: .color(Color.white.opacity(Double(0.65 * (1 - p)))), lineWidth: 1)


            // Layered curved leaves retain the reference's cream paper, raised
            // inner gutter and softly uneven outer edges at every open fraction.
            for layer in (0..<5).reversed() {
                let inset = CGFloat(layer) * size.height * 0.007
                for side in [CGFloat(-1), CGFloat(1)] {
                    let outer = middle + side * (half - size.width * 0.012 - inset * 0.35)
                    let inner = middle + side * spine
                    let shoulder = top + size.height * (0.025 + 0.055 * p) + inset
                    var page = Path()
                    page.move(to: CGPoint(x: inner, y: shoulder + size.height * 0.045 * p))
                    page.addQuadCurve(to: CGPoint(x: outer, y: shoulder),
                        control: CGPoint(x: (inner + outer) / 2, y: top - size.height * 0.025 * p + inset))
                    page.addLine(to: CGPoint(x: outer + side * size.width * 0.012 * p,
                        y: bottom - size.height * 0.035 - inset))
                    page.addQuadCurve(to: CGPoint(x: inner, y: bottom - size.height * 0.025),
                        control: CGPoint(x: (inner + outer) / 2, y: bottom - size.height * 0.095 * p - inset))
                    page.closeSubpath()
                    context.fill(page, with: .color(Color(red: 0.98 - Double(layer) * 0.012,
                        green: 0.95 - Double(layer) * 0.017, blue: 0.87 - Double(layer) * 0.024).opacity(Double(p))))
                    context.stroke(page, with: .color(Color.brown.opacity(Double(p) * 0.12)), lineWidth: 0.65)
                }
            }
            // Deterministic coded washes; no generated replacement asset or
            // user content is embedded in this decorative rendering.
            if p > 0 {
                for index in 0..<44 {
                    let x = cover.minX + cover.width * CGFloat((index * 37 % 97) + 1) / 99
                    let y = top + cover.height * CGFloat((index * 23 % 83) + 5) / 94
                    let width = size.width * CGFloat(3 + index % 5) / 70
                    let wash = Path(ellipseIn: CGRect(x: x, y: y, width: width, height: width * 0.65))
                    context.fill(wash, with: .color(Color.brown.opacity(0.012 * Double(p))))
                }
            }
            let gutter = Path(roundedRect: CGRect(x: middle - spine * 0.35,
                y: top + size.height * 0.06, width: spine * 0.7,
                height: cover.height - size.height * 0.07), cornerSize: CGSize(width: 2, height: 2))
            context.fill(gutter, with: .color(coverColor.opacity(Double(0.7 - 0.45 * p))))
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

struct Prompt10BookFramePreference: PreferenceKey {
    static let defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, newest in newest })
    }
}

extension View {
    func prompt10BookFrame(_ key: String) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(key: Prompt10BookFramePreference.self,
                    value: [key: proxy.frame(in: .named("prompt10.bookStage"))])
            }
        }
    }
}
