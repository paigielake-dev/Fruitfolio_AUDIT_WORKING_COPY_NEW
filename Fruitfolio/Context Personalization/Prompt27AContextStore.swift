#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt27AContextStore: ObservableObject {
    static let storageKey = "fruitfolio.prompt27a.userReproductiveContext.v1"

    @Published private(set) var context: Prompt27AUserReproductiveContext
    @Published private(set) var didRecoverCorruptStoredContext = false

    @Published private(set) var persistenceMessage: String?
    private let persistence: Prompt27ALocalContextPersistence

    init(defaults: UserDefaults = .standard, codec: Prompt27AContextCodec = Prompt27AContextCodec(), key: String? = nil) {
        let persistence = Prompt27ALocalContextPersistence(defaults: defaults, key: key ?? Self.storageKey, codec: codec)
        self.persistence = persistence
        context = persistence.context
        didRecoverCorruptStoredContext = persistence.storageUnreadable
    }

    func setTrackingGoal(_ value: Prompt27ATrackingGoal) { update { $0.setTrackingGoal(value) } }
    func setSexualActivityContext(_ value: Prompt27ASexualActivityContext) { update { $0.setSexualActivityContext(value) } }
    func setReproductiveStage(_ value: Prompt27AReproductiveStage) { update { $0.setReproductiveStage(value) } }
    func setSurrogacyContext(_ value: Prompt27ASurrogacyContext) { update { $0.setSurrogacyContext(value) } }
    func setLactationContext(_ value: Prompt27ALactationContext) { update { $0.setLactationContext(value) } }
    func setCycleHealthContext(_ value: Prompt27ACycleHealthContext, selected: Bool) { update { $0.setCycleHealthContext(value, selected: selected) } }
    func setInfertilityContext(_ value: Prompt27AInfertilityContext) { update { $0.setInfertilityContext(value) } }
    func setFertilityTreatmentContext(_ value: Prompt27AFertilityTreatmentContext) { update { $0.setFertilityTreatmentContext(value) } }
    func setContraceptionContext(_ value: Prompt27AContraceptionContext) { update { $0.setContraceptionContext(value) } }
    func clearContext() { eraseLocalContextData() }

    func savePersonalHealth(_ category: FruitfolioPersonalHealthCategory, text: String,
        status: FruitfolioPersonalHealthStatus = .provided,
        provenance: FruitfolioPersonalHealthProvenance = .userProvided) throws {
        try persistence.apply { try $0.setPersonalHealth(category, text: text, status: status, provenance: provenance) }
        refresh()
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
        update { $0 = updated }
    }

    /// Explicit privacy/export bridge. This exports only the user-reported
    /// context object and never reaches into cycle history or other domains.
    func exportReadableJSON() throws -> Data { try persistence.exportJSON() }

    /// Explicit local erase does not rewrite cycle history, logs or predictions.
    func eraseLocalContextData() {
        persistence.erase()
        refresh()
    }
    private func update(_ mutation: (inout Prompt27AUserReproductiveContext) -> Void) {
        do { try persistence.apply(mutation); refresh() }
        catch { persistenceMessage = "your context could not be saved. the original local data has been kept." }
    }
    private func refresh() {
        context = persistence.context
        didRecoverCorruptStoredContext = persistence.storageUnreadable
        persistenceMessage = nil
    }
}
#endif
