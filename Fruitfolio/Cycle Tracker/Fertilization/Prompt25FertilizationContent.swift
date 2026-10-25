import Foundation

/// Adapter boundary between Phase 25 and the approved FruitsofLife.xo
/// Research Library/content architecture.
///
/// Production implementations must return only founder-approved, Research-Library
/// backed content. They must not synthesize embryology from model memory.
protocol Prompt25FertilizationContentProviding: Sendable {
    func content(
        for stage: Prompt25FertilizationStage
    ) async -> Prompt25EducationalContent
}

/// Safe launch default.
///
/// This intentionally returns the canonical unavailable-content state until the
/// application's approved Research Library adapter is supplied.
nonisolated struct Prompt25UnavailableContentProvider:
    Prompt25FertilizationContentProviding
{
    func content(
        for stage: Prompt25FertilizationStage
    ) async -> Prompt25EducationalContent {
        .unavailable
    }
}

#if DEBUG
/// Deterministic fixture provider for previews/tests only.
/// Never ship these strings as scientific production content.
nonisolated struct Prompt25DebugFixtureContentProvider:
    Prompt25FertilizationContentProviding
{
    func content(
        for stage: Prompt25FertilizationStage
    ) async -> Prompt25EducationalContent {
        Prompt25EducationalContent(
            shortText:
                "Preview fixture for \(stage.title). Production copy comes from the approved Research Library.",
            expandedSections: [
                Prompt25EducationalSection(
                    id: "fixture",
                    heading: "preview",
                    body:
                        "This debug-only text exists to validate layout and progressive disclosure."
                )
            ],
            sourceCount: 2,
            isApproved: false
        )
    }
}
#endif
