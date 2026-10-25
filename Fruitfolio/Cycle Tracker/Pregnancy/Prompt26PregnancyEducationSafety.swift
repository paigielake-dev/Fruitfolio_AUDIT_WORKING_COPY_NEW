import Foundation

enum Prompt26PregnancyEntryContext: Equatable, Sendable {
    case intentionalEncyclopediaOpen
    case directEducationalSearch
    case savedEducationalEntry
    case cyclePredictionPassed(days: Int)
    case symptomTriggered
    case notification
    case backgroundRecommendation
}

enum Prompt26PregnancyArtworkGate {
    static func mayDisplayPregnancySpecificArtwork(in context: Prompt26PregnancyEntryContext) -> Bool {
        switch context {
        case .intentionalEncyclopediaOpen, .directEducationalSearch, .savedEducationalEntry:
            return true
        case .cyclePredictionPassed, .symptomTriggered, .notification, .backgroundRecommendation:
            return false
        }
    }
}

struct Prompt26PregnancyInferenceInput: Equatable, Sendable {
    var predictedPeriodDaysPast: Int?
    var symptoms: Set<String>
    var hasElevatedBBTObservation: Bool
    var hasIntercourseLog: Bool
    var hasEstimatedFertileWindowIntercourse: Bool
    var hasEstimatedOvulation: Bool
    var hasCervicalFluidObservation: Bool
    var hasLHObservation: Bool

    init(
        predictedPeriodDaysPast: Int? = nil,
        symptoms: Set<String> = [],
        hasElevatedBBTObservation: Bool = false,
        hasIntercourseLog: Bool = false,
        hasEstimatedFertileWindowIntercourse: Bool = false,
        hasEstimatedOvulation: Bool = false,
        hasCervicalFluidObservation: Bool = false,
        hasLHObservation: Bool = false
    ) {
        self.predictedPeriodDaysPast = predictedPeriodDaysPast
        self.symptoms = symptoms
        self.hasElevatedBBTObservation = hasElevatedBBTObservation
        self.hasIntercourseLog = hasIntercourseLog
        self.hasEstimatedFertileWindowIntercourse = hasEstimatedFertileWindowIntercourse
        self.hasEstimatedOvulation = hasEstimatedOvulation
        self.hasCervicalFluidObservation = hasCervicalFluidObservation
        self.hasLHObservation = hasLHObservation
    }
}

struct Prompt26PregnancyDerivedState: Equatable, Sendable {
    let pregnancyInferred: Bool
    let pregnancyProbability: Double?
    let gestationalAgeDays: Int?
    let estimatedDueDate: Date?
    let showPregnancySpecificArtworkAutomatically: Bool
    let activatePregnancyMode: Bool

    static let noInference = Prompt26PregnancyDerivedState(
        pregnancyInferred: false,
        pregnancyProbability: nil,
        gestationalAgeDays: nil,
        estimatedDueDate: nil,
        showPregnancySpecificArtworkAutomatically: false,
        activatePregnancyMode: false
    )
}

enum Prompt26PregnancyInferenceGuard {
    static func deriveState(from _: Prompt26PregnancyInferenceInput) -> Prompt26PregnancyDerivedState {
        .noInference
    }
}

enum Prompt26PregnancyQuestionBoundary: Equatable, Sendable {
    case educationalAnswerAllowed
    case testingAndCareEducationOnly
    case unsupportedMedicalInterpretation
}

enum Prompt26PregnancyQuestionPolicy {
    static func boundary(forNormalizedQuery query: String) -> Prompt26PregnancyQuestionBoundary {
        let q = query.lowercased()

        let prohibitedInterpretationMarkers = [
            "interpret my ultrasound",
            "read my ultrasound",
            "interpret my pregnancy test photo",
            "read my pregnancy test photo",
            "tell me the sex from ultrasound",
            "diagnose miscarriage",
            "diagnose ectopic"
        ]
        if prohibitedInterpretationMarkers.contains(where: q.contains) {
            return .unsupportedMedicalInterpretation
        }

        let personalizedPregnancyMarkers = [
            "am i pregnant",
            "could i be pregnant",
            "do you think i'm pregnant",
            "do you think i am pregnant",
            "my period is late"
        ]
        if personalizedPregnancyMarkers.contains(where: q.contains) {
            return .testingAndCareEducationOnly
        }

        return .educationalAnswerAllowed
    }
}
