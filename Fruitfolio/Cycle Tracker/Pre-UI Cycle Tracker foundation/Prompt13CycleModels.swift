import Foundation

// MARK: - Provenance

nonisolated enum BiologicalDataProvenance: String, Codable, CaseIterable, Sendable {
    case recorded
    case calculated
    case estimated
    case educational
}

nonisolated enum Prompt13DataPresence: String, Codable, Sendable {
    case unknown
    case none
    case notApplicable = "not_applicable"
    case recordedNegative = "recorded_negative"
    case recordedValue = "recorded_value"
}

nonisolated enum Prompt13CycleConfidence: String, Codable, CaseIterable, Sendable {
    case limited
    case developing
    case strong

    var userFacingLabel: String {
        switch self {
        case .limited:
            return "limited estimate"
        case .developing:
            return "developing estimate"
        case .strong:
            return "strong estimate"
        }
    }
}

// MARK: - Calendar-safe date

/// A pure calendar date. It intentionally does not contain a time zone or elapsed-hour meaning.
/// Cycle relationships use this value so DST, travel, and midnight boundaries cannot alter a stored event date.
nonisolated struct Prompt13LocalDate: Codable, Hashable, Comparable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    init(
        year: Int,
        month: Int,
        day: Int
    ) throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        guard let date = calendar.date(from: components) else {
            throw Prompt13CycleError.invalidDate
        }

        let check = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard
            check.year == year,
            check.month == month,
            check.day == day
        else {
            throw Prompt13CycleError.invalidDate
        }

        self.year = year
        self.month = month
        self.day = day
    }

    init(
        _ date: Date,
        calendar: Calendar
    ) throws {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        guard
            let year = components.year,
            let month = components.month,
            let day = components.day
        else {
            throw Prompt13CycleError.invalidDate
        }

        try self.init(
            year: year,
            month: month,
            day: day
        )
    }

    var description: String {
        String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }

    static func < (
        lhs: Prompt13LocalDate,
        rhs: Prompt13LocalDate
    ) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }

        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }

        return lhs.day < rhs.day
    }

    func addingDays(
        _ days: Int
    ) throws -> Prompt13LocalDate {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let base = try utcNoonDate(
            calendar: calendar
        )

        guard let result = calendar.date(
            byAdding: .day,
            value: days,
            to: base
        ) else {
            throw Prompt13CycleError.invalidDate
        }

        return try Prompt13LocalDate(
            result,
            calendar: calendar
        )
    }

    func days(
        to other: Prompt13LocalDate
    ) throws -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let start = try utcNoonDate(
            calendar: calendar
        )

        let end = try other.utcNoonDate(
            calendar: calendar
        )

        guard let value = calendar.dateComponents(
            [.day],
            from: start,
            to: end
        ).day else {
            throw Prompt13CycleError.invalidDate
        }

        return value
    }

    private func utcNoonDate(
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()

        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12

        guard let date = calendar.date(
            from: components
        ) else {
            throw Prompt13CycleError.invalidDate
        }

        return date
    }
}

// MARK: - Shared metadata

nonisolated struct Prompt13RecordMetadata: Codable, Equatable, Sendable {
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?
    var revision: Int
    var localProfileID: UUID
    var accountID: UUID?
    var deviceID: UUID?

    init(
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        revision: Int = 1,
        localProfileID: UUID,
        accountID: UUID? = nil,
        deviceID: UUID? = nil
    ) {
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.revision = max(
            1,
            revision
        )
        self.localProfileID = localProfileID
        self.accountID = accountID
        self.deviceID = deviceID
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    mutating func touch(
        at date: Date
    ) {
        updatedAt = date
        revision += 1
    }

    mutating func softDelete(
        at date: Date
    ) {
        deletedAt = date
        touch(
            at: date
        )
    }

    mutating func restore(
        at date: Date
    ) {
        deletedAt = nil
        touch(
            at: date
        )
    }
}

// MARK: - Core models

nonisolated enum Prompt13CycleStartSource: String, Codable, Sendable {
    case userConfirmed = "user_confirmed"
    case importedUserRecord = "imported_user_record"
    case onboardingConfirmed = "onboarding_confirmed"
}

nonisolated struct CycleStart: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var date: Prompt13LocalDate
    var source: Prompt13CycleStartSource
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        date: Prompt13LocalDate,
        source: Prompt13CycleStartSource = .userConfirmed,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.date = date
        self.source = source
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated enum Prompt13CycleStatus: String, Codable, Sendable {
    case open
    case complete
    case needsReview = "needs_review"
}

nonisolated struct Cycle: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let startID: UUID
    let nextStartID: UUID?
    let startDate: Prompt13LocalDate
    let endDate: Prompt13LocalDate?
    let observedLength: Int?
    let status: Prompt13CycleStatus
    let informationType: BiologicalDataProvenance
    let generatedAt: Date

    init(
        id: UUID,
        startID: UUID,
        nextStartID: UUID?,
        startDate: Prompt13LocalDate,
        endDate: Prompt13LocalDate?,
        observedLength: Int?,
        status: Prompt13CycleStatus,
        generatedAt: Date
    ) {
        self.id = id
        self.startID = startID
        self.nextStartID = nextStartID
        self.startDate = startDate
        self.endDate = endDate
        self.observedLength = observedLength
        self.status = status
        self.informationType = .calculated
        self.generatedAt = generatedAt
    }
}

