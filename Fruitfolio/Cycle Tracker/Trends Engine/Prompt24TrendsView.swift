import SwiftUI

@MainActor
struct Prompt24TrendsView: View {
    var loader: Prompt24TrendsLoader
    var contextPolicy: Prompt27AContextPolicyResult

    init(
        loader: Prompt24TrendsLoader? = nil,
        contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult()
    ) {
        self.loader = loader ?? Prompt24TrendsLoader()
        self.contextPolicy = contextPolicy
    }

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @Environment(\.scenePhase) private var scenePhase

    @State private var selectedTab: Prompt24TrendsTab = .cycle
    @State private var selectedSymptoms: Set<Prompt20SymptomID> = [.cramps]
    @State private var snapshot: Prompt24TrendsSnapshot?
    @State private var loadState: LoadState = .loading
    @State private var refreshID = UUID()

    private enum LoadState {
        case loading
        case loaded
        case failed
    }

    private var contextClarification: String? {
        Prompt27AContextPresentationCopy.trendsClarification(
            policy: contextPolicy
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if let contextClarification {
                Text(contextClarification)
                    .font(
                        Font.custom(
                            "Chalkboard SE",
                            size: 12.5,
                            relativeTo: .subheadline
                        )
                    )
                    .foregroundStyle(Prompt24Palette.burgundy.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Prompt24Palette.burgundy.opacity(0.045),
                        in: RoundedRectangle(
                            cornerRadius: 16,
                            style: .continuous
                        )
                    )
                    .accessibilityLabel(contextClarification)
            }

            tabRow

            Group {
                switch loadState {
                case .loading:
                    loadingView
                case .failed:
                    failureView
                case .loaded:
                    loadedContent
                }
            }
            .id(selectedTab)
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .task(id: refreshID) {
            await load()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshID = UUID()
            }
        }
        .accessibilityIdentifier("prompt24.trends")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Text("trends")
                    .font(
                        Font.custom(
                            "Chalkboard SE",
                            size: 26,
                            relativeTo: .title2
                        )
                    )
                    .fontWeight(.bold)
                    .foregroundStyle(Prompt24Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Image("decor_sun")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .offset(y: -1)
                    .accessibilityHidden(true)
            }

            Text("your records, carefully mapped over time ♡")
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 14,
                        relativeTo: .subheadline
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.74))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tabRow: some View {
        HStack(spacing: 12) {
            ForEach(Prompt24TrendsTab.allCases) { tab in
                Button {
                    audioManager.play(.buttonSoftPop)
                    if motionPreferences.reduceMotionActive {
                        selectedTab = tab
                    } else {
                        withAnimation(.easeOut(duration: 0.20)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.rawValue)
                            .font(
                                Font.custom(
                                    "Chalkboard SE",
                                    size: 13,
                                    relativeTo: .subheadline
                                )
                            )
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(Prompt24Palette.burgundy)

                        Prompt24Underline()
                            .stroke(
                                Prompt24Palette.burgundy,
                                style: StrokeStyle(
                                    lineWidth: 1.6,
                                    lineCap: .round
                                )
                            )
                            .frame(height: 5)
                            .opacity(selectedTab == tab ? 0.78 : 0)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(
                    Prompt24SoftPressButtonStyle(
                        reduceMotion: motionPreferences.reduceMotionActive
                    )
                )
                .accessibilityLabel("\(tab.rawValue) trends")
                .accessibilityAddTraits(
                    selectedTab == tab ? [.isSelected] : []
                )
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var loadedContent: some View {
        if let snapshot {
            switch selectedTab {
            case .cycle:
                cycleTab(snapshot)
            case .temperature:
                temperatureTab(snapshot)
            case .symptoms:
                symptomsTab(snapshot)
            }
        } else {
            failureView
        }
    }

    private func cycleTab(
        _ snapshot: Prompt24TrendsSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Prompt24MetricSection(
                title: "cycle length",
                subtitle: "completed recorded cycles",
                hasData: !snapshot.cycleLengths.isEmpty
            ) {
                Prompt24CycleLengthChart(
                    points: snapshot.cycleLengths,
                    median: snapshot.cycleMedianDays,
                    prediction: snapshot.predictionMarker,
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            }

            if !snapshot.cycleLengths.isEmpty {
                HStack(spacing: 18) {
                    if let median = snapshot.cycleMedianDays {
                        Prompt24TinyStat(
                            title: "your median",
                            value: Prompt24Format.days(median)
                        )
                    }

                    if let range = snapshot.cycleObservedRange {
                        Prompt24TinyStat(
                            title: "your recorded range",
                            value: "\(range.lowerBound)–\(range.upperBound) days"
                        )
                    }

                    Prompt24TinyStat(
                        title: "eligible cycles",
                        value: "\(snapshot.cycleLengths.count)"
                    )
                }
                .accessibilityElement(children: .combine)
            }

            Prompt24MetricSection(
                title: "period length",
                subtitle: "complete recorded periods only",
                hasData: !snapshot.periodLengths.isEmpty
            ) {
                Prompt24PeriodLengthChart(
                    points: snapshot.periodLengths,
                    median: snapshot.periodMedianDays,
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            }
        }
    }

    private func temperatureTab(
        _ snapshot: Prompt24TrendsSnapshot
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Prompt24MetricSection(
                title: "basal body temperature",
                subtitle: "recorded waking measurements",
                hasData: snapshot.hasTemperatureData
            ) {
                Prompt24BBTChart(
                    points: snapshot.bbtPoints,
                    displayUnit: snapshot.displayTemperatureUnit,
                    calendar: .autoupdatingCurrent,
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            }

            if snapshot.hasTemperatureData {
                Text(temperatureShiftCopy(snapshot.temperatureShiftStatus))
                    .font(
                        Font.custom(
                            "Chalkboard SE",
                            size: 12,
                            relativeTo: .footnote
                        )
                    )
                    .foregroundStyle(Prompt24Palette.burgundy.opacity(0.70))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func symptomsTab(
        _ snapshot: Prompt24TrendsSnapshot
    ) -> some View {
        let available = Set(snapshot.symptomOccurrences.map(\.symptomID))
        let visible = selectedSymptoms.intersection(available)
        let occurrences = snapshot.symptomOccurrences.filter { visible.contains($0.symptomID) }

        return VStack(alignment: .leading, spacing: 18) {
            symptomToggleGrid(available: available)

            Prompt24MetricSection(
                title: "symptom patterns",
                subtitle: "one timeline using only symptoms you actually logged",
                hasData: !occurrences.isEmpty
            ) {
                Prompt24UnifiedSymptomChart(
                    occurrences: occurrences,
                    selectedSymptoms: visible,
                    reduceMotion: motionPreferences.reduceMotionActive
                )
            }

            ForEach(Array(visible).sorted { $0.displayName < $1.displayName }, id: \.self) { symptom in
                symptomPatternSummary(snapshot.pattern(for: symptom))
            }
        }
    }

    private func symptomToggleGrid(available: Set<Prompt20SymptomID>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("show logged symptoms")
                .font(Font.custom("Chalkboard SE", size: 13, relativeTo: .subheadline))
                .fontWeight(.semibold)

            ForEach(Prompt23SymptomTaxonomy.items.filter { available.contains($0.symptomID) }) { item in
                Button {
                    audioManager.play(.buttonSoftPop)
                    if selectedSymptoms.contains(item.symptomID) {
                        selectedSymptoms.remove(item.symptomID)
                    } else {
                        selectedSymptoms.insert(item.symptomID)
                    }
                } label: {
                    HStack {
                        Text(selectedSymptoms.contains(item.symptomID) ? "●" : "○")
                        Text(item.displayLabel)
                        Spacer()
                    }
                    .font(Font.custom("Chalkboard SE", size: 12.5, relativeTo: .body))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(Prompt24SoftPressButtonStyle(reduceMotion: motionPreferences.reduceMotionActive))
                .accessibilityLabel(item.displayLabel)
                .accessibilityValue(selectedSymptoms.contains(item.symptomID) ? "shown" : "hidden")
            }
        }
    }

    private func symptomPatternSummary(
        _ pattern: Prompt24SymptomPattern
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            switch pattern.status {
            case .insufficientData:
                Text("your patterns will grow here ♡")
            case .unsupported:
                Text(
                    "no recurring timing pattern is supported yet from the completed cycles available."
                )
            case .developing:
                Text(
                    "there are a few repeated observations, but not enough consistent timing to call this a supported pattern."
                )
            case .supported:
                if let start = pattern.windowStartDay,
                   let end = pattern.windowEndDay {
                    Text(
                        "you’ve logged this around a similar time in your cycle before — days \(start)–\(end) appeared in \(pattern.cyclesMatched) of \(pattern.cyclesEvaluated) eligible cycles."
                    )
                } else {
                    Text(
                        "you’ve logged this around a similar time in your cycle before."
                    )
                }
            }

            if pattern.cyclesEvaluated > 0 {
                Text(
                    "\(pattern.cyclesMatched) of \(pattern.cyclesEvaluated) eligible completed cycles"
                )
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 11,
                        relativeTo: .caption
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.60))
            }
        }
        .font(
            Font.custom(
                "Chalkboard SE",
                size: 13,
                relativeTo: .body
            )
        )
        .foregroundStyle(Prompt24Palette.burgundy.opacity(0.82))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            Image("cycledecor_sprout")
                .resizable()
                .scaledToFit()
                .frame(width: 54)
                .accessibilityHidden(true)

            Text("opening your trend pages…")
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 13,
                        relativeTo: .body
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.68))
        }
        .frame(maxWidth: .infinity, minHeight: 310)
    }

    private var failureView: some View {
        VStack(spacing: 12) {
            Image("cycle_graph_blank")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 330)
                .accessibilityHidden(true)

            Image("cycledecor_sprout")
                .resizable()
                .scaledToFit()
                .frame(width: 48)
                .accessibilityHidden(true)

            Text("your patterns will grow here ♡")
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 14,
                        relativeTo: .body
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.76))
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private func load() async {
        loadState = .loading

        do {
            let loaded = try await loader.load()
            guard !Task.isCancelled else { return }
            snapshot = loaded
            loadState = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            snapshot = nil
            loadState = .failed

            #if DEBUG
            print("Prompt24TrendsView load failed:", error)
            #endif
        }
    }

    private func temperatureShiftCopy(
        _ status: Prompt24TemperatureShiftStatus
    ) -> String {
        switch status {
        case .unavailable:
            return "temperature points are shown as recorded. no unapproved ovulation or temperature-shift inference is added."
        case .notDetected:
            return "the validated temperature-shift check did not identify a supported shift in the eligible measurements."
        case .detected(let summary):
            return summary
        }
    }
}

private enum Prompt24Palette {
    static let burgundy = Color(
        red: 128.0 / 255.0,
        green: 0,
        blue: 0
    )
}

private struct Prompt24MetricSection<Chart: View>: View {
    let title: String
    let subtitle: String
    let hasData: Bool
    @ViewBuilder let chart: () -> Chart

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 17,
                        relativeTo: .headline
                    )
                )
                .fontWeight(.semibold)
                .foregroundStyle(Prompt24Palette.burgundy)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 11,
                        relativeTo: .caption
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.62))

            if hasData {
                chart()
                    .frame(height: 230)
            } else {
                Prompt24EmptyGraph()
            }
        }
    }
}

