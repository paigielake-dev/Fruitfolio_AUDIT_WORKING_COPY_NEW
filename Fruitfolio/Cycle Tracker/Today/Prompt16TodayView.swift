import SwiftUI
import Foundation

struct Prompt16TodayView: View {
    var loader = Prompt16TodayLoader()
    var context: Prompt27AUserReproductiveContext = .unspecified
    var contextPolicy: Prompt27AContextPolicyResult = Prompt27AContextPolicyResult()

    let onSeeBiology: () -> Void
    let onLogToday: () -> Void
    let onLogBBT: () -> Void
    let onPredictionInfoRequested: (Prompt16PredictionLearningInfo) -> Void

    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    @State private var state: Prompt16TodayState = .empty
    @State private var predictionResult: Prompt17CyclePredictionResult?
    @State private var estimatedIntervals: Prompt18EstimatedIntervals = .none
    @State private var loadState: Prompt16LoadState = .loading
    @State private var revealProgress: CGFloat = 0
    @State private var showMarker = false

    private var wheelModel: Prompt18WheelModel {
        guard let predictionResult else {
            return Prompt18WheelModel(
                representedCycleLength: nil,
                currentCycleDay: state.cycleDay,
                baseSegments: [],
                fertileOverlay: nil,
                unresolvedIntervals: [],
                currentRegion: nil,
                currentPositionFraction: nil,
                confidence: .limitedEstimate,
                dataSufficiency: .noCompletedCycles,
                historyVersion: "prompt16.awaiting-prompt17"
            )
        }

        return Prompt18CycleWheelBuilder().build(
            prediction: predictionResult,
            estimatedIntervals: estimatedIntervals
        )
    }

    private var displayCycleDay: Int? {
        predictionResult?.currentCycleDay ?? state.cycleDay
    }

    private var displayContextTitle: String {
        wheelModel.currentRegion?.title ?? state.context.title
    }

    private var displayContextExplanation: String {
        wheelModel.currentRegion?.noteBody ?? state.context.explanation
    }

    private var displayIsMenstruation: Bool {
        if predictionResult != nil,
           wheelModel.currentRegion != nil {
            return wheelModel.currentRegion == .menstruation
        }

        return state.context == .menstruation
    }

    private var hasRepresentedCycle: Bool {
        wheelModel.representedCycleLength != nil
    }

    private var shouldOfferPredictionInfo: Bool {
        guard case .loaded = loadState else {
            return false
        }

        return wheelModel.representedCycleLength == nil
    }

    private var currentPredictionsSuppressed: Bool {
        [.nextPeriodPrediction, .fertileWindowPrediction, .ovulationPrediction].allSatisfy {
            contextPolicy[$0].effect == .suppress
        }
    }

    private var todayClarification: String? {
        let policy = contextPolicy[.today]
        guard policy.effect == .clarify || policy.effect == .suppress else { return nil }
        return policy.reason
    }

    private var predictionLearningInfo: Prompt16PredictionLearningInfo {
        let completedCycleCount =
            predictionResult?.completedCycleLengths.count ?? 0

        let suppliedStartCount =
            predictionResult?.normalizedCycleStartDates.count ?? 0

        if suppliedStartCount == 0 {
            return Prompt16PredictionLearningInfo(
                title: "still learning ♡",
                body:
                    "log your period start to begin.",
                progress:
                    "after your next period start, Fruitfolio can estimate your cycle length."
            )
        }

        if completedCycleCount == 0 {
            return Prompt16PredictionLearningInfo(
                title: "still learning ♡",
                body:
                    "one period start is saved.",
                progress:
                    "log your next period start to unlock your first cycle estimate."
            )
        }

        return Prompt16PredictionLearningInfo(
            title: "still learning ♡",
            body:
                "your wheel needs a little more history.",
            progress:
                "keep logging confirmed period starts and Fruitfolio will recalculate."
        )
    }

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                loadingView

            case .loaded:
                if currentPredictionsSuppressed {
                    contextRestrictedContent
                } else {
                    content
                }

