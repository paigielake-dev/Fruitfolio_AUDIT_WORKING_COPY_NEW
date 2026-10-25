import SwiftUI

struct Prompt19CalendarView: View {
    var loader: Prompt19CalendarLoader
    var context: Prompt27AUserReproductiveContext
    var contextPolicy: Prompt27AContextPolicyResult
    let onAction: (Prompt19CalendarAction) -> Void

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    @State private var displayedMonth: Prompt19CalendarMonth
    @State private var selectedKey: Prompt19CalendarDateKey?
    @State private var snapshot: Prompt19CalendarSnapshot
    @State private var loadState: Prompt19CalendarLoadState = .idle
    @State private var monthDrift: CGFloat = 0
    @State private var showPredictionNote = false
    @State private var pendingAction: Prompt19CalendarAction?

    private let calendar: Calendar

    init(
        loader: Prompt19CalendarLoader? = nil,
        context: Prompt27AUserReproductiveContext = .unspecified,
        contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult(),
        initialDate: Date = Date(),
        onAction: @escaping (Prompt19CalendarAction) -> Void
    ) {
        let resolvedLoader = loader ?? Prompt19CalendarLoader()
        self.loader = resolvedLoader
        self.context = context
        self.contextPolicy = contextPolicy
        self.onAction = onAction

        var calendar = resolvedLoader.todayLoader.calendar
        calendar.firstWeekday = 1
        self.calendar = calendar

        let month = Prompt19CalendarMonth(
            containing: initialDate,
            calendar: calendar
        )

        _displayedMonth = State(initialValue: month)
        _snapshot = State(initialValue: .empty(month: month))
    }

    private var engine: Prompt19CalendarEngine {
        Prompt19CalendarEngine(calendar: calendar)
    }

    private var model: Prompt19CalendarMonthModel {
        engine.buildMonth(
            month: displayedMonth,
            annotations: snapshot.annotations,
            today: Date(),
            selected: selectedKey
        )
    }

    private var contextClarification: String? {
        Prompt27AContextPresentationCopy.calendarClarification(
            context: context,
            policy: contextPolicy
        )
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Prompt19CalendarPaperFrame()

            VStack(spacing: 0) {
                monthHeader
                    .padding(.top, 58)
                    .padding(.horizontal, 18)
                    .padding(.bottom, contextClarification == nil ? 12 : 5)

                if let contextClarification {
                    Text(contextClarification)
                        .font(Prompt19Type.footnote)
                        .foregroundStyle(
                            Prompt19Palette.burgundy.opacity(0.70)
                        )
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 8)
                        .accessibilityLabel(contextClarification)
                }

                weekdayHeader
                    .padding(.horizontal, 18)
                    .padding(.bottom, 7)

                calendarGrid
                    .padding(.horizontal, 18)
                    .offset(x: monthDrift)
                    .opacity(loadState == .loading ? 0.70 : 1)

                Spacer(minLength: 10)

                ZStack(alignment: .bottomLeading) {
                    if case .failed = loadState {
                        failureMessage
                            .padding(.leading, 104)
                            .padding(.trailing, 18)
                    } else if snapshot.annotations.isEmpty {
                        earlyStateMessage
                            .padding(.leading, 104)
                            .padding(.trailing, 18)
                    }

                    Prompt19BubbleDecoration()
                        .padding(.leading, 14)
                        .padding(.bottom, 4)
                }
                .frame(height: 82)
            }

