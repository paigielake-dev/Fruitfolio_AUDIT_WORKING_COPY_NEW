import Foundation

/// Explicit, single-question snapshot. Not Codable as a whole, never stored in
/// messages, answers, analytics or Research Library caches.
nonisolated struct FruitfolioAskUserContext: Equatable, Sendable {
    struct Record: Codable, Equatable, Sendable {
        let kind: String
        let sourceID: String
        let provenance: String
        let fields: [String: String]
    }
    let records: [Record]
    let topicHints: [String]
    static let maximumJSONBytes = 6_000
    enum Failure: LocalizedError {
        case tooLarge
        var errorDescription: String? { "choose fewer context items for this question. nothing has been shared yet." }
    }
    func promptJSON() throws -> String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(records)
        guard data.count <= Self.maximumJSONBytes else { throw Failure.tooLarge }
        return String(decoding: data, as: UTF8.self)
    }

    static func selected(measurementIDs: Set<UUID>, personalCategories: Set<FruitfolioPersonalHealthCategory>,
        measurements: [FruitfolioHormoneMeasurement], context: Prompt27AUserReproductiveContext) throws -> Self? {
        var records: [Record] = []
        var hints: Set<String> = []
        for measurement in measurements.filter({ measurementIDs.contains($0.id) }).sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            var fields = ["hormone": measurement.hormoneName, "result_exactly_as_entered": measurement.result,
                "unit_exactly_as_entered": measurement.unit, "test_date": measurement.testDate.ISO8601Format(),
                "sample_type_user_reported": measurement.sampleType, "laboratory_reference_range_user_reported": measurement.laboratoryReferenceRange,
                "notes_user_reported": measurement.notes]
            if let day = measurement.cycleDay { fields["cycle_day_user_reported"] = String(day) }
            if let locale = measurement.resultLocaleIdentifier { fields["result_entry_locale"] = locale }
            records.append(.init(kind: "recorded_hormone_measurement", sourceID: measurement.id.uuidString,
                provenance: "user_reported_not_clinically_verified", fields: fields))
            // Only a known hormone name may augment retrieval. Free-form Other
            // labels and notes cannot inject search instructions or diagnoses.
            if measurement.hormone != .other { hints.insert(measurement.hormone.label) }
        }
        for category in personalCategories.sorted(by: { $0.rawValue < $1.rawValue }) {
            guard let entry = context.personalHealthEntries[category.rawValue], entry.status == .provided,
                  let text = entry.text else { continue }
            records.append(.init(kind: "personal_health_context", sourceID: category.rawValue,
                provenance: entry.provenance == .userReportsClinicianConfirmed
                    ? "clinician_confirmation_reported_by_user_not_verified_by_fruitfolio" : "user_reported_not_clinically_verified", fields: ["category": category.title, "text_user_reported": text,
                    "updated_at": entry.updatedAt.ISO8601Format()]))
            hints.insert(category.title)
        }
        guard !records.isEmpty else { return nil }
        let snapshot = Self(records: records, topicHints: hints.sorted())
        _ = try snapshot.promptJSON()
        return snapshot
    }
}
