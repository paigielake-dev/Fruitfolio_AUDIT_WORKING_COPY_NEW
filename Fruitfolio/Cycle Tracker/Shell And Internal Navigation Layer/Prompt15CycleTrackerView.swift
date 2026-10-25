import SwiftUI

struct Prompt15CycleTrackerView: View {
    let onBack: () -> Void

    @State private var selectedSection: Prompt15CycleSection = .today
    @State private var predictionLearningInfo:
        Prompt16PredictionLearningInfo?
    @State private var dailyLogRequest: Prompt20DailyLogRequest?
    @State private var dailyLogHasUnsavedChanges = false
    @State private var calendarRefreshID = UUID()
    @State private var bodyDetail: Prompt22BodyDetail = .bodyBiology

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager
    @EnvironmentObject private var contextStore: Prompt27AContextStore

    private var contextPolicy: Prompt27AContextPolicyResult {
        Prompt27AContextPolicyEngine().policy(for: contextStore.context)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                globalBackRow

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        header

                        Prompt15CycleNavigation(
                            selectedSection: selectedSection,
                            onSelect: select
                        )
                        .padding(.top, 24)

                        HStack {
                            Spacer()

                            Image("decor_leaves")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 104)
                                .rotationEffect(.degrees(5))
                                .opacity(0.88)
                                .offset(x: 18, y: -3)
                                .accessibilityHidden(true)
                        }
                        .frame(height: 48)
                        .padding(.top, 2)