            Image("decor_rainbow")
                .resizable()
                .scaledToFit()
                .frame(width: 76)
                .rotationEffect(.degrees(-7))
                .offset(x: 10, y: 7)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .task(id: displayedMonth) {
            await loadMonth()
        }
        .sheet(
            isPresented: Binding(
                get: {
                    selectedKey != nil
                },
                set: {
                    if !$0 {
                        selectedKey = nil
                    }
                }
            ),
            onDismiss: {
                guard let action = pendingAction else {
                    return
                }

                pendingAction = nil
                onAction(action)
            }
        ) {
            if let selectedDateKey = selectedKey {
                Prompt19DateSheet(
                    key: selectedDateKey,
                    annotation: snapshot.annotations[selectedDateKey],
                    calendar: calendar,
                    showPredictionNote: showPredictionNote,
                    onDismiss: {
                        selectedKey = nil
                        showPredictionNote = false
                    },
                    onAction: { action in
                        audioManager.play(.buttonSoftPop)
                        pendingAction = action
                        selectedKey = nil
                        showPredictionNote = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(.clear)
            }
        }
        .accessibilityIdentifier("prompt19.calendar")
    }

    private var monthHeader: some View {
        HStack(spacing: 8) {
            Prompt19MonthControl(
                assetName: "control_previous",
                label: "previous"
            ) {
                shiftMonth(-1)
            }

            Spacer(minLength: 2)

            Prompt19Heart()
                .fill(Prompt19Palette.heart.opacity(0.78))
                .frame(width: 16, height: 15)
                .rotationEffect(.degrees(-7))
                .accessibilityHidden(true)

            Text(engine.monthTitle(displayedMonth))
                .font(Prompt19Type.monthTitle)
                .foregroundStyle(Prompt19Palette.burgundy)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background {
                    Prompt19WatercolorBlob(
                        variant: displayedMonth.month
                    )
                    .fill(
                        Prompt19Palette.headerMint.opacity(0.60)
                    )
                }
                .accessibilityAddTraits(.isHeader)

            Prompt19Heart()
                .fill(Prompt19Palette.heart.opacity(0.78))
                .frame(width: 16, height: 15)
                .rotationEffect(.degrees(7))
                .accessibilityHidden(true)

            Spacer(minLength: 2)

            Prompt19MonthControl(
                assetName: "control_next",
                label: "next"
            ) {
                shiftMonth(1)
            }
        }
        .frame(minHeight: 50)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(
                Array(
                    [
                        "S",
                        "M",
                        "T",
                        "W",
                        "T",
                        "F",
                        "S"
                    ].enumerated()
                ),
                id: \.offset
            ) { _, weekday in
                Text(weekday)
                    .font(Prompt19Type.weekday)
                    .foregroundStyle(
                        Prompt19Palette.teal.opacity(0.92)
                    )
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var calendarGrid: some View {
        GeometryReader { proxy in
            let width = max(
                proxy.size.width,
                1
            )

            let columnWidth =
                width / 7.0

            let cellHeight =
                min(
                    max(
                        columnWidth * 1.05,
                        42
                    ),
                    54
                )

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(
                        .flexible(),
                        spacing: 0
                    ),
                    count: 7
                ),
                spacing: 3
            ) {
                ForEach(
                    Array(
                        model.cells.enumerated()
                    ),
                    id: \.offset
                ) { _, cell in
                    Prompt19DateCell(
                        cell: cell,
                        engine: engine,
                        cellHeight: cellHeight,
                        onSelect: select
                    )
                }
            }
        }
        .frame(
            height: gridHeight
        )
        .animation(
            motionPreferences.reduceMotionActive
                ? nil
                : .easeOut(
                    duration: 0.20
                ),
            value: selectedKey
        )
    }

    private var gridHeight: CGFloat {
        CGFloat(
            max(
                model.weekRowCount,
                1
            )
        ) * 59
    }

    private var earlyStateMessage: some View {
        Text(
            "predictions will appear here as Fruitfolio learns from the cycle history you log."
        )
        .font(
            Prompt19Type.footnote
        )
        .foregroundStyle(
            Prompt19Palette
                .burgundy
                .opacity(0.62)
        )
        .multilineTextAlignment(
            .center
        )
        .padding(
            .horizontal,
            28
        )
        .fixedSize(
            horizontal: false,
            vertical: true
        )
    }

    private var failureMessage: some View {
        Text(
            "this calendar page couldn’t refresh just yet. your saved cycle data is still safe."
        )
        .font(
            Prompt19Type.footnote
        )
        .foregroundStyle(
            Prompt19Palette
                .burgundy
                .opacity(0.70)
        )
        .multilineTextAlignment(
            .center
        )
        .padding(
            .horizontal,
            24
        )
        .fixedSize(
            horizontal: false,
            vertical: true
        )
    }

    private func select(
        _ cell: Prompt19CalendarCell
    ) {
        guard
            cell.isInteractive,
            let key = cell.key
        else {
            return
        }

        audioManager.play(
            .buttonSoftPop
        )

        selectedKey = key

        if cell.annotation?.containsEstimate == true {
            showPredictionNote = true
        } else {
            showPredictionNote = false
        }
    }

    private func shiftMonth(
        _ delta: Int
    ) {
        guard let next =
            displayedMonth.shifted(
                by: delta,
                calendar: calendar
            )
        else {
            return
        }

        audioManager.play(
            .buttonSoftPop
        )

        selectedKey = nil
        showPredictionNote = false

        if motionPreferences.reduceMotionActive {
            displayedMonth = next
            monthDrift = 0
            return
        }

        let direction: CGFloat =
            delta > 0
                ? -3
                : 3

        withAnimation(
            .easeOut(
                duration: 0.10
            )
        ) {
            monthDrift = direction
        }

        displayedMonth = next

        withAnimation(
            .easeOut(
                duration: 0.20
            )
        ) {
            monthDrift = 0
        }
    }

    @MainActor
    private func loadMonth() async {
        loadState = .loading

        do {
            let loaded =
                try await loader.load(
                    month: displayedMonth
                )

            guard !Task.isCancelled else {
                return
            }

            snapshot = loaded
            loadState = .loaded
        } catch {
            guard !Task.isCancelled else {
                return
            }

            snapshot = .empty(
                month: displayedMonth
            )

            loadState = .failed(
                String(
                    describing: error
                )
            )
        }
    }
}

private struct Prompt19DateCell: View {
    let cell: Prompt19CalendarCell
    let engine: Prompt19CalendarEngine
    let cellHeight: CGFloat
    let onSelect:
        (Prompt19CalendarCell) -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    @State
    private var hovering = false

