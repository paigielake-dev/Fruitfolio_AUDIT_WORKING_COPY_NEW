import SwiftUI
import Foundation

struct Prompt18DynamicCycleWheel: View {
    let model: Prompt18WheelModel
    let revealProgress: CGFloat
    let showCurrentMarker: Bool
    var onLearnWhy: (Prompt18WheelRegionKind) -> Void = { _ in }
    var onInteraction: () -> Void = {}
    var interactionAllowed: () -> Bool = { true }

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewIsVisible = false
    @State private var noteSession = Prompt18WheelNoteSession()
    private var selectedRegion: Prompt18WheelRegionKind? { noteSession.selectedRegion }
    private var canInteract: Bool { viewIsVisible && scenePhase == .active && interactionAllowed() }

    var body: some View {
        VStack(spacing: 12) {
            drawing
            if dynamicTypeSize.isAccessibilitySize {
                Text(centerSummary).font(.body).multilineTextAlignment(.center)
                ForEach(accessibleSegments) { segment in
                    Button(accessibilityLabel(for: segment)) { select(segment.kind) }
                        .frame(maxWidth: .infinity, minHeight: DesignTokens.Layout.minimumHitTarget)
                        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                    if selectedRegion == segment.kind, let presentationID = noteSession.presentationID {
                        Prompt18TapedNote(kind: segment.kind,
                            onLearnWhy: { learnWhy(segment.kind, expectedID: presentationID) },
                            onClose: { dismissNote(expectedID: presentationID) })
                            .frame(maxWidth: 340).frame(height: 340)
                    }
                }
            }
        }
        .disabled(!canInteract)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilitySummary)
        .onAppear { viewIsVisible = true }
        .onChange(of: model) { _, _ in noteSession.reset() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { noteSession.invalidateActions() }
        }
        .onChange(of: interactionAllowed()) { _, allowed in
            if !allowed { noteSession.invalidateActions() }
        }
    }

    private var accessibleSegments: [Prompt18WheelSegment] {
        model.baseSegments + (model.fertileOverlay.map { [$0] } ?? [])
    }
    private var centerSummary: String {
        let day = model.currentCycleDay.map { "cycle day \($0)" } ?? "cycle day not available"
        let length = model.representedCycleLength.map { "estimated cycle length \($0) days" } ?? "estimated length not available"
        return day + "; " + length
    }
    private func select(_ kind: Prompt18WheelRegionKind) {
        guard canInteract, accessibleSegments.contains(where: { $0.kind == kind }) else { return }
        onInteraction()
        withAnimation(motionPreferences.reduceMotionActive ? nil : .easeOut(duration: 0.18)) {
            noteSession.select(kind, permitted: canInteract, available: Set(accessibleSegments.map(\.kind)))
        }
    }

    private func dismissNote(expectedID: UUID) {
        guard noteSession.admits(expectedID, permitted: canInteract) else { return }
        onInteraction()
        withAnimation(motionPreferences.reduceMotionActive ? nil : .easeOut(duration: 0.18)) {
            noteSession.dismiss(expectedID, permitted: canInteract)
        }
    }

    private func learnWhy(_ kind: Prompt18WheelRegionKind, expectedID: UUID) {
        guard noteSession.admits(expectedID, permitted: canInteract), selectedRegion == kind else { return }
        // Consume before routing so a double invocation cannot open twice.
        guard noteSession.dismiss(expectedID, permitted: canInteract) else { return }
        onInteraction()
        onLearnWhy(kind)
    }

    private var drawing: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let ringSide = min(side * 0.66, 286)

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard let presentationID = noteSession.presentationID else { return }
                        dismissNote(expectedID: presentationID)
                    }

                unresolvedLayer(side: ringSide)

                paintedLayer(side: ringSide)
                    .mask {
                        Prompt18ClockwiseRevealMask(progress: revealProgress)
                    }
                    .allowsHitTesting(revealProgress >= 0.98)
                    .accessibilityHidden(dynamicTypeSize.isAccessibilitySize)

                labelLayer(center: center, side: ringSide)
                    .opacity(dynamicTypeSize.isAccessibilitySize ? 0 : labelOpacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)

                centerContent.opacity(dynamicTypeSize.isAccessibilitySize ? 0 : 1)

                if showCurrentMarker,
                   let fraction = model.currentPositionFraction {
                    Prompt18CurrentMarker()
                        .position(
                            markerPosition(
                                fraction: fraction,
                                center: center,
                                side: ringSide
                            )
                        )
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                if !dynamicTypeSize.isAccessibilitySize, let selectedRegion,
                   let presentationID = noteSession.presentationID,
                   let selectedSegment = segment(for: selectedRegion) {
                    let noteFrame = Prompt18WheelNoteLayout.frame(in: proxy.size,
                        fraction: selectedSegment.midFraction, idealWidth: dynamicTypeSize.isAccessibilitySize ? 340 : 205)
                    Prompt18TapedNote(kind: selectedRegion,
                        onLearnWhy: { learnWhy(selectedRegion, expectedID: presentationID) },
                        onClose: { dismissNote(expectedID: presentationID) })
                    .frame(width: noteFrame.width, height: noteFrame.height)
                    .position(x: noteFrame.midX, y: noteFrame.midY)
                    .transition(.opacity)
                    .zIndex(20)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .onDisappear {
            viewIsVisible = false
            noteSession.reset()
        }
    }

    @ViewBuilder
    private func unresolvedLayer(side: CGFloat) -> some View {
        ZStack {
            ForEach(Array(model.unresolvedIntervals.enumerated()), id: \.offset) { _, interval in
                let segment = wheelSegment(
                    interval: interval,
                    kind: .follicular
                )

                Prompt18PaintedSegment(
                    segment: segment,
                    color: Prompt18Palette.unresolved,
                    baseOpacity: 0.08,
                    selected: false,
                    current: false,
                    isOverlay: false
                )
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func paintedLayer(side: CGFloat) -> some View {
        ZStack {
            ForEach(model.baseSegments) { segment in
                regionButton(
                    segment: segment,
                    side: side,
                    isOverlay: false
                )
            }

            if let fertile = model.fertileOverlay {
                regionButton(
                    segment: fertile,
                    side: side,
                    isOverlay: true
                )
            }
        }
        .frame(width: side, height: side)
    }

    private func regionButton(
        segment: Prompt18WheelSegment,
        side: CGFloat,
        isOverlay: Bool
    ) -> some View {
        let selected = selectedRegion == segment.kind
        let current = model.currentRegion == segment.kind

        return Button {
            select(segment.kind)
        } label: {
            Prompt18PaintedSegment(
                segment: segment,
                color: Prompt18Palette.color(for: segment.kind),
                baseOpacity: isOverlay ? 0.25 : 0.30,
                selected: selected,
                current: current && showCurrentMarker,
                isOverlay: isOverlay
            )
            .frame(width: side, height: side)
            .contentShape(
                Prompt18AnnularSegment(
                    startAngle: .degrees(angle(for: segment.startFraction)),
                    endAngle: .degrees(angle(for: segment.endFraction)),
                    innerRadiusRatio: isOverlay ? 0.45 : 0.53
                )
            )
        }
        .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
        .accessibilityLabel(accessibilityLabel(for: segment))
        .accessibilityHint("Opens a short cycle biology note.")
    }

    @ViewBuilder
    private func labelLayer(
        center: CGPoint,
        side: CGFloat
    ) -> some View {
        ForEach(model.baseSegments) { segment in
            Prompt18WheelLabel(
                text: segment.kind.title,
                estimated: segment.kind == .estimatedOvulation
            )
            .position(
                labelPosition(
                    for: segment,
                    center: center,
                    side: side,
                    isOverlay: false
                )
            )
        }

        if let fertile = model.fertileOverlay {
            Prompt18WheelLabel(
                text: "fertile window",
                estimated: true
            )
            .position(
                labelPosition(
                    for: fertile,
                    center: center,
                    side: side,
                    isOverlay: true
                )
            )
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        VStack(spacing: 4) {
            if let day = model.currentCycleDay {
                Text("cycle day")
                    .font(Prompt18Type.small)
                    .foregroundStyle(
                        Prompt18Palette.burgundy.opacity(0.66)
                    )

                Text("\(day)")
                    .font(Prompt18Type.wheelNumber)
                    .foregroundStyle(
                        Prompt18Palette.burgundy
                    )

                if let cycleLength =
                    model.representedCycleLength {

                    Text("~\(cycleLength) days")
                        .font(Prompt18Type.wheelLength)
                        .foregroundStyle(
                            Prompt18Palette
                                .burgundy
                                .opacity(0.62)
                        )
                        .padding(.top, 2)
                }
            } else if let cycleLength =
                model.representedCycleLength {

                Text("estimated cycle")
                    .font(Prompt18Type.small)
                    .foregroundStyle(
                        Prompt18Palette.burgundy.opacity(0.66)
                    )

                Text("~\(cycleLength) days")
                    .font(Prompt18Type.wheelLength)
                    .foregroundStyle(
                        Prompt18Palette.burgundy
                    )
            } else {
                Text("little by little")
                    .font(Prompt18Type.wheelCenter)
                    .foregroundStyle(
                        Prompt18Palette.burgundy.opacity(0.72)
                    )
            }
        }
        .accessibilityHidden(true)
    }

    private var labelOpacity: Double {
        let normalized = (Double(revealProgress) - 0.72) / 0.28
        return min(1, max(0, normalized))
    }

    private func segment(
        for kind: Prompt18WheelRegionKind
    ) -> Prompt18WheelSegment? {
        if kind == .estimatedFertileWindow {
            return model.fertileOverlay
        }

        return model.baseSegments.first { $0.kind == kind }
    }

    private func wheelSegment(
        interval: Prompt18CycleDayInterval,
        kind: Prompt18WheelRegionKind
    ) -> Prompt18WheelSegment {
        guard let cycleLength = model.representedCycleLength,
              cycleLength > 0 else {
            return Prompt18WheelSegment(
                kind: kind,
                interval: interval,
                startFraction: 0,
                endFraction: 0
            )
        }

        return Prompt18WheelSegment(
            kind: kind,
            interval: interval,
            startFraction: Double(interval.startDay - 1) / Double(cycleLength),
            endFraction: Double(interval.endDay) / Double(cycleLength)
        )
    }

    private func angle(for fraction: Double) -> Double {
        -90 + (fraction * 360)
    }

    private func markerPosition(
        fraction: Double,
        center: CGPoint,
        side: CGFloat
    ) -> CGPoint {
        let radians = Angle.degrees(angle(for: fraction)).radians
        let radius = side * 0.405

        return CGPoint(
            x: center.x + CGFloat(Foundation.cos(radians)) * radius,
            y: center.y + CGFloat(Foundation.sin(radians)) * radius
        )
    }

    private func labelPosition(
        for segment: Prompt18WheelSegment,
        center: CGPoint,
        side: CGFloat,
        isOverlay: Bool
    ) -> CGPoint {
        let radians = Angle.degrees(angle(for: segment.midFraction)).radians
        let radius = side * (isOverlay ? 0.76 : 0.66)

        return CGPoint(
            x: center.x + CGFloat(Foundation.cos(radians)) * radius,
            y: center.y + CGFloat(Foundation.sin(radians)) * radius
        )
    }

    private func accessibilityLabel(
        for segment: Prompt18WheelSegment
    ) -> String {
        var parts = [segment.kind.title]
        parts.append("cycle days \(segment.interval.startDay) through \(segment.interval.endDay)")

        if segment.kind.isEstimate || segment.interval.provenance == .estimated {
            parts.append("estimated")
        }

        if model.currentRegion == segment.kind {
            parts.append("current cycle context")
        }

        return parts.joined(separator: ", ")
    }

    private var accessibilitySummary: String {
        guard let cycleLength = model.representedCycleLength else {
            return "Cycle wheel. Personalized cycle timing is not available yet."
        }

        var parts = ["Dynamic cycle wheel representing \(cycleLength) days"]

        if let day = model.currentCycleDay {
            parts.append("current cycle day \(day)")
        }

        parts.append(model.confidence.rawValue)

        if model.hasEstimatedFertileWindow {
            parts.append("includes an estimated fertile-window overlay")
        }

        if model.hasEstimatedOvulation {
            parts.append("includes an estimated ovulation interval")
        }

        return parts.joined(separator: ", ")
    }
}

private struct Prompt18PaintedSegment: View {
    let segment: Prompt18WheelSegment
    let color: Color
    let baseOpacity: Double
    let selected: Bool
    let current: Bool
    let isOverlay: Bool

    var body: some View {
        ZStack {
            if current {
                paintedShape(opacity: baseOpacity * 0.42, inset: -2.0, radiusAdjustment: -0.010)
                    .scaleEffect(1.025)
            }

            paintedShape(opacity: baseOpacity, inset: 0, radiusAdjustment: 0)
            paintedShape(opacity: baseOpacity * 0.54, inset: 2.5, radiusAdjustment: 0.015)
                .rotationEffect(.degrees(0.55))
            paintedShape(opacity: baseOpacity * 0.30, inset: 5.0, radiusAdjustment: 0.030)
                .rotationEffect(.degrees(-0.7))

            if selected {
                Prompt18AnnularSegment(
                    startAngle: .degrees(-90 + segment.startFraction * 360),
                    endAngle: .degrees(-90 + segment.endFraction * 360),
                    innerRadiusRatio: isOverlay ? 0.47 : 0.57
                )
                .stroke(
                    Prompt18Palette.burgundy.opacity(0.44),
                    style: StrokeStyle(lineWidth: 1.35, lineCap: .round)
                )
                .padding(isOverlay ? 12 : 8)
            }
        }
        .accessibilityHidden(true)
    }

    private func paintedShape(
        opacity: Double,
        inset: CGFloat,
        radiusAdjustment: CGFloat
    ) -> some View {
        Prompt18AnnularSegment(
            startAngle: .degrees(-90 + segment.startFraction * 360),
            endAngle: .degrees(-90 + segment.endFraction * 360),
            innerRadiusRatio: (isOverlay ? 0.47 : 0.57) + radiusAdjustment
        )
        .fill(color.opacity(opacity))
        .padding(isOverlay ? 12 + inset : 8 + inset)
    }
}

private struct Prompt18ClockwiseRevealMask: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let clamped = min(1, max(0, progress))

            Circle()
                .trim(from: 0, to: clamped)
                .stroke(
                    Color.black,
                    style: StrokeStyle(
                        lineWidth: side * 0.48,
                        lineCap: .butt
                    )
                )
                .rotationEffect(.degrees(-90))
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct Prompt18AnnularSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let innerRadiusRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = max(0, min(rect.width, rect.height) / 2)
        let innerRadius = outerRadius * innerRadiusRatio

        var path = Path()
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )
        path.closeSubpath()
        return path
    }
}

private struct Prompt18WheelLabel: View {
    let text: String
    let estimated: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(text)
                .font(Prompt18Type.wheelLabel)
                .fontWeight(.semibold)
                .lineLimit(1)

            if estimated {
                Text("estimated")
                    .font(Prompt18Type.wheelLabelSecondary)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(Prompt18Palette.burgundy.opacity(0.80))
        .fixedSize()
        .accessibilityHidden(true)
    }
}

private struct Prompt18CurrentMarker: View {
    var body: some View {
        Circle()
            .fill(Prompt18Palette.paper)
            .frame(width: 22, height: 22)
            .overlay {
                Circle()
                    .stroke(Prompt18Palette.burgundy, lineWidth: 2.2)
            }
            .shadow(
                color: Prompt18Palette.burgundy.opacity(0.10),
                radius: 2
            )
            .accessibilityHidden(true)
    }
}

private struct Prompt18TapedNote: View {
    let kind: Prompt18WheelRegionKind
    let onLearnWhy: () -> Void
    let onClose: () -> Void
    @EnvironmentObject private var motionPreferences: MotionPreferences
    var body: some View {
        FruitfolioTapedWhitePopup {
            VStack(alignment: .leading, spacing: 8) {
                Text(kind.title).font(Prompt18Type.noteTitle).accessibilityAddTraits(.isHeader)
                Text(kind.noteBody).font(Prompt18Type.noteBody).fixedSize(horizontal: false, vertical: true)
                Button("learn why →", action: onLearnWhy)
                    .font(Prompt18Type.noteLink)
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                    .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                    .accessibilityHint("opens the deeper biology explanation")
                Button("close note", action: onClose)
                    .frame(minHeight: DesignTokens.Layout.minimumHitTarget)
                    .buttonStyle(CutePopButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
            }
            .foregroundStyle(Prompt18Palette.burgundy)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("wheel.note")
    }
}

private enum Prompt18Palette {
    static let burgundy = Color(red: 128.0 / 255.0, green: 0, blue: 0)
    static let paper = DesignTokens.ColorToken.backgroundCream
    static let coral = Color(red: 0.91, green: 0.47, blue: 0.49)
    static let sage = Color(red: 0.55, green: 0.67, blue: 0.52)
    static let peach = Color(red: 0.91, green: 0.68, blue: 0.49)
    static let dustyBlue = Color(red: 0.64, green: 0.78, blue: 0.79)
    static let softYellow = Color(red: 0.92, green: 0.80, blue: 0.45)
    static let unresolved = burgundy

    static func color(for kind: Prompt18WheelRegionKind) -> Color {
        switch kind {
        case .menstruation:
            return coral
        case .follicular:
            return sage
        case .estimatedOvulation:
            return dustyBlue
        case .luteal:
            return peach
        case .estimatedFertileWindow:
            return softYellow
        }
    }
}

private enum Prompt18Type {
    static let small = Font.custom("Chalkboard SE", size: 11.5, relativeTo: .caption)
    static let wheelNumber = Font.custom("Chalkboard SE", size: 32, relativeTo: .title).weight(.bold)
    static let wheelCenter = Font.custom("Chalkboard SE", size: 15, relativeTo: .body)
    static let wheelLabel = Font.custom("Chalkboard SE", size: 10.5, relativeTo: .caption)
    static let wheelLabelSecondary = Font.custom("Chalkboard SE", size: 9, relativeTo: .caption2)
    static let wheelLength = Font.custom("Chalkboard SE", size: 9.5, relativeTo: .caption2)
    static let noteTitle = Font.custom("Chalkboard SE", size: 13, relativeTo: .subheadline).weight(.semibold)
    static let noteBody = Font.custom("Chalkboard SE", size: 11.5, relativeTo: .caption)
    static let noteLink = Font.custom("Chalkboard SE", size: 11.5, relativeTo: .caption).weight(.semibold)
}

#if DEBUG
struct Prompt18WheelRegressionHarness: View {
    @State private var openedBiology = false
    private let model: Prompt18WheelModel
    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let first = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let starts = (0...5).compactMap { calendar.date(byAdding: .day, value: $0 * 28, to: first) }
        let now = calendar.date(byAdding: .day, value: 8, to: starts.last!)!
        let end = calendar.date(byAdding: .day, value: 4, to: starts.last!)!
        let prediction = Prompt17CyclePredictionEngine(calendar: calendar).calculate(from: .init(cycleStartDates: starts,
            periodRecords: [.init(startDate: starts.last!, endDate: end)], asOfDate: now))
        model = Prompt18CycleWheelBuilder().build(prediction: prediction)
    }
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Prompt18DynamicCycleWheel(model: model, revealProgress: 1, showCurrentMarker: false,
                    onLearnWhy: { _ in openedBiology = true })
                if openedBiology { Text("QA biology opened").accessibilityIdentifier("wheelQA.biology") }
            }
            .frame(maxWidth: 430).padding(20).frame(maxWidth: .infinity)
        }
    }
}
#endif