nonisolated struct DailyLog: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var date: Prompt13LocalDate
    var cycleID: UUID?
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        date: Prompt13LocalDate,
        cycleID: UUID? = nil,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.date = date
        self.cycleID = cycleID
        self.metadata = metadata
    }
}

nonisolated enum Prompt13BleedingFlowLevel: String, Codable, CaseIterable, Sendable {
    case none
    case spotting
    case light
    case medium
    case heavy
}

nonisolated struct BleedingObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var flowLevel: Prompt13BleedingFlowLevel
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        flowLevel: Prompt13BleedingFlowLevel,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.flowLevel = flowLevel
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated enum Prompt13SymptomType: String, Codable, CaseIterable, Sendable {
    case cramps
    case bloating
    case headache
    case breastTenderness = "breast_tenderness"
    case fatigue
    case moodChanges = "mood_changes"
    case skin
    case nausea
    case backPain = "back_pain"
    case appetite
    case sleep
    case libido
    case digestiveChanges = "digestive_changes"
    case brainFog = "brain_fog"
    case energy
    case hydration
    case exercise
    case other
}

nonisolated enum Prompt13SymptomSeverity: String, Codable, CaseIterable, Sendable {
    case none
    case mild
    case moderate
    case severe
}

nonisolated struct SymptomObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var symptomType: Prompt13SymptomType
    var severity: Prompt13SymptomSeverity
    var userLabel: String?
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        symptomType: Prompt13SymptomType,
        severity: Prompt13SymptomSeverity,
        userLabel: String? = nil,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.symptomType = symptomType
        self.severity = severity
        self.userLabel = userLabel
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated enum Prompt13TemperatureUnit: String, Codable, CaseIterable, Sendable {
    case fahrenheit
    case celsius
}

nonisolated enum Prompt13TemperatureMeasurementContext: String, Codable, Sendable {
    case basal
    case waking
    case general
    case other
}

nonisolated struct TemperatureObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate

    let originalValue: Double
    let originalUnit: Prompt13TemperatureUnit
    let canonicalCelsius: Double

    var timeRecorded: Date?
    var measurementContext: Prompt13TemperatureMeasurementContext

    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        value: Double,
        unit: Prompt13TemperatureUnit,
        timeRecorded: Date? = nil,
        measurementContext: Prompt13TemperatureMeasurementContext = .basal,
        metadata: Prompt13RecordMetadata
    ) throws {
        guard value.isFinite else {
            throw Prompt13CycleError.invalidTemperature
        }

        let celsius: Double

        switch unit {
        case .celsius:
            celsius = value

        case .fahrenheit:
            celsius =
                (value - 32.0) *
                (5.0 / 9.0)
        }

        guard
            (-100.0 ... 100.0)
                .contains(celsius)
        else {
            throw Prompt13CycleError.invalidTemperature
        }

        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.originalValue = value
        self.originalUnit = unit
        self.canonicalCelsius = celsius
        self.timeRecorded = timeRecorded
        self.measurementContext = measurementContext
        self.informationType = .recorded
        self.metadata = metadata
    }

    func displayValue(
        in unit: Prompt13TemperatureUnit
    ) -> Double {
        switch unit {
        case .celsius:
            return canonicalCelsius

        case .fahrenheit:
            return
                canonicalCelsius *
                (9.0 / 5.0) +
                32.0
        }
    }
}

nonisolated enum Prompt13CervicalFluidCategory: String, Codable, CaseIterable, Sendable {
    case dry
    case sticky
    case creamy
    case watery
    case slipperyEggWhiteLike = "slippery_egg_white_like"
    case other
}

