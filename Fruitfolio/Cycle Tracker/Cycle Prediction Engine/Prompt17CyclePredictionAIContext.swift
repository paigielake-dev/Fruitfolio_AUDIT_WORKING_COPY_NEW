import Foundation

public struct Prompt17StructuredFact<Value: Sendable>: Sendable {
    public let value: Value
    public let provenance: Prompt17BiologicalDataProvenance

    public init(
        value: Value,
        provenance: Prompt17BiologicalDataProvenance
    ) {
        self.value = value
        self.provenance = provenance
    }
}

public struct Prompt17CycleAIContext: Sendable {
    public let currentCycleDay: Prompt17StructuredFact<Int>?
    public let recentCycleLengths: Prompt17StructuredFact<[Int]>
    public let medianCycleLength: Prompt17StructuredFact<Double>?
    public let cycleVariation: Prompt17StructuredFact<Prompt17CycleVariation>?
    public let confidence: Prompt17StructuredFact<Prompt17PredictionConfidence>
    public let nextPeriodWindow: Prompt17StructuredFact<Prompt17DateWindow>?
    public let predictionRangeWidthDays: Prompt17StructuredFact<Int>?

    public init(result: Prompt17CyclePredictionResult) {
        self.currentCycleDay = result.currentCycleDay.map {
            Prompt17StructuredFact(
                value: $0,
                provenance: .calculated
            )
        }

        self.recentCycleLengths = Prompt17StructuredFact(
            value: result.recentCycleLengths,
            provenance: .calculated
        )

        self.medianCycleLength = result.medianCycleLength.map {
            Prompt17StructuredFact(
                value: $0,
                provenance: .calculated
            )
        }

        self.cycleVariation = result.cycleVariation.map {
            Prompt17StructuredFact(
                value: $0,
                provenance: .calculated
            )
        }

        self.confidence = Prompt17StructuredFact(
            value: result.predictionConfidence,
            provenance: .calculated
        )

        self.nextPeriodWindow = result.nextPeriodWindow.map {
            Prompt17StructuredFact(
                value: $0,
                provenance: .estimated
            )
        }

        self.predictionRangeWidthDays = result.predictionRangeHalfWidthDays.map {
            Prompt17StructuredFact(
                value: ($0 * 2) + 1,
                provenance: .calculated
            )
        }
    }
}

public extension Prompt17PredictionConfidence {
    var explanation: String {
        "based on your recent cycle history."
    }
}

public extension Prompt17CyclePredictionResult {
    var highVariationMessage: String? {
        guard cycleVariation == .high else {
            return nil
        }

        return "your recent cycles vary a bit, so this window is wider!"
    }
}