                        contentRegion
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: 560, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
            }

            if let predictionLearningInfo {
                Prompt15PredictionInfoOverlay(
                    info: predictionLearningInfo,
                    onDismiss: dismissPredictionInfo
                )
                .transition(
                    motionPreferences.reduceMotionActive
                        ? .opacity
                        : .opacity.combined(
                            with: .scale(scale: 0.97)
                        )
                )
                .zIndex(50)
            }
        }
        .animation(
            motionPreferences.reduceMotionActive
                ? nil
                : .easeOut(duration: 0.20),
            value: predictionLearningInfo
        )
        .sheet(item: $dailyLogRequest, onDismiss: {
            dailyLogHasUnsavedChanges = false
        }) { request in
            Prompt20DailyLogView(
                selectedDate: request.selectedDate,
                initialExpandedSection: request.initialSection,
                onSaved: { _ in
                    // Recreate only the calendar presentation after a secured local
                    // save so Phase 19 reloads the existing metadata hierarchy.
                    // This does not touch prediction calculations or calendar art.
                    calendarRefreshID = UUID()
                },
                onDirtyStateChange: { isDirty in
                    dailyLogHasUnsavedChanges = isDirty
                }
            )
            .interactiveDismissDisabled(dailyLogHasUnsavedChanges)
        }
        .onChange(of: dailyLogRequest) { _, request in
            if request == nil {
                dailyLogHasUnsavedChanges = false
            }
        }
        .background(
            Prompt15Palette.paper
                .ignoresSafeArea()
        )
        .navigationBarBackButtonHidden(true)
    }

    private var globalBackRow: some View {
        HStack {
            BackControl {
                onBack()
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 10) {
                Text("cycle tracker")
                    .font(Prompt15Type.title)
                    .foregroundStyle(Prompt15Palette.burgundy)
                    .accessibilityAddTraits(.isHeader)

                Image("decor_moon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(5))
                    .accessibilityHidden(true)

                Spacer(minLength: 0)
            }

            Text("your cycle, with the biology underneath")
                .font(Prompt15Type.subtitle)
                .foregroundStyle(
                    Prompt15Palette.burgundy.opacity(0.76)
                )
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var contentRegion: some View {
        Group {
            switch selectedSection {
            case .today:
                Prompt16TodayView(
                    context: contextStore.context,
                    contextPolicy: contextPolicy,
                    onSeeBiology: {
                        select(.body)
                    },
                    onLogToday: {
                        openDailyLog(
                            date: Date(),
                            section: nil
                        )
                    },
                    onLogBBT: {
                        openDailyLog(
                            date: Date(),
                            section: .temperature
                        )
                    },
                    onPredictionInfoRequested: { info in
                        predictionLearningInfo = info
                    }
                )

            case .calendar:
                Prompt19CalendarView(
                    loader: Prompt19CalendarLoader(
                        supplementalProvider:
                            Prompt20CalendarIntegration
                                .supplementalProvider()
                    ),
                    context: contextStore.context,
                    contextPolicy: contextPolicy
                ) { action in
                    switch action {
                    case .logSymptoms(let date):
                        openDailyLog(
                            date: date,
                            section: .symptoms
                        )

                    case .addTemperature(let date):
                        openDailyLog(
                            date: date,
                            section: .temperature
                        )

                    case .addNote(let date):
                        openDailyLog(
                            date: date,
                            section: .notes
                        )

                    case .seeBiology:
                        select(.body)
                    }
                }
                .id(calendarRefreshID)

            case .body:
                VStack(alignment: .leading, spacing: 18) {
                    Prompt22BodyDetailNavigation(
                        selection: bodyDetail
                    ) { detail in
                        if !motionPreferences.reduceMotionActive {
                            withAnimation(.easeOut(duration: 0.20)) {
                                bodyDetail = detail
                            }
                        } else {
                            bodyDetail = detail
                        }
                    }

                    Group {
                        switch bodyDetail {
                        case .bodyBiology:
                            Prompt21BodyBiologyView()
                        case .hormoneRhythm:
                            Prompt22HormoneRhythmView(
                                context: contextStore.context,
                                contextPolicy: contextPolicy
                            )
                        }
                    }
                    .id(bodyDetail)
                    .transition(.opacity)
                }

            case .symptoms:
                Prompt23SymptomsView(
                    activeDate: Date(),
                    contextPolicy: contextPolicy,
                    onSaved: {
                        calendarRefreshID = UUID()
                    }
                )

            case .trends:
                Prompt24TrendsView(contextPolicy: contextPolicy)
            }
        }
        .id(selectedSection)
        .transition(.opacity)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func openDailyLog(
        date: Date,
        section: Prompt20DailyLogSection?
    ) {
        dailyLogHasUnsavedChanges = false
        dailyLogRequest = Prompt20DailyLogRequest(
            selectedDate: date,
            initialSection: section
        )
    }

    private func dismissPredictionInfo() {
        audioManager.play(.buttonSoftPop)

        if motionPreferences.reduceMotionActive {
            predictionLearningInfo = nil
        } else {
            withAnimation(.easeOut(duration: 0.18)) {
                predictionLearningInfo = nil
            }
        }
    }

    private func select(
        _ section: Prompt15CycleSection
    ) {
        guard section != selectedSection else {
            return
        }

        audioManager.play(.buttonSoftPop)

        if motionPreferences.reduceMotionActive {
            selectedSection = section
        } else {
            withAnimation(
                .easeInOut(duration: 0.22)
            ) {
                selectedSection = section
            }
        }
    }
}

private struct Prompt15PredictionInfoOverlay: View {
    let info: Prompt16PredictionLearningInfo
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Prompt15Palette.paper
                .opacity(0.82)
                .ignoresSafeArea()

            Prompt15Palette.burgundy
                .opacity(0.055)
                .ignoresSafeArea()

            Prompt15WoodenPredictionPopup(
                info: info,
                onDismiss: onDismiss
            )
            .padding(.horizontal, 18)
        }
        .ignoresSafeArea()
    }
}

private struct Prompt15WoodenPredictionPopup: View {
    let info: Prompt16PredictionLearningInfo
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let signWidth = min(
                356,
                max(
                    292,
                    proxy.size.width - 44
                )
            )

            let signHeight =
                signWidth * (517.0 / 594.0)

            ZStack {
                Image("popup_wooden_sign")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: signWidth,
                        height: signHeight
                    )
                    .accessibilityHidden(true)

                VStack(spacing: 5) {
                    FruitfolioImage(
                        id: .fruit_peach_soft
                    )
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .accessibilityHidden(true)

                    Text(info.title)
                        .font(
                            Prompt15Type.popupTitle
                        )
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .foregroundStyle(Prompt15Palette.burgundy)

                    Text(info.body)
                        .font(
                            Prompt15Type.popupBody
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.78)
                        .foregroundStyle(Prompt15Palette.burgundy)

                    Text(info.progress)
                        .font(
                            Prompt15Type.popupProgress
                        )
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.76)
                        .foregroundStyle(Prompt15Palette.burgundy)

                    Button {
                        onDismiss()
                    } label: {
                        Text("got it ♡")
                            .font(
                                Prompt15Type.popupButton
                            )
                            .fontWeight(.semibold)
                            .foregroundStyle(Prompt15Palette.burgundy)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(
                        Prompt15SoftPressButtonStyle()
                    )
                    .accessibilityHint(
                        "Closes this explanation."
                    )
                }
                .frame(
                    width: signWidth * 0.70,
                    height: signHeight * 0.61,
                    alignment: .center
                )
                .offset(
                    y: signHeight * 0.105
                )
            }
            .frame(
                width: signWidth,
                height: signHeight
            )
            .position(
                x: proxy.size.width / 2,
                y: proxy.size.height / 2
            )
            .accessibilityElement(
                children: .contain
            )
            .accessibilityLabel(
                "\(info.title). \(info.body) \(info.progress)"
            )
        }
    }
}

