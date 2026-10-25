#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt27AContextStore: ObservableObject {
    static let storageKey = "fruitfolio.prompt27a.userReproductiveContext.v1"

    @Published private(set) var context: Prompt27AUserReproductiveContext
    @Published private(set) var didRecoverCorruptStoredContext = false

    private let defaults: UserDefaults
    private let codec: Prompt27AContextCodec

    init(
        defaults: UserDefaults = .standard,
        codec: Prompt27AContextCodec = Prompt27AContextCodec()
    ) {
        self.defaults = defaults
        self.codec = codec

        let migration = codec.migrationResult(data: defaults.data(forKey: Self.storageKey))
        self.context = migration.context
        if case .corruptStoredValue = migration {
            self.didRecoverCorruptStoredContext = true
            defaults.removeObject(forKey: Self.storageKey)
        }
    }

    func setTrackingGoal(_ value: Prompt27ATrackingGoal) {
        context.setTrackingGoal(value)
        persist()
    }

    func setSexualActivityContext(_ value: Prompt27ASexualActivityContext) {
        context.setSexualActivityContext(value)
        persist()
    }

    func setReproductiveStage(_ value: Prompt27AReproductiveStage) {
        context.setReproductiveStage(value)
        persist()
    }

    func setSurrogacyContext(_ value: Prompt27ASurrogacyContext) {
        context.setSurrogacyContext(value)
        persist()
    }

    func setLactationContext(_ value: Prompt27ALactationContext) {
        context.setLactationContext(value)
        persist()
    }

    func setCycleHealthContext(_ value: Prompt27ACycleHealthContext, selected: Bool) {
        context.setCycleHealthContext(value, selected: selected)
        persist()
    }

    func setInfertilityContext(_ value: Prompt27AInfertilityContext) {
        context.setInfertilityContext(value)
        persist()
    }

    func setFertilityTreatmentContext(_ value: Prompt27AFertilityTreatmentContext) {
        context.setFertilityTreatmentContext(value)
        persist()
    }

    func setContraceptionContext(_ value: Prompt27AContraceptionContext) {
        context.setContraceptionContext(value)
        persist()
    }

    func clearContext() {
        context.clear()
        persist()
    }

    /// Synchronizes only exact semantic overlaps from Cycle Onboarding into
    /// My Context. Ambiguous answers (for example “recent pregnancy” or
    /// “recently stopped hormonal birth control”) are deliberately not inferred
    /// into a different present-tense health state.
    func syncFromCycleOnboarding(_ draft: Prompt14OnboardingDraft) {
        var updated = context
        let now = Date()

        if draft.cycleContextState == .supplied {
            let choices = draft.cycleAffectingContexts
            if choices.contains(.preferNotToSay) {
                updated.setContraceptionContext(.preferNotToSpecify, at: now)
                updated.setFertilityTreatmentContext(.preferNotToSpecify, at: now)
            } else {
                if choices.contains(.hormonalBirthControl) {
                    updated.setContraceptionContext(.hormonalContraception, at: now)
                } else if choices.contains(.none) {
                    updated.setContraceptionContext(.none, at: now)
                }

                if choices.contains(.fertilityMedication) {
                    updated.setFertilityTreatmentContext(.currentlyUndergoing, at: now)
                } else if choices.contains(.none) {
                    updated.setFertilityTreatmentContext(.notCurrentlyUndergoing, at: now)
                }
            }
        }

        if draft.recentContextState == .supplied {
            let choices = draft.recentContexts
            if choices.contains(.preferNotToSay) {
                updated.setReproductiveStage(.preferNotToSpecify, at: now)
                updated.setLactationContext(.preferNotToSpecify, at: now)
            } else {
                if choices.contains(.postpartum) {
                    updated.setReproductiveStage(.postpartum, at: now)
                }
                if choices.contains(.breastfeeding) {
                    updated.setLactationContext(.breastfeedingOrLactating, at: now)
                } else if choices.contains(.none) {
                    updated.setLactationContext(.notCurrentlyBreastfeedingOrLactating, at: now)
                }
            }
        }

        guard updated != context else { return }
        context = updated
        persist()
    }

    /// Explicit privacy/export bridge. This exports only the user-reported
    /// context object and never reaches into cycle history or other domains.
    func exportReadableJSON() throws -> Data {
        try codec.encode(context)
    }

    /// Explicit local erase for this context domain only. Historical cycle,
    /// Daily Log, Trends, BBT, symptom, note, and prediction records are not
    /// rewritten or deleted by this operation.
    func eraseLocalContextData() {
        context = .unspecified
        defaults.removeObject(forKey: Self.storageKey)
    }

    private func persist() {
        guard let data = try? codec.encode(context) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
#endif
