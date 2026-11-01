import SwiftUI

/// One faithful, read-only presentation shared by the record manager and the
/// educational view's explicit My Measurements mode. No result interpretation.
struct HormoneMeasurementSummaryView: View {
    let record: HormoneMeasurement
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(record.displayName).bold()
            Text(record.result + " " + record.unit).textSelection(.enabled)
            Text(record.testDate, style: .date)
            if !record.sampleType.isEmpty { Text(record.sampleType) }
            if !record.cycleDay.isEmpty { Text("cycle day: \(record.cycleDay)") }
            if !record.laboratoryReferenceRange.isEmpty {
                Text("laboratory-provided reference range: \(record.laboratoryReferenceRange)")
            }
            if !record.notes.isEmpty { Text(record.notes).textSelection(.enabled) }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