private struct Prompt15SignHanger: View {
    let width: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let height =
                proxy.size.height

            ZStack {
                Prompt15SignRope(
                    start: CGPoint(
                        x: width * 0.50,
                        y: height * 0.15
                    ),
                    end: CGPoint(
                        x: width * 0.22,
                        y: height * 0.98
                    ),
                    width: width
                )

                Prompt15SignRope(
                    start: CGPoint(
                        x: width * 0.50,
                        y: height * 0.15
                    ),
                    end: CGPoint(
                        x: width * 0.78,
                        y: height * 0.98
                    ),
                    width: width
                )

                Prompt15SignNail()
                    .frame(
                        width: width * 0.065,
                        height: width * 0.065
                    )
                    .position(
                        x: width * 0.50,
                        y: height * 0.15
                    )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Prompt15PredictionPlank<
    Content: View
>: View {
    let variant: Int
    let width: CGFloat
    let minimumHeight: CGFloat
    let hasScrews: Bool
    let content: Content

    init(
        variant: Int,
        width: CGFloat,
        minimumHeight: CGFloat,
        hasScrews: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.width = width
        self.minimumHeight = minimumHeight
        self.hasScrews = hasScrews
        self.content = content()
    }

    var body: some View {
        ZStack {
            Prompt15WoodPlank(
                variant: variant,
                hasScrews: hasScrews
            )

            content
                .frame(
                    maxWidth: .infinity
                )
        }
        .frame(width: width)
        .frame(minHeight: minimumHeight)
        .fixedSize(
            horizontal: false,
            vertical: true
        )
        .rotationEffect(
            .degrees(
                variant == 0
                    ? -0.22
                    : (
                        variant == 1
                            ? 0.16
                            : -0.12
                    )
            )
        )
    }
}

private struct Prompt15SignRope: View {
    let start: CGPoint
    let end: CGPoint
    let width: CGFloat

    var body: some View {
        ZStack {
            Prompt15RopePath(
                start: start,
                end: end,
                bend: 0
            )
            .stroke(
                Color(
                    red: 0.45,
                    green: 0.28,
                    blue: 0.13
                )
                .opacity(0.82),
                style: StrokeStyle(
                    lineWidth:
                        width * 0.021,
                    lineCap: .round
                )
            )

            Prompt15RopePath(
                start: start,
                end: end,
                bend: 0.004
            )
            .stroke(
                Color(
                    red: 0.72,
                    green: 0.48,
                    blue: 0.23
                )
                .opacity(0.78),
                style: StrokeStyle(
                    lineWidth:
                        width * 0.010,
                    lineCap: .round,
                    dash: [
                        width * 0.025,
                        width * 0.020
                    ]
                )
            )

            Prompt15RopePath(
                start: start,
                end: end,
                bend: -0.004
            )
            .stroke(
                Color.white.opacity(0.18),
                style: StrokeStyle(
                    lineWidth:
                        width * 0.004,
                    lineCap: .round,
                    dash: [
                        width * 0.018,
                        width * 0.026
                    ]
                )
            )
        }
    }
}

private struct Prompt15RopePath: Shape {
    let start: CGPoint
    let end: CGPoint
    let bend: CGFloat

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        path.move(
            to: start
        )

        let dx =
            end.x - start.x

        let dy =
            end.y - start.y

        path.addCurve(
            to: end,
            control1: CGPoint(
                x:
                    start.x
                    + dx * 0.32
                    + rect.width * bend,
                y:
                    start.y
                    + dy * 0.32
            ),
            control2: CGPoint(
                x:
                    start.x
                    + dx * 0.68
                    - rect.width * bend,
                y:
                    start.y
                    + dy * 0.68
            )
        )

        return path
    }
}

private struct Prompt15SignNail: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    Color(
                        red: 0.20,
                        green: 0.18,
                        blue: 0.16
                    )
                )

            Circle()
                .stroke(
                    Color.black.opacity(
                        0.42
                    ),
                    lineWidth: 1.25
                )

            Capsule()
                .fill(
                    Color.black.opacity(
                        0.45
                    )
                )
                .frame(
                    width: 3,
                    height: 17
                )
                .rotationEffect(
                    .degrees(-38)
                )
        }
        .shadow(
            color:
                Color.black.opacity(
                    0.14
                ),
            radius: 2,
            y: 1
        )
        .opacity(0.84)
    }
}