nonisolated struct CervicalFluidObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var category: Prompt13CervicalFluidCategory
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        category: Prompt13CervicalFluidCategory,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.category = category
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated struct MedicationObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var medicationName: String
    var dose: Double?
    var unit: String?
    var time: Date?
    var userNote: String?
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        medicationName: String,
        dose: Double? = nil,
        unit: String? = nil,
        time: Date? = nil,
        userNote: String? = nil,
        metadata: Prompt13RecordMetadata
    ) throws {
        let cleanName =
            medicationName
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !cleanName.isEmpty else {
            throw Prompt13CycleError.invalidMedicationName
        }

        if let dose,
           (!dose.isFinite || dose < 0) {
            throw Prompt13CycleError.invalidDose
        }

        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.medicationName = cleanName
        self.dose = dose
        self.unit = unit
        self.time = time
        self.userNote = userNote
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated struct Note: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var text: String
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        text: String,
        metadata: Prompt13RecordMetadata
    ) throws {
        let clean =
            text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !clean.isEmpty else {
            throw Prompt13CycleError.emptyNote
        }

        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.text = clean
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated enum Prompt13PregnancyTestResult: String, Codable, CaseIterable, Sendable {
    case positive
    case negative
    case unclear
    case invalid
}

nonisolated struct PregnancyTestObservation: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    var dailyLogID: UUID?
    var cycleID: UUID?
    var date: Prompt13LocalDate
    var result: Prompt13PregnancyTestResult
    var timeRecorded: Date?
    var userNote: String?
    let informationType: BiologicalDataProvenance
    var metadata: Prompt13RecordMetadata

    init(
        id: UUID = UUID(),
        dailyLogID: UUID? = nil,
        cycleID: UUID? = nil,
        date: Prompt13LocalDate,
        result: Prompt13PregnancyTestResult,
        timeRecorded: Date? = nil,
        userNote: String? = nil,
        metadata: Prompt13RecordMetadata
    ) {
        self.id = id
        self.dailyLogID = dailyLogID
        self.cycleID = cycleID
        self.date = date
        self.result = result
        self.timeRecorded = timeRecorded
        self.userNote = userNote
        self.informationType = .recorded
        self.metadata = metadata
    }
}

nonisolated enum Prompt13PredictionType: String, Codable, CaseIterable, Sendable {
    case nextPeriod = "next_period"
    case fertileWindow = "fertile_window"
    case ovulation
    case cycleLength = "cycle_length"
    case phase
}

nonisolated struct PredictionSnapshot: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let generatedAt: Date
    let predictionType: Prompt13PredictionType
    let targetDate: Prompt13LocalDate?
    let dateRangeStart: Prompt13LocalDate?
    let dateRangeEnd: Prompt13LocalDate?
    let predictedCycleLength: Int?
    let confidence: Prompt13CycleConfidence
    let inputCycleIDs: [UUID]
    let inputObservationIDs: [UUID]
    let methodVersion: String
    let sourceObservationIDs: [UUID]
    let informationType: BiologicalDataProvenance
    let validFrom: Date
    let validUntil: Date?

    init(
        id: UUID = UUID(),
        generatedAt: Date,
        predictionType: Prompt13PredictionType,
        targetDate: Prompt13LocalDate? = nil,
        dateRangeStart: Prompt13LocalDate? = nil,
        dateRangeEnd: Prompt13LocalDate? = nil,
        predictedCycleLength: Int? = nil,
        confidence: Prompt13CycleConfidence,
        inputCycleIDs: [UUID],
        inputObservationIDs: [UUID] = [],
        methodVersion: String,
        sourceObservationIDs: [UUID] = [],
        validFrom: Date,
        validUntil: Date? = nil
    ) {
        self.id = id
        self.generatedAt = generatedAt
        self.predictionType = predictionType
        self.targetDate = targetDate
        self.dateRangeStart = dateRangeStart
        self.dateRangeEnd = dateRangeEnd
        self.predictedCycleLength = predictedCycleLength
        self.confidence = confidence
        self.inputCycleIDs = inputCycleIDs
        self.inputObservationIDs = inputObservationIDs
        self.methodVersion = methodVersion
        self.sourceObservationIDs = sourceObservationIDs
        self.informationType = .estimated
        self.validFrom = validFrom
        self.validUntil = validUntil
    }
}

nonisolated enum Prompt13PatternInsightType: String, Codable, Sendable {
    case cycleLengthRange = "cycle_length_range"
    case symptomNearCycleStart = "symptom_near_cycle_start"
}

nonisolated struct PatternInsight: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let insightType: Prompt13PatternInsightType
    let generatedAt: Date
    let sourceCycleIDs: [UUID]
    let sourceObservationIDs: [UUID]
    let sampleSize: Int
    let confidence: Prompt13CycleConfidence
    let textKey: String
    let dataPayload: [String: String]
    let informationType: BiologicalDataProvenance

    init(
        id: UUID = UUID(),
        insightType: Prompt13PatternInsightType,
        generatedAt: Date,
        sourceCycleIDs: [UUID],
        sourceObservationIDs: [UUID] = [],
        sampleSize: Int,
        confidence: Prompt13CycleConfidence,
        textKey: String,
        dataPayload: [String: String],
        informationType: BiologicalDataProvenance
    ) {
        self.id = id
        self.insightType = insightType
        self.generatedAt = generatedAt
        self.sourceCycleIDs = sourceCycleIDs
        self.sourceObservationIDs = sourceObservationIDs
        self.sampleSize = sampleSize
        self.confidence = confidence
        self.textKey = textKey
        self.dataPayload = dataPayload
        self.informationType = informationType
    }
}