private struct Prompt24EmptyGraph: View {
    var body: some View {
        ZStack {
            Image("cycle_graph_blank")
                .resizable()
                .scaledToFit()
                .opacity(0.88)

            VStack(spacing: 3) {
                Image("cycledecor_sprout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48)
                    .accessibilityHidden(true)

                Text("your patterns will grow here ♡")
                    .font(
                        Font.custom(
                            "Chalkboard SE",
                            size: 13,
                            relativeTo: .body
                        )
                    )
                    .foregroundStyle(Prompt24Palette.burgundy.opacity(0.72))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 230)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("your patterns will grow here")
    }
}

private enum Prompt24LongTermLayout {
    static let pointSpacing: CGFloat = 58
    static let minimumPlotWidth: CGFloat = 320
    static let symptomRowSpacing: CGFloat = 28
    static let minimumSymptomHeight: CGFloat = 184

    static func plotWidth(
        pointCount: Int,
        viewportWidth: CGFloat,
        includesPrediction: Bool = false
    ) -> CGFloat {
        let representedCount = pointCount + (includesPrediction ? 1 : 0)
        let spacingWidth = CGFloat(max(representedCount - 1, 0)) * pointSpacing + 76
        return max(viewportWidth, minimumPlotWidth, spacingWidth)
    }

    static func symptomHeight(
        cycleRowCount: Int,
        viewportHeight: CGFloat
    ) -> CGFloat {
        let rowsHeight = CGFloat(max(cycleRowCount, 1)) * symptomRowSpacing + 58
        return max(viewportHeight, minimumSymptomHeight, rowsHeight)
    }
}

private struct Prompt24CycleLengthChart: View {
    let points: [Prompt24CycleLengthPoint]
    let median: Double?
    let prediction: Prompt24PredictionMarker?
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { viewport in
            let plotWidth = Prompt24LongTermLayout.plotWidth(
                pointCount: points.count,
                viewportWidth: viewport.size.width,
                includesPrediction: prediction != nil
            )

            ScrollView(.horizontal, showsIndicators: false) {
                GeometryReader { proxy in
                    let values = points.map { Double($0.days) }
                    let predicted = prediction.map { Double($0.estimatedCycleLength) }
                    let domain = Prompt24ChartMath.domain(
                        values + [predicted].compactMap { $0 },
                        minimumSpan: 4
                    )

                    ZStack {
                        Prompt24GraphPaper()

                        Canvas { context, size in
                            guard !points.isEmpty else { return }
                            let frame = Prompt24ChartMath.plotFrame(in: size)
                            let count = points.count + (prediction == nil ? 0 : 1)

                            var line = Path()
                            for (index, point) in points.enumerated() {
                                let x = Prompt24ChartMath.x(
                                    index: index,
                                    count: count,
                                    frame: frame
                                )
                                let y = Prompt24ChartMath.y(
                                    value: Double(point.days),
                                    domain: domain,
                                    frame: frame
                                )
                                if index == 0 {
                                    line.move(to: CGPoint(x: x, y: y))
                                } else {
                                    line.addLine(to: CGPoint(x: x, y: y))
                                }
                            }

                            context.stroke(
                                line,
                                with: .color(Prompt24Palette.burgundy.opacity(0.62)),
                                style: StrokeStyle(
                                    lineWidth: 1.6,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )

                            if let median {
                                let y = Prompt24ChartMath.y(
                                    value: median,
                                    domain: domain,
                                    frame: frame
                                )
                                var medianPath = Path()
                                medianPath.move(to: CGPoint(x: frame.minX, y: y))
                                medianPath.addLine(to: CGPoint(x: frame.maxX, y: y))
                                context.stroke(
                                    medianPath,
                                    with: .color(Prompt24Palette.burgundy.opacity(0.28)),
                                    style: StrokeStyle(
                                        lineWidth: 1,
                                        dash: [4, 4]
                                    )
                                )
                            }

                            if let prediction {
                                let index = points.count
                                let x = Prompt24ChartMath.x(
                                    index: index,
                                    count: count,
                                    frame: frame
                                )
                                let y = Prompt24ChartMath.y(
                                    value: Double(prediction.estimatedCycleLength),
                                    domain: domain,
                                    frame: frame
                                )

                                let rect = CGRect(
                                    x: x - 4,
                                    y: y - 4,
                                    width: 8,
                                    height: 8
                                )

                                context.stroke(
                                    Path(ellipseIn: rect),
                                    with: .color(Prompt24Palette.burgundy.opacity(0.48)),
                                    style: StrokeStyle(
                                        lineWidth: 1.4,
                                        dash: [2, 2]
                                    )
                                )
                            }
                        }

                        Prompt24AxisLabels(
                            x: "completed cycles →",
                            y: "days"
                        )

                        ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                            let frame = Prompt24ChartMath.plotFrame(in: proxy.size)
                            let count = points.count + (prediction == nil ? 0 : 1)
                            let x = Prompt24ChartMath.x(
                                index: index,
                                count: count,
                                frame: frame
                            )
                            let y = Prompt24ChartMath.y(
                                value: Double(point.days),
                                domain: domain,
                                frame: frame
                            )

                            Circle()
                                .fill(Prompt24Palette.burgundy.opacity(0.74))
                                .frame(width: 7, height: 7)
                                .position(x: x, y: y)
                                .accessibilityLabel(
                                    "Cycle \(point.cycleIndex), \(point.days) days"
                                )
                        }
                    }
                    .opacity(reduceMotion ? 1 : 1)
                }
                .frame(width: plotWidth, height: viewport.size.height)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Cycle length graph. \(points.count) completed cycles. Swipe horizontally to review long-term history."
        )
    }
}

private struct Prompt24PeriodLengthChart: View {
    let points: [Prompt24PeriodLengthPoint]
    let median: Double?
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { viewport in
            let plotWidth = Prompt24LongTermLayout.plotWidth(
                pointCount: points.count,
                viewportWidth: viewport.size.width
            )

            ScrollView(.horizontal, showsIndicators: false) {
                GeometryReader { proxy in
                    let values = points.map { Double($0.days) }
                    let domain = Prompt24ChartMath.domain(values, minimumSpan: 3)

                    ZStack {
                        Prompt24GraphPaper()

                        Canvas { context, size in
                            let frame = Prompt24ChartMath.plotFrame(in: size)

                            for (index, point) in points.enumerated() {
                                let x = Prompt24ChartMath.x(
                                    index: index,
                                    count: points.count,
                                    frame: frame
                                )
                                let y = Prompt24ChartMath.y(
                                    value: Double(point.days),
                                    domain: domain,
                                    frame: frame
                                )

                                var stem = Path()
                                stem.move(to: CGPoint(x: x, y: frame.maxY))
                                stem.addLine(to: CGPoint(x: x, y: y))

                                context.stroke(
                                    stem,
                                    with: .color(Prompt24Palette.burgundy.opacity(0.36)),
                                    style: StrokeStyle(lineWidth: 1.4, lineCap: .round)
                                )

                                context.fill(
                                    Path(
                                        ellipseIn: CGRect(
                                            x: x - 3.5,
                                            y: y - 3.5,
                                            width: 7,
                                            height: 7
                                        )
                                    ),
                                    with: .color(Prompt24Palette.burgundy.opacity(0.72))
                                )
                            }

                            if let median {
                                let y = Prompt24ChartMath.y(
                                    value: median,
                                    domain: domain,
                                    frame: frame
                                )
                                var path = Path()
                                path.move(to: CGPoint(x: frame.minX, y: y))
                                path.addLine(to: CGPoint(x: frame.maxX, y: y))
                                context.stroke(
                                    path,
                                    with: .color(Prompt24Palette.burgundy.opacity(0.26)),
                                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                                )
                            }
                        }

                        Prompt24AxisLabels(
                            x: "completed periods →",
                            y: "days"
                        )

                        ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                            let frame = Prompt24ChartMath.plotFrame(in: proxy.size)
                            let x = Prompt24ChartMath.x(
                                index: index,
                                count: points.count,
                                frame: frame
                            )
                            let y = Prompt24ChartMath.y(
                                value: Double(point.days),
                                domain: domain,
                                frame: frame
                            )

                            Text("\(point.days) days")
                                .font(
                                    Font.custom(
                                        "Chalkboard SE",
                                        size: 10,
                                        relativeTo: .caption2
                                    )
                                )
                                .fontWeight(.semibold)
                                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.82))
                                .fixedSize()
                                .position(
                                    x: x,
                                    y: max(frame.minY + 8, y - 13)
                                )
                                .accessibilityLabel(
                                    "Completed period \(index + 1), \(point.days) days"
                                )
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        "Period length graph. \(points.count) complete recorded periods. Swipe horizontally to review long-term history."
                    )
                }
                .frame(width: plotWidth, height: viewport.size.height)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }
}

private struct Prompt24BBTChart: View {
    let points: [Prompt24BBTPoint]
    let displayUnit: Prompt20TemperatureUnit
    let calendar: Calendar
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { viewport in
            let plotWidth = Prompt24LongTermLayout.plotWidth(
                pointCount: points.count,
                viewportWidth: viewport.size.width
            )

            ScrollView(.horizontal, showsIndicators: false) {
                GeometryReader { proxy in
                    let values = points.map { $0.value(in: displayUnit) }
                    let domain = Prompt24ChartMath.domain(
                        values,
                        minimumSpan: displayUnit == .fahrenheit ? 1.0 : 0.55
                    )

                    ZStack {
                        Prompt24GraphPaper()

                        Canvas { context, size in
                            let frame = Prompt24ChartMath.plotFrame(in: size)

                            for index in points.indices {
                                let point = points[index]
                                let x = Prompt24ChartMath.x(
                                    index: index,
                                    count: points.count,
                                    frame: frame
                                )
                                let y = Prompt24ChartMath.y(
                                    value: point.value(in: displayUnit),
                                    domain: domain,
                                    frame: frame
                                )

                                context.fill(
                                    Path(
                                        ellipseIn: CGRect(
                                            x: x - 3.2,
                                            y: y - 3.2,
                                            width: 6.4,
                                            height: 6.4
                                        )
                                    ),
                                    with: .color(Prompt24Palette.burgundy.opacity(0.70))
                                )

                                guard index > 0 else { continue }
                                let previous = points[index - 1]
                                let gap = calendar.dateComponents(
                                    [.day],
                                    from: previous.date,
                                    to: point.date
                                ).day

                                guard gap == 1 else { continue }

                                let previousX = Prompt24ChartMath.x(
                                    index: index - 1,
                                    count: points.count,
                                    frame: frame
                                )
                                let previousY = Prompt24ChartMath.y(
                                    value: previous.value(in: displayUnit),
                                    domain: domain,
                                    frame: frame
                                )

                                var segment = Path()
                                segment.move(
                                    to: CGPoint(x: previousX, y: previousY)
                                )
                                segment.addLine(
                                    to: CGPoint(x: x, y: y)
                                )

                                context.stroke(
                                    segment,
                                    with: .color(Prompt24Palette.burgundy.opacity(0.50)),
                                    style: StrokeStyle(
                                        lineWidth: 1.4,
                                        lineCap: .round
                                    )
                                )
                            }
                        }

                        Prompt24AxisLabels(
                            x: "recorded dates →",
                            y: displayUnit.symbol
                        )
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(
                        Prompt24Format.bbtAccessibility(points, unit: displayUnit)
                        + " Swipe horizontally to review long-term history."
                    )
                }
                .frame(width: plotWidth, height: viewport.size.height)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }
}

private struct Prompt24UnifiedSymptomChart: View {
    let occurrences: [Prompt24SymptomOccurrence]
    let selectedSymptoms: Set<Prompt20SymptomID>
    let reduceMotion: Bool

    var body: some View {
        let symptoms = Array(selectedSymptoms).sorted { $0.displayName < $1.displayName }
        let maxDay = max(occurrences.compactMap(\.cycleDay).max() ?? 1, 1)
        GeometryReader { viewport in
            let plotWidth = max(viewport.size.width, Prompt24LongTermLayout.minimumPlotWidth, CGFloat(max(maxDay - 1, 0)) * 18 + 120)
            let plotHeight = max(viewport.size.height, CGFloat(max(symptoms.count, 1)) * 44 + 76)
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                ZStack {
                    Prompt24GraphPaper()
                    Canvas { context, size in
                        let frame = Prompt24ChartMath.plotFrame(in: size)
                        for occurrence in occurrences {
                            guard let day = occurrence.cycleDay,
                                  let row = symptoms.firstIndex(of: occurrence.symptomID) else { continue }
                            let x = frame.minX + CGFloat(max(day - 1, 0)) / CGFloat(max(maxDay - 1, 1)) * frame.width
                            let y = frame.minY + CGFloat(row + 1) / CGFloat(symptoms.count + 1) * frame.height
                            let rect = CGRect(x: x - 4.2, y: y - 4.2, width: 8.4, height: 8.4)
                            context.fill(Path(ellipseIn: rect), with: .color(Prompt24Palette.burgundy.opacity(0.68)))
                        }
                    }
                    ForEach(Array(symptoms.enumerated()), id: \.element) { row, symptom in
                        Text(symptom.displayName)
                            .font(Font.custom("Chalkboard SE", size: 9, relativeTo: .caption2))
                            .foregroundStyle(Prompt24Palette.burgundy.opacity(0.72))
                            .position(x: 52, y: 24 + CGFloat(row + 1) / CGFloat(symptoms.count + 1) * max(plotHeight - 48, 1))
                    }
                    Prompt24AxisLabels(x: "recorded cycle day →", y: "logged symptoms")
                }
                .frame(width: plotWidth, height: plotHeight)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Unified symptom timeline using only logged observations. \(occurrences.count) recorded occurrences are shown.")
            }
        }
    }
}

private struct Prompt24AxisLabels: View {
    let x: String
    let y: String

