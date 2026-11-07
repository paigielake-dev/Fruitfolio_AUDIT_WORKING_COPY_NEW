import Foundation

/// View-time suppression is pure and immediate. A cached/earlier month result
/// cannot keep showing estimates after relevant user context changes. Recorded
/// observations, notes and temperatures remain untouched.
nonisolated enum Prompt19CalendarPresentationPolicy {
    static func annotations(_ original: [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation],
        context: Prompt27AContextPolicyResult) -> [Prompt19CalendarDateKey: Prompt19CalendarDayAnnotation] {
        let adapter = Prompt27AExistingSystemPolicyAdapter(result: context)
        return original.mapValues { value in
            var shown = value
            if !adapter.showCurrentNextPeriodPrediction { shown.predictedPeriod = false }
            if !adapter.showCurrentFertileWindowPrediction { shown.fertileEstimated = false }
            if !adapter.showCurrentOvulationPrediction { shown.ovulationEstimated = false }
            return shown
        }
    }
}
nonisolated struct Prompt19CalendarLoadIdentity: Equatable, Sendable {
    let month: Prompt19CalendarMonth
    let context: Prompt27AContextPolicyResult
    let presentationEpoch: UUID?
    init(month: Prompt19CalendarMonth, context: Prompt27AContextPolicyResult, presentationEpoch: UUID? = nil) {
        self.month = month
        self.context = context
        self.presentationEpoch = presentationEpoch
    }
    func accepts(_ snapshot: Prompt19CalendarSnapshot, current: Self) -> Bool {
        self == current && snapshot.month == month
    }
}