// MARK: - Derived state

nonisolated enum Prompt13VariationLevel: String, Codable, Sendable {
    case low
    case moderate
    case high
    case insufficientData = "insufficient_data"
}

nonisolated struct Prompt13CycleStatistics: Codable, Equatable, Sendable {
    let completedCycleLengths: [Int]
    let mean: Double?
    let median: Double?
    let medianAbsoluteDeviation: Double?
    let minimum: Int?
    let maximum: Int?
    let variation: Prompt13VariationLevel
}

nonisolated struct Prompt13DerivedState: Codable, Equatable, Sendable {
    let generatedAt: Date
    let cycles: [Cycle]
    let statistics: Prompt13CycleStatistics
    let currentCycleDay: Int?
    let currentCycleID: UUID?
    let currentDate: Prompt13LocalDate
    let activePredictions: [PredictionSnapshot]
    let patternInsights: [PatternInsight]
    let needsReviewCycleStartIDs: [UUID]

    var nextPeriodPrediction: PredictionSnapshot? {
        activePredictions.first {
            $0.predictionType == .nextPeriod
        }
    }
}

// MARK: - Archive / persistence

nonisolated struct Prompt13CycleArchive: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var localProfileID: UUID
    var deviceID: UUID

    var cycleStarts: [CycleStart]
    var dailyLogs: [DailyLog]

    var bleedingObservations: [BleedingObservation]
    var symptomObservations: [SymptomObservation]
    var temperatureObservations: [TemperatureObservation]
    var cervicalFluidObservations: [CervicalFluidObservation]
    var medicationObservations: [MedicationObservation]
    var notes: [Note]
    var pregnancyTestObservations: [PregnancyTestObservation]

    var predictionSnapshots: [PredictionSnapshot]
    var patternInsights: [PatternInsight]

    var lastUpdatedAt: Date

    init(
        schemaVersion: Int = 1,
        localProfileID: UUID = UUID(),
        deviceID: UUID = UUID(),
        cycleStarts: [CycleStart] = [],
        dailyLogs: [DailyLog] = [],
        bleedingObservations: [BleedingObservation] = [],
        symptomObservations: [SymptomObservation] = [],
        temperatureObservations: [TemperatureObservation] = [],
        cervicalFluidObservations: [CervicalFluidObservation] = [],
        medicationObservations: [MedicationObservation] = [],
        notes: [Note] = [],
        pregnancyTestObservations: [PregnancyTestObservation] = [],
        predictionSnapshots: [PredictionSnapshot] = [],
        patternInsights: [PatternInsight] = [],
        lastUpdatedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.localProfileID = localProfileID
        self.deviceID = deviceID
        self.cycleStarts = cycleStarts
        self.dailyLogs = dailyLogs
        self.bleedingObservations = bleedingObservations
        self.symptomObservations = symptomObservations
        self.temperatureObservations = temperatureObservations
        self.cervicalFluidObservations = cervicalFluidObservations
        self.medicationObservations = medicationObservations
        self.notes = notes
        self.pregnancyTestObservations = pregnancyTestObservations
        self.predictionSnapshots = predictionSnapshots
        self.patternInsights = patternInsights
        self.lastUpdatedAt = lastUpdatedAt
    }
}

// MARK: - Errors

nonisolated enum Prompt13CycleError: Error, LocalizedError, Equatable {
    case invalidDate
    case futureObservationNotAllowed
    case duplicateCycleStartDate(Prompt13LocalDate)
    case recordNotFound
    case invalidTemperature
    case invalidMedicationName
    case invalidDose
    case emptyNote
    case persistenceFailure
    case syncConflict

    var errorDescription: String? {
        switch self {
        case .invalidDate:
            return "that calendar date is not valid."

        case .futureObservationNotAllowed:
            return "future observations cannot be recorded as facts."

        case let .duplicateCycleStartDate(date):
            return "a recorded cycle start already exists on \(date)."

        case .recordNotFound:
            return "that cycle record could not be found."

        case .invalidTemperature:
            return "that temperature could not be stored safely."

        case .invalidMedicationName:
            return "enter a medication name before saving it."

        case .invalidDose:
            return "that medication dose is not valid."

        case .emptyNote:
            return "a blank note is not stored."

        case .persistenceFailure:
            return "Fruitfolio could not save cycle data locally."

        case .syncConflict:
            return "Fruitfolio found cycle data that needs review before it can be merged."
        }
    }
}