            case .failed:
                fallbackView
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .task {
            await load()
        }
        .accessibilityIdentifier("prompt16.today")
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(Prompt16Palette.burgundy)
                .accessibilityLabel("Loading Today view")

            Text("opening today’s cycle page…")
                .font(Prompt16Type.body)
                .foregroundStyle(
                    Prompt16Palette.burgundy.opacity(0.72)
                )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 420
        )
    }

    private var fallbackView: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            if let todayClarification {
                Text(todayClarification)
                    .font(Prompt16Type.body)
                    .foregroundStyle(Prompt16Palette.burgundy.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
            }

            Prompt16DayIndicator(
                cycleDay: displayCycleDay
            )

            wheelVisual(
                revealProgress: 1,
                showMarker: false
            )

            predictionInfoButton

            Text(
                Prompt16TodayContext
                    .insufficientData
                    .title
            )
            .font(Prompt16Type.contextTitle)
            .foregroundStyle(
                Prompt16Palette.burgundy
            )

            Text(
                Prompt16TodayContext
                    .insufficientData
                    .explanation
            )
            .font(Prompt16Type.body)
            .foregroundStyle(
                Prompt16Palette.burgundy.opacity(0.82)
            )
            .fixedSize(
                horizontal: false,
                vertical: true
            )

            actionArea(
                showBBT: false
            )
            .padding(.top, 8)
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private var contextRestrictedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("today")
                .font(Prompt16Type.contextTitle)
                .foregroundStyle(Prompt16Palette.burgundy)
                .accessibilityAddTraits(.isHeader)

            Text(todayClarification ?? "your saved cycle history is still here, but ordinary current-cycle predictions are not shown for this context.")
                .font(Prompt16Type.body)
                .foregroundStyle(Prompt16Palette.burgundy.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            Text("your historical logs stay saved. changing your context does not rewrite or delete them.")
                .font(Prompt16Type.body)
                .foregroundStyle(Prompt16Palette.burgundy.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            actionArea(showBBT: false)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var content: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            Prompt16DayIndicator(
                cycleDay: displayCycleDay
            )

            wheelVisual(
                revealProgress: revealProgress,
                showMarker: showMarker
            )
            .padding(.top, 10)

            predictionInfoButton
                .padding(.top, 2)

            VStack(
                alignment: .leading,
                spacing: 9
            ) {
                Text(displayContextTitle)
                    .font(Prompt16Type.contextTitle)
                    .foregroundStyle(
                        Prompt16Palette.burgundy
                    )
                    .accessibilityAddTraits(.isHeader)

                if displayIsMenstruation {
                    HStack {
                        Spacer()

                        Prompt16ButterflyFlightDecoration()
                            .offset(x: 14)
                    }
                    .frame(height: 74)
                }

                Text(displayContextExplanation)
                    .font(Prompt16Type.body)
                    .foregroundStyle(
                        Prompt16Palette.burgundy.opacity(0.82)
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                FruitfolioControlPillButton(
                    label: "see what’s happening"
                ) {
                    audioManager.play(
                        .buttonSoftPop
                    )

                    onSeeBiology()
                }
                .frame(
                    maxWidth: 270,
                    alignment: .leading
                )
                .padding(.top, 5)
            }
            .padding(.top, 12)

            actionArea(
                showBBT: state.bbtShortcutEnabled
            )
            .padding(.top, 18)
        }
        .onAppear {
            startRevealAnimation()
        }
    }

    @ViewBuilder
    private func wheelVisual(
        revealProgress: CGFloat,
        showMarker: Bool
    ) -> some View {
        if hasRepresentedCycle {
            Prompt18DynamicCycleWheel(
                model: wheelModel,
                revealProgress: revealProgress,
                showCurrentMarker: showMarker,
                onLearnWhy: { _ in
                    onSeeBiology()
                },
                onInteraction: {
                    audioManager.play(.buttonSoftPop)
                }
            )
            .frame(maxWidth: 430)
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
        } else {
            Prompt16LimitedDataCycleWheel(
                cycleDay: displayCycleDay,
                revealProgress: revealProgress
            )
            .frame(maxWidth: 430)
            .frame(
                maxWidth: .infinity,
                alignment: .center
            )
        }
    }

    @ViewBuilder
    private var predictionInfoButton: some View {
        if shouldOfferPredictionInfo {
            HStack {
                Spacer()

                Button {
                    audioManager.play(.buttonSoftPop)
                    onPredictionInfoRequested(
                        predictionLearningInfo
                    )
                } label: {
                    HStack(spacing: 6) {
                        Text("why is my wheel blank?")

                        Image("ask_question_mark")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 30,
                                height: 30
                            )
                            .accessibilityHidden(true)
                    }
                    .font(Prompt16Type.small)
                    .foregroundStyle(
                        Prompt16Palette.burgundy.opacity(0.78)
                    )
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "Why is my cycle wheel blank?"
                )
                .accessibilityHint(
                    "Explains how much cycle history Fruitfolio needs before it can begin estimating your cycle length."
                )

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func actionArea(
        showBBT: Bool
    ) -> some View {
        HStack(
            alignment: .center,
            spacing: 14
        ) {
            FruitfolioControlPillButton(
                label: "log today +"
            ) {
                audioManager.play(
                    .buttonSoftPop
                )

                onLogToday()
            }
            .frame(maxWidth: 238)

            if showBBT {
                Button {
                    audioManager.play(
                        .buttonSoftPop
                    )

                    onLogBBT()
                } label: {
                    VStack(spacing: 3) {
                        Image("cycle_bbt_thermometer")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 48,
                                height: 48
                            )
                            .accessibilityHidden(true)

                        Text(
                            state.hasRecordedTemperatureToday
                                ? "BBT logged"
                                : "BBT"
                        )
                        .font(Prompt16Type.small)
                        .foregroundStyle(
                            Prompt16Palette.burgundy
                        )
                    }
                    .frame(
                        minWidth: 58,
                        minHeight: 58
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(
                    CutePopButtonStyle(
                        reduceMotion:
                            motionPreferences
                                .reduceMotionActive
                    )
                )
                .accessibilityLabel(
                    state.hasRecordedTemperatureToday
                        ? "BBT, temperature already logged today"
                        : "BBT, log basal body temperature"
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func load() async {
        do {
            let now = Date()

            async let stateTask =
                loader.load(now: now)

            async let archiveTask =
                loader.cycleStore.snapshot()

            async let onboardingTask =
                loader.onboardingStore.snapshot()

            async let dailyLogsTask =
                Prompt20CycleDailyLogStore
                    .shared
                    .allActiveLogs(
                        ownerID: .localDevice
                    )

            let loadedState =
                try await stateTask

            let archive =
                try await archiveTask

            let onboarding =
                try await onboardingTask

            let dailyLogs =
                try await dailyLogsTask

            let prediction =
                try Prompt16Prompt17Bridge
                    .makePrediction(
                        archive: archive,
                        onboarding: onboarding,
                        dailyLogs: dailyLogs,
                        asOfDate: now,
                        calendar: loader.calendar
                    )

            guard !Task.isCancelled else {
                return
            }

            state = loadedState

            predictionResult =
                prediction

            estimatedIntervals = .none

            loadState = .loaded

            startRevealAnimation()
        } catch {
            guard !Task.isCancelled else {
                return
            }

            state = .empty
            predictionResult = nil
            estimatedIntervals = .none
            loadState = .failed
            revealProgress = 1
            showMarker = false

            #if DEBUG
            print(
                "Prompt16TodayView failed to load Prompt 17/18 data:",
                error
            )
            #endif
        }
    }

    private func startRevealAnimation() {
        guard loadState == .loaded else {
            return
        }

        if motionPreferences
            .reduceMotionActive {
            revealProgress = 1
            showMarker = true
            return
        }

        revealProgress = 0
        showMarker = false

        withAnimation(
            .easeOut(
                duration: 0.60
            )
        ) {
            revealProgress = 1
        }

        Task { @MainActor in
            try? await Task.sleep(
                for: .milliseconds(
                    600
                )
            )

            guard !Task.isCancelled else {
                return
            }

            withAnimation(
                .easeOut(
                    duration: 0.18
                )
            ) {
                showMarker = true
            }
        }
    }
}

// MARK: - Prompt 13 -> Prompt 17 bridge

private enum Prompt16Prompt17Bridge {
    static func makePrediction(
        archive: Prompt13CycleArchive,
        onboarding: Prompt14OnboardingDraft,
        dailyLogs: [Prompt20DailyLog],
        asOfDate: Date,
        calendar: Calendar
    ) throws
        -> Prompt17CyclePredictionResult {

        let storedCycleStarts =
            archive
                .cycleStarts
                .filter {
                    !$0.metadata.isDeleted
                }
                .map(\.date)

        let sourceCycleStarts =
            storedCycleStarts.isEmpty
                ? onboarding
                    .allSuppliedCycleStarts
                : storedCycleStarts

        let cycleStartDates =
            try sourceCycleStarts.map {
                try Prompt16LocalDateBridge
                    .foundationDate(
                        from: $0,
                        calendar: calendar
                    )
            }

        let dailyLogCycleStarts =
            dailyLogs.compactMap { log -> Date? in
                guard
                    !log.isDeleted,
                    log.periodEvent == .started
                else {
                    return nil
                }

                return log.date.date(
                    in: calendar
                )
            }

        let allCycleStartDates =
            cycleStartDates
            + dailyLogCycleStarts

        let onboardingPeriodRecords =
            try makeExplicitPeriodRecords(
                onboarding: onboarding,
                calendar: calendar
            )

        let dailyLogPeriodRecords =
            makeDailyLogPeriodRecords(
                dailyLogs: dailyLogs,
                calendar: calendar
            )

        var periodRecordsByStart:
            [Date: Prompt17RecordedPeriod] = [:]

        for record in onboardingPeriodRecords {
            periodRecordsByStart[
                calendar.startOfDay(
                    for: record.startDate
                )
            ] = record
        }

        for record in dailyLogPeriodRecords {
            periodRecordsByStart[
                calendar.startOfDay(
                    for: record.startDate
                )
            ] = record
        }

        let periodRecords =
            periodRecordsByStart
                .values
                .sorted {
                    $0.startDate < $1.startDate
                }

        return Prompt17CyclePredictionEngine(
            calendar: calendar
        )
        .calculate(
            from:
                Prompt17CyclePredictionInput(
                    cycleStartDates:
                        allCycleStartDates,
                    periodRecords:
                        periodRecords,
                    asOfDate:
                        asOfDate
                )
        )
    }

    private static func makeExplicitPeriodRecords(
        onboarding: Prompt14OnboardingDraft,
        calendar: Calendar
    ) throws -> [Prompt17RecordedPeriod] {

        guard
            onboarding.latestPeriodState == .supplied,
            let localStart = onboarding.latestPeriodStart
        else {
            return []
        }

        let start =
            try Prompt16LocalDateBridge
                .foundationDate(
                    from: localStart,
                    calendar: calendar
                )

        let end: Date?

        if onboarding.currentPeriodAnswer == .no,
           onboarding.periodEndState == .supplied,
           let localEnd = onboarding.periodEnd {

            end =
                try Prompt16LocalDateBridge
                    .foundationDate(
                        from: localEnd,
                        calendar: calendar
                    )
        } else {
            end = nil
        }

        return [
            Prompt17RecordedPeriod(
                startDate: start,
                endDate: end
            )
        ]
    }

    private static func makeDailyLogPeriodRecords(
        dailyLogs: [Prompt20DailyLog],
        calendar: Calendar
    ) -> [Prompt17RecordedPeriod] {

        let events =
            dailyLogs.compactMap {
                log -> (
                    date: Date,
                    event: Prompt20PeriodEvent
                )? in

                guard
                    !log.isDeleted,
                    let event = log.periodEvent,
                    let date = log.date.date(
                        in: calendar
                    )
                else {
                    return nil
                }

                return (
                    calendar.startOfDay(
                        for: date
                    ),
                    event
                )
            }
            .sorted {
                $0.date < $1.date
            }

        var records:
            [Prompt17RecordedPeriod] = []

        var openStart:
            Date?

        for event in events {
            switch event.event {
            case .started:
                if let openStart {
                    records.append(
                        Prompt17RecordedPeriod(
                            startDate: openStart,
                            endDate: nil
                        )
                    )
                }

                openStart = event.date

            case .ended:
                guard
                    let start = openStart,
                    event.date >= start
                else {
                    continue
                }

                records.append(
                    Prompt17RecordedPeriod(
                        startDate: start,
                        endDate: event.date
                    )
                )

                openStart = nil
            }
        }

        if let openStart {
            records.append(
                Prompt17RecordedPeriod(
                    startDate: openStart,
                    endDate: nil
                )
            )
        }

        return records
    }
}

// MARK: - Prompt 13 date-only -> Foundation Date

private enum Prompt16LocalDateBridgeError: Error {
    case unsupportedEncoding
    case invalidCalendarDate
}

private enum Prompt16LocalDateBridge {
    static func foundationDate(
        from localDate: Prompt13LocalDate,
        calendar: Calendar
    ) throws -> Date {

        let data =
            try JSONEncoder()
                .encode(
                    localDate
                )

        let object =
            try JSONSerialization
                .jsonObject(
                    with: data
                )

        guard let components =
            extractComponents(
                from: object
            )
        else {
            throw
                Prompt16LocalDateBridgeError
                    .unsupportedEncoding
        }

        var dateComponents =
            DateComponents()

        dateComponents.calendar =
            calendar

        dateComponents.timeZone =
            calendar.timeZone

        dateComponents.year =
            components.year

        dateComponents.month =
            components.month

        dateComponents.day =
            components.day

        dateComponents.hour =
            12

        guard let date =
            calendar.date(
                from: dateComponents
            )
        else {
            throw
                Prompt16LocalDateBridgeError
                    .invalidCalendarDate
        }

        return date
    }

    private static func extractComponents(
        from object: Any
    ) -> (
        year: Int,
        month: Int,
        day: Int
    )? {

        if let dictionary =
            object as? [String: Any] {

            if let year =
                integerValue(
                    dictionary["year"]
                ),
               let month =
                integerValue(
                    dictionary["month"]
                ),
               let day =
                integerValue(
                    dictionary["day"]
                ) {

                return (
                    year,
                    month,
                    day
                )
            }

            for value in dictionary.values {
                if let nested =
                    extractComponents(
                        from: value
                    ) {

                    return nested
                }
            }
        }

        if let array =
            object as? [Any] {

            for value in array {
                if let nested =
                    extractComponents(
                        from: value
                    ) {

                    return nested
                }
            }

            if array.count == 3,
               let year =
                integerValue(
                    array[0]
                ),
               let month =
                integerValue(
                    array[1]
                ),
               let day =
                integerValue(
                    array[2]
                ) {

                return (
                    year,
                    month,
                    day
                )
            }
        }

        if let string =
            object as? String {

            return
                parseDateString(
                    string
                )
        }

        return nil
    }

    private static func integerValue(
        _ value: Any?
    ) -> Int? {

        if let int =
            value as? Int {

            return int
        }

        if let number =
            value as? NSNumber {

            return
                number.intValue
        }

        if let string =
            value as? String {

            return
                Int(string)
        }

        return nil
    }

    private static func parseDateString(
        _ string: String
    ) -> (
        year: Int,
        month: Int,
        day: Int
    )? {

        let pieces =
            string.split(
                separator: "-"
            )

        guard
            pieces.count >= 3,
            let year =
                Int(
                    pieces[0]
                ),
            let month =
                Int(
                    pieces[1]
                )
        else {
            return nil
        }

        let dayDigits =
            pieces[2]
                .prefix {
                    $0.isNumber
                }

        guard let day =
            Int(dayDigits)
        else {
            return nil
        }

        return (
            year,
            month,
            day
        )
    }
}

// MARK: - Truthful limited-data wheel shell

private struct Prompt16LimitedDataCycleWheel: View {
    let cycleDay: Int?
    let revealProgress: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .trim(
                    from: 0,
                    to: max(
                        0.001,
                        min(
                            1,
                            revealProgress
                        )
                    )
                )
                .stroke(
                    Prompt16Palette
                        .sage
                        .opacity(
                            0.14
                        ),
                    style:
                        StrokeStyle(
                            lineWidth:
                                44,
                            lineCap:
                                .round
                        )
                )
                .rotationEffect(
                    .degrees(
                        -90
                    )
                )

            Circle()
                .trim(
                    from: 0,
                    to: max(
                        0.001,
                        min(
                            1,
                            revealProgress
                        )
                    )
                )
                .stroke(
                    Prompt16Palette
                        .coral
                        .opacity(
                            0.08
                        ),
                    style:
                        StrokeStyle(
                            lineWidth:
                                36,
                            lineCap:
                                .round,
                            dash:
                                [7, 4]
                        )
                )
                .rotationEffect(
                    .degrees(
                        -89.3
                    )
                )
                .scaleEffect(
                    0.985
                )

            Circle()
                .trim(
                    from: 0,
                    to: max(
                        0.001,
                        min(
                            1,
                            revealProgress
                        )
                    )
                )
                .stroke(
                    Prompt16Palette
                        .dustyBlue
                        .opacity(
                            0.07
                        ),
                    style:
                        StrokeStyle(
                            lineWidth:
                                30,
                            lineCap:
                                .round,
                            dash:
                                [11, 6]
                        )
                )
                .rotationEffect(
                    .degrees(
                        -90.8
                    )
                )
                .scaleEffect(
                    0.97
                )

            VStack(
                spacing: 4
            ) {
                if let cycleDay {
                    Text(
                        "cycle day"
                    )
                    .font(
                        Prompt16Type
                            .small
                    )
                    .foregroundStyle(
                        Prompt16Palette
                            .burgundy
                            .opacity(
                                0.64
                            )
                    )

                    Text(
                        "\(cycleDay)"
                    )
                    .font(
                        Prompt16Type
                            .wheelNumber
                    )
                    .foregroundStyle(
                        Prompt16Palette
                            .burgundy
                    )
                } else {
                    Text(
                        "building\nyour pattern"
                    )
                    .font(
                        Prompt16Type
                            .wheelCenter
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .foregroundStyle(
                        Prompt16Palette
                            .burgundy
                            .opacity(
                                0.70
                            )
                    )
                }
            }
        }
        .padding(16)
        .aspectRatio(
            1,
            contentMode: .fit
        )
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            cycleDay.map {
                "Cycle wheel. Cycle day \($0). Fruitfolio needs more completed cycle history before showing personalized phase geometry."
            }
            ?? "Cycle wheel. Fruitfolio needs more completed cycle history before showing personalized phase geometry."
        )
    }
}

struct Prompt16PredictionLearningInfo: Equatable {
    let title: String
    let body: String
    let progress: String
}

private enum Prompt16LoadState {
    case loading
    case loaded
    case failed
}

private struct Prompt16DayIndicator: View {
    let cycleDay: Int?

    var body: some View {
        ZStack {
            Image(
                "cycle_day_circle"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 58,
                height: 58
            )
            .accessibilityHidden(
                true
            )

            VStack(
                spacing: -2
            ) {
                Text("day")
                    .font(
                        Prompt16Type
                            .dayLabel
                    )

                Text(
                    cycleDay
                        .map(
                            String.init
                        )
                    ?? "—"
                )
                .font(
                    Prompt16Type
                        .dayNumber
                )
            }
            .foregroundStyle(
                Prompt16Palette
                    .burgundy
            )
        }
        .frame(
            width: 62,
            height: 62
        )
        .accessibilityElement(
            children: .ignore
        )
        .accessibilityLabel(
            cycleDay.map {
                "cycle day \($0)"
            }
            ?? "cycle day not available yet"
        )
    }
}

private struct Prompt16ButterflyFlightDecoration: View {
    @EnvironmentObject private var motionPreferences: MotionPreferences
    @EnvironmentObject private var audioManager: AudioManager

    @State private var flightTrigger = 0
    @State private var flightOffset: CGSize = .zero
    @State private var flightRotation: Double = -7
    @State private var flightScale: CGFloat = 1
    @State private var trailTrim: CGFloat = 1
    @State private var trailOpacity: Double = 0.62

    var body: some View {
        ZStack(alignment: .trailing) {
            Prompt16ButterflyTrail()
                .trim(from: 0, to: trailTrim)
                .stroke(
                    Prompt16Palette.burgundy.opacity(trailOpacity),
                    style: StrokeStyle(
                        lineWidth: 1.45,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: [2.2, 5.2]
                    )
                )
                .frame(width: 112, height: 50)
                .offset(x: -42, y: 7)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Button {
                audioManager.play(.buttonSoftPop)
                flightTrigger &+= 1
            } label: {
                Image("decor_butterfly")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72)
                    .contentShape(Rectangle())
                    .accessibilityHidden(true)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 74, minHeight: 74)
            .contentShape(Rectangle())
            .offset(flightOffset)
            .rotationEffect(.degrees(flightRotation))
            .scaleEffect(flightScale)
            .accessibilityLabel("Butterfly")
            .accessibilityHint(
                "Makes the butterfly flutter along its little flight path."
            )
        }
        .frame(
            width: 158,
            height: 74,
            alignment: .trailing
        )
        .task(id: flightTrigger) {
            guard flightTrigger > 0 else {
                return
            }

            await performFlight()
        }
    }

    @MainActor
    private func performFlight() async {
        if motionPreferences.reduceMotionActive {
            withAnimation(
                .easeOut(
                    duration: 0.12
                )
            ) {
                flightScale = 1.04
                trailOpacity = 0.78
            }

            try? await Task.sleep(
                for: .milliseconds(
                    120
                )
            )

            guard !Task.isCancelled else {
                return
            }

            withAnimation(
                .easeOut(
                    duration: 0.14
                )
            ) {
                flightScale = 1
                trailOpacity = 0.62
            }

            return
        }

        trailTrim = 0.28
        trailOpacity = 0.40

        withAnimation(
            .easeOut(
                duration: 0.12
            )
        ) {
            flightScale = 0.94
            flightRotation = -13
        }

        try? await Task.sleep(
            for: .milliseconds(
                120
            )
        )

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.66,
                blendDuration: 0
            )
        ) {
            flightOffset =
                CGSize(
                    width: -22,
                    height: -14
                )

            flightRotation = 9
            flightScale = 1.06
            trailTrim = 0.56
            trailOpacity = 0.70
        }

        try? await Task.sleep(
            for: .milliseconds(
                190
            )
        )

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .spring(
                response: 0.26,
                dampingFraction: 0.64,
                blendDuration: 0
            )
        ) {
            flightOffset =
                CGSize(
                    width: 8,
                    height: -27
                )

            flightRotation = -15
            flightScale = 0.98
            trailTrim = 0.78
            trailOpacity = 0.78
        }

        try? await Task.sleep(
            for: .milliseconds(
                185
            )
        )

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .spring(
                response: 0.28,
                dampingFraction: 0.67,
                blendDuration: 0
            )
        ) {
            flightOffset =
                CGSize(
                    width: -10,
                    height: -8
                )

            flightRotation = 6
            flightScale = 1.04
            trailTrim = 1
            trailOpacity = 0.74
        }

        try? await Task.sleep(
            for: .milliseconds(
                190
            )
        )

        guard !Task.isCancelled else {
            return
        }

        withAnimation(
            .spring(
                response: 0.34,
                dampingFraction: 0.72,
                blendDuration: 0
            )
        ) {
            flightOffset = .zero
            flightRotation = -7
            flightScale = 1
            trailOpacity = 0.62
        }
    }
}

private struct Prompt16ButterflyTrail: Shape {
    func path(
        in rect: CGRect
    ) -> Path {

        var path =
            Path()

        path.move(
            to:
                CGPoint(
                    x:
                        rect.maxX
                        * 0.96,
                    y:
                        rect.midY
                        * 0.98
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.width
                        * 0.57,
                    y:
                        rect.height
                        * 0.32
                ),
            control1:
                CGPoint(
                    x:
                        rect.width
                        * 0.83,
                    y:
                        rect.height
                        * 0.92
                ),
            control2:
                CGPoint(
                    x:
                        rect.width
                        * 0.69,
                    y:
                        rect.height
                        * 0.20
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.width
                        * 0.18,
                    y:
                        rect.height
                        * 0.58
                ),
            control1:
                CGPoint(
                    x:
                        rect.width
                        * 0.44,
                    y:
                        rect.height
                        * 0.43
                ),
            control2:
                CGPoint(
                    x:
                        rect.width
                        * 0.31,
                    y:
                        rect.height
                        * 0.78
                )
        )

        path.addCurve(
            to:
                CGPoint(
                    x:
                        rect.width
                        * 0.06,
                    y:
                        rect.height
                        * 0.34
                ),
            control1:
                CGPoint(
                    x:
                        rect.width
                        * 0.10,
                    y:
                        rect.height
                        * 0.52
                ),
            control2:
                CGPoint(
                    x:
                        rect.width
                        * 0.04,
                    y:
                        rect.height
                        * 0.46
                )
        )

        return path
    }
}

private enum Prompt16Palette {
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

    static let coral =
        Color(
            red: 0.91,
            green: 0.47,
            blue: 0.49
        )

    static let sage =
        Color(
            red: 0.55,
            green: 0.67,
            blue: 0.52
        )

    static let peach =
        Color(
            red: 0.91,
            green: 0.68,
            blue: 0.49
        )

    static let mutedOlive =
        Color(
            red: 0.72,
            green: 0.70,
            blue: 0.48
        )

    static let dustyBlue =
        Color(
            red: 0.64,
            green: 0.78,
            blue: 0.79
        )

    static let softYellow =
        Color(
            red: 0.92,
            green: 0.80,
            blue: 0.45
        )
}

private enum Prompt16Type {
    static let contextTitle =
        Font.custom(
            "Chalkboard SE",
            size: 20,
            relativeTo:
                .title3
        )
        .weight(
            .semibold
        )

    static let body =
        Font.custom(
            "Chalkboard SE",
            size: 14.5,
            relativeTo:
                .body
        )

    static let small =
        Font.custom(
            "Chalkboard SE",
            size: 11.5,
            relativeTo:
                .caption
        )

    static let dayLabel =
        Font.custom(
            "Chalkboard SE",
            size: 11,
            relativeTo:
                .caption
        )

    static let dayNumber =
        Font.custom(
            "Chalkboard SE",
            size: 24,
            relativeTo:
                .title2
        )
        .weight(
            .bold
        )

    static let wheelNumber =
        Font.custom(
            "Chalkboard SE",
            size: 32,
            relativeTo:
                .title
        )
        .weight(
            .bold
        )

    static let wheelCenter =
        Font.custom(
            "Chalkboard SE",
            size: 15,
            relativeTo:
                .body
        )

    static let wheelLabel =
        Font.custom(
            "Chalkboard SE",
            size: 11.5,
            relativeTo:
                .caption
        )

    static let wheelLabelSecondary =
        Font.custom(
            "Chalkboard SE",
            size: 9.5,
            relativeTo:
                .caption2
        )
}

#Preview {
    let settings =
        SettingsStore()

    Prompt16TodayView(
        onSeeBiology: {},
        onLogToday: {},
        onLogBBT: {},
        onPredictionInfoRequested: { _ in }
    )
    .padding(20)
    .background(
        DesignTokens
            .ColorToken
            .backgroundCream
    )
    .environmentObject(
        MotionPreferences()
    )
    .environmentObject(
        AudioManager(
            settings:
                settings
        )
    )
}