private struct Prompt15WoodPlank: View {
    let variant: Int
    let hasScrews: Bool

    var body: some View {
        GeometryReader { proxy in
            let width =
                proxy.size.width

            let height =
                proxy.size.height

            ZStack {
                Prompt15WoodPlankShape(
                    variant: variant
                )
                .fill(
                    Color(
                        red: 0.92,
                        green: 0.69,
                        blue: 0.43
                    )
                    .opacity(0.88)
                )

                Prompt15WoodPlankShape(
                    variant: variant
                )
                .fill(
                    Color(
                        red: 0.98,
                        green: 0.82,
                        blue: 0.58
                    )
                    .opacity(0.24)
                )
                .scaleEffect(
                    x: 0.986,
                    y: 0.88
                )
                .offset(
                    x: -width * 0.012,
                    y: -height * 0.035
                )
                .blur(radius: 2.6)

                Prompt15WoodPlankShape(
                    variant: variant
                )
                .fill(
                    Color(
                        red: 0.69,
                        green: 0.39,
                        blue: 0.20
                    )
                    .opacity(0.09)
                )
                .scaleEffect(
                    x: 0.974,
                    y: 0.72
                )
                .offset(
                    x: width * 0.016,
                    y: height * 0.10
                )
                .blur(radius: 4)

                Prompt15WoodPigmentClouds(
                    variant: variant
                )
                .clipShape(
                    Prompt15WoodPlankShape(
                        variant: variant
                    )
                )
                .opacity(0.80)

                Prompt15WoodGrain(
                    variant: variant
                )
                .stroke(
                    Color(
                        red: 0.55,
                        green: 0.31,
                        blue: 0.17
                    )
                    .opacity(0.10),
                    style: StrokeStyle(
                        lineWidth: 0.9,
                        lineCap: .round
                    )
                )
                .padding(
                    .horizontal,
                    width * 0.045
                )
                .padding(
                    .vertical,
                    height * 0.19
                )

                Prompt15WoodPlankShape(
                    variant: variant
                )
                .stroke(
                    Color(
                        red: 0.55,
                        green: 0.31,
                        blue: 0.18
                    )
                    .opacity(0.22),
                    lineWidth: 1
                )

                Prompt15WoodPlankShape(
                    variant: variant
                )
                .stroke(
                    Color(
                        red: 0.75,
                        green: 0.49,
                        blue: 0.27
                    )
                    .opacity(0.12),
                    lineWidth: 2.2
                )
                .blur(radius: 1.2)

                if hasScrews {
                    HStack {
                        Prompt15WoodScrew()

                        Spacer()

                        Prompt15WoodScrew()
                    }
                    .padding(
                        .horizontal,
                        width * 0.105
                    )
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

private struct Prompt15WoodPigmentClouds: View {
    let variant: Int

    var body: some View {
        GeometryReader { proxy in
            let width =
                proxy.size.width

            let height =
                proxy.size.height

            ZStack {
                Ellipse()
                    .fill(
                        Color.white.opacity(
                            0.10
                        )
                    )
                    .frame(
                        width:
                            width * 0.58,
                        height:
                            height * 0.55
                    )
                    .offset(
                        x:
                            variant == 1
                            ? -width * 0.16
                            : width * 0.10,
                        y:
                            -height * 0.12
                    )
                    .blur(radius: 10)

                Ellipse()
                    .fill(
                        Color(
                            red: 0.67,
                            green: 0.38,
                            blue: 0.19
                        )
                        .opacity(0.08)
                    )
                    .frame(
                        width:
                            width * 0.48,
                        height:
                            height * 0.52
                    )
                    .offset(
                        x:
                            variant == 2
                            ? width * 0.17
                            : -width * 0.12,
                        y:
                            height * 0.16
                    )
                    .blur(radius: 12)

                Ellipse()
                    .fill(
                        Color(
                            red: 1,
                            green: 0.86,
                            blue: 0.65
                        )
                        .opacity(0.12)
                    )
                    .frame(
                        width:
                            width * 0.36,
                        height:
                            height * 0.40
                    )
                    .offset(
                        x:
                            width * 0.02,
                        y:
                            -height * 0.03
                    )
                    .blur(radius: 8)
            }
        }
        .blendMode(.multiply)
    }
}

private struct Prompt15WatercolorBloom: View {
    let seed: Int

    var body: some View {
        GeometryReader { proxy in
            let width =
                proxy.size.width

            let height =
                proxy.size.height

            ZStack {
                Ellipse()
                    .fill(
                        Color.white.opacity(
                            0.09
                        )
                    )
                    .frame(
                        width:
                            width * 0.82,
                        height:
                            height * 0.72
                    )
                    .offset(
                        x:
                            seed.isMultiple(
                                of: 2
                            )
                            ? -width * 0.05
                            : width * 0.04,
                        y:
                            -height * 0.05
                    )
                    .blur(radius: 8)

                Ellipse()
                    .fill(
                        Color(
                            red: 0.65,
                            green: 0.36,
                            blue: 0.18
                        )
                        .opacity(0.07)
                    )
                    .frame(
                        width:
                            width * 0.74,
                        height:
                            height * 0.60
                    )
                    .offset(
                        x:
                            seed == 1
                            ? -width * 0.08
                            : width * 0.06,
                        y:
                            height * 0.08
                    )
                    .blur(radius: 10)
            }
        }
        .blendMode(.multiply)
        .opacity(0.72)
    }
}

private struct Prompt15WoodScrew: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    Color(
                        red: 0.55,
                        green: 0.32,
                        blue: 0.15
                    )
                )

            Circle()
                .stroke(
                    Color(
                        red: 0.39,
                        green: 0.20,
                        blue: 0.10
                    )
                    .opacity(0.58),
                    lineWidth: 1
                )

            Rectangle()
                .fill(
                    Color(
                        red: 0.35,
                        green: 0.17,
                        blue: 0.08
                    )
                    .opacity(0.70)
                )
                .frame(
                    width: 2,
                    height: 9
                )
                .rotationEffect(
                    .degrees(-35)
                )
        }
        .frame(
            width: 17,
            height: 17
        )
        .opacity(0.78)
    }
}

private struct Prompt15WoodPlankShape: Shape {
    let variant: Int