    var body: some View {
        Group {
            if cell.isInteractive {
                Button {
                    onSelect(cell)
                } label: {
                    content
                }
                .buttonStyle(
                    Prompt19DatePressStyle(
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive
                    )
                )
                .onHover {
                    hovering = $0
                }
                .brightness(
                    hovering
                        ? 0.015
                        : 0
                )
                .accessibilityLabel(
                    engine.accessibilityLabel(
                        for: cell
                    )
                )
                .accessibilityHint(
                    "Opens this date."
                )
            } else {
                Color.clear
                    .frame(
                        maxWidth: .infinity,
                        minHeight: cellHeight
                    )
                    .accessibilityHidden(
                        true
                    )
            }
        }
    }

    private var content: some View {
        ZStack {
            if cell.isInteractive {
                Prompt19WatercolorBlob(
                    variant:
                        (cell.dateNumber ?? 0)
                        + 20
                )
                .fill(
                    Prompt19Palette
                        .dayPink
                        .opacity(0.30)
                )
                .padding(2.5)
            }

            primaryWash

            if cell.annotation?
                .predictedPeriod == true,
               cell.annotation?
                .recordedPeriod != true {
                Prompt19PredictedPeriodOutline()
                    .padding(5)
            }

            boundary

            VStack(
                spacing: 2
            ) {
                Text(
                    cell.dateNumber.map(
                        String.init
                    ) ?? ""
                )
                .font(
                    Prompt19Type.dateNumber
                )
                .foregroundStyle(
                    Prompt19Palette.burgundy
                )
                .frame(
                    minHeight: 20
                )

                primarySymbol
                    .frame(
                        height: 11
                    )

                metadataRow
                    .frame(
                        height: 10
                    )
            }
            .padding(
                .vertical,
                4
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: cellHeight
        )
        .contentShape(
            Rectangle()
        )
    }

    @ViewBuilder
    private var primaryWash: some View {
        switch cell.annotation?
            .primaryState
            ?? .none {

        case .recordedPeriod:
            Prompt19WatercolorBlob(
                variant:
                    cell.dateNumber
                    ?? 0
            )
            .fill(
                Prompt19Palette
                    .period
                    .opacity(0.23)
            )
            .padding(4)

        case .fertileEstimate:
            Prompt19WatercolorBlob(
                variant:
                    (cell.dateNumber ?? 0)
                    + 1
            )
            .fill(
                Prompt19Palette
                    .fertile
                    .opacity(0.20)
            )
            .padding(4)

        case .ovulationEstimate:
            Prompt19WatercolorBlob(
                variant:
                    (cell.dateNumber ?? 0)
                    + 2
            )
            .fill(
                Prompt19Palette
                    .mint
                    .opacity(0.18)
            )
            .padding(5)

        case .predictedPeriod,
             .none:
            Color.clear
        }
    }

    @ViewBuilder
    private var boundary: some View {
        if cell.isSelected {
            Prompt19HandDrawnRing(
                variant:
                    cell.dateNumber
                    ?? 0
            )
            .stroke(
                Prompt19Palette
                    .burgundy
                    .opacity(0.80),
                lineWidth: 1.6
            )
            .padding(2.5)

        } else if cell.isToday {
            Prompt19HandDrawnRing(
                variant:
                    cell.dateNumber
                    ?? 0
            )
            .stroke(
                Prompt19Palette
                    .burgundy
                    .opacity(0.48),
                lineWidth: 0.9
            )
            .padding(4)
        }
    }

    @ViewBuilder
    private var primarySymbol: some View {
        if cell.annotation?
            .recordedPeriod == true {

            Prompt19Droplet()
                .fill(
                    Prompt19Palette
                        .coral
                        .opacity(0.78)
                )
                .frame(
                    width: 6.5,
                    height: 8
                )
                .accessibilityHidden(
                    true
                )

        } else if cell.annotation?
            .ovulationEstimated == true {

            Circle()
                .fill(
                    Prompt19Palette
                        .mint
                        .opacity(0.82)
                )
                .frame(
                    width: 6,
                    height: 6
                )
                .accessibilityHidden(
                    true
                )

        } else if cell.annotation?
            .fertileEstimated == true {

            Prompt19TinyFlower()
                .stroke(
                    Prompt19Palette
                        .olive
                        .opacity(0.74),
                    lineWidth: 0.8
                )
                .frame(
                    width: 9,
                    height: 9
                )
                .accessibilityHidden(
                    true
                )

        } else {
            Color.clear
        }
    }

    private var metadataRow: some View {
        HStack(
            spacing: 3
        ) {
            ForEach(
                cell.annotation?
                    .visibleMetadata
                    ?? [],
                id: \.self
            ) { kind in
                switch kind {

                case .symptom:
                    Circle()
                        .fill(
                            Prompt19Palette
                                .coral
                                .opacity(0.78)
                        )
                        .frame(
                            width: 5.5,
                            height: 5.5
                        )

                case .bbt:
                    Image(
                        "cycle_bbt_thermometer"
                    )
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 9,
                        height: 9
                    )

                case .note:
                    Prompt19BookmarkMark()
                        .fill(
                            Prompt19Palette
                                .burgundy
                                .opacity(0.60)
                        )
                        .frame(
                            width: 6,
                            height: 8
                        )
                }
            }
        }
        .accessibilityHidden(
            true
        )
    }
}

private struct Prompt19DateSheet: View {
    let key:
        Prompt19CalendarDateKey

