#if canImport(SwiftUI) && canImport(Combine)
import Foundation
import Combine
import SwiftUI

@MainActor
final class Prompt27AContextStore: ObservableObject {
    static let storageKey = "fruitfolio.prompt27a.userReproductiveContext.v1"

    @Published private(set) var context: Prompt27AUserReproductiveContext
    @Published private(set) var didRecoverCorruptStoredContext = false

    @Published private(set) var persistenceError: String?
    var loadError: String? {
        didRecoverCorruptStoredContext
            ? "your saved context could not be read. the original data is preserved. clear context explicitly only if you want to discard it."
            : nil
    }

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
        }
        if defaults.object(forKey: Self.storageKey) != nil, defaults.data(forKey: Self.storageKey) == nil {
            self.didRecoverCorruptStoredContext = true
        }
    }

    func setTrackingGoal(_ value: Prompt27ATrackingGoal) {
        mutate { $0.setTrackingGoal(value) }
    }

    func setSexualActivityContext(_ value: Prompt27ASexualActivityContext) {
        mutate { $0.setSexualActivityContext(value) }
    }

    func setReproductiveStage(_ value: Prompt27AReproductiveStage) {
        mutate { $0.setReproductiveStage(value) }
    }

    func setSurrogacyContext(_ value: Prompt27ASurrogacyContext) {
        mutate { $0.setSurrogacyContext(value) }
    }

    func setLactationContext(_ value: Prompt27ALactationContext) {
        mutate { $0.setLactationContext(value) }
    }

    func setCycleHealthContext(_ value: Prompt27ACycleHealthContext, selected: Bool) {
        mutate { $0.setCycleHealthContext(value, selected: selected) }
    }

    func setInfertilityContext(_ value: Prompt27AInfertilityContext) {
        mutate { $0.setInfertilityContext(value) }
    }

    func setFertilityTreatmentContext(_ value: Prompt27AFertilityTreatmentContext) {
        mutate { $0.setFertilityTreatmentContext(value) }
    }

    func setContraceptionContext(_ value: Prompt27AContraceptionContext) {
        mutate { $0.setContraceptionContext(value) }
    }

    func setPersonalHealthField(_ field: Prompt27AHealthField, text: String,
                                status: Prompt27AHealthEntry.Status = .supplied,
                                clinicianConfirmedByUser: Bool = false) {
        mutate { candidate in
            candidate.personalHealthFields[field] = .init(text: text, status: status,
                clinicianConfirmedByUser: clinicianConfirmedByUser)
        }
    }

    func clearContext() {
        var cleared = context
        cleared.clear()
        save(cleared, explicitlyDiscardCorruptData: true)
    }

    /// Synchronizes only exact semantic overlaps from Cycle Onboarding into
    /// My Context. Ambiguous answers (for example “recent pregnancy” or
    /// “recently stopped hormonal birth control”) are deliberately not inferred
    /// into a different present-tense health state.
    func syncFromCycleOnboarding(_ draft: Prompt14OnboardingDraft, previous: Prompt14OnboardingDraft? = nil) {
        guard !didRecoverCorruptStoredContext else { return }
        var updated = context
        let now = Date()
        // An explicitly removed onboarding answer must stop influencing the
        // shared context. Initial loading alone never erases independent edits.
        if let previous {
            if previous.cycleAffectingContexts.contains(.preferNotToSay), !draft.cycleAffectingContexts.contains(.preferNotToSay) {
                if updated.contraceptionContext.value == .preferNotToSpecify { updated.setContraceptionContext(.unspecified, at: now) }
                if updated.fertilityTreatmentContext.value == .preferNotToSpecify { updated.setFertilityTreatmentContext(.unspecified, at: now) }
            }
            if previous.cycleAffectingContexts.contains(.none), !draft.cycleAffectingContexts.contains(.none) {
                if updated.contraceptionContext.value == .none { updated.setContraceptionContext(.unspecified, at: now) }
                if updated.fertilityTreatmentContext.value == .notCurrentlyUndergoing { updated.setFertilityTreatmentContext(.unspecified, at: now) }
            }
            if previous.recentContexts.contains(.preferNotToSay), !draft.recentContexts.contains(.preferNotToSay) {
                if updated.reproductiveStage.value == .preferNotToSpecify { updated.setReproductiveStage(.unspecified, at: now) }
                if updated.lactationContext.value == .preferNotToSpecify { updated.setLactationContext(.unspecified, at: now) }
            }
            if previous.recentContexts.contains(.none), !draft.recentContexts.contains(.none),
               updated.lactationContext.value == .notCurrentlyBreastfeedingOrLactating {
                updated.setLactationContext(.unspecified, at: now)
            }
            if previous.cycleAffectingContexts.contains(.hormonalBirthControl),
               !draft.cycleAffectingContexts.contains(.hormonalBirthControl),
               updated.contraceptionContext.value == .hormonalContraception {
                updated.setContraceptionContext(.unspecified, at: now)
            }
            if previous.cycleAffectingContexts.contains(.fertilityMedication),
               !draft.cycleAffectingContexts.contains(.fertilityMedication),
               updated.fertilityTreatmentContext.value == .currentlyUndergoing {
                updated.setFertilityTreatmentContext(.unspecified, at: now)
            }
            if previous.recentContexts.contains(.postpartum), !draft.recentContexts.contains(.postpartum),
               updated.reproductiveStage.value == .postpartum {
                updated.setReproductiveStage(.unspecified, at: now)
            }
            if previous.recentContexts.contains(.breastfeeding), !draft.recentContexts.contains(.breastfeeding),
               updated.lactationContext.value == .breastfeedingOrLactating {
                updated.setLactationContext(.unspecified, at: now)
            }
        }

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
        save(updated)
    }

    /// Explicit privacy/export bridge. This exports only the user-reported
    /// context object and never reaches into cycle history or other domains.
    func exportReadableJSON() throws -> Data {
        guard !didRecoverCorruptStoredContext else { throw CocoaError(.fileReadCorruptFile) }
        return try codec.encode(context)
    }

    /// Explicit local erase for this context domain only. Historical cycle,
    /// Daily Log, Trends, BBT, symptom, note, and prediction records are not
    /// rewritten or deleted by this operation.
    func eraseLocalContextData() {
        context = .unspecified
        defaults.removeObject(forKey: Self.storageKey)
        didRecoverCorruptStoredContext = false
        persistenceError = nil
    }

    private func mutate(_ edit: (inout Prompt27AUserReproductiveContext) -> Void) {
        guard !didRecoverCorruptStoredContext else { return }
        var candidate = context
        edit(&candidate)
        save(candidate)
    }

    private func save(_ candidate: Prompt27AUserReproductiveContext, explicitlyDiscardCorruptData: Bool = false) {
        guard !didRecoverCorruptStoredContext || explicitlyDiscardCorruptData else { return }
        do {
            let data = try codec.encode(candidate)
            defaults.set(data, forKey: Self.storageKey)
            context = candidate
            didRecoverCorruptStoredContext = false
            persistenceError = nil
        } catch {
            persistenceError = "your context could not be saved. your previous saved information is unchanged."
        }
    }
}
#endif
