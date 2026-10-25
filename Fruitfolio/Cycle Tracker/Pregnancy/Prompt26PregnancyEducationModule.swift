#if canImport(SwiftUI)
import SwiftUI

nonisolated enum Prompt26PregnancyContextualEducationSurface {
    static func shouldSurface(
        policy: Prompt27AContextPolicyResult
    ) -> Bool {
        policy[.pregnancyEducation].effect == .surface
    }
}

enum Prompt26PregnancyEducationModule {
    static let routeID = "pregnancyEducation"
    static let encyclopediaSectionID = "reproductive_health.pregnancy"

    static func rootView(
        provider: any Prompt26PregnancyResearchProviding,
        actions: Prompt26PregnancyEducationActions,
        entryContext: Prompt26PregnancyEntryContext = .intentionalEncyclopediaOpen
    ) -> Prompt26PregnancyEducationRootView {
        Prompt26PregnancyEducationRootView(
            provider: provider,
            actions: actions,
            entryContext: entryContext
        )
    }
}
#endif