    let annotation:
        Prompt19CalendarDayAnnotation?

    let calendar:
        Calendar

    let showPredictionNote:
        Bool

    let onDismiss:
        () -> Void

    let onAction:
        (Prompt19CalendarAction) -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    private var engine:
        Prompt19CalendarEngine {
        Prompt19CalendarEngine(
            calendar: calendar
        )
    }

    private var date: Date? {
        key.date(
            in: calendar
        )
    }

    var body: some View {
        ZStack(
            alignment: .topTrailing
        ) {
            Prompt19Palette.paper
                .ignoresSafeArea()

            ScrollView {
                VStack(
                    alignment: .leading,
                    spacing: 15
                ) {
                    Text(
                        engine.displayDateTitle(
                            key
                        )
                    )
                    .font(
                        Prompt19Type.sheetTitle
                    )
                    .foregroundStyle(
                        Prompt19Palette.burgundy
                    )
                    .accessibilityAddTraits(
                        .isHeader
                    )

                    if let cycleDay =
                        annotation?.cycleDay {
                        Text(
                            "cycle day \(cycleDay)"
                        )
                        .font(
                            Prompt19Type
                                .sheetSubhead
                        )
                        .foregroundStyle(
                            Prompt19Palette
                                .burgundy
                                .opacity(0.70)
                        )
                    }

                    estimateLabels

                    if showPredictionNote {
                        Prompt19PredictionTransparencyNote()
                            .padding(
                                .vertical,
                                2
                            )
                    }

                    recordedSections

                    if let date {
                        actionGrid(
                            date: date
                        )
                        .padding(
                            .top,
                            2
                        )
                    }
                }
                .padding(
                    .horizontal,
                    24
                )
                .padding(
                    .top,
                    30
                )
                .padding(
                    .bottom,
                    36
                )
            }

            Button(
                action: onDismiss
            ) {
                Image(
                    "control_close"
                )
                .resizable()
                .scaledToFit()
                .frame(
                    width: 28,
                    height: 28
                )
                .frame(
                    width: 44,
                    height: 44
                )
                .contentShape(
                    Rectangle()
                )
            }
            .buttonStyle(
                .plain
            )
            .accessibilityLabel(
                "close"
            )
            .padding(
                .top,
                9
            )
            .padding(
                .trailing,
                12
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
        )
    }

    @ViewBuilder
    private var estimateLabels:
        some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {
            if annotation?
                .recordedPeriod == true {

                Text(
                    "period recorded"
                )
                .font(
                    Prompt19Type.stateLabel
                )

            } else {
                if annotation?
                    .predictedPeriod == true {

                    Text(
                        "predicted period"
                    )
                    .font(
                        Prompt19Type.stateLabel
                    )
                }

                if annotation?
                    .fertileEstimated == true {

                    Text(
                        "estimated fertile window ✿"
                    )
                    .font(
                        Prompt19Type.stateLabel
                    )
                }

                if annotation?
                    .ovulationEstimated == true {

                    Text(
                        "estimated ovulation"
                    )
                    .font(
                        Prompt19Type.stateLabel
                    )
                }
            }
        }
        .foregroundStyle(
            Prompt19Palette
                .burgundy
                .opacity(0.76)
        )
    }

    @ViewBuilder
    private var recordedSections:
        some View {

        VStack(
            alignment: .leading,
            spacing: 13
        ) {
            if annotation?
                .recordedPeriod == true {

                Prompt19SheetSection(
                    title: "period",
                    value: "recorded"
                )
            }

            if let symptoms =
                annotation?.symptomSummary,
               !symptoms.isEmpty {

                Prompt19SheetSection(
                    title: "symptoms",
                    value:
                        symptoms.joined(
                            separator: " · "
                        )
                )

            } else if annotation?
                .symptomsLogged == true {

                Prompt19SheetSection(
                    title: "symptoms",
                    value: "logged"
                )
            }

            if let temperature =
                annotation?
                    .temperatureDisplay {

                Prompt19SheetSection(
                    title: "temperature",
                    value: temperature
                )

            } else if annotation?
                .bbtRecorded == true {

                Prompt19SheetSection(
                    title: "temperature",
                    value: "recorded"
                )
            }

            if let note =
                annotation?.noteText,
               !note
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
                .isEmpty {

                Prompt19SheetSection(
                    title: "note",
                    value: note
                )
            }
        }
    }