    func path(
        in rect: CGRect
    ) -> Path {
        let top: [CGFloat]
        let bottom: [CGFloat]

        switch variant % 3 {
        case 1:
            top = [
                0.09,
                0.02,
                0.06,
                0.01,
                0.07,
                0.03,
                0.08
            ]

            bottom = [
                0.91,
                0.97,
                0.93,
                0.99,
                0.92,
                0.96,
                0.90
            ]

        case 2:
            top = [
                0.05,
                0.09,
                0.02,
                0.07,
                0.03,
                0.08,
                0.04
            ]

            bottom = [
                0.95,
                0.90,
                0.98,
                0.92,
                0.97,
                0.91,
                0.96
            ]

        default:
            top = [
                0.07,
                0.02,
                0.08,
                0.03,
                0.06,
                0.01,
                0.07
            ]

            bottom = [
                0.94,
                0.98,
                0.91,
                0.97,
                0.92,
                0.99,
                0.93
            ]
        }

        var path = Path()

        let steps =
            top.count - 1

        path.move(
            to: CGPoint(
                x: rect.minX,
                y:
                    rect.minY
                    + rect.height * top[0]
            )
        )

        for index in 1...steps {
            let fraction =
                CGFloat(index)
                / CGFloat(steps)

            path.addLine(
                to: CGPoint(
                    x:
                        rect.minX
                        + rect.width * fraction,
                    y:
                        rect.minY
                        + rect.height
                        * top[index]
                )
            )
        }

        for index in stride(
            from: steps,
            through: 0,
            by: -1
        ) {
            let fraction =
                CGFloat(index)
                / CGFloat(steps)

            path.addLine(
                to: CGPoint(
                    x:
                        rect.minX
                        + rect.width * fraction,
                    y:
                        rect.minY
                        + rect.height
                        * bottom[index]
                )
            )
        }

        path.closeSubpath()

        return path
    }
}

private struct Prompt15WoodGrain: Shape {
    let variant: Int

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        let lines = 5

