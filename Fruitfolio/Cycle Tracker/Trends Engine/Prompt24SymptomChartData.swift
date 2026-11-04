import Foundation

/// One recorded-observation timeline. Missing cycle assignments never become
/// invented cycle days, and an explicitly empty selection remains empty.
nonisolated struct Prompt24SymptomChartData: Sendable {
    let occurrences: [Prompt24SymptomOccurrence]
    let symptoms: [Prompt20SymptomID]

    static func selection(_ previous: Set<Prompt20SymptomID>?, available: Set<Prompt20SymptomID>) -> Set<Prompt20SymptomID> {
        previous.map { $0.intersection(available) } ?? available
    }

    init(occurrences: [Prompt24SymptomOccurrence], selected: Set<Prompt20SymptomID>) {
        self.occurrences = occurrences.filter { selected.contains($0.symptomID) && $0.date.timeIntervalSince1970.isFinite }
            .sorted { $0.date == $1.date ? $0.symptomID.rawValue < $1.symptomID.rawValue : $0.date < $1.date }
        symptoms = Array(Set(self.occurrences.map(\.symptomID))).sorted { $0.displayName < $1.displayName }
    }

    func dateFraction(_ occurrence: Prompt24SymptomOccurrence) -> Double {
        guard let first = occurrences.first?.date, let last = occurrences.last?.date, last > first else { return 0.5 }
        return min(max(occurrence.date.timeIntervalSince(first) / last.timeIntervalSince(first), 0), 1)
    }
}