    var body: some View {
        GeometryReader { proxy in
            let frame = Prompt24ChartMath.plotFrame(in: proxy.size)

            Text(x)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 9,
                        relativeTo: .caption2
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.58))
                .fixedSize()
                .position(
                    x: frame.midX,
                    y: min(proxy.size.height - 8, frame.maxY + 13)
                )

            Text(y)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 9,
                        relativeTo: .caption2
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.58))
                .fixedSize()
                .rotationEffect(.degrees(-90))
                .position(
                    x: max(8, frame.minX - 16),
                    y: frame.midY
                )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Prompt24GraphPaper: View {
    var body: some View {
        ZStack {
            Image("cycle_graph_blank")
                .resizable()
                .scaledToFill()
                .opacity(0.80)
                .clipped()

            Prompt24Grid()
                .stroke(
                    Prompt24Palette.burgundy.opacity(0.10),
                    style: StrokeStyle(lineWidth: 0.7)
                )
                .padding(.horizontal, 26)
                .padding(.vertical, 22)
        }
        .accessibilityHidden(true)
    }
}

private struct Prompt24Grid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        for step in 0...4 {
            let fraction = CGFloat(step) / 4
            let y = rect.minY + rect.height * fraction
            path.move(to: CGPoint(x: rect.minX, y: y))
            path.addLine(to: CGPoint(x: rect.maxX, y: y))
        }