        for line in 0..<lines {
            let y =
                rect.minY
                + rect.height
                * (
                    CGFloat(line + 1)
                    / CGFloat(lines + 1)
                )

            let wobble =
                rect.height
                * (
                    variant.isMultiple(
                        of: 2
                    )
                    ? 0.028
                    : 0.020
                )

            path.move(
                to: CGPoint(
                    x: rect.minX,
                    y: y
                )
            )

            path.addCurve(
                to: CGPoint(
                    x: rect.maxX,
                    y:
                        y
                        + wobble * 0.25
                ),
                control1: CGPoint(
                    x:
                        rect.minX
                        + rect.width * 0.30,
                    y:
                        y - wobble
                ),
                control2: CGPoint(
                    x:
                        rect.minX
                        + rect.width * 0.72,
                    y:
                        y + wobble
                )
            )
        }

        return path
    }
}

private struct Prompt15SoftPressButtonStyle:
    ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                    ? 0.965
                    : 1
            )
            .animation(
                .easeOut(
                    duration: 0.10
                ),
                value:
                    configuration.isPressed
            )
    }
}

private struct Prompt15BubblePopButtonStyle:
    ButtonStyle {

    let reduceMotion: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        configuration.isPressed
                            ? 0.965
                            : 1
                    )
            )
            .offset(
                y:
                    reduceMotion
                    ? 0
                    : (
                        configuration.isPressed
                            ? 1.5
                            : 0
                    )
            )
            .rotationEffect(
                .degrees(
                    reduceMotion
                        ? 0
                        : (
                            configuration.isPressed
                                ? -0.25
                                : 0
                        )
                )
            )
            .brightness(
                configuration.isPressed
                    ? -0.04
                    : 0
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.08
                    )
                    : .spring(
                        response: 0.22,
                        dampingFraction: 0.70,
                        blendDuration: 0
                    ),
                value:
                    configuration.isPressed
            )
    }
}

private struct Prompt15CycleNavigation: View {
    let selectedSection:
        Prompt15CycleSection

    let onSelect:
        (Prompt15CycleSection) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(
                Prompt15CycleSection.allCases
            ) { section in
                Prompt15CycleTab(
                    section: section,
                    selected:
                        selectedSection
                        == section
                ) {
                    onSelect(section)
                }
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .accessibilityElement(
            children: .contain
        )
        .accessibilityLabel(
            "Cycle Tracker sections"
        )
    }
}

private struct Prompt15CycleTab: View {
    let section: Prompt15CycleSection
    let selected: Bool
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(
                    section.rawValue
                )
                .font(
                    Prompt15Type.tab
                )
                .fontWeight(
                    selected
                        ? .semibold
                        : .regular
                )
                .foregroundStyle(
                    Prompt15Palette
                        .burgundy
                        .opacity(
                            selected
                                ? 1
                                : 0.78
                        )
                )
                .lineLimit(1)
                .minimumScaleFactor(
                    0.94
                )
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )

                ZStack {
                    Color.clear
                        .frame(
                            height: 7
                        )

                    if selected {
                        Prompt15WatercolorWash()
                            .transition(
                                .opacity
                            )
                    }
                }
                .frame(height: 7)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: 44
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            Prompt15BubblePopButtonStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
        .accessibilityLabel(
            section.rawValue
        )
        .accessibilityValue(
            selected
                ? "selected"
                : "not selected"
        )
        .accessibilityAddTraits(
            selected
                ? .isSelected
                : []
        )
        .animation(
            motionPreferences
                .reduceMotionActive
                ? nil
                : .easeInOut(
                    duration: 0.22
                ),
            value: selected
        )
    }
}

