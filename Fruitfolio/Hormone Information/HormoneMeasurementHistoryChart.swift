import SwiftUI
import Charts

/// Comparisons never combine hormones, exact unit strings, or sample types.
/// Plotting coordinates are display-only; original result strings stay intact.
struct HormoneMeasurementSeries: Identifiable {
    struct Key: Hashable {
        let hormone: RecordedHormone
        let otherName: String
        let unit: String
        let sampleType: String
    }
    let id: Key
    let records: [HormoneMeasurement]
    static func groups(_ measurements: [HormoneMeasurement]) -> [Self] {
        let valid = measurements.filter { $0.validationError == nil && coordinate($0) != nil }
        return Dictionary(grouping: valid) {
            Key(hormone: $0.hormone, otherName: $0.hormone == .other ? $0.otherHormoneName : "",
                unit: $0.unit, sampleType: $0.sampleType)
        }.map { key, values in
            Self(id: key, records: Prompt22MeasurementPresentationPolicy.orderedReferences(values))
        }.sorted { $0.records[0].id.uuidString < $1.records[0].id.uuidString }
    }
    static func coordinate(_ record: HormoneMeasurement) -> Double? {
        let value = record.result.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let result = Double(value), result.isFinite else { return nil }
        return result
    }
}

struct HormoneMeasurementHistoryChart: View {
    let measurements: [HormoneMeasurement]
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        let groups = HormoneMeasurementSeries.groups(measurements)
        if !groups.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                Text("recorded measurements over time").font(.headline).accessibilityAddTraits(.isHeader)
                Text("each point is a result you entered, on its recorded test date. there are no estimated values or connecting curves. hormones, sample types, and exact units are shown separately.")
                ForEach(groups) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(group.records[0].displayName).fontWeight(.semibold)
                        Text(group.id.unit)
                        if !group.id.sampleType.isEmpty { Text(group.id.sampleType) }
                        Chart(group.records) { record in
                            if let value = HormoneMeasurementSeries.coordinate(record) {
                                PointMark(x: .value("test date", record.testDate), y: .value("recorded result", value))
                                    .symbol(.circle)
                                    .symbolSize(64)
                                    .foregroundStyle(DesignTokens.ColorToken.primaryBurgundy)
                                    .accessibilityLabel(Text(record.testDate, style: .date))
                                    .accessibilityValue(Text(record.result + " " + record.unit))
                            }
                        }
                        .chartYScale(domain: .automatic(includesZero: false))
                        .chartXAxisLabel("recorded test date")
                        .chartYAxisLabel(group.id.unit)
                        .frame(height: typeSize.isAccessibilitySize ? 300 : 220)
                        .accessibilityLabel("recorded measurements; individual points only")
                        // Always retain a readable exact-value alternative;
                        // chart scaling and Double precision never replace it.
                        ForEach(group.records) { record in
                            HStack(alignment: .top) {
                                Text(record.testDate, style: .date)
                                Spacer()
                                Text(record.result + " " + record.unit)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .accessibilityIdentifier("hormone.history.series." + group.records[0].id.uuidString)
                }
            }
            .accessibilityIdentifier("hormone.history.actualPoints")
        }
    }
}