        return path
    }
}

private struct Prompt24Underline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(
                x: rect.minX + rect.width * 0.30,
                y: rect.minY
            ),
            control2: CGPoint(
                x: rect.minX + rect.width * 0.72,
                y: rect.maxY
            )
        )
        return path
    }
}

private struct Prompt24TinyStat: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 13,
                        relativeTo: .subheadline
                    )
                )
                .fontWeight(.semibold)
                .foregroundStyle(Prompt24Palette.burgundy)

            Text(title)
                .font(
                    Font.custom(
                        "Chalkboard SE",
                        size: 10,
                        relativeTo: .caption2
                    )
                )
                .foregroundStyle(Prompt24Palette.burgundy.opacity(0.60))
        }
    }
}

private struct Prompt24SoftPressButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (configuration.isPressed ? 0.965 : 1)
            )
            .offset(
                y:
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? 1.5 : 0)
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (configuration.isPressed ? -0.25 : 0)
                )
            )
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(
                reduceMotion
                    ? .easeOut(duration: 0.08)
                    : .spring(
                        response: 0.22,
                        dampingFraction: 0.70,
                        blendDuration: 0
                    ),
                value: configuration.isPressed
            )
    }
}

private enum Prompt24ChartMath {
    static func plotFrame(in size: CGSize) -> CGRect {
        CGRect(
            x: 28,
            y: 22,
            width: max(1, size.width - 50),
            height: max(1, size.height - 46)
        )
    }

