import Foundation

public nonisolated enum Prompt20RecordedProvenance: String, Codable, Sendable {
    case recorded
}

public nonisolated struct Prompt20DailyLogOwnerID: Hashable, Codable, Sendable, RawRepresentable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let localDevice = Self(rawValue: "local-device")
}


public struct Prompt20DailyLogRequest: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let selectedDate: Date
    public let initialSection: Prompt20DailyLogSection?

    public init(
        id: UUID = UUID(),
        selectedDate: Date,
        initialSection: Prompt20DailyLogSection? = nil
    ) {
        self.id = id
        self.selectedDate = selectedDate
        self.initialSection = initialSection
    }
}

public nonisolated struct Prompt20LocalDay: Hashable, Codable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    public func date(in calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}

public nonisolated enum Prompt20BleedingLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case none
    case spotting
    case light
    case medium
    case heavy

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: "none"
        case .spotting: "spotting"
        case .light: "light"
        case .medium: "medium"
        case .heavy: "heavy"
        }
    }
}

public nonisolated enum Prompt20PeriodEvent: String, CaseIterable, Codable, Sendable, Identifiable {
    case started
    case ended

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .started: "my period started"
        case .ended: "my period ended"
        }
    }
}

public nonisolated struct Prompt20BleedingObservation: Codable, Equatable, Sendable {
    public var level: Prompt20BleedingLevel
    public var note: String
    public let provenance: Prompt20RecordedProvenance

    public init(
        level: Prompt20BleedingLevel,
        note: String = "",
        provenance: Prompt20RecordedProvenance = .recorded
    ) {
        self.level = level
        self.note = note
        self.provenance = provenance
    }
}

public nonisolated enum Prompt20SymptomID: String, CaseIterable, Codable, Sendable, Identifiable {
    case cramps
    case bloating
    case headache
    case breastTenderness = "breast_tenderness"
    case fatigue
    case moodChanges = "mood_changes"
    case skinChanges = "skin_changes"
    case brainFog = "brain_fog"
    case nausea
    case lowerBackPain = "lower_back_pain"
    case cravings
    case hydration
    case exercise
    case sleepChanges = "sleep_changes"
    case digestiveChanges = "digestive_changes"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cramps: "cramps"
        case .bloating: "bloating"
        case .headache: "headache"
        case .breastTenderness: "breast tenderness"
        case .fatigue: "fatigue"
        case .moodChanges: "mood changes"
        case .skinChanges: "skin changes"
        case .brainFog: "brain fog"
        case .nausea: "nausea"
        case .lowerBackPain: "lower back pain"
        case .cravings: "cravings"
        case .hydration: "hydration"
        case .exercise: "exercise"
        case .sleepChanges: "sleep changes"
        case .digestiveChanges: "digestive changes"
        }
    }

    public var group: Prompt20SymptomGroup {
        switch self {
        case .cramps, .bloating, .headache, .breastTenderness, .nausea, .lowerBackPain, .skinChanges, .hydration, .exercise:
            .body
        case .fatigue, .sleepChanges, .brainFog:
            .energySleep
        case .moodChanges:
            .mood
        case .cravings, .digestiveChanges:
            .digestion
        }
    }
}

public nonisolated enum Prompt20SymptomGroup: String, CaseIterable, Sendable, Identifiable {
    case body
    case energySleep
    case mood
    case digestion

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .body: "body"
        case .energySleep: "energy + sleep"
        case .mood: "mood"
        case .digestion: "digestion"
        }
    }
}

public nonisolated struct Prompt20SymptomObservation: Codable, Equatable, Sendable {
    public var selectedIDs: Set<Prompt20SymptomID>
    public var note: String
    public let provenance: Prompt20RecordedProvenance

    public init(
        selectedIDs: Set<Prompt20SymptomID> = [],
        note: String = "",
        provenance: Prompt20RecordedProvenance = .recorded
    ) {
        self.selectedIDs = selectedIDs
        self.note = note
        self.provenance = provenance
    }
}

public nonisolated enum Prompt20TemperatureUnit: String, CaseIterable, Codable, Sendable, Identifiable {
    case fahrenheit
    case celsius

    public var id: String { rawValue }

    public var symbol: String {
        switch self {
        case .fahrenheit: "°F"
        case .celsius: "°C"
        }
    }
}

public nonisolated enum Prompt20TemperatureReadingType: String, CaseIterable, Codable, Sendable, Identifiable {
    case basalWaking = "basal_waking"
    case general

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .basalWaking: "basal / waking"
        case .general: "general temperature"
        }
    }
}