private struct Prompt15WatercolorWash: View {
    var body: some View {
        GeometryReader { proxy in
            let width = max(
                proxy.size.width,
                1
            )

            let height = max(
                proxy.size.height,
                1
            )

            ZStack {
                Prompt15WatercolorWashShape(
                    variant: 0
                )
                .fill(
                    Prompt15Palette
                        .cycleWash
                        .opacity(0.25)
                )
                .frame(
                    width: width,
                    height:
                        height * 0.72
                )
                .offset(
                    y: height * 0.08
                )

                Prompt15WatercolorWashShape(
                    variant: 1
                )
                .fill(
                    Prompt15Palette
                        .cycleWash
                        .opacity(0.18)
                )
                .frame(
                    width:
                        width * 0.96,
                    height:
                        height * 0.56
                )
                .offset(
                    x:
                        width * 0.01,
                    y:
                        height * 0.18
                )

                Prompt15WatercolorWashShape(
                    variant: 2
                )
                .fill(
                    Prompt15Palette
                        .cycleWash
                        .opacity(0.12)
                )
                .frame(
                    width:
                        width * 0.90,
                    height:
                        height * 0.42
                )
                .offset(
                    x:
                        -width * 0.015,
                    y:
                        height * 0.24
                )
            }
        }
        .frame(height: 7)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Prompt15WatercolorWashShape:
    Shape {

    let variant: Int

    func path(
        in rect: CGRect
    ) -> Path {
        let v =
            variant % 3

        let topOffsets:
            [[CGFloat]] = [
                [
                    0.38,
                    0.20,
                    0.32,
                    0.16,
                    0.28,
                    0.22,
                    0.36
                ],
                [
                    0.28,
                    0.34,
                    0.18,
                    0.30,
                    0.20,
                    0.38,
                    0.24
                ],
                [
                    0.34,
                    0.16,
                    0.26,
                    0.36,
                    0.18,
                    0.30,
                    0.22
                ]
            ]

        let bottomOffsets:
            [[CGFloat]] = [
                [
                    0.70,
                    0.82,
                    0.74,
                    0.88,
                    0.76,
                    0.84,
                    0.68
                ],
                [
                    0.78,
                    0.66,
                    0.86,
                    0.72,
                    0.82,
                    0.70,
                    0.80
                ],
                [
                    0.72,
                    0.88,
                    0.76,
                    0.68,
                    0.84,
                    0.74,
                    0.82
                ]
            ]

        let top =
            topOffsets[v]

        let bottom =
            bottomOffsets[v]

        let steps =
            top.count - 1

        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y:
                    rect.minY
                    + rect.height
                    * top[0]
            )
        )

        for index in 1...steps {
            let fraction =
                CGFloat(index)
                / CGFloat(steps)

            path.addLine(
                to: CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * fraction,
                    y:
                        rect.minY
                        + rect.height
                        * top[index]
                )
            )
        }

        for index in stride(
            from: steps,
            through: 0,
            by: -1
        ) {
            let fraction =
                CGFloat(index)
                / CGFloat(steps)

            path.addLine(
                to: CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * fraction,
                    y:
                        rect.minY
                        + rect.height
                        * bottom[index]
                )
            )
        }

        path.closeSubpath()

        return path
    }
}

private enum Prompt22BodyDetail: String, CaseIterable, Identifiable {
    case bodyBiology = "body biology"
    case hormoneRhythm = "hormone rhythm"

    var id: String { rawValue }
}

