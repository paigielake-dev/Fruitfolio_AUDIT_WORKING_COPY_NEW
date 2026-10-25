import SwiftUI
import Foundation

@MainActor
struct Prompt22HormoneRhythmView: View {
    var loader: Prompt22HormoneRhythmLoader
    var context: Prompt27AUserReproductiveContext
    var contextPolicy: Prompt27AContextPolicyResult

    init(
        loader: Prompt22HormoneRhythmLoader? = nil,
        context: Prompt27AUserReproductiveContext = .unspecified,
        contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult()
    ) {
        self.loader = loader ?? Prompt22HormoneRhythmLoader()
        self.context = context
        self.contextPolicy = contextPolicy
    }

    @EnvironmentObject private var motionPreferences: MotionPreferences

    @State private var loadState: LoadState = .loading
    @State private var presentation =
        Prompt22HormoneRhythmEngine().presentation(for: .neutral)
    @State private var revealProgress: CGFloat = 0

    private enum LoadState {
        case loading
        case loaded
        case failed
    }

    private var contextAdapter: Prompt27AExistingSystemPolicyAdapter {
        Prompt27AExistingSystemPolicyAdapter(result: contextPolicy)
    }

    private var displayedPresentation: Prompt22HormoneRhythmPresentation {
        guard !contextAdapter.showHormoneRhythmContextMarker else {
            return presentation
        }

        return Prompt22HormoneRhythmPresentation(
            title: presentation.title,
            subtitle: presentation.subtitle,
            contextNote: nil,
            sections: presentation.sections.map { section in
                Prompt22HormoneSectionPresentation(
                    hormone: section.hormone,
                    assetName: section.assetName,
                    title: section.title,
                    summary: section.summary,
                    accessibilitySummary: section.accessibilitySummary,
                    pattern: section.pattern,
                    marker: nil,
                    researchIDs: section.researchIDs
                )
            },
            showsContextMarker: false
        )
    }

    private var contextClarification: String? {
        Prompt27AContextPresentationCopy.hormoneClarification(
            context: context,
            policy: contextPolicy
        )
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView
            case .loaded:
                content
            case .failed:
                fallbackView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task {
            await load()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(Prompt22HormoneAsset.accentMarks)
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

            Text("opening hormone rhythm…")
                .font(Prompt22Type.body)
                .foregroundStyle(Prompt22Palette.burgundy.opacity(0.70))
        }
        .frame(maxWidth: .infinity, minHeight: 420)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading hormone rhythm")
    }

    private var fallbackView: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            contextClarificationView

            ForEach(displayedPresentation.sections, id: \.hormone) { section in
                hormoneSection(section)
            }

            patternKey
        }
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 24) {
            header

            contextClarificationView

            if let contextNote = displayedPresentation.contextNote {
                Text(contextNote)
                    .font(Prompt22Type.context)
                    .foregroundStyle(
                        Prompt22Palette.burgundy.opacity(0.72)
                    )
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(
                        "Current Cycle Tracker context: \(contextNote). " +
                        "The marker shows estimated cycle-timeline position only; " +
                        "its vertical placement follows an educational curve and is not a hormone measurement."
                    )
            }

            ForEach(displayedPresentation.sections, id: \.hormone) { section in
                hormoneSection(section)
            }

            patternKey
        }
        .frame(maxWidth: 620, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var contextClarificationView: some View {
        if let contextClarification {
            Text(contextClarification)
                .font(Prompt22Type.context)
                .foregroundStyle(
                    Prompt22Palette.burgundy.opacity(0.72)
                )
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Prompt22Palette.burgundy.opacity(0.045),
                    in: RoundedRectangle(
                        cornerRadius: 16,
                        style: .continuous
                    )
                )
                .accessibilityLabel(contextClarification)
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(displayedPresentation.title)
                    .font(Prompt22Type.title)
                    .foregroundStyle(Prompt22Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Text(displayedPresentation.subtitle)
                    .font(Prompt22Type.subtitle)
                    .foregroundStyle(
                        Prompt22Palette.burgundy.opacity(0.68)
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Image(Prompt22HormoneAsset.accentMarks)
                .resizable()
                .scaledToFit()
                .frame(width: 58)
                .opacity(0.86)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func hormoneSection(
        _ section: Prompt22HormoneSectionPresentation
    ) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center, spacing: 14) {
                Image(section.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 82)
                    .accessibilityHidden(true)

                Text(section.title)
                    .font(Prompt22Type.hormoneTitle)
                    .foregroundStyle(Prompt22Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Spacer(minLength: 0)
            }

            Prompt22QualitativeRhythmGraph(
                points: section.pattern,
                marker: section.marker,
                revealProgress:
                    motionPreferences.reduceMotionActive
                        ? 1
                        : revealProgress
            )
            .frame(height: 112)
            .accessibilityElement()
            .accessibilityLabel(section.accessibilitySummary)

            Text(section.summary)
                .font(Prompt22Type.body)
                .foregroundStyle(
                    Prompt22Palette.burgundy.opacity(0.84)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private var patternKey: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(Prompt22HormoneAsset.increaseArrow)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)

                Text("general direction only")
                    .font(Prompt22Type.note)
                    .foregroundStyle(
                        Prompt22Palette.burgundy.opacity(0.72)
                    )

                Image(Prompt22HormoneAsset.decreaseArrow)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
            }

            HStack(alignment: .center, spacing: 12) {
                Image(Prompt22HormoneAsset.bloodCells)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)

                Text(
                    "these illustrations are educational references, not blood-test results."
                )
                .font(Prompt22Type.note)
                .foregroundStyle(
                    Prompt22Palette.burgundy.opacity(0.72)
                )
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "General direction only. These illustrations are educational references, not blood-test results."
        )
    }

    private func load() async {
        do {
            let input = try await loader.load(now: Date())
            guard !Task.isCancelled else { return }

            presentation =
                Prompt22HormoneRhythmEngine()
                    .presentation(for: input)
            loadState = .loaded

            if motionPreferences.reduceMotionActive {
                revealProgress = 1
            } else {
                revealProgress = 0
                withAnimation(.easeOut(duration: 0.56)) {
                    revealProgress = 1
                }
            }
        } catch {
            guard !Task.isCancelled else { return }

            presentation =
                Prompt22HormoneRhythmEngine()
                    .presentation(for: .neutral)
            loadState = .failed
            revealProgress = 1
        }
    }
}