    private func actionGrid(
        date: Date
    ) -> some View {
        VStack(
            spacing: 9
        ) {
            Prompt19SheetActionButton(
                title: "log symptoms",
                kind: .symptoms
            ) {
                onAction(
                    .logSymptoms(
                        date
                    )
                )
            }

            Prompt19SheetActionButton(
                title: "add temperature",
                kind: .temperature
            ) {
                onAction(
                    .addTemperature(
                        date
                    )
                )
            }

            Prompt19SheetActionButton(
                title: "add note",
                kind: .note
            ) {
                onAction(
                    .addNote(
                        date
                    )
                )
            }

            Prompt19SheetActionButton(
                title: "see biology",
                kind: .biology
            ) {
                onAction(
                    .seeBiology(
                        date
                    )
                )
            }
        }
    }
}

private struct Prompt19SheetSection:
    View {

    let title: String
    let value: String

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            Text(
                title
            )
            .font(
                Prompt19Type.sectionLabel
            )
            .foregroundStyle(
                Prompt19Palette
                    .burgundy
                    .opacity(0.60)
            )

            Text(
                value
            )
            .font(
                Prompt19Type.sheetBody
            )
            .foregroundStyle(
                Prompt19Palette
                    .burgundy
                    .opacity(0.86)
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
        }
    }
}

private enum Prompt19SheetActionKind {
    case symptoms
    case temperature
    case note
    case biology
}

private struct Prompt19SheetActionButton:
    View {

    let title: String
    let kind: Prompt19SheetActionKind
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    var body: some View {
        Button(
            action: action
        ) {
            HStack(
                spacing: 10
            ) {
                icon
                    .frame(
                        width: 22,
                        height: 22
                    )

                Text(
                    title
                )
                .font(
                    Prompt19Type.action
                )
                .foregroundStyle(
                    Prompt19Palette.burgundy
                )

                Spacer()
            }
            .padding(
                .horizontal,
                15
            )
            .frame(
                minHeight: 48
            )
            .background(
                Prompt19WatercolorBlob(
                    variant:
                        title.count
                )
                .fill(
                    actionFill
                        .opacity(0.17)
                )
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            Prompt19GentlePressStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
    }

    @ViewBuilder
    private var icon: some View {
        switch kind {

        case .symptoms:
            Prompt19TinyFlower()
                .stroke(
                    Prompt19Palette
                        .coral
                        .opacity(0.74),
                    lineWidth: 1.1
                )

        case .temperature:
            Image(
                "cycle_bbt_thermometer"
            )
            .resizable()
            .scaledToFit()

        case .note:
            Prompt19BookmarkMark()
                .fill(
                    Prompt19Palette
                        .burgundy
                        .opacity(0.62)
                )
                .padding(5)

        case .biology:
            Image(
                "ask_question_mark"
            )
            .resizable()
            .scaledToFit()
        }
    }

    private var actionFill:
        Color {

        switch kind {

        case .symptoms:
            return Prompt19Palette.coral

        case .temperature:
            return Prompt19Palette.dustyBlue

        case .note:
            return Prompt19Palette.peach

        case .biology:
            return Prompt19Palette.sage
        }
    }
}

private struct Prompt19PredictionTransparencyNote:
    View {

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 8
        ) {
            Image(
                "fruit_blueberry_friendly"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 42
            )
            .accessibilityHidden(
                true
            )

            Text(
                "tiny note these dates are estimates based on what you’ve logged. ✿"
            )
            .font(
                Prompt19Type.note
            )
            .foregroundStyle(
                Prompt19Palette
                    .burgundy
                    .opacity(0.78)
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )
            .padding(
                .vertical,
                10
            )
            .padding(
                .horizontal,
                12
            )
            .background(
                Prompt19WatercolorBlob(
                    variant: 4
                )
                .fill(
                    Prompt19Palette
                        .paper
                        .opacity(0.92)
                )
            )
        }
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            "Tiny note: these dates are estimates based on what you’ve logged."
        )
    }
}

private struct Prompt19MonthControl:
    View {

    let assetName: String
    let label: String
    let action: () -> Void

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    var body: some View {
        Button(
            action: action
        ) {
            VStack(
                spacing: 2
            ) {
                Image(
                    assetName
                )
                .resizable()
                .scaledToFit()
                .frame(
                    width: 22,
                    height: 22
                )

                Text(
                    label
                )
                .font(
                    Prompt19Type.microControl
                )
                .foregroundStyle(
                    Prompt19Palette
                        .coral
                        .opacity(0.74)
                )
            }
            .frame(
                minWidth: 48,
                minHeight: 44
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            Prompt19GentlePressStyle(
                reduceMotion:
                    motionPreferences
                        .reduceMotionActive
            )
        )
        .accessibilityLabel(
            label
        )
    }
}

// MARK: - Watercolor calendar shell

private struct Prompt19CalendarPaperFrame:
    View {

    var body: some View {
        ZStack(
            alignment: .top
        ) {
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                Prompt19Palette.paper
            )

            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Prompt19Palette
                    .teal
                    .opacity(0.72),
                lineWidth: 2.2
            )

            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
            .stroke(
                Prompt19Palette
                    .teal
                    .opacity(0.25),
                lineWidth: 1
            )
            .padding(5)

            HStack(
                spacing: 22
            ) {
                ForEach(
                    0..<7,
                    id: \.self
                ) { index in
                    Prompt19BindingRing()
                        .stroke(
                            Prompt19Palette
                                .teal
                                .opacity(0.88),
                            style:
                                StrokeStyle(
                                    lineWidth: 3.2,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                        )
                        .frame(
                            width: 26,
                            height: 34
                        )
                        .rotationEffect(
                            .degrees(
                                index
                                    .isMultiple(
                                        of: 2
                                    )
                                    ? -2
                                    : 2
                            )
                        )
                }
            }
            .padding(
                .top,
                -11
            )
        }
        .shadow(
            color:
                Prompt19Palette
                    .teal
                    .opacity(0.07),
            radius: 10,
            x: 0,
            y: 5
        )
        .accessibilityHidden(
            true
        )
        .allowsHitTesting(
            false
        )
    }
}