private struct Prompt22BodyDetailNavigation: View {
    let selection: Prompt22BodyDetail
    let onSelect: (Prompt22BodyDetail) -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    @EnvironmentObject
    private var audioManager:
        AudioManager

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Prompt22BodyDetail.allCases) { detail in
                Button {
                    audioManager.play(.buttonSoftPop)
                    onSelect(detail)
                } label: {
                    VStack(spacing: 4) {
                        Text(detail.rawValue)
                            .font(
                                Font.custom(
                                    "Chalkboard SE",
                                    size: 13,
                                    relativeTo: .subheadline
                                )
                            )
                            .fontWeight(
                                selection == detail
                                    ? .semibold
                                    : .regular
                            )
                            .foregroundStyle(
                                Color(
                                    red: 128.0 / 255.0,
                                    green: 0,
                                    blue: 0
                                )
                                .opacity(
                                    selection == detail
                                        ? 1
                                        : 0.70
                                )
                            )

                        Prompt22BodyDetailUnderline()
                            .fill(
                                Color(
                                    red: 128.0 / 255.0,
                                    green: 0,
                                    blue: 0
                                )
                                .opacity(
                                    selection == detail
                                        ? 0.24
                                        : 0
                                )
                            )
                            .frame(height: 4)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(
                    Prompt15BubblePopButtonStyle(
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive
                    )
                )
                .accessibilityValue(
                    selection == detail
                        ? "selected"
                        : "not selected"
                )
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Body education sections")
    }
}

private struct Prompt22BodyDetailUnderline: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x: rect.minX,
                y: rect.midY
            )
        )
        path.addCurve(
            to: CGPoint(
                x: rect.maxX,
                y: rect.midY + 0.2
            ),
            control1: CGPoint(
                x: rect.width * 0.30,
                y: rect.midY - 1.0
            ),
            control2: CGPoint(
                x: rect.width * 0.72,
                y: rect.midY + 1.0
            )
        )
        path.addLine(
            to: CGPoint(
                x: rect.maxX - 1,
                y: rect.maxY - 0.8
            )
        )
        path.addCurve(
            to: CGPoint(
                x: rect.minX + 1,
                y: rect.maxY - 1.2
            ),
            control1: CGPoint(
                x: rect.width * 0.70,
                y: rect.maxY
            ),
            control2: CGPoint(
                x: rect.width * 0.25,
                y: rect.maxY - 0.2
            )
        )
        path.closeSubpath()

        return path
    }
}

private struct Prompt15PhaseContentAnchor:
    View {

    let section:
        Prompt15CycleSection

    let accessibilityDescription:
        String

    var body: some View {
        Color.clear
            .frame(
                maxWidth: .infinity,
                minHeight: 360
            )
            .accessibilityElement()
            .accessibilityLabel(
                accessibilityDescription
            )
            .accessibilityIdentifier(
                "prompt15.\(section.rawValue).content"
            )
    }
}

private enum Prompt15Palette {
    static let burgundy =
        Color(
            red:
                128.0 / 255.0,
            green: 0,
            blue: 0
        )

    static let paper =
        DesignTokens
            .ColorToken
            .backgroundCream

    static let cycleWash =
        Color(
            red: 0.91,
            green: 0.47,
            blue: 0.49
        )
}

private enum Prompt15Type {
    static let title =
        Font.custom(
            "Chalkboard SE",
            size: 31,
            relativeTo: .title
        )
        .weight(.bold)

    static let subtitle =
        Font.custom(
            "Chalkboard SE",
            size: 14,
            relativeTo: .subheadline
        )

    static let tab =
        Font.custom(
            "Chalkboard SE",
            size: 14,
            relativeTo: .subheadline
        )

    static let popupTitle =
        Font.custom(
            "Chalkboard SE",
            size: 15,
            relativeTo: .headline
        )

    static let popupBody =
        Font.custom(
            "Chalkboard SE",
            size: 11.5,
            relativeTo: .caption
        )

    static let popupProgress =
        Font.custom(
            "Chalkboard SE",
            size: 10.5,
            relativeTo: .caption2
        )

    static let popupButton =
        Font.custom(
            "Chalkboard SE",
            size: 11.5,
            relativeTo: .caption
        )
}

#Preview {
    let settings =
        SettingsStore()

    Prompt15CycleTrackerView(
        onBack: {}
    )
    .environmentObject(
        MotionPreferences()
    )
    .environmentObject(
        AudioManager(
            settings: settings
        )
    )
}












