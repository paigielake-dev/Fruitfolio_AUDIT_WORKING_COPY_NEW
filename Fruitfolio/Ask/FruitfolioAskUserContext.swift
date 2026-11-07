import Foundation

/// Fixed privacy copy is identified by type, never by matching error text.
nonisolated enum FruitfolioAskContextNotice: Equatable, Sendable {
    case selectionChanged(wasInFlight: Bool)
    case changedBeforeSending
    case questionChangedBeforeSending
    case requestInterrupted(wasUsingContext: Bool)
    case singleQuestionEducation
    case tooLarge
    case external(String)

    init(error: any Error) {
        if let failure = error as? FruitfolioAskUserContext.Failure {
            switch failure { case .tooLarge: self = .tooLarge }
        } else { self = .external(error.localizedDescription) }
    }

    var text: String {
        switch self {
        case .selectionChanged(let wasInFlight):
            return wasInFlight
                ? "your health context changed. that request was cancelled; choose current records before asking again."
                : "your health context changed. choose the current records again before sharing them."
        case .requestInterrupted(let wasUsingContext):
            return wasUsingContext
                ? "this request was cancelled when the app became inactive. choose current context again before asking."
                : "this request was cancelled when the app became inactive. your question is preserved; ask again when you are ready."
        case .changedBeforeSending:
            return "your context changed before sending. choose current records again."
        case .questionChangedBeforeSending:
            return "your question changed before it was sent. your current draft is still here; choose any context again before sending."
        case .singleQuestionEducation:
            return "selected context is used only for this question; these are educational research excerpts, not a clinical interpretation."
        case .tooLarge:
            return "choose fewer context items for this question. nothing has been shared yet."
        case .external(let text): return text
        }
    }
    var fixedSource: String? {
        if case .external = self { return nil }
        return text
    }
}

nonisolated struct FruitfolioAskContextSelectionCopy: Sendable {
    let source: String
    let protectedLiterals: [String]
    init(count: Int, locale: Locale) {
        let number = count.formatted(.number.locale(locale))
        source = "\(number) selected for one question"
        protectedLiterals = [number]
    }
}

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
        var errorDescription: String? { FruitfolioAskContextNotice.tooLarge.text }
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
                "unit_exactly_as_entered": measurement.unit,
                "test_date_gregorian": measurement.dayForOrdering()?.description ?? "unavailable",
                "test_time_of_day": "not_recorded",
                "test_date_precision": measurement.testDatePrecision?.rawValue ?? "legacy_precision_not_recorded",
                "test_date_basis": measurement.reportedTestDay == nil
                    ? "date_value_in_current_timezone_original_entry_timezone_unknown" : "explicit_user_entered_civil_day",
                "sample_type_user_reported": measurement.sampleType, "laboratory_reference_range_user_reported": measurement.laboratoryReferenceRange,
                "notes_user_reported": measurement.notes]
            if let zone = measurement.testDateEntryTimeZoneIdentifier { fields["date_entry_timezone_not_test_location"] = zone }
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

#if DEBUG
/// Uses only caller-supplied regression preferences. Missing/protected storage
/// fails closed; remounting never overwrites records or resurrects a deletion.
@MainActor
final class FruitfolioAskContextRegressionFixture {
    static let storageKey = "fruitfolio.askContextQA.measurements.v1"
    static let libraryStorageKey = "fruitfolio.askContextQA.library.v1"
    let measurements: FruitfolioHormoneMeasurementStore?
    let savedLibrary: Prompt10SavedLibraryStore?
    let failureMessage: String?
    init(defaults: UserDefaults?) {
        let failure = "Ask regression environment could not be created; original data was preserved."
        guard let defaults else {
            measurements = nil; savedLibrary = nil; failureMessage = failure; return
        }
        let candidate = FruitfolioHormoneMeasurementStore(defaults: defaults, key: Self.storageKey)
        guard !candidate.storageUnreadable, candidate.storageProtectionReason == nil else {
            measurements = nil; savedLibrary = nil; failureMessage = failure; return
        }
        do {
            if defaults.object(forKey: Self.storageKey) == nil {
                var fixture = FruitfolioHormoneMeasurement()
                fixture.hormone = .progesterone; fixture.result = "12.50"; fixture.unit = "ng/mL"
                fixture.notes = "QA explicitly selected fixture context"
                try candidate.save(fixture, locale: Locale(identifier: "en_US"))
            }
            measurements = candidate
            savedLibrary = Prompt10SavedLibraryStore(defaults: defaults, persistenceKey: Self.libraryStorageKey)
            failureMessage = nil
        } catch {
            measurements = nil; savedLibrary = nil; failureMessage = failure
        }
    }
}
#if canImport(Combine)
import Combine
extension FruitfolioAskContextRegressionFixture: ObservableObject {}
#endif
#endif
