import Foundation

enum Prompt27ScienceUserIntent: Equatable, Sendable {
    case learnGenetics
    case learnAnatomy
    case learnHowTestingWorks
    case personalizedGeneticRisk
    case inferGenotype
    case inferAncestry
    case interpretRawGeneticData
    case diagnoseFromLabResult
    case diagnoseFromImage
    case identifyMicrobeFromPhoto
    case inventReferenceRange
    case inventDiagnosticThreshold
    case inventPCRPerformance
}

enum Prompt27ScienceQuestionBoundary: Equatable, Sendable {
    case allowedEducational
    case requiresSeparateValidatedSystem
    case prohibitedInference
}

enum Prompt27ScienceSafety {
    static func boundary(
        for intent: Prompt27ScienceUserIntent
    ) -> Prompt27ScienceQuestionBoundary {
        switch intent {
        case .learnGenetics, .learnAnatomy, .learnHowTestingWorks:
            return .allowedEducational

        case .personalizedGeneticRisk,
             .interpretRawGeneticData,
             .diagnoseFromLabResult,
             .inventReferenceRange,
             .inventDiagnosticThreshold,
             .inventPCRPerformance:
            return .requiresSeparateValidatedSystem

        case .inferGenotype,
             .inferAncestry,
             .diagnoseFromImage,
             .identifyMicrobeFromPhoto:
            return .prohibitedInference
        }
    }

    static func browsingEstablishesMedicalState() -> Bool {
        false
    }

    static func browsingEstablishesGenotype() -> Bool {
        false
    }

    static func browsingEstablishesDiagnosis() -> Bool {
        false
    }

    static func laboratoryIllustrationEstablishesUserTestingHistory() -> Bool {
        false
    }

    static func permitsRuntimeGeneratedScientificArt() -> Bool {
        false
    }

    static func permitsNaiveKeywordIllustrationRouting() -> Bool {
        false
    }
}