public nonisolated struct Prompt20TemperatureObservation: Codable, Equatable, Sendable {
    public var originalValue: Double
    public var originalUnit: Prompt20TemperatureUnit
    public var readingType: Prompt20TemperatureReadingType?
    public var note: String
    public let provenance: Prompt20RecordedProvenance

    public init(
        originalValue: Double,
        originalUnit: Prompt20TemperatureUnit,
        readingType: Prompt20TemperatureReadingType? = nil,
        note: String = "",
        provenance: Prompt20RecordedProvenance = .recorded
    ) {
        self.originalValue = originalValue
        self.originalUnit = originalUnit
        self.readingType = readingType
        self.note = note
        self.provenance = provenance
    }

    public var canonicalCelsius: Double {
        switch originalUnit {
        case .celsius:
            originalValue
        case .fahrenheit:
            (originalValue - 32.0) * 5.0 / 9.0
        }
    }

    public func value(in unit: Prompt20TemperatureUnit) -> Double {
        switch unit {
        case .celsius:
            canonicalCelsius
        case .fahrenheit:
            canonicalCelsius * 9.0 / 5.0 + 32.0
        }
    }
}

public nonisolated enum Prompt20CervicalFluidCategory: String, CaseIterable, Codable, Sendable, Identifiable {
    case dry
    case sticky
    case creamy
    case watery
    case eggWhiteStretchy = "egg_white_stretchy"
    case unsure

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .dry: "none / dry"
        case .sticky: "sticky"
        case .creamy: "creamy"
        case .watery: "watery"
        case .eggWhiteStretchy: "egg-white / stretchy"
        case .unsure: "unsure"
        }
    }
}

public nonisolated struct Prompt20CervicalFluidObservation: Codable, Equatable, Sendable {
    public var category: Prompt20CervicalFluidCategory
    public var note: String
    public let provenance: Prompt20RecordedProvenance

    public init(
        category: Prompt20CervicalFluidCategory,
        note: String = "",
        provenance: Prompt20RecordedProvenance = .recorded
    ) {
        self.category = category
        self.note = note
        self.provenance = provenance
    }
}

public nonisolated struct Prompt20MedicationEntry: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var dose: String
    public var time: String
    public var note: String
    public let provenance: Prompt20RecordedProvenance

    public init(
        id: UUID = UUID(),
        name: String = "",
        dose: String = "",
        time: String = "",
        note: String = "",
        provenance: Prompt20RecordedProvenance = .recorded
    ) {
        self.id = id
        self.name = name
        self.dose = dose
        self.time = time
        self.note = note
        self.provenance = provenance
    }

    public var hasAnyContent: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !dose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !time.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public nonisolated struct Prompt20GeneralNote: Codable, Equatable, Sendable {
    public var text: String
    public let provenance: Prompt20RecordedProvenance

    public init(text: String, provenance: Prompt20RecordedProvenance = .recorded) {
        self.text = text
        self.provenance = provenance
    }
}

public nonisolated struct Prompt20DailyLog: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let ownerID: Prompt20DailyLogOwnerID
    public let date: Prompt20LocalDay
    public var periodEvent: Prompt20PeriodEvent?
    public var bleeding: Prompt20BleedingObservation?
    public var symptoms: Prompt20SymptomObservation?
    public var temperature: Prompt20TemperatureObservation?
    public var cervicalFluid: Prompt20CervicalFluidObservation?
    public var medications: [Prompt20MedicationEntry]
    public var generalNote: Prompt20GeneralNote?
    public let createdAt: Date
    public var updatedAt: Date
    public var revision: Int
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        ownerID: Prompt20DailyLogOwnerID,
        date: Prompt20LocalDay,
        periodEvent: Prompt20PeriodEvent? = nil,
        bleeding: Prompt20BleedingObservation? = nil,
        symptoms: Prompt20SymptomObservation? = nil,
        temperature: Prompt20TemperatureObservation? = nil,
        cervicalFluid: Prompt20CervicalFluidObservation? = nil,
        medications: [Prompt20MedicationEntry] = [],
        generalNote: Prompt20GeneralNote? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        revision: Int = 1,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.ownerID = ownerID
        self.date = date
        self.periodEvent = periodEvent
        self.bleeding = bleeding
        self.symptoms = symptoms
        self.temperature = temperature
        self.cervicalFluid = cervicalFluid
        self.medications = medications
        self.generalNote = generalNote
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.revision = revision
        self.isDeleted = isDeleted
    }

    public var hasRecordedContent: Bool {
        periodEvent != nil ||
        bleeding != nil ||
        symptoms != nil ||
        temperature != nil ||
        cervicalFluid != nil ||
        !medications.isEmpty ||
        generalNote != nil
    }
}