// MARK: - Interactive bubble decoration

private struct Prompt19BubbleDecoration:
    View {

    @EnvironmentObject
    private var motionPreferences:
        MotionPreferences

    @EnvironmentObject
    private var audioManager:
        AudioManager

    @State
    private var scale:
        CGFloat = 1

    @State
    private var rotation:
        Double = 0

    @State
    private var verticalOffset:
        CGFloat = 0

    @State
    private var bounceTask:
        Task<Void, Never>?

    var body: some View {
        Button {
            /*
             Button actions fire on release rather
             than continuously while the pointer or
             finger remains held down.

             That means the entire dramatic bounce
             begins fresh after release regardless
             of how long the user held the bubbles.
            */

            audioManager.play(
                .bubblePop
            )

            performBounce()
        } label: {
            Image(
                "decor_bubbles"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 78
            )
            .scaleEffect(
                scale
            )
            .rotationEffect(
                .degrees(
                    rotation
                )
            )
            .offset(
                y: verticalOffset
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(
            .plain
        )
        .accessibilityLabel(
            "bubbles"
        )
        .accessibilityHint(
            "Plays a bubble pop and bounces the decoration."
        )
        .onDisappear {
            bounceTask?
                .cancel()
        }
    }

    private func performBounce() {
        bounceTask?
            .cancel()

        if motionPreferences
            .reduceMotionActive {

            scale = 1
            rotation = 0
            verticalOffset = 0
            return
        }

        bounceTask =
            Task {
                @MainActor in

                withAnimation(
                    .easeOut(
                        duration: 0.07
                    )
                ) {
                    scale = 0.70
                    rotation = -8
                    verticalOffset = 7
                }

                try? await Task.sleep(
                    for:
                        .milliseconds(
                            70
                        )
                )

                guard !Task.isCancelled
                else {
                    return
                }

                withAnimation(
                    .spring(
                        response: 0.24,
                        dampingFraction: 0.40,
                        blendDuration: 0
                    )
                ) {
                    scale = 1.30
                    rotation = 9
                    verticalOffset = -10
                }

                try? await Task.sleep(
                    for:
                        .milliseconds(
                            170
                        )
                )

                guard !Task.isCancelled
                else {
                    return
                }

                withAnimation(
                    .spring(
                        response: 0.22,
                        dampingFraction: 0.44,
                        blendDuration: 0
                    )
                ) {
                    scale = 0.90
                    rotation = -4
                    verticalOffset = 3
                }

                try? await Task.sleep(
                    for:
                        .milliseconds(
                            135
                        )
                )

                guard !Task.isCancelled
                else {
                    return
                }

                withAnimation(
                    .spring(
                        response: 0.32,
                        dampingFraction: 0.54,
                        blendDuration: 0
                    )
                ) {
                    scale = 1
                    rotation = 0
                    verticalOffset = 0
                }
            }
    }
}

// MARK: - Calendar-binding illustration

private struct Prompt19BindingRing:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        path.move(
            to: CGPoint(
                x:
                    rect.midX
                    - rect.width
                    * 0.28,
                y:
                    rect.maxY
                    * 0.80
            )
        )

        path.addCurve(
            to: CGPoint(
                x:
                    rect.midX
                    + rect.width
                    * 0.30,
                y:
                    rect.maxY
                    * 0.80
            ),
            control1:
                CGPoint(
                    x:
                        rect.minX
                        - rect.width
                        * 0.02,
                    y:
                        rect.minY
                        + rect.height
                        * 0.05
                ),
            control2:
                CGPoint(
                    x:
                        rect.maxX
                        + rect.width
                        * 0.02,
                    y:
                        rect.minY
                        + rect.height
                        * 0.05
                )
        )

        return path
    }
}

// MARK: - Tiny coded watercolor-style heart

private struct Prompt19Heart:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        let top =
            rect.minY
            + rect.height
            * 0.28

        path.move(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.maxY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.minX,
                    y: top
                ),
            control1:
                CGPoint(
                    x:
                        rect.midX
                        - rect.width
                        * 0.12,
                    y:
                        rect.maxY
                        * 0.76
                ),
            control2:
                CGPoint(
                    x: rect.minX,
                    y: rect.midY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.midX,
                    y:
                        rect.minY
                        + rect.height
                        * 0.22
                ),
            control1:
                CGPoint(
                    x: rect.minX,
                    y: rect.minY
                ),
            control2:
                CGPoint(
                    x:
                        rect.midX
                        - rect.width
                        * 0.12,
                    y: rect.minY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: top
                ),
            control1:
                CGPoint(
                    x:
                        rect.midX
                        + rect.width
                        * 0.12,
                    y: rect.minY
                ),
            control2:
                CGPoint(
                    x: rect.maxX,
                    y: rect.minY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.maxY
                ),
            control1:
                CGPoint(
                    x: rect.maxX,
                    y: rect.midY
                ),
            control2:
                CGPoint(
                    x:
                        rect.midX
                        + rect.width
                        * 0.12,
                    y:
                        rect.maxY
                        * 0.76
                )
        )

        path.closeSubpath()

        return path
    }
}

