import SwiftUI

struct Prompt10BookFramePreference: PreferenceKey {
    static let defaultValue: [UUID: CGRect] = [:]
    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// One coded surface from the existing shelf spine to the persistent open book.
/// The supplied watercolor assets remain visual references, never swapped frames.
struct Prompt10ContinuousBook: View, Animatable {
    let style: Prompt10BookStyle
    var reveal: Double
    var openness: Double
    var animatableData: AnimatablePair<Double, Double> {
        get { .init(reveal, openness) }
        set { reveal = newValue.first; openness = newValue.second }
    }

    var body: some View {
        Canvas { context, size in
            let r = Prompt10BookMotion.unit(reveal)
            let o = Prompt10BookMotion.unit(openness)
            let height = max(1, size.height * 0.94)
            let top = (size.height - height) / 2
            let spineWidth = min(size.width * 0.44, height * 0.28)
            let half = max(1, size.width * 0.48)
            let closedWidth = spineWidth + (half - spineWidth) * r
            let hinge = size.width / 2 - closedWidth * (1 - o) / 2
            let left = hinge - half * o
            let right = hinge + closedWidth
            let cover = CGRect(x: left, y: top, width: max(1, right - left), height: height)
            context.fill(Path(roundedRect: cover, cornerRadius: max(2, height * 0.015)), with: .color(style.bookCoverColor))
            context.stroke(Path(roundedRect: cover.insetBy(dx: 2, dy: 2), cornerRadius: 3), with: .color(style.bookCoverColor.opacity(0.75)), lineWidth: 2)
            // Deterministic coded wash: no asset substitution or random redraw.
            for index in 0..<70 {
                let x = cover.minX + cover.width * CGFloat((index * 37 % 101)) / 101
                let y = cover.minY + cover.height * CGFloat((index * 61 % 103)) / 103
                let radius = max(1, min(cover.width, cover.height) * 0.09)
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius * 1.4)), with: .color(.white.opacity(0.035)))
            }
            var pages = context
            pages.opacity = o
            let pageInset = max(3, size.width * 0.018)
            for side in [-1.0, 1.0] {
                let outer = side < 0 ? left + pageInset : right - pageInset
                var page = Path()
                page.move(to: CGPoint(x: hinge, y: top + height * 0.055))
                page.addQuadCurve(to: CGPoint(x: outer, y: top + height * 0.028), control: CGPoint(x: (hinge + outer) / 2, y: top - height * 0.015))
                page.addLine(to: CGPoint(x: outer, y: top + height * 0.955))
                page.addQuadCurve(to: CGPoint(x: hinge, y: top + height * 0.97), control: CGPoint(x: (hinge + outer) / 2, y: top + height * 0.93))
                page.closeSubpath()
                pages.fill(page, with: .linearGradient(Gradient(colors: [Color(red: 0.98, green: 0.94, blue: 0.83), Color(red: 0.91, green: 0.83, blue: 0.66)]), startPoint: CGPoint(x: outer, y: 0), endPoint: CGPoint(x: hinge, y: 0)))
                pages.stroke(page, with: .color(Color.brown.opacity(0.2)), lineWidth: 1)
            }
            // The original spine's inset cream frame remains at the closed end.
            var spine = context
            spine.opacity = 1 - r
            spine.stroke(Path(roundedRect: cover.insetBy(dx: spineWidth * 0.18, dy: height * 0.07), cornerRadius: 1), with: .color(Color.white.opacity(0.8)), lineWidth: 1)
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}

extension Prompt10BookStyle {
    var bookCoverColor: Color {
        switch self {
        case .sage: return Color(red: 0.52, green: 0.64, blue: 0.54)
        case .yellow: return Color(red: 0.88, green: 0.73, blue: 0.40)
        case .pink: return Color(red: 0.84, green: 0.60, blue: 0.67)
        case .coral: return Color(red: 0.84, green: 0.50, blue: 0.46)
        case .lavender: return Color(red: 0.69, green: 0.61, blue: 0.79)
        }
    }
}

#if DEBUG
/// Disposable suite contains fixture labels only, never production saved data.
struct Prompt1BBookRegressionHarness: View {
    @StateObject private var store: Prompt10SavedLibraryStore
    @StateObject private var motion = MotionPreferences()
    private let suite: String
    private let fixtureError: String?

    init() {
        let suite = "fruitfolio.bookQA." + UUID().uuidString
        self.suite = suite
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        let store = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: "fixture")
        var failure: String?
        do {
            for style in Prompt10BookStyle.allCases {
                _ = try store.createEncyclopedia(name: "QA \(style.rawValue)", style: style)
            }
        } catch { failure = error.localizedDescription }
        self.fixtureError = failure
        _store = StateObject(wrappedValue: store)
    }
    var body: some View {
        Group {
            if let fixtureError { Text(fixtureError) }
            else { Prompt10SavedLibraryView(store: store, onBack: {}) }
        }
        .environmentObject(motion)
        .onAppear {
            motion.update(systemReduceMotion: false, appOverride: ProcessInfo.processInfo.arguments.contains("-fruitfolioBookReduceMotion"))
        }
        .onDisappear { UserDefaults.standard.removePersistentDomain(forName: suite) }
    }
}
#endif
