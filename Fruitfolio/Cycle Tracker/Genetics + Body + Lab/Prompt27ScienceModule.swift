import Foundation

@MainActor
struct Prompt27ScienceModule: Sendable {
    let catalog: Prompt27ScientificAssetCatalog
    let router: Prompt27ContextRouter
    let researchProvider: any Prompt27ScienceResearchProviding
    let actions: Prompt27ScienceActions

    init(
        catalog: Prompt27ScientificAssetCatalog? = nil,
        researchProvider: (any Prompt27ScienceResearchProviding)? = nil,
        actions: Prompt27ScienceActions? = nil
    ) {
        let resolvedCatalog = catalog ?? Prompt27ScientificAssetCatalog()
        self.catalog = resolvedCatalog
        self.router = Prompt27ContextRouter(catalog: resolvedCatalog)
        self.researchProvider = researchProvider ?? Prompt27UnavailableScienceResearchProvider()
        self.actions = actions ?? Prompt27ScienceActions()
    }

    func route(
        section: Prompt27ContextualScienceSection
    ) -> Result<Prompt27ScienceVisualRoute, Prompt27ScienceRoutingError> {
        router.route(section: section)
    }
}