    static func domain(
        _ values: [Double],
        minimumSpan: Double
    ) -> ClosedRange<Double> {
        guard let low = values.min(),
              let high = values.max()
        else {
            return 0...minimumSpan
        }

        let center = (low + high) / 2
        let observedSpan = max(high - low, minimumSpan)
        let padding = observedSpan * 0.16

        let lowerBound =
            center - observedSpan / 2 - padding
        let upperBound =
            center + observedSpan / 2 + padding

        return lowerBound...upperBound
    }

    static func x(
        index: Int,
        count: Int,
        frame: CGRect
    ) -> CGFloat {
        guard count > 1 else {
            return frame.midX
        }

        return frame.minX
            + CGFloat(index)
            / CGFloat(count - 1)
            * frame.width
    }

    static func y(
        value: Double,
        domain: ClosedRange<Double>,
        frame: CGRect
    ) -> CGFloat {
        let span = max(domain.upperBound - domain.lowerBound, 0.0001)
        let fraction = (value - domain.lowerBound) / span
        return frame.maxY - CGFloat(fraction) * frame.height
    }
}

private enum Prompt24Format {
    static func days(_ value: Double) -> String {
        if value.rounded() == value {
            return "\(Int(value)) days"
        }

        return String(format: "%.1f days", value)
    }

    static func bbtAccessibility(
        _ points: [Prompt24BBTPoint],
        unit: Prompt20TemperatureUnit
    ) -> String {
        let values = points.map {
            Prompt20TemperatureFormatter.string(
                $0.value(in: unit),
                unit: unit
            )
        }

        if values.isEmpty {
            return "Basal body temperature graph. No recorded measurements."
        }

        return "Basal body temperature graph. \(points.count) recorded measurements. Values: \(values.joined(separator: ", ")) \(unit.symbol)."
    }
}