private struct Prompt22QualitativeRhythmGraph: View {
    let points: [Prompt22NormalizedPoint]
    let marker: Prompt22ContextMarker?
    let revealProgress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(
                origin: .zero,
                size: proxy.size
            )

            ZStack {
                Prompt22PaperLines()
                    .stroke(
                        Prompt22Palette.burgundy.opacity(0.08),
                        lineWidth: 1
                    )

                Prompt22CurveShape(points: points)
                    .trim(from: 0, to: revealProgress)
                    .stroke(
                        Prompt22Palette.burgundy.opacity(0.76),
                        style: StrokeStyle(
                            lineWidth: 2.25,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )

                if let marker {
                    let markerReveal = min(
                        1,
                        max(
                            0,
                            (
                                Double(revealProgress)
                                - marker.x
                                + 0.03
                            ) / 0.03
                        )
                    )

                    Prompt22CurveMarker(
                        confidence: marker.confidence
                    )
                    .opacity(markerReveal)
                    .scaleEffect(0.92 + 0.08 * markerReveal)
                    .position(
                        x: rect.width * CGFloat(marker.x),
                        y: rect.height * CGFloat(1 - marker.y)
                    )
                    .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct Prompt22CurveMarker: View {
    let confidence: Prompt22Confidence

    private var haloOpacity: Double {
        switch confidence {
        case .limited:
            return 0.20
        case .developing:
            return 0.14
        case .strong:
            return 0.08
        case .unavailable:
            return 0.10
        }
    }

    private var haloSize: CGFloat {
        switch confidence {
        case .limited:
            return 34
        case .developing:
            return 30
        case .strong:
            return 26
        case .unavailable:
            return 28
        }
    }

    var body: some View {
        ZStack {
            FruitfolioImage(id: .control_slider_knob)
                .frame(width: haloSize, height: haloSize)
                .opacity(haloOpacity)
                .blur(radius: 4)

            FruitfolioImage(id: .control_slider_knob)
                .frame(width: 20, height: 20)
        }
        .frame(width: 36, height: 36)
        .allowsHitTesting(false)
    }
}

private struct Prompt22PaperLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        for fraction in [0.25, 0.50, 0.75] as [CGFloat] {
            let y = rect.height * fraction
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: rect.width, y: y))
        }

        return path
    }
}

private struct Prompt22CurveShape: Shape {
    let points: [Prompt22NormalizedPoint]

    func path(in rect: CGRect) -> Path {
        guard let first = points.first else {
            return Path()
        }

        var path = Path()
        path.move(
            to: CGPoint(
                x: rect.width * CGFloat(first.x),
                y: rect.height * CGFloat(1 - first.y)
            )
        )

        for point in points.dropFirst() {
            path.addLine(
                to: CGPoint(
                    x: rect.width * CGFloat(point.x),
                    y: rect.height * CGFloat(1 - point.y)
                )
            )
        }

        return path
    }
}

private enum Prompt22Palette {
    static let burgundy = Color(
        red: 128.0 / 255.0,
        green: 0,
        blue: 0
    )
}

private enum Prompt22Type {
    static let title = Font.custom(
        "Chalkboard SE",
        size: 25,
        relativeTo: .title2
    )
    .weight(.bold)

    static let subtitle = Font.custom(
        "Chalkboard SE",
        size: 13,
        relativeTo: .subheadline
    )

    static let hormoneTitle = Font.custom(
        "Chalkboard SE",
        size: 20,
        relativeTo: .title3
    )
    .weight(.semibold)

    static let body = Font.custom(
        "Chalkboard SE",
        size: 14,
        relativeTo: .body
    )

    static let context = Font.custom(
        "Chalkboard SE",
        size: 12.5,
        relativeTo: .subheadline
    )

    static let note = Font.custom(
        "Chalkboard SE",
        size: 12,
        relativeTo: .caption
    )
}