private struct Prompt19DatePressStyle:
    ButtonStyle {

    let reduceMotion:
        Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration
            .label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        configuration
                            .isPressed
                            ? 0.98
                            : 1
                    )
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.05
                    )
                    : .easeOut(
                        duration: 0.09
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}

private struct Prompt19GentlePressStyle:
    ButtonStyle {

    let reduceMotion:
        Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration
            .label
            .scaleEffect(
                reduceMotion
                    ? 1
                    : (
                        configuration
                            .isPressed
                            ? 0.975
                            : 1
                    )
            )
            .offset(
                y:
                    reduceMotion
                    ? 0
                    : (
                        configuration
                            .isPressed
                            ? 1
                            : 0
                    )
            )
            .animation(
                reduceMotion
                    ? .easeOut(
                        duration: 0.05
                    )
                    : .easeOut(
                        duration: 0.10
                    ),
                value:
                    configuration
                        .isPressed
            )
    }
}

private struct Prompt19PredictedPeriodOutline:
    View {

    var body: some View {
        Prompt19HandDrawnRing(
            variant: 3
        )
        .stroke(
            Prompt19Palette
                .period
                .opacity(0.34),
            style:
                StrokeStyle(
                    lineWidth: 1.0,
                    lineCap: .round,
                    dash: [
                        2.2,
                        2.8
                    ]
                )
        )
    }
}

private struct Prompt19WatercolorBlob:
    Shape {

    let variant: Int

    func path(
        in rect: CGRect
    ) -> Path {
        let wobble =
            CGFloat(
                (abs(variant) % 4)
                + 1
            )
            * 0.012

        var path = Path()

        path.move(
            to:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * (
                            0.12
                            + wobble
                        ),
                    y:
                        rect.minY
                        + rect.height
                        * 0.16
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.maxX
                        - rect.width
                        * 0.10,
                    y:
                        rect.minY
                        + rect.height
                        * (
                            0.14
                            + wobble
                        )
                ),
            control1:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.34,
                    y:
                        rect.minY
                        + rect.height
                        * 0.02
                ),
            control2:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.72,
                    y:
                        rect.minY
                        + rect.height
                        * 0.08
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.maxX
                        - rect.width
                        * (
                            0.08
                            + wobble
                        ),
                    y:
                        rect.maxY
                        - rect.height
                        * 0.16
                ),
            control1:
                CGPoint(
                    x: rect.maxX,
                    y:
                        rect.minY
                        + rect.height
                        * 0.35
                ),
            control2:
                CGPoint(
                    x:
                        rect.maxX
                        - rect.width
                        * 0.02,
                    y:
                        rect.minY
                        + rect.height
                        * 0.74
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.10,
                    y:
                        rect.maxY
                        - rect.height
                        * (
                            0.12
                            + wobble
                        )
                ),
            control1:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.70,
                    y: rect.maxY
                ),
            control2:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.30,
                    y:
                        rect.maxY
                        - rect.height
                        * 0.02
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * (
                            0.12
                            + wobble
                        ),
                    y:
                        rect.minY
                        + rect.height
                        * 0.16
                ),
            control1:
                CGPoint(
                    x: rect.minX,
                    y:
                        rect.maxY
                        - rect.height
                        * 0.38
                ),
            control2:
                CGPoint(
                    x:
                        rect.minX
                        + rect.width
                        * 0.02,
                    y:
                        rect.minY
                        + rect.height
                        * 0.32
                )
        )

        path.closeSubpath()

        return path
    }
}

private struct Prompt19HandDrawnRing:
    Shape {

    let variant: Int

    func path(
        in rect: CGRect
    ) -> Path {
        let inset =
            CGFloat(
                abs(variant)
                % 3
            )
            * 0.35

        let ringRect =
            rect.insetBy(
                dx: inset + 1,
                dy: inset + 1
            )

        var path = Path()

        path.addEllipse(
            in: ringRect
        )

        return path
    }
}

private struct Prompt19Droplet:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        path.move(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.minY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.maxY
                ),
            control1:
                CGPoint(
                    x: rect.maxX,
                    y:
                        rect.midY
                        * 0.95
                ),
            control2:
                CGPoint(
                    x: rect.maxX,
                    y: rect.maxY
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x: rect.midX,
                    y: rect.minY
                ),
            control1:
                CGPoint(
                    x: rect.minX,
                    y: rect.maxY
                ),
            control2:
                CGPoint(
                    x: rect.minX,
                    y:
                        rect.midY
                        * 0.95
                )
        )

        return path
    }
}

