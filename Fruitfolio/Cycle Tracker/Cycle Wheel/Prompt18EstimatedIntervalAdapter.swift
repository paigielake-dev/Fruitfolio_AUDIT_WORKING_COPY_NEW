import Foundation

public struct Prompt18EstimatedIntervalAdapter: Sendable {
    private let calendar: Calendar

    public init(calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
    }

    /// Converts already-computed estimated date windows into one-based cycle-day
    /// intervals for the renderer. This adapter performs coordinate conversion only;
    /// it does not predict ovulation or fertility.
    public func makeIntervals(
        cycleStartDate: Date,
        representedCycleLength: Int,
        estimatedOvulation: Prompt17DateWindow?,
        estimatedFertileWindow: Prompt17DateWindow?
    ) -> Prompt18EstimatedIntervals {
        guard representedCycleLength > 0 else {
            return .none
        }

        let start = calendar.startOfDay(for: cycleStartDate)

        return Prompt18EstimatedIntervals(
            estimatedOvulation: cycleDayInterval(
                window: estimatedOvulation,
                cycleStart: start,
                representedCycleLength: representedCycleLength
            ),
            estimatedFertileWindow: cycleDayInterval(
                window: estimatedFertileWindow,
                cycleStart: start,
                representedCycleLength: representedCycleLength
            )
        )
    }

    private func cycleDayInterval(
        window: Prompt17DateWindow?,
        cycleStart: Date,
        representedCycleLength: Int
    ) -> Prompt18CycleDayInterval? {
        guard let window,
              window.provenance == .estimated else {
            return nil
        }

        let startDate = calendar.startOfDay(for: window.start)
        let endDate = calendar.startOfDay(for: window.end)

        guard let startDelta = calendar.dateComponents(
            [.day],
            from: cycleStart,
            to: startDate
        ).day,
        let endDelta = calendar.dateComponents(
            [.day],
            from: cycleStart,
            to: endDate
        ).day else {
            return nil
        }

        let startDay = max(1, startDelta + 1)
        let endDay = min(representedCycleLength, endDelta + 1)

        guard startDay <= endDay else {
            return nil
        }

        return Prompt18CycleDayInterval(
            startDay: startDay,
            endDay: endDay,
            provenance: .estimated
        )
    }
}

