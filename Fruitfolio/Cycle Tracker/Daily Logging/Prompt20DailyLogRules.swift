import Foundation

public enum Prompt20DailyLogValidationIssue: Error, Equatable, Sendable {
    case bleedingLevelRequiredForNote
    case invalidTemperatureFormat
    case implausibleTemperature
    case temperatureValueRequired
    case cervicalCategoryRequiredForNote
    case medicationNameRequired(index: Int)
}

public struct Prompt20DailyLogValidationResult: Equatable, Sendable {
    public var issues: [Prompt20DailyLogValidationIssue]

    public init(issues: [Prompt20DailyLogValidationIssue] = []) {
        self.issues = issues
    }

    public var isValid: Bool { issues.isEmpty }
}

public enum Prompt20DailyLogRules {
    public static func isFuture(
        _ day: Prompt20LocalDay,
        relativeTo now: Date,
        calendar: Calendar
    ) -> Bool {
        day > Prompt20LocalDay(date: now, calendar: calendar)
    }

    public static func validate(_ draft: Prompt20DailyLogDraft) -> Prompt20DailyLogValidationResult {
        var issues: [Prompt20DailyLogValidationIssue] = []

        let bleedingNote = draft.bleedingNote
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.bleedingLevel == nil && !bleedingNote.isEmpty {
            issues.append(.bleedingLevelRequiredForNote)
        }

        let trimmedTemperature = draft.temperatureText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let temperatureNote = draft.temperatureNote
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedTemperature.isEmpty &&
            (draft.temperatureReadingType != nil || !temperatureNote.isEmpty) {
            issues.append(.temperatureValueRequired)
        }

        if !trimmedTemperature.isEmpty {
            if let value = Double(trimmedTemperature.replacingOccurrences(of: ",", with: ".")) {
                let celsius: Double
                switch draft.temperatureUnit {
                case .celsius:
                    celsius = value
                case .fahrenheit:
                    celsius = (value - 32.0) * 5.0 / 9.0
                }

                // Intentionally broad typo-protection, not a clinical range.
                if celsius < 20.0 || celsius > 50.0 {
                    issues.append(.implausibleTemperature)
                }
            } else {
                issues.append(.invalidTemperatureFormat)
            }
        }

        let cervicalNote = draft.cervicalFluidNote
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if draft.cervicalFluidCategory == nil && !cervicalNote.isEmpty {
            issues.append(.cervicalCategoryRequiredForNote)
        }

        for (index, medication) in draft.medications.enumerated() {
            guard medication.hasAnyContent else { continue }
            if medication.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                issues.append(.medicationNameRequired(index: index))
            }
        }

        return Prompt20DailyLogValidationResult(issues: issues)
    }

    public static func makeLog(
        ownerID: Prompt20DailyLogOwnerID,
        date: Prompt20LocalDay,
        draft: Prompt20DailyLogDraft,
        existing: Prompt20DailyLog?,
        now: Date
    ) throws -> Prompt20DailyLog {
        let validation = validate(draft)
        guard validation.isValid else {
            throw Prompt20DailyLogDomainError.validation(validation.issues)
        }

        let bleedingNote = cleaned(draft.bleedingNote)
        let symptomNote = cleaned(draft.symptomNote)
        let temperatureNote = cleaned(draft.temperatureNote)
        let cervicalNote = cleaned(draft.cervicalFluidNote)
        let generalNoteText = cleaned(draft.generalNote)

        let bleeding: Prompt20BleedingObservation?
        if let level = draft.bleedingLevel {
            bleeding = Prompt20BleedingObservation(level: level, note: bleedingNote)
        } else {
            bleeding = nil
        }

        let symptoms: Prompt20SymptomObservation?
        if !draft.selectedSymptoms.isEmpty || !symptomNote.isEmpty {
            symptoms = Prompt20SymptomObservation(
                selectedIDs: draft.selectedSymptoms,
                note: symptomNote
            )
        } else {
            symptoms = nil
        }

        let temperature: Prompt20TemperatureObservation?
        let trimmedTemperature = draft.temperatureText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTemperature.isEmpty,
           let value = Double(trimmedTemperature.replacingOccurrences(of: ",", with: ".")) {
            temperature = Prompt20TemperatureObservation(
                originalValue: value,
                originalUnit: draft.temperatureUnit,
                readingType: draft.temperatureReadingType,
                note: temperatureNote
            )
        } else {
            temperature = nil
        }

        let cervicalFluid: Prompt20CervicalFluidObservation?
        if let category = draft.cervicalFluidCategory {
            cervicalFluid = Prompt20CervicalFluidObservation(
                category: category,
                note: cervicalNote
            )
        } else {
            cervicalFluid = nil
        }

        let medications = draft.medications
            .filter(\.hasAnyContent)
            .map { entry in
                Prompt20MedicationEntry(
                    id: entry.id,
                    name: cleaned(entry.name),
                    dose: cleaned(entry.dose),
                    time: cleaned(entry.time),
                    note: cleaned(entry.note)
                )
            }

        let note = generalNoteText.isEmpty
            ? nil
            : Prompt20GeneralNote(text: generalNoteText)

        return Prompt20DailyLog(
            id: existing?.id ?? UUID(),
            ownerID: ownerID,
            date: date,
            periodEvent: draft.periodEvent,
            bleeding: bleeding,
            symptoms: symptoms,
            temperature: temperature,
            cervicalFluid: cervicalFluid,
            medications: medications,
            generalNote: note,
            createdAt: existing?.createdAt ?? now,
            updatedAt: now,
            revision: max((existing?.revision ?? 0) + 1, 1),
            isDeleted: false
        )
    }

    public static func summary(for log: Prompt20DailyLog) -> Prompt20DailyLogSummary {
        Prompt20DailyLogSummary(
            hasBleedingObservation: log.bleeding != nil,
            hasSymptoms: !(log.symptoms?.selectedIDs.isEmpty ?? true) || !(log.symptoms?.note.isEmpty ?? true),
            hasBasalTemperature: log.temperature?.readingType == .basalWaking,
            hasAnyTemperature: log.temperature != nil,
            hasCervicalFluid: log.cervicalFluid != nil,
            hasMedication: !log.medications.isEmpty,
            hasGeneralNote: log.generalNote != nil,
            symptomNames: log.symptoms?.selectedIDs
                .sorted { $0.rawValue < $1.rawValue }
                .map(\.displayName) ?? [],
            temperatureDisplay: log.temperature.map { temperature in
                let value = Prompt20TemperatureFormatter.string(temperature.originalValue, unit: temperature.originalUnit)
                let kind = temperature.readingType?.displayName
                return kind.map { "\(value)\(temperature.originalUnit.symbol) · \($0)" }
                    ?? "\(value)\(temperature.originalUnit.symbol)"
            },
            notePreview: log.generalNote?.text
        )
    }

    private static func cleaned(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct Prompt20DailyLogSummary: Equatable, Sendable {
    public let hasBleedingObservation: Bool
    public let hasSymptoms: Bool
    public let hasBasalTemperature: Bool
    public let hasAnyTemperature: Bool
    public let hasCervicalFluid: Bool
    public let hasMedication: Bool
    public let hasGeneralNote: Bool
    public let symptomNames: [String]
    public let temperatureDisplay: String?
    public let notePreview: String?
}

public enum Prompt20DailyLogDomainError: Error, Equatable, Sendable {
    case validation([Prompt20DailyLogValidationIssue])
    case futureDate
    case persistenceUnavailable
    case corruptPersistence
}