private struct Prompt19TinyFlower:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        let center =
            CGPoint(
                x: rect.midX,
                y: rect.midY
            )

        let radius =
            min(
                rect.width,
                rect.height
            )
            * 0.20

        for index
            in 0..<5 {

            let angle =
                Double(index)
                * (
                    2
                    * .pi
                    / 5
                )
                - .pi
                / 2

            let x =
                center.x
                + cos(angle)
                * min(
                    rect.width,
                    rect.height
                )
                * 0.28

            let y =
                center.y
                + sin(angle)
                * min(
                    rect.width,
                    rect.height
                )
                * 0.28

            path.addEllipse(
                in:
                    CGRect(
                        x:
                            x
                            - radius,
                        y:
                            y
                            - radius,
                        width:
                            radius
                            * 2,
                        height:
                            radius
                            * 2
                    )
            )
        }

        path.addEllipse(
            in:
                CGRect(
                    x:
                        center.x
                        - radius
                        * 0.55,
                    y:
                        center.y
                        - radius
                        * 0.55,
                    width:
                        radius
                        * 1.1,
                    height:
                        radius
                        * 1.1
                )
        )

        return path
    }
}

private struct Prompt19BookmarkMark:
    Shape {

    func path(
        in rect: CGRect
    ) -> Path {
        var path = Path()

        path.move(
            to:
                CGPoint(
                    x: rect.minX,
                    y: rect.minY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: rect.minY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.maxX,
                    y: rect.maxY
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.midX,
                    y:
                        rect.maxY
                        * 0.76
                )
        )

        path.addLine(
            to:
                CGPoint(
                    x: rect.minX,
                    y: rect.maxY
                )
        )

        path.closeSubpath()

        return path
    }
}

private enum Prompt19Palette {
    static let teal =
        Color(
            red: 0.22,
            green: 0.50,
            blue: 0.50
        )

    static let headerMint =
        Color(
            red: 0.78,
            green: 0.88,
            blue: 0.85
        )

    static let dayPink =
        Color(
            red: 0.96,
            green: 0.73,
            blue: 0.75
        )

    static let heart =
        Color(
            red: 0.95,
            green: 0.59,
            blue: 0.62
        )

    static let burgundy =
        Color(
            red:
                128.0
                / 255.0,
            green: 0,
            blue: 0
        )

    static let paper =
        DesignTokens
            .ColorToken
            .backgroundCream

    static let period =
        Color(
            red: 0.93,
            green: 0.61,
            blue: 0.65
        )

    static let coral =
        Color(
            red: 0.91,
            green: 0.47,
            blue: 0.49
        )

    static let fertile =
        Color(
            red: 0.94,
            green: 0.84,
            blue: 0.52
        )

    static let mint =
        Color(
            red: 0.66,
            green: 0.82,
            blue: 0.74
        )

    static let sage =
        Color(
            red: 0.55,
            green: 0.67,
            blue: 0.52
        )

    static let olive =
        Color(
            red: 0.66,
            green: 0.66,
            blue: 0.42
        )

    static let dustyBlue =
        Color(
            red: 0.64,
            green: 0.78,
            blue: 0.79
        )

    static let peach =
        Color(
            red: 0.91,
            green: 0.68,
            blue: 0.49
        )
}

private enum Prompt19Type {
    static let monthTitle =
        Font.custom(
            "Chalkboard SE",
            size: 19,
            relativeTo:
                .headline
        )
        .weight(
            .semibold
        )

    static let weekday =
        Font.custom(
            "Chalkboard SE",
            size: 15,
            relativeTo:
                .caption
        )
        .weight(
            .semibold
        )

    static let dateNumber =
        Font.custom(
            "Chalkboard SE",
            size: 14,
            relativeTo:
                .caption
        )
        .weight(
            .semibold
        )

    static let footnote =
        Font.custom(
            "Chalkboard SE",
            size: 11,
            relativeTo:
                .caption
        )

    static let microControl =
        Font.custom(
            "Chalkboard SE",
            size: 9.5,
            relativeTo:
                .caption2
        )

    static let sheetTitle =
        Font.custom(
            "Chalkboard SE",
            size: 24,
            relativeTo:
                .title2
        )
        .weight(
            .bold
        )

    static let sheetSubhead =
        Font.custom(
            "Chalkboard SE",
            size: 13,
            relativeTo:
                .subheadline
        )

    static let stateLabel =
        Font.custom(
            "Chalkboard SE",
            size: 12,
            relativeTo:
                .caption
        )
        .weight(
            .semibold
        )

    static let sectionLabel =
        Font.custom(
            "Chalkboard SE",
            size: 10,
            relativeTo:
                .caption2
        )
        .weight(
            .semibold
        )

    static let sheetBody =
        Font.custom(
            "Chalkboard SE",
            size: 14,
            relativeTo:
                .body
        )

    static let action =
        Font.custom(
            "Chalkboard SE",
            size: 13,
            relativeTo:
                .body
        )
        .weight(
            .semibold
        )

    static let note =
        Font.custom(
            "Chalkboard SE",
            size: 11.5,
            relativeTo:
                .caption
        )
}

