public struct Prompt20DailyLogDraft: Equatable, Sendable {
    public var periodEvent: Prompt20PeriodEvent?
    public var bleedingLevel: Prompt20BleedingLevel?
    public var bleedingNote = ""
    public var selectedSymptoms: Set<Prompt20SymptomID> = []
    public var symptomNote = ""
    public var temperatureText = ""
    public var temperatureUnit: Prompt20TemperatureUnit = .fahrenheit
    public var temperatureReadingType: Prompt20TemperatureReadingType?
    public var temperatureNote = ""
    public var cervicalFluidCategory: Prompt20CervicalFluidCategory?
    public var cervicalFluidNote = ""
    public var medications: [Prompt20MedicationEntry] = []
    public var generalNote = ""

    public init() {}

    public init(log: Prompt20DailyLog, displayTemperatureUnit: Prompt20TemperatureUnit) {
        periodEvent = log.periodEvent
        bleedingLevel = log.bleeding?.level
        bleedingNote = log.bleeding?.note ?? ""
        selectedSymptoms = log.symptoms?.selectedIDs ?? []
        symptomNote = log.symptoms?.note ?? ""
        temperatureUnit = displayTemperatureUnit
        if let temperature = log.temperature {
            temperatureText = Prompt20TemperatureFormatter.string(
                temperature.value(in: displayTemperatureUnit),
                unit: displayTemperatureUnit
            )
            temperatureReadingType = temperature.readingType
            temperatureNote = temperature.note
        }
        cervicalFluidCategory = log.cervicalFluid?.category
        cervicalFluidNote = log.cervicalFluid?.note ?? ""
        medications = log.medications
        generalNote = log.generalNote?.text ?? ""
    }

    public var hasAnyContent: Bool {
        periodEvent != nil ||
        bleedingLevel != nil ||
        !bleedingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !selectedSymptoms.isEmpty ||
        !symptomNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !temperatureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        temperatureReadingType != nil ||
        !temperatureNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        cervicalFluidCategory != nil ||
        !cervicalFluidNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        medications.contains(where: \.hasAnyContent) ||
        !generalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public enum Prompt20TemperatureFormatter {
    public static func string(_ value: Double, unit: Prompt20TemperatureUnit) -> String {
        let places = unit == .fahrenheit ? 1 : 2
        return String(format: "%.*f", places, value)
    }
}

public enum Prompt20DailyLogSection: String, CaseIterable, Identifiable, Sendable {
    case bleeding
    case symptoms
    case temperature
    case cervicalFluid
    case medication
    case notes

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .bleeding: "bleeding"
        case .symptoms: "symptoms"
        case .temperature: "temperature"
        case .cervicalFluid: "cervical fluid"
        case .medication: "medication"
        case .notes: "notes"
        }
    }

    public var assetName: String {
        switch self {
        case .bleeding: "symptom_bleeding_pad"
        case .symptoms: "symptom_cramps"
        case .temperature: "cycle_bbt_thermometer"
        case .cervicalFluid: "symptom_cervical_fluid"
        case .medication: "symptom_medication"
        case .notes: "symptom_notes"
        }
    }

    public func hasContent(in draft: Prompt20DailyLogDraft) -> Bool {
        switch self {
        case .bleeding:
            draft.periodEvent != nil ||
            draft.bleedingLevel != nil ||
            !draft.bleedingNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .symptoms:
            !draft.selectedSymptoms.isEmpty ||
            !draft.symptomNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .temperature:
            !draft.temperatureText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            draft.temperatureReadingType != nil ||
            !draft.temperatureNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .cervicalFluid:
            draft.cervicalFluidCategory != nil ||
            !draft.cervicalFluidNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .medication:
            draft.medications.contains(where: \.hasAnyContent)
        case .notes:
            !draft.generalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    public func summary(in draft: Prompt20DailyLogDraft) -> String? {
        switch self {
        case .bleeding:
            if let periodEvent = draft.periodEvent {
                return periodEvent.displayName
            }
            return draft.bleedingLevel?.displayName
        case .symptoms:
            let names = draft.selectedSymptoms.sorted { $0.rawValue < $1.rawValue }
            guard let first = names.first else {
                return draft.symptomNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "note added"
            }
            let extra = names.count - 1
            return extra > 0 ? "\(first.displayName) + \(extra) more" : first.displayName
        case .temperature:
            let value = draft.temperatureText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return nil }
            let kind = draft.temperatureReadingType?.displayName
            return kind.map { "\(value)\(draft.temperatureUnit.symbol) · \($0)" }
                ?? "\(value)\(draft.temperatureUnit.symbol)"
        case .cervicalFluid:
            return draft.cervicalFluidCategory?.displayName
        case .medication:
            let count = draft.medications.filter(\.hasAnyContent).count
            guard count > 0 else { return nil }
            return count == 1 ? "1 entry" : "\(count) entries"
        case .notes:
            return draft.generalNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : "note added"
        }
    }
}
